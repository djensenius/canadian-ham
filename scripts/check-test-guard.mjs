#!/usr/bin/env node
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  mkdirSync,
  mkdtempSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import process from "node:process";

const APPLE_PREFIX = "apps/apple/";
const APPROVAL_MARKER_LINE = /^Test-guard-approved:[ \t]*(?:task-\d+|owner decision \d{4}-\d{2}-\d{2})[ \t]*$/u;

const EXCEPTION_HELPERS = [
  "auditIgnoringOccludedLessonTextContrast",
  "isApprovedMediumDetentToolScrollTextClip",
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
  auditHandler: "performAccessibilityAudit call/handler changes are guarded",
  exceptionHelperCall: "approved-exception helper call changes are guarded",
  sharedHelper: "shared UI-test/audit helper changes are guarded",
  accessibilityHidden: "added .accessibilityHidden(true) is guarded",
  accessibilityIgnoreChildren: "added .accessibilityElement(children: .ignore) or .accessibilityElement() is guarded",
  xctSkip: "added XCTSkip/XCTSkipIf/XCTSkipUnless is guarded",
  minimumScaleFactor: "added .minimumScaleFactor( in app views is guarded",
  deletedTestMethod: "deleted test method is guarded",
};

const FAIL_DIRECTIONS = new Map([
  [RULES.auditHandler, new Set(["addition", "deletion"])],
  [RULES.exceptionHelperCall, new Set(["addition", "deletion"])],
  [RULES.sharedHelper, new Set(["addition", "deletion"])],
  [RULES.accessibilityHidden, new Set(["addition"])],
  [RULES.accessibilityIgnoreChildren, new Set(["addition"])],
  [RULES.xctSkip, new Set(["addition"])],
  [RULES.minimumScaleFactor, new Set(["addition"])],
  [RULES.deletedTestMethod, new Set(["deletion"])],
]);

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
      const beforeComment = line.slice(0, commentStart);
      if (APPROVAL_MARKER_LINE.test(beforeComment)) {
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
  const result = spawnSync("git", args, {
    cwd: options.cwd ?? process.cwd(),
    encoding: "utf8",
    maxBuffer: 20 * 1024 * 1024,
  });
  if (result.status !== 0) {
    const command = `git ${args.join(" ")}`;
    throw new Error(`${command} failed:\n${result.stderr}${result.stdout}`);
  }
  return result.stdout;
}

function gitMergeBase(base, head, repoRoot = process.cwd()) {
  return runGit(["merge-base", base, head], { cwd: repoRoot }).trim();
}

function gitDiff(mergeBase, head, repoRoot = process.cwd()) {
  return runGit(["diff", "--no-ext-diff", "-w", "-M", "--unified=3", `${mergeBase}...${head}`, "--", APPLE_PREFIX], { cwd: repoRoot });
}

