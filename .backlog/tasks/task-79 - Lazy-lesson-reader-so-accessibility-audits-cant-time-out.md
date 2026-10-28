---
id: TASK-79
title: Lazy lesson reader so accessibility audits can't time out
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-28T01:32:00Z'
updated_date: '2026-10-28T03:39:00Z'
labels:
  - accessibility
  - performance
dependencies: []
priority: medium
ordinal: 164000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner 2026-10-27, on TASK-65: 'Fix it so timeout isn't really possible' and lazy long lessons approved. The lesson reader builds every block eagerly: a collapsed L-005-02 exposes 331 descendants and 285 static texts, L-007-01 286/235. Figure audits intermittently fail with XCTest Code=-56 'Audit failed to complete in time' under load (M7 1/5). Make the reader lazy (LazyVStack or equivalent) so the accessibility tree, and the audit, cover roughly what's on screen. No retry wrapper.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The lesson reader (iOS/iPadOS/macOS, and other platforms that share it) builds blocks lazily. VoiceOver reading order, headings/rotor navigation, Try-it and hint anchors, figure focus and scroll-to-anchor still work, and a test proves each
- [ ] #2 Before/after descendant counts and full-audit durations are recorded for L-005-02 and L-007-01 (and the longest lesson). The audit time drops enough that Code=-56 doesn't occur in 10 consecutive runs of the M7 and Ohm's-law figure tests under normal machine load
- [ ] #3 Every existing lesson, figure and title test and audit passes unchanged: the full CanadianHamLessonFigures plan plus the targeted lesson-reader tests, with no new exceptions, skips or helper weakening
- [ ] #4 Appearance is unchanged: before/after screenshots of representative lessons (top, middle, bottom; light and dark; default and AX sizes) are pixel-identical, or any difference is explained and approved
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect reader, block identity, anchors, figure focus and existing immutable audit helpers; add bounded baseline count/screenshot coverage before the lazy change.
2. Convert shared reader block layout to lazy rendering without appearance or audit changes; add focused navigation/heading/state tests.
3. Capture after counts and screenshot hashes, run the figure plan once and targeted reader/iPad/macOS/platform checks, then five M7/Ohms repetitions within the five-hour budget.
4. Commit/push milestones, record exact results and unresolved evidence, and hand off at five hours if validation is incomplete.

5. STOPPED under coordinator decision after the one Dynamic Type identity experiment failed; preserve the lazy prototype/evidence and hand off before any containment/grouping or partial-laziness architecture change. Remaining runtime validation is blocked, not waived.

6. Coordinator-authorized FINAL app-side experiment: wrap each direct lazy child in an accessibility contain container, retaining the existing block identity and heading anchor. Run M1 light Part1, NextLesson and Part2 once each serially on iPhone 17 Pro. If any fails, restore the exact reader, record issue types/elements/frames and load, update handoff, push and stop. If all pass, rerun new navigation/state/figure-return/count tests only, then push and hand off remaining long/platform validation.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Milestones pushed: e0e3ed7634f04bfae54039ced91b36f284bd4e89 adds baseline capture tests; 183c6870 converts shared LessonMarkdownView to LazyVStack with IDs on direct children and adds offscreen heading/Try-it-state and figure-return tests. Existing Practice/figure tests and all shared helpers/audits verified byte-identical to main (strip only new methods and compare entire files). Baseline /tmp/task-79-baseline.xcresult passed 2/2: appearance 183.893 s, top counts 41.418 s. At top: L-005-02 330 descendants / 285 static texts; L-007-01 285 / 235; longest UTF-8 lesson L-008-01 316 / 267. Twelve full-screen before-images exported to /tmp/task-79-baseline-attachments; after smoke and full figure plan queued. Load sampled each minute; one-minute average exceeded 600 during baseline; no other processes modified.

Coordinator approval 2026-10-27: Practice scrollUntilPartiallyVisible now checks element.exists before reading its frame, matching the existing figure-class helper. Existing-element behavior and every assertion/audit unchanged. This is required because lazy offscreen targets do not exist yet; smoke failure at the old unguarded .frame is preserved in /tmp/task-79-after.xcresult (3/4 passed; offscreen-heading test failed). Coordinator also approved scrolling to each figure before TASK-65 structural uniqueness assertions, which are unchanged, plus a new assertion that the distant Ohms wheel is absent at launch. No other pre-existing helper or audit changed. After top counts: 59/27, 56/26, 58/25 descendants/static texts for L-005-02/L-007-01/L-008-01; figure sheet-return test passed 33.458 s; appearance capture passed 141.269 s.

AC4 coordinator approval 2026-10-27: all six AXXXXL lesson-content samples pixel-identical; default top/middle text +/-1 native pixel, bottom summary exact; footer +1 px light / +3 px dark (1 pt), registered residuals <=3/255; system clock/glass-back chrome and subpixel figure/table rasterization differ. No growing text drift, text/wrapping/spacing tokens/colour/size/style change. Exact raw/registered deltas and hashes in docs/testing/task-79-evidence.json; four after-images total 1,112,236 bytes, originals local. Approved differences accurately include corrected 3-px dark footer case.

