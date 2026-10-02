#!/usr/bin/env python3
"""Deterministic raster sumi-e app icon concept renderer.

The renderer intentionally keeps these concept images isolated from the shipped
app-icon exports. It uses ImageMagick only as a raster drawing/compositing engine:
Python builds hundreds of seeded semi-transparent bristle tracks, dry gaps, ink
pools, and paper-edge flecks for each antenna stroke.
"""
from __future__ import annotations

import math
import os
import random
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SIZE = 1024
MAGICK = shutil.which("magick") or shutil.which("convert")
FONT = "/System/Library/Fonts/Helvetica.ttc"
INK = (18, 18, 17)
DRY = (42, 42, 39)
WASH = (83, 83, 78)
BG_INNER = (255, 247, 232)  # #FFF7E8 from src/background.svg
BG_OUTER = (246, 238, 220)  # #F6EEDC from src/background.svg

CONCEPTS = [
    ("01-yagi-beam", "Yagi beam on a mast, drawn as dry sumi-e bristles without broadcast arcs."),
    ("02-lattice-tower", "Lattice tower with a small beam antenna, using broken ink lines for the steelwork."),
    ("03-ground-plane", "Vertical ground-plane antenna with sloping radials and a faint grey wash behind it."),
    ("04-wire-dipole", "Wire dipole sagging between two brushed supports over a single dry horizon stroke."),
]


def rgba(rgb: tuple[int, int, int], alpha: float) -> str:
    return f"rgba({rgb[0]},{rgb[1]},{rgb[2]},{max(0.0, min(alpha, 1.0)):.3f})"


def run(args: list[str]) -> None:
    subprocess.run(args, check=True)


def write_background(path: Path) -> None:
    """Write a warm cream PPM using the current icon's radial palette."""
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
            # Smooth the very subtle radial warmth, with no grain.
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


def sample_polyline(points: list[tuple[float, float]], t: float, lengths: list[float] | None = None, total: float | None = None) -> tuple[float, float, float, float]:
    if lengths is None or total is None:
        lengths, total = polyline_lengths(points)
    if total <= 0:
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


def line_around(center: tuple[float, float], direction: tuple[float, float], length: float) -> list[tuple[float, float]]:
    dx, dy = direction
    mag = max(0.001, math.hypot(dx, dy))
    dx, dy = dx / mag, dy / mag
    half = length / 2.0
    return [(center[0] - dx * half, center[1] - dy * half), (center[0] + dx * half, center[1] + dy * half)]


def jittered_poly(points: list[tuple[float, float]], rng: random.Random, amount: float = 8.0) -> list[tuple[float, float]]:
    out = []
    for i, (x, y) in enumerate(points):
        if i == 0 or i == len(points) - 1:
            out.append((x + rng.uniform(-amount * 0.25, amount * 0.25), y + rng.uniform(-amount * 0.25, amount * 0.25)))
        else:
            out.append((x + rng.uniform(-amount, amount), y + rng.uniform(-amount, amount)))
    return out


