---
id: TASK-41
title: Morse polish follow-ups from review r2
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-11 01:16'
updated_date: '2026-10-20 13:02'
labels:
  - apple
  - web
dependencies: []
priority: low
ordinal: 91000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Low items from the task-12.18/12.19/12.20 review r2 (~/.cache/canadian-ham-reviews/t12-polish-r2.md) that weren't in scope for that PR.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Hardware-keyboard keying works on the pushed exam-style sending screen on macOS and iPad keyboards (focus isn't shared with the screen underneath), with a test where feasible
- [ ] #2 A UI test shows a running beacon stops (or switches to tape) when Reduce Motion or Dim Flashing Lights turns on, in at least one playback screen, beyond the decision-function unit test
- [ ] #3 An Apple test asserts the safety-note wording (square points, grouped digits); the web axe test derives its expected string rather than hard-coding it
- [ ] #4 Apple settings import from the Settings and Study views is covered by a test; behaviour for an unknown timingProfile/outputMode is documented (default vs reject) and matches web or the difference is recorded
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect current Morse focus, playback safety, import, and web test seams; preserve all audit helpers.
2. Give the pushed sending exam independent keyboard focus and add targeted regression coverage.
3. Cover live reduced-flashing playback changes and grouped square-point safety wording; derive the web assertion.
4. Cover the actual Settings/Study import paths and document enum fallback parity.
5. Run targeted iPhone/iPad Morse UI, macOS units, web Morse and localization checks; commit/push each coherent step, record evidence and finalize.
<!-- SECTION:PLAN:END -->
