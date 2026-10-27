# TASK-77 — single-tree mock header and scrolling question navigator

## Scope and implementation

`flagAndNavigatorControls` and `quickJumpControls` now reuse the existing
`MockExamHeaderControlLayout` without changing that layout's measurement or
placement algorithm. Each group has one child tree. It measures the ideal
horizontal stack and selects the same leading vertical stack if it does not
fit; accessibility Dynamic Type retains forced vertical placement. Existing
spacing, alignment, fonts, colours, controls and actions are unchanged. There
are no point-width thresholds, rejected candidate trees or new audit exceptions.

The compact question navigator always has a ScrollView. A GeometryReader
supplies the actual available height as the default-size content's minimum
height, centering the original content when it fits and allowing natural-height
content to scroll when it does not. Its original paper background stays on the
content rather than painting the formerly system-background margins. AX content
keeps its existing top alignment and full paper background. Regular-width iPad
navigation remains inline and unchanged.

The new source-named UI regression,
`CanadianHamPracticeUITests.testHundredQuestionMockExamNavigatorReachesLastQuestionInPortraitAndLandscape`,
launches the real Basic exam without `CanadianHamMockExamLimit`. It checks
`Question 1 of 100`, opens the navigator, scrolls until question 100 is fully
inside its viewport and hittable, taps it, verifies its current-question state,
and returns to `Question 100 of 100`. Both portrait and landscape run on each
device; iPhone exercises the sheet and iPad the inline navigator. Existing
assertions, audits, audit handlers and shared positioning helpers are untouched.

## Native visual comparison method

