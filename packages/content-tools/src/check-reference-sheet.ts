import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

import { isMainModule } from "./cli.ts";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const SHEET_PATH = new URL("../../../content/reference-sheet/basic.md", import.meta.url);

interface RequiredEntry {
  readonly name: string;
  readonly sheetText: string;
  readonly lessonText: string;
  readonly lessonPath: string;
}

const requiredEntries: readonly RequiredEntry[] = [
  { name: "Ohm's law voltage", sheetText: "E = I x R", lessonText: "E = I x R", lessonPath: "content/lessons/m5-basic-electronics/l-005-02-power-ohms-law.md" },
  { name: "Ohm's law current", sheetText: "I = E / R", lessonText: "I = E / R", lessonPath: "content/lessons/m5-basic-electronics/l-005-02-power-ohms-law.md" },
  { name: "Ohm's law resistance", sheetText: "R = E / I", lessonText: "R = E / I", lessonPath: "content/lessons/m5-basic-electronics/l-005-02-power-ohms-law.md" },
  { name: "Power", sheetText: "P = I x E", lessonText: "P = I x E", lessonPath: "content/lessons/m5-basic-electronics/l-005-02-power-ohms-law.md" },
  { name: "Power current", sheetText: "I = P / E", lessonText: "I = P / E", lessonPath: "content/lessons/m5-basic-electronics/l-005-02-power-ohms-law.md" },
  { name: "Power voltage", sheetText: "E = P / I", lessonText: "E = P / I", lessonPath: "content/lessons/m5-basic-electronics/l-005-02-power-ohms-law.md" },
  { name: "Series resistance", sheetText: "Rt = R1 + R2 + R3 ... + Rn", lessonText: "Rt = R1 + R2 + R3 ... + Rn", lessonPath: "content/lessons/m5-basic-electronics/l-005-03-parallel-circuits-and-ratings.md" },
  { name: "Parallel reciprocal resistance", sheetText: "1 / Rt = 1 / R1 + 1 / R2 + 1 / R3 ... + 1 / Rn", lessonText: "1 / Rt = 1 / R1 + 1 / R2 + 1 / R3 ... + 1 / Rn", lessonPath: "content/lessons/m5-basic-electronics/l-005-03-parallel-circuits-and-ratings.md" },
  { name: "Equal parallel resistance", sheetText: "Rt = R / number of equal branches", lessonText: "Rt = R / number of branches", lessonPath: "content/lessons/m5-basic-electronics/l-005-03-parallel-circuits-and-ratings.md" },
  { name: "Two-resistor parallel shortcut", sheetText: "Rt = (R1 x R2) / (R1 + R2)", lessonText: "Rt = (R1 x R2) / (R1 + R2)", lessonPath: "content/lessons/m5-basic-electronics/l-005-03-parallel-circuits-and-ratings.md" },
  { name: "+3 dB", sheetText: "+3 dB | roughly 2x", lessonText: "+3 dB | roughly 2x power", lessonPath: "content/lessons/m5-basic-electronics/l-005-04-ac-db-reactance.md" },
  { name: "-3 dB", sheetText: "-3 dB | roughly 1/2", lessonText: "-3 dB | roughly 1/2 power", lessonPath: "content/lessons/m5-basic-electronics/l-005-04-ac-db-reactance.md" },
  { name: "+10 dB", sheetText: "+10 dB | roughly 10x", lessonText: "+10 dB | roughly 10x power", lessonPath: "content/lessons/m5-basic-electronics/l-005-04-ac-db-reactance.md" },
  { name: "-10 dB", sheetText: "-10 dB | roughly 1/10", lessonText: "-10 dB | roughly 1/10 power", lessonPath: "content/lessons/m5-basic-electronics/l-005-04-ac-db-reactance.md" },
  { name: "Free-space wavelength", sheetText: "λ(m) = 300 / f(MHz)", lessonText: "λ = 300 / f(MHz)", lessonPath: "content/lessons/m6-feedlines-antennas/l-006-03-polarization-dipoles-wavelength.md" },
  { name: "Half-wave dipole length", sheetText: "length(m) ≈ 143 / f(MHz)", lessonText: "half-wave length in metres ≈ 143 / f(MHz)", lessonPath: "content/lessons/m6-feedlines-antennas/l-006-03-polarization-dipoles-wavelength.md" },
  { name: "giga prefix", sheetText: "giga | G | x 1 000 000 000", lessonText: "giga | G | 1 000 000 000 times the base unit", lessonPath: "content/lessons/m5-basic-electronics/l-005-01-units-conductors-current.md" },
  { name: "mega prefix", sheetText: "mega | M | x 1 000 000", lessonText: "mega | M | 1 000 000 times the base unit", lessonPath: "content/lessons/m5-basic-electronics/l-005-01-units-conductors-current.md" },
  { name: "kilo prefix", sheetText: "kilo | k | x 1 000", lessonText: "kilo | k | 1 000 times the base unit", lessonPath: "content/lessons/m5-basic-electronics/l-005-01-units-conductors-current.md" },
  { name: "milli prefix", sheetText: "milli | m | x 0.001", lessonText: "milli | m | a thousandth", lessonPath: "content/lessons/m5-basic-electronics/l-005-01-units-conductors-current.md" },
  { name: "micro prefix", sheetText: "micro | µ | x 0.000 001", lessonText: "micro | µ | a millionth", lessonPath: "content/lessons/m5-basic-electronics/l-005-01-units-conductors-current.md" },
  { name: "pico prefix", sheetText: "pico | p | x 0.000 000 000 001", lessonText: "pico | p | a trillionth", lessonPath: "content/lessons/m5-basic-electronics/l-005-01-units-conductors-current.md" },
  { name: "black resistor code", sheetText: "black | 0 | x 1", lessonText: "black | 0 | x 1", lessonPath: "content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md" },
  { name: "brown resistor code", sheetText: "brown | 1 | x 10", lessonText: "brown | 1 | x 10", lessonPath: "content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md" },
  { name: "red resistor code", sheetText: "red | 2 | x 100", lessonText: "red | 2 | x 100", lessonPath: "content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md" },
  { name: "orange resistor code", sheetText: "orange | 3 | x 1 000", lessonText: "orange | 3 | x 1 000", lessonPath: "content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md" },
  { name: "yellow resistor code", sheetText: "yellow | 4 | x 10 000", lessonText: "yellow | 4 | x 10 000", lessonPath: "content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md" },
  { name: "green resistor code", sheetText: "green | 5 | x 100 000", lessonText: "green | 5 | x 100 000", lessonPath: "content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md" },
  { name: "blue resistor code", sheetText: "blue | 6 | x 1 000 000", lessonText: "blue | 6 | x 1 000 000", lessonPath: "content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md" },
  { name: "violet resistor code", sheetText: "violet | 7 | x 10 000 000", lessonText: "violet | 7 | x 10 000 000", lessonPath: "content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md" },
  { name: "grey resistor code", sheetText: "grey | 8 | x 100 000 000", lessonText: "grey | 8 | x 100 000 000", lessonPath: "content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md" },
  { name: "white resistor code", sheetText: "white | 9 | x 1 000 000 000", lessonText: "white | 9 | x 1 000 000 000", lessonPath: "content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md" },
  { name: "gold resistor code", sheetText: "gold | — | x 0.1", lessonText: "gold | — | x 0.1", lessonPath: "content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md" },
  { name: "silver resistor code", sheetText: "silver | — | x 0.01", lessonText: "silver | — | x 0.01", lessonPath: "content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md" },
];

