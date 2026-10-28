# TASK-79: lazy lesson reader

**Status: blocked, not complete.** The lazy prototype substantially reduces the
accessibility tree but introduces Dynamic Type and contrast audit regressions.
Three bounded app-side attempts failed and were reverted, including the final
coordinator-authorized per-block accessibility-container experiment. TASK-79
remains In Progress, with no acceptance criteria checked. The required failure
branch is complete: preserve evidence, push and stop; the coordinator will close
the lazy approach.

`Platforms/Shared/PlatformLessonMarkdownView.swift` now renders its blocks in a
`LazyVStack`, with each heading anchor on the direct lazy child rather than inside
its not-yet-built heading. The existing iOS/macOS, tvOS and visionOS
`ScrollViewReader`s continue to handle anchor navigation. Alignment, spacing,
padding, colours, cards, text, heading traits and disclosure views are unchanged.
There is no audit retry, audit filter, new exception or timeout increase.

## Tree counts

The new `testLessonReaderTreeCountsAtTop` captures whole-application XCTest query
counts at the **top**, not only visible/focusable elements. All counts use one
launch per lesson with collapsed disclosures on iPhone 17 Pro, iOS 27.0 (24A434).
L-008-01 is the longest bundled lesson by UTF-8 Markdown byte count (25,027 bytes).

| Lesson | Eager descendants / static texts | Lazy descendants / static texts |
| --- | ---: | ---: |
| L-005-02 | 330 / 285 | 59 / 27 |
| L-007-01 | 285 / 235 | 56 / 26 |
| L-008-01 | 316 / 267 | 58 / 25 |

The eager app is from `e0e3ed7634f04bfae54039ced91b36f284bd4e89`; the lazy app is
from the commit named in [the evidence JSON](task-79-evidence.json). The baseline
binary was fully compiled before editing the reader. Both count runs passed.

The earlier [TASK-65 measurements](task-65-flakes.md) were taken **at the figure**,
not at the top: their 331/286 descendants must not be substituted for these top
counts. TASK-65 also records the Code=-56 failure approximately 16 seconds into
the audit, passing M7 screenshot-to-termination intervals of approximately
12–17 seconds, and all baseline whole-method times. Those intervals are not
precise audit durations and are not represented as such here.

## Appearance

`testLessonReaderAppearanceAtTopMiddleAndBottom` captures
`XCUIScreen.main.screenshot()` (never the application screenshot) for L-005-02:
reader top, the `ohms-law` anchor, and the final `summary` anchor; light/dark;
default/AX-XXXL. The JSON records SHA-256 for both PNG bytes and decoded RGBA
pixels, full-image difference bounds, content-region hashes/deltas, and registered
region offsets/deltas. Four representative **after** PNGs are committed under
`docs/testing/task-79/`, totalling 1,112,236 bytes. All 24 original PNGs remain in
the local exported attachments.

None of the twelve whole-screen pairs is literally pixel-identical: the clock
changed, and the system glass back button has small rasterization differences.
Below the navigation bar (native-pixel rectangle `[0,350,1206,2622]`), all **six
AX-XXXL samples are exactly pixel-identical**. Default-size differences are:

- Top: prerequisite-link text is 1 native pixel (1/3 pt) higher; after registration
  it is pixel-identical in both appearances.
- Middle: heading/table are 1 native pixel higher, with registered per-channel
  residuals at most 2/255. Figure/table edges also show subpixel rasterization.
- Bottom: summary text is exactly identical, with zero registration offset.
  Footer controls are 1 native pixel lower in light and **3 native pixels (1 pt)
  lower in dark**, from lazy-stack total-height rounding. Registered per-channel
  residuals are at most 3/255.

Unregistered content channel deltas reach 224/255 where a high-contrast edge
moves; this is not a colour/style change. There is **no growing text drift**:
maximum sampled text registration magnitude remains 1 pixel from top to middle,
and is zero at the bottom summary. The footer's separate 1- or 3-pixel boundary
shift is reported rather than hidden. There is no text, wrapping, spacing-token,
colour, size or style change.

