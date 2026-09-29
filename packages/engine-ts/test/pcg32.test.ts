import assert from "node:assert/strict";
import test from "node:test";
import { pcg32DemoValues } from "../src/index.ts";

test("pcg32_srandom(42, 54) matches the published PCG C demo outputs", () => {
  assert.deepEqual(
    pcg32DemoValues().map((value) => `0x${value.toString(16).padStart(8, "0")}`),
    ["0xa15c02b7", "0x7b47f409", "0xba1d3330", "0x83d2f293", "0xbfa4784b", "0xcbed606e"],
  );
});
