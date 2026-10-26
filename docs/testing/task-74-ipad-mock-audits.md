# TASK-74 — iPad mock exam accessibility investigation

Investigation on 2026-10-26, iPad Pro 13-inch (M5), iPadOS 27.0 simulator,
portrait, native 2× screenshots. Base: `f3394899`. All findings are **resolved and locally validated**.
No new audit handler, algorithm change or waiver is used. The caption and header
fixes are structural; existing shared helpers remain unchanged.

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

### Root cause and structural fix

The actual root cause was the **oversized selectable-text accessibility frame**,
not low-contrast ink. The unchanged whole-image measurement on the original
568×92 PNG reports **4.10405:1 light / 3.55363:1 dark**, because the card border
and next heading are included. Glyph-only measurement is useful diagnosis, not
a substitute for that fail-closed whole-image verdict. This initially resembled
the [TASK-73 thin 2× stroke limitation](task-73-contrast-2x-blocked.md), but a
structural correction removes the ambiguity without a contrast exception.

The caption keeps `.textSelection(.enabled)`, its font, weight, ink and layout.
Adding `.contentShape(.accessibility, Rectangle())` confines its accessibility
shape to its own line box. On iPad the frame changes from
`(60,110,284.5,46.5)` to `(76,126,252.5,14.5)` points; the exported PNG changes
from **568×92 to 504×28**. The unchanged whole-image helper now measures
**16.3364:1 light / 12.6286:1 dark** without a crop. No helper/threshold change,
non-button crop, new handler or measured-composite call is necessary. The
coordinator's provisional measured-scope approval was superseded by this fix;
no such scope line is added to AGENTS.md.

Fresh plain contrast probes pass both appearances on iPad (33.361 s) and
iPhone (52.534 s). The new committed regression
`testMockExamCodeCaptionAccessibilityBoundsLightAndDark` checks that the
caption frame does not overlap the next heading, retains caption PNG/hierarchy
attachments, and runs **plain full-default audits**. Its first iPad run passes
both light/dark in 30.781 s.

**Appearance is unchanged, exactly:** `caption-visual-diff.json` records the
native RGB comparisons and screenshot SHA-256 values. On iPad the entire
header-card rectangle `(118,218)–(1946,568)` has **0 differing pixels**, light
and dark. On iPhone the whole visible app-content region
`(0,390)–(1206,2382)` (which includes the entire card) has **0 differing
pixels**, light and dark. Only OS/navigation chrome outside those rectangles
is excluded. Before/after PNGs are `baseline-{light,dark}-screen.png` /
`caption-shape-ipad-{light,dark}-screen.png`, and
`caption-iphone-{before,after}-{light,dark}-screen.png`.

The host check `/tmp/task74-measure-existing.swift` copies the unchanged
measurement functions, without algorithm edits; outputs are
`/tmp/task74-existing-measurement.log` and the tight-frame ratios above.
Pillow verification is `ImageChops.difference(before.crop(box), after.crop(box))`:
`getbbox()` is `None`, channel extrema are all `(0,0)` and differing-pixel
count is zero in each comparison.

## Finding 2 — nil-element clipping

Bisection (all temporary source changes, no ignored issues):

| Scratch variant | Before inspector | Mock light 100% | Mock light 150% |
| --- | --- | --- | --- |
| Omit only inline navigator | Pass | Fail, nil textClipped | Fail, nil textClipped |
| Omit entire mock header | Pass | Pass | Pass |
| Omit only caption | Pass | Fail, nil textClipped | Fail, nil textClipped |
| Omit only header controls | Pass | Pass | Pass |
| Omit only timer controls | Pass | Pass | Pass |
| Force outer horizontal candidate to its ideal width | Pass | Fail, nil textClipped | Fail, nil textClipped |
| Keep only the already-selected outer vertical candidate | Pass | Pass | Pass |

