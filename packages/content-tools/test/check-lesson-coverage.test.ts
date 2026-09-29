import assert from "node:assert/strict";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import { checkLessonCoverage, LessonCoverageError } from "../src/check-lesson-coverage.ts";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));

async function withFixture(testName: string, run: (root: string) => Promise<void>): Promise<void> {
  const root = await mkdtemp(path.join(tmpdir(), `canadian-ham-coverage-${testName}-`));
  try {
    await mkdir(path.join(root, "content/generated/basic-2025-07-15"), { recursive: true });
    await mkdir(path.join(root, "content/lessons/m1"), { recursive: true });
    await run(root);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

async function writeSubsections(root: string, ids: string[]): Promise<void> {
  await writeFile(
    path.join(root, "content/generated/basic-2025-07-15/subsections.json"),
    `${JSON.stringify(ids.map((id) => ({ id })), null, 2)}\n`,
    "utf8",
  );
}

function lessonMarkdown(covers: string[], extra = ""): string {
  return `---
type: lesson
id: L-001-01
moduleId: M1
categoryIds:
  - B-001
title:
  en: "Fixture lesson"
  fr: null
covers:
${covers.map((id) => `  - ${id}`).join("\n")}
objectives:
  - "Use the fixture objective."
prerequisites: []
estimatedMinutes: 10
quizIds: []
status: outline
${extra}---
## Learning objectives

- Use the fixture objective.

## Key concepts

- Synthetic concept.

## Coverage

- Synthetic coverage.

## Teaching notes

- Synthetic note.
`;
}

function moduleMarkdown(): string {
  return `---
type: module
id: M1
categoryId: B-001
title:
  en: "Fixture module"
  fr: null
lessonIds:
  - L-001-01
status: outline
---
# Fixture module
`;
}

async function runCheck(root: string) {
  return checkLessonCoverage({
    lessonRoot: path.join(root, "content/lessons"),
    expectedSubsectionsPath: path.join(root, "content/generated/basic-2025-07-15/subsections.json"),
  });
}

test("coverage passes and reports duplicate subsection coverage", async () => {
  await withFixture("pass", async (root) => {
    await writeSubsections(root, ["B-001-001", "B-001-002"]);
    await writeFile(path.join(root, "content/lessons/m1/index.md"), moduleMarkdown(), "utf8");
    await writeFile(path.join(root, "content/lessons/m1/l-001-01.md"), lessonMarkdown(["B-001-001", "B-001-002"]), "utf8");
    await writeFile(path.join(root, "content/lessons/m1/l-001-02.md"), lessonMarkdown(["B-001-002"]).replace("L-001-01", "L-001-02"), "utf8");

    const report = await runCheck(root);

    assert.equal(report.coveredSubsectionCount, 2);
    assert.deepEqual(report.duplicateCoverage, [{ subsectionId: "B-001-002", lessonIds: ["L-001-01", "L-001-02"] }]);
    assert.match(report.summaryLines.join("\n"), /Duplicate subsection coverage: B-001-002/);
  });
});

test("coverage fails when an expected subsection is missing", async () => {
  await withFixture("missing", async (root) => {
    await writeSubsections(root, ["B-001-001", "B-001-002"]);
    await writeFile(path.join(root, "content/lessons/m1/index.md"), moduleMarkdown(), "utf8");
    await writeFile(path.join(root, "content/lessons/m1/l-001-01.md"), lessonMarkdown(["B-001-001"]), "utf8");

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonCoverageError && error.report.missingSubsectionIds.includes("B-001-002"),
    );
  });
});

test("coverage fails when a lesson references an unknown subsection", async () => {
  await withFixture("unknown", async (root) => {
    await writeSubsections(root, ["B-001-001"]);
    await writeFile(path.join(root, "content/lessons/m1/index.md"), moduleMarkdown(), "utf8");
    await writeFile(path.join(root, "content/lessons/m1/l-001-01.md"), lessonMarkdown(["B-001-001", "B-999-001"]), "utf8");

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonCoverageError && error.report.unknownSubsectionIds.includes("B-999-001"),
    );
  });
});

test("coverage fails on malformed lesson front matter", async () => {
  await withFixture("malformed", async (root) => {
    await writeSubsections(root, ["B-001-001"]);
    await writeFile(path.join(root, "content/lessons/m1/index.md"), moduleMarkdown(), "utf8");
    await writeFile(path.join(root, "content/lessons/m1/l-001-01.md"), lessonMarkdown(["B-001-001"]).replace("covers:", "covers: B-001-001"), "utf8");

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonCoverageError && error.report.malformedFiles.length === 1,
    );
  });
});

test("real lesson content covers the generated Basic subsections", async () => {
  const report = await checkLessonCoverage({
    lessonRoot: path.join(REPO_ROOT, "content/lessons"),
    expectedSubsectionsPath: path.join(REPO_ROOT, "content/generated/basic-2025-07-15/subsections.json"),
  });

  assert.equal(report.expectedSubsectionCount, 100);
  assert.equal(report.coveredSubsectionCount, 100);
  assert.equal(report.moduleCount, 8);
  assert.ok(report.lessonCount >= 30);
  assert.ok(report.lessonCount <= 45);
});
