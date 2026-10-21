---
id: TASK-50.14.2
title: Apple lesson-quiz hints on all platforms
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-20 13:03'
updated_date: '2026-10-21 14:47'
labels:
  - apple
dependencies:
  - TASK-50.14.1
parent_task_id: TASK-50.14
ordinal: 142000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apply the owner-approved 2026-10-20 rules in TASK-50.14 after the web/model contract lands. Cover iOS/iPadOS/macOS/tvOS/visionOS, reusing bundled hints and the answeredWithHelp attempt model from TASK-50.14.1; lesson quizzes are now approved, not mock exams.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Official bank quiz items on iOS/iPadOS/macOS/tvOS/visionOS reuse practice hint ladder, one-level handling, generic lesson link (including current lesson), reference-sheet availability gating and offline content; concept checks expose no Hint control; mock exams and timed modes stay unchanged.
- [ ] #2 At least 0.5 s hint visibility before scoring qualifies help; post-score hints never mutate records; quiz/hint/answer state survives lesson-link round trips and layout/navigation changes.
- [ ] #3 Hinted correct answers count as correct, results summary counts helped answers, each per-question result marks with help, and passing/completion are unchanged; UI strings are plain translated EN/FR with French English-only-lesson notice.
- [ ] #4 Existing question-progress paths apply TASK-50.15 scheduling/weak-area/recent-answer semantics; persist answeredWithHelp in quiz attempts using the shared model and preserve old attempts without flags, including import/export/sync round trips.
- [ ] #5 Targeted unit/UI tests cover timing, score, progress, persistence, EN/FR, current/other lesson links and hint exclusions; VoiceOver/focus/Dynamic Type and light/dark accessibility audits cover affected screens without weakening tests; Apple localization/text checks and relevant platform checks pass. Web axe evidence remains covered by dependency TASK-50.14.1.
- [ ] #6 Match the web attempt contract: optional answeredWithHelpIds array, sorted unique subset of officialQuestionIds, missing means none; reject unknown/concept IDs in import/sync, preserve the field through persistence/export/import/sync and lesson-ID migrations (filter to destination official membership if an attempt splits).
- [ ] #7 Lesson quizzes have a hint-only toolbar/panel: no calculator or reference sheet is added. Use referenceSheetAvailable=false and hide existing reference-sheet pointer labels, including when the hint metadata has a pointer.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Preserve the optional sorted unique official helped-ID payload through Apple codec, validation, export/import/sync and 46.10 destination filtering; verify the shared fixture and legacy blobs.
2. Reuse practice hint-only presentation around the complete iOS/iPadOS/macOS quiz ScrollView, freeze help at choice, cache state across lesson/layout navigation, and retain score/progress semantics with EN/FR markers. tvOS/visionOS quiz UI is N/A by coordinator decision.
3. Validate targeted macOS units and final build, iPhone/iPad quiz/audit tests and all existing users of the approved DEBUG one-shot layout control. Use the unchanged owner-approved occluded-contrast helper only for feedback; keep full default panel/result audits. Validate localization and generic tvOS/visionOS catalogue builds.
4. Record per-test evidence, preserve all original tests/helpers byte-identically, check verified criteria, commit/push, and return for independent review without opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Review note (TASK-50.14.1 review 2026-10-20): current Apple builds, including TestFlight, accept and then DROP answeredWithHelpIds on lesson-quiz attempts. LessonQuizAttempt (ProgressStore.swift ~206) and DeviceLessonQuizAttemptRecord (ProgressSyncMerge.swift 43-59) use default Decodable, which ignores unknown keys, and upsertLessonQuizAttempt (~2019) re-encodes without the field, so web → Apple import/sync → export loses the flag (scores unaffected). Storage: Apple keeps attempts as a JSON payload blob (payloadData), so adding the optional field needs no SwiftData model migration, but old blobs and archived JSON must decode as none. Validation must reject unknown, concept-check, unsorted and duplicate IDs, matching web.

