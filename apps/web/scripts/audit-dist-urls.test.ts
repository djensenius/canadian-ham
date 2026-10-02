import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdir, mkdtemp, rm, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterEach, describe, it } from "vitest";

import { auditDistCsp, auditDistUrls, isAllowedUrl, OFFICIAL_SOURCE_CITATION_URLS } from "./audit-dist-urls";

const officialSourceUrls = [...OFFICIAL_SOURCE_CITATION_URLS];
const questionBankSourceUrl = "https://apc-cap.ic.gc.ca/datafiles/amat_basic_quest.zip#amat_basic_quest_delim.txt";
const rbr4CitationUrl = "https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service";
const scriptPath = testScriptPath();
const tempDirs: string[] = [];

function testScriptPath(): string {
  const scriptUrl = new URL("audit-dist-urls.ts", import.meta.url);
  if (scriptUrl.protocol === "file:") {
    return fileURLToPath(scriptUrl);
  }
  const pathname = decodeURIComponent(scriptUrl.pathname);
  if (pathname.startsWith("/@fs/")) {
    return pathname.slice("/@fs".length);
  }
  return join(process.cwd(), pathname.replace(/^\//u, ""));
}

afterEach(async () => {
  await Promise.all(tempDirs.splice(0).map((dir) => rm(dir, { force: true, recursive: true })));
});

describe("dist URL audit", () => {
  it("allows only exact official-source citation URLs", () => {
    assert.ok(officialSourceUrls.includes(questionBankSourceUrl));
    assert.ok(officialSourceUrls.includes(rbr4CitationUrl));
    assert.equal(isAllowedUrl(questionBankSourceUrl), true);
    assert.equal(isAllowedUrl(rbr4CitationUrl), true);
    assert.equal(isAllowedUrl("https://ised-isde.canada.ca/site/unlisted-official-page"), false);
    assert.equal(isAllowedUrl("https://www.ised-isde.canada.ca/site/unlisted-official-page"), false);
  });

  it("reports unexpected URLs while allowing XML namespaces, React errors, and citation links", async () => {
    const distDir = await mkdtemp(join(tmpdir(), "canadian-ham-url-audit-"));
    tempDirs.push(distDir);
    await writeFile(join(distDir, "index.html"), `<svg xmlns="http://www.w3.org/2000/svg"></svg><a href="${rbr4CitationUrl}">RBR-4</a><p>${questionBankSourceUrl}</p>`, "utf8");
    await writeFile(join(distDir, "app.js"), `console.log("https://react.dev/errors/418"); fetch("https://example.com/api");`, "utf8");

    assert.deepEqual(await auditDistUrls(distDir), [{ file: "app.js", line: 1, url: "https://example.com/api" }]);
  });

  it("passes the built-index CSP when it contains only self, none, data, and script hash sources", async () => {
    const distDir = await mkdtemp(join(tmpdir(), "canadian-ham-csp-audit-"));
    tempDirs.push(distDir);
    await writeFile(join(distDir, "index.html"), `<meta http-equiv="Content-Security-Policy" content="default-src 'self'; base-uri 'self'; object-src 'none'; form-action 'none'; connect-src 'self'; img-src 'self' data:; font-src 'self'; script-src 'self' 'sha256-E77amc0CnFRHG8inr16ONddkqQaLnAfKqxm96My0KQs='; style-src 'self'">`, "utf8");

    assert.deepEqual(await auditDistCsp(distDir), []);
  });

  it("reports CSP source expressions that could allow third-party origins", async () => {
    const distDir = await mkdtemp(join(tmpdir(), "canadian-ham-csp-audit-third-party-"));
    tempDirs.push(distDir);
    await writeFile(join(distDir, "index.html"), `<meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' cdn.example; connect-src 'self' https://api.example.test">`, "utf8");

    assert.deepEqual(await auditDistCsp(distDir), [
      { file: "index.html", line: 1, directive: "script-src", source: "cdn.example" },
      { file: "index.html", line: 1, directive: "connect-src", source: "https://api.example.test" },
    ]);
  });

  it("fails when dist contains a PDF file", async () => {
    const distDir = await mkdtemp(join(tmpdir(), "canadian-ham-url-audit-pdf-"));
    tempDirs.push(distDir);
    await writeFile(join(distDir, "reference.pdf"), "not a real PDF", "utf8");

    await assert.rejects(() => auditDistUrls(distDir), /does not know how to scan reference\.pdf/);
  });

  it("runs from the CLI and scans the requested dist directory", async () => {
    const distDir = await mkdtemp(join(tmpdir(), "canadian-ham-url-audit-cli-"));
    tempDirs.push(distDir);
    await writeFile(join(distDir, "index.html"), `<a href="https://example.com/api">bad URL</a>`, "utf8");

    const result = spawnSync(process.execPath, [scriptPath, distDir], { encoding: "utf8" });

    assert.equal(result.status, 1);
    assert.match(result.stderr, /index\.html:1: unexpected URL https:\/\/example\.com\/api/);
  });

  it("runs the CSP audit from the CLI", async () => {
    const distDir = await mkdtemp(join(tmpdir(), "canadian-ham-csp-audit-cli-"));
    tempDirs.push(distDir);
    await writeFile(join(distDir, "index.html"), `<meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' cdn.example">`, "utf8");

    const result = spawnSync(process.execPath, [scriptPath, distDir], { encoding: "utf8" });

    assert.equal(result.status, 1);
    assert.match(result.stderr, /index\.html:1: unexpected CSP source cdn\.example in script-src/);
  });

  it("runs from the CLI through a symlink and scans the requested dist directory", async () => {
    const tempDir = await mkdtemp(join(tmpdir(), "canadian-ham-url-audit-symlink-"));
    tempDirs.push(tempDir);
    const distDir = join(tempDir, "dist");
    const linkedScript = join(tempDir, "audit-dist-urls.ts");
    await mkdir(distDir);
    await symlink(scriptPath, linkedScript);
    await writeFile(join(distDir, "index.html"), `<a href="https://example.com/api">bad URL</a>`, "utf8");

    const result = spawnSync(process.execPath, [linkedScript, distDir], { encoding: "utf8" });

    assert.equal(result.status, 1);
    assert.match(result.stderr, /index\.html:1: unexpected URL https:\/\/example\.com\/api/);
  });
});
