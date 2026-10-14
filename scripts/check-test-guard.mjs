#!/usr/bin/env node
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import process from "node:process";

const APPLE_PREFIX = "apps/apple/";
const CHECKER_PATH = "scripts/check-test-guard.mjs";
const WORKFLOW_PATH = ".github/workflows/test-guard.yml";
const PROTECTED_GUARD_FILES = [CHECKER_PATH, WORKFLOW_PATH];
const APPROVAL_MARKER_LINE = /^Test-guard-approved:[ \t]*(?:task-\d+|owner decision \d{4}-\d{2}-\d{2})[ \t]*$/u;

const EXCEPTION_HELPERS = [
  "auditIgnoringOccludedLessonTextContrast",
  "isApprovedMediumDetentToolScrollTextClip",
];

const KNOWN_AUDIT_WRAPPERS = [
  "performAudit",
  "performCourseAudit",
];

const SHARED_HELPERS = [
  ...EXCEPTION_HELPERS,
  "scrollUntilHittable",
  "preciseScroll",
  "positionElementInMiddleVisibleBand",
  "settleScrollableContentBelowNavigationBar",
  "elementsNearestProtectedBar",
  "assertFullyVisibleBelowNavigationBar",
  "lessonAuditGeometryBelowOpaqueNavigationBar",
  "navigationBarElementFrames",
  "protectedNavigationFrame",
  "element",
  "frame",
];

const RULES = {
  auditRange: "performAccessibilityAudit enclosing function, closure or named handler changes are guarded",
  sharedHelper: "shared UI-test/audit helper changes are guarded",
  auditWrapperCall: "audit wrapper or approved-exception helper call-site changes are guarded",
  accessibilityHidden: "added .accessibilityHidden(true) is guarded",
  accessibilityIgnoreChildren: "added .accessibilityElement(children: .ignore) or .accessibilityElement() is guarded",
  xctSkip: "added XCTSkip/XCTSkipIf/XCTSkipUnless is guarded",
  minimumScaleFactor: "added .minimumScaleFactor( in app views is guarded",
  deletedTestMethod: "deleted or disabled Swift func test... method is guarded",
  guardSelfProtection: "changes to the test guard checker or workflow require approval",
};

