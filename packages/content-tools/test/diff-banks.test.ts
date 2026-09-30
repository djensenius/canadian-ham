import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import { buildBankDiffReport, renderBankDiffReport } from "../src/diff-banks.ts";

const FIXTURES_DIR = fileURLToPath(new URL("fixtures/diff-banks/", import.meta.url));
const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const SCRIPT_PATH = path.join(REPO_ROOT, "packages/content-tools/src/diff-banks.ts");
const FROM_BANK = path.join(FIXTURES_DIR, "bank-2025");
const TO_BANK = path.join(FIXTURES_DIR, "bank-2026");

test("diff report lists added, removed, changed text, changed answers, and subsection counts", async () => {
  const report = await buildBankDiffReport(FROM_BANK, TO_BANK);

  assert.equal(report.from.bankId, "basic-2025-07-15");
  assert.equal(report.to.bankId, "basic-2026-01-01");
  assert.deepEqual(report.questions.added, [
    "B-001-001-003",
    "B-001-002-002",
    "B-001-004-001",
  ]);
  assert.deepEqual(report.questions.removed, [
    "B-001-001-002",
    "B-001-003-001",
  ]);
  assert.deepEqual(report.questions.changedText, [
    {
      id: "B-001-002-001",
      changes: {
        en: { from: "Which value is old?", to: "Which value is new?" },
        fr: { from: "Quelle valeur est ancienne?", to: "Quelle valeur est nouvelle?" },
      },
    },
  ]);
  assert.deepEqual(report.questions.changedAnswers, [
    {
      id: "B-001-002-001",
      sourceIndex: 0,
      previous: {
        isCorrect: true,
        text: { en: "Old correct", fr: "Ancienne correcte" },
      },
      current: {
        isCorrect: false,
        text: { en: "New correct", fr: "Ancienne correcte" },
      },
      changedFields: ["isCorrect", "text.en"],
    },
    {
      id: "B-001-002-001",
      sourceIndex: 1,
      previous: {
        isCorrect: false,
        text: { en: "Old distractor", fr: "Ancien distracteur" },
      },
      current: {
        isCorrect: true,
        text: { en: "Old distractor", fr: "Nouveau distracteur" },
      },
      changedFields: ["isCorrect", "text.fr"],
    },
    {
      id: "B-001-002-001",
      sourceIndex: 2,
      previous: {
        isCorrect: false,
        text: { en: "Stable distractor", fr: "Distracteur stable" },
      },
      current: null,
      changedFields: ["removed"],
    },
    {
      id: "B-001-002-001",
      sourceIndex: 4,
      previous: null,
      current: {
        isCorrect: false,
        text: { en: "Added distractor", fr: "Distracteur ajouté" },
      },
      changedFields: ["added"],
    },
  ]);
  assert.deepEqual(report.subsections.added, ["B-001-004"]);
  assert.deepEqual(report.subsections.removed, ["B-001-003"]);
  assert.deepEqual(report.subsections.countChanged, [
    {
      id: "B-001-002",
      fromQuestionCount: 1,
      toQuestionCount: 2,
      fromQuestionIds: ["B-001-002-001"],
      toQuestionIds: ["B-001-002-001", "B-001-002-002"],
    },
  ]);
});

test("rendered diff report includes reviewable EN/FR and answer details", async () => {
  const report = await buildBankDiffReport(FROM_BANK, TO_BANK);
  const rendered = renderBankDiffReport(report);

  assert.match(rendered, /^# Bank diff: basic-2025-07-15 -> basic-2026-01-01/m);
  assert.match(rendered, /- Question IDs added: 3/);
  assert.match(rendered, /- B-001-001-003/);
  assert.match(rendered, /### B-001-002-001/);
  assert.match(rendered, /- EN from: "Which value is old\?"/);
  assert.match(rendered, /- FR to: "Quelle valeur est nouvelle\?"/);
  assert.match(rendered, /### B-001-002-001 answer sourceIndex 0/);
  assert.match(rendered, /- Changed fields: isCorrect, text\.en/);
  assert.match(rendered, /- Changed fields: added/);
  assert.match(rendered, /- B-001-002: 1 -> 2/);
});

function runCli(args: string[], options: { cwd?: string; env?: NodeJS.ProcessEnv } = {}) {
  return spawnSync(process.execPath, [SCRIPT_PATH, ...args], {
    cwd: options.cwd,
    env: options.env,
    encoding: "utf8",
  });
}

test("CLI accepts a leading -- and emits parseable JSON", () => {
  const result = runCli(["--", "--json", FROM_BANK, TO_BANK]);

  assert.equal(result.status, 0, result.stderr);
  const parsed = JSON.parse(result.stdout) as { from: { bankId: string }; to: { bankId: string } };
  assert.equal(parsed.from.bankId, "basic-2025-07-15");
  assert.equal(parsed.to.bankId, "basic-2026-01-01");
});

test("CLI accepts --json in any argument position", () => {
  const result = runCli([FROM_BANK, TO_BANK, "--json"]);

  assert.equal(result.status, 0, result.stderr);
  const parsed = JSON.parse(result.stdout) as { summary: { answerChangeCount: number } };
  assert.equal(parsed.summary.answerChangeCount, 4);
});

test("CLI reports usage with a non-zero exit code", () => {
  const result = runCli([FROM_BANK]);

  assert.equal(result.status, 1);
  assert.match(result.stderr, /usage: node packages\/content-tools\/src\/diff-banks\.ts/);
});

test("CLI resolves relative bank paths against INIT_CWD when set", () => {
  const result = runCli(["--json", "bank-2025", "bank-2026"], {
    cwd: path.join(REPO_ROOT, "packages/content-tools"),
    env: { ...process.env, INIT_CWD: FIXTURES_DIR },
  });

  assert.equal(result.status, 0, result.stderr);
  const parsed = JSON.parse(result.stdout) as { to: { bankId: string } };
  assert.equal(parsed.to.bankId, "basic-2026-01-01");
});
