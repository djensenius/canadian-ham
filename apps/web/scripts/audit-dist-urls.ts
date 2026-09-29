import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const DIST_DIR = fileURLToPath(new URL("../dist/", import.meta.url));
const URL_PATTERN = /https?:\/\/[^\s"'<>`]+/g;
const XML_NAMESPACE_URLS = new Set([
  "http://www.w3.org/1998/Math/MathML",
  "http://www.w3.org/1999/xhtml",
  "http://www.w3.org/1999/xlink",
  "http://www.w3.org/2000/svg",
  "http://www.w3.org/2000/xmlns/",
  "http://www.w3.org/XML/1998/namespace",
]);

interface UrlFinding {
  readonly file: string;
  readonly line: number;
  readonly url: string;
}

function toPosix(relativePath: string): string {
  return relativePath.split(path.sep).join("/");
}

function normalizeUrl(rawUrl: string): string {
  return rawUrl.replace(/[),.;\]}]+$/g, "");
}

function isAllowedUrl(url: string): boolean {
  return XML_NAMESPACE_URLS.has(url) || url.startsWith("https://react.dev/errors/");
}

function lineNumberForOffset(text: string, offset: number): number {
  let line = 1;
  for (let index = 0; index < offset; index += 1) {
    if (text.charCodeAt(index) === 10) {
      line += 1;
    }
  }
  return line;
}

async function findDistFiles(current: string): Promise<string[]> {
  const entries = await readdir(current, { withFileTypes: true });
  const files: string[] = [];
  for (const entry of entries) {
    const entryPath = path.join(current, entry.name);
    if (entry.isDirectory()) {
      files.push(...await findDistFiles(entryPath));
    } else if (entry.isFile()) {
      files.push(entryPath);
    }
  }
  return files.sort();
}

async function auditDistUrls(distDir = DIST_DIR): Promise<UrlFinding[]> {
  const distStat = await stat(distDir).catch(() => null);
  if (distStat === null || !distStat.isDirectory()) {
    throw new Error(`dist directory not found: ${distDir}`);
  }

  const findings: UrlFinding[] = [];
  for (const filePath of await findDistFiles(distDir)) {
    const text = await readFile(filePath, "utf8");
    for (const match of text.matchAll(URL_PATTERN)) {
      const rawUrl = match[0];
      const url = normalizeUrl(rawUrl);
      if (!isAllowedUrl(url)) {
        findings.push({
          file: toPosix(path.relative(distDir, filePath)),
          line: lineNumberForOffset(text, match.index ?? 0),
          url,
        });
      }
    }
  }
  return findings;
}

async function main(): Promise<void> {
  const findings = await auditDistUrls();
  if (findings.length > 0) {
    for (const finding of findings) {
      console.error(`${finding.file}:${finding.line}: unexpected URL ${finding.url}`);
    }
    process.exitCode = 1;
    return;
  }
  console.log("dist URL audit passed.");
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`audit-dist-urls: ${message}`);
  process.exitCode = 1;
});
