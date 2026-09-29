import assert from "node:assert/strict";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import { checkMarkdownLinks } from "../src/check-links.ts";

test("checkMarkdownLinks verifies relative Markdown file and anchor targets", async () => {
  const root = await mkdtemp(path.join(tmpdir(), "canadian-ham-links-"));
  try {
    await mkdir(path.join(root, "docs"), { recursive: true });
    await writeFile(path.join(root, "README.md"), "[Doc](docs/guide.md#hello-world)\n", "utf8");
    await writeFile(path.join(root, "docs/guide.md"), "# Hello, world!\n", "utf8");

    assert.deepEqual(await checkMarkdownLinks(root), []);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("checkMarkdownLinks reports missing relative Markdown targets", async () => {
  const root = await mkdtemp(path.join(tmpdir(), "canadian-ham-links-"));
  try {
    await writeFile(path.join(root, "README.md"), "[Missing](docs/missing.md)\n", "utf8");

    const issues = await checkMarkdownLinks(root);
    assert.equal(issues.length, 1);
    assert.match(issues[0]?.message ?? "", /target does not exist/);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
