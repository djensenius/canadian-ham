---
id: TASK-32
title: macOS Settings window follows the chosen appearance
status: Done
assignee:
  - '@worker'
created_date: '2026-10-03 23:33'
updated_date: '2026-10-05 00:03'
labels:
  - apple
  - macos
milestone: m-0
dependencies:
  - TASK-30
priority: low
ordinal: 60000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: Copilot's final PR #121 review noted the native macOS Settings window doesn't apply the app's selected appearance (light/dark/system) the way the main windows do, so it can look mismatched.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The Settings scene applies the stored appearance preference live, matching the main windows
- [x] #2 A macOS unit or UI check covers it; the macOS suite passes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the macOS Settings scene, appearance preference storage, and existing tests.\n2. Apply the stored appearance preference to NativeSettingsView/Settings scene using the same mapping as main windows without changing shared platform behavior.\n3. Add a focused macOS unit check for live appearance preference propagation.\n4. Run targeted macOS testing while iterating, then one full macOS suite per apps/apple/project.yml; record per-test names/results in notes before finalizing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented NativeSettingsView preferredColorScheme binding from the stored ApplePreferences.Theme and covered live updates through NativeSettingsPreferenceBindings.
Targeted macOS check passed: ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference (DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild ... -only-testing:CanadianHamTests/ProgressStoreTests/testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference ...).
Final macOS suite passed with 46/46 tests and 0 failures. Per-test results:
- LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations: passed
- LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries: passed
- LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish: passed
- LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale: passed
- MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer: passed
- MorseTrainerTests.testFixedTimingProfilesUseEngineValues: passed
- MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp: passed
- MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters: passed
- MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone: passed
- MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse: passed
- MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition: passed
- MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints: passed
- MorseTrainerTests.testMorseSettingsClampAndPreset: passed
- MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled: passed
- MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults: passed
- MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine: passed
- ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync: passed
- ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields: passed
- ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme: passed
- ProgressStoreTests.testImportOfOlderExportRollsBackWhenMorseProgressRemovalFails: passed
- ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails: passed
- ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure: passed
- ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressAsNoMorseProgress: passed
- ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt: passed
- ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues: passed
- ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates: passed
- ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress: passed
- ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId: passed
- ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt: passed
- ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure: passed
- ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder: passed
- ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference: passed
- ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences: passed
- ProgressStoreTests.testProgressStoreRoundTripExportImportReset: passed
- ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails: passed
- ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates: passed
- QuestionBankTests.testBundledJSONDecodesExpectedCounts: passed
- QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary: passed
- QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory: passed
- QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion: passed
- QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes: passed
- QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons: passed
- ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours: passed
- ReadinessAndScoringTests.testExamScoringBoundaries: passed
- ReadinessAndScoringTests.testReadinessStates: passed
- ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate: passed
Skipped iOS/tvOS/visionOS because the only app change is inside #if os(macOS) NativeSettingsView code and the added test is #if os(macOS); apps/apple/project.yml shows this settings/test path affects the CanadianHam macOS test run only for this task.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
NativeSettingsView now applies the stored light/dark/system appearance preference via preferredColorScheme, and the macOS unit test plus full macOS suite verify live preference propagation. iOS/tvOS/visionOS were skipped because changes are macOS-gated.
<!-- SECTION:FINAL_SUMMARY:END -->
