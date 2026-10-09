#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/apps/apple/CanadianHam.xcodeproj"
CATALOG="$ROOT_DIR/apps/apple/CanadianHam/Resources/Localizable.xcstrings"
TMP_DIR="$(mktemp -d)"
CATALOG_HASH_BEFORE="$(shasum -a 256 "$CATALOG" | awk '{print $1}')"

assert_catalog_unchanged() {
  local phase="$1"
  local current_hash
  current_hash="$(shasum -a 256 "$CATALOG" | awk '{print $1}')"
  if [[ "$CATALOG_HASH_BEFORE" != "$current_hash" ]]; then
    echo "$phase modified $CATALOG; run the export intentionally and commit the catalogue changes." >&2
    exit 1
  fi
}

cleanup() {
  local status=$?
  if [[ -f "$CATALOG" ]]; then
    local current_hash
    current_hash="$(shasum -a 256 "$CATALOG" | awk '{print $1}')"
    if [[ "$CATALOG_HASH_BEFORE" != "$current_hash" ]]; then
      echo "Apple localization check modified $CATALOG; run the export intentionally and commit the catalogue changes." >&2
      status=1
    fi
  fi
  rm -rf "$TMP_DIR"
  exit "$status"
}
trap cleanup EXIT

node --no-warnings "$ROOT_DIR/scripts/check-apple-text-sources.ts" --self-test
node --no-warnings "$ROOT_DIR/scripts/check-apple-text-sources.ts"
assert_catalog_unchanged "Apple text-source checks"

DERIVED_DATA="$TMP_DIR/DerivedData"
LOCALIZATION_DIR="$TMP_DIR/Localization"

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xbuild -exportLocalizations \
  -project "$PROJECT" \
  -scheme CanadianHam \
  -configuration DebugCloudKit \
  -derivedDataPath "$DERIVED_DATA" \
  -localizationPath "$LOCALIZATION_DIR" \
  -exportLanguage fr \
  CODE_SIGNING_ALLOWED=NO

assert_catalog_unchanged "xbuild -exportLocalizations"

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xbuild -project "$PROJECT" \
  -scheme CanadianHamTV \
  -destination 'generic/platform=tvOS Simulator' \
  -derivedDataPath "$DERIVED_DATA" \
  build CODE_SIGNING_ALLOWED=NO
assert_catalog_unchanged "CanadianHamTV localization build"

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xbuild -project "$PROJECT" \
  -scheme CanadianHamVision \
  -destination 'generic/platform=visionOS Simulator' \
  -derivedDataPath "$DERIVED_DATA" \
  build CODE_SIGNING_ALLOWED=NO
assert_catalog_unchanged "CanadianHamVision localization build"

XLIFF="$LOCALIZATION_DIR/fr.xcloc/Localized Contents/fr.xliff"

python3 - "$XLIFF" "$CATALOG" "$ROOT_DIR" "$DERIVED_DATA" <<'PY'
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

xliff_path = Path(sys.argv[1])
catalog_path = Path(sys.argv[2])
root_dir = Path(sys.argv[3]).resolve()
derived_data = Path(sys.argv[4]).resolve()

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
gated_icloud_keys = {
    "iCloud Sync",
    "Sync learning progress with iCloud",
    "Off by default. When enabled, learning progress can sync through your private iCloud database after restart; preferences stay local on this device.",
    "Off by default. When enabled, learning progress can sync through your private iCloud database after restart; preferences stay local on this Mac.",
    "iCloud Sync will turn on after you restart the app.",
    "iCloud Sync will turn off after you restart the app.",
    "No accounts, analytics, telemetry, third-party SDKs, or developer-operated servers. iCloud Sync is optional and off until you turn it on; import and export use local files you choose.",
    "This gated Apple app includes bundled content, no accounts, analytics, telemetry, ads, remote config, third-party SDKs, or developer-operated servers. iCloud Sync is optional and off until you turn it on; import and export use local files you choose.",
}
compiled_keys = set()
if derived_data.exists():
    for stringsdata_path in derived_data.glob("Build/Intermediates.noindex/*.build/**/*.stringsdata"):
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

stale_by_compiler = sorted(catalog_keys - compiled_keys - gated_icloud_keys)
if stale_by_compiler:
    print("Apple localization catalogue keys missing from compiler stringsdata:", file=sys.stderr)
    for key in stale_by_compiler:
        print(f"- {key}", file=sys.stderr)
    sys.exit(1)

stale_by_export = sorted(catalog_keys - exported_catalog_keys - gated_icloud_keys)
if stale_by_export:
    print("Apple localization catalogue keys missing from exported XLIFF:", file=sys.stderr)
    for key in stale_by_export:
        print(f"- {key}", file=sys.stderr)
    sys.exit(1)

if missing:
    print("Missing French localization targets:", file=sys.stderr)
    for item in missing:
        print(f"- {item}", file=sys.stderr)
    sys.exit(1)

print("Apple French localization export is complete.")
PY
assert_catalog_unchanged "Apple localization stale check"
