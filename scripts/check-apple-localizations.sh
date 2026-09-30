#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/apps/apple/CanadianHam.xcodeproj"
CATALOG="$ROOT_DIR/apps/apple/CanadianHam/Resources/Localizable.xcstrings"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

python3 "$ROOT_DIR/scripts/check-apple-text-sources.py" --self-test
python3 "$ROOT_DIR/scripts/check-apple-text-sources.py"

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xbuild -exportLocalizations \
  -project "$PROJECT" \
  -localizationPath "$TMP_DIR" \
  -exportLanguage fr

XLIFF="$TMP_DIR/fr.xcloc/Localized Contents/fr.xliff"

python3 - "$XLIFF" "$CATALOG" "$ROOT_DIR" <<'PY'
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

xliff_path = Path(sys.argv[1])
catalog_path = Path(sys.argv[2])
root_dir = Path(sys.argv[3]).resolve()

catalog = json.loads(catalog_path.read_text(encoding="utf-8"))

do_not_translate = {
    key for key, entry in catalog.get("strings", {}).items()
    if entry.get("shouldTranslate") is False
}

ns = {"x": "urn:oasis:names:tc:xliff:document:1.2"}
root = ET.parse(xliff_path).getroot()
missing = []
exported_catalog_keys = set()
for file_node in root.findall("x:file", ns):
    original = file_node.get("original", "")
    is_catalog = original.endswith("Localizable.xcstrings")
    for unit in file_node.findall(".//x:trans-unit", ns):
        unit_id = unit.get("id", "")
        if is_catalog:
            exported_catalog_keys.add(unit_id.split("|==|", 1)[0])
        if is_catalog and unit_id in do_not_translate:
            continue
        target = unit.find("x:target", ns)
        target_text = "" if target is None else "".join(target.itertext()).strip()
        if not target_text:
            source = unit.findtext("x:source", default="", namespaces=ns)
            missing.append(f"{original}: {unit_id} -> {source}")

catalog_keys = set(catalog.get("strings", {}).keys())
compiled_keys = set()
derived_data = Path.home() / "Library/Developer/Xcode/DerivedData"
if derived_data.exists():
    for stringsdata_path in derived_data.glob("CanadianHam-*/Build/Intermediates.noindex/CanadianHam.build/**/*.stringsdata"):
        try:
            stringsdata = json.loads(stringsdata_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        source = stringsdata.get("source", "")
        if not source.startswith(str(root_dir / "apps/apple")):
            continue
        for entry in stringsdata.get("tables", {}).get("Localizable", []):
            key = entry.get("key") if isinstance(entry, dict) else None
            if key:
                compiled_keys.add(key)

if not compiled_keys:
    print("No compiler stringsdata keys found for Apple localization catalogue stale check.", file=sys.stderr)
    sys.exit(1)

stale_by_compiler = sorted(catalog_keys - compiled_keys)
if stale_by_compiler:
    print("Apple localization catalogue keys missing from compiler stringsdata:", file=sys.stderr)
    for key in stale_by_compiler:
        print(f"- {key}", file=sys.stderr)
    sys.exit(1)

stale_by_export = sorted(catalog_keys - exported_catalog_keys)
if stale_by_export:
    print("Apple localization catalogue keys missing from exported XLIFF:", file=sys.stderr)
    for key in stale_by_export:
        print(f"- {key}", file=sys.stderr)
    sys.exit(1)

removed_extraction_state = False
for entry in catalog.get("strings", {}).values():
    if entry.pop("extractionState", None) is not None:
        removed_extraction_state = True
if removed_extraction_state:
    text = json.dumps(catalog, ensure_ascii=False, indent=2).replace('": ', '" : ')
    catalog_path.write_text(text + "\n", encoding="utf-8")

if missing:
    print("Missing French localization targets:", file=sys.stderr)
    for item in missing:
        print(f"- {item}", file=sys.stderr)
    sys.exit(1)

print("Apple French localization export is complete.")
PY
