import { diffMorseCopy, validateMorseText, type MorseCopyDiff, type MorseCopyDiffOperation } from "@canadian-ham/morse-engine";

export type MorseCopyPassageLength = "short" | "medium" | "long";

export interface MorseCopyPracticePassage {
  readonly id: string;
  readonly length: MorseCopyPassageLength;
  readonly title: string;
  readonly text: string;
}

const copyPracticeCorpus = {
  short: Object.freeze([
    {
      id: "short-net-checkin",
      length: "short",
      title: "Net check-in",
      text: "THE NET OPENS AT NOON. QSL?",
    },
    {
      id: "short-qso-signal",
      length: "short",
      title: "QSO signal report",
      text: "CQ CQ DE VE3HAM. SIGNAL 599.",
    },
  ]),
  medium: Object.freeze([
    {
      id: "medium-club-station",
      length: "medium",
      title: "Club station",
      text: "CQ CQ DE VE3HAM. THE CLUB STATION SENDS A SHORT REPORT FROM OTTAWA. SIGNAL 599.",
    },
    {
      id: "medium-portable-weather",
      length: "medium",
      title: "Portable weather",
      text: "VE7XYZ/PORTABLE CALLS AFTER THE NET. WEATHER IS CLEAR, WIND NORTH, POWER 25 WATTS.",
    },
  ]),
  long: Object.freeze([
    {
      id: "long-field-message",
      length: "long",
      title: "Field message",
      text: "CQ CQ DE VE3HAM. THE FIELD STATION COPIES YOUR REPORT 599. QTH IS OTTAWA AND POWER IS 25 WATTS. PLEASE SEND NAME, QTH, AND RST AGAIN.",
    },
    {
      id: "long-traffic-net",
      length: "long",
      title: "Traffic net",
      text: "THE TRAFFIC NET OPENS AT 1900. STATION VE2HAM SENDS MESSAGE 42 FOR FIELD DAY. MOBILE UNIT CHECKS IN FROM ROAD 17. QSL BEFORE NOON.",
    },
  ]),
} as const satisfies Readonly<Record<MorseCopyPassageLength, readonly MorseCopyPracticePassage[]>>;

for (const passage of Object.values(copyPracticeCorpus).flat()) {
  const validation = validateMorseText(passage.text);
  if (!validation.valid) {
    throw new Error(`Copy practice passage ${passage.id} contains characters outside RIC-1 section 8.2.`);
  }
}

export function copyPracticePassage(length: MorseCopyPassageLength, index = 0): MorseCopyPracticePassage {
  const passages = copyPracticeCorpus[length];
  return passages[index % passages.length]!;
}

export function buildCopyDiff(expected: string, received: string): MorseCopyDiff {
  return diffMorseCopy(expected, received);
}

export function containsDotDashNotation(text: string): boolean {
  const stripped = text.replace(/\s/gu, "");
  return stripped.length > 0 && /^[.-]+$/u.test(stripped);
}

export function diffOperationLabel(operation: MorseCopyDiffOperation): string {
  switch (operation.kind) {
    case "match":
      return operation.expected ?? "";
    case "wrong":
      return `Wrong: ${operation.expected ?? ""}→${operation.received ?? ""}`;
    case "missing":
      return `Missing: ${operation.expected ?? ""}`;
    case "inserted":
      return `Inserted: ${operation.received ?? ""}`;
  }
}
