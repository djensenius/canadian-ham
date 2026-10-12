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

The script is deterministic for a given ImageMagick version and macOS system fonts (Georgia and Helvetica for the Top Shelf wordmark and preview labels); exports were last rendered with ImageMagick 7.1.2-32. Production renders differ very slightly from the round-3 concept PNG (wire layer order and a 0.6% wire scale), so the files are not byte-identical. It uses ImageMagick (`/opt/homebrew/bin/magick` when available). It rewrites `design/app-icon/exports/`, installs matching PNGs into the Apple asset catalogues, writes the Icon Composer bundle at `apps/apple/CanadianHam/Resources/AppIcon.icon`, and copies web icons into `apps/web/public/`.

The variants preview uses Xcode's Icon Composer command-line renderer when available at `/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool` (or on `PATH`). Use the same Xcode/OS 27 toolchain as the Apple build checks when reviewing `variants-preview.png`; if `ictool` is unavailable, the renderer prints a warning and falls back to composed appiconset previews instead of OS-rendered `.icon` previews.

## Exports

Exports are written to `design/app-icon/exports/`.

### iOS, iPadOS, macOS

- `app-icon-1024.png`: flattened opaque 1024 x 1024 light PNG; no alpha and no pre-rounded corners. The light design remains the approved task-4 Yagi brush rendering.
- `app-icon-foreground-1024.png`: transparent brushstroke foreground layer for Icon Composer.
- `app-icon-dark-1024.png`: dark-mode fallback with the cream/light mark on the dark warm app field.
- `app-icon-tinted-1024.png`: opaque greyscale tinted fallback with the mark on black, matching Apple's tinted app-icon guidance and the owner's other app catalogues.
- `app-icon-60.png` and `app-icon-120.png`: review renders included on the preview sheet to check small-size legibility.
- `mac-16.png`, `mac-32.png`, `mac-64.png`, `mac-128.png`, `mac-256.png`, `mac-512.png`, and `mac-1024.png`: macOS fallback sizes installed into the appiconset.

The renderer installs the light, dark, tinted, and macOS fallback images into `AppIcon.appiconset` using the same structure as the owner's other apps. It also writes `AppIcon.icon` with the transparent brushstroke layer over a cream gradient fill for Liquid Glass light/dark/clear/tinted rendering on supported Apple platforms.

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
- `pwa-icon-192.png` and `pwa-icon-512.png`: full-size PWA icons for `purpose: "any"`.
- `pwa-maskable-icon-192.png` and `pwa-maskable-icon-512.png`: padded PWA icons with the antenna mark inset into the maskable safe zone for `purpose: "maskable"`.

The renderer copies these files to `apps/web/public/`. `apps/web/index.html` references the SVG favicon, PNG favicon sizes, and Apple touch icon. The generated web manifest references separate full-size `any` PWA PNG icons and padded `maskable` PWA PNG icons.

### Preview

- `preview-sheet.png`: contact sheet showing the main platform exports together for review, including 60 px and 120 px app-icon renders plus 16 px, 32 px, and 64 px favicon renders.
- `variants-preview.png`: task-48 review sheet showing iOS light, dark, tinted, and clear/foreground renderings; the macOS fallback; and the web favicon on light and dark tab bars.

## Icon Composer bundle

The committed Xcode 26+/27 `.icon` bundle lives at `apps/apple/CanadianHam/Resources/AppIcon.icon`. Its structure matches the owner's other apps: `icon.json` plus `Assets/brushstroke.png`, with glass enabled, individual lighting, a layer-colour shadow, and a cream gradient fill from the Canadian Ham palette. The Icon Composer foreground is the approved black brush with a narrow `DARK_INK` cream underlay so `ictool` dark, tinted, and clear OS renders remain legible when OS 27 prefers `AppIcon.icon` over the fallback appiconset. tvOS and visionOS keep their existing layered image-stack assets; dark/tinted app-icon variants are not added there because those platforms use the current layered icon mechanisms rather than the iOS/iPadOS/macOS luminosity appiconset slots.
