#!/usr/bin/env python3
"""Validate checked-in app icon metadata references existing files."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
APPICONSET = ROOT / "apps/apple/CanadianHam/Resources/Assets.xcassets/AppIcon.appiconset"
ICON_COMPOSER = ROOT / "apps/apple/CanadianHam/Resources/AppIcon.icon"


def main() -> None:
    contents_path = APPICONSET / "Contents.json"
    contents = json.loads(contents_path.read_text(encoding="utf-8"))
    missing = [image["filename"] for image in contents["images"] if "filename" in image and not (APPICONSET / image["filename"]).is_file()]
    if missing:
        raise SystemExit(f"Missing AppIcon.appiconset files: {', '.join(missing)}")

    icon_path = ICON_COMPOSER / "icon.json"
    icon = json.loads(icon_path.read_text(encoding="utf-8"))
    missing_icon_assets: list[str] = []
    for group in icon.get("groups", []):
        for layer in group.get("layers", []):
            image_name = layer.get("image-name")
            if isinstance(image_name, str) and not (ICON_COMPOSER / "Assets" / image_name).is_file():
                missing_icon_assets.append(image_name)
    if missing_icon_assets:
        raise SystemExit(f"Missing AppIcon.icon assets: {', '.join(missing_icon_assets)}")

    print("App icon metadata references existing files.")


if __name__ == "__main__":
    main()