function parseArgs(argv) {
  const args = {
    selfTest: false,
    base: process.env.TEST_GUARD_BASE_SHA ?? process.env.BASE_SHA ?? "main",
    head: process.env.TEST_GUARD_HEAD_SHA ?? process.env.HEAD_SHA ?? "HEAD",
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--self-test") {
      args.selfTest = true;
    } else if (arg === "--base") {
      args.base = requireValue(argv, index, arg);
      index += 1;
    } else if (arg === "--head") {
      args.head = requireValue(argv, index, arg);
      index += 1;
    } else if (arg === "--help" || arg === "-h") {
      args.help = true;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return args;
}

function requireValue(argv, index, arg) {
  const value = argv[index + 1];
  if (value === undefined || value.startsWith("--")) {
    throw new Error(`${arg} requires a value.`);
  }
  return value;
}

function usage() {
  return `Usage: node scripts/check-test-guard.mjs [--base <ref>] [--head <ref>] [--self-test]

Checks guarded Apple test/view changes in the git diff base...head.
Environment:
  TEST_GUARD_BASE_SHA / BASE_SHA  Base ref (default: main)
  TEST_GUARD_HEAD_SHA / HEAD_SHA  Head ref (default: HEAD)
  TEST_GUARD_PR_BODY              Pull request body; a line exactly matching
                                  Test-guard-approved: task-123
                                  or Test-guard-approved: owner decision YYYY-MM-DD
                                  approves findings. Fenced blocks and HTML
                                  comments are ignored.`;
}

function hasApprovalMarker(body) {
  let inFence = false;
  let inHtmlComment = false;

  for (const line of String(body ?? "").split(/\r?\n/u)) {
    if (inHtmlComment) {
      if (line.includes("-->")) {
        inHtmlComment = false;
      }
      continue;
    }

    const trimmed = line.trimStart();
    if (/^(?:```|~~~)/u.test(trimmed)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) {
      continue;
    }

    const commentStart = line.indexOf("<!--");
    if (commentStart !== -1) {
      if (APPROVAL_MARKER_LINE.test(line.slice(0, commentStart))) {
        return true;
      }
      if (!line.slice(commentStart + 4).includes("-->")) {
        inHtmlComment = true;
      }
      continue;
    }

    if (APPROVAL_MARKER_LINE.test(line)) {
      return true;
    }
  }

  return false;
}

function runGit(args, options = {}) {
  const result = spawnSync("git", ["-c", "core.quotePath=false", ...args], {
    cwd: options.cwd ?? process.cwd(),
    encoding: "utf8",
    maxBuffer: 20 * 1024 * 1024,
  });
  if (result.status !== 0) {
    throw new Error(`git ${args.join(" ")} failed:\n${result.stderr}${result.stdout}`);
  }
  return result.stdout;
}

function gitMergeBase(base, head, repoRoot = process.cwd()) {
  return runGit(["merge-base", base, head], { cwd: repoRoot }).trim();
}

function gitDiff(mergeBase, head, repoRoot = process.cwd()) {
  return runGit([
    "diff",
    "--no-ext-diff",
    "-w",
    "-M",
    "--unified=3",
    `${mergeBase}...${head}`,
    "--",
    APPLE_PREFIX,
  ], { cwd: repoRoot });
}

function gitChangedProtectedFiles(mergeBase, head, repoRoot = process.cwd()) {
  const output = runGit(["diff", "--name-only", `${mergeBase}...${head}`, "--", ...PROTECTED_GUARD_FILES], { cwd: repoRoot });
  return output.split(/\r?\n/u).filter((line) => line.length > 0);
}

function gitFileAt(ref, filePath, repoRoot = process.cwd()) {
  const result = spawnSync("git", ["-c", "core.quotePath=false", "show", `${ref}:${filePath}`], {
    cwd: repoRoot,
    encoding: "utf8",
    maxBuffer: 20 * 1024 * 1024,
  });
  if (result.status === 0) {
    return result.stdout;
  }

  const output = `${result.stderr}${result.stdout}`;
  if (/fatal: path ['"].*['"] exists on disk, but not in /u.test(output)
      || /fatal: Path ['"].*['"] does not exist in /u.test(output)
      || /exists on disk, but not in /u.test(output)
      || /does not exist in /u.test(output)) {
    return "";
  }

  throw new Error(`git show ${ref}:${filePath} failed:\n${output}`);
}

function parseUnifiedDiff(diff) {
  const files = [];
  let current = null;
  let oldLine = 0;
  let newLine = 0;
  let inHunk = false;
  let seenHunk = false;

  for (const rawLine of diff.split("\n")) {
    if (rawLine.startsWith("diff --git ")) {
      current = { oldPath: null, newPath: null, changes: [] };
      files.push(current);
      inHunk = false;
      seenHunk = false;
      continue;
    }

    if (current === null) {
      continue;
    }

    if (!seenHunk && rawLine.startsWith("--- ")) {
      current.oldPath = parseDiffPath(rawLine.slice(4));
      continue;
    }
    if (!seenHunk && rawLine.startsWith("+++ ")) {
      current.newPath = parseDiffPath(rawLine.slice(4));
      continue;
    }

    const hunk = rawLine.match(/^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@/u);
    if (hunk !== null) {
      oldLine = Number(hunk[1]);
      newLine = Number(hunk[2]);
      inHunk = true;
      seenHunk = true;
      continue;
    }

    if (!inHunk || rawLine.length === 0) {
      continue;
    }

    const marker = rawLine[0];
    const text = rawLine.slice(1);
    if (marker === "+") {
      current.changes.push({ kind: "addition", line: newLine, text });
      newLine += 1;
    } else if (marker === "-") {
      current.changes.push({ kind: "deletion", line: oldLine, text });
      oldLine += 1;
    } else if (marker === " ") {
      oldLine += 1;
      newLine += 1;
    } else if (marker === "\\") {
      // "No newline at end of file" marker.
    }
  }

  return files
    .map((file) => ({ ...file, path: file.newPath ?? file.oldPath }))
    .filter((file) => file.path !== null && file.path.startsWith(APPLE_PREFIX));
}

function parseDiffPath(rawPath) {
  const pathPart = rawPath.trimEnd().split("\t")[0];
  if (pathPart === "/dev/null") {
    return null;
  }
  return decodeGitPath(pathPart).replace(/^[ab]\//u, "");
}

function decodeGitPath(rawPath) {
  if (!rawPath.startsWith('"')) {
    return rawPath;
  }

  const bytes = [];
  let text = "";
  const flushBytes = () => {
    if (bytes.length > 0) {
      text += Buffer.from(bytes).toString("utf8");
      bytes.length = 0;
    }
  };

  for (let index = 1; index < rawPath.length; index += 1) {
    const character = rawPath[index];
    if (character === '"') {
      flushBytes();
      return text;
    }
    if (character !== "\\") {
      flushBytes();
      text += character;
      continue;
    }

    const next = rawPath[index + 1];
    if (next === undefined) {
      flushBytes();
      text += "\\";
      continue;
    }
    if (/[0-7]/u.test(next)) {
      const octal = rawPath.slice(index + 1).match(/^[0-7]{1,3}/u)?.[0] ?? next;
      bytes.push(Number.parseInt(octal, 8));
      index += octal.length;
      continue;
    }

    flushBytes();
    if (next === "n") text += "\n";
    else if (next === "t") text += "\t";
    else if (next === "r") text += "\r";
    else if (next === "b") text += "\b";
    else if (next === "f") text += "\f";
    else text += next;
    index += 1;
  }

  flushBytes();
  return text;
}

function splitLines(content) {
  if (content.length === 0) {
    return [];
  }
  return content.replace(/\n$/u, "").split("\n");
}

function stripSwiftComments(content) {
  const lines = splitLines(content);
  const strippedLines = [];
  let blockDepth = 0;
  let inString = false;
  let inTripleString = false;

  for (const line of lines) {
    let output = "";
    for (let index = 0; index < line.length; index += 1) {
      const current = line[index];
      const next = line[index + 1];
      const next2 = line[index + 2];

      if (blockDepth > 0) {
        if (current === "/" && next === "*") {
          blockDepth += 1;
          output += "  ";
          index += 1;
        } else if (current === "*" && next === "/") {
          blockDepth -= 1;
          output += "  ";
          index += 1;
        } else {
          output += " ";
        }
        continue;
      }

      if (inTripleString) {
        output += current;
        if (current === '"' && next === '"' && next2 === '"') {
          output += next + next2;
          index += 2;
          inTripleString = false;
        }
        continue;
      }

      if (inString) {
        output += current;
        if (current === "\\") {
          if (next !== undefined) {
            output += next;
            index += 1;
          }
        } else if (current === '"') {
          inString = false;
        }
        continue;
      }

      if (current === "/" && next === "/") {
        output += " ".repeat(line.length - index);
        break;
      }
      if (current === "/" && next === "*") {
        blockDepth += 1;
        output += "  ";
        index += 1;
        continue;
      }
      if (current === '"' && next === '"' && next2 === '"') {
        inTripleString = true;
        output += current + next + next2;
        index += 2;
        continue;
      }
      if (current === '"') {
        inString = true;
        output += current;
        continue;
      }

      output += current;
    }
    strippedLines.push(output);
  }

  return strippedLines;
}

function removeInactiveFalseBlocks(lines) {
  const effective = [];
  let disabledDepth = 0;

  for (const line of lines) {
    const trimmed = line.trim();
    if (disabledDepth > 0) {
      if (/^#if\b/u.test(trimmed)) {
        disabledDepth += 1;
      } else if (/^#endif\b/u.test(trimmed)) {
        disabledDepth -= 1;
      }
      effective.push("");
      continue;
    }

    if (/^#if\s+(?:false|0)\b/u.test(trimmed)) {
      disabledDepth = 1;
      effective.push("");
      continue;
    }

    effective.push(line);
  }

  return effective;
}

function normalizedText(lines) {
  return lines.join("\n").replace(/\s+/gu, " ").trim();
}

function lineStartsFromLines(lines) {
  const starts = [];
  let offset = 0;
  for (const line of lines) {
    starts.push(offset);
    offset += line.length + 1;
  }
  return starts;
}

function offsetToLine(starts, offset) {
  let low = 0;
  let high = starts.length - 1;
  while (low <= high) {
    const mid = Math.floor((low + high) / 2);
    if (starts[mid] <= offset) {
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }
  return Math.max(1, high + 1);
}

function allFunctionRanges(strippedLines) {
  const ranges = [];
  const text = strippedLines.join("\n");
  const starts = lineStartsFromLines(strippedLines);
  const pattern = /\bfunc\s+([A-Za-z_][A-Za-z0-9_]*)\b/gu;
  let match;
  while ((match = pattern.exec(text)) !== null) {
    const name = match[1];
    const openBrace = text.indexOf("{", pattern.lastIndex);
    if (openBrace === -1) {
      continue;
    }
    const closeBrace = findMatchingDelimiter(text, openBrace, "{", "}");
    const start = offsetToLine(starts, match.index);
    const end = offsetToLine(starts, closeBrace === -1 ? openBrace : closeBrace);
    ranges.push({ name, start, end });
  }
  return ranges;
}

function findMatchingDelimiter(content, openIndex, openChar, closeChar) {
  let depth = 0;
  let inString = false;
  let inTripleString = false;

  for (let index = openIndex; index < content.length; index += 1) {
    const current = content[index];
    const next = content[index + 1];
    const next2 = content[index + 2];

    if (inTripleString) {
      if (current === '"' && next === '"' && next2 === '"') {
        inTripleString = false;
        index += 2;
      }
      continue;
    }
    if (inString) {
      if (current === "\\") {
        index += 1;
      } else if (current === '"') {
        inString = false;
      }
      continue;
    }
    if (current === '"' && next === '"' && next2 === '"') {
      inTripleString = true;
      index += 2;
      continue;
    }
    if (current === '"') {
      inString = true;
      continue;
    }

    if (current === openChar) {
      depth += 1;
    } else if (current === closeChar) {
      depth -= 1;
      if (depth === 0) {
        return index;
      }
    }
  }

  return -1;
}

function auditClosureRanges(strippedLines) {
  const ranges = [];
  const text = strippedLines.join("\n");
  const starts = lineStartsFromLines(strippedLines);
  let searchIndex = 0;
  let occurrence = 0;

  while (searchIndex < text.length) {
    const tokenIndex = text.indexOf("performAccessibilityAudit", searchIndex);
    if (tokenIndex === -1) {
      break;
    }
    searchIndex = tokenIndex + "performAccessibilityAudit".length;
    const afterToken = nextNonWhitespace(text, searchIndex);
    if (afterToken === -1) {
      continue;
    }

    let braceIndex = -1;
    if (text[afterToken] === "{") {
      braceIndex = afterToken;
    } else if (text[afterToken] === "(") {
      const closeParen = findMatchingDelimiter(text, afterToken, "(", ")");
      if (closeParen !== -1) {
        const inlineBrace = findFirstCharacter(text, "{", afterToken + 1, closeParen);
        const afterParen = nextNonWhitespace(text, closeParen + 1);
        if (inlineBrace !== -1) {
          braceIndex = inlineBrace;
        } else if (afterParen !== -1 && text[afterParen] === "{") {
          braceIndex = afterParen;
        }
      }
    }

    if (braceIndex === -1) {
      continue;
    }

    const closeBrace = findMatchingDelimiter(text, braceIndex, "{", "}");
    occurrence += 1;
    ranges.push({
      key: `audit-closure:${occurrence}`,
      start: offsetToLine(starts, tokenIndex),
      end: offsetToLine(starts, closeBrace === -1 ? braceIndex : closeBrace),
      rule: RULES.auditRange,
    });
  }

  return ranges;
}

function nextNonWhitespace(content, index) {
  for (let cursor = index; cursor < content.length; cursor += 1) {
    if (!/\s/u.test(content[cursor])) {
      return cursor;
    }
  }
  return -1;
}

function findFirstCharacter(content, target, start, end) {
  let inString = false;
  for (let index = start; index < end; index += 1) {
    const current = content[index];
    if (inString) {
      if (current === "\\") index += 1;
      else if (current === '"') inString = false;
      continue;
    }
    if (current === '"') {
      inString = true;
      continue;
    }
    if (current === target) {
      return index;
    }
  }
  return -1;
}

function auditNamedHandlers(strippedLines) {
  const handlers = new Set();
  const text = strippedLines.join("\n");
  let searchIndex = 0;

  while (searchIndex < text.length) {
    const tokenIndex = text.indexOf("performAccessibilityAudit", searchIndex);
    if (tokenIndex === -1) {
      break;
    }
    searchIndex = tokenIndex + "performAccessibilityAudit".length;
    const afterToken = nextNonWhitespace(text, searchIndex);
    if (afterToken === -1 || text[afterToken] !== "(") {
      continue;
    }
    const closeParen = findMatchingDelimiter(text, afterToken, "(", ")");
    if (closeParen === -1) {
      continue;
    }

    for (const argument of topLevelArguments(text.slice(afterToken + 1, closeParen))) {
      const withoutLabel = argument.replace(/^\s*[A-Za-z_][A-Za-z0-9_]*\s*:\s*/u, "").trim();
      const match = withoutLabel.match(/^([A-Za-z_][A-Za-z0-9_]*)$/u);
      if (match !== null && !["true", "false", "nil"].includes(match[1])) {
        handlers.add(match[1]);
      }
    }
  }

  return [...handlers];
}

function topLevelArguments(argumentText) {
  const args = [];
  let start = 0;
  let parenDepth = 0;
  let bracketDepth = 0;
  let braceDepth = 0;
  let inString = false;

  for (let index = 0; index < argumentText.length; index += 1) {
    const current = argumentText[index];
    if (inString) {
      if (current === "\\") index += 1;
      else if (current === '"') inString = false;
      continue;
    }
    if (current === '"') {
      inString = true;
      continue;
    }
    if (current === "(") parenDepth += 1;
    else if (current === ")") parenDepth -= 1;
    else if (current === "[") bracketDepth += 1;
    else if (current === "]") bracketDepth -= 1;
    else if (current === "{") braceDepth += 1;
    else if (current === "}") braceDepth -= 1;
    else if (current === "," && parenDepth === 0 && bracketDepth === 0 && braceDepth === 0) {
      args.push(argumentText.slice(start, index));
      start = index + 1;
    }
  }

  const last = argumentText.slice(start);
  if (last.trim().length > 0) {
    args.push(last);
  }
  return args;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/gu, "\\$&");
}

function linesForRange(lines, range) {
  return lines.slice(range.start - 1, range.end);
}

function functionRangesByNames(strippedLines, names, rule, prefix) {
  const nameSet = new Set(names);
  const seen = new Map();
  const entries = [];
  for (const range of allFunctionRanges(strippedLines)) {
    if (!nameSet.has(range.name)) {
      continue;
    }
    const occurrence = (seen.get(range.name) ?? 0) + 1;
    seen.set(range.name, occurrence);
    entries.push({
      key: `${prefix}:${range.name}:${occurrence}`,
      name: range.name,
      start: range.start,
      end: range.end,
      rule,
    });
  }
  return entries;
}

function functionNamesContainingAudit(strippedLines) {
  return allFunctionRanges(strippedLines)
    .filter((range) => normalizedText(linesForRange(strippedLines, range)).includes("performAccessibilityAudit"))
    .map((range) => range.name);
}

function guardedRangeEntries(strippedLines, counterpartLines = [], filePath = "") {
  const handlerNames = [...new Set([...auditNamedHandlers(strippedLines), ...auditNamedHandlers(counterpartLines)])];
  const auditFunctionNames = isUITestPath(filePath)
    ? [...new Set([...functionNamesContainingAudit(strippedLines), ...functionNamesContainingAudit(counterpartLines)])]
    : [];
  const entries = [
    ...functionRangesByNames(strippedLines, SHARED_HELPERS, RULES.sharedHelper, "shared"),
    ...functionRangesByNames(strippedLines, handlerNames, RULES.auditRange, "handler"),
    ...functionRangesByNames(strippedLines, auditFunctionNames, RULES.auditRange, "audit-function"),
    ...auditClosureRanges(strippedLines),
  ];

  const seen = new Set();
  return entries.filter((entry) => {
    const dedupeKey = `${entry.key}:${entry.start}:${entry.end}:${entry.rule}`;
    if (seen.has(dedupeKey)) {
      return false;
    }
    seen.add(dedupeKey);
    return true;
  }).map((entry) => ({
    ...entry,
    normalized: normalizedText(linesForRange(strippedLines, entry)),
  }));
}

function isUITestPath(filePath) {
  return /UITests\//u.test(filePath);
}

function isAppViewPath(filePath) {
  return filePath.endsWith(".swift")
    && (filePath.startsWith("apps/apple/CanadianHam/") || filePath.startsWith("apps/apple/Platforms/"))
    && !filePath.split("/").some((segment) => /Tests?$/u.test(segment) || /UITests?$/u.test(segment));
}

function checkDiff(diff, getOldContent, getNewContent, protectedFiles = []) {
  const findings = [];
  const seen = new Set();

  for (const protectedFile of protectedFiles) {
    addFinding(findings, seen, protectedFile, 1, RULES.guardSelfProtection);
  }

  const appleFiles = parseUnifiedDiff(diff)
    .map((file) => {
      const oldPath = file.oldPath ?? file.path;
      const newPath = file.newPath ?? file.path;
      const reportPath = newPath ?? oldPath;
      if (reportPath === null || !reportPath.endsWith(".swift")) {
        return null;
      }
      const oldContent = oldPath === null ? "" : getOldContent(oldPath);
      const newContent = newPath === null ? "" : getNewContent(newPath);
      const oldStripped = stripSwiftComments(oldContent);
      const newStripped = stripSwiftComments(newContent);
      return {
        oldPath,
        newPath,
        reportPath,
        oldStripped,
        newStripped,
        oldEffective: removeInactiveFalseBlocks(oldStripped),
        newEffective: removeInactiveFalseBlocks(newStripped),
      };
    })
    .filter((file) => file !== null);

  const globalAuditWrappers = [...new Set([
    ...KNOWN_AUDIT_WRAPPERS,
    ...appleFiles.flatMap((file) => functionNamesContainingAudit(file.oldStripped)),
    ...appleFiles.flatMap((file) => functionNamesContainingAudit(file.newStripped)),
  ])];

  for (const file of appleFiles) {
    compareGuardedRanges(findings, seen, file.reportPath, file.oldStripped, file.newStripped);
    compareLinePatternCounts(findings, seen, file.reportPath, file.oldEffective, file.newEffective);
    compareDeletedTestNames(findings, seen, file.reportPath, file.oldEffective, file.newEffective);
    compareAuditWrapperCalls(findings, seen, file.reportPath, file.oldEffective, file.newEffective, globalAuditWrappers);
  }

  return findings.sort((a, b) => a.filePath.localeCompare(b.filePath) || a.line - b.line || a.rule.localeCompare(b.rule));
}

function compareGuardedRanges(findings, seen, filePath, oldStripped, newStripped) {
  const oldEntries = guardedRangeEntries(oldStripped, newStripped, filePath);
  const newEntries = guardedRangeEntries(newStripped, oldStripped, filePath);
  const oldByKey = new Map(oldEntries.map((entry) => [entry.key, entry]));
  const newByKey = new Map(newEntries.map((entry) => [entry.key, entry]));
  const keys = [...new Set([...oldEntries.map((entry) => entry.key), ...newEntries.map((entry) => entry.key)])];

  for (const key of keys) {
    const oldEntry = oldByKey.get(key);
    const newEntry = newByKey.get(key);
    if ((oldEntry?.normalized ?? "") !== (newEntry?.normalized ?? "")) {
      const findingEntry = newEntry ?? oldEntry;
      addFinding(findings, seen, filePath, findingEntry?.start ?? 1, findingEntry?.rule ?? RULES.auditRange);
    }
  }
}

function compareLinePatternCounts(findings, seen, filePath, oldEffective, newEffective) {
  const rules = [
    {
      rule: RULES.accessibilityHidden,
      pattern: /\.accessibilityHidden\s*\(\s*true\s*\)/gu,
      applies: () => true,
    },
    {
      rule: RULES.accessibilityIgnoreChildren,
      pattern: /\.accessibilityElement\s*\(\s*(?:children\s*:\s*\.ignore\s*)?\)/gu,
      applies: () => true,
    },
    {
      rule: RULES.xctSkip,
      pattern: /\b(?:throw\s+)?XCTSkip(?:If|Unless)?\s*\(/gu,
      applies: () => true,
    },
    {
      rule: RULES.minimumScaleFactor,
      pattern: /\.minimumScaleFactor\s*\(/gu,
      applies: () => isAppViewPath(filePath),
    },
  ];

  const oldText = oldEffective.join("\n");
  const newText = newEffective.join("\n");
  for (const { rule, pattern, applies } of rules) {
    if (!applies()) {
      continue;
    }
    const oldCount = countMatches(oldText, pattern);
    const newCount = countMatches(newText, pattern);
    if (newCount > oldCount) {
      addFinding(findings, seen, filePath, firstLineMatching(newEffective, pattern), rule);
    }
  }
}

function countMatches(text, pattern) {
  pattern.lastIndex = 0;
  return [...text.matchAll(pattern)].length;
}

function firstLineMatching(lines, pattern) {
  for (let index = 0; index < lines.length; index += 1) {
    pattern.lastIndex = 0;
    if (pattern.test(lines[index])) {
      return index + 1;
    }
  }
  return 1;
}

function compareDeletedTestNames(findings, seen, filePath, oldEffective, newEffective) {
  const oldNames = collectTestNames(oldEffective);
  const newNames = collectTestNames(newEffective);
  const newNameSet = new Set(newNames.map((entry) => entry.name));
  for (const oldName of oldNames) {
    if (!newNameSet.has(oldName.name)) {
      addFinding(findings, seen, filePath, oldName.line, RULES.deletedTestMethod);
    }
  }
}

function collectTestNames(lines) {
  const names = [];
  for (let index = 0; index < lines.length; index += 1) {
    const match = lines[index].match(/\bfunc\s+(test[A-Za-z0-9_]*)\s*\(/u);
    if (match !== null) {
      names.push({ name: match[1], line: index + 1 });
    }
  }
  return names;
}

function compareAuditWrapperCalls(findings, seen, filePath, oldEffective, newEffective, auditWrapperNames) {
  const wrapperNames = [...new Set([...EXCEPTION_HELPERS, ...auditWrapperNames])];

  for (const name of wrapperNames) {
    const oldCalls = collectCallLines(oldEffective, name);
    const newCalls = collectCallLines(newEffective, name);
    const shouldFlagIncrease = EXCEPTION_HELPERS.includes(name);
    if (oldCalls.length > newCalls.length) {
      addFinding(findings, seen, filePath, oldCalls[0] ?? 1, RULES.auditWrapperCall);
    } else if (shouldFlagIncrease && newCalls.length > oldCalls.length) {
      addFinding(findings, seen, filePath, newCalls[0] ?? 1, RULES.auditWrapperCall);
    }
  }
}

function collectCallLines(lines, name) {
  const callPattern = new RegExp(`\\b${escapeRegExp(name)}\\s*\\(`, "u");
  const declarationPattern = new RegExp(`\\bfunc\\s+${escapeRegExp(name)}\\b`, "u");
  const calls = [];
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    if (declarationPattern.test(line)) {
      continue;
    }
    if (callPattern.test(line)) {
      calls.push(index + 1);
    }
  }
  return calls;
}

function addFinding(findings, seen, filePath, line, rule) {
  const key = `${filePath}:${line}:${rule}`;
  if (seen.has(key)) {
    return;
  }
  seen.add(key);
  findings.push({ filePath, line, rule });
}

function formatFinding(finding) {
  return `${finding.filePath}:${finding.line}: ${finding.rule}`;
}

function formatGithubWarning(finding) {
  return `::warning file=${escapeGithubCommandProperty(finding.filePath)},line=${finding.line}::${escapeGithubCommandMessage(finding.rule)}`;
}

function escapeGithubCommandProperty(value) {
  return escapeGithubCommandMessage(value).replace(/,/gu, "%2C").replace(/:/gu, "%3A");
}

function escapeGithubCommandMessage(value) {
  return String(value).replace(/%/gu, "%25").replace(/\r/gu, "%0D").replace(/\n/gu, "%0A");
}

function evaluateFindings(findings, prBody) {
  const approved = hasApprovalMarker(prBody);
  return {
    approved,
    findings,
    exitCode: findings.length > 0 && !approved ? 1 : 0,
  };
}

function collectFindingsForRefs({ base, head, repoRoot = process.cwd() }) {
  const mergeBase = gitMergeBase(base, head, repoRoot);
  const diff = gitDiff(mergeBase, head, repoRoot);
  const protectedFiles = gitChangedProtectedFiles(mergeBase, head, repoRoot);
  const findings = checkDiff(
    diff,
    (filePath) => gitFileAt(mergeBase, filePath, repoRoot),
    (filePath) => gitFileAt(head, filePath, repoRoot),
    protectedFiles,
  );
  return { mergeBase, findings };
}

function runGuard({ base, head, prBody, repoRoot = process.cwd() }) {
  const { mergeBase, findings } = collectFindingsForRefs({ base, head, repoRoot });
  const result = evaluateFindings(findings, prBody);

  if (findings.length > 0 && result.approved) {
    console.warn("Test guard findings approved by PR body marker:");
    for (const finding of findings) {
      console.warn(formatGithubWarning(finding));
      console.warn(`- ${formatFinding(finding)}`);
    }
    return 0;
  }

  if (findings.length > 0) {
    console.error("Test guard failed: guarded changes require a PR body line 'Test-guard-approved: task-123' or 'Test-guard-approved: owner decision YYYY-MM-DD'.");
    for (const finding of findings) {
      console.error(`- ${formatFinding(finding)}`);
    }
    return 1;
  }

  if (result.approved) {
    console.log(`Test guard passed: approval marker present but no guarded changes found in ${mergeBase}...${head}.`);
  } else {
    console.log(`Test guard passed: no guarded changes found in ${mergeBase}...${head}.`);
  }
  return 0;
}

function diffFixture(oldContent, newContent, filePath = "apps/apple/CanadianHamUITests/GuardFixture.swift") {
  const oldLines = splitLines(oldContent);
  const newLines = splitLines(newContent);
  const changes = [];
  const max = Math.max(oldLines.length, newLines.length);
  for (let index = 0; index < max; index += 1) {
    if (oldLines[index] === newLines[index]) {
      changes.push(` ${oldLines[index] ?? ""}`);
    } else {
      if (oldLines[index] !== undefined) {
        changes.push(`-${oldLines[index]}`);
      }
      if (newLines[index] !== undefined) {
        changes.push(`+${newLines[index]}`);
      }
    }
  }
  return `diff --git a/${filePath} b/${filePath}\n--- a/${filePath}\n+++ b/${filePath}\n@@ -1,${oldLines.length} +1,${newLines.length} @@\n${changes.join("\n")}\n`;
}

function assertFinds(name, oldContent, newContent, expectedRule, filePath) {
  const diff = diffFixture(oldContent, newContent, filePath);
  assertFindsInDiff(name, diff, oldContent, newContent, expectedRule);
}

function assertFindsInDiff(name, diff, oldContent, newContent, expectedRule) {
  const findings = checkDiff(diff, () => oldContent, () => newContent);
  if (!findings.some((finding) => finding.rule === expectedRule)) {
    throw new Error(`${name} missed ${expectedRule}; findings: ${findings.map(formatFinding).join("; ")}`);
  }
}

function assertClean(name, oldContent, newContent, filePath) {
  const diff = diffFixture(oldContent, newContent, filePath);
  const findings = checkDiff(diff, () => oldContent, () => newContent);
  assert.deepEqual(findings, [], `${name} expected no findings; got ${findings.map(formatFinding).join("; ")}`);
}

function runSelfTest() {
  const testPath = "apps/apple/CanadianHamUITests/GuardFixture.swift";
  const appViewPath = "apps/apple/CanadianHam/GuardView.swift";

  assert.equal(decodeGitPath('"apps/apple/CanadianHamUITests/Gr\\303\\251goire.swift"'), "apps/apple/CanadianHamUITests/Grégoire.swift");

  assertClean(
    "unrelated test assertion passes when no audit wrapper is involved",
    "func testUnrelated() throws {\n    XCTAssertTrue(true)\n}",
    "func testUnrelated() throws {\n    XCTAssertFalse(false)\n}",
    testPath,
  );
  assertFinds(
    "audit trailing closure fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit()\n}",
    "func testAudit() throws {\n    try app.performAccessibilityAudit { issue in\n        return false\n    }\n}",
    RULES.auditRange,
    testPath,
  );
  assertFinds(
    "plain audit deletion fails through enclosing function compare",
    "func performAudit(on app: XCUIApplication) throws {\n    try app.performAccessibilityAudit()\n}",
    "func performAudit(on app: XCUIApplication) throws {\n    XCTAssertTrue(true)\n}",
    RULES.auditRange,
    testPath,
  );
  assertFinds(
    "audit type narrowing fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit()\n}",
    "func testAudit() throws {\n    try app.performAccessibilityAudit(for: .dynamicType)\n}",
    RULES.auditRange,
    testPath,
  );
  assertFinds(
    "audit named handler fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit()\n}",
    "func testAudit() throws {\n    try app.performAccessibilityAudit(myFilter)\n}\nfunc myFilter(_ issue: XCTAccessibilityAuditIssue) -> Bool { true }\n",
    RULES.auditRange,
    testPath,
  );
  assertFinds(
    "existing named handler body edit fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit(myFilter)\n}\nfunc myFilter(_ issue: XCTAccessibilityAuditIssue) -> Bool {\n    return true\n}",
    "func testAudit() throws {\n    try app.performAccessibilityAudit(myFilter)\n}\nfunc myFilter(_ issue: XCTAccessibilityAuditIssue) -> Bool {\n    return false\n}",
    RULES.auditRange,
    testPath,
  );
  assertFinds(
    "exception helper call addition fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit()\n}",
    "func testAudit() throws {\n    try auditIgnoringOccludedLessonTextContrast(app: app)\n}",
    RULES.auditWrapperCall,
    testPath,
  );
  assertFinds(
    "early return in performAudit wrapper fails",
    "func performAudit(on app: XCUIApplication, context: String) throws {\n    try app.performAccessibilityAudit()\n}",
    "func performAudit(on app: XCUIApplication, context: String) throws {\n    return\n    try app.performAccessibilityAudit()\n}",
    RULES.auditRange,
    testPath,
  );

  assertClean(
    "unlisted helper passes",
    "private func ordinaryHelper() {\n    let value = 1\n}",
    "private func ordinaryHelper() {\n    let value = 2\n}",
    testPath,
  );
  assertFinds(
    "shared helper edit fails",
    "private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {\n    app.swipeUp()\n}",
    "private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {\n    app.swipeDown()\n}",
    RULES.sharedHelper,
    testPath,
  );
  assertFinds(
    "geometry helper string literal edit fails",
    "private func element(_ element: XCUIElement, withFrame frame: CGRect, isDescendantOf scrollView: XCUIElement?) -> Bool {\n    let predicate = NSPredicate(format: \"label == %@\", \"A\")\n    return true\n}",
    "private func element(_ element: XCUIElement, withFrame frame: CGRect, isDescendantOf scrollView: XCUIElement?) -> Bool {\n    let predicate = NSPredicate(format: \"label CONTAINS %@\", \"A\")\n    return true\n}",
    RULES.sharedHelper,
    testPath,
  );
  assertFinds(
    "guard reorder in helper fails",
    "private func auditIgnoringOccludedLessonTextContrast(app: XCUIApplication) throws {\n    guard app.exists else { return }\n    guard app.buttons.count > 0 else { return }\n    return\n}",
    "private func auditIgnoringOccludedLessonTextContrast(app: XCUIApplication) throws {\n    guard app.buttons.count > 0 else { return }\n    return\n    guard app.exists else { return }\n}",
    RULES.sharedHelper,
    testPath,
  );
  assertFinds(
    "inline block comment before return in audit closure fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit { issue in\n        guard issue.auditType == .contrast else { return false }\n        return true\n    }\n}",
    "func testAudit() throws {\n    try app.performAccessibilityAudit { issue in\n        /* x */ return true\n        guard issue.auditType == .contrast else { return false }\n        return true\n    }\n}",
    RULES.auditRange,
    testPath,
  );

  assertClean(
    "accessibilityHidden false passes",
    "struct GuardView: View { var body: some View { Text(\"A\") } }",
    "struct GuardView: View { var body: some View { Text(\"A\").accessibilityHidden(false) } }",
    appViewPath,
  );
  assertFinds(
    "accessibilityHidden true fails",
    "struct GuardView: View { var body: some View { Text(\"A\") } }",
    "struct GuardView: View { var body: some View { Text(\"A\").accessibilityHidden(true) } }",
    RULES.accessibilityHidden,
    appViewPath,
  );
  assertFinds(
    "block comment prefix before XCTSkip fails",
    "func testExample() throws {\n    XCTAssertTrue(true)\n}",
    "func testExample() throws {\n    /**/ try XCTSkipIf(true, \"blocked\")\n    XCTAssertTrue(true)\n}",
    RULES.xctSkip,
    testPath,
  );

  assertClean(
    "accessibility combine passes",
    "struct GuardView: View { var body: some View { Text(\"A\") } }",
    "struct GuardView: View { var body: some View { Text(\"A\").accessibilityElement(children: .combine) } }",
    appViewPath,
  );
  assertFinds(
    "accessibility ignore children fails",
    "struct GuardView: View { var body: some View { Text(\"A\") } }",
    "struct GuardView: View { var body: some View { Text(\"A\").accessibilityElement(children: .ignore) } }",
    RULES.accessibilityIgnoreChildren,
    appViewPath,
  );
  assertFinds(
    "accessibilityElement empty args fails",
    "struct GuardView: View { var body: some View { Text(\"A\") } }",
    "struct GuardView: View { var body: some View { Text(\"A\").accessibilityElement() } }",
    RULES.accessibilityIgnoreChildren,
    appViewPath,
  );

  assertFinds(
    "XCTSkip fails",
    "func testExample() throws {\n    XCTAssertTrue(true)\n}",
    "func testExample() throws {\n    throw XCTSkip(\"blocked\")\n}",
    RULES.xctSkip,
    testPath,
  );
  assertClean(
    "comment-only XCTSkip passes",
    "func testExample() throws {\n    XCTAssertTrue(true)\n}",
    "func testExample() throws {\n    // Do not use XCTSkip(\"blocked\") here.\n    XCTAssertTrue(true)\n}",
    testPath,
  );

  assertClean(
    "minimumScaleFactor in test path passes",
    "func testExample() throws {\n    let text = Text(\"A\")\n}",
    "func testExample() throws {\n    let text = Text(\"A\").minimumScaleFactor(0.5)\n}",
    testPath,
  );
  assertFinds(
    "minimumScaleFactor app view fails",
    "struct GuardView: View { var body: some View { Text(\"A\") } }",
    "struct GuardView: View { var body: some View { Text(\"A\").minimumScaleFactor(0.5) } }",
    RULES.minimumScaleFactor,
    appViewPath,
  );

  assertFinds(
    "block comment wrapping a test method fails",
    "func helper() {}\nfunc testWrapped() {\n    XCTAssertTrue(true)\n}\nfunc testStillHere() {}",
    "func helper() {}\n/*\nfunc testWrapped() {\n    XCTAssertTrue(true)\n}\n*/\nfunc testStillHere() {}",
    RULES.deletedTestMethod,
    testPath,
  );
  assertFinds(
    "if false wrapping a test method fails",
    "func helper() {}\nfunc testWrapped() {\n    XCTAssertTrue(true)\n}\nfunc testStillHere() {}",
    "func helper() {}\n#if false\nfunc testWrapped() {\n    XCTAssertTrue(true)\n}\n#endif\nfunc testStillHere() {}",
    RULES.deletedTestMethod,
    testPath,
  );
  assertFinds(
    "deleted wrapper call fails",
    "func testFlow() throws {\n    try performAudit(on: app, context: \"flow\")\n}\nfunc performAudit(on app: XCUIApplication, context: String) throws {\n    try app.performAccessibilityAudit()\n}",
    "func testFlow() throws {\n    XCTAssertTrue(true)\n}\nfunc performAudit(on app: XCUIApplication, context: String) throws {\n    try app.performAccessibilityAudit()\n}",
    RULES.auditWrapperCall,
    testPath,
  );

  assert.equal(hasApprovalMarker("Summary\nTest-guard-approved: task-49\n"), true);
  assert.equal(hasApprovalMarker("Summary\nTest-guard-approved: owner decision 2026-10-14\n"), true);
  assert.equal(hasApprovalMarker("Summary\nTest-guard-approved:\n## Checks\n"), false);
  assert.equal(hasApprovalMarker("Summary\n- Test-guard-approved: task-49\n"), false);
  assert.equal(hasApprovalMarker("Summary\n```\nTest-guard-approved: task-49\n```\n"), false);
  assert.equal(hasApprovalMarker("Summary\n<!--\nTest-guard-approved: task-49\n-->\n"), false);
  assert.equal(hasApprovalMarker("Summary\nTest-guard-approved: other reason\n"), false);

  const hiddenOldA = "struct A: View { var body: some View { Image(\"a\").accessibilityHidden(true) } }";
  const hiddenNewA = "struct A: View { var body: some View { Image(\"a\") } }";
  const hiddenOldB = "struct B: View { var body: some View { Text(\"b\") } }";
  const hiddenNewB = "struct B: View { var body: some View { Text(\"b\").accessibilityHidden(true) } }";
  const swapDiff = `${diffFixture(hiddenOldA, hiddenNewA, "apps/apple/CanadianHam/A.swift")}${diffFixture(hiddenOldB, hiddenNewB, "apps/apple/CanadianHam/B.swift")}`;
  const swapFindings = checkDiff(swapDiff, (filePath) => filePath.endsWith("A.swift") ? hiddenOldA : hiddenOldB, (filePath) => filePath.endsWith("A.swift") ? hiddenNewA : hiddenNewB);
  assert.equal(swapFindings.some((finding) => finding.filePath.endsWith("B.swift") && finding.rule === RULES.accessibilityHidden), true, "swapping accessibilityHidden(true) between files must flag the increased file");

  const failingDiff = diffFixture(
    "struct GuardView: View { var body: some View { Text(\"A\") } }",
    "struct GuardView: View { var body: some View { Text(\"A\").accessibilityHidden(true) } }",
    appViewPath,
  );
  const approvedFindings = checkDiff(failingDiff, () => "struct GuardView: View { var body: some View { Text(\"A\") } }", () => "struct GuardView: View { var body: some View { Text(\"A\").accessibilityHidden(true) } }");
  const approvedResult = evaluateFindings(approvedFindings, "Test-guard-approved: owner decision 2026-10-14");
  assert.equal(approvedResult.exitCode, 0, "approval marker should bypass failing exit code");
  assert.equal(approvedResult.findings.length > 0, true, "approval path should preserve findings for warnings");

  const oldMultiLines = [
    ...Array.from({ length: 20 }, (_, index) => `let before${index} = ${index}`),
    "private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {",
    "    app.swipeUp()",
    "}",
    ...Array.from({ length: 20 }, (_, index) => `let after${index} = ${index}`),
    "func testKept() {",
    "    XCTAssertTrue(true)",
    "}",
  ];
  const newMultiLines = oldMultiLines.map((line) => line === "    app.swipeUp()" ? "    app.swipeDown()" : line === "    XCTAssertTrue(true)" ? "    XCTAssertFalse(false)" : line);
  const multiDiff = `diff --git a/${testPath} b/${testPath}\n--- a/${testPath}\n+++ b/${testPath}\n@@ -20,7 +20,7 @@\n let before19 = 19\n private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {\n-    app.swipeUp()\n+    app.swipeDown()\n }\n let after0 = 0\n let after1 = 1\n@@ -43,6 +43,6 @@\n let after18 = 18\n let after19 = 19\n func testKept() {\n-    XCTAssertTrue(true)\n+    XCTAssertFalse(false)\n }\n`;
  const multiFindings = checkDiff(multiDiff, () => oldMultiLines.join("\n"), () => newMultiLines.join("\n"));
  assert.equal(multiFindings.some((finding) => finding.rule === RULES.sharedHelper), true, "multi-hunk fixture should flag helper change from first hunk");
  assert.equal(multiFindings.every((finding) => finding.line < 40), true, "second hunk line mapping should not create unrelated findings");

  const selfProtected = checkDiff("", () => "", () => "", [CHECKER_PATH]);
  assert.equal(selfProtected.some((finding) => finding.rule === RULES.guardSelfProtection), true, "checker changes must require approval");

  runRealGitSelfTests();

  console.log("test-guard self-test passed.");
}

function runRealGitSelfTests() {
  const root = mkdtempSync(path.join(tmpdir(), "test-guard."));
  try {
    gitIn(root, ["init", "-b", "main"]);
    gitIn(root, ["config", "user.email", "test@example.invalid"]);
    gitIn(root, ["config", "user.name", "Test Guard"]);

    const testDir = path.join(root, "apps/apple/CanadianHamUITests");
    mkdirSync(testDir, { recursive: true });
    const fixturePath = path.join(testDir, "Guard Fixture.swift");
    const original = `${Array.from({ length: 8 }, (_, index) => `// prelude ${index}`).join("\n")}\nprivate func auditIgnoringOccludedLessonTextContrast(app: XCUIApplication) throws {\n    let auditGeometry = lessonAuditGeometryBelowOpaqueNavigationBar(in: app)\n    try app.performAccessibilityAudit { issue in\n        guard issue.auditType == .contrast else { return false }\n        guard !auditGeometry.visibleScrollArea.contains(issue.element!.frame) else { return false }\n        return true\n    }\n}\n`;
    writeFileSync(fixturePath, original);
    gitIn(root, ["add", "."]);
    gitIn(root, ["commit", "-m", "base"]);
    const mergeBase = gitIn(root, ["rev-parse", "HEAD"]).trim();

    gitIn(root, ["checkout", "-b", "feature"]);
    writeFileSync(fixturePath, original.replace("        guard !auditGeometry.visibleScrollArea.contains(issue.element!.frame) else { return false }\n", ""));
    gitIn(root, ["commit", "-am", "delete guarded line"]);
    const head = gitIn(root, ["rev-parse", "HEAD"]).trim();

    gitIn(root, ["checkout", "main"]);
    writeFileSync(fixturePath, `${Array.from({ length: 80 }, (_, index) => `// main shifted line ${index}`).join("\n")}\n${original}`);
    gitIn(root, ["commit", "-am", "move old-side lines"]);
    const base = gitIn(root, ["rev-parse", "HEAD"]).trim();

    const collected = collectFindingsForRefs({ base, head, repoRoot: root });
    assert.equal(collected.mergeBase, mergeBase, "guard should diff against the merge-base, not base tip");
    assert.equal(collected.findings.some((finding) => finding.rule === RULES.sharedHelper || finding.rule === RULES.auditRange), true, "shared guard collection should catch deletion inside moved audit handler");
    const originalConsoleError = console.error;
    try {
      console.error = () => {};
      assert.equal(runGuard({ base, head, prBody: "", repoRoot: root }), 1, "runGuard should fail for deletion inside moved audit handler");
    } finally {
      console.error = originalConsoleError;
    }

    gitIn(root, ["checkout", "feature"]);
    writeFileSync(fixturePath, original);
    const unicodePath = path.join(testDir, "Grégoire.swift");
    writeFileSync(unicodePath, "struct GuardView: View { var body: some View { Text(\"A\").accessibilityHidden(true) } }\n");
    gitIn(root, ["add", "."]);
    gitIn(root, ["commit", "-m", "unicode path finding"]);
    const unicodeHead = gitIn(root, ["rev-parse", "HEAD"]).trim();
    const unicodeMergeBase = gitMergeBase(mergeBase, unicodeHead, root);
    const unicodeFindings = collectFindingsForRefs({ base: unicodeMergeBase, head: unicodeHead, repoRoot: root }).findings;
    assert.equal(unicodeFindings.some((finding) => finding.filePath.endsWith("Grégoire.swift") && finding.rule === RULES.accessibilityHidden), true, "real git diff fixture should parse non-ASCII paths");
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

function gitIn(repoRoot, args) {
  const result = spawnSync("git", [
    "-c", "commit.gpgsign=false",
    "-c", "core.hooksPath=/dev/null",
    "-c", "core.quotePath=false",
    ...args,
  ], {
    cwd: repoRoot,
    encoding: "utf8",
    maxBuffer: 20 * 1024 * 1024,
  });
  if (result.status !== 0) {
    throw new Error(`git ${args.join(" ")} failed in ${repoRoot}:\n${result.stderr}${result.stdout}`);
  }
  return result.stdout;
}

async function main() {
  let args;
  try {
    args = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    console.error(usage());
    return 2;
  }

  if (args.help) {
    console.log(usage());
    return 0;
  }
  if (args.selfTest) {
    runSelfTest();
    return 0;
  }

  return runGuard({
    base: args.base,
    head: args.head,
    prBody: process.env.TEST_GUARD_PR_BODY ?? "",
  });
}

main().then((exitCode) => {
  process.exit(exitCode);
}).catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
