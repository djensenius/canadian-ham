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

- every `::figure` lesson reference resolves to `content/figures/<id>.svg`;
- every figure reference has non-empty alt text;
- each SVG filename is a stable id and the root `<svg id>` matches it;
- SVGs avoid hard-coded hex colours and include `<title>`/`<desc>`;
- estimated text bounds stay inside the viewBox with a small edge margin;
- estimated text bounds do not overlap each other; side-by-side or offset labels keep at least `0.25 × min(font-size)` clearance, while aligned vertical stacks may use `0.08 × min(font-size)`;
- estimated text ink bounds do not intersect stroked `line`, `polyline`, `rect`, `circle`, `ellipse`, or sampled `path` outlines; and
- generated Apple vector assets are in sync with `content/figures/`.

The text estimate intentionally errs wide because Apple CoreSVG can ignore SVG font-family and font-weight. It handles `text-anchor="start|middle|end"`, inherited `font-size`/`font-weight`, bold text, and simple `<tspan>` runs. Path stroke checks sample `M/L/H/V/C/Q/A/Z` commands, absolute or relative, including curves and arcs, and include half the stroke width as padding.

`pnpm check:figures` is wired into GitHub CI. Use `pnpm check:figures:fix` to regenerate Apple assets, then rerun `pnpm check:figures` before committing. Use `node scripts/check-figures.mjs --self-test` when changing checker geometry rules.

## Originality note for task-38.1

The three Ohm’s law figures added for task-38.1 (`ohms-law-triangle`, `power-triangle`, and `ohms-law-power-wheel`) were drawn from scratch as simple ink-style memory aids using only the standard public-domain formula relationships already stated in the lesson. They were not traced from ISED reference art or copied from third-party study guides.