Bundles/logs: `/tmp/task74-{no-navigator,no-header,no-caption,no-controls,no-timer,header-ideal,header-vertical}.{xcresult,log}`.
`bisection-findings.txt` retains outcomes and full issue descriptions. Each
variant has a `bisect-<variant>.png` / `.txt` pair for the 100% screenshot and
full hierarchy. The clipping issue is isolated to the **rejected horizontal
candidate of the outer mock header's ViewThatFits**, not official sheet text,
page image, attribution, text-equivalent toggle, caption or navigator.

The vertical-only scratch screen is **pixel-identical** to the baseline in
the entire visible app region `(0,172)–(2064,2700)`: see
`bisection-vertical-visual-diff.json`. All displayed text/control frames are
intact. The audit leaks a clipped SwiftUI node from a rejected layout candidate
and supplies no corresponding element. The vertical-only experiment is **not
shipped**: making the header always vertical would change wider layouts.

Coordinator direction 2026-10-26 applies the owner's existing **2026-10-18
single-tree adaptive-layout rule**. The final replacement follows
`LessonQuizControlLayout` in `LearnViews.swift`: a private
`MockExamHeaderControlLayout` delegates to `HStackLayout` when the children's
measured ideal width fits the proposed width, otherwise to the same leading
`VStackLayout`. Both use the existing `Spacing.sm`; horizontal alignment stays
centered. Accessibility Dynamic Type keeps its existing forced-vertical layout.
There are **no point-width thresholds and no duplicate candidate child trees**.
Only the outer header layout is replaced; the existing inner controls stay
unchanged. Appearance matrix and full-audit validation pass; details follow.

All TASK-44.5 iPad audit calls are now restored, including raw full audits in
the inspector. Mock and practice coverage additionally audit the 100% image
state, without replacing their existing 150% checks. The nil-element finding
is not ignored; no medium-detent rule is applied to iPad and no new handler
is introduced. The temporary AGENTS.md limitation is removed after successful targeted validation;
no measured-composite scope is added.

## Finding 3 — legacy Questions assumptions

The actual `MockExamView` uses a Questions sheet only at compact horizontal
size class. At regular width its question navigator is **inline below the
answers**, not a sidebar/inspector question list. The tests must use that real
layout rather than invent a compact control on iPad.

`showMockExamQuestionNavigator` uses the real Questions button when present;
otherwise it scrolls to the inline navigator. It asserts the heading exists
and is fully visible/hittable, and retains a screenshot. The largest-type test
also checks that the flagged current question is reachable, tappable and
preserves the current question. Its first iPad attempt exposed a test-positioning
issue: the heading was visible but the LazyVGrid's question item was still below
the fold and unmaterialized. It now scrolls until that exact flagged/current
item exists, then retains every existence/hittability/state assertion and a
screenshot before tapping. The focused rerun passes (52.183 s). The flow tests
return from a compact sheet with Done, or scroll regular-width content back to
the navigation controls.
**Every existing audit call/type and behavior assertion is retained.** Only
the nonexistent regular-width Questions-button requirement is replaced by
layout-equivalent inline navigation assertions; compact reachability/usability
is still checked. Final targeted validation passes on both devices.

Per coordinator direction, the eventual PR needs the approval line
`Test-guard-approved: owner decision 2026-10-22` for intentional audit-test
structure/restoration changes. The guard reports exactly three enclosing
functions in `CanadianHamExamToolsUITests`: the practice reference matrix
(added 100% full audit), the new caption-bound/full-audit regression, and the
mock reference verifier (removed iPad audit gates; added 100% full audit).
The legacy flow's navigation structure changes are also explicitly disclosed
above, even though their unchanged audit calls do not trigger the heuristic.
No audit type/call is removed or narrowed; no handler or ignore rule is added.
`28` named pre-existing audit/positioning/wrapper definitions and the entire
`UITestContrastMeasurement.swift` are byte-identical to `f3394899`.
No PR is created by this worker.

### Scoped follow-through: compact navigator at AX-XXXL

