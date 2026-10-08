export type MorseProfileName = "isedParis" | "ric1Literal";

export type MorseSymbolKind = "dot" | "dash" | "intraCharacterGap" | "interCharacterGap" | "wordGap";
export type MorseOutputMode = "audio" | "visualBeacon" | "visualTape" | "haptics";

export interface MorseTimingProfile {
  readonly name?: MorseProfileName;
  readonly characterWpm: number;
  readonly effectiveWpm: number;
  readonly dotSeconds: number;
  readonly dashSeconds: number;
  readonly intraCharacterGapSeconds: number;
  readonly interCharacterGapSeconds: number;
  readonly wordGapSeconds: number;
}

export interface TimedMorseSymbol {
  readonly kind: MorseSymbolKind;
  readonly startSeconds: number;
  readonly durationSeconds: number;
  readonly character?: string;
}

export interface TimedMorseSequence {
  readonly input: string;
  readonly normalizedText: string;
  readonly profile: MorseTimingProfile;
  readonly symbols: readonly TimedMorseSymbol[];
  readonly totalDurationSeconds: number;
}

export interface MorseSignalEvent {
  readonly kind: "on" | "off";
  readonly atSeconds: number;
  readonly character: string;
  readonly symbolKind: "dot" | "dash";
}

export interface MorseTapeToken {
  readonly token: "." | "-";
  readonly revealAtSeconds: number;
  readonly character: string;
}

export interface MorseHapticEvent {
  readonly startSeconds: number;
  readonly durationSeconds: number;
  readonly character: string;
  readonly symbolKind: "dot" | "dash";
}

export interface MorseRGB {
  readonly red: number;
  readonly green: number;
  readonly blue: number;
}

export interface MorseFlashBeaconPalette {
  readonly resting: MorseRGB;
  readonly active: MorseRGB;
  readonly usesSaturatedRed: boolean;
}

export interface MorseFlashSafetyInput {
  readonly flashAreaCssPixels: number;
  readonly flashesPerSecond: number;
  readonly darkerRelativeLuminance: number;
  readonly lighterRelativeLuminance: number;
  readonly usesSaturatedRed: boolean;
}

export interface MorseFlashSafetyResult {
  readonly safe: boolean;
  readonly reason: "below-area-threshold" | "within-three-flashes" | "below-general-threshold" | "area-too-large" | "saturated-red" | "luminance-too-high";
  readonly luminanceDelta: number;
  readonly maxAreaCssPixels: number;
}

export interface InvalidMorseCharacter {
  readonly character: string;
  /** Zero-based Unicode code point index in the input string. */
  readonly index: number;
}

export interface ValidationResult {
  readonly valid: boolean;
  readonly invalidCharacters: readonly InvalidMorseCharacter[];
}

export interface WeightCount {
  readonly weightedCharacters: number;
  readonly unweightedCharacters: number;
}

export interface MorseExamScore {
  readonly errors: number;
  readonly wrong: number;
  readonly missing: number;
  readonly inserted: number;
  readonly passed: boolean;
  readonly markPercent: number;
  readonly expectedLength: number;
  readonly receivedLength: number;
}

export type MorseCopyDiffKind = "match" | "wrong" | "missing" | "inserted";

export interface MorseCopyDiffOperation {
  readonly kind: MorseCopyDiffKind;
  readonly expected?: string;
  readonly received?: string;
}

export interface MorseCopyDiff {
  readonly score: MorseExamScore;
  readonly operations: readonly MorseCopyDiffOperation[];
}

export interface MorseExamTextOptions {
  readonly seed?: string;
  readonly profile?: MorseTimingProfile;
  readonly minWeightedCharacters?: number;
  readonly minDurationSeconds?: number;
}

export interface MorseExamText {
  readonly text: string;
  readonly normalizedText: string;
  readonly weightedCharacters: number;
  readonly unweightedCharacters: number;
  readonly durationSeconds: number;
  readonly profile: MorseTimingProfile;
}

export type MorseKeyElement = "." | "-";
export type MorseDecodedKind = "character" | "errorSignal" | "unknown";

export interface MorseKeyTimingSample {
  readonly element: MorseKeyElement;
  readonly durationSeconds: number;
  readonly expectedSeconds: number;
  readonly ratioToExpected: number;
}

