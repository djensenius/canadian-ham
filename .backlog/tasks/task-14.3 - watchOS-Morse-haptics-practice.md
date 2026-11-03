---
id: TASK-14.3
title: watchOS Morse haptics practice
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T17:01:00Z'
updated_date: '2026-10-25T20:02:00Z'
labels:
  - apple
  - watchos
milestone: m-1
dependencies:
  - TASK-14.2
documentation:
  - docs/proposals/watchos-companion.md
parent_task_id: TASK-14
type: feature
ordinal: 157000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
One-character listening/feeling drills make Morse useful on the wrist without bringing over the full Koch course or exam. Reuse morse-swift timing, not the existing iOS-only Core Haptics driver. WatchKit WKHapticType plays fixed presets, so pulse duration/cadence and dot/dash recognisability must be demonstrated on physical hardware; simulator success alone is not evidence of tactile fidelity. Escalate if that gate fails instead of silently changing the approved use case.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A Morse drill plays one A-Z character through a WatchKit WKHapticType adapter driven by morse-swift TimedMorseSequence, then offers four distinct pick-the-letter answers with immediate textual feedback, Replay and Next; no course/progress or exam claims are added.
- [ ] #2 The fixed-preset dot/dash mapping, supported cadence/speed and actual hardware observations are documented; a physical watch distinguishes representative short, long and mixed characters without overlapping/collapsed patterns. Unreliable output blocks completion and is escalated.
- [x] #3 Optional locally generated tones can be enabled independently of haptics; audio-off/haptics-off states have a non-flashing dot/dash text alternative and an accessible unavailable-output message where appropriate, without recording audio or accessing a network.
- [x] #4 Replay does not overlap output or reveal/speak the answer prematurely; leaving the screen, inactivity, interruption and advancing cancel pending playback. No workout/location/extended background session is used.
- [x] #5 Unit tests verify sequence-to-output mapping, correct/wrong pick grading, replay and cancellation using existing timing fixtures; targeted watch UI tests verify play/replay/answer/Next and output settings via xbuild, with per-test results recorded.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the watch practice patterns, Morse timing and local tone drivers. 2. Implement session-only Morse settings, deterministic drill and cancellable WatchKit/tone playback with injectable scheduling. 3. Add focused unit/UI tests, localized strings and hardware-check documentation. 4. Run watch tests, localization/text/guard checks and iOS build-for-testing; record evidence, leave AC2 blocked for owner hardware check, commit and push.

5. Apply approved internal-review follow-up: add three session-only localized haptic presets in one mapping table with tests, prove off-main tone rendering/failure handling, restrict interruptions to began, and title the settings sheet. 6. Extend owner hardware-check steps for all presets, sound/Silent Mode and direct Debug install; record deferred audit/VoiceOver findings on TASK-14.5. 7. Run requested watch scheme, localization/text/guards and iOS build-for-testing; update evidence and task notes while AC2 stays blocked, commit and push without a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation milestone: A–Z drill, session-only output settings, fixed click/directionUp mapping, clamped 1–2 WPM cadence and cancellable WatchKit/local synthesized tones implemented. Eight WatchMorseTests passed on Series 12 (42mm), watchOS 27.0; fixture-to-event/tone mapping, grading, replay, stale callback cancellation and spacing covered. Blocked: owner hardware check; AC2 remains unchecked. See docs/testing/task-14.3-watch-morse.md. Targeted watch UI tests and broader requested checks next.

Watch scheme run: 24/26 tests initially passed. Corrected practice-bundle validation to exclude the injected unit-test fixture bundle, native watch switch/picker/lazy Form automation, and a real Swift 6 audio-render callback isolation crash. Added a real tone-render/restart regression test. Targeted reruns now pass the failed practice-content test, all 9 Morse unit tests and the complete output-settings/text/tone UI test. Other five watch UI tests passed in the scheme run. Apple tool diagnostics report simctl collection noise after runs, but targeted final run is TEST SUCCEEDED. No hardware fidelity claim.

