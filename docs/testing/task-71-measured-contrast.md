# TASK-71: measured-contrast audit verification

Owner-delegated decision 2026-10-22 permits the new
`auditVerifyingMeasuredContrast(app:)` helper only for new TASK-46.5 and
TASK-46.6.1 audits. This change adds the helper and its pure proof tests; it does
not change any existing audit, helper, test method, app code or audit call site.
Integration into those task branches remains separate.

The helper calls `performAccessibilityAudit` without specifying audit types
(the full default audit). Only `.contrast` findings with a non-nil element and a
measurable element screenshot at **at least 4.5:1** are ignored. Each ignored
finding gets a keepAlways text attachment containing label, frame and unrounded
ratio. All other findings remain failures. No label whitelist or occlusion rule
is applied by this helper.

## Measurement

`measuredTextContrast(in:)` accepts a `CGImage` at its native pixel resolution
(no point-scale conversion or resampling). It converts to opaque 8-bit sRGB,
groups pixels into 5-bit-per-channel RGB clusters, chooses the largest cluster
as background, and chooses the cluster with the greatest luminance difference
among other clusters covering at least 2% of pixels. Cluster luminances use
average original channel values, not quantized bin centers. WCAG sRGB
linearization uses 0.04045 as the threshold and coefficients
0.2126/0.7152/0.0722; contrast is `(Lmax + 0.05) / (Lmin + 0.05)`.

Uniform images, missing meaningful foreground and images containing transparent
pixels return nil, not a passing ratio. A <2% high-contrast tail cannot rescue
low-contrast text. This is a two-colour text-element measurement, not semantic
text recognition or a whole-screen/multiple-background contrast audit.

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
insufficient foreground coverage and transparent images. Three more tests
measure the exported element screenshots above.

Run only this class on one destination:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -testPlan CanadianHamDefault \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CanadianHamUITests/UITestContrastMeasurementTests \
  -resultBundlePath /tmp/task-71-contrast-tests-final.xcresult \
  test CODE_SIGNING_ALLOWED=NO
```

The command is launched with nohup and its log polled with grep. No other build
is stopped. No full suites are requested: only the iOS UI-test target changed;
macOS, tvOS and visionOS do not compile these files.

### Results (2026-10-23)

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