class InkDrawing:
    def __init__(self, seed: int):
        self.rng = random.Random(seed)
        self.draw: list[str] = []

    def brush_stroke(
        self,
        points: list[tuple[float, float]],
        widths: tuple[float, float, float] = (16, 32, 12),
        bristles: int | None = None,
        ink: tuple[int, int, int] = INK,
        alpha: tuple[float, float] = (0.19, 0.42),
        dry_start: float = 0.62,
        roughness: float = 2.6,
        splatter: bool = True,
        pools: bool = True,
    ) -> None:
        points = jittered_poly(points, self.rng, amount=roughness * 1.4)
        lengths, total = polyline_lengths(points)
        max_width = max(widths)
        count = bristles if bristles is not None else max(12, int(max_width * 1.15))

        # Pale wet underbody: ties individual bristles together while staying visibly streaky.
        self.draw.append("fill none")
        self.draw.append(f"stroke {rgba(ink, 0.078)}")
        self.draw.append(f"stroke-width {max_width * 0.72:.2f}")
        self.draw.append("stroke-linecap round")
        self.draw.append("path '" + " ".join(("M" if i == 0 else "L") + f" {x:.1f},{y:.1f}" for i, (x, y) in enumerate(points)) + "'")

        for _ in range(count):
            offset_frac = self.rng.uniform(-1.12, 1.12)
            edge = abs(offset_frac)
            bristle_width = self.rng.uniform(0.7, 2.4) * (1.15 - min(edge, 1.0) * 0.45)
            base_alpha = self.rng.uniform(alpha[0], alpha[1]) * (1.0 - min(edge, 1.0) * 0.28)
            depletion = self.rng.uniform(0.50, 0.92)
            phase = self.rng.uniform(0.0, math.tau)
            samples = max(18, int(total / 9.0))
            segment: list[tuple[float, float]] = []

            def flush() -> None:
                nonlocal segment
                if len(segment) >= 2:
                    self.draw.append("fill none")
                    self.draw.append(f"stroke {rgba(ink, base_alpha)}")
                    self.draw.append(f"stroke-width {max(0.45, bristle_width):.2f}")
                    self.draw.append("stroke-linecap round")
                    self.draw.append("path '" + " ".join(("M" if i == 0 else "L") + f" {x:.1f},{y:.1f}" for i, (x, y) in enumerate(segment)) + "'")
                segment = []

            for s in range(samples + 1):
                t = s / samples
                w = widths[0] * (1 - t) + widths[2] * t + widths[1] * math.sin(math.pi * t)
                x, y, tx, ty = sample_polyline(points, t, lengths, total)
                nx, ny = -ty, tx
                dry = max(0.0, (t - dry_start) / max(0.001, 1.0 - dry_start))
                # Long bristle tracks break into dry white cuts near the end and on the edges.
                break_chance = dry * (1.08 - depletion) + max(0.0, edge - 0.72) * 0.10
                if self.rng.random() < break_chance * 0.72:
                    flush()
                    continue
                wander = math.sin(t * math.tau * self.rng.uniform(1.0, 2.7) + phase) * roughness
                skip_jitter = self.rng.uniform(-roughness, roughness)
                ox = nx * (offset_frac * w * 0.5 + wander) + self.rng.uniform(-roughness, roughness) * 0.26
                oy = ny * (offset_frac * w * 0.5 + wander) + skip_jitter * 0.26
                segment.append((x + ox, y + oy))
            flush()

        # Ink pooling at the touch-down and lift-off points.
        if pools:
            for t, scale, count_pools in [(0.0, 1.05, 16), (1.0, 0.82, 12)]:
                x, y, tx, ty = sample_polyline(points, t, lengths, total)
                for _ in range(count_pools):
                    rx = self.rng.uniform(max_width * 0.10, max_width * 0.40) * scale
                    ry = self.rng.uniform(max_width * 0.07, max_width * 0.28) * scale
                    dx = self.rng.uniform(-max_width * 0.26, max_width * 0.26)
                    dy = self.rng.uniform(-max_width * 0.26, max_width * 0.26)
                    self.draw.append(f"fill {rgba(ink, self.rng.uniform(0.045, 0.13))}")
                    self.draw.append(f"ellipse {x+dx:.1f},{y+dy:.1f} {rx:.1f},{ry:.1f} 0,360")

        if splatter:
            # Slightly rough absorbent-paper edge: sparse feathered flecks, not tiled grain.
            flecks = max(10, int(total / 16))
            for _ in range(flecks):
                t = self.rng.random()
                w = widths[0] * (1 - t) + widths[2] * t + widths[1] * math.sin(math.pi * t)
                x, y, tx, ty = sample_polyline(points, t, lengths, total)
                nx, ny = -ty, tx
                side = -1 if self.rng.random() < 0.5 else 1
                d = side * self.rng.uniform(w * 0.35, w * 0.66)
                fx = x + nx * d + self.rng.uniform(-5, 5)
                fy = y + ny * d + self.rng.uniform(-5, 5)
                self.draw.append(f"fill {rgba(ink, self.rng.uniform(0.018, 0.060))}")
                self.draw.append(f"ellipse {fx:.1f},{fy:.1f} {self.rng.uniform(0.8,3.4):.1f},{self.rng.uniform(0.6,2.8):.1f} 0,360")

    def wash_stroke(self, points: list[tuple[float, float]], width: float = 54, alpha: float = 0.055) -> None:
        self.brush_stroke(points, widths=(width * 0.5, width, width * 0.28), bristles=int(width * 0.50), ink=WASH, alpha=(alpha * 0.25, alpha), dry_start=0.40, roughness=6.0, splatter=False, pools=False)

    def save(self, path: Path) -> None:
        path.write_text("\n".join(self.draw) + "\n", encoding="utf-8")


