---
id: TASK-79
title: Lazy lesson reader so accessibility audits can't time out
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-28T01:32:00Z'
updated_date: '2026-10-28T02:16:00Z'
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
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Milestones pushed: e0e3ed7634f04bfae54039ced91b36f284bd4e89 adds baseline capture tests; 183c6870 converts shared LessonMarkdownView to LazyVStack with IDs on direct children and adds offscreen heading/Try-it-state and figure-return tests. Existing Practice/figure tests and all shared helpers/audits verified byte-identical to main (strip only new methods and compare entire files). Baseline /tmp/task-79-baseline.xcresult passed 2/2: appearance 183.893 s, top counts 41.418 s. At top: L-005-02 330 descendants / 285 static texts; L-007-01 285 / 235; longest UTF-8 lesson L-008-01 316 / 267. Twelve full-screen before-images exported to /tmp/task-79-baseline-attachments; after smoke and full figure plan queued. Load sampled each minute; one-minute average exceeded 600 during baseline; no other processes modified.

Coordinator approval 2026-10-27: Practice scrollUntilPartiallyVisible now checks element.exists before reading its frame, matching the existing figure-class helper. Existing-element behavior and every assertion/audit unchanged. This is required because lazy offscreen targets do not exist yet; smoke failure at the old unguarded .frame is preserved in /tmp/task-79-after.xcresult (3/4 passed; offscreen-heading test failed). Coordinator also approved scrolling to each figure before TASK-65 structural uniqueness assertions, which are unchanged, plus a new assertion that the distant Ohms wheel is absent at launch. No other pre-existing helper or audit changed. After top counts: 59/27, 56/26, 58/25 descendants/static texts for L-005-02/L-007-01/L-008-01; figure sheet-return test passed 33.458 s; appearance capture passed 141.269 s.

AC4 coordinator approval 2026-10-27: all six AXXXXL lesson-content samples pixel-identical; default top/middle text +/-1 native pixel, bottom summary exact; footer +1 px light / +3 px dark (1 pt), registered residuals <=3/255; system clock/glass-back chrome and subpixel figure/table rasterization differ. No growing text drift, text/wrapping/spacing tokens/colour/size/style change. Exact raw/registered deltas and hashes in docs/testing/task-79-evidence.json; four after-images total 1,112,236 bytes, originals local. Approved differences accurately include corrected 3-px dark footer case.

The single targeted rerun after the approved existence guard passed: testLessonReaderOffscreenHeadingsAndTryItStateSurviveScrolling 566.029 s, /tmp/task-79-navigation-fix.xcresult, exit 0. This verifies beyond-first-screen headings in authored order and Try-it expansion retained after scrolling down to Summary and back, then collapse. Full figure-plan driver is now waiting on the shared xbuild lock. No test/audit skipped or filtered beyond the explicitly selected targeted test invocation.
<!-- SECTION:NOTES:END -->
