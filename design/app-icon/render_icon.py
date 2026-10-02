#!/usr/bin/env python3
"""Render and install the approved Canadian Ham app icon.

The production mark is derived from round-3 concept 1 (`concepts/01-hex-top`):
a top-down hex beam with six straight dry-brush spreaders, a brushed hexagon
perimeter, a pressed hub dot, and two pale zigzag W/M wire elements.
"""
from __future__ import annotations

import math
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True

from concepts.render_concepts import (  # Reuse the deterministic round-3 brush engine.
    SumiDrawing,
    brush_from_hub,
    hex_points,
    lerp_point,
    paint_hex_perimeter,
    paint_hex_wires,
)

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent
EXPORTS = ROOT / "exports"
APPLE_ASSETS = REPO / "apps/apple/CanadianHam/Resources/Assets.xcassets/AppIcon.appiconset"
TVOS_ASSETS = REPO / "apps/apple/Platforms/tvOS/Resources/Assets.xcassets/App Icon & Top Shelf Image.brandassets"
VISION_ASSETS = REPO / "apps/apple/Platforms/visionOS/Resources/Assets.xcassets/AppIcon.solidimagestack"
WEB_PUBLIC = REPO / "apps/web/public"
MAGICK = Path("/opt/homebrew/bin/magick") if Path("/opt/homebrew/bin/magick").exists() else None
if MAGICK is None:
    found = shutil.which("magick") or shutil.which("convert")
    MAGICK = Path(found) if found else None
FONT_SANS = Path("/System/Library/Fonts/Helvetica.ttc")
FONT_SERIF = Path("/System/Library/Fonts/Supplemental/Georgia.ttf")

SIZE = 1024
INK = "#15120F"
CREAM_INNER = (255, 247, 232)
CREAM_OUTER = (246, 238, 220)
CREAM_OUTER_HEX = "#F6EEDC"
DARK_FIELD = "#201B16"
DARK_INK = "#F3E8D2"


def run(args: list[object]) -> None:
    subprocess.run([str(arg) for arg in args], check=True)


def require_magick() -> None:
    if MAGICK is None:
        raise SystemExit("ImageMagick 'magick' or 'convert' is required")


def write_background(path: Path, width: int, height: int) -> None:
    """Write the warm cream field at the requested output resolution."""
    cx = width * 0.46
    cy = height * 0.42
    radius = max(width, height) * 0.72
    data = bytearray(f"P6\n{width} {height}\n255\n".encode("ascii"))
    for y in range(height):
        dy = y - cy
        for x in range(width):
            dx = x - cx
            t = min(1.0, math.sqrt(dx * dx + dy * dy) / radius)
            t = t * t * (3.0 - 2.0 * t)
            data.extend(int(CREAM_INNER[i] * (1 - t) + CREAM_OUTER[i] * t) for i in range(3))
    path.write_bytes(data)


def render_draw_commands(commands: list[str], output: Path, tmp: Path, stem: str, *, width: int = SIZE, height: int = SIZE) -> None:
    draw_file = tmp / f"{stem}.mvg"
    draw_file.write_text("\n".join(commands) + "\n", encoding="utf-8")
    run([
        MAGICK,
        "-size",
        f"{width}x{height}",
        "xc:none",
        "-draw",
        f"@{draw_file}",
        "-strip",
        "-define",
        "png:compression-level=9",
        "PNG32:" + str(output),
    ])


def render_background_png(output: Path, tmp: Path, width: int, height: int) -> None:
    ppm = tmp / f"background-{width}x{height}.ppm"
    write_background(ppm, width, height)
    run([MAGICK, str(ppm), "-strip", "-define", "png:compression-level=9", "PNG24:" + str(output)])


def resize_png(src: Path, dst: Path, width: int, height: int, *, alpha: bool = False) -> None:
    prefix = "PNG32:" if alpha else "PNG24:"
    run([MAGICK, str(src), "-resize", f"{width}x{height}!", "-strip", "-define", "png:compression-level=9", prefix + str(dst)])


