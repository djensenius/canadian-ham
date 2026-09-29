#!/usr/bin/env python3
"""Measure contrast for XCTest accessibility-audit findings.

The script intentionally uses only the Python standard library plus the macOS
`sips` command to convert PNG screenshots to BMP files that stdlib code can
sample. Raw finding files must include XCTest element frames in points and a
screen frame line; the UI tests export both to apps/apple/docs/a11y-evidence.
"""

from __future__ import annotations

import argparse
import collections
import math
import os
import re
import struct
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

CONTRAST_AUDIT_RAW_VALUE = "1"
FRAME_RE = re.compile(
    r"x: (?P<x>-?\d+(?:\.\d+)?), y: (?P<y>-?\d+(?:\.\d+)?), "
    r"width: (?P<width>\d+(?:\.\d+)?), height: (?P<height>\d+(?:\.\d+)?)"
)
AUDIT_TYPE_RE = re.compile(r"auditType: .*rawValue: (?P<raw>\d+)")


@dataclass(frozen=True)
class Rect:
    x: float
    y: float
    width: float
    height: float


@dataclass(frozen=True)
class Finding:
    screen: str
    issue: str
    audit_type_raw: str
    identifier: str
    label: str
    element_type: str
    frame: Rect
    compact_description: str
    screen_frame: Rect
    raw_file: Path
    screenshot_file: Path


@dataclass(frozen=True)
class BMPImage:
    width: int
    height: int
    pixels: bytes
    row_stride: int
    bytes_per_pixel: int
    top_down: bool

    def rgb_at(self, x: int, y: int) -> tuple[int, int, int]:
        x = max(0, min(self.width - 1, x))
        y = max(0, min(self.height - 1, y))
        storage_y = y if self.top_down else self.height - 1 - y
        offset = storage_y * self.row_stride + x * self.bytes_per_pixel
        blue = self.pixels[offset]
        green = self.pixels[offset + 1]
        red = self.pixels[offset + 2]
        return red, green, blue


def parse_rect(text: str) -> Rect:
    match = FRAME_RE.search(text)
    if not match:
        raise ValueError(f"Could not parse frame: {text}")
    return Rect(
        x=float(match.group("x")),
        y=float(match.group("y")),
        width=float(match.group("width")),
        height=float(match.group("height")),
    )


def parse_findings(raw_file: Path) -> list[Finding]:
    text = raw_file.read_text(encoding="utf-8")
    screen_match = re.search(r"^Screen: (?P<screen>.+)$", text, re.MULTILINE)
    screen = screen_match.group("screen") if screen_match else raw_file.name.removesuffix("-raw-accessibility-audit-findings.txt")
    screen_frame_match = re.search(r"^Screen frame: (?P<frame>.+)$", text, re.MULTILINE)
    if not screen_frame_match:
        raise ValueError(f"Missing Screen frame line in {raw_file}")
    screen_frame = parse_rect(screen_frame_match.group("frame"))
    screenshot_file = raw_file.with_name(raw_file.name.replace("-raw-accessibility-audit-findings.txt", "-accessibility-audit.png"))

    findings: list[Finding] = []
    for block in re.split(r"\n\nIssue ", text):
        if "auditType:" not in block:
            continue
        if not block.startswith("Issue "):
            block = "Issue " + block
        issue_heading = block.splitlines()[0].rstrip(":")
        audit_match = AUDIT_TYPE_RE.search(block)
        if not audit_match:
            continue
        audit_type_raw = audit_match.group("raw")
        values: dict[str, str] = {}
        for line in block.splitlines()[1:]:
            if ": " in line:
                key, value = line.split(": ", 1)
                values[key] = value
        if audit_type_raw != CONTRAST_AUDIT_RAW_VALUE:
            continue
        findings.append(
            Finding(
                screen=screen,
                issue=issue_heading,
                audit_type_raw=audit_type_raw,
                identifier=values.get("element.identifier", ""),
                label=values.get("element.label", ""),
                element_type=values.get("element.elementType", ""),
                frame=parse_rect(values.get("element.frame", "")),
                compact_description=values.get("compactDescription", ""),
                screen_frame=screen_frame,
                raw_file=raw_file,
                screenshot_file=screenshot_file,
            )
        )
    return findings


