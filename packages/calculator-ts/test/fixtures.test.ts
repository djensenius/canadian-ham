import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { applyCalculatorKey, createCalculatorState, runCalculatorKeys, type CalculatorKey, type CalculatorLocale } from "../src/index.ts";

const calculatorKeys = new Set<string>(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "+", "-", "×", "÷", "=", "√", "x²", "1/x", "±", "%", "C/CE", "AC", "backspace"]);

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "../../..");
const fixturePath = join(repoRoot, "fixtures/calculator/sequences.json");
const fixture = JSON.parse(await readFile(fixturePath, "utf8"));

test("fixtures/calculator/sequences.json matches the TypeScript calculator engine", async (t) => {
  assert.equal(fixture.schemaVersion, 1);
  assert.equal(fixture.kind, "calculator-sequences");
  assert.ok(Array.isArray(fixture.cases), "fixture cases must be an array");
  assert.ok(fixture.cases.length >= 60, "calculator fixture must cover at least 60 cases");

  for (const testCase of fixture.cases) {
    await t.test(testCase.id, () => {
      assert.equal(typeof testCase.id, "string");
      assert.ok(Array.isArray(testCase.keys), `${testCase.id}: keys must be an array`);
      for (const key of testCase.keys) {
        assert.equal(calculatorKeys.has(key), true, `${testCase.id}: unknown key ${key}`);
      }
      const locale = (testCase.locale ?? "en") as CalculatorLocale;
      const keys = testCase.keys as CalculatorKey[];
      const result = runCalculatorKeys(keys, { locale });
      assert.equal(result.display, testCase.expectedDisplay, testCase.id);
      assert.ok([...result.display].length <= 16, `${testCase.id}: display ${result.display} exceeds 16 code points`);
      if (testCase.expectedDisplayValue !== undefined) {
        assert.deepEqual(result.displayValue, testCase.expectedDisplayValue, testCase.id);
      }
    });
  }
});

test("seeded calculator fuzz keeps display within the UI bound", () => {
  const keys: CalculatorKey[] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "+", "-", "×", "÷", "=", "√", "x²", "1/x", "±", "%", "C/CE", "AC", "backspace"];
  let seed = 0x44_10_12_01;
  let state = createCalculatorState();
  for (let index = 0; index < 50_000; index += 1) {
    seed = (Math.imul(seed, 1_664_525) + 1_013_904_223) >>> 0;
    const key = keys[seed % keys.length]!;
    state = applyCalculatorKey(state, key);
    assert.ok([...state.display].length <= 16, `step ${index} key ${key} display ${state.display} exceeds 16 code points`);
  }
});

test("calculator state does not retain a formula or text history", () => {
  const result = runCalculatorKeys(["1", "+", "2", "×", "3", "=", "="]);
  assert.equal(result.display, "27");
  assert.deepEqual(Object.keys(result).toSorted(), [
    "accumulator",
    "awaitingOperand",
    "currentEntry",
    "display",
    "displayValue",
    "displayedValue",
    "entering",
    "error",
    "justEvaluated",
    "lastOperation",
    "locale",
    "pendingOperator",
  ]);
  assert.ok(!("formula" in result));
  assert.ok(!("history" in result));
  assert.ok(!("text" in result));
});
