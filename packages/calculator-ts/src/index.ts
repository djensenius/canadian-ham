export type CalculatorLocale = "en" | "fr";
export type CalculatorDigitKey = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9";
export type CalculatorBinaryOperator = "+" | "-" | "×" | "÷";
export type CalculatorKey =
  | CalculatorDigitKey
  | "."
  | CalculatorBinaryOperator
  | "="
  | "√"
  | "x²"
  | "1/x"
  | "±"
  | "%"
  | "C/CE"
  | "AC"
  | "backspace";

export interface CalculatorLastOperation {
  readonly operator: CalculatorBinaryOperator;
  readonly rightOperand: number;
}

export interface CalculatorState {
  readonly locale: CalculatorLocale;
  readonly display: string;
  readonly error: boolean;
  readonly accumulator: number | null;
  readonly pendingOperator: CalculatorBinaryOperator | null;
  readonly currentEntry: string;
  readonly entering: boolean;
  readonly displayedValue: number;
  readonly awaitingOperand: boolean;
  readonly lastOperation: CalculatorLastOperation | null;
  readonly justEvaluated: boolean;
}

export interface CalculatorOptions {
  readonly locale?: CalculatorLocale;
}

const DIGIT_KEYS = new Set<CalculatorKey>(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]);
const BINARY_OPERATOR_KEYS = new Set<CalculatorKey>(["+", "-", "×", "÷"]);
const MAX_SIGNIFICANT_DIGITS = 12;
const RESULT_SIGNIFICANT_DIGITS = 15;

export function createCalculatorState(options: CalculatorOptions = {}): CalculatorState {
  return withDisplay({
    locale: options.locale ?? "en",
    display: "0",
    error: false,
    accumulator: null,
    pendingOperator: null,
    currentEntry: "0",
    entering: false,
    displayedValue: 0,
    awaitingOperand: false,
    lastOperation: null,
    justEvaluated: false,
  });
}

export function runCalculatorKeys(keys: readonly CalculatorKey[], options: CalculatorOptions = {}): CalculatorState {
  return keys.reduce((state, key) => applyCalculatorKey(state, key), createCalculatorState(options));
}

export function applyCalculatorKey(state: CalculatorState, key: CalculatorKey): CalculatorState {
  if (key === "AC") {
    return createCalculatorState({ locale: state.locale });
  }

  if (state.error) {
    if (isDigitKey(key)) {
      return inputDigit(createCalculatorState({ locale: state.locale }), key);
    }
    return state;
  }

  if (isDigitKey(key)) {
    return inputDigit(state, key);
  }

  if (key === ".") {
    return inputDecimalPoint(state);
  }

  if (isBinaryOperatorKey(key)) {
    return inputBinaryOperator(state, key);
  }

  switch (key) {
    case "=":
      return inputEquals(state);
    case "√":
      return applyUnaryOperation(state, (value) => value < 0 ? null : Math.sqrt(value));
    case "x²":
      return applyUnaryOperation(state, (value) => value * value);
    case "1/x":
      return applyUnaryOperation(state, (value) => value === 0 ? null : 1 / value);
    case "±":
      return toggleSign(state);
    case "%":
      return applyPercent(state);
    case "C/CE":
      return clearEntry(state);
    case "backspace":
      return backspace(state);
  }
}

export function displayCalculatorValue(value: number, locale: CalculatorLocale = "en"): string {
  if (!Number.isFinite(value)) {
    return "Error";
  }

  const normalizedValue = Object.is(value, -0) ? 0 : value;
  const absoluteValue = Math.abs(normalizedValue);
  if (absoluteValue === 0) {
    return "0";
  }

  const scientific = absoluteValue >= 999_999_999_999.5 || absoluteValue < 1e-9;
  const raw = scientific
    ? normalizeScientific(normalizedValue.toExponential(MAX_SIGNIFICANT_DIGITS - 1))
    : normalizeFixed(normalizedValue.toFixed(fractionDigitsFor(absoluteValue)));
  return localizeDecimalSeparator(raw, locale);
}