def render_concept(name: str, idx: int, out_dir: Path, tmp: Path) -> None:
    drawing = InkDrawing(seed=1040 + idx * 97)

    if idx == 1:
        # Yagi beam: diagonal mast, boom, and unequal driven/reflector/director elements.
        drawing.wash_stroke([(245, 620), (440, 505), (685, 405), (810, 300)], width=34, alpha=0.045)
        drawing.brush_stroke([(370, 815), (425, 640), (502, 420)], widths=(30, 38, 20), dry_start=0.66, roughness=3.0)
        boom = [(260, 415), (485, 374), (792, 324)]
        drawing.brush_stroke(boom, widths=(22, 29, 16), dry_start=0.58, roughness=2.8)
        boom_dir = (792 - 260, 324 - 415)
        perp = (-boom_dir[1], boom_dir[0])
        for c, length, w in [((302, 407), 262, 19), ((418, 386), 330, 23), ((545, 365), 286, 19), ((657, 345), 220, 17), ((752, 330), 166, 15)]:
            drawing.brush_stroke(line_around(c, perp, length), widths=(w * 0.65, w, w * 0.54), bristles=int(w * 0.95), dry_start=0.55, roughness=2.5)
        # Tiny feed stub instead of podcast-like waves.
        drawing.brush_stroke([(485, 374), (494, 438), (506, 495)], widths=(9, 13, 6), bristles=10, dry_start=0.50, roughness=2.0)

    elif idx == 2:
        # Lattice tower with a compact beam at top.
        drawing.wash_stroke([(335, 790), (470, 570), (565, 340), (715, 240)], width=42, alpha=0.040)
        left = [(333, 812), (397, 640), (454, 470), (496, 265)]
        right = [(655, 812), (604, 635), (548, 468), (506, 265)]
        drawing.brush_stroke(left, widths=(27, 34, 16), dry_start=0.68, roughness=2.8)
        drawing.brush_stroke(right, widths=(27, 34, 16), dry_start=0.68, roughness=2.8)
        for y, x1, x2 in [(733, 360, 627), (640, 397, 602), (548, 423, 575), (455, 452, 549), (360, 476, 525)]:
            drawing.brush_stroke([(x1, y), ((x1 + x2) / 2, y - 22), (x2, y)], widths=(10, 15, 8), bristles=10, dry_start=0.52, roughness=2.0)
        for a, b in [((360, 733), (602, 640)), ((627, 733), (397, 640)), ((397, 640), (575, 548)), ((602, 640), (423, 548)), ((423, 548), (549, 455)), ((575, 548), (452, 455))]:
            drawing.brush_stroke([a, b], widths=(8, 12, 6), bristles=8, dry_start=0.46, roughness=1.8)
        # Top Yagi beam.
        drawing.brush_stroke([(245, 255), (508, 252), (783, 249)], widths=(17, 25, 14), dry_start=0.60, roughness=2.2)
        for c, length in [((300, 255), 190), ((438, 253), 245), ((574, 252), 215), ((705, 250), 160)]:
            drawing.brush_stroke([(c[0], c[1] - length / 2), (c[0], c[1] + length / 2)], widths=(11, 17, 9), bristles=11, dry_start=0.56, roughness=2.0)

    elif idx == 3:
        # Vertical ground-plane antenna: whip, coil/base, and sloping radials.
        drawing.wash_stroke([(316, 248), (493, 405), (622, 635), (732, 820)], width=62, alpha=0.036)
        drawing.brush_stroke([(512, 184), (508, 390), (515, 704)], widths=(26, 46, 34), dry_start=0.72, roughness=3.0)
        drawing.brush_stroke([(468, 700), (512, 726), (560, 700)], widths=(24, 38, 24), bristles=28, dry_start=0.52, roughness=2.4)
        for end, w in [((188, 862), 34), ((330, 902), 28), ((694, 902), 28), ((836, 862), 34)]:
            drawing.brush_stroke([(512, 726), ((512 + end[0]) / 2, (726 + end[1]) / 2 - 15), end], widths=(23, w, 15), bristles=int(w * 1.05), dry_start=0.58, roughness=3.0)
        drawing.brush_stroke([(486, 762), (538, 762)], widths=(16, 28, 16), bristles=20, dry_start=0.52, roughness=2.1)

    elif idx == 4:
        # Wire dipole between two supports over a single dry horizon.
        drawing.wash_stroke([(165, 718), (360, 694), (638, 710), (862, 680)], width=36, alpha=0.030)
        drawing.brush_stroke([(158, 786), (390, 758), (628, 774), (872, 744)], widths=(19, 27, 15), dry_start=0.56, roughness=3.6)
        drawing.brush_stroke([(232, 784), (256, 568), (284, 336)], widths=(26, 34, 17), dry_start=0.70, roughness=3.0)
        drawing.brush_stroke([(794, 784), (768, 568), (742, 336)], widths=(26, 34, 17), dry_start=0.70, roughness=3.0)
        drawing.brush_stroke([(284, 360), (390, 426), (510, 492), (630, 426), (742, 360)], widths=(18, 30, 14), bristles=30, dry_start=0.62, roughness=3.4)
        drawing.brush_stroke([(510, 492), (514, 602), (506, 704)], widths=(12, 18, 8), bristles=12, dry_start=0.54, roughness=2.2)
        # small strain insulators, brushed rather than precise dots.
        drawing.brush_stroke([(318, 388), (343, 400)], widths=(8, 12, 6), bristles=7, dry_start=0.45, roughness=1.6)
        drawing.brush_stroke([(681, 398), (707, 386)], widths=(8, 12, 6), bristles=7, dry_start=0.45, roughness=1.6)

    else:
        raise ValueError(idx)

    draw_file = tmp / f"{name}.mvg"
    bg_file = tmp / f"{name}.ppm"
    drawing.save(draw_file)
    write_background(bg_file)
    out_dir.mkdir(parents=True, exist_ok=True)
    output = out_dir / "app-icon-1024.png"
    run([MAGICK, str(bg_file), "-draw", f"@{draw_file}", "-strip", "PNG24:" + str(output)])


