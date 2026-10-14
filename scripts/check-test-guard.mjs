#!/usr/bin/env node
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import process from "node:process";

const APPLE_PREFIX = "apps/apple/";
const APPROVAL_MARKER = /^Test-guard-approved:\s*\S.*$/mu;

const SHARED_HELPERS = [
  "auditIgnoringOccludedLessonTextContrast",
  "scrollUntilHittable",
  "preciseScroll",
  "positionElementInMiddleVisibleBand",
  "settleScrollableContentBelowNavigationBar",
  "elementsNearestProtectedBar",
  "assertFullyVisibleBelowNavigationBar",
  "isApprovedMediumDetentToolScrollTextClip",
];

const RULES = {
  auditHandler: "performAccessibilityAudit handler/trailing-closure changes are guarded",
  sharedHelper: "shared UI-test/audit helper changes are guarded",
  accessibilityHidden: "added .accessibilityHidden(true) is guarded",
  accessibilityIgnoreChildren: "added .accessibilityElement(children: .ignore) is guarded",
  xctSkip: "added XCTSkip/XCTSkipIf/XCTSkipUnless is guarded",
  minimumScaleFactor: "added .minimumScaleFactor( in app views is guarded",
  deletedTestMethod: "deleted test method is guarded",
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
  TEST_GUARD_PR_BODY              Pull request body; a line starting
                                  Test-guard-approved: bypasses failures.`;
}

function hasApprovalMarker(body) {
  return APPROVAL_MARKER.test(body ?? "");
}

function runGit(args, options = {}) {
  const result = spawnSync("git", args, {
    cwd: process.cwd(),
    encoding: "utf8",
    maxBuffer: 20 * 1024 * 1024,
    ...options,
  });
  if (result.status !== 0) {
    const command = `git ${args.join(" ")}`;
    throw new Error(`${command} failed:\n${result.stderr}${result.stdout}`);
  }
  return result.stdout;
}

function gitDiff(base, head) {
  return runGit(["diff", "--no-ext-diff", "--no-renames", "--unified=3", `${base}...${head}`, "--", APPLE_PREFIX]);
}

function gitFileAt(ref, filePath) {
  const result = spawnSync("git", ["show", `${ref}:${filePath}`], {
    cwd: process.cwd(),
    encoding: "utf8",
    maxBuffer: 20 * 1024 * 1024,
  });
  if (result.status !== 0) {
    return "";
  }
  return result.stdout;
}

function parseUnifiedDiff(diff) {
  const files = [];
  let current = null;
  let oldLine = 0;
  let newLine = 0;
  let inHunk = false;

  for (const rawLine of diff.split("\n")) {
    if (rawLine.startsWith("diff --git ")) {
      const paths = rawLine.match(/^diff --git a\/(.+) b\/(.+)$/u);
      current = {
        oldPath: paths?.[1] ?? null,
        newPath: paths?.[2] ?? null,
        changes: [],
      };
      files.push(current);
      inHunk = false;
      continue;
    }

    if (current === null) {
      continue;
    }

    if (rawLine.startsWith("--- ")) {
      current.oldPath = parseDiffPath(rawLine.slice(4));
      continue;
    }
    if (rawLine.startsWith("+++ ")) {
      current.newPath = parseDiffPath(rawLine.slice(4));
      continue;
    }

    const hunk = rawLine.match(/^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@/u);
    if (hunk !== null) {
      oldLine = Number(hunk[1]);
      newLine = Number(hunk[2]);
      inHunk = true;
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
  if (rawPath === "/dev/null") {
    return null;
  }
  return rawPath.replace(/^[ab]\//u, "");
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

function stripSwiftLine(line, state) {
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

function namedFunctionRanges(content, names) {
  const lines = splitLines(content);
  const escapedNames = names.map(escapeRegExp).join("|");
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

    ranges.push({ name: match[1], start: index + 1, end: endLine });
  }

  return ranges;
}

function auditHandlerRanges(content) {
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
      continue;
    }

    const firstClosure = findFirstCodeChar(content, "{", afterToken + 1, closeParen);
    const afterParen = nextNonWhitespace(content, closeParen + 1);
    const hasTrailingClosure = afterParen !== -1 && content[afterParen] === "{";
    const hasHandlerArgument = firstClosure !== -1
      || hasTopLevelComma(content, afterToken + 1, closeParen)
      || /\b(?:issueHandler|handler)\s*:/u.test(content.slice(afterToken + 1, closeParen));

    if (firstClosure !== -1) {
      const closureEnd = findMatchingDelimiter(content, firstClosure, "{", "}");
      ranges.push({
        start: offsetToLine(starts, tokenIndex),
        end: offsetToLine(starts, Math.max(closeParen, closureEnd)),
      });
    } else if (hasTrailingClosure) {
      addBraceRange(ranges, content, starts, tokenIndex, afterParen);
    } else if (hasHandlerArgument) {
      ranges.push({
        start: offsetToLine(starts, tokenIndex),
        end: offsetToLine(starts, closeParen),
      });
    }
  }

  return ranges;
}

function addBraceRange(ranges, content, starts, tokenIndex, braceIndex) {
  const closeBrace = findMatchingDelimiter(content, braceIndex, "{", "}");
  ranges.push({
    start: offsetToLine(starts, tokenIndex),
    end: offsetToLine(starts, closeBrace === -1 ? braceIndex : closeBrace),
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

function hasTopLevelComma(content, start, end) {
  let parenDepth = 0;
  let bracketDepth = 0;
  let braceDepth = 0;
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

    if (current === "(" ) parenDepth += 1;
    else if (current === ")") parenDepth -= 1;
    else if (current === "[") bracketDepth += 1;
    else if (current === "]") bracketDepth -= 1;
    else if (current === "{") braceDepth += 1;
    else if (current === "}") braceDepth -= 1;
    else if (current === "," && parenDepth === 0 && bracketDepth === 0 && braceDepth === 0) return true;
  }

  return false;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/gu, "\\$&");
}

function lineInRanges(line, ranges) {
  return ranges.some((range) => line >= range.start && line <= range.end);
}

function isAppViewPath(filePath) {
  return filePath.endsWith(".swift")
    && (filePath.startsWith("apps/apple/CanadianHam/") || filePath.startsWith("apps/apple/Platforms/"))
    && !filePath.split("/").some((segment) => /Tests?$/u.test(segment) || /UITests?$/u.test(segment));
}

function checkDiff(diff, getOldContent, getNewContent) {
  return checkDiffWithApproval(diff, "", getOldContent, getNewContent);
}

function checkDiffWithApproval(diff, prBody, getOldContent, getNewContent) {
  if (hasApprovalMarker(prBody)) {
    return [];
  }

  const findings = [];
  const seen = new Set();

  for (const file of parseUnifiedDiff(diff)) {
    const oldPath = file.oldPath ?? file.path;
    const newPath = file.newPath ?? file.path;
    const oldContent = oldPath === null ? "" : getOldContent(oldPath);
    const newContent = newPath === null ? "" : getNewContent(newPath);
    const oldHelperRanges = namedFunctionRanges(oldContent, SHARED_HELPERS);
    const newHelperRanges = namedFunctionRanges(newContent, SHARED_HELPERS);
    const oldAuditRanges = auditHandlerRanges(oldContent);
    const newAuditRanges = auditHandlerRanges(newContent);

    for (const change of file.changes) {
      const pathForFinding = change.kind === "deletion" ? (oldPath ?? file.path) : (newPath ?? file.path);
      if (pathForFinding === null) {
        continue;
      }

      if (change.kind === "addition") {
        if (lineInRanges(change.line, newAuditRanges)) {
          addFinding(findings, seen, pathForFinding, change.line, RULES.auditHandler);
        }
        if (lineInRanges(change.line, newHelperRanges)) {
          addFinding(findings, seen, pathForFinding, change.line, RULES.sharedHelper);
        }
        if (/\.accessibilityHidden\s*\(\s*true\s*\)/u.test(change.text)) {
          addFinding(findings, seen, pathForFinding, change.line, RULES.accessibilityHidden);
        }
        if (/\.accessibilityElement\s*\(\s*children\s*:\s*\.ignore\s*\)/u.test(change.text)) {
          addFinding(findings, seen, pathForFinding, change.line, RULES.accessibilityIgnoreChildren);
        }
        if (/\bXCTSkip(?:If|Unless)?\s*\(/u.test(change.text) || /\bthrow\s+XCTSkip\b/u.test(change.text)) {
          addFinding(findings, seen, pathForFinding, change.line, RULES.xctSkip);
        }
        if (isAppViewPath(pathForFinding) && /\.minimumScaleFactor\s*\(/u.test(change.text)) {
          addFinding(findings, seen, pathForFinding, change.line, RULES.minimumScaleFactor);
        }
      } else if (change.kind === "deletion") {
        if (lineInRanges(change.line, oldAuditRanges)) {
          addFinding(findings, seen, pathForFinding, change.line, RULES.auditHandler);
        }
        if (lineInRanges(change.line, oldHelperRanges)) {
          addFinding(findings, seen, pathForFinding, change.line, RULES.sharedHelper);
        }
        if (/^\s*func\s+test[A-Za-z0-9_]*\s*\(/u.test(change.text)) {
          addFinding(findings, seen, pathForFinding, change.line, RULES.deletedTestMethod);
        }
      }
    }
  }

  return findings;
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

function runGuard({ base, head, prBody }) {
  if (hasApprovalMarker(prBody)) {
    console.log("Test guard approved by PR body marker; guarded Apple test/view changes are allowed for this PR.");
    return 0;
  }

  const diff = gitDiff(base, head);
  const findings = checkDiff(
    diff,
    (filePath) => gitFileAt(base, filePath),
    (filePath) => gitFileAt(head, filePath),
  );

  if (findings.length > 0) {
    console.error("Test guard failed: guarded Apple test/view changes require a PR body line 'Test-guard-approved: <reason>'.");
    for (const finding of findings) {
      console.error(`- ${formatFinding(finding)}`);
    }
    return 1;
  }

  console.log(`Test guard passed: no guarded Apple test/view changes found in ${base}...${head}.`);
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
  const findings = checkDiff(diff, () => oldContent, () => newContent);
  if (!findings.some((finding) => finding.rule === expectedRule)) {
    throw new Error(`${name} missed ${expectedRule}; findings: ${findings.map(formatFinding).join("; ")}`);
  }
}

function assertClean(name, oldContent, newContent, filePath) {
  const diff = diffFixture(oldContent, newContent, filePath);
  const findings = checkDiff(diff, () => oldContent, () => newContent);
  assert.deepEqual(findings, [], `${name} expected no findings`);
}

function runSelfTest() {
  const testPath = "apps/apple/CanadianHamUITests/GuardFixture.swift";
  const appViewPath = "apps/apple/CanadianHam/GuardView.swift";

  assertClean(
    "plain audit call passes",
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
    "non-test method deletion passes",
    "func helper() {\n    XCTAssertTrue(true)\n}\nfunc testStillHere() {\n    XCTAssertTrue(true)\n}",
    "func helper() {\n    XCTAssertTrue(true)\n}\nfunc testStillHere() {\n    XCTAssertTrue(true)\n}",
    testPath,
  );
  assertFinds(
    "deleted test method fails",
    "func helper() {\n    XCTAssertTrue(true)\n}\nfunc testRemoved() {\n    XCTAssertTrue(true)\n}",
    "func helper() {\n    XCTAssertTrue(true)\n}\n    XCTAssertTrue(true)\n}",
    RULES.deletedTestMethod,
    testPath,
  );

  assert.equal(hasApprovalMarker("Summary\nTest-guard-approved: task-49 self-test\n"), true);
  assert.equal(hasApprovalMarker("Summary\nTest-guard-approved:\n"), false);

  assertFinds(
    "audit handler argument fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit()\n}",
    "func testAudit() throws {\n    try app.performAccessibilityAudit(for: .all, auditHandler)\n}",
    RULES.auditHandler,
    testPath,
  );
  assertFinds(
    "existing audit handler body edit fails",
    "func testAudit() throws {\n    try app.performAccessibilityAudit { issue in\n        return issue.auditType == .contrast\n    }\n}",
    "func testAudit() throws {\n    try app.performAccessibilityAudit { issue in\n        return false\n    }\n}",
    RULES.auditHandler,
    testPath,
  );

  const failingDiff = diffFixture(
    "struct GuardView: View { var body: some View { Text(\"A\") } }",
    "struct GuardView: View { var body: some View { Text(\"A\").accessibilityHidden(true) } }",
    appViewPath,
  );
  const approvedFindings = checkDiffWithApproval(
    failingDiff,
    "Test-guard-approved: owner decision 2026-10-14",
    () => "struct GuardView: View { var body: some View { Text(\"A\") } }",
    () => "struct GuardView: View { var body: some View { Text(\"A\").accessibilityHidden(true) } }",
  );
  assert.deepEqual(approvedFindings, [], "approval marker should bypass failing findings");

  console.log("test-guard self-test passed.");
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
