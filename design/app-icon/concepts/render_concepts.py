#!/usr/bin/env python3
"""Deterministic sumi-e app icon concept renderer.

Round 3 keeps the filled sumi-e construction from round 2 and focuses the set on
hex-beam antennas. Each brush mark is a single opaque ink body built by
offsetting a centreline with an explicit pressure profile, then cutting hihaku
dry-brush gaps through the lift-off tail.
"""
from __future__ import annotations

import argparse
import math
import random
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SIZE = 1024
MAGICK = Path("/opt/homebrew/bin/magick") if Path("/opt/homebrew/bin/magick").exists() else None
if MAGICK is None:
    found = shutil.which("magick") or shutil.which("convert")
    MAGICK = Path(found) if found else None
FONT = "/System/Library/Fonts/Helvetica.ttc"
INK = "#15120F"
INK_SOFT = "rgba(21,18,15,0.18)"
WASH = "rgba(48,44,38,0.14)"
BG_INNER = (255, 247, 232)  # #FFF7E8 from src/background.svg
BG_OUTER = (246, 238, 220)  # #F6EEDC from src/background.svg

CONCEPTS = [
    ("01-hex-top", "Top-down hex beam: straight sumi-e spreaders, a closed hexagon perimeter, pressed hub, and two light zigzag wire elements."),
    ("02-hex-top-enso", "Top-down hex beam framed by a thinner open ensō circle with a dry-brush gap."),
    ("03-hex-top-minimal", "Minimal top-down hex beam: bold hexagon perimeter, six straight spreaders, and a pressed centre hub only."),
    ("04-hex-side", "Side-view hex beam: mast, hub, six thin umbrella-like spreaders, and a flattened hexagon wire outline."),
]

CLOSEUP_CROPS = {
    "01-hex-top": (250, 250),
    "02-hex-top-enso": (244, 244),
    "03-hex-top-minimal": (244, 244),
    "04-hex-side": (220, 260),
}


def run(args: list[str]) -> None:
    subprocess.run([str(a) for a in args], check=True)


def write_background(path: Path) -> None:
    """Write the existing warm cream radial background, with no paper grain."""
    cx = SIZE * 0.46
    cy = SIZE * 0.42
    radius = SIZE * 0.72
    data = bytearray()
    data.extend(f"P6\n{SIZE} {SIZE}\n255\n".encode("ascii"))
    for y in range(SIZE):
        dy = y - cy
        for x in range(SIZE):
            dx = x - cx
            t = min(1.0, math.sqrt(dx * dx + dy * dy) / radius)
            t = t * t * (3.0 - 2.0 * t)
            data.extend(int(BG_INNER[i] * (1 - t) + BG_OUTER[i] * t) for i in range(3))
    path.write_bytes(data)


def polyline_lengths(points: list[tuple[float, float]]) -> tuple[list[float], float]:
    lengths = [0.0]
    total = 0.0
    for a, b in zip(points, points[1:]):
        seg = math.hypot(b[0] - a[0], b[1] - a[1])
        total += seg
        lengths.append(total)
    return lengths, total


def sample_polyline(
    points: list[tuple[float, float]],
    t: float,
    lengths: list[float] | None = None,
    total: float | None = None,
) -> tuple[float, float, float, float]:
    if lengths is None or total is None:
        lengths, total = polyline_lengths(points)
    if total <= 0.0:
        return points[0][0], points[0][1], 1.0, 0.0
    d = max(0.0, min(1.0, t)) * total
    idx = 0
    while idx < len(lengths) - 2 and lengths[idx + 1] < d:
        idx += 1
    a = points[idx]
    b = points[idx + 1]
    seg_len = max(0.001, lengths[idx + 1] - lengths[idx])
    u = (d - lengths[idx]) / seg_len
    x = a[0] + (b[0] - a[0]) * u
    y = a[1] + (b[1] - a[1]) * u
    tx = (b[0] - a[0]) / seg_len
    ty = (b[1] - a[1]) / seg_len
    return x, y, tx, ty


def path_from(points: list[tuple[float, float]], close: bool = False) -> str:
    if not points:
        return ""
    pieces = [f"M {points[0][0]:.1f},{points[0][1]:.1f}"]
    pieces.extend(f"L {x:.1f},{y:.1f}" for x, y in points[1:])
    if close:
        pieces.append("Z")
    return " ".join(pieces)


