# Lesson figure pipeline

Lesson figures are original SVG sources shared by web and Apple. They are supplemental to the lesson text: each figure needs concise alt text in the lesson reference, and any formula-dense figure needs a text equivalent near the reference.

## Source files

- Put one original SVG source per figure in `content/figures/`.
- Use a stable lower-case id as the filename, for example `ohms-law-triangle.svg`.
- Set the root `<svg id="...">` to the same id as the filename.
- Include `<title>` and `<desc>` in the SVG for authoring context.
- Draw from scratch. Do not trace or copy ISED, RAC, or other third-party reference figures.
- Use labels as SVG `<text>` where feasible so formula labels remain inspectable in the web source. Before review, confirm the generated Apple asset renders every label in the real app screenshots. Apple's CoreSVG path may ignore SVG `font-family` and `font-weight`, so leave enough clearance for a wider fallback font.
- Use `currentColor` for fills and strokes. Do not hard-code colours in SVGs; web and Apple supply ink/paper colours from design tokens.
- Keep all text comfortably inside the `viewBox` with edge margin. The check script estimates text bounds and rejects text that is too close to the edge.
- Keep neighbouring labels separated. Estimated text bounds must not overlap; side-by-side or offset labels keep at least `0.25 × min(font-size)` clearance, while same-anchor vertical stacks may use `0.08 × min(font-size)`.
- No stroke may cross or touch text. Break dividers around labels/formulas or move labels into clear regions. The checker compares estimated text ink against stroked `line`, `polyline`, `polygon`, `rect`, `circle`, `ellipse`, and sampled `path` outlines, including relative path commands.
- Filled `polygon` and `circle` shapes, such as arrowheads or dots, must also stay clear of text ink.
- Keep label text large relative to the `viewBox`: every SVG `<text>` `font-size` must be at least `0.0367 × viewBox width`, which keeps text at least about 11 pt when a figure is displayed 300 pt wide. Use substantially larger text for primary symbol labels. If smaller text is unavoidable, provide an enlarged view and a text equivalent.
- Stay within the SVG subset accepted by `scripts/check-figures.mjs`: no script/style/foreignObject, no event handlers, no external references, no transforms, no marker references, no nested `<svg>`, presentation attributes only, and unitless geometry/text lengths. Use `fill`/`stroke` values of `currentColor` or `none`. The checker intentionally fails unsupported SVG features rather than guessing.

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
- To find P: I x E.
- To find P: I² x R.
- To find P: E² / R.
- To find E: I x R.
- To find E: P / I.
- To find E: √(P x R).
- To find I: E / R.
- To find I: P / E.
- To find I: √(P / R).
- To find R: E / I.
- To find R: E² / P.
- To find R: P / I².
::
```

The directive parser accepts whitespace after `::figure`, case-insensitive `Alt text:`, and `-`, `*`, or `+` bullets for text-equivalent rows. It ignores directives inside fenced code, rejects duplicate figure ids on the same page, and treats an unclosed directive as ending before a blank line or heading so it cannot hide the rest of the lesson. Keep the existing `## Illustration brief` section in the lesson for authors and originality review. Renderers intentionally hide that author brief from learners. When no `::figure ...` directive is present, learners see no placeholder card.

## Web rendering

`apps/web/src/components/MarkdownContent.tsx` parses `::figure` blocks, inlines the matching `content/figures/*.svg` source through Vite `?raw`, and exposes the directive alt text as the image accessible name. The figure container uses `currentColor` and CSS custom properties from `apps/web/src/styles/tokens.css` so light and dark themes use the same source SVG. Formula-dense text equivalents render in a native `<details>` disclosure so learners can open them on demand.

Web sizing comes from the SVG `viewBox`: figures fill the lesson column width and preserve their aspect ratio. Do not add per-figure CSS sizing rules unless a reviewed design exception requires it.

## Apple rendering

SwiftUI cannot render arbitrary SVG files from `content/figures/` at runtime. Instead, run:

```sh
pnpm check:figures:fix
```

