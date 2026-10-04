---
id: TASK-12.16
title: 'Morse course correctness follow-ups from PR #127'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-04 09:12'
updated_date: '2026-10-04 11:06'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.5
parent_task_id: TASK-12
priority: high
ordinal: 63000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: Copilot's final review of PR #127 found six issues in the new course code: the summary claims the next lesson unlocked after review sessions and after lesson 40; the daily streak resets to 0 at midnight until today's first lesson (TS and Swift); Apple builds progress dates with Calendar.current, so non-Gregorian calendars produce dates that don't match web; and the TypeScript course parser doesn't validate unit IDs while Swift does.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Summary copy depends on session mode and lesson position: reviews and lesson 40 never claim an unlock (web and Apple), with tests
- [x] #2 The daily streak counts back from today if there's activity today, otherwise from yesterday, so it only breaks after a missed day; identical in TS and Swift with a shared fixture
- [x] #3 Apple progress dates use a Gregorian calendar in the current time zone; the TS parser validates unit IDs unit-01..unit-08 like Swift; tests cover both
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Fix the shared Morse course engine behavior: daily streak starts from today or yesterday and TypeScript validates unit IDs unit-01..unit-08, then cover both with package tests/shared fixture.
2. Update web and Apple lesson summary copy so review sessions and final lesson completions do not claim a next unlock, and add tests.
3. Use a Gregorian current-time-zone date formatter for Apple local progress dates and cover it in Swift tests.
4. Run targeted package/web/Swift checks for the changed code before moving to task-12.15.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented shared Morse course correctness fixes. Targeted validation:
- packages/morse-engine Vitest: packages/morse-engine/test/course.test.ts and fixtures.test.ts passed (17 tests), including rejects course fixtures with unexpected unit IDs and shared course-streak fixture cases.
- packages/morse-swift: initial swift test without DEVELOPER_DIR failed because CommandLineTools could not resolve XCTest; reran with DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer and MorseFixtureTests/testEveryMorseFixtureMatchesSwiftEngine passed.
- web: pnpm --filter @canadian-ham/web test -- App.test.tsx passed (Vitest reported 13 files, 122 tests), including uses Morse course summary copy for review sessions and the final lesson.
- Apple targeted macOS xbuild unit tests passed: MorseTrainerTests/testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition and MorseTrainerTests/testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone.

Final validation on branch task-12.16-course-fixes at pre-validation tip 70d4ea8064107880d00fe9e14e257b6c816fafbe: all required checks passed; no code changes were made.