def composite_images(base: Path, overlays: list[Path], output: Path, *, alpha: bool = False) -> None:
    args: list[object] = [MAGICK, str(base)]
    for overlay in overlays:
        args.extend([str(overlay), "-composite"])
    args.extend(["-strip", "-define", "png:compression-level=9", ("PNG32:" if alpha else "PNG24:") + str(output)])
    run(args)


def approved_mark_layers() -> tuple[list[str], list[str], list[str]]:
    """Return full, middle, and front draw commands for the owner-approved mark."""
    drawing = SumiDrawing(seed=4511)
    cx = cy = 512
    radius = 342
    corners = hex_points(cx, cy, radius)
    hub = (cx, cy)

    for tip in corners:
        brush_from_hub(
            drawing,
            hub,
            tip,
            (34, 6, 29),
            inset=0.060,
            edge_noise=2.0,
            dry_gaps=5,
            press=0.26,
            splatter=1,
        )
    paint_hex_perimeter(drawing, corners, (38, 8, 34), edge_noise=2.0)
    front_before_wires = list(drawing.draw)

    paint_hex_wires(drawing, corners, cx, cy, radius, scale=1.0)
    wire_commands = drawing.draw[len(front_before_wires) :]

    drawing.ink_dot(cx, cy, 27, 27 * 0.92, alpha=0.98)
    hub_commands = drawing.draw[len(front_before_wires) + len(wire_commands) :]

    front_commands = front_before_wires + hub_commands
    full_commands = front_before_wires + wire_commands + hub_commands
    return full_commands, wire_commands, front_commands


def write_favicon_svg(path: Path) -> None:
    points = []
    for i in range(6):
        angle = math.radians(-90 + 60 * i)
        points.append((32 + math.cos(angle) * 21.5, 32 + math.sin(angle) * 21.5))
    polygon = " ".join(f"{x:.2f},{y:.2f}" for x, y in points)
    spokes = "\n".join(
        f'  <path class="ink spoke" d="M32 32 L{x:.2f} {y:.2f}" fill="none" stroke="{INK}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>'
        for x, y in points
    )
    path.write_text(
        f"""<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 64 64\" width=\"64\" height=\"64\">
  <style>
    .paper {{ fill: {CREAM_OUTER_HEX.lower()}; }}
    .ink {{ fill: none; stroke: {INK.lower()}; stroke-linecap: round; stroke-linejoin: round; }}
    .perimeter {{ stroke-width: 4.0; }}
    .spoke {{ stroke-width: 2.4; }}
    .hub {{ fill: {INK.lower()}; stroke: none; }}
    @media (prefers-color-scheme: dark) {{
      .paper {{ fill: {DARK_FIELD}; }}
      .ink {{ stroke: {DARK_INK.lower()}; }}
      .hub {{ fill: {DARK_INK.lower()}; }}
    }}
  </style>
  <rect width=\"64\" height=\"64\" rx=\"14\" class=\"paper\"/>
  <polygon class=\"ink perimeter\" points=\"{polygon}\" fill=\"none\" stroke=\"{INK}\" stroke-width=\"4.0\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>
{spokes}
  <circle class=\"hub\" cx=\"32\" cy=\"32\" r=\"3.4\" fill=\"{INK}\"/>
</svg>
""",
        encoding="utf-8",
    )


