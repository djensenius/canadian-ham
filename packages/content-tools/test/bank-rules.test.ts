import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import test from "node:test";

import { contentRulesForBankId } from "../src/banks.ts";
import { rulesForBankId } from "../../engine-ts/src/banks.ts";

interface SharedBankRules {
  readonly bankId: string;
  readonly categoryIds: readonly string[];
  readonly mockExamQuestionCount: number;
  readonly subsectionCount: number;
  readonly passPercent: number;
  readonly hasHonours: boolean;
  readonly honoursPercent: number | null;
}

interface SharedBankRulesFixture {
  readonly schemaVersion: number;
  readonly banks: readonly SharedBankRules[];
}

const fixturePath = fileURLToPath(new URL("../../../fixtures/banks/rules.json", import.meta.url));

test("shared bank-rule fixture agrees with content-tools and engine-ts", async () => {
  const fixture = JSON.parse(await readFile(fixturePath, "utf8")) as SharedBankRulesFixture;
  assert.equal(fixture.schemaVersion, 1);

  for (const expected of fixture.banks) {
    const contentRules = contentRulesForBankId(expected.bankId);
    assert.deepEqual(
      {
        bankId: contentRules.bankId,
        categoryIds: contentRules.categoryRules.map((category) => category.id),
        mockExamQuestionCount: contentRules.examQuestionCount,
        subsectionCount: contentRules.subsectionCount,
        passPercent: contentRules.passPercent,
        hasHonours: contentRules.hasHonours,
        honoursPercent: contentRules.honoursPercent,
      },
      expected,
      `content-tools ${expected.bankId}`,
    );

    const engineRules = rulesForBankId(expected.bankId);
    assert.deepEqual(engineRules, expected, `engine-ts ${expected.bankId}`);
  }
});

test("content-tools bank rules accept only schema-valid Advanced ids", () => {
  assert.equal(contentRulesForBankId("advanced-2026-01-15").bankId, "advanced-2026-01-15");
  for (const bankId of ["advanced-", "advanced-X", "advanced-2026_01"]) {
    assert.throws(() => contentRulesForBankId(bankId), new RegExp(`unsupported bankId ${bankId}`));
  }
});
