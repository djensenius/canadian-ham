---
id: TASK-30
title: Native Settings window on macOS
status: Done
assignee:
  - '@worker'
created_date: '2026-10-03 12:03'
updated_date: '2026-10-03 23:28'
labels:
  - apple
  - macos
  - accessibility
milestone: m-0
dependencies:
  - TASK-12.3
priority: medium
ordinal: 59000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner wants the Mac app to feel native: app settings belong in the standard Settings window (app menu → Settings…, Command-comma), not an in-app page. iPhone and iPad keep their in-app Settings.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 macOS uses a SwiftUI Settings scene (Command-comma) with tabs for General (language, appearance), Data (export, import, reset) and Morse (all Morse settings); the in-app Settings page/sidebar entry is removed on macOS only
- [x] #2 All settings behave identically to iOS (same storage, live updates to open windows), with keyboard navigation and VoiceOver labels; Full Keyboard Access works
- [x] #3 macOS unit tests cover the shared settings model; iOS/iPadOS in-app Settings is unchanged and its UI tests pass; the macOS and iOS xbuild suites pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a macOS SwiftUI Settings scene wired to shared progress and Morse settings models.\n2. Move macOS settings out of the in-app sidebar while keeping iPhone/iPad in-app settings.\n3. Add model coverage and run macOS/iOS validation.

Fix review round: make macOS settings/main windows observe shared progress-store changes live through AppSettingsModel revisions, surface data-action errors, verify sandbox import/export entitlement, and add model/root synchronization tests.

Review round 3: keep macOS settings scope unchanged, restore shared legal wording, add sandbox export/import release-checklist coverage with owner manual verification note, and close only after required final validation passes.

Fix round 4: finalize alongside the compact iPhone navigation/accessibility fix; keep macOS Settings behavior unchanged and verify shared Apple suites.

Review fix round: add practice-mode and mock-exam timer controls to the macOS native Settings General tab with shared live preferences and macOS binding coverage; rerun targeted macOS validation plus final iOS/macOS suites and l10n/text checks.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented a native macOS Settings scene with General, Data, and Morse tabs backed by the shared ProgressStoreService and MorseTrainerSettings state; removed the macOS in-app Settings sidebar entry.

Validation gap: macOS xbuild suite passed and shared settings-model unit coverage was added. Full iOS suite timed out before completion, so AC3 remains unchecked pending a completed iOS run.

Final validation (2026-10-03): iOS `CanadianHam` full suite passed after confirming the compact iPhone Morse top-level navigation (`CanadianHamTests`: 30 tests, 0 failures; `CanadianHamUITests`: 30 tests, 0 failures; log `/tmp/task-12.12-ios-final.log`). Prior branch validation already recorded the macOS xbuild suite passing and shared settings-model unit coverage. iOS in-app Settings remained covered by the full iOS UI suite.

Fix round implementation committed through 6d929a0. macOS settings model/live-update changes and targeted tests are in place; final task closure is blocked by the task-12.12 iOS full-suite accessibility failure, so task remains In Progress.

Fix round 3 progress: added the release-checklist item for manual macOS sandbox Data-tab export/import verification; owner verification on their Mac is still required for task-30 AC2 sandbox evidence. Task remains In Progress pending the shared final validation.

Fix round 4 final: macOS Settings code unchanged in this round, but shared final validation passed on commit f7bcbaaf7ee19004aced3bcfcd703efa87377243. Evidence: pnpm check:apple-l10n; node scripts/check-apple-text-sources.ts; pnpm check:apple-network; full iOS xbuild passed (/tmp/task-12.12-r4-ios-full-final2.log, 64 tests including iOS in-app Settings and compact navigation); full macOS xbuild passed (/tmp/task-12.12-r4-macos-full-final.log, 32 unit tests); full tvOS and visionOS xbuild passed. Task-30 AC2 sandbox import/export remains dependent on the owner manual check on their Mac as requested; this branch has the entitlement/checklist coverage and no-network validation, but no automated sandbox file-panel import/export can replace that owner check.