def render_favicon_pngs(_svg: Path) -> None:
    # Render PNG favicons directly so 16 px can stay legible without relying on
    # SVG/CSS support in the rasterizer. The browser-facing SVG remains adaptive.
    points64 = []
    for i in range(6):
        angle = math.radians(-90 + 60 * i)
        points64.append((32 + math.cos(angle) * 21.5, 32 + math.sin(angle) * 21.5))
    for size in (16, 32, 64):
        scale = size / 64.0
        points = [(x * scale, y * scale) for x, y in points64]
        draw = [
            "stroke-linecap round",
            "stroke-linejoin round",
            f"stroke {INK}",
            f"stroke-width {max(1.4, 4.0 * scale):.2f}",
            "fill none",
            "polygon " + " ".join(f"{x:.2f},{y:.2f}" for x, y in points),
        ]
        if size >= 32:
            draw.extend([
                f"stroke-width {max(1.0, 2.4 * scale):.2f}",
                *[f"line {32 * scale:.2f},{32 * scale:.2f} {x:.2f},{y:.2f}" for x, y in points],
            ])
        hub_radius = max(1.2, 3.4 * scale)
        draw.extend([
            "stroke none",
            f"fill {INK}",
            f"circle {32 * scale:.2f},{32 * scale:.2f} {32 * scale + hub_radius:.2f},{32 * scale:.2f}",
        ])
        draw_file = EXPORTS / f".favicon-{size}.mvg"
        draw_file.write_text("\n".join(draw) + "\n", encoding="utf-8")
        try:
            run([
                MAGICK,
                "-size",
                f"{size}x{size}",
                f"xc:{CREAM_OUTER_HEX}",
                "-draw",
                f"@{draw_file}",
                "-alpha",
                "remove",
                "-alpha",
                "off",
                "-strip",
                "-define",
                "png:compression-level=9",
                "PNG24:" + str(EXPORTS / f"favicon-{size}.png"),
            ])
        finally:
            draw_file.unlink(missing_ok=True)


def render_tvos_layers(back: Path, middle: Path, front: Path, tmp: Path) -> None:
    specs = [
        ("tvos-small-400x240", 400, 240, 0.78),
        ("tvos-small-800x480", 800, 480, 0.78),
        ("tvos-app-store-1280x768", 1280, 768, 0.78),
    ]
    for name, width, height, scale in specs:
        render_background_png(EXPORTS / f"{name}-back.png", tmp, width, height)
        mark_size = int(height * scale)
        x = (width - mark_size) // 2
        y = (height - mark_size) // 2
        for layer_name, layer_src in (("middle", middle), ("front", front)):
            run([
                MAGICK,
                "-size",
                f"{width}x{height}",
                "xc:none",
                "(",
                str(layer_src),
                "-resize",
                f"{mark_size}x{mark_size}!",
                ")",
                "-geometry",
                f"+{x}+{y}",
                "-composite",
                "-strip",
                "-define",
                "png:compression-level=9",
                "PNG32:" + str(EXPORTS / f"{name}-{layer_name}.png"),
            ])


def render_top_shelf(mark: Path, tmp: Path) -> None:
    specs = [
        ("tvos-top-shelf-1920x720.png", 1920, 720, False),
        ("tvos-top-shelf-3840x1440.png", 3840, 1440, False),
        ("tvos-top-shelf-wide-2320x720.png", 2320, 720, True),
        ("tvos-top-shelf-wide-4640x1440.png", 4640, 1440, True),
    ]
    for filename, width, height, wide in specs:
        canvas = tmp / f"{filename}.base.png"
        render_background_png(canvas, tmp, width, height)
        mark_size = int(height * (0.72 if wide else 0.70))
        mark_x = int(width * (0.25 if wide else 0.26) - mark_size / 2)
        mark_y = (height - mark_size) // 2
        text_x = int(width * 0.50)
        text_y = int(height * 0.37)
        point_size = int(height * 0.16)
        run([
            MAGICK,
            str(canvas),
            "(",
            str(mark),
            "-resize",
            f"{mark_size}x{mark_size}!",
            ")",
            "-geometry",
            f"+{mark_x}+{mark_y}",
            "-composite",
            "-font",
            str(FONT_SERIF if FONT_SERIF.exists() else FONT_SANS),
            "-fill",
            INK,
            "-pointsize",
            str(point_size),
            "-gravity",
            "NorthWest",
            "-annotate",
            f"+{text_x}+{text_y}",
            "Canadian Ham",
            "-strip",
            "-define",
            "png:compression-level=9",
            "PNG24:" + str(EXPORTS / filename),
        ])


