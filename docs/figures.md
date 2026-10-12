# Lesson figure pipeline

Lesson figures are original SVG sources shared by web and Apple. They are supplemental to the lesson text: each figure needs concise alt text in the lesson reference, and any formula-dense figure needs a text equivalent near the reference.

## Source files

- Put one original SVG source per figure in `content/figures/`.
- Use a stable lower-case id as the filename, for example `ohms-law-triangle.svg`.
- Set the root `<svg id="...">` to the same id as the filename.
- Include `<title>` and `<desc>` in the SVG for authoring context.
- Draw from scratch. Do not trace or copy ISED, RAC, or other third-party reference figures.
- Use labels as SVG `<text>` where feasible so formula labels remain inspectable in source.
- Use `currentColor` for fills and strokes. Do not hard-code colours in SVGs; web and Apple supply ink/paper colours from design tokens.

## Referencing a figure from a lesson

Use a small block directive in lesson Markdown:

```md
::figure ohms-law-triangle
Alt text: Ohm’s law triangle with E above I and R, showing E = I x R, I = E / R, and R = E / I.
::
```

For a dense formula figure, add a text equivalent inside the same directive:

```md
::figure ohms-law-power-wheel
Alt text: Ohm’s law and power wheel with quadrants for P, E, I, and R and three formulas in each quadrant.
Text equivalent:
- To find P: I x E; I² x R; E² / R.
- To find E: I x R; P / I; √(P x R).
- To find I: E / R; P / E; √(P / R).
- To find R: E / I; E² / P; P / I².
::
```

Keep the existing `## Illustration brief` section in the lesson for authors and originality review. Renderers intentionally hide that author brief from learners. When no `::figure ...` directive is present, learners see no placeholder card.

## Web rendering

`apps/web/src/components/MarkdownContent.tsx` parses `::figure` blocks, inlines the matching `content/figures/*.svg` source through Vite `?raw`, and exposes the directive alt text as the image accessible name. The figure container uses `currentColor` and CSS custom properties from `apps/web/src/styles/tokens.css` so light and dark themes use the same source SVG. Formula-dense text equivalents render in a native `<details>` disclosure so learners can open them on demand.

## Apple rendering

SwiftUI cannot render arbitrary SVG files from `content/figures/` at runtime. Instead, run:

```sh
pnpm check:figures:fix
```

That command copies each source SVG into `apps/apple/CanadianHam/Resources/FigureAssets.xcassets/lesson-figure-<id>.imageset/` with preserved-vector and template-rendering asset metadata. `apps/apple/project.yml` includes that generated asset catalog in the iOS/iPadOS/macOS app target. `apps/apple/CanadianHam/Views/LearnViews.swift` renders `Image("lesson-figure-<id>")` as a template image tinted with `DesignTokens.Colors.ink`, inside token-coloured paper surfaces. Optional text equivalents render in a SwiftUI `DisclosureGroup`.

After changing `apps/apple/project.yml`, regenerate the project from `apps/apple/` with XcodeGen and run it twice to confirm determinism:

```sh
cd apps/apple && /opt/homebrew/bin/xcodegen generate --spec project.yml
cd apps/apple && /opt/homebrew/bin/xcodegen generate --spec project.yml
git diff -- apps/apple/CanadianHam.xcodeproj
```

## Checks

Run the figure check from the repository root:

```sh
pnpm check:figures
```

The check verifies:

- every `::figure` lesson reference outside fenced code resolves to `content/figures/<id>.svg`;
- every figure reference has non-empty alt text and no duplicate figure id on the same page;
- each SVG filename is a stable id and the root `<svg id>` matches it;
- SVGs include `<title>`/`<desc>`, avoid hard-coded colours, use only allowed elements/attributes, and have no script/style/event-handler/external-reference surface;
- every SVG `<text>` `font-size` is large enough for about 11 pt text at 300 pt display width;
- estimated text bounds stay inside the viewBox with about `0.25 × font-size` edge clearance;
- estimated text bounds do not overlap each other; side-by-side or offset labels keep at least `0.25 × min(font-size)` clearance, while same-anchor vertical stacks may use `0.08 × min(font-size)`;
- estimated text ink bounds do not intersect stroked `line`, `polyline`, `polygon`, `rect`, `circle`, `ellipse`, or sampled `path` outlines;
- estimated text ink bounds do not intersect filled `polygon` or `circle` shapes used for arrowheads and dots; and
- generated Apple vector assets and generated Apple figure metadata are in sync with `content/figures/`.

The text estimate intentionally errs wide for both the web's requested monospace font and Apple's CoreSVG fallback: character widths use the larger of the proportional estimate and `0.6 × character count × font-size`. It handles `text-anchor="start|middle|end"`, inherited `font-size`/`font-weight`, bold text, and simple `<tspan>` runs. Path stroke checks sample `M/L/H/V/C/Q/S/T/A/Z` commands, absolute or relative, including curves and arcs, and include half the stroke width as padding. The checker intentionally fails unsupported SVG features rather than guessing: transforms, CSS `style` or `class`, `<use>`, `<symbol>`, nested `<svg>`, `<textPath>`, `<foreignObject>`, baseline/letter-spacing/text-length text attributes, per-glyph coordinate lists, non-unitless font sizes, and unknown path commands are not allowed. Content in `<defs>`, `<marker>`, `<clipPath>`, `<mask>`, and `<pattern>` is skipped.

`pnpm check:figures` and `node scripts/check-figures.mjs --self-test` are wired into GitHub CI. Use `pnpm check:figures:fix` to regenerate Apple assets and metadata, then rerun both commands before committing. Use the self-test when changing checker geometry rules.

## Contrast and evidence

Figure strokes and text use `currentColor` against token paper surfaces. The rendered figure art sits on paper-inset (`#EFE3CB` light and `#181410` dark) with ink (`#1F1A14` light and `#F3E8D2` dark), giving approximately 13.6:1 in light and 15.1:1 in dark. Evidence previews under `docs/evidence/task-38.1/` wrap the same SVGs in token-coloured backgrounds; the `app/` evidence is exported from real iOS UI-test screenshot attachments.

## Originality note for task-38.1

The three Ohm’s law figures added for task-38.1 (`ohms-law-triangle`, `power-triangle`, and `ohms-law-power-wheel`) were drawn from scratch as simple ink-style memory aids using only the standard public-domain formula relationships already stated in the lesson. They were not traced from ISED reference art or copied from third-party study guides.

## Originality note for task-38.4

The ten lesson figures added for task-38.4 (`transformer-resonance-meters`, `feedline-types-balun`, `swr-loss-matching`, `yagi-vertical-length`, `loop-antenna-patterns`, `propagation-paths-skip-zone`, `daytime-absorption-frequency-window`, `vhf-unusual-propagation-modes`, `interference-troubleshooting-map`, and `filter-response-sketches`) were drawn from scratch as simplified ink-style teaching diagrams based on the original lesson prose and standard circuit, antenna, propagation, and filter concepts. They were not traced from ISED reference art, RAC material, or third-party study guides.
