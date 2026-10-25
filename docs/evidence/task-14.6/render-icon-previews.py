#!/usr/bin/env python3
"""Render TASK-14.6's circular before/after watch-icon review (ImageMagick 7)."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
SOURCES = {
    "before": ROOT / "design/app-icon/exports/app-icon-1024.png",
    "after": ROOT / "apps/apple/Platforms/watchOS/Resources/Assets.xcassets/AppIcon.appiconset/watch-icon-1024.png",
}
SIZES = (1024, 196, 88, 48)


def run(*args: str | Path) -> None:
    subprocess.run(["magick", *map(str, args)], check=True)


for stage, source in SOURCES.items():
    for size in SIZES:
        # Mask at the source resolution, then downsample colour and alpha together.
        # Transparency is for these review previews only; the shipped icon is RGB.
        run(source, "(", "-size", "1024x1024", "xc:black", "-fill", "white",
            "-draw", "circle 511.5,511.5 511.5,0", ")", "-alpha", "off",
            "-compose", "CopyOpacity", "-composite", "-resize", f"{size}x{size}",
            "-strip", f"PNG32:{OUT / f'icon-{stage}-circle-{size}.png'}")
    run("montage", *(OUT / f"icon-{stage}-circle-{size}.png" for size in SIZES[1:]),
        "-background", "#303030", "-geometry", "+16+16", "-tile", "3x1",
        OUT / f"icon-{stage}-small.png")
