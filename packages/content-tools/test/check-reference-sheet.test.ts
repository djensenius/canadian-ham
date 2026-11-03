import assert from "node:assert/strict";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import { validateReferenceSheet, type RequiredReferenceSheetEntry } from "../src/check-reference-sheet.ts";

const fixtureEntry: RequiredReferenceSheetEntry = {
  name: "fixture formula",
  sheetText: "E = I x R",
  lessonText: "E = I x R",
  lessonPath: "content/lessons/fixture.md",
};
const fixtureSections = ["## Ohm's law"];
const validSheet = `# Original Basic formula and reference study aid

Study aid for Canadian Ham practice; the real Basic exam provides the official ISED reference sheet.

## Ohm's law

E = I x R
`;

async function withReferenceFixture(run: (fixture: { readonly root: string; readonly sheetPath: string; readonly lessonPath: string }) => Promise<void>): Promise<void> {
  const root = await mkdtemp(path.join(tmpdir(), "canadian-ham-reference-sheet-"));
  const sheetPath = path.join(root, "content/reference-sheet/basic.md");
  const lessonPath = path.join(root, fixtureEntry.lessonPath);
  try {
    await mkdir(path.dirname(sheetPath), { recursive: true });
    await mkdir(path.dirname(lessonPath), { recursive: true });
    await writeFile(sheetPath, validSheet, "utf8");
    await writeFile(lessonPath, "Lesson teaches E = I x R for Ohm's law.\n", "utf8");
    await run({ root, sheetPath, lessonPath });
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

async function validateFixture(root: string, sheetPath: string, entry: RequiredReferenceSheetEntry = fixtureEntry): Promise<readonly string[]> {
  return validateReferenceSheet({
    repoRoot: root,
    sheetPath,
    requiredEntries: [entry],
    requiredSections: fixtureSections,
  });
}

test("validateReferenceSheet accepts a valid fixture", async () => {
  await withReferenceFixture(async ({ root, sheetPath }) => {
    assert.deepEqual(await validateFixture(root, sheetPath), []);
  });
});

test("validateReferenceSheet rejects a missing heading", async () => {
  await withReferenceFixture(async ({ root, sheetPath }) => {
    await writeFile(sheetPath, validSheet.replace("# Original Basic formula and reference study aid\n", "# Formula sheet\n"), "utf8");

    const issues = await validateFixture(root, sheetPath);
    assert.ok(issues.some((issue) => /must start with the approved original-study-aid heading/.test(issue)));
  });
});

test("validateReferenceSheet rejects a missing required section", async () => {
  await withReferenceFixture(async ({ root, sheetPath }) => {
    await writeFile(sheetPath, validSheet.replace("## Ohm's law", "## Power"), "utf8");

    const issues = await validateFixture(root, sheetPath);
    assert.ok(issues.some((issue) => /missing ## Ohm's law/.test(issue)));
  });
});

test("validateReferenceSheet rejects a missing required entry", async () => {
  await withReferenceFixture(async ({ root, sheetPath }) => {
    await writeFile(sheetPath, validSheet.replace("E = I x R", "I = E / R"), "utf8");

    const issues = await validateFixture(root, sheetPath);
    assert.ok(issues.some((issue) => /missing fixture formula: E = I x R/.test(issue)));
  });
});

test("validateReferenceSheet rejects lesson drift", async () => {
  await withReferenceFixture(async ({ root, sheetPath, lessonPath }) => {
    await writeFile(lessonPath, "Lesson drifted to a different notation.\n", "utf8");

    const issues = await validateFixture(root, sheetPath);
    assert.ok(issues.some((issue) => /content\/lessons\/fixture.md no longer verifies fixture formula/.test(issue)));
  });
});

test("validateReferenceSheet rejects prohibited official-reference wording", async () => {
  await withReferenceFixture(async ({ root, sheetPath }) => {
    await writeFile(sheetPath, `${validSheet}\nReference Material for Amateur Radio\n`, "utf8");

    const issues = await validateFixture(root, sheetPath);
    assert.ok(issues.some((issue) => /official-reference-sheet wording/.test(issue)));
  });
});
