import assert from "node:assert/strict";
import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { lessonReaderHeadingAnchors } from "../src/check-hints.ts";
import { loadQuestionHints } from "../src/hints.ts";

const repoRoot = fileURLToPath(new URL("../../..", import.meta.url));
const lessonRoot = path.join(repoRoot, "content/lessons/m1-regulations-policies");

async function lessonMarkdown(lessonId: string): Promise<string> {
  const file = (await readdir(lessonRoot)).find((name) => name.startsWith(`${lessonId.toLowerCase()}-`));
  assert.ok(file, lessonId);
  return readFile(path.join(lessonRoot, file), "utf8");
}

function headingBlock(markdown: string, heading: string): string {
  const block = markdown.split(`## ${heading}\n`)[1]?.split(/^## /mu)[0];
  assert.ok(block, heading);
  return block;
}

for (let number = 1; number <= 6; number += 1) {
  const lessonId = `L-001-${String(number).padStart(2, "0")}`;
  test(`${lessonId} introduces principles and gives every reference table a short Why column`, async () => {
    const markdown = await lessonMarkdown(lessonId);
    const sections = [...markdown.matchAll(/^## Reference facts: (.+)\n([\s\S]*?)(?=^## |$(?![\s\S]))/gmu)];
    assert.ok(sections.length >= 3, lessonId);
    for (const [, heading, body] of sections) {
      const tableStart = body!.indexOf("\n|");
      assert.ok(tableStart > 0, `${lessonId}: ${heading} needs a principle before its table`);
      const tables = body!.match(/^\|[^\n]+\n\|[-| ]+\|/gmu) ?? [];
      assert.ok(tables.length > 0, heading);
      for (const header of tables) assert.match(header.split("\n")[0]!, /\bWhy\b/u, heading);
      for (const table of body!.matchAll(/(?:^\|[^\n]+\|\n?)+/gmu)) {
        const rows = table[0].trim().split("\n");
        const columns = rows[0]!.split("|").length;
        for (const row of rows) assert.equal(row.split("|").length, columns, `${lessonId}: table column count`);
      }
    }
    assert.match(markdown, /^## How these rules fit together$/mu);
    assert.doesNotMatch(markdown, /Fact established for this lesson|^## Try it|^## Common mistakes|^### (?:Worked example|Faded practice|Misconception):/mu);
  });
}

test("L-001-02 and L-001-04 keep companion matrices with the same qualification rows", async () => {
  const stationWork = headingBlock(await lessonMarkdown("L-001-02"), "Reference facts: Qualification-by-privilege matrix for station work");
  const accessAndPower = headingBlock(await lessonMarkdown("L-001-04"), "Reference facts: Qualification-by-privilege matrix for access and power");
  const qualifications = ["Basic only", "Basic with Honours", "Basic plus Morse", "Basic plus Advanced"];
  for (const matrix of [stationWork, accessAndPower]) {
    const rows = [...matrix.matchAll(/^\| (Basic [^|]+) \|/gmu)].map((match) => match[1]!.trim());
    assert.deepEqual(rows, qualifications);
  }
  const workRows = stationWork.split("\n").filter((line) => /^\| Basic/u.test(line));
  for (const row of workRows.slice(0, 3)) assert.match(row, /Requires Advanced as well/u);
  assert.match(workRows[3]!, /\| Permitted\. \| Permitted\. \|/u);
  assert.match(accessAndPower, /250 W DC input.*560 W SSB PEP.*190 W carrier/u);
  assert.match(accessAndPower, /1 000 W DC input.*2 250 W SSB PEP/u);
  assert.equal(accessAndPower.match(/Same Basic limits/gu)?.length, 2);
  assert.match(accessAndPower, /repeater on an amateur frequency above 30 MHz/u);
});

test("L-001-01 M1 numbers board keeps similar numbers attached to separate duties and quantities", async () => {
  const board = headingBlock(await lessonMarkdown("L-001-01"), "Reference facts: M1 numbers board");
  for (const value of ["48 hours", "$60", "5 words per minute", "80%", "30 minutes", "30 MHz", "250 W", "560 W", "190 W", "1 000 W", "2 250 W", "30 kHz", "20 kHz", "6 kHz", "1 kHz", "48 MHz to 300 MHz"]) {
    assert.ok(board.includes(value), value);
  }
  const deadlines = board.split("\n").filter((line) => line.startsWith("| 30 days |"));
  assert.equal(deadlines.length, 2);
  assert.match(deadlines[0]!, /mailing-address/u);
  assert.match(deadlines[1]!, /public comment/u);
});

const subsectionSections: Readonly<Record<number, readonly [string, string]>> = {
  1: ["L-001-01", "authority-comes-from-named-sources"],
  2: ["L-001-01", "a-lifetime-certificate-needs-current-records"],
  3: ["L-001-01", "trust-needs-honest-signals-and-fair-process"],
  4: ["L-001-01", "qualifications-follow-a-learning-path"],
  5: ["L-001-02", "both-sides-need-authority"],
  6: ["L-001-02", "both-sides-need-authority"],
  7: ["L-001-02", "messages-stay-open-and-non-commercial"],
  8: ["L-001-02", "qualification-by-privilege-matrix-for-station-work"],
  9: ["L-001-02", "control-stays-with-responsible-people"],
  10: ["L-001-03", "share-spectrum-without-harm"],
  11: ["L-001-03", "life-safety-has-narrow-exceptions"],
  12: ["L-001-03", "message-handling-stays-unpaid"],
  13: ["L-001-03", "make-the-station-traceable"],
  14: ["L-001-05", "a-guest-speaks-under-supervision"],
  15: ["L-001-04", "qualification-by-privilege-matrix-for-access-and-power"],
  16: ["L-001-04", "mode-width-must-fit-the-band"],
  17: ["L-001-04", "power-needs-a-quantity-and-a-measurement-point"],
  18: ["L-001-04", "automatic-signals-still-need-clean-control"],
  19: ["L-001-04", "automatic-signals-still-need-clean-control"],
  20: ["L-001-05", "international-permission-includes-purpose"],
  21: ["L-001-05", "location-decides-the-applicable-limits"],
  22: ["L-001-01", "qualifications-follow-a-learning-path"],
  23: ["L-001-06", "follow-the-applicable-consultation-process"],
  24: ["L-001-06", "protect-people-by-assessing-exposure"],
  25: ["L-001-06", "investigate-interference-at-the-affected-equipment"],
};

function teachingSection(questionId: string): { lessonId: string; sectionAnchor: string } {
  const [, , subsection, item] = questionId.split("-").map(Number);
  let [lessonId, section] = subsectionSections[subsection!]!;
  if (subsection === 3 && item === 4) section = subsectionSections[1]![1];
  if (subsection === 15 && item! >= 5 && item! <= 10 || subsection === 16 && item === 8) section = "band-edges-contain-the-whole-signal";
  if (subsection === 17 && [1, 2, 4, 5, 7, 9, 10].includes(item!) || subsection === 18 && [3, 4].includes(item!)) section = subsectionSections[15]![1];
  if (subsection === 14 && [2, 5, 9, 10].includes(item!) || subsection === 21 && item! >= 6) section = "visit-arrangements-pair-permission-with-identification";
  if (subsection === 14 && item === 4) section = subsectionSections[20]![1];
  if (subsection === 20 && item === 5) section = subsectionSections[21]![1];
  return { lessonId, sectionAnchor: `reference-facts-${section}` };
}

test("all 199 B-001 hints land on their teaching principle, not a generic relationship section", async () => {
  const questions = JSON.parse(await readFile(path.join(repoRoot, "content/generated/basic-2025-07-15/questions.json"), "utf8")) as { id: string; categoryId: string }[];
  const m1 = questions.filter((question) => question.categoryId === "B-001");
  const hints = new Map((await loadQuestionHints()).map((hint) => [hint.questionId, hint]));
  assert.equal(m1.length, 199);
  for (const question of m1) {
    const expected = teachingSection(question.id);
    assert.deepEqual(hints.get(question.id)?.lessonLink, expected, question.id);
    assert.ok(lessonReaderHeadingAnchors(await lessonMarkdown(expected.lessonId)).has(expected.sectionAnchor), question.id);
  }
});

test("M1 taught-facts comparison indexes every B-001 question exactly once with a retained teaching location", async () => {
  const audit = await readFile(path.join(repoRoot, "docs/lesson-review/m1-principles-taught-facts.md"), "utf8");
  const questions = JSON.parse(await readFile(path.join(repoRoot, "content/generated/basic-2025-07-15/questions.json"), "utf8")) as { id: string; categoryId: string }[];
  const rows = [...audit.matchAll(/^\| (B-001-\d{3}-\d{3}) \| (.+) \| Retained; (L-001-\d{2})#(reference-facts-[a-z0-9-]+)\. \|$/gmu)];
  assert.deepEqual(rows.map((row) => row[1]).sort(), questions.filter((question) => question.categoryId === "B-001").map((question) => question.id).sort());
  for (const [, questionId, , lessonId, sectionAnchor] of rows) assert.deepEqual({ lessonId, sectionAnchor }, teachingSection(questionId!), questionId);
  assert.doesNotMatch(audit, /Pending rewrite comparison/u);
});
