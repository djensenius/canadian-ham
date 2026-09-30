#!/usr/bin/env python3
"""Guard SwiftUI text entry points against unlocalized plain String content."""
from __future__ import annotations

import argparse
import dataclasses
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE_ROOTS = [
    ROOT / "apps/apple/CanadianHam/Views",
    ROOT / "apps/apple/Platforms",
]
SELF_TEST_FIXTURE = ROOT / "scripts/fixtures/apple-text-sources"
MARKER_RE = re.compile(r"//\s*l10n:\s*(content|verbatim)\b")
DECL_RE = re.compile(r"(?:@\w+(?:\([^)]*\))?\s+)*(?:private\s+|fileprivate\s+|internal\s+|public\s+|let\s+|var\s+|static\s+|final\s+|weak\s+|unowned\s+)*\b(let|var)\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?::\s*([^=\n{]+))?(?:=\s*([^\n]+))?")
PARAM_RE = re.compile(r"(?:^|[,\(])\s*(?:_[ ]+)?([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([^,\)]+)")

STRING_TYPES = {"String", "String?"}
LOCALIZED_TYPES = {
    "LocalizedStringKey",
    "LocalizedStringKey?",
    "LocalizedStringResource",
    "LocalizedStringResource?",
    "AttributedString",
    "AttributedString?",
    "Text",
    "Text?",
}

@dataclasses.dataclass(frozen=True)
class Violation:
    path: Path
    line: int
    expression: str
    callee: str

    def format(self, root: Path = ROOT) -> str:
        try:
            rel = self.path.relative_to(root)
        except ValueError:
            rel = self.path
        return f"{rel}:{self.line}: {self.callee}({self.expression}) uses an unlocalized plain String; convert it or add // l10n: content or // l10n: verbatim"


def strip_comments(line: str) -> str:
    if "//" not in line:
        return line
    return line.split("//", 1)[0]


def collect_symbols(text: str) -> dict[str, str]:
    symbols: dict[str, str] = {}
    for raw_line in text.splitlines():
        line = strip_comments(raw_line)
        for match in DECL_RE.finditer(line):
            name = match.group(2)
            typ = (match.group(3) or "").strip()
            initializer = (match.group(4) or "").strip()
            if typ:
                symbols[name] = normalize_type(typ)
            elif initializer.startswith('"') or initializer.startswith('String(localized:'):
                symbols[name] = "String"
        if "func " in line or "init(" in line or "(" in line:
            for param in PARAM_RE.finditer(line):
                symbols[param.group(1)] = normalize_type(param.group(2))
    return symbols


def normalize_type(typ: str) -> str:
    typ = typ.strip()
    typ = typ.split("=", 1)[0].strip()
    typ = typ.replace("@escaping ", "")
    typ = re.split(r"\s+", typ)[0]
    return typ.rstrip(",")


