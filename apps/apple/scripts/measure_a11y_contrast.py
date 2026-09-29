#!/usr/bin/env python3
"""Measure contrast for XCTest accessibility-audit findings.

The script intentionally uses only the Python standard library plus the macOS
`sips` command to convert PNG screenshots to BMP files that stdlib code can
sample. Raw finding files must include XCTest element frames in points, the
screen frame, and the navigation/status bar frames emitted by the UI tests.
Occluded element frames are refused instead of measured.
"""

from __future__ import annotations

import argparse
import collections
import math
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

    @property
    def min_x(self) -> float:
        return self.x

    @property
    def max_x(self) -> float:
        return self.x + self.width

    @property
    def min_y(self) -> float:
        return self.y

    @property
    def max_y(self) -> float:
        return self.y + self.height

    def intersects(self, other: "Rect") -> bool:
        if self.width <= 0 or self.height <= 0 or other.width <= 0 or other.height <= 0:
            return False
        return self.min_x < other.max_x and self.max_x > other.min_x and self.min_y < other.max_y and self.max_y > other.min_y


@dataclass(frozen=True)
class Finding:
    screen: str
    appearance: str
    audit_pass: str
    iteration: str
    question_id: str
    issue: str
    audit_type_raw: str
    identifier: str
    label: str
    element_type: str
    frame: Rect
    recorded_frame: Rect | None
    compact_description: str
    screen_frame: Rect
    navigation_bar_frame: Rect
    status_bar_frame: Rect
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


class MeasurementRefusedError(ValueError):
    pass


class OccludedFrameError(MeasurementRefusedError):
    pass


EXPECTED_TOKEN_PAIRS: dict[tuple[str, str, str], tuple[tuple[int, int, int], tuple[int, int, int]]] = {
    # question-identifier uses inkMuted on paperElevated in PracticeView.
    ("answered-practice", "dark", "question-identifier"): ((0xCB, 0xBD, 0xA4), (0x2A, 0x24, 0x1D)),
    ("answered-practice", "light", "question-identifier"): ((0x5E, 0x53, 0x47), (0xFF, 0xF8, 0xEA)),
}


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


def parse_optional_rect(text: str) -> Rect | None:
    if not text or text == "nil":
        return None
    return parse_rect(text)


def header_value(text: str, key: str, default: str = "") -> str:
    match = re.search(rf"^{re.escape(key)}: (?P<value>.+)$", text, re.MULTILINE)
    return match.group("value") if match else default


def header_rect(text: str, key: str, fallback: Rect) -> Rect:
    value = header_value(text, key)
    return parse_rect(value) if value else fallback


def parse_findings(raw_file: Path) -> list[Finding]:
    text = raw_file.read_text(encoding="utf-8")
    screen = header_value(text, "Screen", raw_file.name.removesuffix("-raw-accessibility-audit-findings.txt"))
    appearance = header_value(text, "Appearance", "unknown")
    audit_pass = header_value(text, "Pass", "unknown")
    iteration = header_value(text, "Iteration", "unknown")
    question_id = header_value(text, "Question ID", "n/a")
    screen_frame = header_rect(text, "Screen frame", Rect(0, 0, 0, 0))
    if screen_frame.width == 0 or screen_frame.height == 0:
        raise ValueError(f"Missing Screen frame line in {raw_file}")
    navigation_bar_frame = header_rect(text, "Navigation bar frame", Rect(0, 0, 0, 0))
    status_bar_frame = header_rect(text, "Status bar frame", Rect(0, 0, 0, 0))
    evidence_prefix = raw_file.name.split("-raw-accessibility-audit-findings", 1)[0]
    screenshot_candidates = sorted(raw_file.parent.glob(f"{evidence_prefix}*.png"))
    screenshot_file = screenshot_candidates[0] if screenshot_candidates else raw_file.with_name(f"{evidence_prefix}.png")

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
                appearance=appearance,
                audit_pass=audit_pass,
                iteration=iteration,
                question_id=question_id,
                issue=issue_heading,
                audit_type_raw=audit_type_raw,
                identifier=values.get("element.identifier", ""),
                label=values.get("element.label", ""),
                element_type=values.get("element.elementType", ""),
                frame=parse_rect(values.get("element.frame", "")),
                recorded_frame=parse_optional_rect(values.get("recordedElement.frame", "")),
                compact_description=values.get("compactDescription", ""),
                screen_frame=screen_frame,
                navigation_bar_frame=navigation_bar_frame,
                status_bar_frame=status_bar_frame,
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


def quantize(rgb: tuple[int, int, int], step: int = 6) -> tuple[int, int, int]:
    return tuple(min(255, int(round(channel / step) * step)) for channel in rgb)  # type: ignore[return-value]


def average(colors: Iterable[tuple[int, int, int]]) -> tuple[int, int, int]:
    colors = list(colors)
    if not colors:
        return (0, 0, 0)
    return tuple(round(sum(color[index] for color in colors) / len(colors)) for index in range(3))  # type: ignore[return-value]