def render_preview_sheet(tmp: Path) -> None:
    items = [
        ("app-icon-1024.png", 160, 160),
        ("app-icon-60.png", 60, 60),
        ("app-icon-120.png", 120, 120),
        ("visionos-back-1024.png", 110, 110),
        ("visionos-middle-1024.png", 110, 110),
        ("visionos-front-1024.png", 110, 110),
        ("apple-touch-icon-180.png", 90, 90),
        ("pwa-icon-192.png", 90, 90),
        ("pwa-icon-512.png", 90, 90),
        ("favicon-16.png", 16, 16),
        ("favicon-32.png", 32, 32),
        ("favicon-64.png", 64, 64),
        ("tvos-small-400x240-back.png", 150, 90),
        ("tvos-small-400x240-middle.png", 150, 90),
        ("tvos-small-400x240-front.png", 150, 90),
        ("tvos-app-store-1280x768-back.png", 150, 90),
        ("tvos-app-store-1280x768-middle.png", 150, 90),
        ("tvos-app-store-1280x768-front.png", 150, 90),
        ("tvos-top-shelf-1920x720.png", 240, 90),
        ("tvos-top-shelf-wide-2320x720.png", 290, 90),
    ]
    sheet_width = 980
    row_height = 190
    columns = 3
    rows = math.ceil(len(items) / columns)
    sheet_height = rows * row_height + 80
    sheet = tmp / "preview-sheet.png"
    run([MAGICK, "-size", f"{sheet_width}x{sheet_height}", f"xc:{CREAM_OUTER_HEX}", str(sheet)])
    for index, (name, display_width, display_height) in enumerate(items):
        col = index % columns
        row = index // columns
        cell_x = col * (sheet_width // columns) + 20
        cell_y = (rows - row - 1) * row_height + 20
        image_x = cell_x
        image_y = cell_y + 44
        pad = 6
        run([
            MAGICK,
            str(sheet),
            "-fill",
            "#FFFFFFAA",
            "-draw",
            f"rectangle {image_x - pad},{image_y - pad} {image_x + display_width + pad},{image_y + display_height + pad}",
            str(sheet),
        ])
        run([
            MAGICK,
            str(sheet),
            "(",
            str(EXPORTS / name),
            "-resize",
            f"{display_width}x{display_height}!",
            ")",
            "-geometry",
            f"+{image_x}+{image_y}",
            "-composite",
            "-font",
            str(FONT_SANS),
            "-fill",
            INK,
            "-pointsize",
            "14",
            "-gravity",
            "NorthWest",
            "-annotate",
            f"+{cell_x}+{cell_y + 8}",
            name,
            str(sheet),
        ])
    run([MAGICK, str(sheet), "-strip", "-define", "png:compression-level=9", "PNG24:" + str(EXPORTS / "preview-sheet.png")])


def copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)