def line_around(center: tuple[float, float], direction: tuple[float, float], length: float) -> list[tuple[float, float]]:
    dx, dy = direction
    mag = max(0.001, math.hypot(dx, dy))
    dx, dy = dx / mag, dy / mag
    half = length / 2.0
    return [(center[0] - dx * half, center[1] - dy * half), (center[0] + dx * half, center[1] + dy * half)]


class SumiDrawing:
    def __init__(self, seed: int):
        self.rng = random.Random(seed)
        self.draw: list[str] = []

    def _profile_width(self, t: float, widths: tuple[float, float, float], press: float) -> float:
        start, middle, end = widths
        # Fast press-down swelling, sustained belly, then lifting taper.
        lift = 1.0 - 0.70 * max(0.0, (t - 0.70) / 0.30) ** 1.4
        base = start * (1 - t) + end * t + middle * math.sin(math.pi * t)
        return max(2.0, base * lift + start * press * math.exp(-(t / 0.085) ** 2))

    def _outline(
        self,
        points: list[tuple[float, float]],
        widths: tuple[float, float, float],
        samples: int,
        edge_noise: float,
        press: float,
    ) -> tuple[list[tuple[float, float]], list[tuple[float, float]], list[tuple[float, float, float, float, float]]]:
        lengths, total = polyline_lengths(points)
        left: list[tuple[float, float]] = []
        right: list[tuple[float, float]] = []
        sampled: list[tuple[float, float, float, float, float]] = []
        phase_a = self.rng.uniform(0.0, math.tau)
        phase_b = self.rng.uniform(0.0, math.tau)
        phase_c = self.rng.uniform(0.0, math.tau)
        for i in range(samples + 1):
            t = i / samples
            x, y, tx, ty = sample_polyline(points, t, lengths, total)
            nx, ny = -ty, tx
            width = self._profile_width(t, widths, press)
            rough_l = edge_noise * (
                0.66 * math.sin(t * math.tau * 2.0 + phase_a)
                + 0.34 * math.sin(t * math.tau * 5.0 + phase_b)
                + self.rng.uniform(-0.45, 0.45)
            )
            rough_r = edge_noise * (
                0.62 * math.sin(t * math.tau * 2.3 + phase_c)
                + 0.38 * math.sin(t * math.tau * 4.4 + phase_a)
                + self.rng.uniform(-0.45, 0.45)
            )
            half_l = max(1.0, width * 0.5 + rough_l)
            half_r = max(1.0, width * 0.5 + rough_r)
            left.append((x + nx * half_l, y + ny * half_l))
            right.append((x - nx * half_r, y - ny * half_r))
            sampled.append((x, y, tx, ty, width))
        return left, right, sampled

    def _superellipse_blob(
        self,
        x: float,
        y: float,
        tx: float,
        ty: float,
        width: float,
        length: float,
        squareness: float,
    ) -> list[tuple[float, float]]:
        nx, ny = -ty, tx
        pts: list[tuple[float, float]] = []
        n = 36
        # Put most of the blob behind the starting point so it feels like a brush landing.
        cx = x - tx * length * 0.18
        cy = y - ty * length * 0.18
        for i in range(n):
            a = math.tau * i / n
            ca = math.cos(a)
            sa = math.sin(a)
            # Superellipse-ish: flatter sides than a perfect oval.
            ex = math.copysign(abs(ca) ** (2.0 / squareness), ca) * length * 0.5
            ey = math.copysign(abs(sa) ** (2.0 / squareness), sa) * width * 0.55
            j = self.rng.uniform(-0.9, 0.9)
            pts.append((cx + tx * ex + nx * (ey + j), cy + ty * ex + ny * (ey + j)))
        return pts

    def _dry_gap(
        self,
        points: list[tuple[float, float]],
        offset_frac: float,
        t0: float,
        t1: float,
        widths: tuple[float, float, float],
        gap_width: float,
        wiggle: float,
    ) -> list[tuple[float, float]]:
        lengths, total = polyline_lengths(points)
        center: list[tuple[float, float, float, float, float]] = []
        samples = max(6, int((t1 - t0) * total / 22))
        phase = self.rng.uniform(0.0, math.tau)
        for i in range(samples + 1):
            u = i / samples
            t = t0 + (t1 - t0) * u
            x, y, tx, ty = sample_polyline(points, t, lengths, total)
            nx, ny = -ty, tx
            w = self._profile_width(t, widths, 0.0)
            wander = math.sin(u * math.tau * 1.25 + phase) * wiggle + self.rng.uniform(-wiggle * 0.32, wiggle * 0.32)
            off = offset_frac * w * 0.43 + wander
            grow = 0.40 + 0.95 * u
            center.append((x + nx * off, y + ny * off, tx, ty, gap_width * grow))
        left: list[tuple[float, float]] = []
        right: list[tuple[float, float]] = []
        for x, y, tx, ty, w in center:
            nx, ny = -ty, tx
            left.append((x + nx * w * 0.5, y + ny * w * 0.5))
            right.append((x - nx * w * 0.5, y - ny * w * 0.5))
        return left + list(reversed(right))

    def brush_stroke(
        self,
        points: list[tuple[float, float]],
        widths: tuple[float, float, float],
        *,
        dry_start: float = 0.60,
        dry_gaps: int = 5,
        edge_noise: float = 4.0,
        press: float = 0.55,
        splatter: int = 4,
    ) -> None:
        lengths, total = polyline_lengths(points)
        samples = max(32, int(total / 10))
        left, right, sampled = self._outline(points, widths, samples, edge_noise, press)
        body = left + list(reversed(right))
        start_x, start_y, start_tx, start_ty, start_w = sampled[0]

        dry_gap_paths: list[list[tuple[float, float]]] = []
        offsets = [0.0]
        for i in range(dry_gaps - 1):
            mag = 0.18 + 0.16 * i + self.rng.uniform(-0.04, 0.04)
            offsets.append(mag if i % 2 == 0 else -mag)
        for i, off in enumerate(offsets[:dry_gaps]):
            t0 = min(0.86, dry_start + self.rng.uniform(-0.035, 0.10) + i * 0.012)
            t1 = 0.955 + self.rng.uniform(0.000, 0.030)
            gap_source = max(widths)
            gap_w = self.rng.uniform(gap_source * 0.040, gap_source * 0.090) * (1.0 + i * 0.08)
            dry_gap_paths.append(self._dry_gap(points, off, t0, t1, widths, gap_w, edge_noise * 0.36))

        # Open a few shorter skips within the tail so it reads as dry hihaku, not a highlight.
        for _ in range(max(1, dry_gaps // 2)):
            off = self.rng.uniform(-0.42, 0.42)
            t0 = self.rng.uniform(max(0.55, dry_start - 0.06), 0.77)
            t1 = self.rng.uniform(0.82, 0.95)
            dry_gap_paths.append(self._dry_gap(points, off, t0, t1, widths, self.rng.uniform(3.0, 7.0), edge_noise * 0.28))

        body_with_holes = " ".join([path_from(body, close=True), *(path_from(gap, close=True) for gap in dry_gap_paths)])

        # Soft bleed halo below the hard opaque core; this is not an outline. The same even-odd
        # cutouts are used for the core and halo so hihaku reads as actual gaps in the ink body.
        self.draw.append("stroke none")
        self.draw.append("fill-rule evenodd")
        self.draw.append(f"fill {INK_SOFT}")
        self.draw.append(f"path '{body_with_holes}'")
        blob = self._superellipse_blob(start_x, start_y, start_tx, start_ty, start_w * 1.08, start_w * 1.28, 3.2)
        self.draw.append("fill-rule nonzero")
        self.draw.append(f"path '{path_from(blob, close=True)}'")

        self.draw.append("fill-rule evenodd")
        self.draw.append(f"fill {INK}")
        self.draw.append(f"path '{body_with_holes}'")
        self.draw.append("fill-rule nonzero")
        self.draw.append(f"path '{path_from(blob, close=True)}'")

        # A small hook or pressure twist at some entries, still part of the same landing mark.
        if press > 0.30 and self.rng.random() < 0.55:
            nx, ny = -start_ty, start_tx
            hook = [
                (start_x - start_tx * start_w * 0.48 + nx * start_w * 0.18, start_y - start_ty * start_w * 0.48 + ny * start_w * 0.18),
                (start_x - start_tx * start_w * 0.80 - nx * start_w * 0.22, start_y - start_ty * start_w * 0.80 - ny * start_w * 0.22),
                (start_x - start_tx * start_w * 0.25 - nx * start_w * 0.38, start_y - start_ty * start_w * 0.25 - ny * start_w * 0.38),
            ]
            self.draw.append(f"path '{path_from(hook, close=True)}'")

        if splatter:
            for _ in range(splatter):
                t = self.rng.uniform(0.08, 0.92)
                x, y, tx, ty = sample_polyline(points, t, lengths, total)
                nx, ny = -ty, tx
                w = self._profile_width(t, widths, press)
                side = -1 if self.rng.random() < 0.5 else 1
                d = side * self.rng.uniform(w * 0.55, w * 0.95)
                rx = self.rng.uniform(1.2, 4.4)
                ry = self.rng.uniform(1.0, 3.8)
                self.draw.append(f"fill rgba(21,18,15,{self.rng.uniform(0.20,0.45):.3f})")
                self.draw.append(f"ellipse {x + nx * d:.1f},{y + ny * d:.1f} {rx:.1f},{ry:.1f} 0,360")

    def wash_stroke(self, points: list[tuple[float, float]], width: float = 88) -> None:
        left, right, _ = self._outline(points, (width * 0.60, width, width * 0.38), max(28, int(polyline_lengths(points)[1] / 14)), 5.0, 0.10)
        self.draw.append("stroke none")
        self.draw.append("fill-rule nonzero")
        self.draw.append(f"fill {WASH}")
        self.draw.append(f"path '{path_from(left + list(reversed(right)), close=True)}'")

    def light_stroke(self, points: list[tuple[float, float]], widths: tuple[float, float, float], alpha: float = 0.45) -> None:
        """A translucent filled brush body for thinner antenna wires, not a stroked hairline."""
        left, right, _ = self._outline(points, widths, max(24, int(polyline_lengths(points)[1] / 12)), 1.7, 0.18)
        self.draw.append("stroke none")
        self.draw.append("fill-rule nonzero")
        self.draw.append(f"fill rgba(21,18,15,{alpha:.3f})")
        self.draw.append(f"path '{path_from(left + list(reversed(right)), close=True)}'")

    def ink_dot(self, cx: float, cy: float, rx: float, ry: float, alpha: float = 1.0) -> None:
        """Pressed hub dot with a smoother irregular edge than the line landings."""
        pts: list[tuple[float, float]] = []
        phase = self.rng.uniform(0.0, math.tau)
        for i in range(40):
            a = math.tau * i / 40
            r = 1.0 + 0.030 * math.sin(a * 3.0 + phase) + self.rng.uniform(-0.025, 0.025)
            pts.append((cx + math.cos(a) * rx * r, cy + math.sin(a) * ry * r))
        self.draw.append("stroke none")
        self.draw.append("fill-rule nonzero")
        self.draw.append(f"fill rgba(21,18,15,{0.16 * alpha:.3f})")
        self.draw.append(f"path '{path_from(pts, close=True)}'")
        self.draw.append(f"fill rgba(21,18,15,{alpha:.3f})")
        self.draw.append(f"path '{path_from(pts, close=True)}'")

    def enso(self, cx: float, cy: float, rx: float, ry: float, widths: tuple[float, float, float] = (42, 26, 14)) -> None:
        # Classic open ensō: one clockwise near-circle, thinner than round 2 so it frames rather than dominates.
        points: list[tuple[float, float]] = []
        start = math.radians(224)
        end = math.radians(522)  # Leaves an open gap of roughly 60 degrees.
        steps = 72
        for i in range(steps + 1):
            u = i / steps
            a = start + (end - start) * u
            wobble = 1.0 + 0.018 * math.sin(u * math.tau * 2.0 + 0.6) + 0.010 * math.sin(u * math.tau * 5.0)
            points.append((cx + math.cos(a) * rx * wobble, cy + math.sin(a) * ry * wobble))
        self.brush_stroke(points, widths, dry_start=0.56, dry_gaps=8, edge_noise=4.0, press=0.62, splatter=4)

    def save(self, path: Path) -> None:
        path.write_text("\n".join(self.draw) + "\n", encoding="utf-8")


def render_drawing(drawing: SumiDrawing, output: Path, tmp: Path, stem: str) -> None:
    draw_file = tmp / f"{stem}.mvg"
    bg_file = tmp / f"{stem}.ppm"
    drawing.save(draw_file)
    write_background(bg_file)
    run([
        MAGICK,
        str(bg_file),
        "-draw",
        f"@{draw_file}",
        "-strip",
        "-define",
        "png:compression-level=9",
        "PNG24:" + str(output),
    ])


def render_texture_test(output: Path, tmp: Path) -> None:
    drawing = SumiDrawing(seed=40401)
    drawing.brush_stroke([(145, 560), (310, 455), (585, 480), (860, 340)], (86, 102, 26), dry_start=0.55, dry_gaps=9, edge_noise=7.0, press=0.95, splatter=8)
    render_drawing(drawing, output, tmp, "texture-test")


def lerp_point(a: tuple[float, float], b: tuple[float, float], t: float) -> tuple[float, float]:
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def hex_points(cx: float, cy: float, radius: float, rotation_deg: float = -90.0) -> list[tuple[float, float]]:
    return [
        (cx + math.cos(math.radians(rotation_deg + 60 * i)) * radius, cy + math.sin(math.radians(rotation_deg + 60 * i)) * radius)
        for i in range(6)
    ]


def brush_from_hub(
    drawing: SumiDrawing,
    hub: tuple[float, float],
    tip: tuple[float, float],
    widths: tuple[float, float, float],
    *,
    inset: float,
    edge_noise: float,
    dry_gaps: int,
    press: float,
    splatter: int,
) -> None:
    start = lerp_point(hub, tip, inset)
    drawing.brush_stroke([start, tip], widths, dry_start=0.72, dry_gaps=dry_gaps, edge_noise=edge_noise, press=press, splatter=splatter)


def paint_hex_perimeter(drawing: SumiDrawing, corners: list[tuple[float, float]], widths: tuple[float, float, float], edge_noise: float) -> None:
    # Three overlapping, confident perimeter strokes: closed hex silhouette without a signal-arc read.
    for pts in ([corners[5], corners[0], corners[1]], [corners[1], corners[2], corners[3]], [corners[3], corners[4], corners[5]]):
        drawing.brush_stroke(list(pts), widths, dry_start=0.74, dry_gaps=5, edge_noise=edge_noise, press=0.34, splatter=1)


def paint_hex_wires(drawing: SumiDrawing, corners: list[tuple[float, float]], cx: float, cy: float, radius: float, scale: float = 1.0) -> None:
    # Two pale W/M wire elements only. Keeping them separated avoids a spider-web or snowflake read.
    upper = [
        lerp_point(corners[5], corners[0], 0.08),
        (cx - radius * 0.50, cy - radius * 0.56),
        (cx - radius * 0.25, cy - radius * 0.34),
        (cx, cy - radius * 0.50),
        (cx + radius * 0.25, cy - radius * 0.34),
        (cx + radius * 0.50, cy - radius * 0.56),
        lerp_point(corners[0], corners[1], 0.92),
    ]
    lower = [
        lerp_point(corners[4], corners[3], 0.08),
        (cx - radius * 0.50, cy + radius * 0.56),
        (cx - radius * 0.25, cy + radius * 0.34),
        (cx, cy + radius * 0.50),
        (cx + radius * 0.25, cy + radius * 0.34),
        (cx + radius * 0.50, cy + radius * 0.56),
        lerp_point(corners[3], corners[2], 0.08),
    ]
    wire_widths = (11 * scale, 5 * scale, 9 * scale)
    drawing.light_stroke(upper, wire_widths, alpha=0.36)
    drawing.light_stroke(lower, wire_widths, alpha=0.34)


def paint_top_hex_beam(
    drawing: SumiDrawing,
    *,
    cx: float,
    cy: float,
    radius: float,
    spoke_widths: tuple[float, float, float],
    perimeter_widths: tuple[float, float, float],
    include_wires: bool,
    hub_radius: float,
    edge_noise: float,
) -> None:
    corners = hex_points(cx, cy, radius)
    hub = (cx, cy)
    for tip in corners:
        brush_from_hub(drawing, hub, tip, spoke_widths, inset=0.060, edge_noise=edge_noise, dry_gaps=5, press=0.26, splatter=1)
    paint_hex_perimeter(drawing, corners, perimeter_widths, edge_noise=edge_noise)
    if include_wires:
        paint_hex_wires(drawing, corners, cx, cy, radius, scale=radius / 340.0)
    drawing.ink_dot(cx, cy, hub_radius, hub_radius * 0.92, alpha=0.98)


def paint_side_hex_beam(drawing: SumiDrawing) -> None:
    hub = (512, 642)
    tips = [(168, 558), (276, 390), (420, 300), (604, 300), (748, 390), (856, 558)]
    drawing.wash_stroke([(210, 660), (512, 626), (814, 660)], width=48)
    drawing.brush_stroke([(502, 874), (508, 748), hub], (42, 8, 34), dry_start=0.68, dry_gaps=5, edge_noise=2.0, press=0.62, splatter=3)
    drawing.light_stroke(tips + [tips[0]], (14, 5, 12), alpha=0.48)
    for tip in tips:
        brush_from_hub(drawing, hub, tip, (21, 5, 18), inset=0.055, edge_noise=1.35, dry_gaps=4, press=0.20, splatter=0)
    drawing.ink_dot(hub[0], hub[1], 25, 22, alpha=0.96)


def render_concept(slug: str, idx: int, out_dir: Path, tmp: Path) -> None:
    drawing = SumiDrawing(seed=4200 + idx * 311)

    if idx == 1:
        paint_top_hex_beam(
            drawing,
            cx=512,
            cy=512,
            radius=342,
            spoke_widths=(34, 6, 29),
            perimeter_widths=(38, 8, 34),
            include_wires=True,
            hub_radius=27,
            edge_noise=2.0,
        )
    elif idx == 2:
        drawing.enso(512, 516, 366, 354, widths=(38, 22, 13))
        paint_top_hex_beam(
            drawing,
            cx=512,
            cy=512,
            radius=282,
            spoke_widths=(27, 5, 23),
            perimeter_widths=(30, 6, 27),
            include_wires=True,
            hub_radius=22,
            edge_noise=1.7,
        )
    elif idx == 3:
        paint_top_hex_beam(
            drawing,
            cx=512,
            cy=512,
            radius=356,
            spoke_widths=(44, 8, 39),
            perimeter_widths=(49, 10, 43),
            include_wires=False,
            hub_radius=35,
            edge_noise=2.2,
        )
    elif idx == 4:
        paint_side_hex_beam(drawing)
    else:
        raise ValueError(idx)

    out_dir.mkdir(parents=True, exist_ok=True)
    render_drawing(drawing, out_dir / "app-icon-1024.png", tmp, slug)


def make_rounded(src: Path, dst: Path, size: int) -> None:
    radius = max(6, int(size * 0.225))
    run([
        MAGICK,
        str(src),
        "-resize",
        f"{size}x{size}!",
        "-alpha",
        "set",
        "(",
        "-size",
        f"{size}x{size}",
        "xc:none",
        "-fill",
        "white",
        "-draw",
        f"roundrectangle 0,0,{size - 1},{size - 1},{radius},{radius}",
        ")",
        "-compose",
        "CopyOpacity",
        "-composite",
        "-background",
        "#EDE7D9",
        "-alpha",
        "remove",
        "-strip",
        str(dst),
    ])


def make_square(src: Path, dst: Path, size: int) -> None:
    run([MAGICK, str(src), "-resize", f"{size}x{size}!", "-strip", str(dst)])


def make_panel(idx: int, slug: str, src: Path, tmp: Path) -> Path:
    panel = tmp / f"panel-{idx}.png"
    run([MAGICK, "-size", "620x790", "xc:#FAF7EF", "-font", FONT, "-fill", "#191817", "-pointsize", "30", "-gravity", "North", "-annotate", "+0+16", f"{idx}", str(panel)])
    title = slug[3:].replace("-", " ").title()
    run([MAGICK, str(panel), "-font", FONT, "-fill", "#57534B", "-pointsize", "17", "-gravity", "North", "-annotate", "+0+54", title, str(panel)])
    run([MAGICK, str(panel), "-font", FONT, "-fill", "#2A2926", "-pointsize", "18", "-gravity", "NorthWest", "-annotate", "+72+86", "square", "-annotate", "+344+86", "iOS mask", str(panel)])
    rows = [("1024 scaled", 256, 110), ("180 px", 180, 390), ("60 px", 60, 590), ("32 px", 32, 675)]
    for label, px, y in rows:
        sq = tmp / f"{slug}-{px}-square.png"
        rd = tmp / f"{slug}-{px}-round.png"
        make_square(src, sq, px)
        make_rounded(src, rd, px)
        x1 = 72 + (256 - px) // 2
        x2 = 344 + (256 - px) // 2
        run([MAGICK, str(panel), str(sq), "-geometry", f"+{x1}+{y}", "-composite", str(panel)])
        run([MAGICK, str(panel), str(rd), "-geometry", f"+{x2}+{y}", "-composite", str(panel)])
        run([MAGICK, str(panel), "-font", FONT, "-fill", "#676158", "-pointsize", "15", "-gravity", "NorthWest", "-annotate", f"+16+{y + max(0, (px // 2) - 8)}", label, str(panel)])
    return panel


def make_comparison(tmp: Path) -> None:
    panels = []
    for idx, (slug, _desc) in enumerate(CONCEPTS, start=1):
        src = ROOT / slug / "app-icon-1024.png"
        panels.append(make_panel(idx, slug, src, tmp))
    run([MAGICK, *map(str, panels), "+append", "-strip", "-define", "png:compression-level=9", str(ROOT / "comparison.png")])


def make_closeups(tmp: Path) -> None:
    crops: list[Path] = []
    for slug, _desc in CONCEPTS:
        x, y = CLOSEUP_CROPS[slug]
        src = ROOT / slug / "app-icon-1024.png"
        crop = tmp / f"{slug}-closeup.png"
        run([MAGICK, str(src), "-crop", f"512x512+{x}+{y}", "+repage", "-strip", str(crop)])
        crops.append(crop)
    run([MAGICK, *map(str, crops), "+append", "-strip", "-define", "png:compression-level=9", str(ROOT / "closeups.png")])


def write_descriptions() -> None:
    current = {slug for slug, _desc in CONCEPTS}
    retired_slugs = {
        "01-yagi-beam",
        "02-radio-tower",
        "02-lattice-tower",
        "03-ground-plane",
        "04-enso-yagi",
        "04-wire-dipole",
        "05-hex-beam",
    }
    for old_slug in retired_slugs:
        old_dir = ROOT / old_slug
        if old_dir.exists() and old_slug not in current:
            shutil.rmtree(old_dir)
    for slug, desc in CONCEPTS:
        d = ROOT / slug
        d.mkdir(parents=True, exist_ok=True)
        (d / "description.txt").write_text(desc + "\n", encoding="utf-8")


def render_all() -> None:
    if not MAGICK:
        raise SystemExit("ImageMagick 'magick' or 'convert' is required")
    write_descriptions()
    with tempfile.TemporaryDirectory(prefix="ch-icon-concepts-") as td:
        tmp = Path(td)
        for idx, (slug, _desc) in enumerate(CONCEPTS, start=1):
            render_concept(slug, idx, ROOT / slug, tmp)
        make_comparison(tmp)
        make_closeups(tmp)
    print(f"Rendered {len(CONCEPTS)} concept PNGs, comparison.png, and closeups.png")


def main() -> None:
    parser = argparse.ArgumentParser(description="Render deterministic sumi-e app icon concepts.")
    parser.add_argument("--texture-test", type=Path, help="Render one full-size brush stroke texture test to this path.")
    args = parser.parse_args()
    if not MAGICK:
        raise SystemExit("ImageMagick 'magick' or 'convert' is required")
    if args.texture_test:
        with tempfile.TemporaryDirectory(prefix="ch-icon-texture-") as td:
            render_texture_test(args.texture_test, Path(td))
        print(f"Rendered texture test: {args.texture_test}")
    else:
        render_all()


if __name__ == "__main__":
    main()
