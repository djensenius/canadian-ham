export type MorseProfileName = "isedParis" | "ric1Literal";

export type MorseSymbolKind = "dot" | "dash" | "intraCharacterGap" | "interCharacterGap" | "wordGap";

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

export interface InvalidMorseCharacter {
  readonly character: string;
  /** Zero-based Unicode Character index in the input string. */
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

export const MORSE_CODE_TABLE = {
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
} as const;

export const ALLOWED_RIC1_CHARACTERS = Object.freeze(Object.keys(MORSE_CODE_TABLE));

const allowedCharacters = new Set<string>(ALLOWED_RIC1_CHARACTERS);
const punctuationAndFigures = new Set<string>(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", ",", "?", "-", "/"]);

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

export function scoreMorseCopy(expected: string, received: string): MorseExamScore {
  const expectedCharacters = canonicalMorseCharacters(expected);
  const receivedCharacters = canonicalMorseCharacters(received);
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

  while (row > 0 || column > 0) {
    if (
      row > 0 &&
      column > 0 &&
      expectedCharacters[row - 1] === receivedCharacters[column - 1] &&
      dp[row]![column] === dp[row - 1]![column - 1]
    ) {
      row -= 1;
      column -= 1;
      continue;
    }

    if (row > 0 && column > 0 && dp[row]![column] === dp[row - 1]![column - 1]! + 1) {
      wrong += 1;
      row -= 1;
      column -= 1;
      continue;
    }

    if (row > 0 && dp[row]![column] === dp[row - 1]![column]! + 1) {
      missing += 1;
      row -= 1;
      continue;
    }

    inserted += 1;
    column -= 1;
  }

  const errors = dp[expectedCharacters.length]![receivedCharacters.length]!;
  return {
    errors,
    wrong,
    missing,
    inserted,
    passed: errors <= 5,
    markPercent: errors <= 5 ? 100 : Math.max(0, 105 - errors),
    expectedLength: expectedCharacters.length,
    receivedLength: receivedCharacters.length,
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

function normalizeCharacter(character: string): string | undefined {
  const normalized = character.toLocaleUpperCase("en-CA");
  return Array.from(normalized).length === 1 ? normalized : undefined;
}

function isWhitespace(character: string): boolean {
  return /^\s$/u.test(character);
}