The first iPhone final run passed eight product methods, but the largest-type
legacy method exposed a real pre-existing defect in the **unchanged compact
navigator sheet**: its non-scrolling VStack compressed the heading and buttons,
so Next unanswered overlapped Question navigator. The new stricter assertion
caught it; no baseline assertion/audit was removed. The original method only
checked that the heading existed after opening Questions.

[`compact-navigator-ax-before-video-frame.png`](../evidence/task-74/compact-navigator-ax-before-video-frame.png)
is an extracted frame from the automatic screen recording in
`/tmp/task74-iphone-final.xcresult`, not a lossless pixel-measurement fixture.
The source recording is
`/tmp/task74-iphone-largest-failure/BF1A8D8E-4F77-4703-B6CC-DC9C05BDA8EC.mp4`.

Coordinator direction explicitly approved a small container-only repair here,
with a stop boundary of about 30 lines and no shared navigator-logic changes.
The repair is **17 additions / 6 deletions (including its explanatory comment)**: extract the identical existing
VStack into `navigatorSheetContent` and wrap it in a ScrollView only at
accessibility Dynamic Type sizes. Default-size layout remains the same VStack;
font/weight/colours, question-selection logic, Done action and regular inline
navigator are unchanged. The heading can now take its natural line height
and the entire list remains reachable by scrolling instead of compressing.

Both compact and inline paths retain the stronger fully-visible/hittable
heading and flagged-current-item assertions. Compact visibility correctly uses
the modal window below the status bar, not the **covered root navigation bar**;
regular inline visibility still uses the existing protected-navigation geometry.
The shared helpers are not modified. Default navigator PNGs are compared from
the unchanged light/dark mock-flow fixtures before/after this repair.
All four comparisons have **zero differing pixels**, including the entire
modal below the 62 pt status bar: `navigator-default-visual-diffs.json` records
both PNGs, hashes and native bounds. The strict iPhone largest-header test and
both flow reruns pass (76.546 / 130.148 / 156.702 s); the final iPad nine-method
set also passes. The new scrolling layout's
[heading](../evidence/task-74/compact-navigator-ax-after-heading.png) and
[reachable flagged current item](../evidence/task-74/compact-navigator-ax-after-current-question.png)
are retained as native PNGs. No follow-up or exception is needed.


## Appearance parity and evidence integrity

The caption-only structural change is measured independently in four light/dark
comparisons above. The header replacement is isolated separately: BEFORE uses
the original outer `ViewThatFits` with the caption fix retained; AFTER uses the
new fitting layout with the same fixture and caption. This avoids attributing
one structural change's effect to another.

`header-layout-visual-diffs.json` records **12/12 zero-difference** native RGB
comparisons for the complete visible app body below its unchanged navigation
bar. All have matching window/navigation geometry. `caption-visual-diff.json`
records four more zero-difference comparisons, and
`navigator-default-visual-diffs.json` records four modal comparisons: **20/20
final appearance comparisons are pixel-identical**, without an antialiasing
allowance. Each record contains exact native rectangles and both PNG SHA-256s.