Acceptance evidence: AC1 seeded watch play/replay/answer/Next UI and 100 seeded grading/choice unit cases passed. AC3 independent haptic/tone matrix, real AVAudioSourceNode render/restart regression, tone-only UI and static requested text/no-output message UI passed. AC4 overlap guard, stale callback invalidation, cancellation before/mid-sequence, Next cooldown, delayed-scheduler safety and pre-answer UI non-reveal assertions passed; exit/scene/interruption/media-reset hooks all call the same tested cancel path. AC5 21 watch unit + 6 UI tests have passing evidence across the scheme run and targeted fix reruns; per-test rows are in docs/testing/task-14.3-watch-morse.md. pnpm check:apple-l10n (final export unchanged), text-source gate/self-test, network/iCloud guards/self-tests, test guard/self-test, deterministic XcodeGen, iOS build-for-testing and macOS 223/223 unit tests passed. macOS per-test rows: docs/testing/task-14.3-macos-unit-results.md. No shared Swift/package changes, so morse-swift swift test was not required. No full iOS/tvOS/visionOS suites: only additive watch strings outside watch targets; localization builds cover them, merge-batch suites remain coordinator-owned. Blocked: owner hardware check. AC2 stays unchecked and TASK-14.3 stays In Progress. No physical haptic fidelity, VoiceOver listening, TestFlight upload or PR claimed.

Approved internal-review follow-up implemented in 00aaae43: session-only Haptic style picker with three EN/FR candidates in one mapping table (Style 1 click/directionUp unchanged default; Style 2 click/start; Style 3 retry/start); unit coverage for every pair and selected-style forwarding. Settings now has a visible NavigationStack title; UI test switches both alternatives, preserves the style across navigation and resets to Style 1 on relaunch. Real-tone test now proves actual off-main rendering with a relaxed atomic render counter on two fresh starts; if category/session activation is unavailable it asserts the controller failure state and full resource cleanup, logs the error and does not skip. Both starts actually rendered off-main on this host. Only interruption .began cancels; a new test covers .ended, invalid/missing values and pending-output cancellation.

Owner hardware doc now compares all three styles in one session, requests tone-off preset-sound observations with Silent Mode off/on, explains candidate rationale without claiming single taps, and permits a direct Debug install from Xcode onto the owner's paired watch (not distribution) with the DEBUG -watchMorseSeed workflow. TASK-14.5 notes now explicitly cover full Practice/Morse audits, Letter A labels, choices-available announcement and VoiceOver/tone overlap.

Requested validation PASS: complete CanadianHamWatch scheme on Apple Watch Series 12 (42mm), watchOS 27.0: 23 unit + 6 UI tests = 29/29, no failures/skips. pnpm check:apple-l10n (French export plus tvOS/visionOS/watchOS builds, no catalogue mutation); text-source gate/self-test; network and iCloud guards/self-tests; test guard/self-test (origin/main...HEAD, no guarded changes); iOS CanadianHam build-for-testing on iPhone 17 Pro; git diff --check. Catalogue verification confirms exactly seven new fr/fr-CA keys with prior order/values preserved. Logs and 29 per-test rows in docs/testing/task-14.3-watch-morse.md. No shared Swift/package or target membership changes; no Swift-package tests, full iOS/tvOS/visionOS suites, repeated macOS units or figure/title sweeps in this watch-only fix round. Earlier macOS 223/223 results remain linked from the evidence doc. Tool warnings: legacy interruption API and connect deprecations, synchronous audio-session activation, pre-existing plural formatting and post-test simctl diagnostics; TEST SUCCEEDED.

Blocked: owner hardware check. AC2 remains unchecked and TASK-14.3 remains In Progress. No haptic fidelity, physical-watch run, VoiceOver listening, distribution, upload or PR claimed. Only the coordinator may later change the default from Style 1 after owner observations.

