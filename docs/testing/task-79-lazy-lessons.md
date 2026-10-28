# TASK-79: lazy lesson reader

**Status: implementation in progress; full validation not yet complete.**

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
- `/tmp/task-79-navigation-fix.{sh,log,xcresult}`: targeted fix validation.
- `/tmp/task-79-figures.{sh,log,xcresult}`: full `CanadianHamLessonFigures` plan.
- `/tmp/task-79-{baseline,after,figures}-load.log`: command-wide UTC/load samples.

The complete requested figure, targeted reader/iPad, macOS, repeated M7/Ohm,
platform-build and localization results will be recorded after they finish.
The task is not claimed complete based on smoke/count evidence alone.
