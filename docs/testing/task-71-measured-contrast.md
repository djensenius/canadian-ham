# TASK-71: measured-contrast audit verification

Owner-delegated decision 2026-10-22 permits the new
`auditVerifyingMeasuredContrast(app:)` helper only for new TASK-46.5 and
TASK-46.6.1 audits. This change adds the helper and its pure proof tests; it does
not change any existing audit, helper, test method, app code or audit call site.
Integration into those task branches remains separate.

The helper calls `performAccessibilityAudit` without specifying audit types
(the full default audit). Only `.contrast` findings with a non-nil element and a
measurable element screenshot at **at least 4.5:1** are ignored. Before taking
a screenshot, the element must have a non-empty frame fully contained in
`app.windows.firstMatch.frame`, below the bottom of the navigation/status bars
(the same protected-bar boundary as the existing occluded-content helper).
Partly offscreen/under-bar elements fail here; the separate occluded-content
exception is not applied by this helper.

Every contrast finding, **passing or failing**, gets a keepAlways text attachment
containing label, frame and unrounded ratio, or `unmeasurable` when no safe
measurement is available (including nil elements or rejected frames). All
non-contrast findings remain failures. There is no label whitelist.

## Measurement

`measuredTextContrast(in:)` accepts a `CGImage` at its native pixel resolution
(no point-scale conversion or resampling). It converts to opaque 8-bit sRGB,
groups pixels into 5-bit-per-channel RGB clusters and chooses the largest
cluster as the candidate background. Cluster luminances use average original
channel values, not quantized bin centers. WCAG sRGB linearization uses 0.04045
as the threshold and coefficients 0.2126/0.7152/0.0722; contrast is
`(Lmax + 0.05) / (Lmin + 0.05)`.

The measurement is deliberately conservative:

1. The background must cover **more than 50%** of the image. Each other cluster
   covering **at least 2%** is significant. If any significant foreground covers
   **25% or more**, the background assignment is ambiguous and returns nil. A
   two-tone panel is not treated as high-contrast text.
2. A significant non-background cluster within **1.1:1** of the background also
   returns nil: broad background noise or bin splits cannot establish a safe
   text/background assignment. This fails closed rather than merging away what
   could be very faint text.
3. Select significant **retained cores first**, farthest from the background in
   luminance first (deterministic ties). A cluster may be excluded as an
   **antialiased edge blend only toward an already retained core**; that core is
   never removed later. The blend's projection on the background/core sRGB colour
   line must have fraction **greater than 0 and at most 0.9**, with perpendicular
   RGB distance at most **8** (8-bit channel units). In addition, **every** pixel
   in that cluster must be within **two native pixels** in each axis of both the
   background and that retained core. A discarded middle tone cannot support a
   second exclusion. Colour alone cannot distinguish grey text from an edge
   blend; separate text/solid blocks are not discarded without spatial support.
