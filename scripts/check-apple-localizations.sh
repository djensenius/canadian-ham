#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/apps/apple/CanadianHam.xcodeproj"
CATALOG="$ROOT_DIR/apps/apple/CanadianHam/Resources/Localizable.xcstrings"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xbuild -exportLocalizations \
  -project "$PROJECT" \
  -localizationPath "$TMP_DIR" \
  -exportLanguage fr

XLIFF="$TMP_DIR/fr.xcloc/Localized Contents/fr.xliff"

python3 - "$XLIFF" "$CATALOG" <<'PY'
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

xliff_path = Path(sys.argv[1])
catalog_path = Path(sys.argv[2])

catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
stale = sorted(
    key for key, entry in catalog.get("strings", {}).items()
    if entry.get("extractionState") == "stale"
)
if stale:
    print("Stale Apple localization catalogue keys:", file=sys.stderr)
    for key in stale:
        print(f"- {key}", file=sys.stderr)
    sys.exit(1)

do_not_translate = {
    key for key, entry in catalog.get("strings", {}).items()
    if entry.get("shouldTranslate") is False
}

ns = {"x": "urn:oasis:names:tc:xliff:document:1.2"}
root = ET.parse(xliff_path).getroot()
missing = []
for file_node in root.findall("x:file", ns):
    original = file_node.get("original", "")
    for unit in file_node.findall(".//x:trans-unit", ns):
        unit_id = unit.get("id", "")
        if original.endswith("Localizable.xcstrings") and unit_id in do_not_translate:
            continue
        target = unit.find("x:target", ns)
        target_text = "" if target is None else "".join(target.itertext()).strip()
        if not target_text:
            source = unit.findtext("x:source", default="", namespaces=ns)
            missing.append(f"{original}: {unit_id} -> {source}")

if missing:
    print("Missing French localization targets:", file=sys.stderr)
    for item in missing:
        print(f"- {item}", file=sys.stderr)
    sys.exit(1)

print("Apple French localization export is complete.")
PY
