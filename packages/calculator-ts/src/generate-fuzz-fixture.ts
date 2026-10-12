import { readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { applyCalculatorKey, createCalculatorState, type CalculatorKey } from "./index.ts";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "../../..");
const fixturePath = join(repoRoot, "fixtures/calculator/sequences.json");
const fuzzKeys: readonly CalculatorKey[] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "+", "-", "×", "÷", "=", "√", "x²", "1/x", "±", "%", "C/CE", "AC", "backspace"];
const fuzzSeed = 0x44_10_12_01;
const fuzzSteps = 20_000;
const snapshotEvery = 100;

interface FuzzSnapshot {
  readonly step: number;
  readonly key: CalculatorKey;
  readonly display: string;
}

interface CalculatorFixtureFile {
  fuzzDrift?: {
    seed: number;
    steps: number;
    snapshotEvery: number;
    lcg: string;
    keys: readonly CalculatorKey[];
    snapshots: readonly FuzzSnapshot[];
  };
}

async function main(): Promise<void> {
  const checkMode = process.argv.includes("--check");
  const fixture = JSON.parse(await readFile(fixturePath, "utf8")) as CalculatorFixtureFile;
  fixture.fuzzDrift = buildFuzzDriftFixture();
  const next = `${JSON.stringify(fixture, null, 2)}\n`;

  if (checkMode) {
    const current = await readFile(fixturePath, "utf8");
    if (current !== next) {
      console.error("calculator fuzz fixture drift: run pnpm --filter @canadian-ham/calculator-engine generate-fuzz-fixture");
      process.exitCode = 1;
      return;
    }
    console.log("calculator fuzz fixture is up to date");
    return;
  }

  await writeFile(fixturePath, next, "utf8");
  console.log("wrote fixtures/calculator/sequences.json fuzzDrift");
}

function buildFuzzDriftFixture(): NonNullable<CalculatorFixtureFile["fuzzDrift"]> {
  let seed = fuzzSeed;
  let state = createCalculatorState();
  const snapshots: FuzzSnapshot[] = [];
  for (let index = 0; index < fuzzSteps; index += 1) {
    seed = (Math.imul(seed, 1_664_525) + 1_013_904_223) >>> 0;
    const key = fuzzKeys[seed % fuzzKeys.length]!;
    state = applyCalculatorKey(state, key);
    const step = index + 1;
    if (step % snapshotEvery === 0) {
      snapshots.push({ step, key, display: state.display });
    }
  }
  return {
    seed: fuzzSeed,
    steps: fuzzSteps,
    snapshotEvery,
    lcg: "seed = (seed * 1664525 + 1013904223) mod 2^32; key = keys[seed % keys.length]",
    keys: fuzzKeys,
    snapshots,
  };
}

await main();