That command copies each source SVG into `apps/apple/CanadianHam/Resources/FigureAssets.xcassets/lesson-figure-<id>.imageset/` with preserved-vector and template-rendering asset metadata, and regenerates `apps/apple/CanadianHam/Generated/LessonFigureMetadata.swift` from each SVG `viewBox`. `apps/apple/project.yml` includes the generated asset catalog in the iOS/iPadOS/macOS app target, and XcodeGen includes the generated Swift metadata. `apps/apple/CanadianHam/Views/LearnViews.swift` renders `Image("lesson-figure-<id>")` as a template image tinted with `DesignTokens.Colors.ink`, inside token-coloured paper surfaces, scaled to the available width using the generated aspect ratio. The Enlarge figure button, or double-tapping the image, opens a fitted enlarged sheet with pinch zoom and double-tap zoom. Optional text equivalents render as one formula per row in a SwiftUI `DisclosureGroup`.

Apple's SVG renderer is stricter than browser SVG. Keep to the checked subset above and verify real app screenshots after adding figures. If a future Apple asset drops SVG `<text>`, update `check:figures:fix` to generate Apple-specific outlined text or render labels as SwiftUI text overlays while keeping web source text inspectable.

After changing `apps/apple/project.yml` or adding generated Swift files, regenerate the project from `apps/apple/` with XcodeGen and run it twice to confirm determinism:

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
- SVGs include `<title>`/`<desc>`, avoid hard-coded colours, use only allowed elements/attributes, and have no DOCTYPE/ENTITY/CDATA, script/style/event-handler/external-reference surface;
- estimated text bounds use a monospace-aware width estimate, inherited unitless `font-size`/`font-weight`, bold text, `text-anchor="start|middle|end"`, and simple `<tspan>` runs with explicit `x`/`y` line positions;
- SVG text stays inside the `viewBox` with about `0.25 × font-size` edge clearance and every `<text>` is large enough for the 11 pt at 300 pt display-width minimum;
- estimated text bounds do not overlap each other; side-by-side or offset labels keep at least `0.25 × min(font-size)` clearance, while same-anchor vertical stacks may use `0.08 × min(font-size)`;
- estimated text ink bounds do not intersect stroked `line`, `polyline`, `polygon`, `rect`, `circle`, `ellipse`, or sampled `path` outlines; path checks sample `M/L/H/V/C/Q/S/T/A/Z` commands, absolute or relative, including curves and arcs, and include half the stroke width as padding;
- estimated text ink bounds do not intersect filled `polygon` or `circle` shapes used for arrowheads and dots;
- unsupported SVG features fail loudly instead of being approximated: transforms, CSS `style` or `class`, `<style>`, `<use>`, `<symbol>`, nested `<svg>`, `<textPath>`, `<foreignObject>`, `marker-start|mid|end`, baseline/letter-spacing/text-length text attributes, per-glyph coordinate lists, `dx`/`dy`-only tspans, non-unitless sizes/geometry, and unknown path commands are not allowed; and
- generated Apple vector assets and generated Apple figure metadata are in sync with `content/figures/`.

Content in `<defs>`, `<marker>`, `<clipPath>`, `<mask>`, and `<pattern>` is skipped by geometry checks, except `<style>` remains a failure because it can affect the whole figure. Shape coordinates and stroke widths must be unitless.

Run the checker self-test when changing the checker itself:

```sh
node scripts/check-figures.mjs --self-test
```

`pnpm check:figures` and `node scripts/check-figures.mjs --self-test` are wired into GitHub CI. Use `pnpm check:figures:fix` to regenerate Apple assets, then rerun both commands before committing.

## Contrast and evidence

Figure strokes and text use `currentColor` against token paper surfaces. The rendered figure art sits on paper-inset (`#EFE3CB` light and `#181410` dark) with ink (`#1F1A14` light and `#F3E8D2` dark), giving approximately 13.6:1 in light and 15.1:1 in dark. Evidence previews under `docs/evidence/task-38.1/` wrap the same SVGs in token-coloured backgrounds; the `app/` evidence is exported from real iOS UI-test screenshot attachments.

## Originality note for task-38.1

The three Ohm’s law figures added for task-38.1 (`ohms-law-triangle`, `power-triangle`, and `ohms-law-power-wheel`) were drawn from scratch as simple ink-style memory aids using only the standard public-domain formula relationships already stated in the lesson. They were not traced from ISED reference art or copied from third-party study guides.