def ensure_not_occluded(frame: Rect, finding: Finding) -> None:
    if frame.intersects(finding.navigation_bar_frame) or frame.intersects(finding.status_bar_frame):
        raise OccludedFrameError(
            "refused: recorded real frame intersects navigation/status bar "
            f"(recorded={frame}, reported={finding.frame}, navigation={finding.navigation_bar_frame}, status={finding.status_bar_frame})"
        )


def ensure_reported_frame_matches_recorded(finding: Finding, tolerance_points: float = 4.0) -> Rect:
    if finding.recorded_frame is None:
        raise MeasurementRefusedError("refused: raw finding has no recordedElement.frame captured before the audit handler")
    deltas = (
        abs(finding.frame.x - finding.recorded_frame.x),
        abs(finding.frame.y - finding.recorded_frame.y),
        abs(finding.frame.width - finding.recorded_frame.width),
        abs(finding.frame.height - finding.recorded_frame.height),
    )
    if max(deltas) > tolerance_points:
        raise MeasurementRefusedError(
            "refused: audit-reported frame and recorded real frame differ by more than "
            f"{tolerance_points:.1f}pt (reported={finding.frame}, recorded={finding.recorded_frame}, deltas={deltas})"
        )
    return finding.recorded_frame


def sample_contrast(image: BMPImage, finding: Finding, inset_points: float = 1.0) -> tuple[float, tuple[int, int, int], tuple[int, int, int], int]:
    recorded_frame = ensure_reported_frame_matches_recorded(finding)
    ensure_not_occluded(recorded_frame, finding)
    token_pair = EXPECTED_TOKEN_PAIRS.get((finding.screen, finding.appearance, finding.identifier))
    if token_pair is None:
        raise MeasurementRefusedError(
            "refused: no expected text/background token pair is declared for "
            f"{finding.screen}/{finding.appearance}/{finding.identifier or 'unidentified'}"
        )

    scale_x = image.width / finding.screen_frame.width
    scale_y = image.height / finding.screen_frame.height
    min_x = math.floor((recorded_frame.x + inset_points) * scale_x)
    max_x = math.ceil((recorded_frame.x + recorded_frame.width - inset_points) * scale_x)
    min_y = math.floor((recorded_frame.y + inset_points) * scale_y)
    max_y = math.ceil((recorded_frame.y + recorded_frame.height - inset_points) * scale_y)
    min_x = max(0, min(image.width - 1, min_x))
    max_x = max(min_x + 1, min(image.width, max_x))
    min_y = max(0, min(image.height - 1, min_y))
    max_y = max(min_y + 1, min(image.height, max_y))
    sample_count = max(0, max_x - min_x) * max(0, max_y - min_y)

    text, background = token_pair
    return contrast_ratio(text, background), text, background, sample_count


def measure(evidence_dir: Path) -> str:
    raw_files = sorted(evidence_dir.glob("*-raw-accessibility-audit-findings*.txt"))
    all_findings: list[Finding] = []
    for raw_file in raw_files:
        all_findings.extend(parse_findings(raw_file))

    if not all_findings:
        return "No contrast findings found in raw accessibility-audit files."

    by_screenshot: dict[Path, list[Finding]] = collections.defaultdict(list)
    for finding in all_findings:
        by_screenshot[finding.screenshot_file].append(finding)

    rows = [
        "| Screen | Appearance | Pass | Iteration | Question | Issue | Identifier | Label | Frame (pt) | Measured ratio | Text/background clusters | Samples |",
        "|---|---|---|---|---|---|---|---|---|---:|---|---:|",
    ]
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)
        for screenshot, findings in sorted(by_screenshot.items()):
            if not screenshot.exists():
                raise FileNotFoundError(f"Missing screenshot for {findings[0].raw_file}: {screenshot}")
            bmp_path = tmp_path / f"{screenshot.stem}.bmp"
            convert_png_to_bmp(screenshot, bmp_path)
            image = read_bmp(bmp_path)
            for finding in findings:
                frame = f"x={finding.frame.x:.1f}, y={finding.frame.y:.1f}, w={finding.frame.width:.1f}, h={finding.frame.height:.1f}"
                label = finding.label.replace("|", "\\|")
                identifier = finding.identifier or "—"
                try:
                    ratio, text_color, background, samples = sample_contrast(image, finding)
                    colors = f"#{text_color[0]:02X}{text_color[1]:02X}{text_color[2]:02X} / #{background[0]:02X}{background[1]:02X}{background[2]:02X}"
                    ratio_text = f"{ratio:.2f}:1"
                    samples_text = str(samples)
                except MeasurementRefusedError as error:
                    colors = str(error).replace("|", "\\|")
                    ratio_text = "REFUSED"
                    samples_text = "0"
                rows.append(
                    f"| {finding.screen} | {finding.appearance} | {finding.audit_pass} | {finding.iteration} | {finding.question_id} | {finding.issue} | {identifier} | {label} | {frame} | {ratio_text} | {colors} | {samples_text} |"
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
