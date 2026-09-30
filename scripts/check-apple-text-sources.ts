#!/usr/bin/env node
import { existsSync, mkdtempSync, readdirSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, extname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_SOURCE_ROOTS = [
  join(ROOT, "apps/apple/CanadianHam"),
  join(ROOT, "apps/apple/Platforms"),
];
const SELF_TEST_FIXTURE = join(ROOT, "scripts/fixtures/apple-text-sources");

// content(question) means official/question-bank text in the active question language.
const MARKER_RE = /\/\/\s*l10n:\s*(?:content\((?:en|fr|question)\)|localized\b|verbatim\b)/;
const STRING_LITERAL_RE = /^#*"/;

interface Violation {
  path: string;
  line: number;
  callee: string;
  expression: string;
  message: string;
}

interface CallPattern {
  callee: string;
  pattern: RegExp;
  requiresMarker: boolean;
}

const INIT_SUFFIX_RE = "(?:\\s*\\.\\s*init)?";

const callPatterns: CallPattern[] = [
  { callee: "LocalizedStringKey", pattern: new RegExp(`\\bLocalizedStringKey${INIT_SUFFIX_RE}\\s*\\(`, "g"), requiresMarker: false },
  { callee: "Text", pattern: new RegExp(`\\bText${INIT_SUFFIX_RE}\\s*\\(`, "g"), requiresMarker: true },
  { callee: "Label", pattern: new RegExp(`\\bLabel${INIT_SUFFIX_RE}\\s*\\(`, "g"), requiresMarker: true },
  { callee: "Button", pattern: new RegExp(`\\bButton${INIT_SUFFIX_RE}\\s*\\(`, "g"), requiresMarker: true },
  { callee: "navigationTitle", pattern: new RegExp(`\\.navigationTitle${INIT_SUFFIX_RE}\\s*\\(`, "g"), requiresMarker: true },
  { callee: "accessibilityLabel", pattern: new RegExp(`\\.accessibilityLabel${INIT_SUFFIX_RE}\\s*\\(`, "g"), requiresMarker: true },
  { callee: "accessibilityHint", pattern: new RegExp(`\\.accessibilityHint${INIT_SUFFIX_RE}\\s*\\(`, "g"), requiresMarker: true },
  { callee: "accessibilityValue", pattern: new RegExp(`\\.accessibilityValue${INIT_SUFFIX_RE}\\s*\\(`, "g"), requiresMarker: true },
  { callee: ".init", pattern: /(?<![A-Za-z0-9_)\]])\.\s*init\s*\(/g, requiresMarker: true },
];

function formatViolation(violation: Violation): string {
  const rel = relative(ROOT, violation.path) || violation.path;
  return `${rel}:${violation.line}: ${violation.message}`;
}

function lineNumber(text: string, offset: number): number {
  let line = 1;
  for (let index = 0; index < offset; index += 1) {
    if (text.charCodeAt(index) === 10) line += 1;
  }
  return line;
}

function lineHasMarker(lines: string[], line: number): boolean {
  return line >= 1 && line <= lines.length && MARKER_RE.test(lines[line - 1] ?? "");
}

function findMatchingParen(text: string, openIndex: number): number | undefined {
  let depth = 0;
  let inString = false;
  let escaped = false;
  let inLineComment = false;
  let inBlockComment = false;
  for (let index = openIndex; index < text.length; index += 1) {
    const char = text[index];
    const next = text[index + 1] ?? "";
    if (inLineComment) {
      if (char === "\n") inLineComment = false;
      continue;
    }
    if (inBlockComment) {
      if (char === "*" && next === "/") {
        inBlockComment = false;
        index += 1;
      }
      continue;
    }
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (char === "\\") {
        escaped = true;
      } else if (char === '"') {
        inString = false;
      }
      continue;
    }
    if (char === "/" && next === "/") {
      inLineComment = true;
      index += 1;
      continue;
    }
    if (char === "/" && next === "*") {
      inBlockComment = true;
      index += 1;
      continue;
    }
    if (char === '"') {
      inString = true;
      continue;
    }
    if (char === "(") {
      depth += 1;
    } else if (char === ")") {
      depth -= 1;
      if (depth === 0) return index;
    }
  }
  return undefined;
}

