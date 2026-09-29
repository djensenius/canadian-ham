# App icon system

The Canadian Ham icon follows the owner's app family: a single sumi-e-inspired ink mark on a warm cream/parchment field with generous breathing room and a small vermilion seal. The motif is a hand-brushed antenna/radio mast emitting three imperfect radio arcs. The owner may replace this programmer-authored SVG with handmade artwork later; the layer contract and export sizes should remain stable.

## Source layers

All SVG sources use a shared `0 0 1024 1024` coordinate system:

- `src/background.svg`: opaque warm paper field with subtle SVG grain.
- `src/waves.svg`: middle transparent layer with variable-width filled radio arcs.
- `src/mast.svg`: front transparent layer with the mast/base brush mark.
- `src/seal.svg`: front transparent vermilion maple-leaf seal accent.

The brush feel is built from filled paths rather than uniform strokes so the silhouette reads at small sizes. Initial exports were reviewed against `/tmp/ch-reviews/style-reference.png` in three passes: first for family fit, second to refine the seal mark, and third to add more breathing room and verify the contact sheet.

## Re-rendering

From the repository root:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift design/app-icon/render.swift
```

The script is zero-dependency Swift using AppKit `NSImage` SVG rendering on macOS. ImageMagick at `/opt/homebrew/bin/magick` may be used as a future fallback if AppKit SVG behaviour changes, but the current renderer does not require it.

## Exports

Exports are written to `design/app-icon/exports/`.

### iOS, iPadOS, macOS

- `app-icon-1024.png`: flattened opaque 1024 x 1024 PNG; no alpha and no pre-rounded corners.

### visionOS Solid Image Stack

- `visionos-back-1024.png`: opaque cream back layer.
- `visionos-middle-1024.png`: transparent waves layer.
- `visionos-front-1024.png`: transparent mast/seal layer.

Key content stays inside the central safe circle for visionOS masking.

### tvOS layered app icon

For each stack, the `back` layer is opaque and the `middle`/`front` layers are transparent:

- Small icon @1x: `tvos-small-400x240-{back,middle,front}.png`.
- Small icon @2x: `tvos-small-800x480-{back,middle,front}.png`.
- App Store icon: `tvos-app-store-1280x768-{back,middle,front}.png`.

Top Shelf images:

- `tvos-top-shelf-1920x720.png` and `tvos-top-shelf-3840x1440.png`.
- `tvos-top-shelf-wide-2320x720.png` and `tvos-top-shelf-wide-4640x1440.png`.

The wide formats compose the mast and waves as an ink-brush landscape with generous cream space.

### Web

- `favicon.svg`: simplified responsive SVG with a dark-mode variant through `prefers-color-scheme`.
- `apple-touch-icon-180.png`.
- `pwa-icon-192.png` and `pwa-icon-512.png`.

### Preview

- `preview-sheet.png`: contact sheet showing the main platform exports together for review.

## Icon Composer bundle

An Xcode 26+/27 `.icon` Icon Composer bundle was not committed because the exact `icon.json` layer-asset format was not validated in this repository. Follow-up: validate the installed Icon Composer format in Xcode's Applications folder and add `design/app-icon/CanadianHam.icon` only after Xcode accepts it.
