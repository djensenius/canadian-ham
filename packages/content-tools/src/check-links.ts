import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const SKIPPED_DIRECTORIES = new Set([".git", "node_modules", "dist", "build", "coverage", ".pnpm-store"]);

export interface LinkIssue {
  readonly file: string;
  readonly line: number;
  readonly target: string;
  readonly message: string;
}

interface MarkdownLink {
  readonly file: string;
  readonly line: number;
  readonly target: string;
}

function toPosix(relativePath: string): string {
  return relativePath.split(path.sep).join("/");
}

function isExternalTarget(target: string): boolean {
  return /^[a-z][a-z0-9+.-]*:/i.test(target) || target.startsWith("//");
}

function splitTarget(target: string): { pathPart: string; fragment: string } {
  const hashIndex = target.indexOf("#");
  if (hashIndex === -1) {
    return { pathPart: target, fragment: "" };
  }
  return {
    pathPart: target.slice(0, hashIndex),
    fragment: target.slice(hashIndex + 1),
  };
}

function removeOptionalTitle(rawTarget: string): string {
  const trimmed = rawTarget.trim();
  if (trimmed.startsWith("<") && trimmed.includes(">")) {
    return trimmed.slice(1, trimmed.indexOf(">"));
  }
  const whitespaceIndex = trimmed.search(/\s/);
  return whitespaceIndex === -1 ? trimmed : trimmed.slice(0, whitespaceIndex);
}

function markdownLines(text: string): Array<{ line: string; lineNumber: number }> {
  const lines: Array<{ line: string; lineNumber: number }> = [];
  let lineNumber = 1;
  for (const line of text.split(/\r?\n/)) {
    lines.push({ line, lineNumber });
    lineNumber += 1;
  }
  return lines;
}

function extractMarkdownLinks(file: string, text: string): MarkdownLink[] {
  const links: MarkdownLink[] = [];
  const inlineLinkPattern = /(?<!!)\[[^\]\n]+\]\(([^)\n]+)\)/g;
  const referenceDefinitionPattern = /^ {0,3}\[([^\]\n]+)\]:\s*(\S+)/;
  let fence: { marker: "`" | "~"; length: number } | null = null;

  for (const { line, lineNumber } of markdownLines(text)) {
    const fenceMatch = line.match(/^ {0,3}(`{3,}|~{3,})/);
    if (fence !== null) {
      if (fenceMatch && fenceMatch[1]?.startsWith(fence.marker) && fenceMatch[1].length >= fence.length) {
        fence = null;
      }
      continue;
    }
    if (fenceMatch) {
      const marker = fenceMatch[1]!;
      fence = { marker: marker[0] as "`" | "~", length: marker.length };
      continue;
    }

    for (const match of line.matchAll(inlineLinkPattern)) {
      const target = removeOptionalTitle(match[1] ?? "");
      if (target.length > 0) {
        links.push({ file, line: lineNumber, target });
      }
    }

    const referenceMatch = line.match(referenceDefinitionPattern);
    const label = referenceMatch?.[1] ?? "";
    if (referenceMatch && !label.startsWith("^")) {
      const target = removeOptionalTitle(referenceMatch[2] ?? "");
      if (target.length > 0) {
        links.push({ file, line: lineNumber, target });
      }
    }
  }

  return links;
}