Coordinator confirmed tvOS/visionOS have no lesson quizzes: no new quiz surface; iOS/iPadOS/macOS UI and shared attempt payload are in scope. tvOS/visionOS build-only validation required if their compiled shared files change. Implemented optional payload field, strict help-ID validation, migration filtering, root-owned quiz session cache, practice hint-only panel and markers. Added fixture/persistence/import/sync tests and focused UI/audit tests; validation starting.

Validation so far (all through nohup xbuild scripts, logs /tmp/task-50.14.2-runs): macOS targeted run PASS, 32/32 tests (HintSessionStateTests 26/26; ProgressStoreTests: help fixture/payload/import/export/sync parity, session cache, split migration, concept-inclusive migration fixture, atomic archived multi-device migration and save rollback all PASS). Separate real 0.5-second/freeze-at-choice test PASS, 1/1. pnpm check:schemas PASS (2,034 targets); node scripts/check-apple-text-sources.ts PASS; test-guard self-test PASS. Guard reports only the three added full-default audit calls, intentional under the owner 2026-10-20 lesson-quiz decision; current checker does not accept dotted task IDs in approval markers, so PR should use Test-guard-approved: owner decision 2026-10-20. iPhone/iPad focused UI tests and full localization/tvOS/visionOS builds pending shared lock. No full test suites run.

Initial iPhone UI run: concept exclusions, French/current-lesson round trip, one-level-help persistence and post-choice immutability/persistence PASS. AX/layout was blocked by the existing debug overlay covering Hint; new-test positioning now scrolls Hint below that overlay and explicitly asserts it is not overlapped. Light/dark feedback audits exposed only opaque-navigation-bar occluded text false positives (xcresult screenshots in /tmp/task-50.14.2-runs/phone-failures). R2 confirmed moving one header merely exposed the next occluded element. Coordinator explicitly authorized calling existing auditIgnoringOccludedLessonTextContrast for quiz feedback in light/dark under owner decision 2026-10-12. The helper is byte-identical; fully visible contrast and all non-contrast issues still fail. Removed the attempt to position-shuffle the occluded header. Hint-panel and top-visible saved-results audits remain unfiltered defaults. PR marker now required: Test-guard-approved: owner decision 2026-10-12. All affected tests queued for targeted rerun; no full suite.

Localization validation completed PASS: pnpm check:apple-l10n (complete French XLIFF export, catalogue unchanged, generic CanadianHamTV and CanadianHamVision builds both BUILD SUCCEEDED). R2 iPhone: French/current-lesson round trip PASS (238.844s), one-level hinted-help persistence PASS (135.128s), post-choice immutability/persistence PASS (139.328s), light full-default panel/feedback/result audits PASS (182.198s); AX failed because the existing test-only layout overlay intercepted the tap, and dark failed on the next occluded header text. Those two causes are addressed in current source. R3 is queued for AX plus light/dark audit tests, followed by the 7-test iPad Pro 13-inch (M5) run. Programmatic suffix comparison against e04991d8 confirms every pre-existing ExamTools UI test and every audit/positioning helper remains byte-identical. No full suites.

R3 dark panel/approved-feedback/default-result audits PASS (201.045s). AX still failed before reopening because content would not scroll, revealing the actual integration error: examToolPresentation had been attached inside the outer quiz ScrollView, producing a fixed inspector container around tall card content at regular width. Moved the presenter outside the quiz ScrollView exactly as practice does; retained all load-error handling. Current source ce146da5 is pushed. R4 nohup script queued: targeted macOS cache+timing tests to compile the revised screen, then all 7 affected new quiz UI methods on iPhone 17 Pro and iPad Pro 13-inch (M5), stop on first failed command. Shared/approved helpers remain byte-identical; no suite or test/audit removal.