function firstArgument(argumentText: string): string {
  const text = argumentText.trim();
  let depth = 0;
  let inString = false;
  let escaped = false;
  let inLineComment = false;
  let inBlockComment = false;
  for (let index = 0; index < text.length; index += 1) {
    const char = text[index];
    const next = text[index + 1] ?? "";
    if (inLineComment) {
      if (char === "\n") inLineComment = false;
      continue;
    }
    if (inBlockComment) {
      if (char === "*" && next === "/") {
        inBlockComment = false;
        index += 1;
      }
      continue;
    }
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (char === "\\") {
        escaped = true;
      } else if (char === '"') {
        inString = false;
      }
      continue;
    }
    if (char === "/" && next === "/") {
      inLineComment = true;
      index += 1;
      continue;
    }
    if (char === "/" && next === "*") {
      inBlockComment = true;
      index += 1;
      continue;
    }
    if (char === '"') {
      inString = true;
      continue;
    }
    if ("([{".includes(char)) {
      depth += 1;
    } else if (")]}".includes(char)) {
      depth -= 1;
    } else if (char === "," && depth === 0) {
      return text.slice(0, index).trim();
    }
  }
  return text;
}

function compact(expression: string): string {
  return expression.replace(/\s+/g, " ").trim();
}

function unlabeled(expression: string): string {
  const match = expression.match(/^[A-Za-z_][A-Za-z0-9_]*\s*:\s*([\s\S]*)$/);
  return match ? match[1].trim() : expression.trim();
}

