#!/usr/bin/env python3
"""Render and install the approved Canadian Ham app icon.

The production mark is derived from round-3 concept 1 (`concepts/01-hex-top`):
a top-down hex beam with six straight dry-brush spreaders, a brushed hexagon
perimeter, a pressed hub dot, and two pale zigzag W/M wire elements.
"""
from __future__ import annotations

import json
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
ICON_COMPOSER = REPO / "apps/apple/CanadianHam/Resources/AppIcon.icon"
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
DARK_FIELD_INNER = (42, 36, 30)
DARK_FIELD_OUTER = (32, 27, 22)
DARK_INK = "#F3E8D2"
TINTED_FOREGROUND = "#FFFFFF"
TINTED_BACKGROUND = "#000000"


def run(args: list[object]) -> None:
    subprocess.run([str(arg) for arg in args], check=True)


def require_magick() -> None:
    if MAGICK is None:
        raise SystemExit("ImageMagick 'magick' or 'convert' is required")


def write_radial_background(path: Path, width: int, height: int, inner: tuple[int, int, int], outer: tuple[int, int, int]) -> None:
    """Write the app-icon radial field at the requested output resolution."""
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
            data.extend(int(inner[i] * (1 - t) + outer[i] * t) for i in range(3))
    path.write_bytes(data)


def write_background(path: Path, width: int, height: int) -> None:
    """Write the warm cream field at the requested output resolution."""
    write_radial_background(path, width, height, CREAM_INNER, CREAM_OUTER)


def write_dark_background(path: Path, width: int, height: int) -> None:
    """Write the dark warm field for the dark app icon variant."""
    write_radial_background(path, width, height, DARK_FIELD_INNER, DARK_FIELD_OUTER)


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


def render_dark_background_png(output: Path, tmp: Path, width: int, height: int) -> None:
    ppm = tmp / f"dark-background-{width}x{height}.ppm"
    write_dark_background(ppm, width, height)
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


def recolor_visible_pixels(src: Path, dst: Path, color: str, tmp: Path, stem: str) -> None:
    """Paint every visible source pixel with color while preserving alpha."""
    alpha = tmp / f"{stem}-alpha.png"
    run([MAGICK, str(src), "-alpha", "extract", str(alpha)])
    run([
        MAGICK,
        "-size",
        f"{SIZE}x{SIZE}",
        f"xc:{color}",
        str(alpha),
        "-compose",
        "CopyOpacity",
        "-composite",
        "-strip",
        "-define",
        "png:compression-level=9",
        "PNG32:" + str(dst),
    ])


def inset_mark_icon(mark: Path, background: Path, output: Path, size: int, tmp: Path, *, inset_scale: float) -> None:
    """Compose a mark inside the maskable safe zone on an existing background."""
    mark_size = round(size * inset_scale)
    offset = (size - mark_size) // 2
    resized_mark = tmp / f"safe-mark-{size}.png"
    resize_png(mark, resized_mark, mark_size, mark_size, alpha=True)
    run([
        MAGICK,
        str(background),
        str(resized_mark),
        "-geometry",
        f"+{offset}+{offset}",
        "-composite",
        "-strip",
        "-define",
        "png:compression-level=9",
        "PNG24:" + str(output),
    ])


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


def draw_roundrect_mask(src: Path, output: Path, width: int, height: int, radius: int, tmp: Path, stem: str) -> None:
    mask = tmp / f"{stem}-mask.png"
    resized = tmp / f"{stem}-resized.png"
    resize_png(src, resized, width, height, alpha=True)
    run([
        MAGICK,
        "-size",
        f"{width}x{height}",
        "xc:none",
        "-fill",
        "white",
        "-draw",
        f"roundrectangle 0,0 {width - 1},{height - 1} {radius},{radius}",
        str(mask),
    ])
    run([MAGICK, str(resized), str(mask), "-compose", "CopyOpacity", "-composite", "PNG32:" + str(output)])