export interface MorseDecodedCharacter {
  readonly kind: MorseDecodedKind;
  readonly elements: string;
  readonly character?: string;
}

export interface MorseCharacterTimingFeedback {
  readonly elements: string;
  readonly decoded: MorseDecodedCharacter;
  readonly dotDashRatio: number | null;
  readonly timingConsistencyPercent: number;
  readonly averageRatioToExpected: number;
}

export interface MorseSendingScore {
  readonly diff: MorseCopyDiff;
  readonly completedWithinTime: boolean;
  readonly passed: boolean;
  readonly markPercent: number;
}

export const MORSE_ERROR_SIGNAL_DOTS = 8;
export const MORSE_FLASH_REFERENCE_WIDTH_CSS_PIXELS = 341;
export const MORSE_FLASH_REFERENCE_HEIGHT_CSS_PIXELS = 256;
export const MORSE_FLASH_MAX_AREA_CSS_PIXELS = (MORSE_FLASH_REFERENCE_WIDTH_CSS_PIXELS * MORSE_FLASH_REFERENCE_HEIGHT_CSS_PIXELS) / 4;
export const MORSE_BEACON_AREA_CSS_PIXELS = 112 * 112;
export const MORSE_BEACON_RESTING_MIX = 0;
export const MORSE_BEACON_ACTIVE_MIX = 1;
export const MORSE_LIGHT_PAPER_INSET_RGB = Object.freeze({ red: 0xef / 255, green: 0xe3 / 255, blue: 0xcb / 255 });
export const MORSE_DARK_PAPER_INSET_RGB = Object.freeze({ red: 0x18 / 255, green: 0x14 / 255, blue: 0x10 / 255 });
export const MORSE_LIGHT_ACCENT_RGB = Object.freeze({ red: 0xa5 / 255, green: 0x3a / 255, blue: 0x2a / 255 });
export const MORSE_DARK_ACCENT_RGB = Object.freeze({ red: 0xff / 255, green: 0x8a / 255, blue: 0x70 / 255 });

export const MORSE_CODE_TABLE = Object.freeze({
  A: ".-",
  B: "-...",
  C: "-.-.",
  D: "-..",
  E: ".",
  F: "..-.",
  G: "--.",
  H: "....",
  I: "..",
  J: ".---",
  K: "-.-",
  L: ".-..",
  M: "--",
  N: "-.",
  O: "---",
  P: ".--.",
  Q: "--.-",
  R: ".-.",
  S: "...",
  T: "-",
  U: "..-",
  V: "...-",
  W: ".--",
  X: "-..-",
  Y: "-.--",
  Z: "--..",
  "0": "-----",
  "1": ".----",
  "2": "..---",
  "3": "...--",
  "4": "....-",
  "5": ".....",
  "6": "-....",
  "7": "--...",
  "8": "---..",
  "9": "----.",
  ".": ".-.-.-",
  ",": "--..--",
  "?": "..--..",
  "-": "-....-",
  "/": "-..-.",
} as const);

export const ALLOWED_RIC1_CHARACTERS = Object.freeze(Object.keys(MORSE_CODE_TABLE));

