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

export interface CalculatorSpokenDisplay {
  readonly en: string;
  readonly fr: string;
}

export interface CalculatorDisplayValue {
  readonly mantissa: string | null;
  readonly exponent: number | null;
  readonly isNegative: boolean;
  readonly isError: boolean;
  readonly visual: string;
  readonly spoken: CalculatorSpokenDisplay;
}

export interface CalculatorState {
  readonly locale: CalculatorLocale;
  readonly display: string;
  readonly displayValue: CalculatorDisplayValue;
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

interface DecimalParts {
  readonly mantissa: string;
  readonly exponent: number;
  readonly isNegative: boolean;
  readonly scientific: boolean;
}

interface RoundedDecimal {
  readonly digits: string;
  readonly decimalExponent: number;
  readonly isNegative: boolean;
}

const DIGIT_KEYS = new Set<CalculatorKey>(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]);
const BINARY_OPERATOR_KEYS = new Set<CalculatorKey>(["+", "-", "×", "÷"]);
const MAX_SIGNIFICANT_DIGITS = 12;
const MAX_ENTRY_LENGTH = 15;
const RESULT_SIGNIFICANT_DIGITS = 15;
const CANCELLATION_TOLERANCE = 1e-14;
const MIN_NONZERO_ABSOLUTE_VALUE = 1e-99;
const MAX_ABSOLUTE_VALUE = 1e100;
const TYPOGRAPHIC_MINUS = "−";
const SCIENTIFIC_MANTISSA_DIGITS = 10;
const POWERS_OF_TEN: readonly number[] = Object.freeze(Array.from({ length: 121 }, (_, index) => Number(`1e${index}`)));