def render_web_tab_preview(output: Path, favicon: Path, *, dark: bool, tmp: Path) -> None:
    width, height = 260, 88
    bar = DARK_FIELD if dark else "#F8F1E4"
    tab = "#302821" if dark else "#FFFFFF"
    text = DARK_INK if dark else INK
    favicon_src = favicon
    if dark:
        favicon_src = tmp / "favicon-dark-64.png"
        points = []
        for i in range(6):
            angle = math.radians(-90 + 60 * i)
            points.append((32 + math.cos(angle) * 21.5, 32 + math.sin(angle) * 21.5))
        draw = [
            "stroke-linecap round",
            "stroke-linejoin round",
            f"stroke {DARK_INK}",
            "stroke-width 4.0",
            "fill none",
            "polygon " + " ".join(f"{x:.2f},{y:.2f}" for x, y in points),
            "stroke-width 2.4",
            *[f"line 32.00,32.00 {x:.2f},{y:.2f}" for x, y in points],
            "stroke none",
            f"fill {DARK_INK}",
            "circle 32.00,32.00 35.40,32.00",
        ]
        draw_file = tmp / "favicon-dark.mvg"
        draw_file.write_text("\n".join(draw) + "\n", encoding="utf-8")
        run([
            MAGICK,
            "-size",
            "64x64",
            f"xc:{DARK_FIELD}",
            "-draw",
            f"@{draw_file}",
            "-strip",
            "PNG24:" + str(favicon_src),
        ])
    run([
        MAGICK,
        "-size",
        f"{width}x{height}",
        f"xc:{bar}",
        "-fill",
        tab,
        "-draw",
        "roundrectangle 18,18 242,74 18,18",
        "(",
        str(favicon_src),
        "-resize",
        "32x32!",
        ")",
        "-geometry",
        "+34+32",
        "-composite",
        "-font",
        str(FONT_SANS),
        "-fill",
        text,
        "-pointsize",
        "17",
        "-gravity",
        "NorthWest",
        "-annotate",
        "+78+37",
        "Canadian Ham",
        "-strip",
        "PNG24:" + str(output),
    ])