const reverseMorseCodeTable = new Map<string, string>(Object.entries(MORSE_CODE_TABLE).map(([character, elements]) => [elements, character]));
const allowedCharacters = new Set<string>(ALLOWED_RIC1_CHARACTERS);
const punctuationAndFigures = new Set<string>(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", ",", "?", "-", "/"]);
const morseWhitespaceCodePoints = new Set<number>([
  0x0009,
  0x000a,
  0x000b,
  0x000c,
  0x000d,
  0x0020,
  0x0085,
  0x00a0,
  0x1680,
  0x2000,
  0x2001,
  0x2002,
  0x2003,
  0x2004,
  0x2005,
  0x2006,
  0x2007,
  0x2008,
  0x2009,
  0x200a,
  0x2028,
  0x2029,
  0x202f,
  0x205f,
  0x3000,
  0xfeff,
]);

export const MORSE_TIMING_PROFILES = Object.freeze({
  isedParis: Object.freeze({ ...farnsworthTiming({ characterWpm: 12, effectiveWpm: 5 }), name: "isedParis" as const }),
  ric1Literal: Object.freeze({
    name: "ric1Literal" as const,
    characterWpm: 12,
    effectiveWpm: 60 / 7.6,
    dotSeconds: 0.1,
    dashSeconds: 0.3,
    intraCharacterGapSeconds: 0.1,
    interCharacterGapSeconds: 0.7,
    wordGapSeconds: 1.7,
  }),
});

const EXAM_SENTENCE_CORPUS = Object.freeze([
  "THE RADIO OPERATOR CHECKS THE NORTH ANTENNA.",
  "WEATHER REPORTS WILL BE SHORT AND CLEAR.",
  "STATION VE3ABC COPIES YOUR SIGNAL 599.",
  "QTH IS OTTAWA AND POWER IS 25 WATTS.",
  "PORTABLE STATION VE7XYZ CALLS CQ AGAIN.",
  "THE MESSAGE NUMBER IS 42 FOR FIELD DAY.",
  "QSJ 1962 WAS LOGGED AFTER THE CONTACT.",
  "PLEASE SEND NAME, QTH, AND RST AGAIN.",
  "MOBILE UNIT CHECKS IN FROM ROAD 17.",
  "FORECAST PERIODS WILL BE SHORTENED TODAY.",
  "CALL VE2HAM/PORTABLE AFTER THE NET.",
  "QSL THE TEST MESSAGE BEFORE NOON.",
]);

const DEFAULT_EXAM_MIN_WEIGHTED_CHARACTERS = 75;
const DEFAULT_EXAM_MIN_DURATION_SECONDS = 180;

export class MorseValidationError extends Error {
  readonly invalidCharacters: readonly InvalidMorseCharacter[];

  constructor(invalidCharacters: readonly InvalidMorseCharacter[]) {
    super(`Text contains characters outside RIC-1 section 8.2: ${invalidCharacters.map((entry) => entry.character).join(" ")}`);
    this.name = "MorseValidationError";
    this.invalidCharacters = invalidCharacters;
  }
}

export function farnsworthTiming(input: { readonly characterWpm: number; readonly effectiveWpm: number }): MorseTimingProfile {
  const { characterWpm } = input;
  const effectiveWpm = Math.min(input.effectiveWpm, characterWpm);
  if (!Number.isFinite(characterWpm) || characterWpm <= 0) {
    throw new RangeError("characterWpm must be a positive finite number");
  }
  if (!Number.isFinite(input.effectiveWpm) || input.effectiveWpm <= 0) {
    throw new RangeError("effectiveWpm must be a positive finite number");
  }

  const dotSeconds = 1.2 / characterWpm;
  const farnsworthAggregateGapSeconds = (60 * characterWpm - 37.2 * effectiveWpm) / (effectiveWpm * characterWpm);
  return {
    characterWpm,
    effectiveWpm,
    dotSeconds,
    dashSeconds: 3 * dotSeconds,
    intraCharacterGapSeconds: dotSeconds,
    interCharacterGapSeconds: (3 * farnsworthAggregateGapSeconds) / 19,
    wordGapSeconds: (7 * farnsworthAggregateGapSeconds) / 19,
  };
}

export function profileForName(name: MorseProfileName): MorseTimingProfile {
  return MORSE_TIMING_PROFILES[name];
}

export function validateMorseText(text: string): ValidationResult {
  const invalidCharacters: InvalidMorseCharacter[] = [];
  Array.from(text).forEach((character, index) => {
    if (isWhitespace(character)) {
      return;
    }
    const normalized = normalizeCharacter(character);
    if (normalized === undefined || !allowedCharacters.has(normalized)) {
      invalidCharacters.push({ character, index });
    }
  });
  return { valid: invalidCharacters.length === 0, invalidCharacters };
}

export function canonicalMorseCharacters(text: string): string[] {
  const invalidCharacters = validateMorseText(text).invalidCharacters;
  if (invalidCharacters.length > 0) {
    throw new MorseValidationError(invalidCharacters);
  }
  return Array.from(text).flatMap((character) => {
    if (isWhitespace(character)) {
      return [];
    }
    return normalizeCharacter(character) ?? [];
  });
}

export function weightedCharacterCount(text: string): WeightCount {
  const characters = canonicalMorseCharacters(text);
  return {
    weightedCharacters: characters.reduce((total, character) => total + (punctuationAndFigures.has(character) ? 2 : 1), 0),
    unweightedCharacters: characters.length,
  };
}

export function textToTimedMorse(text: string, profile: MorseTimingProfile = MORSE_TIMING_PROFILES.isedParis): TimedMorseSequence {
  const words = canonicalMorseWords(text);
  const symbols: TimedMorseSymbol[] = [];
  let cursor = 0;

  for (const word of words) {
    word.forEach((character, characterIndex) => {
      const code = MORSE_CODE_TABLE[character as keyof typeof MORSE_CODE_TABLE];
      Array.from(code).forEach((element, elementIndex) => {
        const kind: MorseSymbolKind = element === "." ? "dot" : "dash";
        const durationSeconds = kind === "dot" ? profile.dotSeconds : profile.dashSeconds;
        symbols.push({ kind, startSeconds: cursor, durationSeconds, character });
        cursor += durationSeconds;

        if (elementIndex < code.length - 1) {
          symbols.push({
            kind: "intraCharacterGap",
            startSeconds: cursor,
            durationSeconds: profile.intraCharacterGapSeconds,
            character,
          });
          cursor += profile.intraCharacterGapSeconds;
        }
      });

      symbols.push({
        kind: characterIndex === word.length - 1 ? "wordGap" : "interCharacterGap",
        startSeconds: cursor,
        durationSeconds: characterIndex === word.length - 1 ? profile.wordGapSeconds : profile.interCharacterGapSeconds,
      });
      cursor += characterIndex === word.length - 1 ? profile.wordGapSeconds : profile.interCharacterGapSeconds;
    });
  }

  return {
    input: text,
    normalizedText: words.map((word) => word.join("")).join(" "),
    profile,
    symbols,
    totalDurationSeconds: cursor,
  };
}

export function morseSignalEvents(sequence: TimedMorseSequence): MorseSignalEvent[] {
  return sequence.symbols.flatMap((symbol) => {
    if ((symbol.kind !== "dot" && symbol.kind !== "dash") || symbol.character === undefined) {
      return [];
    }
    return [
      { kind: "on" as const, atSeconds: symbol.startSeconds, character: symbol.character, symbolKind: symbol.kind },
      { kind: "off" as const, atSeconds: symbol.startSeconds + symbol.durationSeconds, character: symbol.character, symbolKind: symbol.kind },
    ];
  });
}

export function morseTapeTokens(sequence: TimedMorseSequence): MorseTapeToken[] {
  return sequence.symbols.flatMap((symbol) => {
    if ((symbol.kind !== "dot" && symbol.kind !== "dash") || symbol.character === undefined) {
      return [];
    }
    return [{ token: symbol.kind === "dot" ? "." as const : "-" as const, revealAtSeconds: symbol.startSeconds, character: symbol.character }];
  });
}

export function morseHapticEvents(sequence: TimedMorseSequence): MorseHapticEvent[] {
  return sequence.symbols.flatMap((symbol) => {
    if ((symbol.kind !== "dot" && symbol.kind !== "dash") || symbol.character === undefined) {
      return [];
    }
    return [{ startSeconds: symbol.startSeconds, durationSeconds: symbol.durationSeconds, character: symbol.character, symbolKind: symbol.kind }];
  });
}

export function maxMorseFlashesPerSecond(events: readonly MorseSignalEvent[]): number {
  const onTimes = events.filter((event) => event.kind === "on").map((event) => event.atSeconds).toSorted((left, right) => left - right);
  let maxFlashes = 0;
  let windowStart = 0;
  for (let windowEnd = 0; windowEnd < onTimes.length; windowEnd += 1) {
    while (onTimes[windowEnd]! - onTimes[windowStart]! >= 1) {
      windowStart += 1;
    }
    maxFlashes = Math.max(maxFlashes, windowEnd - windowStart + 1);
  }
  return maxFlashes;
}

export function morseRelativeLuminance(color: MorseRGB): number {
  const linearRed = linearizeSrgb(color.red);
  const linearGreen = linearizeSrgb(color.green);
  const linearBlue = linearizeSrgb(color.blue);
  return (0.2126 * linearRed) + (0.7152 * linearGreen) + (0.0722 * linearBlue);
}

export function mixMorseRgb(foreground: MorseRGB, background: MorseRGB, foregroundRatio: number): MorseRGB {
  const ratio = Math.max(0, Math.min(1, foregroundRatio));
  return {
    red: foreground.red * ratio + background.red * (1 - ratio),
    green: foreground.green * ratio + background.green * (1 - ratio),
    blue: foreground.blue * ratio + background.blue * (1 - ratio),
  };
}

export function morseBeaconPalette(input: { readonly accent: MorseRGB; readonly background: MorseRGB }): MorseFlashBeaconPalette {
  return {
    resting: mixMorseRgb(input.accent, input.background, MORSE_BEACON_RESTING_MIX),
    active: mixMorseRgb(input.accent, input.background, MORSE_BEACON_ACTIVE_MIX),
    usesSaturatedRed: isSaturatedRed(input.accent),
  };
}

export function evaluateMorseBeaconFlashSafety(input: { readonly palette: MorseFlashBeaconPalette; readonly flashesPerSecond: number; readonly flashAreaCssPixels?: number }): MorseFlashSafetyResult {
  return evaluateMorseFlashSafety({
    flashAreaCssPixels: input.flashAreaCssPixels ?? MORSE_BEACON_AREA_CSS_PIXELS,
    flashesPerSecond: input.flashesPerSecond,
    darkerRelativeLuminance: morseRelativeLuminance(input.palette.resting),
    lighterRelativeLuminance: morseRelativeLuminance(input.palette.active),
    usesSaturatedRed: input.palette.usesSaturatedRed,
  });
}

export function evaluateMorseFlashSafety(input: MorseFlashSafetyInput): MorseFlashSafetyResult {
  const darker = Math.min(input.darkerRelativeLuminance, input.lighterRelativeLuminance);
  const lighter = Math.max(input.darkerRelativeLuminance, input.lighterRelativeLuminance);
  const luminanceDelta = lighter - darker;
  if (input.usesSaturatedRed) {
    return { safe: false, reason: "saturated-red", luminanceDelta, maxAreaCssPixels: MORSE_FLASH_MAX_AREA_CSS_PIXELS };
  }
  if (input.flashAreaCssPixels <= MORSE_FLASH_MAX_AREA_CSS_PIXELS) {
    return { safe: true, reason: "below-area-threshold", luminanceDelta, maxAreaCssPixels: MORSE_FLASH_MAX_AREA_CSS_PIXELS };
  }
  if (input.flashesPerSecond <= 3) {
    return { safe: true, reason: "within-three-flashes", luminanceDelta, maxAreaCssPixels: MORSE_FLASH_MAX_AREA_CSS_PIXELS };
  }
  if (luminanceDelta < 0.1 || darker >= 0.8) {
    return { safe: true, reason: "below-general-threshold", luminanceDelta, maxAreaCssPixels: MORSE_FLASH_MAX_AREA_CSS_PIXELS };
  }
  return { safe: false, reason: "area-too-large", luminanceDelta, maxAreaCssPixels: MORSE_FLASH_MAX_AREA_CSS_PIXELS };
}

function linearizeSrgb(component: number): number {
  return component <= 0.03928 ? component / 12.92 : ((component + 0.055) / 1.055) ** 2.4;
}

function isSaturatedRed(color: MorseRGB): boolean {
  const total = color.red + color.green + color.blue;
  return total > 0 && color.red / total >= 0.8;
}

export function classifyMorseKeyDown(durationSeconds: number, profile: MorseTimingProfile): MorseKeyTimingSample {
  if (!Number.isFinite(durationSeconds) || durationSeconds <= 0) {
    throw new RangeError("durationSeconds must be a positive finite number");
  }
  const dotDashBoundarySeconds = 2 * profile.dotSeconds;
  const element: MorseKeyElement = durationSeconds <= dotDashBoundarySeconds ? "." : "-";
  const expectedSeconds = element === "." ? profile.dotSeconds : profile.dashSeconds;
  return { element, durationSeconds, expectedSeconds, ratioToExpected: durationSeconds / expectedSeconds };
}

export function decodeMorseElements(elements: readonly MorseKeyElement[] | string): MorseDecodedCharacter {
  const normalizedElements = typeof elements === "string" ? elements : elements.join("");
  if (!/^[.-]+$/u.test(normalizedElements)) {
    return { kind: "unknown", elements: normalizedElements };
  }
  if (normalizedElements === ".".repeat(MORSE_ERROR_SIGNAL_DOTS)) {
    return { kind: "errorSignal", elements: normalizedElements };
  }
  const character = reverseMorseCodeTable.get(normalizedElements);
  return character === undefined
    ? { kind: "unknown", elements: normalizedElements }
    : { kind: "character", elements: normalizedElements, character };
}

export function applyMorseDecodedCharacter(text: string, decoded: MorseDecodedCharacter): string {
  if (decoded.kind === "errorSignal") {
    return Array.from(text).slice(0, -1).join("");
  }
  if (decoded.kind === "character" && decoded.character !== undefined) {
    return `${text}${decoded.character}`;
  }
  return text;
}

export function morseCharacterTimingFeedback(samples: readonly MorseKeyTimingSample[]): MorseCharacterTimingFeedback {
  const elements = samples.map((sample) => sample.element).join("");
  const ratios = samples.map((sample) => sample.ratioToExpected);
  const averageRatioToExpected = ratios.length === 0 ? 1 : ratios.reduce((total, ratio) => total + ratio, 0) / ratios.length;
  const meanAbsoluteError = ratios.length === 0 ? 0 : ratios.reduce((total, ratio) => total + Math.abs(ratio - 1), 0) / ratios.length;
  const dotDurations = samples.filter((sample) => sample.element === ".").map((sample) => sample.durationSeconds);
  const dashDurations = samples.filter((sample) => sample.element === "-").map((sample) => sample.durationSeconds);
  const dotDashRatio = dotDurations.length > 0 && dashDurations.length > 0
    ? average(dashDurations) / average(dotDurations)
    : null;
  return {
    elements,
    decoded: decodeMorseElements(elements),
    dotDashRatio,
    timingConsistencyPercent: Math.max(0, Math.min(100, Math.round((1 - meanAbsoluteError) * 100))),
    averageRatioToExpected,
  };
}

export function scoreMorseSending(expected: string, sent: string, completedWithinTime = true): MorseSendingScore {
  const diff = diffMorseCopy(expected, sent);
  return {
    diff,
    completedWithinTime,
    passed: diff.score.passed,
    markPercent: diff.score.markPercent,
  };
}

export function generateMorseExamText(options: MorseExamTextOptions = {}): MorseExamText {
  const profile = options.profile ?? MORSE_TIMING_PROFILES.isedParis;
  const minWeightedCharacters = options.minWeightedCharacters ?? DEFAULT_EXAM_MIN_WEIGHTED_CHARACTERS;
  const minDurationSeconds = options.minDurationSeconds ?? DEFAULT_EXAM_MIN_DURATION_SECONDS;
  const random = seededRandom(options.seed ?? "morse-copy-exam");
  const startIndex = Math.floor(random() * EXAM_SENTENCE_CORPUS.length);
  const selectedSentences: string[] = [];
  let sentenceIndex = startIndex;

  for (let guard = 0; guard < 200; guard += 1) {
    selectedSentences.push(EXAM_SENTENCE_CORPUS[sentenceIndex % EXAM_SENTENCE_CORPUS.length]!);
    sentenceIndex += 1 + Math.floor(random() * 3);
    const candidate = selectedSentences.join(" ");
    const weight = weightedCharacterCount(candidate);
    const sequence = textToTimedMorse(candidate, profile);
    if (weight.weightedCharacters >= minWeightedCharacters && sequence.totalDurationSeconds >= minDurationSeconds) {
      return {
        text: candidate,
        normalizedText: sequence.normalizedText,
        weightedCharacters: weight.weightedCharacters,
        unweightedCharacters: weight.unweightedCharacters,
        durationSeconds: sequence.totalDurationSeconds,
        profile,
      };
    }
  }

  throw new Error("Unable to generate Morse exam text that satisfies RIC-1 section 8.2 constraints.");
}

export function scoreMorseCopy(expected: string, received: string): MorseExamScore {
  return alignMorseCopy(expected, received).score;
}

export function diffMorseCopy(expected: string, received: string): MorseCopyDiff {
  return alignMorseCopy(expected, received);
}

function alignMorseCopy(expected: string, received: string): MorseCopyDiff {
  const expectedCharacters = canonicalMorseCharacters(expected);
  const receivedCharacters = receivedMorseCopyCharacters(received);
  const rows = expectedCharacters.length + 1;
  const columns = receivedCharacters.length + 1;
  const dp = Array.from({ length: rows }, () => Array.from({ length: columns }, () => 0));

  for (let row = 1; row < rows; row += 1) {
    dp[row]![0] = row;
  }
  for (let column = 1; column < columns; column += 1) {
    dp[0]![column] = column;
  }

  for (let row = 1; row < rows; row += 1) {
    for (let column = 1; column < columns; column += 1) {
      const substitutionCost = expectedCharacters[row - 1] === receivedCharacters[column - 1] ? 0 : 1;
      dp[row]![column] = Math.min(
        dp[row - 1]![column]! + 1,
        dp[row]![column - 1]! + 1,
        dp[row - 1]![column - 1]! + substitutionCost,
      );
    }
  }

  let row = expectedCharacters.length;
  let column = receivedCharacters.length;
  let wrong = 0;
  let missing = 0;
  let inserted = 0;
  const operations: MorseCopyDiffOperation[] = [];

  while (row > 0 || column > 0) {
    if (
      row > 0 &&
      column > 0 &&
      expectedCharacters[row - 1] === receivedCharacters[column - 1] &&
      dp[row]![column] === dp[row - 1]![column - 1]
    ) {
      operations.push({ kind: "match", expected: expectedCharacters[row - 1], received: receivedCharacters[column - 1] });
      row -= 1;
      column -= 1;
      continue;
    }

    if (row > 0 && column > 0 && dp[row]![column] === dp[row - 1]![column - 1]! + 1) {
      operations.push({ kind: "wrong", expected: expectedCharacters[row - 1], received: receivedCharacters[column - 1] });
      wrong += 1;
      row -= 1;
      column -= 1;
      continue;
    }

    if (row > 0 && dp[row]![column] === dp[row - 1]![column]! + 1) {
      operations.push({ kind: "missing", expected: expectedCharacters[row - 1] });
      missing += 1;
      row -= 1;
      continue;
    }

    operations.push({ kind: "inserted", received: receivedCharacters[column - 1] });
    inserted += 1;
    column -= 1;
  }

  const errors = dp[expectedCharacters.length]![receivedCharacters.length]!;
  return {
    score: {
      errors,
      wrong,
      missing,
      inserted,
      passed: errors <= 5,
      markPercent: errors <= 5 ? 100 : Math.max(0, 105 - errors),
      expectedLength: expectedCharacters.length,
      receivedLength: receivedCharacters.length,
    },
    operations: operations.reverse(),
  };
}

function canonicalMorseWords(text: string): string[][] {
  const invalidCharacters = validateMorseText(text).invalidCharacters;
  if (invalidCharacters.length > 0) {
    throw new MorseValidationError(invalidCharacters);
  }

  const words: string[][] = [];
  let currentWord: string[] = [];
  for (const character of Array.from(text)) {
    if (isWhitespace(character)) {
      if (currentWord.length > 0) {
        words.push(currentWord);
        currentWord = [];
      }
      continue;
    }
    const normalized = normalizeCharacter(character);
    if (normalized !== undefined) {
      currentWord.push(normalized);
    }
  }
  if (currentWord.length > 0) {
    words.push(currentWord);
  }
  return words;
}

function receivedMorseCopyCharacters(text: string): string[] {
  return Array.from(text.normalize("NFC")).flatMap((character) => {
    if (isWhitespace(character)) {
      return [];
    }
    const normalized = normalizeCharacter(character);
    return normalized !== undefined && allowedCharacters.has(normalized) ? [normalized] : [character];
  });
}

function normalizeCharacter(character: string): string | undefined {
  const codePoint = character.codePointAt(0);
  if (codePoint === undefined || codePoint > 0x7f) {
    return undefined;
  }
  return character.toUpperCase();
}

function average(values: readonly number[]): number {
  return values.reduce((total, value) => total + value, 0) / values.length;
}

function seededRandom(seed: string): () => number {
  let state = 2166136261;
  for (const character of seed) {
    state ^= character.codePointAt(0) ?? 0;
    state = Math.imul(state, 16777619) >>> 0;
  }
  if (state === 0) {
    state = 0x9e3779b9;
  }
  return () => {
    state = Math.imul(state ^ (state >>> 15), 2246822507) >>> 0;
    state = Math.imul(state ^ (state >>> 13), 3266489909) >>> 0;
    state = (state ^ (state >>> 16)) >>> 0;
    return state / 0x100000000;
  };
}

function isWhitespace(character: string): boolean {
  const codePoint = character.codePointAt(0);
  return codePoint !== undefined && morseWhitespaceCodePoints.has(codePoint);
}