function stringLiteralTokenEnd(expression: string): number | undefined {
  const value = unlabeled(expression);
  const prefix = value.match(/^(#*)"/);
  if (!prefix) return undefined;
  const hashes = prefix[1] ?? "";
  const closing = `"${hashes}`;
  let escaped = false;
  for (let index = hashes.length + 1; index < value.length; index += 1) {
    const char = value[index];
    if (hashes.length === 0 && escaped) {
      escaped = false;
      continue;
    }
    if (hashes.length === 0 && char === "\\") {
      escaped = true;
      continue;
    }
    if (char === '"' && value.slice(index, index + closing.length) === closing) {
      return index + closing.length;
    }
  }
  return undefined;
}

function isStringLiteral(expression: string): boolean {
  const value = unlabeled(expression);
  const end = stringLiteralTokenEnd(expression);
  return end !== undefined && value.slice(end).trim() === "";
}

function literalInterpolations(expression: string): string[] {
  const value = unlabeled(expression);
  const prefix = value.match(/^(#*)"/);
  if (!prefix) return [];
  const hashes = prefix[1] ?? "";
  const opening = `\\${hashes}(`;
  const interpolations: string[] = [];
  let escaped = false;
  for (let index = hashes.length + 1; index < value.length; index += 1) {
    const char = value[index];
    if (hashes.length === 0 && escaped) {
      escaped = false;
      continue;
    }
    if (hashes.length === 0 && char === "\\") {
      if (value.startsWith(opening, index)) {
        const openIndex = index + opening.length - 1;
        const closeIndex = findMatchingParen(value, openIndex);
        if (closeIndex !== undefined) {
          interpolations.push(value.slice(openIndex + 1, closeIndex));
          index = closeIndex;
        }
      } else {
        escaped = true;
      }
      continue;
    }
    if (hashes.length > 0 && value.startsWith(opening, index)) {
      const openIndex = index + opening.length - 1;
      const closeIndex = findMatchingParen(value, openIndex);
      if (closeIndex !== undefined) {
        interpolations.push(value.slice(openIndex + 1, closeIndex));
        index = closeIndex;
      }
    }
  }
  return interpolations;
}

function isPureInterpolationLiteral(expression: string): boolean {
  const value = unlabeled(expression);
  const prefix = value.match(/^(#*)"/);
  if (!prefix) return false;
  const end = stringLiteralTokenEnd(expression);
  if (end === undefined || value.slice(end).trim() !== "") return false;

  const hashes = prefix[1] ?? "";
  const contentStart = hashes.length + 1;
  const contentEnd = end - (`"${hashes}`).length;
  const opening = `\\${hashes}(`;
  let index = contentStart;
  let foundInterpolation = false;

  while (index < contentEnd) {
    if (!value.startsWith(opening, index)) return false;
    const openIndex = index + opening.length - 1;
    const closeIndex = findMatchingParen(value, openIndex);
    if (closeIndex === undefined || closeIndex >= contentEnd) return false;
    foundInterpolation = true;
    index = closeIndex + 1;
  }

  return foundInterpolation;
}

function hasHiddenContentInterpolation(expression: string): boolean {
  return literalInterpolations(expression).some((interpolation) => /(?:\.text\s*\(|\.(?:en|fr)\b|question|answer|title|name|prompt|body|note|altText|description)/i.test(interpolation));
}

function isTextVerbatimLiteral(expression: string): boolean {
  const value = expression.trim();
  if (/^verbatim\s*:/.test(value)) return isStringLiteral(value);
  const textMatch = value.match(/^Text\s*\(([^]*)\)$/);
  return textMatch ? isTextVerbatimLiteral(textMatch[1]) : false;
}

function isNonLiteralLocalizedStringKey(expression: string): boolean {
  const value = expression.trim();
  const match = value.match(/^LocalizedStringKey(?:\s*\.\s*init)?\s*\(([^]*)\)$/);
  return Boolean(match && !isStringLiteral(firstArgument(match[1])));
}

function shouldSkipButtonInitializer(expression: string): boolean {
  return /^(role|action|intent)\s*:/.test(expression.trim());
}

function scanFile(path: string): Violation[] {
  const text = readFileSync(path, "utf8");
  const lines = text.split(/\r?\n/);
  const violations: Violation[] = [];
  const invalidLocalizedStringKeyStarts = new Set<number>();

  for (const callPattern of callPatterns) {
    callPattern.pattern.lastIndex = 0;
    for (const match of text.matchAll(callPattern.pattern)) {
      const openIndex = text.indexOf("(", match.index ?? 0);
      const closeIndex = findMatchingParen(text, openIndex);
      if (closeIndex === undefined) continue;
      const startLine = lineNumber(text, match.index ?? 0);
      const argument = firstArgument(text.slice(openIndex + 1, closeIndex));

      if (callPattern.callee === "LocalizedStringKey") {
        if (!isStringLiteral(argument)) {
          invalidLocalizedStringKeyStarts.add(match.index ?? 0);
          violations.push({
            path,
            line: startLine,
            callee: callPattern.callee,
            expression: compact(argument),
            message: `LocalizedStringKey(${compact(argument)}) uses a non-literal key; pass a localized String/Text or keep a LocalizedStringResource`,
          });
        }
        continue;
      }

      if (callPattern.callee === "Button" && shouldSkipButtonInitializer(argument)) continue;
      const hasMarker = lineHasMarker(lines, startLine);
      if ((isStringLiteral(argument) || isTextVerbatimLiteral(argument)) && !isPureInterpolationLiteral(argument) && (!hasHiddenContentInterpolation(argument) || hasMarker)) continue;
      if (isNonLiteralLocalizedStringKey(argument)) continue;
      if (hasMarker) continue;

      violations.push({
        path,
        line: startLine,
        callee: callPattern.callee,
        expression: compact(argument),
        message: `${callPattern.callee}(${compact(argument)}) uses a non-literal text source; add // l10n: content(<lang>), // l10n: localized, or // l10n: verbatim`,
      });
    }
  }

  return violations;
}

function shouldSkipEntry(entry: string): boolean {
  if (basename(entry) === "CanadianHam.xcodeproj") return true;
  const rel = relative(ROOT, entry);
  if (!rel || rel.startsWith("..") || isAbsolute(rel)) return false;
  return rel.split(sep).some((part) => part.endsWith("Tests"));
}

function swiftFiles(roots: string[]): string[] {
  const files: string[] = [];
  const visit = (entry: string) => {
    if (shouldSkipEntry(entry)) return;
    const statEntries = readdirOrFile(entry);
    for (const child of statEntries) {
      if (child.kind === "file" && extname(child.path) === ".swift") {
        files.push(child.path);
      } else if (child.kind === "directory") {
        visit(child.path);
      }
    }
  };
  for (const root of roots) {
    const resolvedRoot = resolve(root);
    if (!existsSync(resolvedRoot)) {
      throw new Error(`Apple text-source root does not exist: ${relative(ROOT, resolvedRoot) || resolvedRoot}`);
    }
    visit(resolvedRoot);
  }
  return files.sort();
}

function readdirOrFile(path: string): { kind: "file" | "directory"; path: string }[] {
  try {
    const entries = readdirSync(path, { withFileTypes: true });
    return entries.map((entry) => ({ kind: entry.isDirectory() ? "directory" : "file", path: join(path, entry.name) }));
  } catch {
    return [{ kind: "file", path }];
  }
}

function runScan(roots: string[]): Violation[] {
  const files = swiftFiles(roots);
  if (files.length === 0) {
    throw new Error(`Apple text-source scan found 0 Swift files under: ${roots.map((root) => relative(ROOT, resolve(root)) || resolve(root)).join(", ")}`);
  }
  return files.flatMap(scanFile);
}

function expectRunScanError(roots: string[], expectedFragment: string): void {
  try {
    runScan(roots);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes(expectedFragment)) return;
    console.error(`Apple text-source gate self-test expected error containing "${expectedFragment}" but got "${message}".`);
    process.exit(1);
  }
  console.error(`Apple text-source gate self-test expected error containing "${expectedFragment}" but scan succeeded.`);
  process.exit(1);
}

function selfTest(): void {
  const actual = runScan([SELF_TEST_FIXTURE]).map(formatViolation).sort();
  const expectedFragments = [
    "InvalidTextFixture.swift:16: LocalizedStringKey(wrappedKey) uses a non-literal key",
    "InvalidTextFixture.swift:17: Text(makeTitle()) uses a non-literal text source",
    "InvalidTextFixture.swift:18: Text(model.title) uses a non-literal text source",
    "InvalidTextFixture.swift:21: Text(text) uses a non-literal text source",
    "InvalidTextFixture.swift:22: Text(\"\" + runtime) uses a non-literal text source",
    "InvalidTextFixture.swift:23: Text(\"x\".uppercased()) uses a non-literal text source",
    "InvalidTextFixture.swift:24: Text(verbatim: \"\" + runtime) uses a non-literal text source",
    "InvalidTextFixture.swift:25: Text(\"Question \\(model.title)\") uses a non-literal text source",
    "InvalidTextFixture.swift:26: Text(\"Answer \\(model.name)\") uses a non-literal text source",
    "InvalidTextFixture.swift:27: Text(\"\\(runtime)\") uses a non-literal text source",
    "InvalidTextFixture.swift:29: accessibilityLabel(\"\" + s) uses a non-literal text source",
    "InvalidTextFixture.swift:30: LocalizedStringKey(\"\" + runtime) uses a non-literal key",
    "InvalidTextFixture.swift:31: LocalizedStringKey(marked) uses a non-literal key",
    "InvalidTextFixture.swift:32: Text(runtime) uses a non-literal text source",
    "InvalidTextFixture.swift:33: Label(runtime) uses a non-literal text source",
    "InvalidTextFixture.swift:34: Button(runtime) uses a non-literal text source",
    "InvalidTextFixture.swift:35: .init(runtime) uses a non-literal text source",
  ];
  const missing = expectedFragments.filter((fragment) => !actual.some((line) => line.includes(fragment)));
  const forbiddenFragments = [
    "InvalidTextFixture.swift:28: Text(\"\\(marked)\") uses a non-literal text source",
    "SkippedTextFixture.swift",
  ];
  const forbidden = forbiddenFragments.filter((fragment) => actual.some((line) => line.includes(fragment)));
  if (actual.length !== expectedFragments.length || missing.length > 0 || forbidden.length > 0) {
    console.error("Apple text-source gate self-test failed.");
    console.error("Expected fragments:");
    for (const fragment of expectedFragments) console.error(`- ${fragment}`);
    if (forbidden.length > 0) {
      console.error("Forbidden fragments:");
      for (const fragment of forbidden) console.error(`- ${fragment}`);
    }
    console.error("Actual:");
    for (const line of actual) console.error(`- ${line}`);
    process.exit(1);
  }

  expectRunScanError([join(SELF_TEST_FIXTURE, "MissingRoot")], "does not exist");
  const emptyRoot = mkdtempSync(join(tmpdir(), "apple-text-sources-empty-"));
  try {
    expectRunScanError([emptyRoot], "found 0 Swift files");
  } finally {
    rmSync(emptyRoot, { recursive: true, force: true });
  }
}

const args = process.argv.slice(2);
if (args.includes("--self-test")) {
  selfTest();
  console.log("Apple text-source gate self-test passed.");
  process.exit(0);
}

const roots = args.length > 0 ? args : DEFAULT_SOURCE_ROOTS;
let violations: Violation[];
try {
  violations = runScan(roots);
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
if (violations.length > 0) {
  console.error("Unlocalized SwiftUI text sources:");
  for (const violation of violations) console.error(`- ${formatViolation(violation)}`);
  process.exit(1);
}
console.log("Apple SwiftUI text sources are localized or explicitly marked.");