def install_apple_assets(full_icon: Path) -> None:
    copy_file(full_icon, APPLE_ASSETS / "app-icon-1024.png")
    mac_sizes = {
        "mac-icon-16.png": (16, 16),
        "mac-icon-16@2x.png": (32, 32),
        "mac-icon-32.png": (32, 32),
        "mac-icon-32@2x.png": (64, 64),
        "mac-icon-128.png": (128, 128),
        "mac-icon-128@2x.png": (256, 256),
        "mac-icon-256.png": (256, 256),
        "mac-icon-256@2x.png": (512, 512),
        "mac-icon-512.png": (512, 512),
        "mac-icon-512@2x.png": (1024, 1024),
    }
    for name, (width, height) in mac_sizes.items():
        resize_png(full_icon, APPLE_ASSETS / name, width, height)

    tvos_layers = {
        "App Icon - Small.imagestack/Back.imagestacklayer/Content.imageset": ["tvos-small-400x240-back.png", "tvos-small-800x480-back.png"],
        "App Icon - Small.imagestack/Middle.imagestacklayer/Content.imageset": ["tvos-small-400x240-middle.png", "tvos-small-800x480-middle.png"],
        "App Icon - Small.imagestack/Front.imagestacklayer/Content.imageset": ["tvos-small-400x240-front.png", "tvos-small-800x480-front.png"],
        "App Icon - App Store.imagestack/Back.imagestacklayer/Content.imageset": ["tvos-app-store-1280x768-back.png"],
        "App Icon - App Store.imagestack/Middle.imagestacklayer/Content.imageset": ["tvos-app-store-1280x768-middle.png"],
        "App Icon - App Store.imagestack/Front.imagestacklayer/Content.imageset": ["tvos-app-store-1280x768-front.png"],
        "Top Shelf Image.imageset": ["tvos-top-shelf-1920x720.png", "tvos-top-shelf-3840x1440.png"],
        "Top Shelf Image Wide.imageset": ["tvos-top-shelf-wide-2320x720.png", "tvos-top-shelf-wide-4640x1440.png"],
    }
    for relative_dir, names in tvos_layers.items():
        for name in names:
            copy_file(EXPORTS / name, TVOS_ASSETS / relative_dir / name)

    vision_layers = {
        "Back.solidimagestacklayer/Content.imageset": "visionos-back-1024.png",
        "Middle.solidimagestacklayer/Content.imageset": "visionos-middle-1024.png",
        "Front.solidimagestacklayer/Content.imageset": "visionos-front-1024.png",
    }
    for relative_dir, name in vision_layers.items():
        copy_file(EXPORTS / name, VISION_ASSETS / relative_dir / name)


def install_web_assets() -> None:
    for name in (
        "favicon.svg",
        "favicon-16.png",
        "favicon-32.png",
        "favicon-64.png",
        "apple-touch-icon-180.png",
        "pwa-icon-192.png",
        "pwa-icon-512.png",
    ):
        copy_file(EXPORTS / name, WEB_PUBLIC / name)


def render_all() -> None:
    require_magick()
    EXPORTS.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="ch-icon-production-") as td:
        tmp = Path(td)
        full_commands, middle_commands, front_commands = approved_mark_layers()
        full_mark = tmp / "mark-full-1024.png"
        middle = tmp / "mark-middle-1024.png"
        front = tmp / "mark-front-1024.png"
        back = tmp / "background-1024.png"
        render_draw_commands(full_commands, full_mark, tmp, "mark-full")
        render_draw_commands(middle_commands, middle, tmp, "mark-middle")
        render_draw_commands(front_commands, front, tmp, "mark-front")
        render_background_png(back, tmp, SIZE, SIZE)

        composite_images(back, [middle, front], EXPORTS / "app-icon-1024.png")
        resize_png(EXPORTS / "app-icon-1024.png", EXPORTS / "app-icon-60.png", 60, 60)
        resize_png(EXPORTS / "app-icon-1024.png", EXPORTS / "app-icon-120.png", 120, 120)
        copy_file(back, EXPORTS / "visionos-back-1024.png")
        copy_file(middle, EXPORTS / "visionos-middle-1024.png")
        copy_file(front, EXPORTS / "visionos-front-1024.png")

        render_tvos_layers(back, middle, front, tmp)
        render_top_shelf(full_mark, tmp)

        for name, size in (("apple-touch-icon-180.png", 180), ("pwa-icon-192.png", 192), ("pwa-icon-512.png", 512)):
            resize_png(EXPORTS / "app-icon-1024.png", EXPORTS / name, size, size)

        favicon_svg = EXPORTS / "favicon.svg"
        write_favicon_svg(favicon_svg)
        render_favicon_pngs(favicon_svg)
        render_preview_sheet(tmp)

        install_apple_assets(EXPORTS / "app-icon-1024.png")
        install_web_assets()

    print(f"Rendered approved app icon exports and installed checked-in consumers from {EXPORTS}")


if __name__ == "__main__":
    render_all()