Resume 2026-10-21: overnight R4 completed. macOS cache/timing recheck PASS (2/2) and current/other lesson route test PASS (1/1). iPhone: concept exclusions PASS (23.782s), dark audits PASS (146.398s), French/current-lesson round trip PASS (168.292s), light audits PASS (139.836s), one-level help persistence PASS (108.015s), post-choice immutability PASS (116.571s). AX successfully preserved state/reopened Hint 2, but existing DEBUG layout overlay intercepted the inspector Close tool (full close frame is inside overlay). Coordinator explicitly approved a DEBUG-only one-shot allowsHitTesting(false) after transition, retaining visible label/value and no Release behavior; shared helpers must stay byte-identical. Rerun all six existing users of -CanadianHamShowSimulatedSizeClassChangeControl (two practice transitions and four deep Learn transitions) on iPhone and iPad, plus AX and new iPad quiz tests. No other code/audit scope changes.

R5 iPhone 17 Pro PASS (7/7) after the approved DEBUG-only one-shot control fix: AX-XXXL hint/layout round trip 189.978s; compact-to-split deep lesson 46.935s; compact-to-split deep quiz 81.995s; compact-to-regular practice selection/calculator 64.893s; regular-to-compact practice selection/calculator 64.359s; split-to-compact deep lesson 27.860s; split-to-compact deep quiz 87.757s. All six pre-existing launch-argument control tests and shared helpers are unmodified. Combined with R4, every new iPhone quiz test is now green. Nohup runner has started the iPad Pro 13-inch (M5) run with all seven new quiz methods plus the same six existing control users (13 methods); no finished checks repeated.

iPad first targeted run: 11/13 methods PASS, including all six existing DEBUG control users, AX/layout, concept exclusions, French/current-lesson link, one-level and post-choice persistence. Both light/dark hint-panel default audits correctly failed a non-contrast Dynamic Type issue on the disabled background Submit lesson quiz button. Attachment says the font cannot be changed; the new ViewThatFits navigation swaps between two distinct button trees as text grows. Replaced that navigation-only container with a single wrapping vertical control stack for stable identity and scalable text at every size; this is the real quiz layout in all builds, not an audit-only layout. Full audits and shared helpers unchanged. Rerun only affected iPad/iPhone audit methods and iPad AX case.

# Final targeted validation evidence

macOS: 34 distinct unit methods passed (the later focused cache/timing recheck repeats two).

