# TASK-74 — iPad mock exam accessibility investigation

Investigation on 2026-10-26, iPad Pro 13-inch (M5), iPadOS 27.0 simulator,
portrait, native 2× screenshots. Base: `f3394899`. Work is **In Progress**.
No new accessibility exception has been authorized or implemented.

## Evidence and reproduction

The TASK-44.5 notes were read with `backlog task view task-44.5 --plain`.
There is no separate TASK-44.5 document in `docs/testing`; its per-test results
and original `/tmp/task445-*` artifacts are recorded in that task. The old
exported PNGs still exist locally, but the evidence here was regenerated from
current source, not inferred from those historical results.

All Apple runs use `nohup bash /tmp/task74-<run>.sh` and `xbuild`, polled with
`grep` for test cases, findings and exit status. One destination and one worker
per run. Shared-build-lock waits are allowed to finish; no builds are killed.
Full stdout and explicit result bundles are retained in `/tmp/task74-*`.
Only relevant tests run, not full platform suites.

### Baseline scratch probes (not shipped)

`/tmp/task74-baseline.xcresult`, `/tmp/task74-baseline.log`:

- `CanadianHamExamToolsUITests.testTask74ScratchCaption`: expected FAIL,
  36.304 s; light `Contrast failed`, dark `Contrast nearly passed`, both
  `mock-exam-seed`.
- `CanadianHamExamToolsUITests.testTask74ScratchSheetClipping`: expected FAIL,
  166.569 s; **practice light/dark at 100%/150% all pass `.textClipped`**;
  **mock light/dark at 100%/150% each fail one nil-element `.textClipped`**.
  This probe uses page 4 on both paths and the same Basic question
  `B-001-002-002`, so page and question differences do not confound comparison.
- Total: 2 diagnostic tests, 6 expected audit failures, exit 65.

Scratch probes use `continueAfterFailure = true` to collect the full matrix.
The diagnostic handler logs each issue and element description and always
returns **false** (no ignored findings). Clipping probes request only
`.textClipped` to isolate finding 2, not to certify a full audit. These temporary
tests and every bisection-only app edit are excluded from the final source.

To reproduce: temporarily add a test in `CanadianHamExamToolsUITests` that
launches its existing practice fixture or a 3-question mock with seed
`ui-a11y-mock-exam-timer`, opens the reference tool, taps Next three times,
audits `.textClipped` at 100%, taps Zoom in, then audits again at 150%.
Repeat with light/dark. Attach `app.debugDescription` and `app.screenshot()`
before each audit. Caption probe starts a one-question mock with that same
seed, captures `mock-exam-seed.screenshot()` and audits `.contrast`.
The run selects only `testTask74ScratchCaption` and
`testTask74ScratchSheetClipping` with `-only-testing:` and writes
`-resultBundlePath /tmp/task74-baseline.xcresult`.

Fresh native screenshots and complete reference-sheet hierarchies are checked
in under [`../evidence/task-74/`](../evidence/task-74/); `baseline-findings.txt`
retains issue descriptions, identifiers/nil elements and per-test outcomes.

| Path | Light 100% | Light 150% | Dark 100% | Dark 150% |
| --- | --- | --- | --- | --- |
| Practice | [PNG](../evidence/task-74/baseline-practice-light-100.png) | [PNG](../evidence/task-74/baseline-practice-light-150.png) | [PNG](../evidence/task-74/baseline-practice-dark-100.png) | [PNG](../evidence/task-74/baseline-practice-dark-150.png) |
| Mock | [PNG](../evidence/task-74/baseline-mock-light-100.png) | [PNG](../evidence/task-74/baseline-mock-light-150.png) | [PNG](../evidence/task-74/baseline-mock-dark-100.png) | [PNG](../evidence/task-74/baseline-mock-dark-150.png) |

Each PNG has a same-stem `-hierarchy.txt` file. The nil finding says:
`Text of this SwiftUI.AccessibilityNode may be clipped at larger Dynamic Type sizes.`
It supplies no element, identifier, frame or element screenshot. The whole-app
hierarchy includes both the inspector and the underlying mock, not just the
reference sheet. Therefore the mock-only finding must be bisected before
attributing it to the sheet or to a framework bug.

## Finding 1 — exam-code caption

The caption already uses `DesignTokens.Colors.ink`, the strongest existing ink
token, and `.caption.monospaced()` (13 pt at default size). There is no real
low-contrast colour to replace. Direct measurements of **fresh rendered glyph
cores**, excluding the card border and next heading:

| Appearance | Background RGB | Ink RGB | Exact ink pixels | WCAG ratio |
| --- | --- | --- | --- | --- |
| Light | 255, 248, 234 | 31, 26, 20 | 727 | **16.3364:1** |
| Dark | 42, 36, 29 | 243, 232, 210 | 727 | **12.6297:1** |

[Light crop](../evidence/task-74/baseline-light-caption.png),
[dark crop](../evidence/task-74/baseline-dark-caption.png);
full screenshots are `baseline-{light,dark}-screen.png`.
`caption-pixel-measurements.json` records PNG SHA-256, pixel counts, exact
native crop bounds `(30,30)–(540,61)` and unrounded ratios. The 568×92 element
PNG includes a border and part of the next heading because the text-selection
accessibility frame exceeds the glyph bounds; those pixels are deliberately
excluded from the measurement. The glyph-only rectangle contains 1,661 light /
1,847 dark pixels with contrast ≥4.5:1, not merely a single extreme pixel.

Measurement is reproducible with Python/Pillow: read the PNG as RGB, crop the
above bounds, use `collections.Counter` to identify the dominant background
and next most common colour (the ink cores). Linearize each sRGB component
`c/255` with `c/12.92` for `c <= 0.04045`, else `((c+0.055)/1.055)^2.4`;
relative luminance is `0.2126 R + 0.7152 G + 0.0722 B`; ratio is
`(Llighter+0.05)/(Ldarker+0.05)`. Core RGBs agree exactly with semantic tokens.
Antialiased edge pixels are blends, not the text's specified ink colour.

Conclusion: the reported contrast failure is consistent with the known
[TASK-73 thin 2× stroke limitation](task-73-contrast-2x-blocked.md), not a
<4.5:1 ink/background pair. No weight/colour/layout change is justified solely
to appease that measurement. There is no before/after visual change.
**Owner decision required:** whether to authorize a narrowly scoped verified
contrast treatment for this non-button caption, or commission a separately
approved design/measurement change. TASK-71/73 scopes are not extended here.

## Finding 2 — nil-element clipping

Bisection and remediation results pending. Practice is clean in the fresh
page-4 100%/150% light/dark clipping matrix; mock fails in all four states.
No nil-element exception is added, and the iPhone medium-detent rule is not
used on iPad.

## Finding 3 — legacy Questions assumptions

The actual `MockExamView` uses a Questions sheet only at compact horizontal
size class. At regular width its question navigator is **inline below the
answers**, not a sidebar/inspector question list. The tests must use that real
layout rather than invent a compact control on iPad. Implementation/validation
results pending. Every existing audit and behavior assertion is retained;
layout-equivalent navigator reachability/usability replaces the nonexistent
regular-width Questions button assertion.

The eventual PR needs `Test-guard-approved: task-74` for intentional audit-test
structure changes. No PR is created by this worker.

## Final validation

Pending targeted iPad tests, affected iPhone tests, macOS compilation, text
sources, localization and test guard. tvOS, visionOS and watchOS suites are not
run for this targeted iPad investigation; any shared app change must be
accounted for in the coordinator's merge-batch platform selection.
