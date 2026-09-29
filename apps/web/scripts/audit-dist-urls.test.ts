import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, describe, it } from "vitest";

import { auditDistUrls, isAllowedUrl, OFFICIAL_SOURCE_CITATION_URLS } from "./audit-dist-urls";

const rbr4CitationUrl = [...OFFICIAL_SOURCE_CITATION_URLS][0]!;
const scriptPath = join(process.cwd(), "scripts/audit-dist-urls.ts");
const tempDirs: string[] = [];

afterEach(async () => {
  await Promise.all(tempDirs.splice(0).map((dir) => rm(dir, { force: true, recursive: true })));
});

describe("dist URL audit", () => {
  it("allows only exact official-source citation URLs", () => {
    assert.equal(isAllowedUrl(rbr4CitationUrl), true);
    assert.equal(isAllowedUrl("https://ised-isde.canada.ca/site/unlisted-official-page"), false);
    assert.equal(isAllowedUrl("https://www.ised-isde.canada.ca/site/unlisted-official-page"), false);
  });

  it("reports unexpected URLs while allowing XML namespaces, React errors, and citation links", async () => {
    const distDir = await mkdtemp(join(tmpdir(), "canadian-ham-url-audit-"));
    tempDirs.push(distDir);
    await writeFile(join(distDir, "index.html"), `<svg xmlns="http://www.w3.org/2000/svg"></svg><a href="${rbr4CitationUrl}">RBR-4</a>`, "utf8");
    await writeFile(join(distDir, "app.js"), `console.log("https://react.dev/errors/418"); fetch("https://example.com/api");`, "utf8");

    assert.deepEqual(await auditDistUrls(distDir), [{ file: "app.js", line: 1, url: "https://example.com/api" }]);
  });

  it("runs from the CLI and scans the requested dist directory", async () => {
    const distDir = await mkdtemp(join(tmpdir(), "canadian-ham-url-audit-cli-"));
    tempDirs.push(distDir);
    await writeFile(join(distDir, "index.html"), `<a href="https://example.com/api">bad URL</a>`, "utf8");

    const result = spawnSync(process.execPath, [scriptPath, distDir], { encoding: "utf8" });

    assert.equal(result.status, 1);
    assert.match(result.stderr, /index\.html:1: unexpected URL https:\/\/example\.com\/api/);
  });
});