The single targeted rerun after the approved existence guard passed: testLessonReaderOffscreenHeadingsAndTryItStateSurviveScrolling 566.029 s, /tmp/task-79-navigation-fix.xcresult, exit 0. This verifies beyond-first-screen headings in authored order and Try-it expansion retained after scrolling down to Summary and back, then collapse. Full figure-plan driver is now waiting on the shared xbuild lock. No test/audit skipped or filtered beyond the explicitly selected targeted test invocation.

Coordinator-approved early stop of first full figure plan after failures: /tmp/task-79-figures.xcresult finalized (exit75 following SIGINT, not timeout); structural test PASS 684.430 s; M1 dark PASS 201.552 s; M1 LightPart1 FAIL 156.861 s and NextLesson FAIL 155.781 s (Dynamic Type unsupported on Figure text equivalent); M1 LightPart2 FAIL 153.659 s (contrast on visible ordinary paragraph); Part3 cancelled, all later methods not run. No Code=-56. Complete issues/element screenshots exported to /tmp/task-79-figures-failure-attachments; originals retained. First failing M1 light method then PASS on detached origin/main 6a449802614303741ee5aa07f973803c46f535b7: 388.729 s, /tmp/task-79-main-comparison.xcresult, exit0. Reader SHA256 byte-identical to original main; detached comparison worktree removed. This establishes a lazy-reader regression, not a passing full plan. Investigating app-side control font/layout; audits/handlers untouched.

Blocked; stopping per coordinator explicit failure branch, not marking Done. Required eager main baseline was completed ONCE and PASS (388.729 s, origin/main 6a449802, result bundle main-comparison). Temporary diagnostic never committed and removed: dynamicType raw65536, Figure text equivalent StaticText frame before (52,872,298,28.333), at issue (52,199,298,28.333); scroll/content geometry changed during audit. No conclusive proof of node reuse. Semantic-font/intrinsic-height attempt failed all3 and reverted 2a83b14f. Coordinator-approved disclosure id(dynamicTypeSize) experiment also FAILED first method 206.499 s (/tmp/task-79-dynamic-type-id.xcresult, exit65), reverted 5a932cc7. Source is exactly the first lazy prototype again; no rejected fixes/grouping remain. Shared audit handlers untouched; approved existence guard and structural navigation/assertion are the only old-test adaptations. Full results/issues/remaining checks are committed in docs/testing/task-79-{lazy-lessons.md,results.json,evidence.json}. Full figure completion, repeated M7/Ohm, targeted old reader/iPad/title tests, macOS, tvOS/visionOS builds and full l10n export outstanding; individual audit-duration comparisons outstanding. Source/text/guard self-tests and parity checks pass; no skips/exceptions/retry wrapper. All ACs remain unchecked. Handoff /tmp/task-79-handoff.md; no PR.

Resumed under coordinator's bounded containment experiment direction. Fully read /tmp/task-79-handoff.md and AGENTS.md; previous attempts remain reverted and all ACs unchecked. No full plan, repeated iterations, audit changes, exception/filter/skip/retry/ignore or hidden content authorized.

FINAL containment experiment completed under coordinator direction and FAILED all3, then exactly reverted. Attempt e7a03cf5d64f4613c10e3cd72eb7189f0e175dc7; revert a08980ac89535a838bfb7cc0076c81c4e74645fe. One serial xbuild invocation per M1 light method in CanadianHamLessonFigures, iPhone17Pro, exactly1 visit each: Part1 FAIL179.412s, NextLesson FAIL204.911s, Part2 FAIL174.877s; all finalized Dynamic Type unsupported, exit65, no cancellation/retry/Code=-56. Elements: Figure text equivalent; Club-net plans; Identify the station, not just the person speaking... paragraph (full label committed). Shared handler does not log AX frames; failure screenshot-derived bounds in points: (52,199,298,28), (52,193,83.667,14.333), and approximate (40,191.333,322,86). First2 unique exact RGB crop matches; Part2 subpixel-rasterization best match, explicitly not exact AX geometry. Per-test one-minute load min-max:72.84-434.12(4),395.32-466.08(5),343.21-430.49(4), command-wide including build/lock wait; not normal-load evidence. Bundles /tmp/task-79-contain-{part1,next-lesson,part2}.xcresult; all issues, attachment paths/hashes, frame provenance, commands and load in results JSON/docs. Post-failure simulator diagnostic collection warned simctl lookup failed, but completed audit failures/screenshots/bundles finalized. Test guard/self-test passed with .contain present. Reader restored byte-for-byte to resumed HEAD/original lazy prototype (SHA256 372ea91b3d528f9298e2c1b0ecc5e29a8dcc9fd51ee1df6eb3f9bffdfe6d3c93); entire UI test files/shared handlers unchanged. No hidden content, new exception/filter/skip/retry/ignore, audit/helper weakening or timeout change. Failure branch: no navigation/count reruns, full figure plan or repetitions launched; no further experiment. All ACs unchecked; In Progress/blocked, coordinator will close lazy approach. Updated /tmp/task-79-handoff.md; push and stop.
<!-- SECTION:NOTES:END -->