Command results:
- PASS: `pnpm install --frozen-lockfile` — Lockfile was up to date; packages reused.
- PASS: `pnpm typecheck` — Workspace typecheck completed.
- PASS: `TZ=UTC pnpm test` — release-permission self-test passed; content-tools node:test 100 passed; @canadian-ham/morse-engine Vitest 15 passed; @canadian-ham/web Vitest 121 passed.
- PASS: `pnpm build:web` — Vite production build completed; existing chunk-size warning only.
- PASS: `pnpm check:apple-l10n` — Apple French localization export completed.
- PASS: `node scripts/check-apple-text-sources.ts` — Apple SwiftUI text sources are localized or explicitly marked; Node emitted MODULE_TYPELESS_PACKAGE_JSON warning only.
- PASS: `cd packages/morse-swift && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test` — MorseFixtureTests/testEveryMorseFixtureMatchesSwiftEngine passed; Swift Testing reported 0 additional tests.
- PASS: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test CODE_SIGNING_ALLOWED=NO` — Executed 50 tests, with 0 failures (0 unexpected) in 2827.555 (2827.607) seconds; Executed 50 tests, with 0 failures (0 unexpected) in 2827.555 (2827.608) seconds; xcresult /Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-bvwegohnpxzdjlchwymywgmwugno/Logs/Test/Test-CanadianHam-2026.10.04_06-04-05--0400.xcresult
- PASS: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES` — Executed 43 tests, with 0 failures (0 unexpected) in 1.314 (1.327) seconds; Executed 43 tests, with 0 failures (0 unexpected) in 1.314 (1.327) seconds; xcresult /Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-bvwegohnpxzdjlchwymywgmwugno/Logs/Test/Test-CanadianHam-2026.10.04_06-54-05--0400.xcresult
- PASS: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamTV -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' test CODE_SIGNING_ALLOWED=NO` — Executed 12 tests, with 0 failures (0 unexpected) in 284.151 (284.163) seconds; Executed 12 tests, with 0 failures (0 unexpected) in 284.151 (284.165) seconds; xcresult /Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-bvwegohnpxzdjlchwymywgmwugno/Logs/Test/Test-CanadianHamTV-2026.10.04_06-54-33--0400.xcresult
- PASS: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamVision -destination 'platform=visionOS Simulator,name=Apple Vision Pro' test CODE_SIGNING_ALLOWED=NO` — Executed 9 tests, with 0 failures (0 unexpected) in 197.990 (198.072) seconds; Executed 9 tests, with 0 failures (0 unexpected) in 197.990 (198.073) seconds; xcresult /Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-bvwegohnpxzdjlchwymywgmwugno/Logs/Test/Test-CanadianHamVision-2026.10.04_07-01-30--0400.xcresult

Per-test results:
- Swift package: PASS CanadianHamMorseEngineTests.MorseFixtureTests/testEveryMorseFixtureMatchesSwiftEngine
- iOS (92 named XCTest cases):
  - PASSED: CanadianHamTests.LocalizationCatalogTests/testEveryCatalogKeyHasFrenchTranslations (0.010 seconds)
  - PASSED: CanadianHamTests.LocalizationCatalogTests/testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries (0.011 seconds)
  - PASSED: CanadianHamTests.LocalizationCatalogTests/testLocalizedNullableTextAndLanguageFallsBackToEnglish (0.000 seconds)
  - PASSED: CanadianHamTests.LocalizationCatalogTests/testQuestionBankLoadErrorDescriptionUsesFrenchLocale (0.003 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testCompletedMorseCourseSessionIgnoresResubmittedAnswer (0.001 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testFixedTimingProfilesUseEngineValues (0.002 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp (0.002 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters (0.002 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseCourseProgressIgnoresStoredProgressForAnotherCourse (0.002 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseExamGeneratorMeetsReceivingExamConstraints (0.005 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseSettingsClampAndPreset (0.001 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseSettingsDecodesLegacyPayloadWithIsEnabled (0.002 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseSettingsRoundTripThroughUserDefaults (0.010 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseStopDelayDrainsFadeBeforeStoppingEngine (0.002 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testAppSettingsModelPublishesMorseSettingsForRootViewSync (0.002 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testDecodesLegacyBasicExportWithoutBankIdFields (0.098 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme (0.037 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportOfOlderExportRollsBackWhenMorseProgressRemovalFails (0.066 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportRollbackKeepsExistingDataWhenReplacementFails (0.098 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportRollbackPropagatesMorseProgressRemovalFailure (0.038 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportsOlderExportWithoutMorseCourseProgressAsNoMorseProgress (0.045 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt (0.043 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues (0.003 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates (0.041 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportValidationRejectsInvalidMorseCourseProgress (0.046 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportValidationRejectsMismatchedScoreBankId (0.052 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt (0.056 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure (0.051 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testMockExamTimerRefreshPreservesFractionalRemainder (0.003 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testProgressStoreRoundTripExportImportReset (0.113 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testResetRollsBackWhenMorseProgressRemovalFails (0.055 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testSharedAppleSettingsModelAppliesLivePreferenceUpdates (0.018 seconds)
  - PASSED: CanadianHamTests.QuestionBankTests/testBundledJSONDecodesExpectedCounts (0.082 seconds)
  - PASSED: CanadianHamTests.QuestionBankTests/testBundledLessonsAndExplanationsLoadThroughContentLibrary (0.737 seconds)
  - PASSED: CanadianHamTests.QuestionBankTests/testEngineQuestionDrawKeepsQuestionInsideRequestedCategory (0.019 seconds)
  - PASSED: CanadianHamTests.QuestionBankTests/testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion (0.074 seconds)
  - PASSED: CanadianHamTests.QuestionBankTests/testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes (0.001 seconds)
  - PASSED: CanadianHamTests.QuestionBankTests/testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons (0.322 seconds)
  - PASSED: CanadianHamTests.ReadinessAndScoringTests/testAdvancedScoringAndReadinessSuppressHonours (0.001 seconds)
  - PASSED: CanadianHamTests.ReadinessAndScoringTests/testExamScoringBoundaries (0.001 seconds)
  - PASSED: CanadianHamTests.ReadinessAndScoringTests/testReadinessStates (0.000 seconds)
  - PASSED: CanadianHamTests.ReadinessAndScoringTests/testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate (0.033 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testAboutShowsReleaseAttributionDisclaimerAndBankVersion (29.888 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditCoreScreensDark (103.532 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditCoreScreensLight (99.620 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditLearnFlowDark (42.907 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditLearnFlowLight (39.206 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowDark (106.303 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowLight (101.726 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditMorseCourseLessonAndSummaryDark (141.899 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditMorseCourseLessonAndSummaryLight (129.807 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditMorseExamGradedDiffDark (64.123 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditMorseExamGradedDiffLight (64.853 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionDark (96.667 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionLight (97.223 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testCanPracticeInFrenchAndSeeFeedback (25.566 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testCompactHomeStartPracticeAndMockExamBackReturnToHome (30.379 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testCompactMockExamEndExamDiscardsInProgressSession (26.760 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testCompactRootNavigationPreservesMockExamState (42.389 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testCompactRootNavigationPreservesPracticeSessionState (46.352 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testCompactTopLevelListPushesMorseThenLearn (18.865 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testCompletesFirstMorseLessonSessionOnIOS (176.074 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testDueReviewLaterSessionKeepsPositionTallyAndReviewAfterSubmit (53.957 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testExplanationAppearsAfterAnsweringInPractice (23.470 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testFrenchAboutKeepsLegalTextInEnglish (14.056 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice (75.660 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testLanguagePickerExistsOnCategoryListAndPractice (18.713 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testLanguagePickerExistsOnCompactHomeLearnMorseAndMockExam (40.495 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testLearnOpensLessonAndShowsFirstHeading (10.903 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testLearnUserNavigationOpensLessonQuiz (146.274 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testLessonQuizResultPersistsAfterRelaunch (28.853 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testLongestAnswerWrapsAtLargestAccessibilityTextSize (24.799 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testMockExamDoesNotShowCorrectnessBeforeSubmit (20.839 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testMockExamHeaderControlsSupportLargestAccessibilityTextSize (48.638 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testMockExamNextUnansweredJumpsAfterAnsweringFirstQuestion (36.350 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testMockExamResultHeadingCarriesVoiceOverSubmissionSummary (27.555 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testMorseCopyPracticeAndExamFlow (44.451 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testMorseCopyStartResetsAfterAudioStartupFailure (15.053 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testMorseExamStartResetsAfterAudioStartupFailure (51.932 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testMorseLessonSummaryShowsCorrectAnswerForWrongFinalAnswerOnIOS (166.311 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testMorseSectionIsTopLevelShowsCourseAndOpensFirstLesson (31.003 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testMorseStartingQuickListenStopsCopyPlayback (41.493 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testPracticeFlowSupportsLargestAccessibilityTextSize (56.767 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testPracticeImmediateFeedbackKeepsStateAfterFirstAnswer (18.313 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testPracticeModeChangeReopensCachedSessionFresh (62.160 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testRegularWidthMockExamEndExamDiscardsInProgressSession (33.992 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testRegularWidthMockExamResultPersistsAfterSubmit (47.200 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testReviewLaterHidesCorrectnessUntilSubmitAndResultsSurviveSave (22.065 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testSettingsResetClearsCompactMockExamCacheWithoutRelaunch (48.686 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testSettingsResetClearsSavedMockExamProgress (53.109 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testSubsectionPracticeOpensFromHubAndShowsReviewScreen (29.398 seconds)
  - PASSED: CanadianHamUITests.CanadianHamPracticeUITests/testWeakAreasImmediateSessionKeepsFeedbackPositionAndTallyAfterAnswers (50.918 seconds)
  - NOTE: post-success simulator diagnostic collection emitted xcrun simctl warning after ** TEST SUCCEEDED **; command exit status was success.
- macOS (43 named XCTest cases):
  - PASSED: CanadianHamTests.LocalizationCatalogTests/testEveryCatalogKeyHasFrenchTranslations (0.006 seconds)
  - PASSED: CanadianHamTests.LocalizationCatalogTests/testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries (0.004 seconds)
  - PASSED: CanadianHamTests.LocalizationCatalogTests/testLocalizedNullableTextAndLanguageFallsBackToEnglish (0.001 seconds)
  - PASSED: CanadianHamTests.LocalizationCatalogTests/testQuestionBankLoadErrorDescriptionUsesFrenchLocale (0.003 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testCompletedMorseCourseSessionIgnoresResubmittedAnswer (0.001 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testFixedTimingProfilesUseEngineValues (0.001 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp (0.001 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters (0.001 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseCourseProgressIgnoresStoredProgressForAnotherCourse (0.001 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseExamGeneratorMeetsReceivingExamConstraints (0.002 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseSettingsClampAndPreset (0.001 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseSettingsDecodesLegacyPayloadWithIsEnabled (0.001 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseSettingsRoundTripThroughUserDefaults (0.002 seconds)
  - PASSED: CanadianHamTests.MorseTrainerTests/testMorseStopDelayDrainsFadeBeforeStoppingEngine (0.001 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testAppSettingsModelPublishesMorseSettingsForRootViewSync (0.001 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testDecodesLegacyBasicExportWithoutBankIdFields (0.027 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme (0.023 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportOfOlderExportRollsBackWhenMorseProgressRemovalFails (0.026 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportRollbackKeepsExistingDataWhenReplacementFails (0.035 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportRollbackPropagatesMorseProgressRemovalFailure (0.028 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportsOlderExportWithoutMorseCourseProgressAsNoMorseProgress (0.024 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt (0.025 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues (0.001 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates (0.023 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportValidationRejectsInvalidMorseCourseProgress (0.025 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportValidationRejectsMismatchedScoreBankId (0.024 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt (0.026 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure (0.024 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testMockExamTimerRefreshPreservesFractionalRemainder (0.001 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testNativeSettingsGeneralBindingsUpdatePracticePreferences (0.005 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testProgressStoreRoundTripExportImportReset (0.038 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testResetRollsBackWhenMorseProgressRemovalFails (0.008 seconds)
  - PASSED: CanadianHamTests.ProgressStoreTests/testSharedAppleSettingsModelAppliesLivePreferenceUpdates (0.005 seconds)
  - PASSED: CanadianHamTests.QuestionBankTests/testBundledJSONDecodesExpectedCounts (0.019 seconds)
  - PASSED: CanadianHamTests.QuestionBankTests/testBundledLessonsAndExplanationsLoadThroughContentLibrary (0.447 seconds)
  - PASSED: CanadianHamTests.QuestionBankTests/testEngineQuestionDrawKeepsQuestionInsideRequestedCategory (0.018 seconds)
  - PASSED: CanadianHamTests.QuestionBankTests/testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion (0.079 seconds)
  - PASSED: CanadianHamTests.QuestionBankTests/testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes (0.001 seconds)
  - PASSED: CanadianHamTests.QuestionBankTests/testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons (0.328 seconds)
  - PASSED: CanadianHamTests.ReadinessAndScoringTests/testAdvancedScoringAndReadinessSuppressHonours (0.001 seconds)
  - PASSED: CanadianHamTests.ReadinessAndScoringTests/testExamScoringBoundaries (0.001 seconds)
  - PASSED: CanadianHamTests.ReadinessAndScoringTests/testReadinessStates (0.001 seconds)
  - PASSED: CanadianHamTests.ReadinessAndScoringTests/testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate (0.029 seconds)
- tvOS (15 named XCTest cases):
  - PASSED: CanadianHamTVTests.CanadianHamTVTests/testBundledQuestionBankLoadsForTVApp (0.025 seconds)
  - PASSED: CanadianHamTVTests.CanadianHamTVTests/testTVPracticeQuestionDrawStaysInCategoryAndShufflesAnswers (0.019 seconds)
  - PASSED: CanadianHamTVTests.CanadianHamTVTests/testTVPracticeSeedsVaryAcrossSessionIDs (0.019 seconds)
  - PASSED: CanadianHamTVUITests.CanadianHamTVUITests/testAboutAccessibilityAuditLightAndDark (13.594 seconds)
  - PASSED: CanadianHamTVUITests.CanadianHamTVUITests/testAboutLowerSectionsReachableWithRemote (13.658 seconds)
  - PASSED: CanadianHamTVUITests.CanadianHamTVUITests/testAboutShowsReleaseAttributionDisclaimerAndBankVersion (4.595 seconds)
  - PASSED: CanadianHamTVUITests.CanadianHamTVUITests/testCategoryGridAccessibilityAuditLightAndDark (13.111 seconds)
  - PASSED: CanadianHamTVUITests.CanadianHamTVUITests/testCategoryGridNavigatesToMorse (8.162 seconds)
  - PASSED: CanadianHamTVUITests.CanadianHamTVUITests/testFocusRingEvidenceScreenshots (75.771 seconds)
  - PASSED: CanadianHamTVUITests.CanadianHamTVUITests/testLayoutEvidenceScreenshots (78.930 seconds)
  - PASSED: CanadianHamTVUITests.CanadianHamTVUITests/testMorseAccessibilityAuditLightAndDark (12.948 seconds)
  - PASSED: CanadianHamTVUITests.CanadianHamTVUITests/testMorseScreenShowsPlaybackControls (6.602 seconds)
  - PASSED: CanadianHamTVUITests.CanadianHamTVUITests/testPracticeAccessibilityAuditLightAndDark (28.465 seconds)
  - PASSED: CanadianHamTVUITests.CanadianHamTVUITests/testPracticeInteractionSwitchesLanguageShowsFeedbackAndAdvances (17.008 seconds)
  - PASSED: CanadianHamTVUITests.CanadianHamTVUITests/testRemoteMenuReturnsPracticeAndAboutToCategoryGrid (11.307 seconds)
  - NOTE: post-success simulator diagnostic collection emitted xcrun simctl warning after ** TEST SUCCEEDED **; command exit status was success.
- visionOS (12 named XCTest cases):
  - PASSED: CanadianHamVisionTests.CanadianHamVisionTests/testBundledQuestionBankLoadsForVisionApp (0.048 seconds)
  - PASSED: CanadianHamVisionTests.CanadianHamVisionTests/testVisionPracticeQuestionDrawStaysInCategoryAndShufflesAnswers (0.028 seconds)
  - PASSED: CanadianHamVisionTests.CanadianHamVisionTests/testVisionPracticeSeedsVaryAcrossSessionIDs (0.029 seconds)
  - PASSED: CanadianHamVisionUITests.CanadianHamVisionUITests/testAboutAccessibilityAuditLightAndDark (31.265 seconds)
  - PASSED: CanadianHamVisionUITests.CanadianHamVisionUITests/testAboutShowsReleaseAttributionDisclaimerAndBankVersion (15.026 seconds)
  - PASSED: CanadianHamVisionUITests.CanadianHamVisionUITests/testCategoryGridAccessibilityAuditLightAndDark (20.824 seconds)
  - PASSED: CanadianHamVisionUITests.CanadianHamVisionUITests/testCategoryGridNavigatesToMorse (13.162 seconds)
  - PASSED: CanadianHamVisionUITests.CanadianHamVisionUITests/testLongestQuestionSupportsLargestDynamicType (23.798 seconds)
  - PASSED: CanadianHamVisionUITests.CanadianHamVisionUITests/testMorseAccessibilityAuditLightAndDark (17.332 seconds)
  - PASSED: CanadianHamVisionUITests.CanadianHamVisionUITests/testMorseScreenShowsPlaybackControls (21.416 seconds)
  - PASSED: CanadianHamVisionUITests.CanadianHamVisionUITests/testPracticeAccessibilityAuditLightAndDark (37.300 seconds)
  - PASSED: CanadianHamVisionUITests.CanadianHamVisionUITests/testPracticeInteractionSwitchesLanguageShowsFeedbackAndAdvances (17.868 seconds)
  - NOTE: post-success simulator diagnostic collection emitted xcrun simctl warning after ** TEST SUCCEEDED **; command exit status was success.

No code files were changed during final validation; this note records validation evidence only.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed Morse course summary copy for review/final-lesson sessions on web and Apple; changed TS/Swift daily streaks to count from today or yesterday using a shared fixture; made Apple local progress dates Gregorian in the current time zone; and added TS validation for unit IDs. Verified with package Vitest, DEVELOPER_DIR swift test, targeted web App tests, and targeted xbuild macOS unit tests named in notes.
<!-- SECTION:FINAL_SUMMARY:END -->
