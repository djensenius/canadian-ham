# App icon system

The Canadian Ham icon follows the owner's app family: a sumi-e-inspired black ink mark on a warm cream field with generous breathing room. The approved motif is the round-3 **top-down hex beam**: a brushed hexagon perimeter, six straight dry-brush spreaders, a pressed hub dot, and two pale zigzag W/M wire elements that suggest the antenna wire path without becoming a spider web.

The owner approved `design/app-icon/concepts/01-hex-top` on 2026-10-02. `design/app-icon/render_icon.py` is now the production source of truth; the earlier `render.swift` and committed `src/*.svg` antenna-wave sources were retired because they no longer produce the app icon.

## Source layers

The production renderer builds the mark from deterministic vector brush commands, then rasterizes at the requested export sizes with ImageMagick. The core coordinate system is `0 0 1024 1024`:

- **Back:** opaque warm cream radial field, with no paper grain or tiled texture.
- **Middle:** transparent layer containing only the pale zigzag W/M wire elements.
- **Front:** transparent layer containing the brushed hexagon perimeter, six spreaders, dry-brush tails, splatter, and hub dot.
- **Flattened app/web icons:** back + middle + front composited on the cream field.

Layered tvOS and visionOS exports use these same semantic layers so parallax has meaningful depth: back = cream field, middle = pale wire paths, front = perimeter/spreaders/hub. The hex mark stays inside the visionOS central safe circle and is inset in tvOS image stacks.

## Iteration notes

1. **Round 1:** explored generated ham-radio antenna marks (Yagi/beam, tower, ground-plane, wire/dipole ideas) using the warm cream + sumi-e direction. Critique: the concepts established the family direction but several marks were too hairline-like or too generic at 60 px.
2. **Round 2:** rebuilt the concept renderer around filled brush silhouettes with deterministic pressure, dry-brush hihaku cutouts, and comparison/closeup sheets. Owner steering added a hex-beam candidate, but the first hex-beam read too much like a leaf/cannabis silhouette.
3. **Round 3:** replaced the set with top-down hex-beam studies. The owner selected `01-hex-top`: a clear hex-beam plan view with a brushed hexagon perimeter, six straight spreaders, hub dot, and pale W/M wire elements. This production pass promotes that chosen concept into all export targets.

Current visual critique after regenerating `preview-sheet.png`, `app-icon-1024.png`, `app-icon-60.png`, and `favicon-32.png`: the 1024 icon keeps the selected brush texture and pale W/M wires; the 60 px app icon reduces to a recognizable hex/spoke mark; the 32 px favicon uses a simplified vector hex with spokes and hub; and the 16 px favicon drops fine wire detail for legibility.

## Re-rendering

From the repository root:

```sh
python3 design/app-icon/render_icon.py
```

The script is deterministic for a given ImageMagick version and macOS system fonts (Georgia and Helvetica for the Top Shelf wordmark and preview labels); exports were last rendered with ImageMagick 7.1.2-32. Production renders differ very slightly from the round-3 concept PNG (wire layer order and a 0.6% wire scale), so the files are not byte-identical. It uses ImageMagick (`/opt/homebrew/bin/magick` when available). It rewrites `design/app-icon/exports/`, installs matching PNGs into the Apple asset catalogues, and copies web icons into `apps/web/public/`. It does not change `apps/apple/project.yml` or target membership.

## Exports

Exports are written to `design/app-icon/exports/`.

### iOS, iPadOS, macOS

- `app-icon-1024.png`: flattened opaque 1024 x 1024 PNG; no alpha and no pre-rounded corners.
- `app-icon-60.png` and `app-icon-120.png`: review renders included on the preview sheet to check small-size legibility.

The renderer also installs the flattened icon into the existing Apple `AppIcon.appiconset`, including the existing macOS size slots. This catalogue has no dark/tinted appearance slots, so no new icon mechanism is added.

### visionOS Solid Image Stack

- `visionos-back-1024.png`: opaque cream back layer.
- `visionos-middle-1024.png`: transparent W/M wire layer.
- `visionos-front-1024.png`: transparent perimeter, spreaders, dry-brush tails, splatter, and hub layer.

### tvOS layered app icon

For each stack, the `back` layer is opaque and the `middle`/`front` layers are transparent:

- Small icon @1x: `tvos-small-400x240-{back,middle,front}.png`.
- Small icon @2x: `tvos-small-800x480-{back,middle,front}.png`.
- App Store icon: `tvos-app-store-1280x768-{back,middle,front}.png`.

Top Shelf images:

- `tvos-top-shelf-1920x720.png` and `tvos-top-shelf-3840x1440.png`.
- `tvos-top-shelf-wide-2320x720.png` and `tvos-top-shelf-wide-4640x1440.png`.

The Top Shelf formats place the hex mark on the left with generous cream space and the existing serif “Canadian Ham” wordmark on the right; both standard and wide compositions are generated at their final resolutions so nothing is clipped.

### Web

- `favicon.svg`: simplified adaptive vector hex with perimeter, spokes, hub, and `prefers-color-scheme` dark support.
- `favicon-16.png`, `favicon-32.png`, and `favicon-64.png`: opaque light-mode PNG favicons; no PNG favicon draws the wires, and the 16 px render also drops the spokes, leaving the hex outline and hub for legibility.
- `apple-touch-icon-180.png`.
- `pwa-icon-192.png` and `pwa-icon-512.png`.

The renderer copies these files to `apps/web/public/`. `apps/web/index.html` references the SVG favicon, PNG favicon sizes, and Apple touch icon. The generated web manifest continues to reference the PWA PNG icons.

### Preview

- `preview-sheet.png`: contact sheet showing the main platform exports together for review, including 60 px and 120 px app-icon renders plus 16 px, 32 px, and 64 px favicon renders.

## Icon Composer bundle

An Xcode 26+/27 `.icon` Icon Composer bundle is still not committed because the exact `icon.json` layer-asset format has not been validated in this repository. Follow-up remains: validate the installed Icon Composer format in Xcode's Applications folder and add `design/app-icon/CanadianHam.icon` only after Xcode accepts it.