function inputDigit(state: CalculatorState, key: CalculatorDigitKey): CalculatorState {
  const startFresh = state.justEvaluated && state.pendingOperator === null;
  const base = startFresh ? createCalculatorState({ locale: state.locale }) : state;
  let entry: string;
  if (!base.entering) {
    entry = key;
  } else if (base.currentEntry === "0") {
    entry = key;
  } else if (base.currentEntry === "-0") {
    entry = key === "0" ? "-0" : `-${key}`;
  } else {
    entry = `${base.currentEntry}${key}`;
  }
  return withDisplay({
    ...base,
    currentEntry: entry,
    entering: true,
    displayedValue: numberFromEntry(entry),
    awaitingOperand: false,
    justEvaluated: false,
  });
}

function inputDecimalPoint(state: CalculatorState): CalculatorState {
  const startFresh = state.justEvaluated && state.pendingOperator === null;
  const base = startFresh ? createCalculatorState({ locale: state.locale }) : state;
  if (!base.entering) {
    return withDisplay({
      ...base,
      currentEntry: "0.",
      entering: true,
      displayedValue: 0,
      awaitingOperand: false,
      justEvaluated: false,
    });
  }
  if (base.currentEntry.includes(".")) {
    return base;
  }
  const currentEntry = `${base.currentEntry}.`;
  return withDisplay({ ...base, currentEntry, displayedValue: numberFromEntry(currentEntry), awaitingOperand: false, justEvaluated: false });
}

function inputBinaryOperator(state: CalculatorState, operator: CalculatorBinaryOperator): CalculatorState {
  const currentValue = currentValueFor(state);
  if (state.pendingOperator !== null && state.accumulator !== null && !state.awaitingOperand) {
    const result = evaluateBinaryOperation(state.pendingOperator, state.accumulator, currentValue);
    if (result === null) {
      return errorState(state);
    }
    return withDisplay({
      ...state,
      accumulator: result,
      pendingOperator: operator,
      currentEntry: "0",
      entering: false,
      displayedValue: result,
      awaitingOperand: true,
      justEvaluated: false,
    });
  }

  return withDisplay({
    ...state,
    accumulator: currentValue,
    pendingOperator: operator,
    currentEntry: "0",
    entering: false,
    displayedValue: currentValue,
    awaitingOperand: true,
    justEvaluated: false,
  });
}

function inputEquals(state: CalculatorState): CalculatorState {
  if (state.pendingOperator !== null && state.accumulator !== null) {
    const rightOperand = currentValueFor(state);
    const result = evaluateBinaryOperation(state.pendingOperator, state.accumulator, rightOperand);
    if (result === null) {
      return errorState(state);
    }
    return withDisplay({
      ...state,
      accumulator: null,
      pendingOperator: null,
      currentEntry: "0",
      entering: false,
      displayedValue: result,
      awaitingOperand: false,
      lastOperation: { operator: state.pendingOperator, rightOperand },
      justEvaluated: true,
    });
  }

  if (state.lastOperation !== null) {
    const result = evaluateBinaryOperation(state.lastOperation.operator, state.displayedValue, state.lastOperation.rightOperand);
    if (result === null) {
      return errorState(state);
    }
    return withDisplay({
      ...state,
      currentEntry: "0",
      entering: false,
      displayedValue: result,
      awaitingOperand: false,
      justEvaluated: true,
    });
  }

  if (state.entering) {
    return withDisplay({
      ...state,
      currentEntry: "0",
      entering: false,
      displayedValue: currentValueFor(state),
      awaitingOperand: false,
      justEvaluated: true,
    });
  }

  return state;
}

function applyUnaryOperation(state: CalculatorState, operation: (value: number) => number | null): CalculatorState {
  const result = operation(currentValueFor(state));
  if (result === null || !Number.isFinite(result)) {
    return errorState(state);
  }
  return withDisplay({
    ...state,
    currentEntry: "0",
    entering: false,
    displayedValue: normalizeResult(result),
    awaitingOperand: false,
    justEvaluated: false,
  });
}

function toggleSign(state: CalculatorState): CalculatorState {
  if (state.entering) {
    const currentEntry = state.currentEntry.startsWith("-") ? state.currentEntry.slice(1) : `-${state.currentEntry}`;
    return withDisplay({ ...state, currentEntry, displayedValue: numberFromEntry(currentEntry), awaitingOperand: false, justEvaluated: false });
  }
  const displayedValue = normalizeResult(-state.displayedValue);
  return withDisplay({ ...state, displayedValue, awaitingOperand: false, justEvaluated: false });
}