function gitFileAt(ref, filePath, repoRoot = process.cwd()) {
  const result = spawnSync("git", ["show", `${ref}:${filePath}`], {
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
      current = {
        oldPath: null,
        newPath: null,
        changes: [],
      };
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
    .map((file) => ({
      ...file,
      path: file.newPath ?? file.oldPath,
    }))
    .filter((file) => file.path !== null && file.path.startsWith(APPLE_PREFIX));
}

function parseDiffPath(rawPath) {
  const pathPart = rawPath.trimEnd().split("\t")[0];
  if (pathPart === "/dev/null") {
    return null;
  }

  const decoded = decodeGitPath(pathPart);
  return decoded.replace(/^[ab]\//u, "");
}

function decodeGitPath(rawPath) {
  if (!rawPath.startsWith('"')) {
    return rawPath;
  }

  let result = "";
  for (let index = 1; index < rawPath.length; index += 1) {
    const character = rawPath[index];
    if (character === '"') {
      return result;
    }
    if (character !== "\\") {
      result += character;
      continue;
    }

    const next = rawPath[index + 1];
    if (next === undefined) {
      result += "\\";
      continue;
    }
    if (next === "n") result += "\n";
    else if (next === "t") result += "\t";
    else if (next === "r") result += "\r";
    else if (next === "b") result += "\b";
    else if (next === "f") result += "\f";
    else if (next === "\\" || next === '"') result += next;
    else if (/[0-7]/u.test(next)) {
      const octal = rawPath.slice(index + 1).match(/^[0-7]{1,3}/u)?.[0] ?? next;
      result += String.fromCharCode(Number.parseInt(octal, 8));
      index += octal.length - 1;
    } else {
      result += next;
    }
    index += 1;
  }

  return result;
}

function splitLines(content) {
  if (content.length === 0) {
    return [];
  }
  return content.replace(/\n$/u, "").split("\n");
}

function lineStarts(content) {
  const starts = [0];
  for (let index = 0; index < content.length; index += 1) {
    if (content[index] === "\n") {
      starts.push(index + 1);
    }
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
  return high + 1;
}

function stripSwiftLine(line, state = { blockComment: false, string: false }) {
  let result = "";
  for (let index = 0; index < line.length; index += 1) {
    const current = line[index];
    const next = line[index + 1];

    if (state.blockComment) {
      if (current === "*" && next === "/") {
        state.blockComment = false;
        index += 1;
      }
      result += " ";
      continue;
    }

    if (state.string) {
      if (current === "\\") {
        result += "  ";
        index += 1;
        continue;
      }
      if (current === '"') {
        state.string = false;
      }
      result += " ";
      continue;
    }

    if (current === "/" && next === "/") {
      result += " ".repeat(line.length - index);
      break;
    }
    if (current === "/" && next === "*") {
      state.blockComment = true;
      result += "  ";
      index += 1;
      continue;
    }
    if (current === '"') {
      state.string = true;
      result += " ";
      continue;
    }

    result += current;
  }
  return result;
}

function isCommentOnlyOrBlank(line) {
  const trimmed = line.trim();
  if (trimmed.length === 0) {
    return true;
  }
  if (trimmed.startsWith("//") || trimmed.startsWith("/*") || trimmed.startsWith("*") || trimmed.startsWith("*/")) {
    return true;
  }
  return stripSwiftLine(line, { blockComment: false, string: false }).trim().length === 0;
}

function normalizedCodeLine(line) {
  return stripSwiftLine(line, { blockComment: false, string: false }).replace(/\s+/gu, " ").trim();
}

function namedFunctionRanges(content, names, rule = RULES.sharedHelper) {
  const uniqueNames = [...new Set(names)].filter((name) => name.length > 0);
  if (uniqueNames.length === 0) {
    return [];
  }

  const lines = splitLines(content);
  const escapedNames = uniqueNames.map(escapeRegExp).join("|");
  const functionPattern = new RegExp(`\\bfunc\\s+(${escapedNames})\\b`, "u");
  const ranges = [];
  const state = { blockComment: false, string: false };
  const stripped = lines.map((line) => stripSwiftLine(line, state));

  for (let index = 0; index < stripped.length; index += 1) {
    const match = stripped[index].match(functionPattern);
    if (match === null) {
      continue;
    }

    let foundOpeningBrace = false;
    let depth = 0;
    let endLine = index + 1;
    for (let scan = index; scan < stripped.length; scan += 1) {
      for (const character of stripped[scan]) {
        if (character === "{") {
          foundOpeningBrace = true;
          depth += 1;
        } else if (character === "}" && foundOpeningBrace) {
          depth -= 1;
        }
      }
      if (foundOpeningBrace && depth <= 0) {
        endLine = scan + 1;
        break;
      }
    }

    ranges.push({ name: match[1], start: index + 1, end: endLine, rule });
  }

  return ranges;
}

function auditCallRanges(content) {
  const ranges = [];
  const starts = lineStarts(content);
  const token = "performAccessibilityAudit";
  let searchIndex = 0;

  while (searchIndex < content.length) {
    const tokenIndex = content.indexOf(token, searchIndex);
    if (tokenIndex === -1) {
      break;
    }
    searchIndex = tokenIndex + token.length;

    if (isIdentifierCharacter(content[tokenIndex - 1]) || isIdentifierCharacter(content[tokenIndex + token.length])) {
      continue;
    }

    const afterToken = nextNonWhitespace(content, tokenIndex + token.length);
    if (afterToken === -1) {
      continue;
    }

    if (content[afterToken] === "{") {
      addBraceRange(ranges, content, starts, tokenIndex, afterToken);
      continue;
    }

    if (content[afterToken] !== "(") {
      continue;
    }

    const closeParen = findMatchingDelimiter(content, afterToken, "(", ")");
    if (closeParen === -1) {
      ranges.push({ name: token, start: offsetToLine(starts, tokenIndex), end: offsetToLine(starts, afterToken), rule: RULES.auditHandler });
      continue;
    }

    const firstClosure = findFirstCodeChar(content, "{", afterToken + 1, closeParen);
    const afterParen = nextNonWhitespace(content, closeParen + 1);
    const hasTrailingClosure = afterParen !== -1 && content[afterParen] === "{";
    if (firstClosure !== -1) {
      const closureEnd = findMatchingDelimiter(content, firstClosure, "{", "}");
      ranges.push({
        name: token,
        start: offsetToLine(starts, tokenIndex),
        end: offsetToLine(starts, Math.max(closeParen, closureEnd)),
        rule: RULES.auditHandler,
      });
    } else if (hasTrailingClosure) {
      addBraceRange(ranges, content, starts, tokenIndex, afterParen);
    } else {
      ranges.push({
        name: token,
        start: offsetToLine(starts, tokenIndex),
        end: offsetToLine(starts, closeParen),
        rule: RULES.auditHandler,
      });
    }
  }

  return ranges;
}

function auditNamedHandlers(content) {
  const handlers = new Set();
  const token = "performAccessibilityAudit";
  let searchIndex = 0;

  while (searchIndex < content.length) {
    const tokenIndex = content.indexOf(token, searchIndex);
    if (tokenIndex === -1) {
      break;
    }
    searchIndex = tokenIndex + token.length;

    const afterToken = nextNonWhitespace(content, tokenIndex + token.length);
    if (afterToken === -1 || content[afterToken] !== "(") {
      continue;
    }
    const closeParen = findMatchingDelimiter(content, afterToken, "(", ")");
    if (closeParen === -1) {
      continue;
    }

    for (const argument of topLevelArguments(content.slice(afterToken + 1, closeParen))) {
      const normalized = argument.trim();
      const handlerMatch = normalized.match(/^(?:handler\s*:\s*|issueHandler\s*:\s*)?([A-Za-z_][A-Za-z0-9_]*)$/u)
        ?? normalized.match(/^_?\s*([A-Za-z_][A-Za-z0-9_]*)$/u);
      if (handlerMatch !== null && !["for", "true", "false", "nil"].includes(handlerMatch[1])) {
        handlers.add(handlerMatch[1]);
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
  let blockComment = false;
  let lineComment = false;
  let string = false;

  for (let index = 0; index < argumentText.length; index += 1) {
    const current = argumentText[index];
    const next = argumentText[index + 1];
    if (lineComment) {
      if (current === "\n") lineComment = false;
      continue;
    }
    if (blockComment) {
      if (current === "*" && next === "/") {
        blockComment = false;
        index += 1;
      }
      continue;
    }
    if (string) {
      if (current === "\\") index += 1;
      else if (current === '"') string = false;
      continue;
    }
    if (current === "/" && next === "/") {
      lineComment = true;
      index += 1;
      continue;
    }
    if (current === "/" && next === "*") {
      blockComment = true;
      index += 1;
      continue;
    }
    if (current === '"') {
      string = true;
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

function addBraceRange(ranges, content, starts, tokenIndex, braceIndex) {
  const closeBrace = findMatchingDelimiter(content, braceIndex, "{", "}");
  ranges.push({
    name: "performAccessibilityAudit",
    start: offsetToLine(starts, tokenIndex),
    end: offsetToLine(starts, closeBrace === -1 ? braceIndex : closeBrace),
    rule: RULES.auditHandler,
  });
}

function nextNonWhitespace(content, index) {
  for (let cursor = index; cursor < content.length; cursor += 1) {
    if (!/\s/u.test(content[cursor])) {
      return cursor;
    }
  }
  return -1;
}

function isIdentifierCharacter(character) {
  return character !== undefined && /[A-Za-z0-9_]/u.test(character);
}

function findMatchingDelimiter(content, openIndex, openChar, closeChar) {
  let depth = 0;
  let blockComment = false;
  let lineComment = false;
  let string = false;

  for (let index = openIndex; index < content.length; index += 1) {
    const current = content[index];
    const next = content[index + 1];

    if (lineComment) {
      if (current === "\n") {
        lineComment = false;
      }
      continue;
    }
    if (blockComment) {
      if (current === "*" && next === "/") {
        blockComment = false;
        index += 1;
      }
      continue;
    }
    if (string) {
      if (current === "\\") {
        index += 1;
      } else if (current === '"') {
        string = false;
      }
      continue;
    }

    if (current === "/" && next === "/") {
      lineComment = true;
      index += 1;
      continue;
    }
    if (current === "/" && next === "*") {
      blockComment = true;
      index += 1;
      continue;
    }
    if (current === '"') {
      string = true;
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

function findFirstCodeChar(content, target, start, end) {
  let blockComment = false;
  let lineComment = false;
  let string = false;
  for (let index = start; index < end; index += 1) {
    const current = content[index];
    const next = content[index + 1];
    if (lineComment) {
      if (current === "\n") lineComment = false;
      continue;
    }
    if (blockComment) {
      if (current === "*" && next === "/") {
        blockComment = false;
        index += 1;
      }
      continue;
    }
    if (string) {
      if (current === "\\") index += 1;
      else if (current === '"') string = false;
      continue;
    }
    if (current === "/" && next === "/") {
      lineComment = true;
      index += 1;
      continue;
    }
    if (current === "/" && next === "*") {
      blockComment = true;
      index += 1;
      continue;
    }
    if (current === '"') {
      string = true;
      continue;
    }
    if (current === target) {
      return index;
    }
  }
  return -1;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/gu, "\\$&");
}

function rangeContainingLine(line, ranges) {
  return ranges.find((range) => line >= range.start && line <= range.end) ?? null;
}

function isAppViewPath(filePath) {
  return filePath.endsWith(".swift")
    && (filePath.startsWith("apps/apple/CanadianHam/") || filePath.startsWith("apps/apple/Platforms/"))
    && !filePath.split("/").some((segment) => /Tests?$/u.test(segment) || /UITests?$/u.test(segment));
}

function checkDiff(diff, getOldContent, getNewContent) {
  const events = collectGuardEvents(diff, getOldContent, getNewContent);
  return collapseEventsToFindings(events);
}

function collectGuardEvents(diff, getOldContent, getNewContent) {
  const events = [];

  for (const file of parseUnifiedDiff(diff)) {
    const oldPath = file.oldPath ?? file.path;
    const newPath = file.newPath ?? file.path;
    const oldContent = oldPath === null ? "" : getOldContent(oldPath);
    const newContent = newPath === null ? "" : getNewContent(newPath);
    const oldNamedHandlers = auditNamedHandlers(oldContent);
    const newNamedHandlers = auditNamedHandlers(newContent);
    const oldRanges = [
      ...namedFunctionRanges(oldContent, SHARED_HELPERS, RULES.sharedHelper),
      ...namedFunctionRanges(oldContent, oldNamedHandlers, RULES.auditHandler),
      ...auditCallRanges(oldContent),
    ];
    const newRanges = [
      ...namedFunctionRanges(newContent, SHARED_HELPERS, RULES.sharedHelper),
      ...namedFunctionRanges(newContent, newNamedHandlers, RULES.auditHandler),
      ...auditCallRanges(newContent),
    ];

    for (const change of file.changes) {
      const pathForFinding = change.kind === "deletion" ? (oldPath ?? file.path) : (newPath ?? file.path);
      if (pathForFinding === null || isCommentOnlyOrBlank(change.text)) {
        continue;
      }

      const code = normalizedCodeLine(change.text);
      if (code.length === 0) {
        continue;
      }

      const ranges = change.kind === "deletion" ? oldRanges : newRanges;
      const range = rangeContainingLine(change.line, ranges);
      if (range !== null) {
        addEvent(events, change.kind, pathForFinding, change.line, range.rule, `${range.name}:${code}`);
      }

      if (/\bperformAccessibilityAudit\b/u.test(code)) {
        addEvent(events, change.kind, pathForFinding, change.line, RULES.auditHandler, `performAccessibilityAudit:${code}`);
      }

      const exceptionHelper = EXCEPTION_HELPERS.find((helper) => new RegExp(`\\b${escapeRegExp(helper)}\\s*\\(`, "u").test(code));
      if (exceptionHelper !== undefined) {
        addEvent(events, change.kind, pathForFinding, change.line, RULES.exceptionHelperCall, `${exceptionHelper}:${code}`);
      }

      if (/\.accessibilityHidden\s*\(\s*true\s*\)/u.test(code)) {
        addEvent(events, change.kind, pathForFinding, change.line, RULES.accessibilityHidden, "accessibilityHidden(true)");
      }
      if (/\.accessibilityElement\s*\(\s*(?:children\s*:\s*\.ignore\s*)?\)/u.test(code)) {
        addEvent(events, change.kind, pathForFinding, change.line, RULES.accessibilityIgnoreChildren, "accessibilityElement(ignore)");
      }
      if (/\bXCTSkip(?:If|Unless)?\s*\(/u.test(code) || /\bthrow\s+XCTSkip\b/u.test(code)) {
        addEvent(events, change.kind, pathForFinding, change.line, RULES.xctSkip, "XCTSkip");
      }
      if (isAppViewPath(pathForFinding) && /\.minimumScaleFactor\s*\(/u.test(code)) {
        addEvent(events, change.kind, pathForFinding, change.line, RULES.minimumScaleFactor, "minimumScaleFactor");
      }

      const testMatch = code.match(/^\s*func\s+(test[A-Za-z0-9_]*)\s*\(/u);
      if (testMatch !== null) {
        addEvent(events, change.kind, pathForFinding, change.line, RULES.deletedTestMethod, testMatch[1]);
      }
    }
  }

  return events;
}

function addEvent(events, direction, filePath, line, rule, key) {
  events.push({ direction, filePath, line, rule, key });
}

function collapseEventsToFindings(events) {
  const buckets = new Map();
  for (const event of events) {
    const bucketKey = `${event.rule}\0${event.key}`;
    const bucket = buckets.get(bucketKey) ?? { additions: [], deletions: [] };
    if (event.direction === "addition") {
      bucket.additions.push(event);
    } else {
      bucket.deletions.push(event);
    }
    buckets.set(bucketKey, bucket);
  }

  const findings = [];
  const seen = new Set();
  for (const [bucketKey, bucket] of buckets) {
    const rule = bucketKey.split("\0", 1)[0];
    const failDirections = FAIL_DIRECTIONS.get(rule) ?? new Set(["addition", "deletion"]);
    const matchedPairs = Math.min(bucket.additions.length, bucket.deletions.length);

    if (failDirections.has("addition")) {
      for (const event of bucket.additions.slice(matchedPairs)) {
        addFinding(findings, seen, event.filePath, event.line, event.rule);
      }
    }
    if (failDirections.has("deletion")) {
      for (const event of bucket.deletions.slice(matchedPairs)) {
        addFinding(findings, seen, event.filePath, event.line, event.rule);
      }
    }
  }

  return findings.sort((a, b) => a.filePath.localeCompare(b.filePath) || a.line - b.line || a.rule.localeCompare(b.rule));
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
  const message = escapeGithubCommand(finding.rule);
  return `::warning file=${escapeGithubCommand(finding.filePath)},line=${finding.line}::${message}`;
}

function escapeGithubCommand(value) {
  return String(value)
    .replace(/%/gu, "%25")
    .replace(/\r/gu, "%0D")
    .replace(/\n/gu, "%0A")
    .replace(/,/gu, "%2C")
    .replace(/:/gu, "%3A");
}

function evaluateFindings(findings, prBody) {
  const approved = hasApprovalMarker(prBody);
  return {
    approved,
    findings,
    exitCode: findings.length > 0 && !approved ? 1 : 0,
  };
}

function runGuard({ base, head, prBody, repoRoot = process.cwd() }) {
  const mergeBase = gitMergeBase(base, head, repoRoot);
  const diff = gitDiff(mergeBase, head, repoRoot);
  const findings = checkDiff(
    diff,
    (filePath) => gitFileAt(mergeBase, filePath, repoRoot),
    (filePath) => gitFileAt(head, filePath, repoRoot),
  );
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
    console.error("Test guard failed: guarded Apple test/view changes require a PR body line 'Test-guard-approved: task-123' or 'Test-guard-approved: owner decision YYYY-MM-DD'.");
    for (const finding of findings) {
      console.error(`- ${formatFinding(finding)}`);
    }
    return 1;
  }

  if (result.approved) {
    console.log(`Test guard passed: approval marker present but no guarded Apple test/view changes found in ${mergeBase}...${head}.`);
  } else {
    console.log(`Test guard passed: no guarded Apple test/view changes found in ${mergeBase}...${head}.`);
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

  assertClean(
    "plain audit call plus unrelated assertion passes",
    "func testAudit() throws {\n    try app.performAccessibilityAudit()\n}",
    "func testAudit() throws {\n    try app.performAccessibilityAudit()\n    XCTAssertTrue(true)\n}",
    testPath,
  );
  assertFinds(
    "audit trailing closure fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit()\n}",
    "func testAudit() throws {\n    try app.performAccessibilityAudit { issue in\n        return false\n    }\n}",
    RULES.auditHandler,
    testPath,
  );
  assertFinds(
    "plain audit deletion fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit()\n}",
    "func testAudit() throws {\n    XCTAssertTrue(true)\n}",
    RULES.auditHandler,
    testPath,
  );
  assertFinds(
    "audit type narrowing fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit()\n}",
    "func testAudit() throws {\n    try app.performAccessibilityAudit(for: .dynamicType)\n}",
    RULES.auditHandler,
    testPath,
  );
  assertFinds(
    "audit named handler fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit()\n}",
    "func testAudit() throws {\n    try app.performAccessibilityAudit(myFilter)\n}",
    RULES.auditHandler,
    testPath,
  );
  assertFinds(
    "existing named handler body edit fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit(myFilter)\n}\nfunc myFilter(_ issue: XCTAccessibilityAuditIssue) -> Bool {\n    return true\n}",
    "func testAudit() throws {\n    try app.performAccessibilityAudit(myFilter)\n}\nfunc myFilter(_ issue: XCTAccessibilityAuditIssue) -> Bool {\n    return false\n}",
    RULES.auditHandler,
    testPath,
  );
  assertFinds(
    "exception helper call fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit()\n}",
    "func testAudit() throws {\n    try auditIgnoringOccludedLessonTextContrast(app: app)\n}",
    RULES.exceptionHelperCall,
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
    "geometry helper edit fails",
    "private func lessonAuditGeometryBelowOpaqueNavigationBar(in app: XCUIApplication) -> LessonAuditGeometry {\n    return geometry\n}",
    "private func lessonAuditGeometryBelowOpaqueNavigationBar(in app: XCUIApplication) -> LessonAuditGeometry {\n    return narrowedGeometry\n}",
    RULES.sharedHelper,
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
  assertClean(
    "touching existing accessibilityHidden true cancels by count",
    "struct GuardView: View { var body: some View { Image(\"a\").accessibilityHidden(true) } }",
    "struct GuardView: View { var body: some View { Image(\"b\").accessibilityHidden(true) } }",
    appViewPath,
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

  assertClean(
    "ordinary XCTest assertion passes",
    "func testExample() throws {\n    XCTAssertTrue(true)\n}",
    "func testExample() throws {\n    XCTAssertFalse(false)\n}",
    testPath,
  );
  assertFinds(
    "XCTSkip fails",
    "func testExample() throws {\n    XCTAssertTrue(true)\n}",
    "func testExample() throws {\n    throw XCTSkip(\"blocked\")\n}",
    RULES.xctSkip,
    testPath,
  );
  assertFinds(
    "XCTSkipIf fails",
    "func testExample() throws {\n    XCTAssertTrue(true)\n}",
    "func testExample() throws {\n    try XCTSkipIf(true, \"blocked\")\n}",
    RULES.xctSkip,
    testPath,
  );
  assertFinds(
    "XCTSkipUnless fails",
    "func testExample() throws {\n    XCTAssertTrue(true)\n}",
    "func testExample() throws {\n    try XCTSkipUnless(false, \"blocked\")\n}",
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

  assertClean(
    "test method move cancels by name",
    "func testMoved() {\n    XCTAssertTrue(true)\n}\nfunc helper() {}",
    "func helper() {}\nfunc testMoved() {\n    XCTAssertTrue(true)\n}",
    testPath,
  );
  assertFinds(
    "deleted test method fails",
    "func helper() {\n    XCTAssertTrue(true)\n}\nfunc testRemoved() {\n    XCTAssertTrue(true)\n}",
    "func helper() {\n    XCTAssertTrue(true)\n}\n    XCTAssertTrue(true)\n}",
    RULES.deletedTestMethod,
    testPath,
  );

  assert.equal(hasApprovalMarker("Summary\nTest-guard-approved: task-49\n"), true);
  assert.equal(hasApprovalMarker("Summary\nTest-guard-approved: owner decision 2026-10-14\n"), true);
  assert.equal(hasApprovalMarker("Summary\nTest-guard-approved:\n## Checks\n"), false);
  assert.equal(hasApprovalMarker("Summary\n- Test-guard-approved: task-49\n"), false);
  assert.equal(hasApprovalMarker("Summary\n```\nTest-guard-approved: task-49\n```\n"), false);
  assert.equal(hasApprovalMarker("Summary\n<!--\nTest-guard-approved: task-49\n-->\n"), false);
  assert.equal(hasApprovalMarker("Summary\nTest-guard-approved: other reason\n"), false);

  const failingDiff = diffFixture(
    "struct GuardView: View { var body: some View { Text(\"A\") } }",
    "struct GuardView: View { var body: some View { Text(\"A\").accessibilityHidden(true) } }",
    appViewPath,
  );
  const approvedFindings = checkDiff(
    failingDiff,
    () => "struct GuardView: View { var body: some View { Text(\"A\") } }",
    () => "struct GuardView: View { var body: some View { Text(\"A\").accessibilityHidden(true) } }",
  );
  const approvedResult = evaluateFindings(approvedFindings, "Test-guard-approved: owner decision 2026-10-14");
  assert.equal(approvedResult.exitCode, 0, "approval marker should bypass failing exit code");
  assert.equal(approvedResult.findings.length > 0, true, "approval path should preserve findings for warnings");

  const oldMulti = `${Array.from({ length: 20 }, (_, index) => `let before${index} = ${index}`).join("\n")}\nprivate func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {\n    app.swipeUp()\n}\n${Array.from({ length: 20 }, (_, index) => `let after${index} = ${index}`).join("\n")}\nfunc testKept() {\n    XCTAssertTrue(true)\n}`;
  const newMulti = oldMulti
    .replace("app.swipeUp()", "app.swipeDown()")
    .replace("XCTAssertTrue(true)", "XCTAssertFalse(false)");
  const multiDiff = `diff --git a/${testPath} b/${testPath}\n--- a/${testPath}\n+++ b/${testPath}\n@@ -19,7 +19,7 @@\n let before18 = 18\n let before19 = 19\n private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {\n-    app.swipeUp()\n+    app.swipeDown()\n }\n let after0 = 0\n let after1 = 1\n@@ -44,5 +44,5 @@\n let after18 = 18\n let after19 = 19\n func testKept() {\n-    XCTAssertTrue(true)\n+    XCTAssertFalse(false)\n }\n`;
  assertFindsInDiff("multi-hunk mid-function helper edit fails", multiDiff, oldMulti, newMulti, RULES.sharedHelper);

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
    writeFileSync(fixturePath, `// main moved the helper down\n// another new line\n${original}`);
    gitIn(root, ["commit", "-am", "move old-side lines"]);
    const base = gitIn(root, ["rev-parse", "HEAD"]).trim();

    const computedMergeBase = gitMergeBase(base, head, root);
    assert.equal(computedMergeBase, mergeBase, "guard should diff against the merge-base, not base tip");
    const movedDiff = gitDiff(computedMergeBase, head, root);
    const movedFindings = checkDiff(
      movedDiff,
      (filePath) => gitFileAt(computedMergeBase, filePath, root),
      (filePath) => gitFileAt(head, filePath, root),
    );
    assert.equal(movedFindings.some((finding) => finding.rule === RULES.sharedHelper || finding.rule === RULES.auditHandler), true, "merge-base old-side reads should catch deletion inside moved audit handler");

    gitIn(root, ["checkout", "feature"]);
    writeFileSync(fixturePath, original);
    const quotedPath = path.join(testDir, "Quoted Path.swift");
    writeFileSync(quotedPath, "struct GuardView: View { var body: some View { Text(\"A\").accessibilityHidden(true) } }\n");
    gitIn(root, ["add", "."]);
    gitIn(root, ["commit", "-m", "quoted path finding"]);
    const quotedHead = gitIn(root, ["rev-parse", "HEAD"]).trim();
    const quotedMergeBase = gitMergeBase(mergeBase, quotedHead, root);
    const quotedDiff = gitDiff(quotedMergeBase, quotedHead, root);
    const quotedFindings = checkDiff(
      quotedDiff,
      (filePath) => gitFileAt(quotedMergeBase, filePath, root),
      (filePath) => gitFileAt(quotedHead, filePath, root),
    );
    assert.equal(quotedFindings.some((finding) => finding.filePath.endsWith("Quoted Path.swift") && finding.rule === RULES.accessibilityHidden), true, "real git diff fixture should parse paths with spaces");
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

function gitIn(repoRoot, args) {
  const result = spawnSync("git", args, {
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
