#!/usr/bin/env node
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, extname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_SOURCE_ROOTS = [
  join(ROOT, "apps/apple/CanadianHam"),
  join(ROOT, "apps/apple/Platforms"),
];
const SELF_TEST_FIXTURE = join(ROOT, "scripts/fixtures/apple-text-sources");

const MARKER_RE = /\/\/\s*l10n:\s*(?:content\([^)]+\)|localized\b|verbatim\b)/;
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

const callPatterns: CallPattern[] = [
  { callee: "LocalizedStringKey", pattern: /\bLocalizedStringKey\s*\(/g, requiresMarker: false },
  { callee: "Text", pattern: /\bText\s*\(/g, requiresMarker: true },
  { callee: "Label", pattern: /\bLabel\s*\(/g, requiresMarker: true },
  { callee: "Button", pattern: /\bButton\s*\(/g, requiresMarker: true },
  { callee: "navigationTitle", pattern: /\.navigationTitle\s*\(/g, requiresMarker: true },
  { callee: "accessibilityLabel", pattern: /\.accessibilityLabel\s*\(/g, requiresMarker: true },
  { callee: "accessibilityHint", pattern: /\.accessibilityHint\s*\(/g, requiresMarker: true },
  { callee: "accessibilityValue", pattern: /\.accessibilityValue\s*\(/g, requiresMarker: true },
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

function isStringLiteral(expression: string): boolean {
  return STRING_LITERAL_RE.test(unlabeled(expression));
}

function isTextVerbatimLiteral(expression: string): boolean {
  const value = expression.trim();
  if (/^verbatim\s*:\s*#*"/.test(value)) return true;
  const textMatch = value.match(/^Text\s*\(([^]*)\)$/);
  return textMatch ? /^verbatim\s*:\s*#*"/.test(textMatch[1].trim()) : false;
}

function isNonLiteralLocalizedStringKey(expression: string): boolean {
  const value = expression.trim();
  const match = value.match(/^LocalizedStringKey\s*\(([^]*)\)$/);
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
      if (isStringLiteral(argument) || isTextVerbatimLiteral(argument)) continue;
      if (isNonLiteralLocalizedStringKey(argument)) continue;
      if (lineHasMarker(lines, startLine)) continue;

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

function swiftFiles(roots: string[]): string[] {
  const files: string[] = [];
  const visit = (entry: string) => {
    const parts = entry.split(sep);
    if (parts.some((part) => part.endsWith("Tests") || part === "CanadianHam.xcodeproj")) return;
    const statEntries = existsSync(entry) ? readdirOrFile(entry) : [];
    for (const child of statEntries) {
      if (child.kind === "file" && extname(child.path) === ".swift") {
        files.push(child.path);
      } else if (child.kind === "directory") {
        visit(child.path);
      }
    }
  };
  for (const root of roots) visit(resolve(root));
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
  return swiftFiles(roots).flatMap(scanFile);
}

function selfTest(): void {
  const actual = runScan([SELF_TEST_FIXTURE]).map(formatViolation).sort();
  const expectedFragments = [
    "InvalidTextFixture.swift:13: LocalizedStringKey(wrappedKey) uses a non-literal key",
    "InvalidTextFixture.swift:14: Text(makeTitle()) uses a non-literal text source",
    "InvalidTextFixture.swift:15: Text(model.title) uses a non-literal text source",
    "InvalidTextFixture.swift:18: Text(text) uses a non-literal text source",
  ];
  const missing = expectedFragments.filter((fragment) => !actual.some((line) => line.includes(fragment)));
  if (actual.length !== expectedFragments.length || missing.length > 0) {
    console.error("Apple text-source gate self-test failed.");
    console.error("Expected fragments:");
    for (const fragment of expectedFragments) console.error(`- ${fragment}`);
    console.error("Actual:");
    for (const line of actual) console.error(`- ${line}`);
    process.exit(1);
  }
}

const args = process.argv.slice(2);
if (args.includes("--self-test")) {
  selfTest();
  console.log("Apple text-source gate self-test passed.");
  process.exit(0);
}

const roots = args.length > 0 ? args : DEFAULT_SOURCE_ROOTS;
const violations = runScan(roots);
if (violations.length > 0) {
  console.error("Unlocalized SwiftUI text sources:");
  for (const violation of violations) console.error(`- ${formatViolation(violation)}`);
  process.exit(1);
}
console.log("Apple SwiftUI text sources are localized or explicitly marked.");
