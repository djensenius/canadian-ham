import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { contrastRows, type TokenSet } from "../src/token-utils.ts";

const tokens = JSON.parse(await readFile(new URL("../tokens.json", import.meta.url), "utf8")) as TokenSet;

test("declared foreground/background contrast pairs meet WCAG 2.2 AA thresholds", () => {
  const rows = contrastRows(tokens);
  const table = rows.map((row) => ({
    id: row.id,
    theme: row.theme,
    kind: row.kind,
    ratio: row.ratio.toFixed(2),
    minimum: row.minimum.toFixed(1),
  }));
  console.table(table);

  for (const row of rows) {
    assert.ok(
      row.ratio >= row.minimum,
      `${row.id} contrast ${row.ratio.toFixed(2)} is below ${row.minimum.toFixed(1)} for ${row.kind}`,
    );
  }
});