| Device / header case | Before | After | Different pixels |
| --- | --- | --- | --- |
| ipad `portrait-AXXXL-dark` | [PNG](../evidence/task-74/header-before-ipad-portrait-AXXXL-dark.png) | [PNG](../evidence/task-74/header-after-ipad-portrait-AXXXL-dark.png) | 0 |
| ipad `portrait-AXXXL-light` | [PNG](../evidence/task-74/header-before-ipad-portrait-AXXXL-light.png) | [PNG](../evidence/task-74/header-after-ipad-portrait-AXXXL-light.png) | 0 |
| ipad `portrait-default-dark-inspector` | [PNG](../evidence/task-74/header-before-ipad-portrait-default-dark-inspector.png) | [PNG](../evidence/task-74/header-after-ipad-portrait-default-dark-inspector.png) | 0 |
| ipad `portrait-default-dark` | [PNG](../evidence/task-74/header-before-ipad-portrait-default-dark.png) | [PNG](../evidence/task-74/header-after-ipad-portrait-default-dark.png) | 0 |
| ipad `portrait-default-light-inspector` | [PNG](../evidence/task-74/header-before-ipad-portrait-default-light-inspector.png) | [PNG](../evidence/task-74/header-after-ipad-portrait-default-light-inspector.png) | 0 |
| ipad `portrait-default-light` | [PNG](../evidence/task-74/header-before-ipad-portrait-default-light.png) | [PNG](../evidence/task-74/header-after-ipad-portrait-default-light.png) | 0 |
| iphone `landscape-default-dark` | [PNG](../evidence/task-74/header-before-iphone-landscape-default-dark.png) | [PNG](../evidence/task-74/header-after-iphone-landscape-default-dark.png) | 0 |
| iphone `landscape-default-light` | [PNG](../evidence/task-74/header-before-iphone-landscape-default-light.png) | [PNG](../evidence/task-74/header-after-iphone-landscape-default-light.png) | 0 |
| iphone `portrait-AXXXL-dark` | [PNG](../evidence/task-74/header-before-iphone-portrait-AXXXL-dark.png) | [PNG](../evidence/task-74/header-after-iphone-portrait-AXXXL-dark.png) | 0 |
| iphone `portrait-AXXXL-light` | [PNG](../evidence/task-74/header-before-iphone-portrait-AXXXL-light.png) | [PNG](../evidence/task-74/header-after-iphone-portrait-AXXXL-light.png) | 0 |
| iphone `portrait-default-dark` | [PNG](../evidence/task-74/header-before-iphone-portrait-default-dark.png) | [PNG](../evidence/task-74/header-after-iphone-portrait-default-dark.png) | 0 |
| iphone `portrait-default-light` | [PNG](../evidence/task-74/header-before-iphone-portrait-default-light.png) | [PNG](../evidence/task-74/header-after-iphone-portrait-default-light.png) | 0 |

Two initial AFTER captures were not settled: the first iPad light inspector was
sampled during its slide-in animation, and the first iPhone light AX capture
still displayed a transient 9 px scroll indicator outside the card. Neither
changed any header pixel. The individual cases were recaptured after the page
loaded / 1.2 s settling and after the scrollbar faded / 2 s respectively; the
original bundles remain `/tmp/task74-ipad-final.xcresult` and
`/tmp/task74-iphone-final.xcresult`. Correct settled captures are in
`/tmp/task74-ipad-settled.xcresult` (32.629 s) and
`/tmp/task74-iphone-settled.xcresult` (68.186 s); the JSON identifies those bundle
overrides. No product layout or audit was changed to obtain a screenshot.