Fix round 7 final validation (implementation commit 9e74901210e6345a0d2d37fcde09924515da8157):
- PR #121 Copilot comments 4175230153 and 4175230175 addressed: macOS native Settings General tab now exposes Practice mode and optional mock-exam timer with shared EN/FR preferences; cached practice sessions track their creation practice mode and reload on mode changes without reloading per-answer saves.
- Targeted checks: macOS `testNativeSettingsGeneralBindingsUpdatePracticePreferences` passed (`/tmp/task-12.12-r7-macos-targeted.log`); initial iOS targeted run exposed a test visibility issue, then `testPracticeModeChangeReopensCachedSessionFresh` passed after narrowing the assertion (`/tmp/task-12.12-r7-ios-targeted2.log`).
- Localization/text checks passed: `pnpm check:apple-l10n`; `node scripts/check-apple-text-sources.ts`.
- Final iOS full xbuild passed on iPhone 17 Pro: 73 tests, 0 failures (`/tmp/task-12.12-r7-ios-full.log`). Per-test names:
  - CanadianHamTests.LocalizationCatalogTests/testEveryCatalogKeyHasFrenchTranslations: PASSED
  - CanadianHamTests.LocalizationCatalogTests/testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries: PASSED
  - CanadianHamTests.LocalizationCatalogTests/testLocalizedNullableTextAndLanguageFallsBackToEnglish: PASSED
  - CanadianHamTests.LocalizationCatalogTests/testQuestionBankLoadErrorDescriptionUsesFrenchLocale: PASSED
  - CanadianHamTests.MorseTrainerTests/testFixedTimingProfilesUseEngineValues: PASSED
  - CanadianHamTests.MorseTrainerTests/testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp: PASSED
  - CanadianHamTests.MorseTrainerTests/testMorseSettingsClampAndPreset: PASSED
  - CanadianHamTests.MorseTrainerTests/testMorseSettingsDecodesLegacyPayloadWithIsEnabled: PASSED
  - CanadianHamTests.MorseTrainerTests/testMorseSettingsRoundTripThroughUserDefaults: PASSED
  - CanadianHamTests.MorseTrainerTests/testMorseStopDelayDrainsFadeBeforeStoppingEngine: PASSED
  - CanadianHamTests.ProgressStoreTests/testAppSettingsModelPublishesMorseSettingsForRootViewSync: PASSED
  - CanadianHamTests.ProgressStoreTests/testDecodesLegacyBasicExportWithoutBankIdFields: PASSED
  - CanadianHamTests.ProgressStoreTests/testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme: PASSED
  - CanadianHamTests.ProgressStoreTests/testImportRollbackKeepsExistingDataWhenReplacementFails: PASSED
  - CanadianHamTests.ProgressStoreTests/testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt: PASSED
  - CanadianHamTests.ProgressStoreTests/testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues: PASSED
  - CanadianHamTests.ProgressStoreTests/testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates: PASSED
  - CanadianHamTests.ProgressStoreTests/testImportValidationRejectsMismatchedScoreBankId: PASSED
  - CanadianHamTests.ProgressStoreTests/testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt: PASSED
  - CanadianHamTests.ProgressStoreTests/testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure: PASSED
  - CanadianHamTests.ProgressStoreTests/testMockExamTimerRefreshPreservesFractionalRemainder: PASSED
  - CanadianHamTests.ProgressStoreTests/testProgressStoreRoundTripExportImportReset: PASSED
  - CanadianHamTests.ProgressStoreTests/testSharedAppleSettingsModelAppliesLivePreferenceUpdates: PASSED
  - CanadianHamTests.QuestionBankTests/testBundledJSONDecodesExpectedCounts: PASSED
  - CanadianHamTests.QuestionBankTests/testBundledLessonsAndExplanationsLoadThroughContentLibrary: PASSED
  - CanadianHamTests.QuestionBankTests/testEngineQuestionDrawKeepsQuestionInsideRequestedCategory: PASSED
  - CanadianHamTests.QuestionBankTests/testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion: PASSED
  - CanadianHamTests.QuestionBankTests/testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes: PASSED
  - CanadianHamTests.QuestionBankTests/testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons: PASSED
  - CanadianHamTests.ReadinessAndScoringTests/testAdvancedScoringAndReadinessSuppressHonours: PASSED
  - CanadianHamTests.ReadinessAndScoringTests/testExamScoringBoundaries: PASSED
  - CanadianHamTests.ReadinessAndScoringTests/testReadinessStates: PASSED
  - CanadianHamTests.ReadinessAndScoringTests/testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testAboutShowsReleaseAttributionDisclaimerAndBankVersion: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditCoreScreensDark: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditCoreScreensLight: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditLearnFlowDark: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditLearnFlowLight: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowDark: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowLight: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionDark: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionLight: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testCanPracticeInFrenchAndSeeFeedback: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testCompactHomeStartPracticeAndMockExamBackReturnToHome: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testCompactMockExamEndExamDiscardsInProgressSession: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testCompactRootNavigationPreservesMockExamState: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testCompactRootNavigationPreservesPracticeSessionState: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testCompactTopLevelListPushesMorseThenLearn: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testDueReviewLaterSessionKeepsPositionTallyAndReviewAfterSubmit: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testExplanationAppearsAfterAnsweringInPractice: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testFrenchAboutKeepsLegalTextInEnglish: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testLanguagePickerExistsOnCategoryListAndPractice: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testLanguagePickerExistsOnCompactHomeLearnMorseAndMockExam: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testLearnOpensLessonAndShowsFirstHeading: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testLearnUserNavigationOpensLessonQuiz: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testLessonQuizResultPersistsAfterRelaunch: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testLongestAnswerWrapsAtLargestAccessibilityTextSize: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testMockExamDoesNotShowCorrectnessBeforeSubmit: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testMockExamHeaderControlsSupportLargestAccessibilityTextSize: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testMockExamNextUnansweredJumpsAfterAnsweringFirstQuestion: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testMockExamResultHeadingCarriesVoiceOverSubmissionSummary: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testMorseSectionIsTopLevelAndShowsSettings: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testPracticeFlowSupportsLargestAccessibilityTextSize: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testPracticeImmediateFeedbackKeepsStateAfterFirstAnswer: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testPracticeModeChangeReopensCachedSessionFresh: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testRegularWidthMockExamEndExamDiscardsInProgressSession: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testRegularWidthMockExamResultPersistsAfterSubmit: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testReviewLaterHidesCorrectnessUntilSubmitAndResultsSurviveSave: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testSettingsResetClearsCompactMockExamCacheWithoutRelaunch: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testSettingsResetClearsSavedMockExamProgress: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testSubsectionPracticeOpensFromHubAndShowsReviewScreen: PASSED
  - CanadianHamUITests.CanadianHamPracticeUITests/testWeakAreasImmediateSessionKeepsFeedbackPositionAndTallyAfterAnswers: PASSED