def render_variants_preview_sheet(tmp: Path) -> None:
    variants = [
        ("iOS light", EXPORTS / "app-icon-1024.png", 168, 168, "round"),
        ("iOS dark", EXPORTS / "app-icon-dark-1024.png", 168, 168, "round"),
        ("iOS tinted", EXPORTS / "app-icon-tinted-1024.png", 168, 168, "round"),
        ("iOS clear foreground", EXPORTS / "app-icon-foreground-1024.png", 168, 168, "clear"),
        ("macOS fallback", EXPORTS / "mac-1024.png", 168, 168, "round"),
        ("Web favicon light", tmp / "web-tab-light.png", 260, 88, "plain"),
        ("Web favicon dark", tmp / "web-tab-dark.png", 260, 88, "plain"),
    ]
    render_web_tab_preview(tmp / "web-tab-light.png", EXPORTS / "favicon-64.png", dark=False, tmp=tmp)
    render_web_tab_preview(tmp / "web-tab-dark.png", EXPORTS / "favicon-64.png", dark=True, tmp=tmp)
    sheet_width = 1060
    sheet_height = 610
    sheet = tmp / "variants-preview.png"
    run([MAGICK, "-size", f"{sheet_width}x{sheet_height}", "xc:#FBF4E8", str(sheet)])
    run([
        MAGICK,
        str(sheet),
        "-font",
        str(FONT_SANS),
        "-fill",
        INK,
        "-pointsize",
        "28",
        "-gravity",
        "NorthWest",
        "-annotate",
        "+32+24",
        "Canadian Ham app icon variants",
        str(sheet),
    ])
    cell_w = 250
    positions = [(32, 96), (290, 96), (548, 96), (806, 96), (32, 350), (290, 398), (580, 398)]
    for index, (label, src, width, height, mode) in enumerate(variants):
        x, y = positions[index]
        label_y = y - 32
        display_src = src
        if mode == "round":
            display_src = tmp / f"variant-{index}-round.png"
            draw_roundrect_mask(src, display_src, width, height, 38, tmp, f"variant-{index}")
        elif mode == "clear":
            checker = tmp / "checker.png"
            run([MAGICK, "-size", f"{width}x{height}", "pattern:checkerboard", "-resize", f"{width}x{height}!", str(checker)])
            display_src = tmp / f"variant-{index}-clear.png"
            run([MAGICK, str(checker), "(", str(src), "-resize", f"{width}x{height}!", ")", "-composite", "PNG24:" + str(display_src)])
        run([
            MAGICK,
            str(sheet),
            "-fill",
            "#FFFFFFAA",
            "-draw",
            f"roundrectangle {x - 14},{y - 14} {x + width + 14},{y + height + 14} 22,22",
            str(sheet),
        ])
        run([
            MAGICK,
            str(sheet),
            "(",
            str(display_src),
            "-resize",
            f"{width}x{height}!",
            ")",
            "-geometry",
            f"+{x}+{y}",
            "-composite",
            str(sheet),
        ])
        run([
            MAGICK,
            str(sheet),
            "-font",
            str(FONT_SANS),
            "-fill",
            INK,
            "-pointsize",
            "16",
            "-gravity",
            "NorthWest",
            "-annotate",
            f"+{x}+{label_y}",
            label,
            str(sheet),
        ])
    note = "tvOS and visionOS keep their layered image-stack assets; Apple dark/tinted variants apply to the shared iOS/iPadOS/macOS AppIcon."
    run([
        MAGICK,
        str(sheet),
        "-font",
        str(FONT_SANS),
        "-fill",
        "#5A5046",
        "-pointsize",
        "14",
        "-gravity",
        "SouthWest",
        "-annotate",
        "+32+28",
        note,
        "-strip",
        "-define",
        "png:compression-level=9",
        "PNG24:" + str(EXPORTS / "variants-preview.png"),
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


def write_json(path: Path, payload: object) -> None:
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def write_appiconset_contents() -> None:
    images: list[dict[str, object]] = [
        {"filename": "icon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
        {
            "appearances": [{"appearance": "luminosity", "value": "dark"}],
            "filename": "icon-dark-1024.png",
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024",
        },
        {
            "appearances": [{"appearance": "luminosity", "value": "tinted"}],
            "filename": "icon-tinted-1024.png",
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024",
        },
    ]
    for filename, idiom_size, scale in (
        ("mac-16.png", "16x16", "1x"),
        ("mac-32.png", "16x16", "2x"),
        ("mac-32.png", "32x32", "1x"),
        ("mac-64.png", "32x32", "2x"),
        ("mac-128.png", "128x128", "1x"),
        ("mac-256.png", "128x128", "2x"),
        ("mac-256.png", "256x256", "1x"),
        ("mac-512.png", "256x256", "2x"),
        ("mac-512.png", "512x512", "1x"),
        ("mac-1024.png", "512x512", "2x"),
    ):
        images.append({"filename": filename, "idiom": "mac", "scale": scale, "size": idiom_size})
    write_json(APPLE_ASSETS / "Contents.json", {"images": images, "info": {"author": "xcode", "version": 1}})


def srgb_string(rgb: tuple[int, int, int]) -> str:
    return "srgb:" + ",".join(f"{channel / 255:.5f}" for channel in rgb) + ",1.00000"


def write_icon_composer_bundle(foreground: Path) -> None:
    assets_dir = ICON_COMPOSER / "Assets"
    assets_dir.mkdir(parents=True, exist_ok=True)
    copy_file(foreground, assets_dir / "brushstroke.png")
    write_json(
        ICON_COMPOSER / "icon.json",
        {
            "color-space-for-untagged-svg-colors": "display-p3",
            "fill": {"linear-gradient": [srgb_string(CREAM_INNER), srgb_string(CREAM_OUTER)]},
            "groups": [
                {
                    "blend-mode": "normal",
                    "layers": [
                        {
                            "blend-mode": "normal",
                            "fill": "automatic",
                            "glass": True,
                            "hidden": False,
                            "image-name": "brushstroke.png",
                            "name": "Brushstroke",
                        }
                    ],
                    "lighting": "individual",
                    "name": "Brushstroke",
                    "shadow": {"kind": "layer-color", "opacity": 0.35},
                    "specular": True,
                    "translucency": {"enabled": False, "value": 0.5},
                }
            ],
            "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
        },
    )


def install_apple_assets(full_icon: Path, dark_icon: Path, tinted_icon: Path, foreground: Path) -> None:
    copy_file(full_icon, APPLE_ASSETS / "icon-1024.png")
    copy_file(dark_icon, APPLE_ASSETS / "icon-dark-1024.png")
    copy_file(tinted_icon, APPLE_ASSETS / "icon-tinted-1024.png")
    for old_name in APPLE_ASSETS.glob("mac-icon-*.png"):
        old_name.unlink()
    for old_name in ("app-icon-1024.png",):
        (APPLE_ASSETS / old_name).unlink(missing_ok=True)
    mac_sizes = {
        "mac-16.png": (16, 16),
        "mac-32.png": (32, 32),
        "mac-64.png": (64, 64),
        "mac-128.png": (128, 128),
        "mac-256.png": (256, 256),
        "mac-512.png": (512, 512),
        "mac-1024.png": (1024, 1024),
    }
    for name, (width, height) in mac_sizes.items():
        resize_png(full_icon, APPLE_ASSETS / name, width, height)
    write_appiconset_contents()
    write_icon_composer_bundle(foreground)

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
        copy_file(full_mark, EXPORTS / "app-icon-foreground-1024.png")
        dark_back = tmp / "dark-background-1024.png"
        dark_mark = tmp / "mark-dark-1024.png"
        tinted_mark = tmp / "mark-tinted-1024.png"
        render_dark_background_png(dark_back, tmp, SIZE, SIZE)
        recolor_visible_pixels(full_mark, dark_mark, DARK_INK, tmp, "mark-dark")
        composite_images(dark_back, [dark_mark], EXPORTS / "app-icon-dark-1024.png")
        recolor_visible_pixels(full_mark, tinted_mark, TINTED_FOREGROUND, tmp, "mark-tinted")
        run([
            MAGICK,
            "-size",
            f"{SIZE}x{SIZE}",
            f"xc:{TINTED_BACKGROUND}",
            str(tinted_mark),
            "-composite",
            "-strip",
            "-define",
            "png:compression-level=9",
            "PNG24:" + str(EXPORTS / "app-icon-tinted-1024.png"),
        ])
        resize_png(EXPORTS / "app-icon-1024.png", EXPORTS / "app-icon-60.png", 60, 60)
        resize_png(EXPORTS / "app-icon-1024.png", EXPORTS / "app-icon-120.png", 120, 120)
        for name, size in (
            ("mac-16.png", 16),
            ("mac-32.png", 32),
            ("mac-64.png", 64),
            ("mac-128.png", 128),
            ("mac-256.png", 256),
            ("mac-512.png", 512),
            ("mac-1024.png", 1024),
        ):
            resize_png(EXPORTS / "app-icon-1024.png", EXPORTS / name, size, size)
        copy_file(back, EXPORTS / "visionos-back-1024.png")
        copy_file(middle, EXPORTS / "visionos-middle-1024.png")
        copy_file(front, EXPORTS / "visionos-front-1024.png")

        render_tvos_layers(back, middle, front, tmp)
        render_top_shelf(full_mark, tmp)

        resize_png(EXPORTS / "app-icon-1024.png", EXPORTS / "apple-touch-icon-180.png", 180, 180)
        for name, size in (("pwa-icon-192.png", 192), ("pwa-icon-512.png", 512)):
            pwa_back = tmp / f"pwa-background-{size}.png"
            render_background_png(pwa_back, tmp, size, size)
            inset_mark_icon(full_mark, pwa_back, EXPORTS / name, size, tmp, inset_scale=0.78)

        favicon_svg = EXPORTS / "favicon.svg"
        write_favicon_svg(favicon_svg)
        render_favicon_pngs(favicon_svg)
        render_preview_sheet(tmp)
        render_variants_preview_sheet(tmp)

        install_apple_assets(EXPORTS / "app-icon-1024.png", EXPORTS / "app-icon-dark-1024.png", EXPORTS / "app-icon-tinted-1024.png", full_mark)
        install_web_assets()

    print(f"Rendered approved app icon exports and installed checked-in consumers from {EXPORTS}")


if __name__ == "__main__":
    render_all()
