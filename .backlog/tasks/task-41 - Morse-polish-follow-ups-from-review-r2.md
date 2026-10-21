---
id: TASK-41
title: Morse polish follow-ups from review r2
status: Done
assignee:
  - '@worker'
created_date: '2026-10-11 01:16'
updated_date: '2026-10-21 21:31'
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
- [x] #1 Hardware-keyboard keying works on the pushed exam-style sending screen on macOS and iPad keyboards (focus isn't shared with the screen underneath), with a test where feasible
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

8. Review follow-up (2026-10-21): make queued lifecycle commands non-droppable; regress release then silence while preparation is suspended and verify engine/session cleanup. Detach stopped-engine nodes before sending restart and cover repeated restarts. Assert exam/practice/exam DEBUG focus, gate timing diagnostics to DEBUG, and reuse the production web safety-note builder. Preserve key classification on audio failure with a unit test (note 6); leave the brief shared session lock contention unchanged (note 8). Commit before detached targeted checks: ordered six iPhone methods with one allowed Results Light heading-only retry, iPad keyboard, macOS Morse units, web Morse tests and test guard. Keep Done, append evidence, push; no PR.
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

Validation still blocked on the shared xbuild lock after mac32 passed: the unchanged iPhone hardware-keyboard method has not yet begun on the async-audio fix. Live runner /tmp/task-41-audio-checks.sh, output /tmp/task-41-audio-validation-20261021T151530Z, stops on first failure and then covers iPad keyboard, four sending regressions, localization and guards. Other lanes repeatedly acquired the lock ahead of this waiter; no other processes were touched. Defensive continuation artifact /tmp/task-41-handoff2.md records the full diagnosis, approved app fix, exact live state, and remaining criteria; AC1 remains unchecked and task In Progress. Fresh git fetch origin main, text-source, test-guard --base origin/main --head HEAD, diff/index/clean-tree checks all pass on the current source. Localization and hardware-after timings remain unverified.

AC1 hardware validation passed on the real, unchanged Space-key regression: iPhone 17 Pro testMorseSendingExamHardwareKeyboardFocusIsSeparateFromPractice PASS (86.027s); iPad Pro 13-inch (M5) same method PASS (41.222s). Both assert exact E -> EE -> E through running pushed exam, Back to practice, and re-entry; logged focus is exam -> practice -> exam, with key-up received and held=false at each stage. No expected character, assertion, timeout, or test warm-up was changed. iPhone measured holds 0.117308875/0.10954525/0.132496541s and async tone-start latencies 0.000985375/0.00026775/0.00153075s. iPad holds 0.114616416/0.1173235/0.102765375s and starts 0.000944459/0.0003395/0.000771083s. Dot threshold stays 0.2s; before fix hold was 0.579024076s with 0.569211006s synchronous startup. Shared macOS app code compiled and mac32 units passed (including the injected slow-starter test); no macOS UI-test target or physical-keyboard manual run was used. Evidence: /tmp/task-41-audio-validation-20261021T151530Z/{iphone,ipad}-keyboard.log and matching xcresults. Runner advanced to the four existing sending regressions, then localization and final guards; task remains In Progress until those gates complete.

2026-10-21 final sending-regression rerun passed all four requested existing iPhone methods on the async-audio/focus fix: testMorseSendingPracticeBackFromRunningExamStopsDeadlineGrading PASS (74.516s); testMorseSendingPracticeClearsPendingCharacterWhenLeaving PASS (57.251s); testMorseSendingPracticeGradesHeldStraightKeyBeforeScoring PASS (58.552s); testMorseSendingPracticeUsesDebugHookAndPushesResultsScreen PASS (71.353s). Evidence: /tmp/task-41-audio-validation-20261021T151530Z/iphone-sending.log and iphone-sending.xcresult. Combined current evidence: mac32 units + both hardware-device methods + four sending methods all passed. Runner advanced to pnpm check:apple-l10n and is queued on its xbuild localization-export step. All ACs verified/checked, but task intentionally stays In Progress until localization/final runner gates finish; no PR. No full Apple suites run.

Final validation COMPLETE at 2026-10-21T20:10:02Z. /tmp/task-41-audio-checks.sh finished every step with exit=0; evidence directory /tmp/task-41-audio-validation-20261021T151530Z contains exact commands, status, logs and xcresults. Current execution totals: 32/32 macOS Morse units, both iPhone/iPad hardware-keyboard executions, and all four existing iPhone sending regressions passed (38 Apple test executions). All per-test results and before/after hardware timings are recorded above. pnpm check:apple-l10n PASS: French export complete, tvOS and visionOS generic simulator builds SUCCEEDED, compiler/XLIFF/catalogue checks passed, no catalogue rewrite. node scripts/check-apple-text-sources.ts PASS; node scripts/check-test-guard.mjs --base origin/main --head HEAD PASS (no guarded changes); git diff --check origin/main...HEAD PASS; working tree/index clean before final Backlog-only commits. The final explicit throwing-closure annotation compiled through the localization gate. Earlier AC2 beacon UI pass and 84 relevant web passes remain valid; web code did not change during this resume. No full Apple suites were run: they belong to coordinator merge batch, and shared MorseAudioDriver membership means that batch must cover all four platforms. No physical macOS keyboard interaction was manually exercised; the shared macOS app compiled and all Morse units passed. Existing local host CoreData unknown-model-version startup warning was not reset or changed. No PR opened; ready for required independent branch review.

