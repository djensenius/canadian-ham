import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import { checkLessonCoverage, LessonCoverageError } from "../src/check-lesson-coverage.ts";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const CHECK_SCRIPT = path.join(REPO_ROOT, "packages/content-tools/src/check-lesson-coverage.ts");
const MODULE_ORDERS: Record<string, number> = {
  M1: 8,
  M2: 7,
  M3: 4,
  M4: 2,
  M5: 1,
  M6: 3,
  M7: 5,
  M8: 6,
};

type FixtureModule = {
  id: string;
  categoryId: string;
  order: number;
  title: string;
  lessonIds: string[];
  status: string;
};

type FixtureLesson = {
  id: string;
  moduleId: string;
  categoryIds: string[];
  title: string;
  covers: string[];
  prerequisites: string[];
  status: string;
};

async function withFixture(testName: string, run: (root: string) => Promise<void>): Promise<void> {
  const root = await mkdtemp(path.join(tmpdir(), `canadian-ham-coverage-${testName}-`));
  try {
    await mkdir(path.join(root, "content/generated/basic-2025-07-15"), { recursive: true });
    await mkdir(path.join(root, "content/lessons"), { recursive: true });
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

function categoryId(moduleNumber: number): string {
  return `B-00${moduleNumber}`;
}

function lessonId(moduleNumber: number, lessonNumber = 1): string {
  return `L-00${moduleNumber}-${String(lessonNumber).padStart(2, "0")}`;
}

function baseFixture(): { modules: Map<string, FixtureModule>; lessons: Map<string, FixtureLesson>; expectedSubsectionIds: string[] } {
  const modules = new Map<string, FixtureModule>();
  const lessons = new Map<string, FixtureLesson>();
  const expectedSubsectionIds: string[] = [];

  for (let moduleNumber = 1; moduleNumber <= 8; moduleNumber += 1) {
    const moduleId = `M${moduleNumber}`;
    const category = categoryId(moduleNumber);
    const firstLessonId = lessonId(moduleNumber);
    const subsectionId = `${category}-001`;
    modules.set(moduleId, {
      id: moduleId,
      categoryId: category,
      order: MODULE_ORDERS[moduleId]!,
      title: `Fixture module ${moduleNumber}`,
      lessonIds: [firstLessonId],
      status: "outline",
    });
    lessons.set(firstLessonId, {
      id: firstLessonId,
      moduleId,
      categoryIds: [category],
      title: `Fixture lesson ${moduleNumber}`,
      covers: [subsectionId],
      prerequisites: [],
      status: "outline",
    });
    expectedSubsectionIds.push(subsectionId);
  }

  return { modules, lessons, expectedSubsectionIds };
}

function moduleMarkdown(module: FixtureModule): string {
  return `---
type: module
id: ${module.id}
categoryId: ${module.categoryId}
order: ${module.order}
title:
  en: "${module.title}"
  fr: null
lessonIds:
${module.lessonIds.map((id) => `  - ${id}`).join("\n")}
status: ${module.status}
---
# ${module.title}
`;
}

function lessonMarkdown(lesson: FixtureLesson): string {
  return `---
type: lesson
id: ${lesson.id}
moduleId: ${lesson.moduleId}
categoryIds:
${lesson.categoryIds.map((id) => `  - ${id}`).join("\n")}
title:
  en: "${lesson.title}"
  fr: null
covers:
${lesson.covers.map((id) => `  - ${id}`).join("\n")}
objectives:
  - "Use the fixture objective."
prerequisites:${lesson.prerequisites.length === 0 ? " []" : `\n${lesson.prerequisites.map((id) => `  - ${id}`).join("\n")}`}
estimatedMinutes: 10
quizIds: []
status: ${lesson.status}
---
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

async function writeFixture(
  root: string,
  mutate?: (fixture: { modules: Map<string, FixtureModule>; lessons: Map<string, FixtureLesson>; expectedSubsectionIds: string[] }) => void,
): Promise<void> {
  const fixture = baseFixture();
  mutate?.(fixture);
  await writeSubsections(root, fixture.expectedSubsectionIds);
  for (const module of fixture.modules.values()) {
    const moduleDir = path.join(root, "content/lessons", module.id.toLowerCase());
    await mkdir(moduleDir, { recursive: true });
    await writeFile(path.join(moduleDir, "index.md"), moduleMarkdown(module), "utf8");
  }
  for (const lesson of fixture.lessons.values()) {
    const moduleDir = path.join(root, "content/lessons", lesson.moduleId.toLowerCase());
    await mkdir(moduleDir, { recursive: true });
    await writeFile(path.join(moduleDir, `${lesson.id.toLowerCase()}.md`), lessonMarkdown(lesson), "utf8");
  }
}

async function runCheck(root: string) {
  return checkLessonCoverage({
    lessonRoot: path.join(root, "content/lessons"),
    expectedSubsectionsPath: path.join(root, "content/generated/basic-2025-07-15/subsections.json"),
  });
}

async function assertCoverageError(root: string, predicate: (error: LessonCoverageError) => boolean): Promise<void> {
  await assert.rejects(
    () => runCheck(root),
    (error: unknown) => error instanceof LessonCoverageError && predicate(error),
  );
}

test("coverage passes and reports duplicate subsection coverage", async () => {
  await withFixture("pass", async (root) => {
    await writeFixture(root, ({ modules, lessons }) => {
      modules.get("M1")!.lessonIds.push("L-001-02");
      lessons.set("L-001-02", {
        id: "L-001-02",
        moduleId: "M1",
        categoryIds: ["B-001"],
        title: "Second fixture lesson",
        covers: ["B-001-001"],
        prerequisites: [],
        status: "outline",
      });
    });

    const report = await runCheck(root);

    assert.equal(report.coveredSubsectionCount, 8);
    assert.deepEqual(report.duplicateCoverage, [{ subsectionId: "B-001-001", lessonIds: ["L-001-01", "L-001-02"] }]);
    assert.match(report.summaryLines.join("\n"), /Duplicate subsection coverage: B-001-001/);
  });
});

test("coverage accepts draft, review, and published status values", async () => {
  await withFixture("statuses", async (root) => {
    await writeFixture(root, ({ modules, lessons }) => {
      modules.get("M1")!.status = "draft";
      modules.get("M2")!.status = "review";
      modules.get("M3")!.status = "published";
      lessons.get("L-001-01")!.status = "draft";
      lessons.get("L-002-01")!.status = "review";
      lessons.get("L-003-01")!.status = "published";
    });

    const report = await runCheck(root);

    assert.equal(report.moduleCount, 8);
    assert.equal(report.lessonCount, 8);
  });
});

test("coverage fails when an expected subsection is missing", async () => {
  await withFixture("missing", async (root) => {
    await writeFixture(root, ({ expectedSubsectionIds }) => {
      expectedSubsectionIds.push("B-001-002");
    });

    await assertCoverageError(root, (error) => error.report.missingSubsectionIds.includes("B-001-002"));
  });
});

test("coverage fails when a lesson references an unknown subsection", async () => {
  await withFixture("unknown", async (root) => {
    await writeFixture(root, ({ lessons }) => {
      lessons.get("L-001-01")!.covers.push("B-001-999");
    });

    await assertCoverageError(root, (error) => error.report.unknownSubsectionIds.includes("B-001-999"));
  });
});

test("coverage fails on malformed lesson front matter", async () => {
  await withFixture("malformed-lesson", async (root) => {
    await writeFixture(root);
    const lessonPath = path.join(root, "content/lessons/m1/l-001-01.md");
    const markdown = lessonMarkdown({
      id: "L-001-01",
      moduleId: "M1",
      categoryIds: ["B-001"],
      title: "Fixture lesson 1",
      covers: ["B-001-001"],
      prerequisites: [],
      status: "outline",
    }).replace("covers:\n  - B-001-001", "covers: B-001-001");
    await writeFile(lessonPath, markdown, "utf8");

    await assertCoverageError(root, (error) => error.report.malformedFiles.some((file) => file.filePath === lessonPath));
  });
});

test("coverage fails on malformed module front matter", async () => {
  await withFixture("malformed-module", async (root) => {
    await writeFixture(root);
    const modulePath = path.join(root, "content/lessons/m1/index.md");
    const markdown = moduleMarkdown({
      id: "M1",
      categoryId: "B-001",
      order: 8,
      title: "Fixture module 1",
      lessonIds: ["L-001-01"],
      status: "outline",
    }).replace("order: 8\n", "");
    await writeFile(modulePath, markdown, "utf8");

    await assertCoverageError(root, (error) => error.report.malformedFiles.some((file) => file.filePath === modulePath));
  });
});

test("coverage fails on unquoted scalar values containing spaces", async () => {
  await withFixture("unquoted-spaces", async (root) => {
    await writeFixture(root);
    const lessonPath = path.join(root, "content/lessons/m1/l-001-01.md");
    const markdown = lessonMarkdown({
      id: "L-001-01",
      moduleId: "M1",
      categoryIds: ["B-001"],
      title: "Fixture lesson 1",
      covers: ["B-001-001"],
      prerequisites: [],
      status: "outline",
    }).replace("  en: \"Fixture lesson 1\"", "  en: Fixture lesson 1");
    await writeFile(lessonPath, markdown, "utf8");

    await assertCoverageError(root, (error) => error.report.malformedFiles.some((file) => /quote scalar values/.test(file.message)));
  });
});

test("coverage fails when a module lessonIds entry does not exist", async () => {
  await withFixture("module-unknown-lesson", async (root) => {
    await writeFixture(root, ({ modules }) => {
      modules.get("M1")!.lessonIds.push("L-001-99");
    });

    await assertCoverageError(root, (error) => error.report.malformedFiles.some((file) => /unknown lesson L-001-99/.test(file.message)));
  });
});

test("coverage fails when a module lessonIds entry belongs to another module", async () => {
  await withFixture("module-lesson-mismatch", async (root) => {
    await writeFixture(root, ({ modules }) => {
      modules.get("M2")!.lessonIds.push("L-001-01");
    });

    await assertCoverageError(root, (error) => error.report.malformedFiles.some((file) => /L-001-01 with moduleId M1, expected M2/.test(file.message)));
  });
});

test("coverage fails when a lesson moduleId does not refer to an existing module", async () => {
  await withFixture("lesson-unknown-module", async (root) => {
    await writeFixture(root, ({ modules }) => {
      modules.delete("M1");
    });

    await assertCoverageError(root, (error) => error.report.malformedFiles.some((file) => /unknown module M1/.test(file.message)));
  });
});

test("coverage fails when a lesson prerequisite does not exist", async () => {
  await withFixture("unknown-prerequisite", async (root) => {
    await writeFixture(root, ({ lessons }) => {
      lessons.get("L-001-01")!.prerequisites.push("L-001-99");
    });

    await assertCoverageError(root, (error) => error.report.malformedFiles.some((file) => /unknown lesson L-001-99/.test(file.message)));
  });
});

test("coverage fails when a lesson covers entry does not match its categoryIds prefix", async () => {
  await withFixture("cover-prefix", async (root) => {
    await writeFixture(root, ({ lessons }) => {
      lessons.get("L-001-01")!.covers.push("B-002-001");
    });

    await assertCoverageError(root, (error) => error.report.malformedFiles.some((file) => /covers B-002-001 does not match categoryIds B-001/.test(file.message)));
  });
});

test("coverage fails when module order values do not cover 1 through 8", async () => {
  await withFixture("bad-order", async (root) => {
    await writeFixture(root, ({ modules }) => {
      modules.get("M1")!.order = 1;
    });

    await assertCoverageError(root, (error) => error.report.malformedFiles.some((file) => /module order values must uniquely cover exactly 1 through 8/.test(file.message)));
  });
});

test("CLI runs and exits non-zero on bad content", async () => {
  await withFixture("cli-failure", async (root) => {
    await writeFixture(root, ({ expectedSubsectionIds }) => {
      expectedSubsectionIds.push("B-001-002");
    });

    const result = await new Promise<{ code: number | null; stderr: string }>((resolve, reject) => {
      const child = spawn(process.execPath, [
        CHECK_SCRIPT,
        "--lessons",
        path.join(root, "content/lessons"),
        "--subsections",
        path.join(root, "content/generated/basic-2025-07-15/subsections.json"),
      ], { stdio: ["ignore", "ignore", "pipe"] });
      let stderr = "";
      if (child.stderr === null) {
        reject(new Error("expected child stderr pipe"));
        return;
      }
      child.stderr.setEncoding("utf8");
      child.stderr.on("data", (chunk: string) => {
        stderr += chunk;
      });
      child.on("error", reject);
      child.on("close", (code) => {
        resolve({ code, stderr });
      });
    });

    assert.equal(result.code, 1);
    assert.match(result.stderr, /Missing subsections: B-001-002/);
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
