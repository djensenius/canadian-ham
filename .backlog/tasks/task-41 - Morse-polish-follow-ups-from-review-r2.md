---
id: TASK-41
title: Morse polish follow-ups from review r2
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-11 01:16'
updated_date: '2026-10-21 14:50'
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
- [x] #2 A UI test shows a running beacon stops (or switches to tape) when Reduce Motion or Dim Flashing Lights turns on, in at least one playback screen, beyond the decision-function unit test
- [x] #3 An Apple test asserts the safety-note wording (square points, grouped digits); the web axe test derives its expected string rather than hard-coding it
- [x] #4 Apple settings import from the Settings and Study views is covered by a test; behaviour for an unknown timingProfile/outputMode is documented (default vs reject) and matches web or the difference is recorded
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect current Morse focus, playback safety, import, and web test seams; preserve every existing audit/test/helper.
2. Give practice and pushed exam distinct keyboard focus targets outside native scroll paging, restore focus after layout/Start, and verify actual key events through navigation (AC #1 still under targeted validation).
3. Verify running Quick listen beacon stops when its Reduce Motion input changes, and next playback uses tape; cover grouped square-point safety wording and derive the web axe string.
4. Test the actual Native Settings and Study Settings import methods for normalized live/persisted settings, notifications, and rejection without mutation. Preserve and document current unknown-enum rejection, matching web validation (the old review is stale).
5. Run only targeted iPhone/iPad Morse UI, relevant macOS Morse units, web Morse, localization/text-source and test-guard checks. Use detached xbuild scripts and grep-only polling; respect the shared lock. Commit/push coherent steps, record evidence, and finalize only after remaining keyboard/iPad/localization checks pass.

6. Resume AC1: diagnose nil focus from the completed keyboard run; give each visible keying surface reliable post-navigation focus with explicit edit interactions/default focus, preserving underlying-screen isolation and all strict hardware-key assertions. Commit before detached targeted iPhone/iPad, sending-regression/macOS-unit and localization checks; finalize only with passing evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented distinct practice/exam keyboard focus targets and a regression covering keying in a running pushed exam, Back, and re-entry. Added live Reduce Motion UI coverage using a DEBUG-only environment control that exercises the real onChange path, grouped square-point safety wording assertions, and web axe strings derived from engine constants and translations. Audit and exception helpers are unchanged.

Both Settings confirmation actions now call testable view import methods. Tests cover normalized live/persisted settings, replacement notifications, and rejection without mutation. Decision correction after validating current source: the old r2 review is stale. ProgressStore.validate and an existing test already reject unknown timingProfile/outputMode strings on Apple, matching web. Preserve that rejection rather than weaken existing tests. The initializer fallback is defensive only. Source comments and proposal documentation record this policy.

Validation so far: pnpm typecheck passed after pnpm install --frozen-lockfile restored missing workspace bin links. Relevant web tests: 63 Morse/settings/progress-store tests plus 21 selected App Morse tests passed. Test guard passed with no guarded changes. First two macOS build attempts exposed test-only Unicode syntax and duplicate model namespace issues, both fixed. Third targeted Morse unit run: 28 passed, 2 new import tests exposed the stale fallback assumption; corrected those tests to assert current rejection and rerunning only those 2. No production validation rules or existing tests were changed. Apple tests use detached xbuild scripts and grep-only polling; shared lock waits respected. Initial foreground localization check timed out; final localization validation remains queued.

macOS import fix round passed both new view-path tests: testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess (0.049s), testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess (0.038s); combined with 28 passing Morse tests from the previous targeted class run, all 30 relevant Morse unit tests are verified. Host app startup logged a stale local CoreData model-version warning; tests use isolated in-memory stores and passed.

iPhone first integration round passed all four existing sending regressions: testMorseSendingPracticeBackFromRunningExamStopsDeadlineGrading (78.322s), testMorseSendingPracticeClearsPendingCharacterWhenLeaving (76.163s), testMorseSendingPracticeGradesHeldStraightKeyBeforeScoring (99.181s), testMorseSendingPracticeUsesDebugHookAndPushesResultsScreen (105.285s). Both new integration tests failed and are under targeted retest, not checked off. Failure artifacts showed focus lost after Start and a LabeledContent AX prefix; fixed post-layout focus restoration (same pattern as calculator) and exact AX string variants. Moved the DEBUG reduced-motion input into Quick listen itself after the root-level injection did not propagate reliably through navigation. Read-only native accessibility environment is not mutated. Beacon/Stop assertions remain, with combined live-state polling and diagnostic output.

Detached runner: /tmp/task-41-validate-r6.sh; evidence/logs/results: /tmp/task-41-validation-20261020. Only 2 failing iPhone methods rerun, then 1 iPad keyboard method, then localization gate. Shared xbuild lock waits have been lengthy and respected; no other builds interrupted.

AC #2 verified: testMorseRunningBeaconStopsWhenReduceMotionTurnsOn passed on iPhone 17 Pro (57.198s) after local DEBUG flag injection; it asserts a real beacon is running before the flag change, Stop disables and beacon disappears after it, then the next Play renders tape. AC #3 verified by passed testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas plus the passed derived-string web axe test. AC #4 verified by both passed app view-path import tests and web unknown-enum rejection regression; both platforms reject unknown enum strings. AC #1 remains unchecked while actual hardware-event regression is debugged. Final iPad and localization validation remain pending; task stays In Progress.

Coordinator-approved partial handoff (2026-10-20): the shared lock is now held by the coordinator TASK-46.6 full CanadianHamLessonFigures plan (~3 hours). The keyboard-only retry waited from 15:16 UTC without starting. Per coordinator direction, cancelled ONLY this worktree's queued /tmp/task-41-validate-r7.sh runner and its waiting xbuild/lockf descendants; no active build or other lane was signalled.

ACs #2, #3, #4 remain verified/checked. AC #1 remains unverified/unchecked: previous keyboard tests decoded no character; the latest non-scrolling focus-container fix and focus/key-phase diagnostics have NOT yet run. Current source has zero-spacing outer focus containers to keep Space away from native scroll paging, distinct practice/exam targets, post-layout/Start restoration, and strict E/EE assertions with diagnostic output. No existing tests or audit/shared/exception helper bytes were changed.

Remaining coordinator work after the figure plan: run the single keyboard method on iPhone 17 Pro, fix only with targeted reruns if necessary, run it on iPad Pro 13-inch (M5), then pnpm check:apple-l10n (must not rewrite the catalog) and text-source/test-guard gates. Exact commands, passing criteria, current SHA, and all per-test results are in /tmp/task-41-handoff.md. This task intentionally stays In Progress, not Done; no PR opened.
<!-- SECTION:NOTES:END -->