The coordinator explicitly approved these exact differences on 2026-10-27,
including the corrected +3-pixel dark footer measurement, for TASK-79 AC4.

## Tests and necessary test adaptation

New tests cover top counts, appearance, reaching offscreen headings in authored
reading order, preserving an expanded Try-it answer across scrolling, deep-anchor
navigation, and returning from an enlarged figure without a scroll jump. The
heading `.isHeader` and accessibility focus modifiers remain intact.

The first lazy smoke run passed appearance capture (141.269 s), figure return
(33.458 s), and counts (41.228 s), but the offscreen-heading test failed in the
pre-existing Practice `scrollUntilPartiallyVisible`: it read `.frame` on a lazy
target that did not yet exist. This failed result is retained, not counted as a
pass. The coordinator approved the following **only** adaptations:

1. Add `element.exists,` before that frame read, matching the figure-class helper.
   Behavior for an existing target is unchanged. No assertion/audit was removed.
2. In the TASK-65 structural figure test, scroll to each figure before its
   **unchanged** uniqueness assertions. Add a regression assertion that the distant
   wheel does **not** exist in the tree at launch. All collapsed/expanded row
   count and uniqueness assertions remain unchanged.

Every accessibility audit/handler and all other pre-existing shared helpers
remain byte-identical to main. Test guard and text-source checker/self-tests
passed after the implementation and these adaptations.

## Local evidence and reproduction