def line_number(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def line_has_marker(lines: list[str], line: int) -> bool:
    return 1 <= line <= len(lines) and bool(MARKER_RE.search(lines[line - 1]))


def find_matching_paren(text: str, open_index: int) -> int | None:
    depth = 0
    in_string = False
    escaped = False
    in_line_comment = False
    for index in range(open_index, len(text)):
        char = text[index]
        next_char = text[index + 1] if index + 1 < len(text) else ""
        if in_line_comment:
            if char == "\n":
                in_line_comment = False
            continue
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == "/" and next_char == "/":
            in_line_comment = True
            continue
        if char == '"':
            in_string = True
            continue
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return index
    return None


def first_argument(argument_text: str) -> str:
    text = argument_text.strip()
    depth = 0
    in_string = False
    escaped = False
    for index, char in enumerate(text):
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
            continue
        if char in "([{" :
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == "," and depth == 0:
            return text[:index].strip()
    return text


def expression_name(expression: str) -> str | None:
    expr = expression.strip()
    if not expr:
        return None
    expr = re.sub(r"\s+", " ", expr)
    if "(" in expr or "{" in expr or "[" in expr:
        return None
    if expr.startswith("."):
        return None
    parts = expr.split(".")
    if all(re.match(r"^[A-Za-z_][A-Za-z0-9_]*\??$", part) for part in parts):
        return parts[-1].rstrip("?")
    return None


def is_allowed_expression(expression: str, symbols: dict[str, str]) -> bool:
    expr = expression.strip()
    if not expr:
        return True
    allowed_prefixes = (
        '"',
        "LocalizedStringKey(",
        "LocalizedStringResource(",
        "String(localized:",
        "Text(verbatim:",
        "Text(",
        "Image(",
        "Label(",
        "localized(",
        "localizedVision(",
        "english(",
        "englishVision(",
        "AttributedString(",
    )
    if expr.startswith(allowed_prefixes):
        return True
    name = expression_name(expr)
    if name is None:
        return True
    typ = symbols.get(name)
    if typ in LOCALIZED_TYPES:
        return True
    return typ not in STRING_TYPES


def scan_file(path: Path) -> list[Violation]:
    text = path.read_text(encoding="utf-8")
    symbols = collect_symbols(text)
    lines = text.splitlines()
    violations: list[Violation] = []
    call_patterns = [
        ("Text", re.compile(r"\bText\s*\(")),
        ("Label", re.compile(r"\bLabel\s*\(")),
        ("Button", re.compile(r"\bButton\s*\(")),
        ("accessibilityLabel", re.compile(r"\.accessibilityLabel\s*\(")),
        ("accessibilityHint", re.compile(r"\.accessibilityHint\s*\(")),
        ("navigationTitle", re.compile(r"\.navigationTitle\s*\(")),
    ]
    for callee, pattern in call_patterns:
        for match in pattern.finditer(text):
            open_index = text.find("(", match.start())
            close_index = find_matching_paren(text, open_index)
            if close_index is None:
                continue
            start_line = line_number(text, match.start())
            if line_has_marker(lines, start_line):
                continue
            argument = first_argument(text[open_index + 1:close_index])
            if callee == "Label" and "systemImage:" in argument:
                argument = first_argument(argument)
            if not is_allowed_expression(argument, symbols):
                violations.append(Violation(path, start_line, re.sub(r"\s+", " ", argument), callee))
    return violations


def swift_files(roots: list[Path]) -> list[Path]:
    files: list[Path] = []
    for root in roots:
        if root.is_file() and root.suffix == ".swift":
            files.append(root)
        elif root.exists():
            files.extend(sorted(root.rglob("*.swift")))
    return [path for path in files if "Tests" not in path.parts]


def run_scan(roots: list[Path]) -> list[Violation]:
    violations: list[Violation] = []
    for path in swift_files(roots):
        violations.extend(scan_file(path))
    return violations


def self_test() -> None:
    violations = run_scan([SELF_TEST_FIXTURE])
    formatted = [violation.format(ROOT) for violation in violations]
    expected_fragment = "InvalidTextFixture.swift:12: Text(unmarked)"
    if len(violations) != 1 or expected_fragment not in formatted[0]:
        print("Apple text-source gate self-test failed.", file=sys.stderr)
        print("Expected exactly:", expected_fragment, file=sys.stderr)
        print("Actual:", file=sys.stderr)
        for item in formatted:
            print(f"- {item}", file=sys.stderr)
        raise SystemExit(1)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("roots", nargs="*", type=Path)
    args = parser.parse_args()

    if args.self_test:
        self_test()
        print("Apple text-source gate self-test passed.")
        return

    roots = args.roots or DEFAULT_SOURCE_ROOTS
    violations = run_scan(roots)
    if violations:
        print("Unlocalized SwiftUI plain-String text sources:", file=sys.stderr)
        for violation in violations:
            print(f"- {violation.format(ROOT)}", file=sys.stderr)
        raise SystemExit(1)
    print("Apple SwiftUI text sources are localized or explicitly marked.")


if __name__ == "__main__":
    main()