- Final macOS full xbuild passed on macOS arm64 with UI tests skipped per project policy: 34 tests, 0 failures (`/tmp/task-12.12-r7-macos-full.log`). Per-test names:
  - CanadianHamTests.LocalizationCatalogTests/testEveryCatalogKeyHasFrenchTranslations: PASSED
  - CanadianHamTests.LocalizationCatalogTests/testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries: PASSED
  - CanadianHamTests.LocalizationCatalogTests/testLocalizedNullableTextAndLanguageFallsBackToEnglish: PASSED
  - CanadianHamTests.LocalizationCatalogTests/testQuestionBankLoadErrorDescriptionUsesFrenchLocale: PASSED
  - CanadianHamTests.MorseTrainerTests/testFixedTimingProfilesUseEngineValues: PASSED
  - CanadianHamTests.MorseTrainerTests/testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp: PASSED
  - CanadianHamTests.MorseTrainerTests/testMorseSettingsClampAndPreset: PASSED
  - CanadianHamTests.MorseTrainerTests/testMorseSettingsDecodesLegacyPayloadWithIsEnabled: PASSED
  - CanadianHamTests.MorseTrainerTests/testMorseSettingsRoundTripThroughUserDefaults: PASSED
  - CanadianHamTests.MorseTrainerTests/testMorseStopDelayDrainsFadeBeforeStoppingEngine: PASSED
  - CanadianHamTests.ProgressStoreTests/testAppSettingsModelPublishesMorseSettingsForRootViewSync: PASSED
  - CanadianHamTests.ProgressStoreTests/testDecodesLegacyBasicExportWithoutBankIdFields: PASSED
  - CanadianHamTests.ProgressStoreTests/testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme: PASSED
  - CanadianHamTests.ProgressStoreTests/testImportRollbackKeepsExistingDataWhenReplacementFails: PASSED
  - CanadianHamTests.ProgressStoreTests/testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt: PASSED
  - CanadianHamTests.ProgressStoreTests/testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues: PASSED
  - CanadianHamTests.ProgressStoreTests/testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates: PASSED
  - CanadianHamTests.ProgressStoreTests/testImportValidationRejectsMismatchedScoreBankId: PASSED
  - CanadianHamTests.ProgressStoreTests/testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt: PASSED
  - CanadianHamTests.ProgressStoreTests/testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure: PASSED
  - CanadianHamTests.ProgressStoreTests/testMockExamTimerRefreshPreservesFractionalRemainder: PASSED
  - CanadianHamTests.ProgressStoreTests/testNativeSettingsGeneralBindingsUpdatePracticePreferences: PASSED
  - CanadianHamTests.ProgressStoreTests/testProgressStoreRoundTripExportImportReset: PASSED
  - CanadianHamTests.ProgressStoreTests/testSharedAppleSettingsModelAppliesLivePreferenceUpdates: PASSED
  - CanadianHamTests.QuestionBankTests/testBundledJSONDecodesExpectedCounts: PASSED
  - CanadianHamTests.QuestionBankTests/testBundledLessonsAndExplanationsLoadThroughContentLibrary: PASSED
  - CanadianHamTests.QuestionBankTests/testEngineQuestionDrawKeepsQuestionInsideRequestedCategory: PASSED
  - CanadianHamTests.QuestionBankTests/testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion: PASSED
  - CanadianHamTests.QuestionBankTests/testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes: PASSED
  - CanadianHamTests.QuestionBankTests/testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons: PASSED
  - CanadianHamTests.ReadinessAndScoringTests/testAdvancedScoringAndReadinessSuppressHonours: PASSED
  - CanadianHamTests.ReadinessAndScoringTests/testExamScoringBoundaries: PASSED
  - CanadianHamTests.ReadinessAndScoringTests/testReadinessStates: PASSED
  - CanadianHamTests.ReadinessAndScoringTests/testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate: PASSED
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
macOS keeps the native SwiftUI Settings scene and shared settings model from earlier rounds. Final validation on f7bcbaaf7ee19004aced3bcfcd703efa87377243 passed Apple localization/text/network checks plus full iOS and macOS xbuild suites; iOS in-app Settings stayed covered. Owner manual verification is still the evidence source for sandbox Data-tab import/export behavior.
<!-- SECTION:FINAL_SUMMARY:END -->
