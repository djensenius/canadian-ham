import assert from "node:assert/strict";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import { checkMarkdownLinks } from "../src/check-links.ts";

async function withTempRepo(run: (root: string) => Promise<void>): Promise<void> {
  const root = await mkdtemp(path.join(tmpdir(), "canadian-ham-links-"));
  try {
    await run(root);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

test("checkMarkdownLinks verifies relative Markdown file and anchor targets", async () => {
  await withTempRepo(async (root) => {
    await mkdir(path.join(root, "docs"), { recursive: true });
    await writeFile(path.join(root, "README.md"), "[Doc](docs/guide.md#hello-world)\n", "utf8");
    await writeFile(path.join(root, "docs/guide.md"), "# Hello, world!\n", "utf8");

    assert.deepEqual(await checkMarkdownLinks(root), []);
  });
});

test("checkMarkdownLinks reports missing relative Markdown targets", async () => {
  await withTempRepo(async (root) => {
    await writeFile(path.join(root, "README.md"), "[Missing](docs/missing.md)\n", "utf8");

    const issues = await checkMarkdownLinks(root);
    assert.equal(issues.length, 1);
    assert.match(issues[0]?.message ?? "", /target does not exist/);
  });
});

test("checkMarkdownLinks verifies same-file anchors", async () => {
  await withTempRepo(async (root) => {
    await writeFile(path.join(root, "README.md"), "[Local](#same-file-heading)\n\n## Same file heading\n", "utf8");

    assert.deepEqual(await checkMarkdownLinks(root), []);
  });
});

test("checkMarkdownLinks reports missing same-file anchors", async () => {
  await withTempRepo(async (root) => {
    await writeFile(path.join(root, "README.md"), "[Missing](#missing-heading)\n\n## Existing heading\n", "utf8");

    const issues = await checkMarkdownLinks(root);
    assert.equal(issues.length, 1);
    assert.equal(issues[0]?.target, "#missing-heading");
    assert.match(issues[0]?.message ?? "", /anchor does not exist/);
  });
});

test("checkMarkdownLinks ignores links inside fenced code blocks", async () => {
  await withTempRepo(async (root) => {
    await writeFile(root + "/README.md", "```md\n[Missing](missing.md)\n```\n", "utf8");

    assert.deepEqual(await checkMarkdownLinks(root), []);
  });
});

test("checkMarkdownLinks does not treat footnote definitions as link definitions", async () => {
  await withTempRepo(async (root) => {
    await writeFile(path.join(root, "README.md"), "A note.[^1]\n\n[^1]: text that is not a link target\n", "utf8");

    assert.deepEqual(await checkMarkdownLinks(root), []);
  });
});

test("checkMarkdownLinks follows GitHub heading slugs by replacing each whitespace character", async () => {
  await withTempRepo(async (root) => {
    await writeFile(path.join(root, "README.md"), "[Heading](#a--b)\n\n## A  B\n", "utf8");

    assert.deepEqual(await checkMarkdownLinks(root), []);
  });
});

test("checkMarkdownLinks reports invalid URI encoding as one issue", async () => {
  await withTempRepo(async (root) => {
    await writeFile(path.join(root, "README.md"), "[Broken](#bad%zz)\n", "utf8");

    const issues = await checkMarkdownLinks(root);
    assert.equal(issues.length, 1);
    assert.equal(issues[0]?.target, "#bad%zz");
    assert.match(issues[0]?.message ?? "", /not valid URI-encoded text/);
  });
});
