import { realpathSync } from "node:fs";
import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const MODULE_PATH = currentModulePath();
const DIST_DIR = path.resolve(path.dirname(MODULE_PATH), "../dist/");
const URL_PATTERN = /https?:\/\/[^\s"'<>`]+/g;
const XML_NAMESPACE_URLS = new Set([
  "http://www.w3.org/1998/Math/MathML",
  "http://www.w3.org/1999/xhtml",
  "http://www.w3.org/1999/xlink",
  "http://www.w3.org/2000/svg",
  "http://www.w3.org/2000/xmlns/",
  "http://www.w3.org/XML/1998/namespace",
]);

// Official ISED/Government of Canada source URLs are allowed in dist only as
// bundled source/citation text or href values that are not fetched, preloaded,
// or cached automatically. Keep this allowlist exact; unexpected external URLs
// must still fail the audit rather than being hidden behind a broader network
// exception.
export const OFFICIAL_SOURCE_CITATION_URLS = new Set([
  "https://apc-cap.ic.gc.ca/datafiles/amat_basic_quest.zip#amat_basic_quest_delim.txt",
  "https://apc-cap.ic.gc.ca/datafiles/amat_adv_quest.zip#amat_adv_quest_delim.txt",
  "https://ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/downloads",
  "https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service",
]);

const TEXT_EXTENSIONS = new Set([".cjs", ".css", ".html", ".js", ".json", ".map", ".mjs", ".svg", ".txt", ".webmanifest", ".xml"]);
const BINARY_EXTENSIONS = new Set([".avif", ".gif", ".ico", ".jpg", ".jpeg", ".png", ".webp"]);

interface UrlFinding {
  readonly file: string;
  readonly line: number;
  readonly url: string;
}

interface CspFinding {
  readonly file: string;
  readonly line: number;
  readonly directive: string;
  readonly source: string;
}

const CSP_META_PATTERN = /<meta\b(?=[^>]*\bhttp-equiv\s*=\s*(["'])Content-Security-Policy\1)[^>]*>/iu;
const CSP_CONTENT_PATTERN = /\bcontent\s*=\s*"([^"]*)"/iu;
const ALLOWED_CSP_SOURCES = new Set(["'self'", "'none'"]);
const ALLOWED_DEFAULT_SRC_SOURCES = new Set(["'self'", "'none'"]);
const CSP_HASH_PATTERN = /^'sha(?:256|384|512)-[A-Za-z0-9+/=]+'$/u;

function currentModulePath(): string {
  const moduleUrl = new URL(import.meta.url);
  if (moduleUrl.protocol === "file:") {
    return fileURLToPath(moduleUrl);
  }
  const pathname = decodeURIComponent(moduleUrl.pathname);
  if (pathname.startsWith("/@fs/")) {
    return pathname.slice("/@fs".length);
  }
  return path.isAbsolute(pathname) ? pathname : path.join(process.cwd(), pathname);
}

function toPosix(relativePath: string): string {
  return relativePath.split(path.sep).join("/");
}

function normalizeUrl(rawUrl: string): string {
  return rawUrl.replace(/[),.;\]}]+$/g, "");
}