4. Validate the **local background at each retained core component's boundary**.
   Label core pixels with **4-connectivity**, independently per retained colour
   cluster. Attach each excluded blend pixel to the nearest supporting core
   pixel's component within the unchanged **two-native-pixel** neighbourhood in
   each axis; squared-distance ties use the first row-major core pixel. Blends
   never support another blend assignment or merge disconnected cores.
   Validate every component containing **at least four native pixels**, including
   its assigned blends, independently of image area. This small absolute minimum
   includes glyphs and dots even far below 0.5% coverage; only one-to-three-pixel
   specks skip spatial validation (not the cluster's ratio calculation).
   Boundary pixels have an in-image **4-neighbour** outside their component.
   At least **50%** must have supported background within **two native pixels**
   in each axis. Support is either an actual background pixel, or a blend toward
   that component's retained core which is **4-connected**, possibly through
   other validated blends, to actual background. Clusters below 2% may supply
   this **spatial evidence only** after passing the **same** fraction ≤0.9,
   RGB-residual ≤8, and **every-pixel radius-two core AND background** blend
   checks. They never enter the reported ratio or merge core components. This
   support is independent of which same-colour component owns an excluded blend
   pixel, but not of its validated retained core colour. If **more than 50%** of
   boundary pixels directly border another retained foreground colour region,
   return nil even if supported background is nearby. A significant component
   with no measurable boundary also returns nil.
   A single failing component makes the entire image unmeasurable: a supported
   block on cream cannot lend its boundary to same-colour inset text. The
   supervisor approved boundary (not filled-interior) validation to keep thick
   text, solid blocks and icons on a single background measurable, without
   increasing the radius or altering existing fixtures.
5. Compute the WCAG ratio for **every remaining significant foreground** against
   the background and report the **minimum ratio**, not the darkest tone or the
   largest luminance difference. Every remaining tone must therefore meet 4.5:1
   for the audit finding to be ignored. Dark icons, borders, offscreen black
   bands or bold headings cannot rescue lower-contrast text.

Uniform images, missing meaningful foreground, ambiguous backgrounds and images
containing transparent pixels return nil, not a passing ratio. Clusters below
2% still never enter the ratio; this is a dominant-background text-element heuristic,
not semantic text recognition or a general multiple-local-background audit.
Native screenshot scale is preserved. Bold 15 pt text at 3× and explicit
significant edge-band fixtures test the colour/spatial tolerances; the original
2% cutoff and 5-bit quantization were not loosened.

## Exported screenshot provenance

The following are **unaltered element screenshots**, not app screenshot crops.
All three came from iPhone 17 Pro failure attachments at scale 3. The source
`manifest.json` files identify them as Element Screenshot attachments.

| Bundled resource | Original attachment | Label | Pixels |
| --- | --- | --- | --- |
| `correct-feedback-light.png` | `/tmp/task-46.6.1-iphone-final-attachments/D9662C8A-EFA8-4DC3-A1E5-23F442D3FBD1.png` | Correct 820 / 1 000 = 0.82 A, so only the display unit differs. | 860 × 126 |
| `correct-feedback-dark.png` | `/tmp/task-46.6.1-iphone-final-attachments/7DBFA3EB-2C30-4107-A150-DF8D5FFFEBB0.png` | Correct 820 / 1 000 = 0.82 A, so only the display unit differs. | 860 × 126 |
| `try-it-paragraph-light.png` | `/tmp/task-46.5-aligned-iphone-attachments/326FDD52-FACC-4AB9-8299-C9F343F47B21.png` | Compare blue-red-brown and blue-red-orange value bands. Their first two bands match. | 956 × 192 |

Resource directory:
`apps/apple/CanadianHamUITests/Resources/ContrastMeasurement/`.
SHA-256:

```text
b8fc4a925a34004e5b5b0deb9016774c7e90dfe18be023d3097dc759cfff2d65  correct-feedback-light.png
46f116ed81e0a348a66bc3f39bd65b3b1938779de5004937d25eb1057024bb5d  correct-feedback-dark.png
c292e9eba4626b831b9238e32926bc24264b1f36e66fc89724a94170f9c2eba6  try-it-paragraph-light.png
```

The light/dark feedback evidence is indexed by
`/tmp/task-46.6.1-iphone-final-failure-evidence.json`. Older TASK-46.5 element
attachments include black offscreen renders; those were inspected but are not
used as passing fixtures. TASK-65's existing notes document unrelated historic
heading-wait/audit timeout flakes, not a measured-contrast exemption.

## Targeted validation

The pure proof class has no app launch. Its synthetic images cover near-black
on cream, deliberately failing #9A9A9A on cream, pale on dark green, 15 pt
anti-aliased high/low-contrast text, a tiny high-contrast tail, uniform images,
insufficient foreground coverage and transparent images. Review regressions
also cover 3% near-black and mid-grey blocks together; mixed 15 pt bold lines
at 3×; a 5.4% dark icon beside grey text; a cream/light-green panel with dark
text; equal large tones; significant near-background noise; a 3% black
'offscreen' band beside grey text; solid blend-coloured foreground; significant
antialiased bands; real bold-text edge cluster coverage at 3×; and the
non-empty/window/below-bar geometry gate. The three exported screenshot tests
are retained and rerun.

Run only this class on one destination:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -testPlan CanadianHamDefault \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CanadianHamUITests/UITestContrastMeasurementTests \
  -resultBundlePath /tmp/task-71-review-tests.xcresult \
  test CODE_SIGNING_ALLOWED=NO
```

The command is launched with nohup and its log polled with grep. No other build
is stopped. No full suites are requested: only the iOS UI-test target changed;
macOS, tvOS and visionOS do not compile these files.

### Initial results (2026-10-23, before internal review)

These historical results describe the original 12-test proof, not the revised
minimum-ratio algorithm. The review follow-up and current results are below.

Final log: `/tmp/task-71-contrast-tests-final.log`.
Result bundle: `/tmp/task-71-contrast-tests-final.xcresult`.
Summary: `/tmp/task-71-final-summary.json`; exported measurement attachments:
`/tmp/task-71-final-proof-attachments/`.
**12 passed, 0 failed, 0 skipped**, exit 0; XCTest class elapsed 2.372 s.
No warnings/errors originate in either new Swift file in the final build.
An initial run also passed all 12 tests; its new `XCTContext` actor-isolation
warning was fixed by marking the proof class `@MainActor`, then rerunning only
that class. No app is launched by the proof tests. The live audit handler is
compiled but not invoked here; the exported-image tests are the requested proof
against the known false-positive renders, not a claim of live screen integration.

| Test (`UITestContrastMeasurementTests`) | Final result | Seconds |
| --- | --- | ---: |
| `testAntialiased15PointLowContrastTextStillFails` | PASS | 1.542 |
| `testAntialiased15PointTextMeasuresExpectedContrast` | PASS | 0.094 |
| `testExportedCorrectFeedbackDarkPasses` | PASS | 0.088 |
| `testExportedCorrectFeedbackLightPasses` | PASS | 0.070 |
| `testExportedTryItParagraphLightPasses` | PASS | 0.073 |
| `testMidGreyOnCreamFails` | PASS | 0.070 |
| `testNearBlackOnCreamPasses` | PASS | 0.073 |
| `testOnlyTinyForegroundIsUnmeasurable` | PASS | 0.072 |
| `testPaleOnDarkGreenPasses` | PASS | 0.070 |
| `testTinyHighContrastTailDoesNotRescueLowContrastText` | PASS | 0.073 |
| `testTransparentImageIsUnmeasurable` | PASS | 0.071 |
| `testUniformImageIsUnmeasurable` | PASS | 0.077 |

KeepAlways measurement attachments report:

- Correct feedback light: **8.344323837747055:1**.
- Correct feedback dark: **11.403364958858397:1**.
- Try-it paragraph light: **16.336427704401043:1**.
- The synthetic #9A9A9A/cream tests assert **2.6591:1** within 0.01
  (two-colour panel) / 0.1 (15 pt anti-aliased text), both below 4.5.

XcodeGen was run twice; `project.pbxproj` and the complete generated-project
Git diff were byte-identical between runs. `git diff --check` passed.
The three pre-existing UI-test source files have no diff against the baseline.

`node scripts/check-test-guard.mjs --self-test` passed. Against `main...HEAD`,
the unapproved guard **failed as expected** (exit 1) and flagged the new
`auditVerifyingMeasuredContrast` function/default audit call in
`UITestContrastMeasurement.swift:72–73`. With the approval marker it passed
(exit 0), still reporting the approved findings. Logs:
`/tmp/task-71-test-guard-unapproved.log` and
`/tmp/task-71-test-guard-approved.log`.

The PR must carry the standalone approval line:

```text
Test-guard-approved: owner decision 2026-10-22
```

### Internal review follow-up results (2026-10-23, prior algorithm)

B1/B2: replaced the maximum-difference choice with the minimum WCAG ratio after
conservative colour-line **and spatial** antialias filtering. Ambiguous large
background tones and significant near-background noise return nil. Retained all
12 original tests and added 11 regressions. A separate solid blend-coloured
block proves that merely lying on the colour line is not enough to be dropped.
S1: added the non-empty/window/below-navigation-and-status-bar gate and pure
geometry tests, plus the black-band regression. S2: failed contrast findings now
get keepAlways label/frame/ratio-or-unmeasurable diagnostics too. S3: actual
15 pt bold text at 3× has a significant edge cluster covering **2.6667%** of
pixels; it measures **15.9942758247219:1**. Explicit one-pixel blend bands cover
**6.4%** and still measure the correct core ratio. No tolerance widening was
needed.

Targeted command above ran via `nohup bash /tmp/task-71-review-tests.sh`, with
`grep` polling, on the single iPhone 17 Pro iOS 27.0 destination. No builds were
killed. **23 passed, 0 failed, 0 skipped**, exit 0; XCTest class elapsed 3.469 s.
Log: `/tmp/task-71-review-tests.log`.
Result bundle: `/tmp/task-71-review-tests.xcresult`.
Summary: `/tmp/task-71-review-summary.json`.
KeepAlways proof attachments: `/tmp/task-71-review-proof-attachments/`.
There are no Swift warnings/errors in the changed files; the build emits the
unrelated AppIntents metadata-skipped warning. No app launches or live audit
integration were added; the failure diagnostic path is compiled, not invoked by
these pure proofs. Full suites and macOS/tvOS/visionOS were skipped because only
the iOS UI-test target changed.

| Test (`UITestContrastMeasurementTests`) | Review result | Seconds |
| --- | --- | ---: |
| `testAntialiased15PointBoldEdgeCoverageAt3x` | PASS | 0.801 |
| `testAntialiased15PointBoldMixedContrastLinesFailAt3x` | PASS | 0.139 |
| `testAntialiased15PointLowContrastTextStillFails` | PASS | 0.089 |
| `testAntialiased15PointTextMeasuresExpectedContrast` | PASS | 0.073 |
| `testBlackOffscreenBandDoesNotRescueMidGreyText` | PASS | 0.083 |
| `testContrastMeasurementRejectsInvisibleFrames` | PASS | 0.122 |
| `testDarkIconDoesNotRescueMidGreyText` | PASS | 0.073 |
| `testEqualLargeTonesAreUnmeasurable` | PASS | 0.137 |
| `testExportedCorrectFeedbackDarkPasses` | PASS | 0.116 |
| `testExportedCorrectFeedbackLightPasses` | PASS | 0.073 |
| `testExportedTryItParagraphLightPasses` | PASS | 0.123 |
| `testMidGreyOnCreamFails` | PASS | 0.072 |
| `testNearBlackOnCreamPasses` | PASS | 0.084 |
| `testOnlyTinyForegroundIsUnmeasurable` | PASS | 0.079 |
| `testPaleOnDarkGreenPasses` | PASS | 0.081 |
| `testSignificantAntialiasedEdgeBandsMeasureCoreContrast` | PASS | 0.075 |
| `testSignificantNearBackgroundNoiseIsUnmeasurable` | PASS | 0.077 |
| `testSignificantNearBlackAndMidGreyBlocksDoNotPass` | PASS | 0.156 |
| `testSolidBlendColourIsNotMistakenForAntialiasing` | PASS | 0.158 |
| `testTinyHighContrastTailDoesNotRescueLowContrastText` | PASS | 0.078 |
| `testTransparentImageIsUnmeasurable` | PASS | 0.121 |
| `testTwoTonePanelWithDarkTextIsUnmeasurable` | PASS | 0.223 |
| `testUniformImageIsUnmeasurable` | PASS | 0.439 |

The rerun screenshot attachments still report **8.344323837747055:1** (light
feedback), **11.403364958858397:1** (dark feedback), and
**16.336427704401043:1** (Try-it paragraph). Low-contrast mixed blocks, mixed bold
lines, icon/text and black-band/text tests assert the grey text's **2.6591:1**
within 0.01/0.1; two-tone panels assert nil. Existing pre-TASK-71 UI-test sources
remain unchanged.

Review-fix test guard: `node scripts/check-test-guard.mjs --self-test` passed.
Against `main...HEAD`, the unapproved check failed as expected (exit 1), flagging
the new handler/default audit at lines 128/136. The same check with
`TEST_GUARD_PR_BODY='Test-guard-approved: owner decision 2026-10-22'` passed
(exit 0), still reporting the approved findings. Logs:
`/tmp/task-71-review-test-guard-{self,unapproved,approved}.log`.
`git diff --check` passed. No target membership/resources changed in this fix,
so XcodeGen regeneration was unnecessary. No PR opened.


### Copilot PR #1007 inset/chained-blend follow-up (2026-10-23, before component fix)

Addressed `PRRT_kwDOUxZq_M6vncjQ` (small inset panel) and
`PRRT_kwDOUxZq_M6vncj3` (chained blend exclusions). Retained cores are now
permanent and selected in descending distance from background luminance;
excluded clusters never support later exclusions. Every retained region also
needs a locally supported boundary, with foreground-dominated boundaries
returning nil. The supervisor clarified boundary-pixel validation instead of
filled-interior validation: a radius-three test on **all** pixels would reject
existing solid 80×20 blocks and the 60×78 icon even on cream. The approved
boundary interpretation uses radius **two**, not a larger radius. No existing
fixture, assertion, coverage cutoff, blend tolerance or real screenshot changed.

Added exactly two regressions:

- `testInsetPanelCannotUseTheSurroundingCreamAsTextBackground`: 100×100,
  **84% #FFF8E8**, **12.8% #404040** inset panel (40×40 before overdraw),
  **3.2% #201C18** text (16×20 inside it). Accepts only nil or a ratio <4.5;
  the real local text/panel ratio is ~1.63:1.
- `testChainedBlendsCannotUseAnExcludedCore`: 100×100 #FFF8E8 with one-pixel
  strokes of **#908A80, #58534C, #201C18** at **x, x+2, x+4**, for
  x=10/30/50/70 and y=10…89. Each tone covers **3.2%**. Accepts only nil or
  a ratio <4.5; a measurable result must equal the first tone's **3.2357:1**
  within 0.01.

**Pre-fix proof:** added both tests while leaving the previous helper unchanged
(from `e2ea6e06`). Ran only those two methods through nohup/xbuild with grep
polling on the same iPhone 17 Pro destination. Both failed as required:

| New regression | Previous result | Expected | Outcome |
| --- | ---: | --- | --- |
| Inset panel | 9.797721859358917:1 | nil or <4.5 | FAIL |
| Chained blends | 15.9942758247219:1 | nil or <4.5 | FAIL |

Exit **65**; **2 failed, 0 passed, 0 skipped**. Log:
`/tmp/task-71-copilot-regressions-before.log`; result bundle:
`/tmp/task-71-copilot-regressions-before.xcresult`; extracted summary:
`/tmp/task-71-copilot-before-summary.json`. The first run's extra ratio assertion
used 3.2375 (also within 0.01 of 3.2357); the final test spells the rounded
expected WCAG ratio 3.2357. Both runs enforce the identical <4.5 gate.

**Post-fix proof:** ran the entire class, including all **24 unchanged existing
tests** and both new regressions, via:

```sh
nohup bash /tmp/task-71-copilot-tests.sh > /tmp/task-71-copilot-tests.log 2>&1 < /dev/null &
# Script runs:
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -testPlan CanadianHamDefault \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CanadianHamUITests/UITestContrastMeasurementTests \
  -resultBundlePath /tmp/task-71-copilot-tests.xcresult \
  test CODE_SIGNING_ALLOWED=NO
```

Polled with grep; no builds killed. **26 passed, 0 failed, 0 skipped**, exit **0**;
class elapsed **4.886 s** (4.899 s including suite overhead). iPhone 17 Pro,
iOS 27.0. Result summary: `/tmp/task-71-copilot-summary.json`; exported
keepAlways attachments: `/tmp/task-71-copilot-proof-attachments/`.

| Test (`UITestContrastMeasurementTests`) | Result | Seconds |
| --- | --- | ---: |
| `testAntialiased15PointBoldEdgeCoverageAt3x` | PASS | 0.908 |
| `testAntialiased15PointBoldMixedContrastLinesFailAt3x` | PASS | 0.121 |
| `testAntialiased15PointLowContrastTextStillFails` | PASS | 0.085 |
| `testAntialiased15PointTextMeasuresExpectedContrast` | PASS | 0.087 |
| `testBlackOffscreenBandDoesNotRescueMidGreyText` | PASS | 0.071 |
| `testChainedBlendsCannotUseAnExcludedCore` | PASS | 0.070 |
| `testContrastMeasurementRejectsInvisibleFrames` | PASS | 0.071 |
| `testDarkIconDoesNotRescueMidGreyText` | PASS | 0.095 |
| `testEqualLargeTonesAreUnmeasurable` | PASS | 0.071 |
| `testExportedCorrectFeedbackDarkPasses` | PASS | 0.143 |
| `testExportedCorrectFeedbackLightPasses` | PASS | 0.104 |
| `testExportedTryItParagraphLightPasses` | PASS | 0.151 |
| `testInsetPanelCannotUseTheSurroundingCreamAsTextBackground` | PASS | 0.077 |
| `testInterleavedNearIdenticalGreysCannotHideEachOtherBesideDarkText` | PASS | 0.074 |
| `testMidGreyOnCreamFails` | PASS | 0.069 |
| `testNearBlackOnCreamPasses` | PASS | 0.071 |
| `testOnlyTinyForegroundIsUnmeasurable` | PASS | 0.077 |
| `testPaleOnDarkGreenPasses` | PASS | 0.089 |
| `testSignificantAntialiasedEdgeBandsMeasureCoreContrast` | PASS | 0.078 |
| `testSignificantNearBackgroundNoiseIsUnmeasurable` | PASS | 0.089 |
| `testSignificantNearBlackAndMidGreyBlocksDoNotPass` | PASS | 0.119 |
| `testSolidBlendColourIsNotMistakenForAntialiasing` | PASS | 0.219 |
| `testTinyHighContrastTailDoesNotRescueLowContrastText` | PASS | 0.254 |
| `testTransparentImageIsUnmeasurable` | PASS | 0.445 |
| `testTwoTonePanelWithDarkTextIsUnmeasurable` | PASS | 0.908 |
| `testUniformImageIsUnmeasurable` | PASS | 0.338 |

All three real screenshot measurements remain **non-nil and unchanged**:
**8.344323837747055:1** (feedback light), **11.403364958858397:1** (feedback dark),
and **16.336427704401043:1** (Try-it paragraph). Actual bold 15 pt 3× edge coverage
is still **2.6667%**, measuring **15.9942758247219:1**. Significant synthetic
anti-aliased edge bands also pass unchanged. No loosening was needed.

No Swift warnings/errors in either changed source; only the unrelated
AppIntents metadata-skipped warning. No live app/audit integration was added.
Only the iOS UI-test target is changed; macOS/tvOS/visionOS and full Apple suites
were skipped. No target membership changed, so XcodeGen was not needed.
The pre-existing dominant-background, 5-bit clustering and <2% coverage
limitations remain; this is not general semantic text recognition.


### Copilot PR #1007 disconnected-component follow-up (2026-10-23, current)

Addressed `PRRT_kwDOUxZq_M6vn59C`. Colour-wide counters allowed a separate
correctly contrasted block to mask low-contrast inset text of the same colour.
Core pixels now have **four-connected component IDs**, and every excluded blend
pixel is assigned to its nearest supporting core component, not pooled by colour.
Each component of **at least four native pixels** independently needs the same
radius-two, **at least 50%** supported boundary and **at most 50%** other-retained
foreground border. A failing component returns nil for the entire image.
The minimum-ratio calculation and all existing thresholds/fixtures are unchanged.

Added three regressions:

- `testDisconnectedDarkBlockCannotRescueInsetLowContrastText`: **exactly** the
  original 100×100 inset-panel fixture plus a **16×40 #201C18 rectangle at
  (5,10)** on cream. Accepts only nil or <4.5. On the unchanged `3478f40e`
  helper this **failed**, returning **9.797721859358917:1** despite the inset
  text's ~1.6324:1 local contrast. Targeted pre-fix xbuild exit **65**, one failed
  test, zero passed/skipped. Log/bundle: `/tmp/task-71-components-before.log`
  and `/tmp/task-71-components-before.xcresult`; extracted summary:
  `/tmp/task-71-components-before-summary.json`.
- `testFourPixelInsetGlyphCannotBorrowAnotherComponentsBoundary`: a 2×2 glyph
  on the inset panel plus the separate cream-backed block must return nil.
  The glyph is only **0.04%** of the image, proving the four-pixel component
  minimum does not silently ignore small text when its colour is significant.
- `testSubthresholdAntialiasedPanelEdgeCannotSupportInsetDarkStrokes`: two
  1×4 dark strokes on a 10×10 #404040 panel with a one-pixel cream/panel blend
  border (**0.44%** coverage), plus the separate cream-backed block. Only nil
  or <4.5 is accepted; the panel's subthreshold edge cannot rescue its text.

#### Screenshot diagnostics and approved refinement

The first four-connected implementation deliberately failed closed on all three
real screenshots: **25 passed / 3 failed**, exit65, log/bundle
`/tmp/task-71-components-tests.{log,xcresult}`. Bold and all adversarial proofs
still passed. Work paused and this was reported rather than loosening rules.
Native CGImage diagnostics isolated thin equals signs/hyphens, not tiny noise:

| Resource | Core component pixels | Native-pixel bounding box (inclusive) | Boundary pixels | Direct-background support | Other retained / panel / excluded-blend neighbours |
| --- | ---: | --- | ---: | ---: | --- |
| feedback dark | 48 | (471,26)–(494,27) | 48 | 4 | 0 / 0 / 0 |
| feedback dark | 48 | (471,40)–(494,41) | 48 | 4 | 0 / 0 / 0 |
| feedback light | 48 | (471,40)–(494,41) | 48 | 4 | 0 / 0 / 0 |
| Try-it light | 32 | (324,33)–(339,34) | 32 | 4 | 0 / 0 / 0 |
| Try-it light | 32 | (422,33)–(437,34) | 32 | 4 | 0 / 0 / 0 |
| Try-it light | 32 | (796,33)–(811,34) | 32 | 4 | 0 / 0 / 0 |
| Try-it light | 32 | (894,33)–(909,34) | 32 | 4 | 0 / 0 / 0 |

All neighbours outside those cores were **sub-2% antialias shades**, so none had
been classified as excluded blends. `/tmp/task-71-components-diagnostics.log`
logs every failing component and all adjacent cluster means, keys, counts and
assigned-core values (none initially). Main adjacent shade pairs, rounded RGB:

- Dark upper stroke: (85,105,86) and (217,238,211), 24 boundary pixels each;
  dark lower stroke: (185,206,181) and (209,230,204), 24 each.
- Light stroke: (51,85,53) and (76,107,77), 24 each.
- Each Try-it hyphen: (50,45,38) and (123,117,107), 16 each.

On escalation, the supervisor explicitly approved **support-only** classification
of sub-2% clusters under the **identical** fraction≤0.9 / RGB-residual≤8 /
every-pixel radius-two core-and-background blend rules, plus **four-connected
reachability to actual background**. Such shades cannot change the minimum
ratio, join components, or support a different retained colour. The extra
subthreshold-panel-edge adversarial test above was required and added. No
8-connectivity, larger radius, lower support share, tiny-component exemption,
colour tolerance change, or fixture modification was needed.

The refined host diagnostics in
`/tmp/task-71-components-support-diagnostics.log` show **48/48** and **32/32**
supported boundary pixels for all seven formerly failing components, with no
other-retained borders. The three images were also visually inspected unchanged.

#### Final targeted iPhone results

```sh
nohup bash /tmp/task-71-components-final.sh > /tmp/task-71-components-final.log 2>&1 < /dev/null &
# Script exports DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer and runs:
xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -testPlan CanadianHamDefault \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CanadianHamUITests/UITestContrastMeasurementTests \
  -resultBundlePath /tmp/task-71-components-final.xcresult \
  test CODE_SIGNING_ALLOWED=NO
```

Polled with grep; no builds were killed. **29 passed, 0 failed, 0 skipped**,
exit **0**, class elapsed **23.466 s**. All **26 previous test methods** are
unchanged. Destination iPhone 17 Pro, iOS 27.0. Extracted summary:
`/tmp/task-71-components-final-summary.json`; keepAlways attachments:
`/tmp/task-71-components-proof-attachments/`.

| Test (`UITestContrastMeasurementTests`) | Result | Seconds |
| --- | --- | ---: |
| `testAntialiased15PointBoldEdgeCoverageAt3x` | PASS | 0.876 |
| `testAntialiased15PointBoldMixedContrastLinesFailAt3x` | PASS | 0.954 |
| `testAntialiased15PointLowContrastTextStillFails` | PASS | 0.399 |
| `testAntialiased15PointTextMeasuresExpectedContrast` | PASS | 3.427 |
| `testBlackOffscreenBandDoesNotRescueMidGreyText` | PASS | 0.686 |
| `testChainedBlendsCannotUseAnExcludedCore` | PASS | 2.365 |
| `testContrastMeasurementRejectsInvisibleFrames` | PASS | 0.093 |
| `testDarkIconDoesNotRescueMidGreyText` | PASS | 0.446 |
| `testDisconnectedDarkBlockCannotRescueInsetLowContrastText` | PASS | 0.072 |
| `testEqualLargeTonesAreUnmeasurable` | PASS | 0.074 |
| `testExportedCorrectFeedbackDarkPasses` | PASS | 0.866 |
| `testExportedCorrectFeedbackLightPasses` | PASS | 6.223 |
| `testExportedTryItParagraphLightPasses` | PASS | 1.463 |
| `testFourPixelInsetGlyphCannotBorrowAnotherComponentsBoundary` | PASS | 0.076 |
| `testInsetPanelCannotUseTheSurroundingCreamAsTextBackground` | PASS | 0.075 |
| `testInterleavedNearIdenticalGreysCannotHideEachOtherBesideDarkText` | PASS | 0.078 |
| `testMidGreyOnCreamFails` | PASS | 0.090 |
| `testNearBlackOnCreamPasses` | PASS | 0.134 |
| `testOnlyTinyForegroundIsUnmeasurable` | PASS | 0.080 |
| `testPaleOnDarkGreenPasses` | PASS | 0.082 |
| `testSignificantAntialiasedEdgeBandsMeasureCoreContrast` | PASS | 0.144 |
| `testSignificantNearBackgroundNoiseIsUnmeasurable` | PASS | 1.158 |
| `testSignificantNearBlackAndMidGreyBlocksDoNotPass` | PASS | 0.644 |
| `testSolidBlendColourIsNotMistakenForAntialiasing` | PASS | 0.340 |
| `testSubthresholdAntialiasedPanelEdgeCannotSupportInsetDarkStrokes` | PASS | 0.296 |
| `testTinyHighContrastTailDoesNotRescueLowContrastText` | PASS | 0.302 |
| `testTransparentImageIsUnmeasurable` | PASS | 0.272 |
| `testTwoTonePanelWithDarkTextIsUnmeasurable` | PASS | 0.620 |
| `testUniformImageIsUnmeasurable` | PASS | 1.131 |

Real screenshot measurements are again **non-nil and unchanged**:
**8.344323837747055:1** (feedback light), **11.403364958858397:1** (feedback dark),
and **16.336427704401043:1** (Try-it light). Actual bold 15pt 3× edge coverage
remains **2.6667%**, ratio **15.9942758247219:1**. The significant synthetic AA
bands, mixed bold lines, icon/text, inset panel, chained blends, mixed-background
fixture, and all earlier adversarial proofs pass without changing assertions.

No changed-source Swift warnings/errors; only the unrelated AppIntents metadata
warning. No live app launch/audit integration was added. Full iOS suites and
macOS/tvOS/visionOS were skipped because only the iOS UI-test target changed.
No target membership changed, so XcodeGen was unnecessary. The dominant-background,
5-bit-cluster and <2%-ratio-coverage heuristic limitations still apply; this is
not semantic text recognition or proof of all possible local backgrounds.
