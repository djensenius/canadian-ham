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
    displayDigest: {
      algorithm: string;
      separatorByte: string;
      hex: string;
    };
    keys: readonly CalculatorKey[];
    snapshots: readonly FuzzSnapshot[];
  };
}

const fnv64Offset = 0xcbf29ce484222325n;
const fnv64Prime = 0x100000001b3n;
const uint64Mask = 0xffffffffffffffffn;
const digestSeparatorByte = 0x00;

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
  let displayDigest = fnv64Offset;
  const snapshots: FuzzSnapshot[] = [];
  for (let index = 0; index < fuzzSteps; index += 1) {
    seed = (Math.imul(seed, 1_664_525) + 1_013_904_223) >>> 0;
    const key = fuzzKeys[seed % fuzzKeys.length]!;
    state = applyCalculatorKey(state, key);
    displayDigest = updateDisplayDigest(displayDigest, state.display);
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
    displayDigest: {
      algorithm: "FNV-1a-64 over every step display's UTF-8 bytes in order, followed by one separator byte per display",
      separatorByte: "0x00",
      hex: hex64(displayDigest),
    },
    keys: fuzzKeys,
    snapshots,
  };
}

function updateDisplayDigest(hash: bigint, display: string): bigint {
  let next = hash;
  for (const byte of Buffer.from(display, "utf8")) {
    next = fnv64(next, byte);
  }
  return fnv64(next, digestSeparatorByte);
}

function fnv64(hash: bigint, byte: number): bigint {
  return ((hash ^ BigInt(byte)) * fnv64Prime) & uint64Mask;
}

function hex64(value: bigint): string {
  return value.toString(16).padStart(16, "0");
}

await main();