export function isAllowedUrl(url: string): boolean {
  return XML_NAMESPACE_URLS.has(url) || url.startsWith("https://react.dev/errors/") || OFFICIAL_SOURCE_CITATION_URLS.has(url);
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

export async function auditDistUrls(distDir = DIST_DIR): Promise<UrlFinding[]> {
  const distStat = await stat(distDir).catch(() => null);
  if (distStat === null || !distStat.isDirectory()) {
    throw new Error(`dist directory not found: ${distDir}`);
  }

  const findings: UrlFinding[] = [];
  for (const filePath of await findDistFiles(distDir)) {
    const extension = path.extname(filePath).toLowerCase();
    if (BINARY_EXTENSIONS.has(extension)) {
      continue;
    }
    if (!TEXT_EXTENSIONS.has(extension)) {
      throw new Error(`dist URL audit does not know how to scan ${toPosix(path.relative(distDir, filePath))}`);
    }
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

export async function auditDistCsp(distDir = DIST_DIR): Promise<CspFinding[]> {
  const indexPath = path.join(distDir, "index.html");
  const indexHtml = await readFile(indexPath, "utf8");
  const cspMetaMatch = indexHtml.match(CSP_META_PATTERN);
  if (cspMetaMatch === null || cspMetaMatch.index === undefined) {
    return [{ file: "index.html", line: 1, directive: "meta", source: "missing Content-Security-Policy meta tag" }];
  }

  const cspMeta = cspMetaMatch[0];
  const contentMatch = cspMeta.match(CSP_CONTENT_PATTERN);
  if (contentMatch === null) {
    return [{ file: "index.html", line: lineNumberForOffset(indexHtml, cspMetaMatch.index), directive: "meta", source: "missing content attribute" }];
  }

  const findings: CspFinding[] = [];
  let defaultSrcSources: readonly string[] | undefined;
  const seenDirectives = new Set<string>();
  const cspLine = lineNumberForOffset(indexHtml, cspMetaMatch.index);
  for (const directiveText of contentMatch[1].split(";")) {
    const tokens = directiveText.trim().split(/\s+/u).filter((token) => token.length > 0);
    const [directive, ...sources] = tokens;
    if (directive === undefined) {
      continue;
    }
    const directiveName = directive.toLowerCase();
    if (seenDirectives.has(directiveName)) {
      // Browsers honour only the first occurrence of a directive, so a duplicate can hide a weaker policy.
      findings.push({ file: "index.html", line: cspLine, directive, source: "duplicate directive" });
      continue;
    }
    seenDirectives.add(directiveName);
    if (directive === "default-src") {
      defaultSrcSources = sources;
      continue;
    }
    for (const source of sources) {
      if (isAllowedCspSource(directive, source)) {
        continue;
      }
      findings.push({
        file: "index.html",
        line: cspLine,
        directive,
        source,
      });
    }
  }

  if (defaultSrcSources === undefined) {
    findings.push({ file: "index.html", line: cspLine, directive: "default-src", source: "missing default-src directive" });
  } else if (!hasRequiredDefaultSrc(defaultSrcSources)) {
    findings.push({ file: "index.html", line: cspLine, directive: "default-src", source: defaultSrcSources.join(" ") || "missing source" });
  }

  return findings;
}

function hasRequiredDefaultSrc(sources: readonly string[]): boolean {
  const source = sources[0];
  return sources.length === 1 && source !== undefined && ALLOWED_DEFAULT_SRC_SOURCES.has(source);
}

function isAllowedCspSource(directive: string, source: string): boolean {
  return ALLOWED_CSP_SOURCES.has(source) || (directive === "img-src" && source === "data:") || CSP_HASH_PATTERN.test(source);
}

async function main(distDirArg = process.argv[2]): Promise<void> {
  const distDir = distDirArg === undefined ? DIST_DIR : path.resolve(distDirArg);
  const urlFindings = await auditDistUrls(distDir);
  const cspFindings = await auditDistCsp(distDir);
  if (urlFindings.length > 0 || cspFindings.length > 0) {
    for (const finding of urlFindings) {
      console.error(`${finding.file}:${finding.line}: unexpected URL ${finding.url}`);
    }
    for (const finding of cspFindings) {
      console.error(`${finding.file}:${finding.line}: unexpected CSP source ${finding.source} in ${finding.directive}`);
    }
    process.exitCode = 1;
    return;
  }
  console.log("dist URL and CSP audit passed.");
}

function isDirectCliInvocation(): boolean {
  if (process.argv[1] === undefined) {
    return false;
  }
  try {
    return realpathSync(path.resolve(process.argv[1])) === realpathSync(MODULE_PATH);
  } catch {
    return false;
  }
}

if (isDirectCliInvocation()) {
  main().catch((error: unknown) => {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`audit-dist-urls: ${message}`);
    process.exitCode = 1;
  });
}
