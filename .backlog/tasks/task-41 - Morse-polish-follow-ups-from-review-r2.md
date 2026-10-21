---
id: TASK-41
title: Morse polish follow-ups from review r2
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-11 01:16'
updated_date: '2026-10-21 16:45'
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

7. Coordinator-approved latency fix (2026-10-21): measured first Space hold 0.579024s, of which synchronous AVAudioEngine startup consumed 0.569211s, with a 0.2s dot limit. Keep E/EE/E unchanged. Move sending audio preparation/start off the main actor with serialized lifecycle and existing output/mute settings; record key event times before audio; add a unit regression with an injected slow audio starter; prepare on sending-screen appearance and clean up on disappearance. Rerun the unchanged two-device keyboard regression plus sending and macOS Morse tests, recording before/after timing.
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

2026-10-21 AC1 resume: reproduced nil focus with explicit edit interactions/defaultFocus (9e4e963a). Isolated FocusState into a key-capture modifier instantiated separately in each navigation host (8d719a99), keeping inactive-screen guards and held-key cleanup. The next unchanged iPhone regression received real Space down/up and decoded exactly T; diagnostic Focus was exam, held false. No assertions/timeouts have changed. Per coordinator direction, instrumented DEBUG hold duration/dot threshold and audio-startup timing (9e535cac), committed/pushed before detached unchanged-test rerun. Evidence under /tmp/task-41-resume-20261021T145036Z (nil), /tmp/task-41-resume-20261021T145508Z (focused/T); current numeric diagnostic run /tmp/task-41-resume-20261021T150022Z is waiting for the shared lock. Existing settings inspection: slowest character speed is 12 WPM; both fixed profiles use a 0.1s dot, so maximum existing dot/dash threshold is 0.2s. Exact E/EE/E expectations remain unchanged pending measured evidence and coordinator decision.

Coordinator-approved AC1 latency fix (2026-10-21): unchanged iPhone test measured hold=0.579024076s, synchronous audio startup=0.569211006s, dot limit=0.2s. No existing timing setting gives margin, so coordinator directed fixing the real app bug, not warming from the test or changing E/EE/E. Source 687e4f39 now gives each navigation host local FocusState, records monotonic key event times first, prepares/retains a silent engine on a sending audio actor, serializes async sound commands and discards stale starts, releases with the existing fade on inactivity/playback handoff/leaving, and retains only silence across practice/exam navigation. Shared audio-session changes are locked across actors; normalization/volume and finite-element schedules are preserved. Added deterministic injected-slow-starter classification and leave-during-preparation/no-late-tone units. Hardware test adds diagnostic logging only; exact E/EE/E assertions and timeouts remain unchanged. Stop-on-first-failure runner /tmp/task-41-audio-checks.sh is queued at its macOS Morse unit step behind another lane; no build interrupted. Text-source and test-guard checks against origin/main already pass; final gates repeat after Apple results. AudioDriver target membership affects all four platforms; targeted iOS/macOS tests plus the requested localization gate (including tvOS/visionOS builds) are this iteration, with full platform suites deferred to the coordinator merge batch per policy.

2026-10-21 macOS targeted MorseTrainerTests: 32/32 passed (0 failures, 0.135s test time), source 0613b992. Evidence: /tmp/task-41-audio-validation-20261021T151530Z/mac-morse.log and mac-morse.xcresult. No full suites run. Afterward, 42c86998 only makes the session-lock closure explicitly throwing to remove a macOS compile warning (no runtime behavior change); the pending localization gate will compile it on macOS and the other targets. Existing local CoreData model-version startup warning remains; no local store was reset. Per-test results:
- testCompletedMorseCourseSessionIgnoresResubmittedAnswer — PASS (0.001 seconds)
- testFixedTimingProfilesUseEngineValues — PASS (0.001 seconds)
- testLessonBodyAndBulletContrastTokensMeetMinimumRatio — PASS (0.001 seconds)
- testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp — PASS (0.001 seconds)
- testMorseAudioSessionStaysActiveUntilLastPlayerReleases — PASS (0.001 seconds)
- testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins — PASS (0.001 seconds)
- testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas — PASS (0.001 seconds)
- testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters — PASS (0.001 seconds)
- testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone — PASS (0.002 seconds)
- testMorseCourseProgressIgnoresStoredProgressForAnotherCourse — PASS (0.002 seconds)
- testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition — PASS (0.001 seconds)
- testMorseExamGeneratorMeetsReceivingExamConstraints — PASS (0.002 seconds)
- testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime — PASS (0.001 seconds)
- testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying — PASS (0.001 seconds)
- testMorseSendingClassifiesTimingAndErrorSignal — PASS (0.001 seconds)
- testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended — PASS (0.002 seconds)
- testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone — PASS (0.002 seconds)
- testMorseSendingPendingFinalizationHelperCancelsAndClears — PASS (0.001 seconds)
- testMorseSendingRemainingExamSecondsUsesFixedDeadline — PASS (0.001 seconds)
- testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters — PASS (0.001 seconds)
- testMorseSettingsClampAndPreset — PASS (0.001 seconds)
- testMorseSettingsCodableRoundTripPreservesOutputMode — PASS (0.001 seconds)
- testMorseSettingsDecodesLegacyPayloadWithIsEnabled — PASS (0.001 seconds)
- testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast — PASS (0.009 seconds)
- testMorseSettingsRoundTripThroughUserDefaults — PASS (0.004 seconds)
- testMorseStopDelayDrainsFadeBeforeStoppingEngine — PASS (0.001 seconds)
- testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced — PASS (0.001 seconds)
- testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess — PASS (0.049 seconds)
- testReduceFlashingDecisionUsesInjectedFlags — PASS (0.001 seconds)
- testReduceFlashingStopsOnlyRunningVisualBeacon — PASS (0.001 seconds)
- testScheduleMorseVisualPlaybackInitialStateAndFallback — PASS (0.001 seconds)
- testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess — PASS (0.043 seconds)
<!-- SECTION:NOTES:END -->
