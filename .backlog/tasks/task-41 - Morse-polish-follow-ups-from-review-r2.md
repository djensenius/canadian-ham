---
id: TASK-41
title: Morse polish follow-ups from review r2
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-11 01:16'
updated_date: '2026-10-20 13:25'
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented distinct practice/exam keyboard focus targets and a regression covering keying in a running pushed exam, Back, and re-entry. Added live Reduce Motion UI coverage using a DEBUG-only environment control that exercises the real onChange path, grouped square-point safety wording assertions, and web axe strings derived from engine constants and translations. Audit and exception helpers are unchanged.

Both Settings confirmation actions now call testable view import methods. Tests cover normalized live/persisted settings, replacement notifications, and rejection without mutation. Decision correction after validating current source: the old r2 review is stale. ProgressStore.validate and an existing test already reject unknown timingProfile/outputMode strings on Apple, matching web. Preserve that rejection rather than weaken existing tests. The initializer fallback is defensive only. Source comments and proposal documentation record this policy.

Validation so far: pnpm typecheck passed after pnpm install --frozen-lockfile restored missing workspace bin links. Relevant web tests: 63 Morse/settings/progress-store tests plus 21 selected App Morse tests passed. Test guard passed with no guarded changes. First two macOS build attempts exposed test-only Unicode syntax and duplicate model namespace issues, both fixed. Third targeted Morse unit run: 28 passed, 2 new import tests exposed the stale fallback assumption; corrected those tests to assert current rejection and rerunning only those 2. No production validation rules or existing tests were changed. Apple tests use detached xbuild scripts and grep-only polling; shared lock waits respected. Initial foreground localization check timed out; final localization validation remains queued.
<!-- SECTION:NOTES:END -->