export function createCalculatorState(options: CalculatorOptions = {}): CalculatorState {
  return withDisplay({
    locale: options.locale ?? "en",
    display: "0",
    displayValue: zeroDisplayValue(),
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
    if (key === "C/CE") {
      return createCalculatorState({ locale: state.locale });
    }
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
  return displayValueForNumber(value, locale).visual;
}

export function displayCalculatorValueDetails(value: number, locale: CalculatorLocale = "en"): CalculatorDisplayValue {
  return displayValueForNumber(value, locale);
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
  if (entryExceedsLimits(entry)) {
    return base;
  }
  const displayedValue = numberFromEntry(entry);
  if (!Number.isFinite(displayedValue)) {
    return errorState(base);
  }
  return withDisplay({
    ...base,
    currentEntry: entry,
    entering: true,
    displayedValue,
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
  if (entryExceedsLimits(currentEntry)) {
    return base;
  }
  return withDisplay({ ...base, currentEntry, displayedValue: numberFromEntry(currentEntry), awaitingOperand: false, justEvaluated: false });
}

function inputBinaryOperator(state: CalculatorState, operator: CalculatorBinaryOperator): CalculatorState {
  const currentValue = currentValueFor(state);
  if (!Number.isFinite(currentValue)) {
    return errorState(state);
  }
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
  const normalizedResult = result === null ? null : normalizeResult(result);
  if (normalizedResult === null) {
    return errorState(state);
  }
  return withDisplay({
    ...state,
    currentEntry: "0",
    entering: false,
    displayedValue: normalizedResult,
    awaitingOperand: false,
    lastOperation: null,
    justEvaluated: false,
  });
}

function toggleSign(state: CalculatorState): CalculatorState {
  if (state.entering) {
    const currentEntry = state.currentEntry.startsWith("-") ? state.currentEntry.slice(1) : `-${state.currentEntry}`;
    return withDisplay({ ...state, currentEntry, displayedValue: numberFromEntry(currentEntry), awaitingOperand: false, lastOperation: null, justEvaluated: false });
  }
  const displayedValue = normalizeResult(-state.displayedValue);
  if (displayedValue === null) {
    return errorState(state);
  }
  return withDisplay({ ...state, displayedValue, awaitingOperand: false, lastOperation: null, justEvaluated: false });
}

function applyPercent(state: CalculatorState): CalculatorState {
  const currentValue = currentValueFor(state);
  let result: number;
  if (state.pendingOperator === "+" || state.pendingOperator === "-") {
    result = (state.accumulator ?? 0) * currentValue / 100;
  } else {
    result = currentValue / 100;
  }
  const normalizedResult = normalizeResult(result);
  if (normalizedResult === null) {
    return errorState(state);
  }
  return withDisplay({
    ...state,
    currentEntry: "0",
    entering: false,
    displayedValue: normalizedResult,
    awaitingOperand: false,
    lastOperation: null,
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
    lastOperation: null,
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
  return withDisplay({ ...state, currentEntry, displayedValue: numberFromEntry(currentEntry), awaitingOperand: false, justEvaluated: false });
}

function evaluateBinaryOperation(operator: CalculatorBinaryOperator, left: number, right: number): number | null {
  let result: number;
  switch (operator) {
    case "+":
      result = cancelIfSubtractiveNoise(left + right, left, right);
      break;
    case "-":
      result = cancelIfSubtractiveNoise(left - right, left, right);
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
  return normalizeResult(result);
}

function cancelIfSubtractiveNoise(result: number, left: number, right: number): number {
  const tolerance = Math.max(Math.abs(left), Math.abs(right)) * CANCELLATION_TOLERANCE;
  return Math.abs(result) <= tolerance ? 0 : result;
}

function currentValueFor(state: CalculatorState): number {
  return state.entering ? numberFromEntry(state.currentEntry) : state.displayedValue;
}

function numberFromEntry(entry: string): number {
  if (entry === "-" || entry === "" || entry === "." || entry === "-.") {
    return 0;
  }
  const parsed = Number(entry);
  if (!Number.isFinite(parsed)) {
    return Number.POSITIVE_INFINITY;
  }
  if (Math.abs(parsed) >= MAX_ABSOLUTE_VALUE) {
    return Number.POSITIVE_INFINITY;
  }
  if (parsed !== 0 && Math.abs(parsed) < MIN_NONZERO_ABSOLUTE_VALUE) {
    return 0;
  }
  return parsed;
}

function withDisplay(state: Omit<CalculatorState, "display" | "displayValue"> & { readonly display?: string; readonly displayValue?: CalculatorDisplayValue }): CalculatorState {
  const display = state.error
    ? "Error"
    : state.entering
      ? visualEntry(state.currentEntry, state.locale)
      : displayCalculatorValue(state.displayedValue, state.locale);
  const displayValue = state.error
    ? errorDisplayValue(display)
    : state.entering
      ? displayValueForEntry(state.currentEntry, state.locale, display)
      : displayValueForNumber(state.displayedValue, state.locale);
  return { ...state, display, displayValue };
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

function normalizeResult(value: number): number | null {
  if (!Number.isFinite(value)) {
    return null;
  }
  if (Object.is(value, -0) || value === 0) {
    return 0;
  }
  if (Math.abs(value) >= MAX_ABSOLUTE_VALUE) {
    return null;
  }
  if (Math.abs(value) < MIN_NONZERO_ABSOLUTE_VALUE) {
    return 0;
  }
  const rounded = roundToSignificantDigits(value, RESULT_SIGNIFICANT_DIGITS);
  if (!Number.isFinite(rounded) || Math.abs(rounded) >= MAX_ABSOLUTE_VALUE) {
    return null;
  }
  if (rounded !== 0 && Math.abs(rounded) < MIN_NONZERO_ABSOLUTE_VALUE) {
    return 0;
  }
  return Object.is(rounded, -0) ? 0 : rounded;
}

function roundToSignificantDigits(value: number, significantDigits: number): number {
  const absoluteValue = Math.abs(value);
  if (!Number.isFinite(absoluteValue) || absoluteValue === 0) {
    return value;
  }
  const exponent = Math.floor(Math.log10(absoluteValue));
  const shift = significantDigits - exponent - 1;
  const scaled = shift >= 0
    ? absoluteValue * powerOfTen(shift)
    : absoluteValue / powerOfTen(-shift);
  if (!Number.isFinite(scaled)) {
    return value;
  }
  const roundedCoefficient = Math.floor(scaled + 0.5);
  return Math.sign(value) * (shift >= 0
    ? roundedCoefficient / powerOfTen(shift)
    : roundedCoefficient * powerOfTen(-shift));
}

function displayValueForNumber(value: number, locale: CalculatorLocale): CalculatorDisplayValue {
  const normalizedValue = normalizeDisplayValue(value);
  if (normalizedValue === null) {
    return errorDisplayValue("Error");
  }
  const parts = decimalParts(normalizedValue);
  const visual = localizeDecimalSeparator(visualFromParts(parts), locale);
  return displayValueFromParts(parts, visual);
}

function displayValueForEntry(entry: string, _locale: CalculatorLocale, visual: string): CalculatorDisplayValue {
  const isNegative = entry.startsWith("-");
  const unsignedEntry = isNegative ? entry.slice(1) : entry;
  const mantissa = unsignedEntry === "" || unsignedEntry === "." ? "0" : unsignedEntry;
  return {
    mantissa,
    exponent: 0,
    isNegative,
    isError: false,
    visual,
    spoken: spokenEntry(entry),
  };
}

function zeroDisplayValue(): CalculatorDisplayValue {
  return {
    mantissa: "0",
    exponent: 0,
    isNegative: false,
    isError: false,
    visual: "0",
    spoken: { en: "0", fr: "0" },
  };
}

function errorDisplayValue(visual: string): CalculatorDisplayValue {
  return {
    mantissa: null,
    exponent: null,
    isNegative: false,
    isError: true,
    visual,
    spoken: { en: "Error", fr: "Erreur" },
  };
}

function normalizeDisplayValue(value: number): number | null {
  if (!Number.isFinite(value) || Math.abs(value) >= MAX_ABSOLUTE_VALUE) {
    return null;
  }
  if (Object.is(value, -0) || value === 0 || Math.abs(value) < MIN_NONZERO_ABSOLUTE_VALUE) {
    return 0;
  }
  return value;
}

function decimalParts(value: number): DecimalParts {
  const normalizedValue = normalizeDisplayValue(value);
  if (normalizedValue === null || normalizedValue === 0) {
    return { mantissa: "0", exponent: 0, isNegative: false, scientific: false };
  }

  const roundedForClassification = roundedDecimal(normalizedValue, MAX_SIGNIFICANT_DIGITS);
  const exponent = scientificExponent(roundedForClassification);
  if (exponent >= 12 || exponent < -9) {
    return scientificDecimalParts(normalizedValue);
  }

  if (exponent >= -3) {
    const zerosBeforeFirstSignificantDigit = exponent < 0 ? -exponent - 1 : 0;
    const fixedSignificantDigits = Math.min(MAX_SIGNIFICANT_DIGITS, MAX_SIGNIFICANT_DIGITS - zerosBeforeFirstSignificantDigit);
    return fixedDecimalParts(normalizedValue, fixedSignificantDigits);
  }

  const zerosBeforeFirstSignificantDigit = -exponent - 1;
  if (zerosBeforeFirstSignificantDigit + roundedForClassification.digits.length <= MAX_SIGNIFICANT_DIGITS) {
    return fixedDecimalParts(normalizedValue, MAX_SIGNIFICANT_DIGITS);
  }

  return scientificDecimalParts(normalizedValue);
}

function fixedDecimalParts(value: number, significantDigits: number): DecimalParts {
  const rounded = roundedDecimal(value, significantDigits);
  return {
    mantissa: fixedFromDigits(rounded.digits, rounded.decimalExponent),
    exponent: 0,
    isNegative: rounded.isNegative,
    scientific: false,
  };
}

function scientificDecimalParts(value: number): DecimalParts {
  const rounded = roundedDecimal(value, SCIENTIFIC_MANTISSA_DIGITS);
  return {
    mantissa: mantissaFromDigits(rounded.digits),
    exponent: scientificExponent(rounded),
    isNegative: rounded.isNegative,
    scientific: true,
  };
}

function roundedDecimal(value: number, significantDigits: number): RoundedDecimal {
  const isNegative = value < 0;
  const absoluteValue = Math.abs(value);
  if (!Number.isFinite(absoluteValue) || absoluteValue === 0) {
    return { digits: "0", decimalExponent: 0, isNegative: false };
  }

  const exponent = Math.floor(Math.log10(absoluteValue));
  const shift = significantDigits - exponent - 1;
  const scaled = shift >= 0
    ? absoluteValue * powerOfTen(shift)
    : absoluteValue / powerOfTen(-shift);
  if (!Number.isFinite(scaled)) {
    return { digits: "0", decimalExponent: 0, isNegative: false };
  }

  let coefficient = BigInt(Math.floor(scaled + 0.5));
  let decimalExponent = -shift;
  const overflow = 10n ** BigInt(significantDigits);
  if (coefficient === 0n) {
    return { digits: "0", decimalExponent: 0, isNegative: false };
  }
  if (coefficient >= overflow) {
    coefficient /= 10n;
    decimalExponent += 1;
  }

  const coefficientDigits = coefficient.toString();
  const digits = trimTrailingZeros(coefficientDigits, decimalExponent);
  decimalExponent += coefficientDigits.length - digits.length;
  return { digits, decimalExponent, isNegative };
}

function scientificExponent(rounded: RoundedDecimal): number {
  return rounded.digits.length + rounded.decimalExponent - 1;
}

function trimTrailingZeros(digits: string, decimalExponent: number): string {
  let result = digits;
  while (decimalExponent < 0 && result.length > 1 && result.endsWith("0")) {
    result = result.slice(0, -1);
    decimalExponent += 1;
  }
  return result;
}

function mantissaFromDigits(digits: string): string {
  const raw = digits.length === 1 ? digits : `${digits[0]}.${digits.slice(1)}`;
  return normalizeDecimalString(raw);
}

function fixedFromDigits(digits: string, decimalExponent: number): string {
  if (decimalExponent >= 0) {
    return `${digits}${"0".repeat(decimalExponent)}`;
  }
  const pointIndex = digits.length + decimalExponent;
  if (pointIndex > 0) {
    return normalizeDecimalString(`${digits.slice(0, pointIndex)}.${digits.slice(pointIndex)}`);
  }
  return normalizeDecimalString(`0.${"0".repeat(-pointIndex)}${digits}`);
}

function normalizeDecimalString(value: string): string {
  if (!value.includes(".")) {
    return value;
  }
  let result = value;
  while (result.endsWith("0")) {
    result = result.slice(0, -1);
  }
  return result.endsWith(".") ? result.slice(0, -1) : result;
}

function visualFromParts(parts: DecimalParts): string {
  if (parts.mantissa === "0") {
    return "0";
  }
  const sign = parts.isNegative ? TYPOGRAPHIC_MINUS : "";
  if (parts.scientific) {
    const exponent = parts.exponent < 0 ? `${TYPOGRAPHIC_MINUS}${Math.abs(parts.exponent)}` : String(parts.exponent);
    return `${sign}${parts.mantissa}e${exponent}`;
  }
  return `${sign}${parts.mantissa}`;
}

function displayValueFromParts(parts: DecimalParts, visual: string): CalculatorDisplayValue {
  return {
    mantissa: parts.mantissa,
    exponent: parts.exponent,
    isNegative: parts.isNegative,
    isError: false,
    visual,
    spoken: spokenDisplay(parts),
  };
}

function spokenDisplay(parts: DecimalParts): CalculatorSpokenDisplay {
  const englishSign = parts.isNegative ? "minus " : "";
  const frenchSign = parts.isNegative ? "moins " : "";
  if (parts.scientific) {
    const englishExponentSign = parts.exponent < 0 ? "minus " : "";
    const frenchExponentSign = parts.exponent < 0 ? "moins " : "";
    return {
      en: `${englishSign}${parts.mantissa} times ten to the ${englishExponentSign}${Math.abs(parts.exponent)}`,
      fr: `${frenchSign}${parts.mantissa.replace(".", ",")} fois dix puissance ${frenchExponentSign}${Math.abs(parts.exponent)}`,
    };
  }
  return {
    en: `${englishSign}${parts.mantissa}`,
    fr: `${frenchSign}${parts.mantissa.replace(".", ",")}`,
  };
}

function spokenEntry(entry: string): CalculatorSpokenDisplay {
  const isNegative = entry.startsWith("-");
  const unsignedEntry = isNegative ? entry.slice(1) : entry;
  const spokenValue = unsignedEntry === "" || unsignedEntry === "." ? "0" : unsignedEntry;
  return {
    en: `${isNegative ? "minus " : ""}${spokenValue}`,
    fr: `${isNegative ? "moins " : ""}${spokenValue.replace(".", ",")}`,
  };
}

function visualEntry(entry: string, locale: CalculatorLocale): string {
  const visual = entry.startsWith("-") ? `${TYPOGRAPHIC_MINUS}${entry.slice(1)}` : entry;
  return localizeDecimalSeparator(visual, locale);
}

function localizeDecimalSeparator(value: string, locale: CalculatorLocale): string {
  return locale === "fr" ? value.replace(".", ",") : value;
}

function entryExceedsLimits(entry: string): boolean {
  const unsignedEntry = entry.startsWith("-") ? entry.slice(1) : entry;
  return unsignedEntry.length > MAX_ENTRY_LENGTH || significantDigitCount(entry) > MAX_SIGNIFICANT_DIGITS;
}

function powerOfTen(exponent: number): number {
  return POWERS_OF_TEN[exponent] ?? Number.POSITIVE_INFINITY;
}

function significantDigitCount(entry: string): number {
  let count = 0;
  let foundNonZero = false;
  for (const character of entry) {
    if (character < "0" || character > "9") {
      continue;
    }
    if (!foundNonZero) {
      if (character === "0") {
        continue;
      }
      foundNonZero = true;
    }
    count += 1;
  }
  return count;
}

function isDigitKey(key: CalculatorKey): key is CalculatorDigitKey {
  return DIGIT_KEYS.has(key);
}

function isBinaryOperatorKey(key: CalculatorKey): key is CalculatorBinaryOperator {
  return BINARY_OPERATOR_KEYS.has(key);
}