All Apple work uses `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
and `xbuild`, serial testing, and one destination per invocation. No other lane's
process is stopped. Baseline/after load is sampled every minute; the one-minute
load exceeded 600 during both runs, so these are **not normal-load** measurements.

- `/tmp/task-79-baseline.{sh,log,xcresult}`: 2/2 tests passed; appearance 183.893 s,
  counts 41.418 s. Export: `/tmp/task-79-baseline-attachments/manifest.json`.
- `/tmp/task-79-after.{sh,log,xcresult}`: first lazy smoke, 3/4 passed as above.
  Export: `/tmp/task-79-after-attachments/manifest.json`.
- `/tmp/task-79-navigation-fix.{sh,log,xcresult}`: targeted fix validation **passed**,
  offscreen headings/Try-it persistence 566.029 s.
- `/tmp/task-79-figures.{sh,log,xcresult}`: interrupted first full
  `CanadianHamLessonFigures` plan; not a passing full run.
- `/tmp/task-79-{baseline,after,figures}-load.log`: command-wide UTC/load samples.

## Blocking figure-audit regression

The first full figure plan was stopped with coordinator approval, by sending
SIGINT **only** to this task's figure-plan `xcodebuild` process. The bundle
finalized, exit 75 (`TEST INTERRUPTED`):

| Method | Result | Whole-method seconds |
| --- | --- | ---: |
| Structural collapsed/expanded uniqueness and lazy-launch regression | Pass | 684.430 |
| M1 dark sample | Pass | 201.552 |
| M1 light Part1 | Fail: Dynamic Type unsupported | 156.861 |
| M1 light Part1NextLesson | Fail: Dynamic Type unsupported | 155.781 |
| M1 light Part2 | Fail: contrast on visible paragraph | 153.659 |
| M1 light Part3 | Cancelled, not a completed failure | — |

Later methods were not run. The summary's four failed entries include that one
cancelled method; there are **three real completed failures**, not four. The
console mislabeled Part2's error; its finalized issue and screenshot establish
that it is contrast, not a third Dynamic Type finding. No Code=-56 occurred in
these completed visits, which is not consecutive M7/Ohm evidence.

### Once-only eager main comparison

The unchanged first failing M1 light method **passed 388.729 s** in a detached
worktree at `origin/main` commit
`6a449802614303741ee5aa07f973803c46f535b7` (TASK-80 merge). The reader is byte-identical
to the original task base, SHA-256
`0afefb2d2a8ca18c9f522db979ed61a1f05738ef9d5aac6cdc660213c648f7fb`.
Command/bundle: `/tmp/task-79-main-comparison.{sh,log,xcresult}`, exit 0. The
comparison ran **once**, before the app-side attempts/diagnostic below, and the
detached worktree was removed afterwards. Thus this is a lazy-reader regression,
not a known pre-existing main failure.

### Bounded attempts and scratch diagnostic

1. Explicit semantic `.body` on the disclosure control plus intrinsic vertical
   label sizing: all three M1 light methods still failed (239.186, 114.566,
   207.636 s). Attempt `16bd8b01`, reverted `2a83b14f`; no such lines remain.
2. A coordinator-approved, **temporary uncommitted** scratch method ran the full
   default audit with a local closure that only logged and returned `false` for
   every finding. It never filtered/ignored anything and deliberately failed
   (177.090 s). The scratch method was deleted immediately after export and
   **was never committed**. The shared audit handler was never edited.
3. Coordinator-approved disclosure `.id(dynamicTypeSize)` experiment, with
   expansion state outside that identity to avoid resetting it during re-layout:
   first M1 light method still failed Dynamic Type (206.499 s). Attempt
   `df489404`, reverted `5a932cc7`. Neither identity nor extra state remains.
   The coordinator's explicit failure branch required stopping there. A later
   direction authorized only the final containment experiment documented below.

The diagnostic finding is `.dynamicType` raw value 65536, `StaticText` with label
`Figure text equivalent`, at `(52,199,298,28.333)` points. The before-audit tree had
the same label at `(52,872,298,28.333)`, partly below the 874-point viewport. During
the audit, content height changed from 5951.3 to 5743.3 points, scroll-content
minimum Y from -2759 to -2958, and the label was brought to Y=199 without a height
change. This suggests lazy re-layout/AX lifecycle interaction, **not proof of
node reuse**. The semantic font was already correct; adding a font or forcing
vertical intrinsic size did not resolve it.

Full element description/path:
`/tmp/task-79-diagnostic-attachments/AEA1D142-DD45-4417-AC3D-7A12CAC168F4.txt`.
Before tree:
`/tmp/task-79-diagnostic-attachments/A14DF995-2BEF-4440-8E68-71A76E6B888F.txt`.
The issue description and screenshots for the original failures are exported in
`/tmp/task-79-figures-failure-attachments/manifest.json`.

[Per-test results JSON](task-79-results.json) preserves every completed run,
including failures, the cancelled method, diagnostic status, exact source SHAs
and sampled load ranges. Those timings are **whole methods**, not individual
full-audit timings. The required per-audit duration comparison for L-005-02,
L-007-01 and the longest lesson remains uncollected; no performance/acceptance
claim substitutes method durations for it.

## Final per-block containment experiment — failed and exactly reverted

The coordinator authorized **one final app-side experiment**: give each direct
lazy child a `VStack(alignment: .leading, spacing: 0)` container with
`.accessibilityElement(children: .contain)`. The existing stable `ForEach`
`DisplayLessonBlock.id` and direct-child heading-anchor/fallback IDs were retained.
No child, label, heading trait or control was removed/combined/hidden. Test guard
self-test and the actual branch diff passed with `.contain` present; the guard
matches `.ignore` and bare `.accessibilityElement()`, not `.contain`.

Attempt: `e7a03cf5d64f4613c10e3cd72eb7189f0e175dc7`. Each requested method ran
**once**, in its own serial `xbuild` invocation on iPhone 17 Pro, in the
`CanadianHamLessonFigures` plan with exactly one `-only-testing` method selected.
The finalized bundles each report `Test case with 1 run`. All three failed:

| M1 light method | Whole-method seconds | Issue / StaticText label | Screenshot-derived frame (points) | One-minute load min–max (samples) |
| --- | ---: | --- | --- | --- |
| Part1 | 179.412 | Dynamic Type / `Figure text equivalent` | `(52, 199, 298, 28)` | 72.84–434.12 (4) |
| Part1NextLesson | 204.911 | Dynamic Type / `Club-net plans` | `(52, 193, 83.667, 14.333)` | 395.32–466.08 (5) |
| Part2 | 174.877 | Dynamic Type / `Identify the station, not just the person speaking. Every station in a contact sends its own call sign. Starting, ending and interval identification are separate duties.` | approximately `(40, 191.333, 322, 86)` | 343.21–430.49 (4) |

All three finalized issue descriptions say `Dynamic Type font sizes are partially
unsupported` / `User will not be able to change the font size of this
SwiftUI.AccessibilityNode`. Part2 is **Dynamic Type in this experiment**, unlike
the original lazy-plan contrast failure. All invocations exited 65; none was
interrupted, retried or skipped. No Code=-56 occurred, but these were not the
required consecutive M7/Ohm runs or normal-load measurements.

**Frame provenance:** the immutable shared handler does not log the AX frame.
The frames above are reconstructed from the failure app/element screenshots at
3 native pixels per point, **not claimed as exact AX-frame measurements**. Part1
and NextLesson each have a unique, exact whole-element RGB crop match at native
pixel bounds `[156,597,894,84]` and `[156,579,251,43]`. Part2 has subpixel text
rasterization differences; its best RGB crop near the visible paragraph is
`[120,574,966,258]`, mean absolute channel delta 3.621/255, maximum 100/255. Its
position is approximate. Screenshot paths/hashes, matching details, full labels,
commands, source commit, per-method results and load ranges are in the results
JSON; every original failure screenshot is preserved locally.

Artifacts: `/tmp/task-79-contain-{part1,next-lesson,part2}.{log,xcresult,exit}`,
`-load.log`, `-details.json`, and `-attachments/manifest.json`; driver
`/tmp/task-79-contain.sh`. The unchanged XCTest runner also logged a **post-failure**
error72 collecting simulator diagnostics (`simctl` lookup failed). The audit
failures, issue screenshots and one-run test results all finalized successfully;
this warning is not the reason the tests failed.

The experiment was exactly reverted in
`a08980ac89535a838bfb7cc0076c81c4e74645fe`. The reader is byte-identical to both
resumed HEAD `dde54540f5113e9a87746dbfffcf87697cef7dee` and the original lazy
prototype, SHA-256
`372ea91b3d528f9298e2c1b0ecc5e29a8dcc9fd51ee1df6eb3f9bffdfe6d3c93`.
Both UI test files are byte-identical to resumed HEAD, including all shared
handlers. No containment code remains. Per the explicit failure branch, no
navigation/state/figure-return/count reruns, full figure plan or repetitions were
launched after these failures. No further app-side experiment is authorized.

## Remaining checks and handoff

The complete figure plan/restart, existing targeted reader tests, five-iteration
M7/Ohm run, targeted iPad tests, title sweeps, macOS unit/build-for-testing,
tvOS/visionOS builds and full localization export were **not run/completed**.
The new navigation/state/figure-return tests and top descendant counts were not
rerun with containment because the required all-three-pass gate failed. The
coordinator's failure branch stops further work; these checks are not waived.
Both tvOS and visionOS compile the shared reader per `project.yml`; watchOS does
not compile it.

Text-source checker/self-test, test-guard/self-test, diff whitespace and source
identity checks pass. No retry wrapper, audit narrowing, new exception, skip,
`.ignore`/hidden accessibility content, or weakened assertion exists. The only
pre-existing helper change is the expressly approved existence guard; the
structural assertions remain intact with the approved navigation/lazy assertion.

The final stable `.contain` direction failed and is reverted. The coordinator
will close the lazy approach; no further architecture change or validation run
is authorized here. The task is not claimed complete based on tree/appearance
evidence alone. Updated handoff: `/tmp/task-79-handoff.md`.
