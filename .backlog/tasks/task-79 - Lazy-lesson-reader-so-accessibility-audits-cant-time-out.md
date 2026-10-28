---
id: TASK-79
title: Lazy lesson reader so accessibility audits can't time out
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-28T01:32:00Z'
updated_date: '2026-10-28T01:33:00Z'
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
