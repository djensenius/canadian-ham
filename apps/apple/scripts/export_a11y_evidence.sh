#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
apple_dir="$(cd "$script_dir/.." && pwd)"
output_dir="$apple_dir/docs/a11y-evidence"

if [[ $# -gt 0 ]]; then
  xcresult_path="$1"
else
  xcresult_path="$(python3 - <<'PY'
from pathlib import Path
root = Path.home() / "Library" / "Developer" / "Xcode" / "DerivedData"
paths = [path for path in root.glob("*/Logs/Test/*.xcresult") if path.is_dir()]
if paths:
    print(max(paths, key=lambda path: path.stat().st_mtime))
PY
)"
fi

if [[ -z "${xcresult_path:-}" || ! -d "$xcresult_path" ]]; then
  echo "No .xcresult bundle found. Pass one explicitly or run the UI tests first." >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

rm -rf "$output_dir"
mkdir -p "$output_dir"

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
  xcrun xcresulttool export attachments \
  --path "$xcresult_path" \
  --output-path "$tmp_dir/exported" >/dev/null

python3 - "$tmp_dir/exported" "$output_dir" <<'PY'
from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

exported = Path(sys.argv[1])
out = Path(sys.argv[2])
manifest_path = exported / "manifest.json"
allowed_name = re.compile(r"(accessibility-audit|audit-position-log)")
allowed_suffixes = {".png", ".txt"}


def safe_name(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "-", name).strip("-")


def candidate_paths(value):
    if isinstance(value, dict):
        for key in ("filename", "fileName", "path", "url", "payloadRef", "payloadRefId", "id"):
            item = value.get(key)
            if isinstance(item, str):
                yield item
        for item in value.values():
            yield from candidate_paths(item)
    elif isinstance(value, list):
        for item in value:
            yield from candidate_paths(item)

copied = 0
if manifest_path.exists():
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    containers = manifest if isinstance(manifest, list) else [manifest] if isinstance(manifest, dict) else []
    entries = []
    for container in containers:
        if isinstance(container, dict) and isinstance(container.get("attachments"), list):
            entries.extend(container["attachments"])
        elif isinstance(container, dict):
            entries.append(container)
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        attachment_name = str(
            entry.get("suggestedHumanReadableName")
            or entry.get("name")
            or entry.get("attachmentName")
            or entry.get("filename")
            or ""
        )
        if not allowed_name.search(attachment_name):
            continue
        source = None
        exported_file_name = entry.get("exportedFileName")
        if isinstance(exported_file_name, str):
            possible = exported / exported_file_name
            if possible.is_file():
                source = possible
        if source is None:
            for candidate in candidate_paths(entry):
                candidate_path = Path(candidate)
                possible = candidate_path if candidate_path.is_absolute() else exported / candidate_path
                if possible.is_file():
                    source = possible
                    break
        if source is None:
            continue
        suffix = source.suffix or Path(attachment_name).suffix or (".png" if "screenshot" in attachment_name.lower() or "audit" in attachment_name.lower() else ".txt")
        destination = out / safe_name(attachment_name + suffix if not attachment_name.endswith(suffix) else attachment_name)
        shutil.copy2(source, destination)
        copied += 1

# xcresulttool versions that already export attachment names are handled here;
# this also catches files the manifest parser did not understand.
for source in exported.rglob("*"):
    if not source.is_file() or source.name == "manifest.json":
        continue
    if source.suffix not in allowed_suffixes:
        continue
    if not allowed_name.search(source.name):
        continue
    destination = out / safe_name(source.name)
    if not destination.exists():
        shutil.copy2(source, destination)
        copied += 1

if copied == 0:
    raise SystemExit("No accessibility-audit attachments were exported from the result bundle")
print(f"Exported {copied} accessibility evidence attachment(s) to {out}")
PY

printf 'Source xcresult: %s\n' "$xcresult_path" > "$output_dir/xcresult-source.txt"