function slugForHeadingText(headingText: string): string {
  return headingText
    .trim()
    .replace(/`([^`]+)`/g, "$1")
    .replace(/<[^>]+>/g, "")
    .toLowerCase()
    .replace(/[^\p{Letter}\p{Number}\s-]/gu, "")
    .trim()
    .replace(/\s/g, "-");
}

function markdownAnchors(text: string): Set<string> {
  const anchors = new Set<string>();
  const seen = new Map<string, number>();
  const headingPattern = /^ {0,3}#{1,6}\s+(.+?)\s*#*\s*$/gm;
  for (const match of text.matchAll(headingPattern)) {
    const baseSlug = slugForHeadingText(match[1] ?? "");
    if (baseSlug.length === 0) {
      continue;
    }
    const previousCount = seen.get(baseSlug) ?? 0;
    seen.set(baseSlug, previousCount + 1);
    anchors.add(previousCount === 0 ? baseSlug : `${baseSlug}-${previousCount}`);
  }

  const htmlIdPattern = /\sid=["']([^"']+)["']/g;
  for (const match of text.matchAll(htmlIdPattern)) {
    if (match[1]) {
      anchors.add(match[1]);
    }
  }

  return anchors;
}

async function pathExists(targetPath: string): Promise<boolean> {
  try {
    await stat(targetPath);
    return true;
  } catch (error: unknown) {
    if (error instanceof Error && "code" in error && error.code === "ENOENT") {
      return false;
    }
    throw error;
  }
}

async function findMarkdownFiles(root: string, current = root): Promise<string[]> {
  const entries = await readdir(current, { withFileTypes: true });
  const files: string[] = [];
  for (const entry of entries) {
    if (entry.isDirectory()) {
      if (!SKIPPED_DIRECTORIES.has(entry.name)) {
        files.push(...await findMarkdownFiles(root, path.join(current, entry.name)));
      }
    } else if (entry.isFile() && entry.name.endsWith(".md")) {
      files.push(path.join(current, entry.name));
    }
  }
  return files.sort();
}

async function validateLink(root: string, link: MarkdownLink): Promise<LinkIssue | null> {
  if (isExternalTarget(link.target)) {
    return null;
  }

  const { pathPart, fragment } = splitTarget(link.target);
  const sourceFilePath = path.join(root, link.file);
  const sourceDirectory = path.dirname(sourceFilePath);
  let decodedPathPart: string;
  let decodedFragment: string;
  try {
    decodedPathPart = decodeURIComponent(pathPart);
    decodedFragment = decodeURIComponent(fragment);
  } catch {
    return { ...link, message: "target is not valid URI-encoded text" };
  }

  const targetPath = pathPart.length === 0 ? sourceFilePath : path.resolve(sourceDirectory, decodedPathPart);
  const relativeTarget = path.relative(root, targetPath);
  if (relativeTarget.startsWith("..") || path.isAbsolute(relativeTarget)) {
    return { ...link, message: "relative link points outside the repository" };
  }

  if (!await pathExists(targetPath)) {
    return { ...link, message: `target does not exist: ${toPosix(relativeTarget)}` };
  }

  if (fragment.length === 0) {
    return null;
  }

  if (!targetPath.endsWith(".md")) {
    return null;
  }

  const targetText = await readFile(targetPath, "utf8");
  const anchors = markdownAnchors(targetText);
  if (!anchors.has(decodedFragment)) {
    return { ...link, message: `anchor does not exist: #${fragment}` };
  }

  return null;
}

export async function checkMarkdownLinks(root = REPO_ROOT): Promise<LinkIssue[]> {
  const markdownFiles = await findMarkdownFiles(root);
  const issues: LinkIssue[] = [];
  for (const absoluteFile of markdownFiles) {
    const file = toPosix(path.relative(root, absoluteFile));
    const text = await readFile(absoluteFile, "utf8");
    const links = extractMarkdownLinks(file, text);
    for (const link of links) {
      const issue = await validateLink(root, link);
      if (issue !== null) {
        issues.push(issue);
      }
    }
  }
  return issues;
}

async function main(): Promise<void> {
  const issues = await checkMarkdownLinks(REPO_ROOT);
  if (issues.length > 0) {
    for (const issue of issues) {
      console.error(`${issue.file}:${issue.line}: ${issue.target} - ${issue.message}`);
    }
    process.exitCode = 1;
    return;
  }
  console.log("Markdown relative links verified.");
}

if (fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error: unknown) => {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`check-links: ${message}`);
    process.exitCode = 1;
  });
}