Review follow-up source 4add8428632715a79b0fbe12586abef57284db6b: lifecycle prepare/silence/release commands now always execute in queue order; only tone starts/elements are superseded. Added suspended-preparation release→silence regression asserting prepared engine false and modeled shared session users zero. Sending restart cleans up the stopped engine before attaching a new source; a real AVAudioEngine unit covers three external-stop/restart cycles, single source attachment and balanced shared session users. Hardware UI regression now asserts DEBUG exam→practice→exam focus as well as unchanged E/EE/E. Timing fields and measurements are DEBUG-only. Web axe now calls the production morseOutputSafetyNote builder (also used by playback) and asserts square-point/grouped-area text. Note 6 decision: preserve the recorded press when sidetone preparation fails, report the existing audio error, and classify on key-up; added failure-path unit. Note 8 deliberately unchanged per assignment: AVAudioSession category/activation remains under the shared lock, with rare brief possible main-thread contention. Note 3 remains explicit: no physical macOS keyboard manual run; macOS evidence is compilation plus Morse units. Targeted stop-on-first-failure runner /tmp/task-41-review-checks.sh queued behind the shared xbuild lock; evidence /tmp/task-41-review-validation-20261021T202728Z. Task remains Done per coordinator direction; no PR.

2026-10-21 review follow-up targeted validation COMPLETE (all requested checks exit 0). Source: Swift 45421f5b plus web assertion cleanup af9b0442. Stable DEBUG Focus: exam/practice/exam labels replace runtime-qualified private-enum descriptions; both device tests assert those labels and unchanged E/EE/E. Web wording remains its existing px²; only Apple wording is square points. The web axe test calls the same morseOutputSafetyNote builder as production playback and checks grouped area text. All six iPhone methods ran in the requested order and passed on their first attempt; Results Light did not need the TASK-65 retry. Both hardware-keyboard tests assert focus, not just log it. Apple per-test results:
- iphone-keyboard: testMorseSendingExamHardwareKeyboardFocusIsSeparateFromPractice — PASS (76.458 seconds)
- iphone-main-light: testAccessibilityAuditMorseSendingMainAndExamScreensLight — PASS (91.837 seconds)
- iphone-main-dark: testAccessibilityAuditMorseSendingMainAndExamScreensDark — PASS (86.496 seconds)
- iphone-results-light: testAccessibilityAuditMorseSendingResultsLight — PASS (89.753 seconds)
- iphone-results-dark: testAccessibilityAuditMorseSendingResultsDark — PASS (83.005 seconds)
- iphone-deadline: testMorseSendingPracticeGradesImmediatelyAtDeadline — PASS (52.757 seconds)
- ipad-keyboard: testMorseSendingExamHardwareKeyboardFocusIsSeparateFromPractice — PASS (40.504 seconds)
- mac-morse: testCompletedMorseCourseSessionIgnoresResubmittedAnswer — PASS (0.001 seconds)
- mac-morse: testFixedTimingProfilesUseEngineValues — PASS (0.001 seconds)
- mac-morse: testLessonBodyAndBulletContrastTokensMeetMinimumRatio — PASS (0.001 seconds)
- mac-morse: testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession — PASS (1.662 seconds)
- mac-morse: testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp — PASS (0.002 seconds)
- mac-morse: testMorseAudioSessionStaysActiveUntilLastPlayerReleases — PASS (0.002 seconds)
- mac-morse: testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins — PASS (0.002 seconds)
- mac-morse: testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas — PASS (0.003 seconds)
- mac-morse: testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters — PASS (0.001 seconds)
- mac-morse: testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone — PASS (0.002 seconds)
- mac-morse: testMorseCourseProgressIgnoresStoredProgressForAnotherCourse — PASS (0.001 seconds)
- mac-morse: testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition — PASS (0.001 seconds)
- mac-morse: testMorseExamGeneratorMeetsReceivingExamConstraints — PASS (0.003 seconds)
- mac-morse: testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime — PASS (0.001 seconds)
- mac-morse: testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying — PASS (0.004 seconds)
- mac-morse: testMorseSendingClassifiesTimingAndErrorSignal — PASS (0.001 seconds)
- mac-morse: testMorseSendingKeyerClassifiesPressWhenAudioFails — PASS (0.004 seconds)
- mac-morse: testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended — PASS (0.002 seconds)
- mac-morse: testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone — PASS (0.002 seconds)
- mac-morse: testMorseSendingKeyerReleaseCannotBeSupersededBySilence — PASS (0.002 seconds)
- mac-morse: testMorseSendingPendingFinalizationHelperCancelsAndClears — PASS (0.001 seconds)
- mac-morse: testMorseSendingRemainingExamSecondsUsesFixedDeadline — PASS (0.001 seconds)
- mac-morse: testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters — PASS (0.001 seconds)
- mac-morse: testMorseSettingsClampAndPreset — PASS (0.001 seconds)
- mac-morse: testMorseSettingsCodableRoundTripPreservesOutputMode — PASS (0.001 seconds)
- mac-morse: testMorseSettingsDecodesLegacyPayloadWithIsEnabled — PASS (0.001 seconds)
- mac-morse: testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast — PASS (0.008 seconds)
- mac-morse: testMorseSettingsRoundTripThroughUserDefaults — PASS (0.004 seconds)
- mac-morse: testMorseStopDelayDrainsFadeBeforeStoppingEngine — PASS (0.001 seconds)
- mac-morse: testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced — PASS (0.001 seconds)
- mac-morse: testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess — PASS (0.047 seconds)
- mac-morse: testReduceFlashingDecisionUsesInjectedFlags — PASS (0.001 seconds)
- mac-morse: testReduceFlashingStopsOnlyRunningVisualBeacon — PASS (0.001 seconds)
- mac-morse: testScheduleMorseVisualPlaybackInitialStateAndFallback — PASS (0.001 seconds)
- mac-morse: testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess — PASS (0.036 seconds)
42 Apple test executions total: 35/35 macOS Morse units, 6/6 iPhone UI methods, 1/1 iPad keyboard method. macOS new regressions: stopped-engine/source/session restart 1.662s; audio-failure classification 0.004s; non-droppable release→silence 0.002s. Web: 25/25 Morse library/settings/sending tests and 21/21 selected App Morse tests passed (73 non-Morse App tests excluded by name filter, no source skips added). pnpm typecheck, Apple text-source checker, test-guard self-test, branch guard against origin/main and diff-check all passed. No guarded changes found. Exact commands, complete logs and 8 xcresults: /tmp/task-41-review-validation-20261021T202728Z. Runner: /tmp/task-41-review-checks.sh. Shared lock waits respected; no other builds signalled. xbuild logged a non-fatal simctl lookup warning during keyboard-run cleanup; both test commands exited zero. No physical macOS keyboard manual run is claimed. No full Apple suites ran; the shared driver still requires all four platform suites in the coordinator merge batch. Per AGENTS SwiftUI-text policy, an additional detached pnpm check:apple-l10n is running (/tmp/task-41-review-l10n.sh), covering export and generic tvOS/visionOS builds without catalogue rewriting. Task remains Done by coordinator direction; final push follows that gate. Note 8 remains deliberately unchanged as recorded above.