- CanadianHamTests.HintSessionStateTests/testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekEndsWhenPhoneFullyOpensOrCloses: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekFastUnfoldThroughBandNeverPeeks: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekLeavingToleranceDoesNotResetDismissalSuppression: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekPresentationDismissalSuppressesReopenUntilReset: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekPresentationImmediateAnswerEndsEligibility: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekPresentationStartsOnlyOnceUntilPostureReset: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekRecheckPeeksWithoutNewSamples: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekRequiresStableDwellInSlightOpenBand: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekSlowCloseThroughBandNeverPeeks: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekToleratesSmallJitterOnlyAfterPeekStarts: PASS (0.000s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHingePeekUnavailableSampleDoesNotResetDismissalSuppression: PASS (0.000s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHintQualificationMarksUnansweredQuestionAsQualifiedOnly: PASS (0.003s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp: PASS (0.392s; mac.log)
- CanadianHamTests.HintSessionStateTests/testHintVisibilityTimerDoesNotQualifyShortPeekRoute: PASS (0.293s; mac.log)
- CanadianHamTests.HintSessionStateTests/testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp: PASS (0.002s; mac.log)
- CanadianHamTests.HintSessionStateTests/testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testReviewLaterHintAfterSelectionRecordsHelp: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission: PASS (0.001s; mac.log)
- CanadianHamTests.HintSessionStateTests/testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange: PASS (2.670s; mac.log)
- CanadianHamTests.ProgressStoreTests/testImportMigratesTask4610LessonSplitProgressAndQuizAttempts: PASS (0.053s; mac.log)
- CanadianHamTests.ProgressStoreTests/testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure: PASS (0.037s; mac.log)
- CanadianHamTests.ProgressStoreTests/testLessonQuizHelpFixtureValidationAndPayloadRoundTrips: PASS (0.142s; mac.log)
- CanadianHamTests.ProgressStoreTests/testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice: PASS (1.630s; mac-r4.log)
- CanadianHamTests.ProgressStoreTests/testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation: PASS (0.002s; mac-r4.log)
- CanadianHamTests.ProgressStoreTests/testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices: PASS (0.044s; mac.log)
- CanadianHamTests.ProgressStoreTests/testTask4610SharedConceptMappingAndConceptInclusiveScores: PASS (0.245s; mac.log)
- CanadianHamTests.RootNavigationMappingTests/testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts: PASS (0.001s; routes.log)

## iPhone 17 Pro: 13 distinct UI methods PASS

- testCompactToSplitKeepsDeepLearnLesson: PASS (46.935s; phone-r5.log)
- testCompactToSplitKeepsDeepLearnQuiz: PASS (81.995s; phone-r5.log)
- testLessonQuizConceptCheckHasNoHintOrOtherTools: PASS (23.782s; phone-r4.log)
- testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip: PASS (189.978s; phone-r5.log)
- testLessonQuizHintsDarkAndFullAccessibilityAudits: PASS (161.993s; phone-r6.log)
- testLessonQuizHintsFrenchAndCurrentLessonRoundTrip: PASS (168.292s; phone-r4.log)
- testLessonQuizHintsLightAndFullAccessibilityAudits: PASS (138.668s; phone-r6.log)
- testLessonQuizOneLevelHintAndHelpCountPersistsAfterRelaunch: PASS (108.015s; phone-r4.log)
- testLessonQuizPostChoiceHintsDoNotChangeSavedHelpAndRelaunchKeepsHelpCount: PASS (116.571s; phone-r4.log)
- testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue: PASS (64.893s; phone-r5.log)
- testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue: PASS (64.359s; phone-r5.log)
- testSplitToCompactKeepsDeepLearnLesson: PASS (27.860s; phone-r5.log)
- testSplitToCompactKeepsDeepLearnQuiz: PASS (87.757s; phone-r5.log)

## iPad Pro 13-inch (M5): 13 distinct UI methods PASS

- testCompactToSplitKeepsDeepLearnLesson: PASS (24.301s; pad.log)
- testCompactToSplitKeepsDeepLearnQuiz: PASS (38.731s; pad.log)
- testLessonQuizConceptCheckHasNoHintOrOtherTools: PASS (9.125s; pad.log)
- testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip: PASS (63.476s; pad-r6.log)
- testLessonQuizHintsDarkAndFullAccessibilityAudits: PASS (54.077s; pad-r6.log)
- testLessonQuizHintsFrenchAndCurrentLessonRoundTrip: PASS (61.182s; pad.log)
- testLessonQuizHintsLightAndFullAccessibilityAudits: PASS (51.161s; pad-r6.log)
- testLessonQuizOneLevelHintAndHelpCountPersistsAfterRelaunch: PASS (52.277s; pad.log)
- testLessonQuizPostChoiceHintsDoNotChangeSavedHelpAndRelaunchKeepsHelpCount: PASS (53.258s; pad.log)
- testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue: PASS (35.421s; pad.log)
- testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue: PASS (33.719s; pad.log)
- testSplitToCompactKeepsDeepLearnLesson: PASS (20.485s; pad.log)
- testSplitToCompactKeepsDeepLearnQuiz: PASS (41.611s; pad.log)

Other checks: pnpm check:schemas PASS (2,034 targets); pnpm check:apple-l10n PASS (complete French export; catalogue unchanged; generic tvOS/visionOS builds PASS); Apple text-source checker PASS; test-guard self-test PASS; guarded diff PASS with owner decision 2026-10-12 marker; all pre-existing UI test/helper suffix bytes match base e04991d8; git diff --check PASS.

Scope: no tvOS/visionOS quiz UI exists, so their quiz tests are N/A; shared catalogue build checks passed. No full suites run. Native macOS final-source build PASS (mac-final-build.log).
<!-- SECTION:NOTES:END -->