const requiredSections = [
  "## Ohm's law",
  "## Power",
  "## Series and parallel resistance",
  "## Decibel power shortcuts",
  "## Wavelength and dipole length",
  "## Metric prefixes",
  "## Four-band resistor colour code",
];

function normalizeMarkdownTable(text: string): string {
  return text
    .replace(/\r\n/g, "\n")
    .replace(/\s*\|\s*/g, " | ")
    .replace(/[ \t]+/g, " ")
    .trim();
}

async function validateReferenceSheet(): Promise<readonly string[]> {
  const issues: string[] = [];
  const sheet = await readFile(SHEET_PATH, "utf8");
  const normalizedSheet = normalizeMarkdownTable(sheet);

  if (!sheet.startsWith("# Original Basic formula and reference study aid\n")) {
    issues.push("content/reference-sheet/basic.md must start with the approved original-study-aid heading.");
  }
  if (!sheet.includes("Study aid for Canadian Ham practice; the real Basic exam provides the official ISED reference sheet.")) {
    issues.push("content/reference-sheet/basic.md must state that it is a study aid and that the exam provides the official ISED sheet.");
  }
  for (const section of requiredSections) {
    if (!sheet.includes(section)) {
      issues.push(`content/reference-sheet/basic.md is missing ${section}.`);
    }
  }
  if (/Reference Material for Amateur Radio|block diagram|official ISED reference sheet content/i.test(sheet)) {
    issues.push("content/reference-sheet/basic.md appears to include official-reference-sheet wording instead of original study-aid content.");
  }

  const lessonCache = new Map<string, string>();
  for (const entry of requiredEntries) {
    if (!normalizedSheet.includes(normalizeMarkdownTable(entry.sheetText))) {
      issues.push(`content/reference-sheet/basic.md is missing ${entry.name}: ${entry.sheetText}`);
    }
    let lessonText = lessonCache.get(entry.lessonPath);
    if (lessonText === undefined) {
      lessonText = await readFile(new URL(`../../../${entry.lessonPath}`, import.meta.url), "utf8");
      lessonCache.set(entry.lessonPath, lessonText);
    }
    if (!normalizeMarkdownTable(lessonText).includes(normalizeMarkdownTable(entry.lessonText))) {
      issues.push(`${entry.lessonPath} no longer verifies ${entry.name}: ${entry.lessonText}`);
    }
  }

  return issues;
}

async function main(): Promise<void> {
  const issues = await validateReferenceSheet();
  if (issues.length > 0) {
    throw new Error(["Reference sheet validation failed:", ...issues.map((issue) => `- ${issue}`)].join("\n"));
  }
  console.log(`check-reference-sheet: validated ${requiredEntries.length} entries against lessons from ${REPO_ROOT}content/reference-sheet/basic.md`);
}

if (isMainModule(import.meta)) {
  main().catch((error: unknown) => {
    const message = error instanceof Error ? error.message : String(error);
    console.error(message);
    process.exitCode = 1;
  });
}