Review follow-up final gate PASS at 2026-10-21T21:31:02Z: pnpm check:apple-l10n exited 0, French export/compiler/catalogue checks passed, and generic tvOS plus visionOS simulator builds both SUCCEEDED. Catalogue unchanged and working tree clean. All requested targeted tests/checks plus the SwiftUI-text localization gate are now complete with no failures/retries. Evidence and exact commands remain /tmp/task-41-review-validation-20261021T202728Z; full per-test results are in the preceding note. All Apple invocations used xbuild, all waits used detached nohup runners and grep polling, and no other build was killed. No full Apple suites or physical macOS keyboard manual run claimed. Note 8 shared-session lock contention is intentionally retained. Task kept Done, ready for reviewer verification and coordinator merge-batch policy; no PR opened.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Completed all four Morse-polish acceptance criteria. Practice and pushed exam own separate keyboard focus bindings; the real keyboard regression preserves exact E/EE/E through exam, Back and re-entry on iPhone and iPad. A measured first-key audio stall (0.569s startup stretching a 0.579s hold) is fixed with asynchronous silent preparation, ordered/cancelled tone requests and monotonic event-time classification; injected slow-start and no-late-tone units pass. Existing live-beacon safety, localized square-point wording/derived web axe expectations, and Settings/Study import rejection coverage are retained. Validation: 32 macOS units, 2 device keyboard executions, 4 sending regressions, localization export plus tvOS/visionOS builds, text-source and test-guard checks all pass; previous 84 relevant web tests and beacon UI pass are recorded. Full per-test/timing evidence is in task notes and /tmp/task-41-audio-validation-20261021T151530Z. No PR; internal review required. Full four-platform suites are deferred to the coordinator merge batch; no physical macOS keyboard manual run claimed.

Review notes addressed: queued release/lifecycle work cannot be superseded by silence; stopped-engine restart detaches old sources and balances session users; device keyboard tests assert exam/practice/exam focus; diagnostic timing is DEBUG-only; web axe uses the production safety-note builder. Audio failure now preserves recorded press classification. Fresh validation passed 35 macOS Morse units (including 3 new regressions), all 6 ordered iPhone methods and iPad keyboard, 46 web Morse tests, typecheck, localization with tvOS/visionOS builds, text-source and test guard. Results Light passed first try. Full per-test evidence: /tmp/task-41-review-validation-20261021T202728Z. Note 8 remains unchanged; physical macOS keyboard behavior is not manually verified. No PR.
<!-- SECTION:FINAL_SUMMARY:END -->