The appearance probes are temporary, not committed. All scratch tests/layout
bisections are removed. Only native PNGs, relevant full hierarchies, issue notes
and numeric evidence are retained. `evidence-manifest.json` enumerates every
artifact with its SHA-256 and size (excluding the manifest's own recursive hash).

To independently verify any metric (Python/Pillow):

```python
from PIL import Image, ImageChops
before = Image.open(before_path).convert("RGB")
after = Image.open(after_path).convert("RGB")
diff = ImageChops.difference(before.crop(tuple(native_box)), after.crop(tuple(native_box)))
assert diff.getbbox() is None
```

Use the exact PNG names and `nativeBodyBoxXYXY` / `nativeComparisonBoxXYXY`
rectangles in the corresponding JSON. Source code milestones are
`4c7a437c` (caption/header/audit restoration) and `3eec51d4` (small compact AX
scrolling repair). No shared helper, measured-contrast algorithm or approved
exception scope changed.

## Final validation

All nine product UI methods are green on each requested device. iPad's latest
nine-method run includes the compact-container revision; iPhone uses the six
unaffected exam-tool/caption methods from its full run plus the three affected
practice methods rerun after the compact repair. No skipped product methods.
The earlier failed diagnostics and two test/fixture iterations are disclosed
below, not counted as final passes.

### Per-test product UI results

`ET` = `CanadianHamExamToolsUITests`; `P` = `CanadianHamPracticeUITests`.
Every row runs as `CanadianHamUITests/<class>/<method>`.

| Class / method | iPad Pro 13-inch (M5) | iPhone 17 Pro |
| --- | --- | --- |
| `ET.testAdvancedMockExamHasNoBasicReferenceSheetOrHints` | PASS 17.885 s | PASS 38.965 s |
| `ET.testMockExamCodeCaptionAccessibilityBoundsLightAndDark` | PASS 30.748 s | PASS 51.305 s |
| `ET.testMockExamOfficialReferenceSheetDarkPreservesPausedExam` | PASS 102.097 s | PASS 203.124 s |
| `ET.testMockExamOfficialReferenceSheetLightPreservesRunningExam` | PASS 101.353 s | PASS 210.034 s |
| `ET.testOfficialReferenceSheetLightAndDarkEnglishAndFrench` | PASS 208.247 s | PASS 261.846 s |
| `ET.testReferenceSheetLargestDynamicTypeKeepsControlsReachable` | PASS 38.385 s | PASS 135.597 s |
| `P.testAccessibilityAuditMockExamFlowDark` | PASS 100.294 s | PASS 156.702 s |
| `P.testAccessibilityAuditMockExamFlowLight` | PASS 97.460 s | PASS 130.148 s |
| `P.testMockExamHeaderControlsSupportLargestAccessibilityTextSize` | PASS 51.171 s | PASS 76.546 s |

### Run ledger and command reproduction

All runners were launched with `nohup`, polled with grep, used `xbuild`, and
waited for the shared lock. Logs/result bundles are explicit `/tmp` paths, so
Xcode's rolling DerivedData test retention does not rotate them away.

| Run | Selection / outcome | Log and result bundle stem |
| --- | --- | --- |
| Initial iPad final-layout run | 8 product passes + AX clipping probe pass; largest-header lazy item not materialized (fixed) | `/tmp/task74-ipad-targeted` |
| Focused iPad rerun | largest-header PASS 52.183 s; header capture PASS 81.876 s | `/tmp/task74-ipad-final` |
| iPhone full run | 8 product passes + header capture PASS 180.736 s; largest-header exposed compact AX overlap (fixed) | `/tmp/task74-iphone-final` |
| iPhone compact repair rerun | both mock flows and largest-header: 3/3 PASS | `/tmp/task74-iphone-compact` |
| Final iPad set | all 9 product methods PASS on the final container revision | `/tmp/task74-ipad-compact` |
| macOS units / UI-test compilation | 223/223 PASS, 20.971 s test runtime | `/tmp/task74-macos-final` |
| Latest macOS `build-for-testing` | PASS after compact-container repair; UI-test target compiles | `/tmp/task74-macos-build.log` |

For each stem above, stdout is `<stem>.log` and test results are
`<stem>.xcresult` (except the explicitly named build-only log).

Every UI runner exports:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export XBUILD_TEST_WORKERS=1
```

Then calls the following template, adding one `-only-testing:` for each selected
row above (all nine for `/tmp/task74-ipad-compact`, only the three `P` rows for
`/tmp/task74-iphone-compact`). The earlier iPhone full run selected all nine
plus the temporary header-appearance capture, which is not committed.

```sh
xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testMockExamCodeCaptionAccessibilityBoundsLightAndDark \
  -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testAdvancedMockExamHasNoBasicReferenceSheetOrHints \
  -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetDarkPreservesPausedExam \
  -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetLightPreservesRunningExam \
  -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testOfficialReferenceSheetLightAndDarkEnglishAndFrench \
  -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testReferenceSheetLargestDynamicTypeKeepsControlsReachable \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowDark \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowLight \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testMockExamHeaderControlsSupportLargestAccessibilityTextSize \
  -resultBundlePath /tmp/task74-ipad-compact.xcresult test CODE_SIGNING_ALLOWED=NO
# iPhone destination: 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Exact executed runners remain `/tmp/task74-{ipad-targeted,final-ui,compact-reruns}.sh`.
The selected methods and destinations are fully specified by the table/ledger;
no full iOS suite, extra destination, or simulator was booted by hand.

macOS commands (both compile `CanadianHamUITests`, but do not run it):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests \
  -resultBundlePath /tmp/task74-macos-final.xcresult test \
  SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests \
  build-for-testing SDKROOT=macosx SUPPORTED_PLATFORMS=macosx \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

The first macOS attempt was blocked by an **uncommitted diagnostic probe**
using the iOS-only `.textClipped` audit-type constant. That temporary method was
removed; the retry compiled the UI-test target and passed all 223 units. The
latest UI-container revision was then compiled with `build-for-testing`; no
unit/model logic changed. Expected corrupt-store Core Data error logging comes
from negative migration tests, all of which pass. Post-test `simctl` lookup
warnings do not change the recorded test results/exit status.

### Static / localization / guard checks

- `pnpm check:apple-l10n`: PASS (`/tmp/task74-l10n.log`, exit 0). Includes
  localization export and generic tvOS/visionOS/watchOS builds; catalogues stay
  byte-identical. No translated UI string or official question text changed.
- `node scripts/check-apple-text-sources.ts`: PASS (`/tmp/task74-text-sources.log`).
- `node scripts/check-test-guard.mjs --self-test`: PASS
  (`/tmp/task74-guard-self-test.log`).
- `TEST_GUARD_PR_BODY='Test-guard-approved: owner decision 2026-10-22' node scripts/check-test-guard.mjs --base f3394899 --head HEAD`:
  PASS with the intentional findings/approval described above (`/tmp/task74-guard.log`).
- Shared-helper byte comparison: PASS (`/tmp/task74-shared-helpers.log`),
  28 named definitions plus the entire measurement source unchanged.
- `git diff --check`: PASS. No scratch test/app layout, new exception, changed
  audit handler, hard-coded colour, hidden visible text, minimum scale factor,
  or algorithm/threshold change ships.

`project.yml` target membership confirms `StudyViews.swift` belongs only to the
shared iOS/macOS `CanadianHam` app target, not the TV, vision or watch targets.
Those platforms' suites are not run for this change; their generic builds run
as part of the explicitly requested localization check. Full iOS suites remain
the coordinator's merge-batch responsibility, per project testing policy.
No PR or distribution build is created by this worker.

### macOS unit per-test results

<details>
<summary>223 existing unit methods, all passed (seconds)</summary>

| Method | Result | Seconds |
| --- | --- | --- |
| `CanadianHamTests.DuoLayoutPolicyTests.testCompactWidthIPhoneKeepsSheetPolicy` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testIPadInspectorRuleRemainsSizeClassDriven` | PASS | 0.000 |
| `CanadianHamTests.DuoLayoutPolicyTests.testMacAndOtherIdiomsNeverUseIPhonePolicy` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds` | PASS | 0.000 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes` | PASS | 0.000 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testKeyHandlingProducesEngineDisplayAndSpokenResult` | PASS | 0.000 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testOfficialReferenceSheetGateAndBundledPages` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testQuestionCardFocusResetKeepsTextSelectionEnabled` | PASS | 0.005 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine` | PASS | 0.006 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekEndsWhenPhoneFullyOpensOrCloses` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekFastUnfoldThroughBandNeverPeeks` | PASS | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekLeavingToleranceDoesNotResetDismissalSuppression` | PASS | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility` | PASS | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` | PASS | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` | PASS | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` | PASS | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` | PASS | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` | PASS | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` | PASS | 0.395 |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute` | PASS | 0.293 |
| `CanadianHamTests.HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` | PASS | 0.002 |
| `CanadianHamTests.HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` | PASS | 2.544 |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata` | PASS | 0.003 |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection` | PASS | 0.002 |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusMapsShuffledSourceChoices` | PASS | 0.003 |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext` | PASS | 0.002 |
| `CanadianHamTests.LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations` | PASS | 0.009 |
| `CanadianHamTests.LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` | PASS | 0.004 |
| `CanadianHamTests.LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides` | PASS | 0.001 |
| `CanadianHamTests.LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish` | PASS | 0.000 |
| `CanadianHamTests.LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale` | PASS | 0.003 |
| `CanadianHamTests.LocalizationCatalogTests.testReviewHeadingMarksEnglishFallbackTitleInsideFrenchText` | PASS | 0.001 |
| `CanadianHamTests.LocalizationCatalogTests.testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testFixedTimingProfilesUseEngineValues` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testLessonBodyAndBulletContrastTokensMeetMinimumRatio` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession` | PASS | 1.694 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas` | PASS | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints` | PASS | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` | PASS | 0.105 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesPressWhenAudioFails` | PASS | 0.006 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended` | PASS | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError` | PASS | 0.105 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone` | PASS | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReleaseCannotBeSupersededBySilence` | PASS | 0.004 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress` | PASS | 0.104 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError` | PASS | 0.106 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsClampAndPreset` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` | PASS | 0.008 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults` | PASS | 0.004 |
| `CanadianHamTests.MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | PASS | 0.041 |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon` | PASS | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` | PASS | 0.074 |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts` | PASS | 0.025 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` | PASS | 0.005 |
| `CanadianHamTests.ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` | PASS | 0.021 |
| `CanadianHamTests.ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields` | PASS | 0.031 |
| `CanadianHamTests.ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` | PASS | 0.030 |
| `CanadianHamTests.ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` | PASS | 0.022 |
| `CanadianHamTests.ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` | PASS | 0.057 |
| `CanadianHamTests.ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem` | PASS | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory` | PASS | 0.065 |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete` | PASS | 0.026 |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` | PASS | 0.036 |
| `CanadianHamTests.ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent` | PASS | 0.002 |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` | PASS | 0.049 |
| `CanadianHamTests.ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` | PASS | 0.036 |
| `CanadianHamTests.ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportLeavesTask4610Version2LessonSplitRowsUnchanged` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesMixedTask4610SyncRowsByRowVersion` | PASS | 0.040 |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesTask4610LessonSplitProgressAndQuizAttempts` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` | PASS | 0.074 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails` | PASS | 0.044 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates` | PASS | 0.036 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress` | PASS | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` | PASS | 0.034 |
| `CanadianHamTests.ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` | PASS | 0.047 |
| `CanadianHamTests.ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` | PASS | 0.064 |
| `CanadianHamTests.ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` | PASS | 0.036 |
| `CanadianHamTests.ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` | PASS | 0.044 |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` | PASS | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` | PASS | 0.014 |
| `CanadianHamTests.ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue` | PASS | 0.009 |
| `CanadianHamTests.ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` | PASS | 0.009 |
| `CanadianHamTests.ProgressStoreTests.testLegacyEmptyReviewQuestionIdsImportAtTopLevelAndInSyncRows` | PASS | 0.093 |
| `CanadianHamTests.ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` | PASS | 0.012 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` | PASS | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` | PASS | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` | PASS | 0.009 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` | PASS | 0.032 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpFixtureValidationAndPayloadRoundTrips` | PASS | 0.133 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix` | PASS | 0.031 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice` | PASS | 2.628 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation` | PASS | 0.002 |
| `CanadianHamTests.ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` | PASS | 0.056 |
| `CanadianHamTests.ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` | PASS | 0.058 |
| `CanadianHamTests.ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` | PASS | 0.034 |
| `CanadianHamTests.ProgressStoreTests.testM1QuizRoundBoundariesPreserveOneSessionAnswersHelpAndDismissedCheckpoint` | PASS | 0.564 |
| `CanadianHamTests.ProgressStoreTests.testM1QuizRoundsRetainEveryItemAndSeededOrderWithinTeachingSections` | PASS | 0.554 |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` | PASS | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` | PASS | 0.034 |
| `CanadianHamTests.ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` | PASS | 0.546 |
| `CanadianHamTests.ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` | PASS | 0.020 |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` | PASS | 0.074 |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` | PASS | 0.077 |
| `CanadianHamTests.ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` | PASS | 0.030 |
| `CanadianHamTests.ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences` | PASS | 0.055 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender` | PASS | 0.961 |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference` | PASS | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences` | PASS | 0.012 |
| `CanadianHamTests.ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` | PASS | 0.012 |
| `CanadianHamTests.ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` | PASS | 0.044 |
| `CanadianHamTests.ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` | PASS | 0.036 |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreRoundTripExportImportReset` | PASS | 0.059 |
| `CanadianHamTests.ProgressStoreTests.testQuizRoundsWithConceptChecksKeepTheCompleteUngroupedOrder` | PASS | 0.546 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff` | PASS | 0.014 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` | PASS | 0.032 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` | PASS | 0.048 |
| `CanadianHamTests.ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference` | PASS | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference` | PASS | 0.015 |
| `CanadianHamTests.ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails` | PASS | 0.016 |
| `CanadianHamTests.ProgressStoreTests.testReviewAttemptPayloadImportSyncAndLegacyVersionRejection` | PASS | 0.057 |
| `CanadianHamTests.ProgressStoreTests.testReviewItemsUseEarlierTaughtPoolsAndFinalM1Round` | PASS | 1.665 |
| `CanadianHamTests.ProgressStoreTests.testReviewSourceMayDifferFromCanonicalHintLessonWithAuthoredSectionAnchor` | PASS | 0.565 |
| `CanadianHamTests.ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext` | PASS | 1.765 |
| `CanadianHamTests.ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates` | PASS | 0.015 |
| `CanadianHamTests.ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` | PASS | 0.007 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` | PASS | 0.093 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` | PASS | 0.066 |
| `CanadianHamTests.ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` | PASS | 0.032 |
| `CanadianHamTests.ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` | PASS | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices` | PASS | 0.044 |
| `CanadianHamTests.ProgressStoreTests.testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration` | PASS | 0.030 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds` | PASS | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating` | PASS | 0.102 |
| `CanadianHamTests.ProgressStoreTests.testTask4610SharedConceptMappingAndConceptInclusiveScores` | PASS | 0.249 |
| `CanadianHamTests.ProgressStoreTests.testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows` | PASS | 0.042 |
| `CanadianHamTests.ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` | PASS | 0.056 |
| `CanadianHamTests.QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` | PASS | 0.013 |
| `CanadianHamTests.QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` | PASS | 0.014 |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsNoReadmeFiles` | PASS | 0.014 |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories` | PASS | 0.001 |
| `CanadianHamTests.QuestionBankTests.testBundledJSONDecodesExpectedCounts` | PASS | 0.019 |
| `CanadianHamTests.QuestionBankTests.testBundledLessonModelExposesPrerequisites` | PASS | 0.565 |
| `CanadianHamTests.QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary` | PASS | 0.741 |
| `CanadianHamTests.QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` | PASS | 0.020 |
| `CanadianHamTests.QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` | PASS | 0.080 |
| `CanadianHamTests.QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` | PASS | 0.001 |
| `CanadianHamTests.QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` | PASS | 0.566 |
| `CanadianHamTests.ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours` | PASS | 0.001 |
| `CanadianHamTests.ReadinessAndScoringTests.testExamScoringBoundaries` | PASS | 0.001 |
| `CanadianHamTests.ReadinessAndScoringTests.testReadinessStates` | PASS | 0.001 |
| `CanadianHamTests.ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` | PASS | 0.037 |
| `CanadianHamTests.RootNavigationMappingTests.testCompactHomeSessionAndSectionPushesUseVisibleDestination` | PASS | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testEmptyCompactPathMapsToHome` | PASS | 0.000 |
| `CanadianHamTests.RootNavigationMappingTests.testEveryLearnRouteRoundTripsWithItsWholeStack` | PASS | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testEveryRootSelectionRoundTrips` | PASS | 0.003 |
| `CanadianHamTests.RootNavigationMappingTests.testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts` | PASS | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testPracticeHintLessonStackKeepsSessionAsSplitSelection` | PASS | 0.000 |

</details>