def make_rounded(src: Path, dst: Path, size: int) -> None:
    radius = max(6, int(size * 0.225))
    run([
        MAGICK,
        str(src),
        "-resize", f"{size}x{size}!",
        "-alpha", "set",
        "(", "-size", f"{size}x{size}", "xc:none", "-fill", "white", "-draw", f"roundrectangle 0,0,{size-1},{size-1},{radius},{radius}", ")",
        "-compose", "CopyOpacity", "-composite",
        "-background", "#EDE7D9", "-alpha", "remove", "-strip", str(dst),
    ])


def make_square(src: Path, dst: Path, size: int) -> None:
    run([MAGICK, str(src), "-resize", f"{size}x{size}!", "-strip", str(dst)])


def make_panel(idx: int, slug: str, description: str, src: Path, tmp: Path) -> Path:
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
    panels: list[Path] = []
    for idx, (slug, desc) in enumerate(CONCEPTS, start=1):
        src = ROOT / slug / "app-icon-1024.png"
        panels.append(make_panel(idx, slug, desc, src, tmp))
    comparison = ROOT / "comparison.png"
    cmd = [MAGICK, *map(str, panels), "+append", "-strip", str(comparison)]
    run(cmd)


def write_descriptions() -> None:
    for slug, desc in CONCEPTS:
        d = ROOT / slug
        d.mkdir(parents=True, exist_ok=True)
        (d / "description.txt").write_text(desc + "\n", encoding="utf-8")


def main() -> None:
    if not MAGICK:
        raise SystemExit("ImageMagick 'magick' or 'convert' is required")
    write_descriptions()
    with tempfile.TemporaryDirectory(prefix="ch-icon-concepts-") as td:
        tmp = Path(td)
        for idx, (slug, _desc) in enumerate(CONCEPTS, start=1):
            render_concept(slug, idx, ROOT / slug, tmp)
        make_comparison(tmp)
    print("Rendered 4 concept PNGs and design/app-icon/concepts/comparison.png")


if __name__ == "__main__":
    main()