This follows [TASK-74's evidence method](task-74-ipad-mock-audits.md): temporary
XCTest probes attach native PNGs and complete accessibility hierarchies,
using one xbuild destination and one test worker per run. Both versions use the
same English/Canadian locale, seed `ui-task77-header`, first question
`B-001-002-002`, one-question limit, timer off, and explicit default (`L`) or
AX-XXXL content-size category. Each image settles for two seconds before capture.
Portrait captures use `XCUIApplication.screenshot()`; the corrected landscape
captures use `XCUIScreen.main.screenshot()`. No probe or diagnostic app variant
is shipped.

Baseline app source is `3872dc5410517d64172ed1b20c2d7f3d287eb606`;
the header implementation is `343bbf49853e099d54de45c66c4f1f7577ae9267`.
Subsequent container-only changes do not alter any header pixel. Before/after
PNG names, SHA-256s, result-bundle paths, native comparison rectangles and control
frames are recorded in the evidence JSON under `docs/evidence/task-77/`.
Before images and all full result bundles remain under `/tmp/task77-*`; only a
few representative native after images are committed.

Losslessly apply the PNG EXIF orientation before comparison (no resampling),
then compare RGB pixels below the unchanged navigation bar for header captures,
and the entire modal below the status bar for fitting-sheet captures. Exclude
only system/navigation chrome, not app content, scroll indicators or antialiased
pixels. Window and navigation geometry must match. There are no tolerance masks
or colour/antialiasing allowances. Reproduce a recorded comparison with Pillow:

```python
from PIL import Image, ImageChops, ImageOps
before = ImageOps.exif_transpose(Image.open(before_path)).convert("RGB")
after = ImageOps.exif_transpose(Image.open(after_path)).convert("RGB")
diff = ImageChops.difference(before.crop(tuple(native_box)), after.crop(tuple(native_box)))
assert diff.getbbox() is None
```

The matrix includes iPad portrait default with the inspector closed and open,
iPad portrait AX-XXXL, and iPhone portrait/landscape at default and AX-XXXL,
all in light and dark. Header control frames identify both the flag-group and
quick-jump axes, proving horizontal and vertical selections. Supplementary AX
captures explicitly position the early controls as well as the lower controls;
no offscreen frame is presented as proof of visible pixel parity.

## Final appearance results

[The numeric ledger](../evidence/task-77/visual-diffs.json) contains **34/34 exact
matches**: 32 header views and two complete fitting-sheet views. Every comparison
has **0 differing pixels** and **0 maximum channel difference**. All 12 corrected
landscape pairs use full-screen captures; all 24 source landscape images have
correct native geometry and **0 all-black columns / 0 all-black rows**. The 12
positioned AX comparisons additionally record that the target is fully inside
the visible body in both versions.

Six "-lower" records (iPad AX-XXXL, iPhone landscape AX-XXXL and iPhone portrait
AX-XXXL, each in light and dark) repeat their base case: the captures weren't
taken at a different scroll position, so their hashes and control frames match
the base records. That leaves **28 distinct exact comparisons**. The early
controls are still covered by the positioned `-flag`, `-questions` and
`-unanswered` AX captures.

| Header selection | Cases that prove it |
| --- | --- |
| Horizontal flag group, horizontal quick jumps | iPad default (inspector closed/open), iPhone landscape default; light/dark |
| Vertical flag group, horizontal quick jumps | iPhone portrait default; light/dark |
| Vertical flag group, vertical quick jumps | iPad and iPhone AX-XXXL; iPhone portrait/landscape, including fully positioned early controls; light/dark |

Only four representative native after PNGs are kept:
[iPad dark inspector](../evidence/task-77/after-ipad-header-portrait-default-dark-inspector.png),
[iPhone default landscape](../evidence/task-77/after-iphone-header-landscape-default-light.png),
[iPhone AX-XXXL Questions](../evidence/task-77/after-iphone-header-portrait-AXXXL-light-questions.png),
and [reachable question 100 in landscape](../evidence/task-77/after-iphone-navigator-landscape-question-100.png).
Three matching full hierarchies are also kept. The entire evidence directory is
**1,292,650 bytes** (about 1.3 MB), including JSON and its
[SHA-256/size manifest](../evidence/task-77/evidence-manifest.json). Native PNG
bytes, including EXIF orientation, are preserved; use the lossless normalization
above when a viewer does not honour orientation.

## Final product validation

All ten requested product methods pass on each device. The final compact-sheet
container is `b78985c983d47798d0d4bcd19f17c40ebb694eb5`. The four affected iPhone
Practice methods were rerun on that implementation; the six ExamTools methods
do not open this navigator, and their green header/reference-sheet results carry
forward unchanged. iPad uses the unchanged inline navigator, so its ten results
also carry forward through the compact-container-only refinement.

The full per-test ledger, destinations, log paths and result bundles are in
[the test-results JSON](../evidence/task-77/test-results.json). There are no skipped product tests.

| Method (under `CanadianHamUITests/`) | iPad Pro 13-inch (M5) | iPhone 17 Pro |
| --- | --- | --- |
| `CanadianHamExamToolsUITests/testAdvancedMockExamHasNoBasicReferenceSheetOrHints` | PASS 19.377 s | PASS 38.657 s |
| `CanadianHamExamToolsUITests/testMockExamCodeCaptionAccessibilityBoundsLightAndDark` | PASS 31.675 s | PASS 48.094 s |
| `CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetDarkPreservesPausedExam` | PASS 106.693 s | PASS 209.385 s |
| `CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetLightPreservesRunningExam` | PASS 140.035 s | PASS 202.793 s |
| `CanadianHamExamToolsUITests/testOfficialReferenceSheetLightAndDarkEnglishAndFrench` | PASS 186.827 s | PASS 260.981 s |
| `CanadianHamExamToolsUITests/testReferenceSheetLargestDynamicTypeKeepsControlsReachable` | PASS 38.330 s | PASS 128.545 s |
| `CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowDark` | PASS 96.489 s | PASS 142.542 s |
| `CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowLight` | PASS 98.130 s | PASS 144.142 s |
| `CanadianHamPracticeUITests/testMockExamHeaderControlsSupportLargestAccessibilityTextSize` | PASS 51.386 s | PASS 85.549 s |
| `CanadianHamPracticeUITests/testHundredQuestionMockExamNavigatorReachesLastQuestionInPortraitAndLandscape` | PASS 92.446 s | PASS 119.842 s |

Final macOS `build-for-testing` passes, including UI-test compilation, with every
scratch probe removed before the build. Its log is
`/tmp/task77-macos-final-build.log` (`TEST BUILD SUCCEEDED`, exit 0). The subsequent local attachment API change is inside the new method’s
`#if os(iOS)` body only; no macOS-visible source changed. No unit/model logic
changed, and a macOS unit run was not requested.

### Run ledger and reproduction

Every Apple runner uses `xbuild`, waits for the shared lock, exports
`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` and
`XBUILD_TEST_WORKERS=1`, and uses one destination. No other build was killed by
this worker and no simulator was booted manually. The long shared-lock wait and
session revival did not alter the test selections or audit requirements.

| Run stem under `/tmp/` | Selection / result |
| --- | --- |
| `task77-before-ipad` | Baseline main appearance probe PASS, 106.539 s |
| `task77-before-iphone` | Baseline main appearance probe PASS, 272.889 s |
| `task77-final-ipad` | Nine original TASK-74 product methods PASS |
| `task77-final-iphone` | Nine original TASK-74 product methods PASS |
| `task77-after-ipad` | Main appearance probe PASS 102.279 s; new full-grid method PASS 92.446 s |
| `task77-after-iphone` | Main appearance probe PASS 304.174 s; new full-grid method PASS 111.605 s |
| `task77-sheet-fix-iphone` | Fitting-sheet probe PASS 60.677 s; all four affected product methods PASS (table above) |
| `task77-before-ax-iphone` | Fully positioned baseline AX probe PASS, 506.544 s |
| `task77-after-ax-fixed-iphone` | Matching positioned AX probe PASS, 504.434 s |
| `task77-before-landscape-screen` | Corrected full-screen landscape baseline probe PASS, 423.610 s |
| `task77-after-landscape-screen` | Matching full-screen probe PASS 324.026 s; local-attachment full-grid rerun PASS 119.842 s |

Each test stem has both `.log` and `.xcresult`. The actual runners remain
`/tmp/task77-{baseline,after,final,sheet-fix,ax-baseline-and-mac,ax-after-fixed,landscape-screen}.sh`.
The original final runner selected the first nine methods above on each device;
the new full-grid method ran in the two `after` bundles, the affected iPhone
fix round selected the four Practice methods, and the screenshot-only revision
reran only the new method once on iPhone (iPad was unaffected). No full Apple suite was run.
To reproduce the entire product set in one run, use this template and add an
`-only-testing:CanadianHamUITests/<class>/<method>` argument for each of the ten
rows above:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export XBUILD_TEST_WORKERS=1
xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testHundredQuestionMockExamNavigatorReachesLastQuestionInPortraitAndLandscape \
  -resultBundlePath /tmp/task77-reproduction.xcresult test CODE_SIGNING_ALLOWED=NO
# iPad destination: 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'
```

The final macOS command is:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests \
  build-for-testing SDKROOT=macosx SUPPORTED_PLATFORMS=macosx \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

### Disclosed evidence iterations

The initial ScrollView container made the entire fitting sheet paper-coloured,
where the old fitting VStack had system-background margins. Its scroll-anchor
centering also introduced a small rasterization difference. The dedicated
fitting-sheet comparison caught this despite all product methods passing.
The measured-height container preserves both the original background extent
and centering: the corrected full-modal light/dark comparisons each have **zero
differing pixels**. Original mismatches remain in
`/tmp/task77-initial-visual-diffs.json` and the initial images; they are not counted
as final parity and are not committed.

The first supplementary AX probe used coarse swipes and oscillated past a
partially visible landscape flag button (diagnostic-only FAIL, 314.407 s in
`/tmp/task77-after-ax-iphone.xcresult`). The temporary probe now uses the existing
unchanged precise-scroll helper, and asserts each target is fully visible and
hittable before attaching its image. Both corrected positioned probes pass. No product assertion or audit was removed,
weakened or replaced, and no new exception was added.

### Landscape screenshot correction (also applies to TASK-74)

Final evidence inspection found that `XCUIApplication.screenshot()` landscape
PNGs were truncated: they had a 2622×1206 raw raster with EXIF orientation 8,
a 1416-column full-height black strip (1,707,696 pixels), and only part of the
rotated app. Numeric parity between those images did **not** prove whole-screen
landscape parity. TASK-74 used the same API; its historical landscape claim
therefore rested on partial images, as corrected in that document.

Under coordinator approval, only the landscape evidence is replaced using one
baseline and one after run with `XCUIScreen.main.screenshot()`. The new full-screen
PNGs have a 1206×2622 raw raster with EXIF orientation 8; lossless orientation gives
the correct 2622×1206 native landscape screen matching the 874×402 point window.
`visual-diffs.json` records raw/oriented sizes, EXIF orientation, screen API,
comparison bounds and black-column/row measurements. The 12 replacement pairs
are pixel-identical over the complete visible body; this supersedes the earlier
partial-image comparisons. No image is resized or
colour-adjusted. Portrait captures and fitting-sheet captures are unchanged.
The new full-grid test changes only its own local attachment to the full-screen
API; all assertions, shared screenshot/positioning helpers and audits stay intact.

### Scope of platform and static checks

`StudyViews.swift` belongs only to the iOS/macOS `CanadianHam` target in
`project.yml`, not TV, vision or watch. Those platform suites are not run; no
shared package, target membership or string catalogue changed. Full iOS suites
remain the coordinator's merge-batch responsibility. This worker created no PR
or distribution build.

Final static checks (all PASS):

- `node scripts/check-apple-text-sources.ts` (`/tmp/task77-text-sources.log`).
- `node scripts/check-test-guard.mjs --self-test` (`/tmp/task77-guard-self-test.log`).
- `node scripts/check-test-guard.mjs --base 3872dc54 --head HEAD`
  (`/tmp/task77-guard.log`): **no guarded changes**, no approval marker needed.
- `git diff --check`.
- `CanadianHamExamToolsUITests.swift` is byte-identical to the base after removing
  scratch probes; the only Practice test change is the new method. Existing
  audit/positioning helpers and every original assertion/audit remain unchanged.
- All evidence manifest hashes/sizes match; 34 native comparisons are exact,
  native scale/window geometry matches, and no truncated landscape PNG ships.