function applyPercent(state: CalculatorState): CalculatorState {
  const currentValue = currentValueFor(state);
  let result: number;
  if (state.pendingOperator === "+" || state.pendingOperator === "-") {
    result = (state.accumulator ?? 0) * currentValue / 100;
  } else {
    result = currentValue / 100;
  }
  return withDisplay({
    ...state,
    currentEntry: "0",
    entering: false,
    displayedValue: normalizeResult(result),
    awaitingOperand: false,
    justEvaluated: false,
  });
}

function clearEntry(state: CalculatorState): CalculatorState {
  return withDisplay({
    ...state,
    currentEntry: "0",
    entering: false,
    displayedValue: 0,
    awaitingOperand: false,
    justEvaluated: false,
  });
}

function backspace(state: CalculatorState): CalculatorState {
  if (!state.entering) {
    return state;
  }

  let currentEntry = state.currentEntry.slice(0, -1);
  if (currentEntry === "" || currentEntry === "-") {
    currentEntry = state.currentEntry.startsWith("-") ? "-0" : "0";
  }
  if (currentEntry === "-0" && !state.currentEntry.startsWith("-")) {
    currentEntry = "0";
  }
  return withDisplay({ ...state, currentEntry, displayedValue: numberFromEntry(currentEntry), awaitingOperand: false, justEvaluated: false });
}

function evaluateBinaryOperation(operator: CalculatorBinaryOperator, left: number, right: number): number | null {
  let result: number;
  switch (operator) {
    case "+":
      result = left + right;
      break;
    case "-":
      result = left - right;
      break;
    case "×":
      result = left * right;
      break;
    case "÷":
      if (right === 0) {
        return null;
      }
      result = left / right;
      break;
  }
  return Number.isFinite(result) ? normalizeResult(result) : null;
}

function currentValueFor(state: CalculatorState): number {
  return state.entering ? numberFromEntry(state.currentEntry) : state.displayedValue;
}

function numberFromEntry(entry: string): number {
  if (entry === "-" || entry === "" || entry === "." || entry === "-.") {
    return 0;
  }
  const parsed = Number(entry);
  return Number.isFinite(parsed) ? parsed : 0;
}

function withDisplay(state: Omit<CalculatorState, "display"> & { readonly display?: string }): CalculatorState {
  const display = state.error
    ? "Error"
    : state.entering
      ? localizeDecimalSeparator(state.currentEntry, state.locale)
      : displayCalculatorValue(state.displayedValue, state.locale);
  return { ...state, display };
}

function errorState(state: CalculatorState): CalculatorState {
  return withDisplay({
    ...state,
    error: true,
    accumulator: null,
    pendingOperator: null,
    currentEntry: "0",
    entering: false,
    displayedValue: 0,
    awaitingOperand: false,
    lastOperation: null,
    justEvaluated: false,
  });
}

function normalizeResult(value: number): number {
  if (Object.is(value, -0) || Math.abs(value) < 5e-15) {
    return 0;
  }
  const exponent = Math.floor(Math.log10(Math.abs(value)));
  const factor = 10 ** (RESULT_SIGNIFICANT_DIGITS - exponent - 1);
  if (!Number.isFinite(factor) || factor === 0) {
    return value;
  }
  return Math.round(value * factor) / factor;
}

function fractionDigitsFor(absoluteValue: number): number {
  const exponent = Math.floor(Math.log10(absoluteValue));
  return Math.max(0, MAX_SIGNIFICANT_DIGITS - exponent - 1);
}

function normalizeFixed(value: string): string {
  if (!value.includes(".")) {
    return value;
  }
  return value.replace(/\.0+$/, "").replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "");
}

function normalizeScientific(value: string): string {
  const [mantissa, exponent = "0"] = value.split("e");
  const normalizedMantissa = normalizeFixed(mantissa ?? "0");
  const normalizedExponent = String(Number(exponent));
  return `${normalizedMantissa}e${normalizedExponent}`;
}

function localizeDecimalSeparator(value: string, locale: CalculatorLocale): string {
  return locale === "fr" ? value.replace(".", ",") : value;
}

function isDigitKey(key: CalculatorKey): key is CalculatorDigitKey {
  return DIGIT_KEYS.has(key);
}

function isBinaryOperatorKey(key: CalculatorKey): key is CalculatorBinaryOperator {
  return BINARY_OPERATOR_KEYS.has(key);
}