Complete review-follow-up per-test results (all PASS):
- CanadianHamWatchTests.CanadianHamWatchTests.testIndependentOfflineBundle: PASS (0.004s)
- CanadianHamWatchTests.CanadianHamWatchTests.testPlannedSections: PASS (0.001s)
- CanadianHamWatchTests.CanadianHamWatchTests.testSharedPackagesOnWatch: PASS (0.002s)
- CanadianHamWatchTests.WatchMorseTests.testCancelBeforeStartAndMidSequenceInvalidatesEvenStaleCallbacks: PASS (0.005s)
- CanadianHamWatchTests.WatchMorseTests.testDelayedSchedulerDoesNotCollapsePresets: PASS (0.001s)
- CanadianHamWatchTests.WatchMorseTests.testFourDistinctSeededChoicesGradingAndNextReset: PASS (0.006s)
- CanadianHamWatchTests.WatchMorseTests.testHapticStylesMapEveryPairAndReachOutput: PASS (0.002s)
- CanadianHamWatchTests.WatchMorseTests.testLocalToneDriverRendersOffMainActorAndRestartsAfterStop: PASS (0.368s)
- CanadianHamWatchTests.WatchMorseTests.testNextCancelsAndPreservesPresetCooldown: PASS (0.001s)
- CanadianHamWatchTests.WatchMorseTests.testOnlyBeganAudioInterruptionCancelsPlayback: PASS (0.001s)
- CanadianHamWatchTests.WatchMorseTests.testOutputsAreIndependentOffDoesNotStartAndToneFailureStops: PASS (0.004s)
- CanadianHamWatchTests.WatchMorseTests.testReplayCannotOverlapAndCompletedReplayUsesSameSequence: PASS (0.001s)
- CanadianHamWatchTests.WatchMorseTests.testSpeedClampsAndAllLettersRespectCadenceFloor: PASS (0.002s)
- CanadianHamWatchTests.WatchMorseTests.testTimingFixturesMapToWatchPresetsAndToneSegments: PASS (0.005s)
- CanadianHamWatchTests.WatchPracticeTests.testAColdBundledPracticeLoadMeasurements: PASS (0.361s)
- CanadianHamWatchTests.WatchPracticeTests.testDistractorNotesFollowDisplayedOrderWithOfficialChoiceText: PASS (0.297s)
- CanadianHamWatchTests.WatchPracticeTests.testEmptyLoadErrorAndMissingResourcesFailSafely: PASS (0.002s)
- CanadianHamWatchTests.WatchPracticeTests.testFrenchExplanationFallbackHasEnglishAccessibilityLanguage: PASS (0.292s)
- CanadianHamWatchTests.WatchPracticeTests.testMeasureBundledPracticeLoad: PASS (0.008s)
- CanadianHamWatchTests.WatchPracticeTests.testNewSessionRestoresNeitherAnswerNorQuestionSequence: PASS (0.137s)
- CanadianHamWatchTests.WatchPracticeTests.testRenderedExplanationsNeverExposeAuthoringLabels: PASS (0.411s)
- CanadianHamWatchTests.WatchPracticeTests.testSeededShuffleGradesSourceIndexNotDisplayPositionAndLocksSubmission: PASS (0.157s)
- CanadianHamWatchTests.WatchPracticeTests.testWatchBundleContainsCompleteBasicBankAndOnlyPracticeContent: PASS (0.148s)
- CanadianHamWatchUITests.CanadianHamWatchUITests.testLaunchAndNavigateEnglish: PASS (18.108s)
- CanadianHamWatchUITests.CanadianHamWatchUITests.testLaunchAndNavigateFrench: PASS (14.750s)
- CanadianHamWatchUITests.WatchMorseUITests.testIndependentOutputsTextAlternativeAndSessionOnlySettings: PASS (136.414s)
- CanadianHamWatchUITests.WatchMorseUITests.testPlayReplayAnswerNextAndNoEarlyReveal: PASS (49.423s)
- CanadianHamWatchUITests.WatchPracticeUITests.testCrownSelectionRequiresConfirmAndFrenchFeedbackLabelsEnglishFallback: PASS (53.887s)
- CanadianHamWatchUITests.WatchPracticeUITests.testTapFeedbackNextAndRelaunchDoesNotRestoreAnswer: PASS (32.606s)

Copilot (PR #1033): the 1.2 s haptic spacing reset when the Morse screen was re-entered, because each visit builds a new playback controller. It now lives in a shared WatchMorseHapticCooldown (per process); tests inject their own. New test testHapticSpacingSurvivesLeavingAndReenteringMorse. Watch scheme 30/30.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented offline A–Z watch Morse practice with four choices, feedback, Replay/Next, cancellable WatchKit output and independent local tones, session-only settings and static text fallback. Approved-review follow-up adds three localized haptic styles (default click/directionUp unchanged, alternatives click/start and retry/start), one mapping table, a visible settings title, measured off-main render-callback assertions and began-only interruption handling. All 29 watch tests, iOS test build, localization/text/guards pass in the follow-up; earlier 223 macOS unit passes remain recorded. Owner hardware documentation covers same-session comparison of all styles, tone-off preset sounds/Silent Mode and direct paired-watch Debug installation/seeded rounds. TASK-14.5 holds audit/VoiceOver polish findings. AC1/3/4/5 remain checked; AC2 stays blocked for physical-watch observations, task intentionally In Progress. No default change, hardware fidelity, upload or PR claimed.
<!-- SECTION:FINAL_SUMMARY:END -->