def convert_png_to_bmp(png_file: Path, bmp_file: Path) -> None:
    subprocess.run(
        ["sips", "-s", "format", "bmp", str(png_file), "--out", str(bmp_file)],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def read_bmp(path: Path) -> BMPImage:
    data = path.read_bytes()
    if data[:2] != b"BM":
        raise ValueError(f"Not a BMP file: {path}")
    pixel_offset = struct.unpack_from("<I", data, 10)[0]
    dib_header_size = struct.unpack_from("<I", data, 14)[0]
    if dib_header_size < 40:
        raise ValueError(f"Unsupported BMP DIB header in {path}")
    width = struct.unpack_from("<i", data, 18)[0]
    raw_height = struct.unpack_from("<i", data, 22)[0]
    planes = struct.unpack_from("<H", data, 26)[0]
    bits_per_pixel = struct.unpack_from("<H", data, 28)[0]
    compression = struct.unpack_from("<I", data, 30)[0]
    if planes != 1 or compression != 0 or bits_per_pixel not in (24, 32):
        raise ValueError(f"Unsupported BMP format in {path}: bpp={bits_per_pixel}, compression={compression}")
    height = abs(raw_height)
    top_down = raw_height < 0
    bytes_per_pixel = bits_per_pixel // 8
    row_stride = ((width * bytes_per_pixel + 3) // 4) * 4
    pixels = data[pixel_offset : pixel_offset + row_stride * height]
    return BMPImage(width=width, height=height, pixels=pixels, row_stride=row_stride, bytes_per_pixel=bytes_per_pixel, top_down=top_down)


def srgb_to_linear(component: int) -> float:
    value = component / 255.0
    if value <= 0.04045:
        return value / 12.92
    return ((value + 0.055) / 1.055) ** 2.4


def relative_luminance(rgb: tuple[int, int, int]) -> float:
    red, green, blue = (srgb_to_linear(component) for component in rgb)
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue


def contrast_ratio(color_a: tuple[int, int, int], color_b: tuple[int, int, int]) -> float:
    lum_a = relative_luminance(color_a)
    lum_b = relative_luminance(color_b)
    lighter = max(lum_a, lum_b)
    darker = min(lum_a, lum_b)
    return (lighter + 0.05) / (darker + 0.05)


def quantize(rgb: tuple[int, int, int], step: int = 8) -> tuple[int, int, int]:
    return tuple(min(255, int(round(channel / step) * step)) for channel in rgb)  # type: ignore[return-value]


def average(colors: Iterable[tuple[int, int, int]]) -> tuple[int, int, int]:
    colors = list(colors)
    if not colors:
        return (0, 0, 0)
    return tuple(round(sum(color[index] for color in colors) / len(colors)) for index in range(3))  # type: ignore[return-value]


def sample_contrast(image: BMPImage, finding: Finding, inset_points: float = 1.0) -> tuple[float, tuple[int, int, int], tuple[int, int, int], int]:
    scale_x = image.width / finding.screen_frame.width
    scale_y = image.height / finding.screen_frame.height
    min_x = math.floor((finding.frame.x + inset_points) * scale_x)
    max_x = math.ceil((finding.frame.x + finding.frame.width - inset_points) * scale_x)
    min_y = math.floor((finding.frame.y + inset_points) * scale_y)
    max_y = math.ceil((finding.frame.y + finding.frame.height - inset_points) * scale_y)
    min_x = max(0, min(image.width - 1, min_x))
    max_x = max(min_x + 1, min(image.width, max_x))
    min_y = max(0, min(image.height - 1, min_y))
    max_y = max(min_y + 1, min(image.height, max_y))

    counts: collections.Counter[tuple[int, int, int]] = collections.Counter()
    sample_count = 0
    for y in range(min_y, max_y):
        for x in range(min_x, max_x):
            rgb = image.rgb_at(x, y)
            counts[quantize(rgb)] += 1
            sample_count += 1

    if not counts:
        return 1.0, (0, 0, 0), (0, 0, 0), 0

    # Use the darkest and lightest populated clusters in the element frame.
    clusters = list(counts.items())
    darkest_cluster = min(clusters, key=lambda item: relative_luminance(item[0]))[0]
    lightest_cluster = max(clusters, key=lambda item: relative_luminance(item[0]))[0]

    darkest_colors = [color for color in counts.elements() if color == darkest_cluster]
    lightest_colors = [color for color in counts.elements() if color == lightest_cluster]
    darkest = average(darkest_colors) or darkest_cluster
    lightest = average(lightest_colors) or lightest_cluster
    return contrast_ratio(darkest, lightest), darkest, lightest, sample_count


def measure(evidence_dir: Path) -> str:
    raw_files = sorted(evidence_dir.glob("*-raw-accessibility-audit-findings.txt"))
    all_findings: list[Finding] = []
    for raw_file in raw_files:
        all_findings.extend(parse_findings(raw_file))

    if not all_findings:
        return "No contrast findings found in raw accessibility-audit files."

    by_screenshot: dict[Path, list[Finding]] = collections.defaultdict(list)
    for finding in all_findings:
        by_screenshot[finding.screenshot_file].append(finding)

    rows = [
        "| Screen | Issue | Identifier | Label | Frame (pt) | Measured ratio | Sampled colours | Samples |",
        "|---|---|---|---|---|---:|---|---:|",
    ]
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)
        for screenshot, findings in sorted(by_screenshot.items()):
            bmp_path = tmp_path / f"{screenshot.stem}.bmp"
            convert_png_to_bmp(screenshot, bmp_path)
            image = read_bmp(bmp_path)
            for finding in findings:
                ratio, dark, light, samples = sample_contrast(image, finding)
                frame = f"x={finding.frame.x:.1f}, y={finding.frame.y:.1f}, w={finding.frame.width:.1f}, h={finding.frame.height:.1f}"
                colors = f"#{dark[0]:02X}{dark[1]:02X}{dark[2]:02X} / #{light[0]:02X}{light[1]:02X}{light[2]:02X}"
                label = finding.label.replace("|", "\\|")
                identifier = finding.identifier or "—"
                rows.append(
                    f"| {finding.screen} | {finding.issue} | {identifier} | {label} | {frame} | {ratio:.2f}:1 | {colors} | {samples} |"
                )
    return "\n".join(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "evidence_dir",
        nargs="?",
        default=Path(__file__).resolve().parents[1] / "docs" / "a11y-evidence",
        type=Path,
        help="Directory containing exported PNG screenshots and raw accessibility-audit text files.",
    )
    args = parser.parse_args()
    print(measure(args.evidence_dir))


if __name__ == "__main__":
    main()
