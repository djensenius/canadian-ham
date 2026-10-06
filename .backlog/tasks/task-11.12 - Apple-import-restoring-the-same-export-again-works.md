---
id: TASK-11.12
title: 'Apple import: restoring the same export again works'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-05 13:33'
updated_date: '2026-10-06 00:12'
labels: []
dependencies:
  - TASK-11.5
parent_task_id: TASK-11
priority: medium
ordinal: 65000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: ProgressModels marks questionId and attempt id as @Attribute(.unique). Since task-11.5, Apple import deletes the imported bank's records and reinserts them in one save. Re-importing the same export (the usual 'restore backup' case) has no test and could hit a uniqueness conflict. Found in the task-11.5 review (~/.cache/canadian-ham-reviews/t115-r2.md).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A unit test exports progress, then imports that same file twice; progress, exam attempts and lesson data are identical afterwards
- [x] #2 Any uniqueness conflict found is fixed; the macOS and iOS suites pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add Apple import regression coverage for exporting then importing the same file twice, and compare progress, attempts, lessons, Morse and preferences snapshots after each restore.
2. Fix any SwiftData uniqueness conflicts found by the regression and add import validation for Advanced attempts with honours=true on Apple and web.
3. Add focused Apple and web tests for rejecting honours=true when the target bank has no Honours result.
4. Run targeted import tests, then required web and Apple validation before checking acceptance criteria.

5. Address review round 1: add per-test full-run names/counts to task notes and re-run required checks after code changes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Started implementation. Added scope from PR #141 Copilot final summary: Advanced imports must reject attempts marked honours=true on Apple and web because Advanced has no Honours result.

Implemented Apple same-export-twice regression and Advanced honours import rejection on Apple/web. Web pnpm test, typecheck, build, dist URL/CSP audit, and Apple text-source check passed; iOS targeted ProgressStoreTests are queued behind the xbuild lock in /tmp/t1112-ios-progressstore.log.

Validation passed:
- pnpm --filter @canadian-ham/web test -- src/lib/progressStore.test.ts src/App.test.tsx -t "rejects Advanced import attempts marked with Honours|confirms before a course switch discards an unfinished mock exam" (Vitest: 13 files, 129 tests passed).
- pnpm test (release/content/morse/web: 100 node tests, 17 Morse tests, 129 web tests passed).
- pnpm typecheck; pnpm build:web; pnpm --filter @canadian-ham/web exec node scripts/audit-dist-urls.ts.
- node scripts/check-apple-text-sources.ts.
- Targeted iOS xbuild ProgressStoreTests: 21 tests passed, including testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons and testAdvancedImportRejectsHonoursAttempts.
- Apple final suite via /tmp/t1112-apple-final-2.log: pnpm check:apple-l10n passed (Apple French localization export complete); iOS full suite 60 tests passed; macOS full suite 53 tests passed; tvOS full suite 12 tests passed; visionOS full suite 9 tests passed.

Review round 1 requested changes: per-test final full-run evidence names/counts were missing; reopening task for fix evidence updates.

Review round 1 fixes completed and validated.

Code/test changes:
- AppSettingsModel now registers unfinished-work checks by window UUID and reports hasAnyUnfinishedCourseWork across all active RootView windows; RootView registers on appear and unregisters on disappear. Added unit test testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows.
- Web course-switch dialog now closes on Escape, clears on import/reset, returns focus to the course switcher after Cancel/Confirm, and only treats practice sessions as unfinished after at least one answer. Added web coverage for the mock confirmation flow and unanswered practice switch.
- Apple practice sessions now only count as unfinished after at least one answer; Settings Cancel returns accessibility focus toward the course picker. Fixed the weak Basic selected assertion in CanadianHamPracticeUITests.

Targeted validation:
- Web: App.test.tsx test "confirms before a course switch discards an unfinished mock exam" passed.
- Web: App.test.tsx test "does not confirm a course switch for an unanswered practice session" passed.
- iOS targeted xbuild: ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows passed.
- iOS targeted xbuild: CanadianHamPracticeUITests.testCourseSwitchConfirmationAuditsDark passed.
- iOS targeted xbuild: CanadianHamPracticeUITests.testCourseSwitchConfirmationKeepsMockExamWhenCancelledLight passed.

Final full-run evidence on final code commit c41cee8b75773b317a2fef87d0dfed010348199a:
- Web/content/Morse: pnpm test passed (content-tools 100 tests; Morse engine 17 tests; web 130 tests). pnpm typecheck, pnpm build:web, and dist URL/CSP audit passed.
- Apple text sources: node scripts/check-apple-text-sources.ts passed.
- iOS xbuild full run passed: CanadianHamTests unit bundle 52 tests, CanadianHamUITests UI bundle 60 tests.
  - iOS unit LocalizationCatalogTests: testEveryCatalogKeyHasFrenchTranslations; testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries; testLocalizedNullableTextAndLanguageFallsBackToEnglish; testQuestionBankLoadErrorDescriptionUsesFrenchLocale.
  - iOS unit MorseTrainerTests: testCompletedMorseCourseSessionIgnoresResubmittedAnswer; testFixedTimingProfilesUseEngineValues; testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp; testMorseAudioSessionStaysActiveUntilLastPlayerReleases; testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters; testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone; testMorseCourseProgressIgnoresStoredProgressForAnotherCourse; testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition; testMorseExamGeneratorMeetsReceivingExamConstraints; testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime; testMorseSettingsClampAndPreset; testMorseSettingsDecodesLegacyPayloadWithIsEnabled; testMorseSettingsRoundTripThroughUserDefaults; testMorseStopDelayDrainsFadeBeforeStoppingEngine.
  - iOS unit ProgressStoreTests: testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress; testAdvancedImportRejectsHonoursAttempts; testAppSettingsModelPublishesMorseSettingsForRootViewSync; testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows; testDecodesLegacyBasicExportWithoutBankIdFields; testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme; testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons; testImportOfOlderExportDoesNotRemoveExistingMorseProgress; testImportRollbackKeepsExistingDataWhenReplacementFails; testImportRollbackPropagatesMorseProgressRemovalFailure; testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress; testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt; testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues; testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates; testImportValidationRejectsInvalidMorseCourseProgress; testImportValidationRejectsMismatchedScoreBankId; testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt; testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure; testMockExamTimerRefreshPreservesFractionalRemainder; testProgressStoreRoundTripExportImportReset; testResetRollsBackWhenMorseProgressRemovalFails; testSharedAppleSettingsModelAppliesLivePreferenceUpdates.
  - iOS unit QuestionBankTests: testAdvancedBundledJSONDecodesExpectedCountsAndEnglishCategoryFallbacks; testAdvancedMockExamUsesFiftyQuestionsAndNoHonours; testBundledJSONDecodesExpectedCounts; testBundledLessonsAndExplanationsLoadThroughContentLibrary; testEngineQuestionDrawKeepsQuestionInsideRequestedCategory; testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion; testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes; testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons.
  - iOS unit ReadinessAndScoringTests: testAdvancedScoringAndReadinessSuppressHonours; testExamScoringBoundaries; testReadinessStates; testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate.
  - iOS UI CanadianHamPracticeUITests: testAboutShowsReleaseAttributionDisclaimerAndBankVersion; testAccessibilityAuditAdvancedCourseScreensDark; testAccessibilityAuditAdvancedCourseScreensLight; testAccessibilityAuditCoreScreensDark; testAccessibilityAuditCoreScreensLight; testAccessibilityAuditLearnFlowDark; testAccessibilityAuditLearnFlowLight; testAccessibilityAuditMockExamFlowDark; testAccessibilityAuditMockExamFlowLight; testAccessibilityAuditMorseCourseLessonAndSummaryDark; testAccessibilityAuditMorseCourseLessonAndSummaryLight; testAccessibilityAuditMorseExamGradedDiffDark; testAccessibilityAuditMorseExamGradedDiffLight; testAccessibilityAuditPracticeSessionDark; testAccessibilityAuditPracticeSessionLight; testCanPracticeInFrenchAndSeeFeedback; testCompactHomeStartPracticeAndMockExamBackReturnToHome; testCompactMockExamEndExamDiscardsInProgressSession; testCompactRootNavigationPreservesMockExamState; testCompactRootNavigationPreservesPracticeSessionState; testCompactTopLevelListPushesMorseThenLearn; testCompletesFirstMorseLessonSessionOnIOS; testCoursePickerSwitchesToAdvancedLessonsAndFiftyQuestionMockWithoutHonours; testCourseSwitchConfirmationAuditsDark; testCourseSwitchConfirmationKeepsMockExamWhenCancelledLight; testDueReviewLaterSessionKeepsPositionTallyAndReviewAfterSubmit; testExplanationAppearsAfterAnsweringInPractice; testFrenchAboutKeepsLegalTextInEnglish; testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice; testLanguagePickerExistsOnCategoryListAndPractice; testLanguagePickerExistsOnCompactQuestionScreensAndIsAbsentOnMorse; testLearnOpensLessonAndShowsFirstHeading; testLearnUserNavigationOpensLessonQuiz; testLessonQuizResultPersistsAfterRelaunch; testLongestAnswerWrapsAtLargestAccessibilityTextSize; testMockExamDoesNotShowCorrectnessBeforeSubmit; testMockExamHeaderControlsSupportLargestAccessibilityTextSize; testMockExamNextUnansweredJumpsAfterAnsweringFirstQuestion; testMockExamResultHeadingCarriesVoiceOverSubmissionSummary; testMorseCopyPracticeAndExamFlow; testMorseCopyStartResetsAfterAudioStartupFailure; testMorseExamGradingPushesResultsScreen; testMorseExamStartResetsAfterAudioStartupFailure; testMorseLessonSummaryShowsCorrectAnswerForWrongFinalAnswerOnIOS; testMorseQuickListenAfterFinishedCourseAudioDoesNotReportStop; testMorseResultsStartAgainActionsReturnToMorseOnce; testMorseSectionIsTopLevelShowsCourseAndOpensFirstLesson; testMorseStartingCourseAudioStopsCopyPlayback; testMorseStartingQuickListenStopsCopyPlayback; testMorseStartingQuickListenStopsCoursePlayback; testPracticeFlowSupportsLargestAccessibilityTextSize; testPracticeImmediateFeedbackKeepsStateAfterFirstAnswer; testPracticeModeChangeReopensCachedSessionFresh; testRegularWidthMockExamEndExamDiscardsInProgressSession; testRegularWidthMockExamResultPersistsAfterSubmit; testReviewLaterHidesCorrectnessUntilSubmitAndResultsSurviveSave; testSettingsResetClearsCompactMockExamCacheWithoutRelaunch; testSettingsResetClearsSavedMockExamProgress; testSubsectionPracticeOpensFromHubAndShowsReviewScreen; testWeakAreasImmediateSessionKeepsFeedbackPositionAndTallyAfterAnswers.
- macOS xbuild full run passed: CanadianHamTests unit bundle 54 tests (CanadianHamUITests skipped per project command).
  - macOS unit LocalizationCatalogTests: testEveryCatalogKeyHasFrenchTranslations; testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries; testLocalizedNullableTextAndLanguageFallsBackToEnglish; testQuestionBankLoadErrorDescriptionUsesFrenchLocale.
  - macOS unit MorseTrainerTests: testCompletedMorseCourseSessionIgnoresResubmittedAnswer; testFixedTimingProfilesUseEngineValues; testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp; testMorseAudioSessionStaysActiveUntilLastPlayerReleases; testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters; testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone; testMorseCourseProgressIgnoresStoredProgressForAnotherCourse; testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition; testMorseExamGeneratorMeetsReceivingExamConstraints; testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime; testMorseSettingsClampAndPreset; testMorseSettingsDecodesLegacyPayloadWithIsEnabled; testMorseSettingsRoundTripThroughUserDefaults; testMorseStopDelayDrainsFadeBeforeStoppingEngine.
  - macOS unit ProgressStoreTests: testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress; testAdvancedImportRejectsHonoursAttempts; testAppSettingsModelPublishesMorseSettingsForRootViewSync; testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows; testDecodesLegacyBasicExportWithoutBankIdFields; testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme; testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons; testImportOfOlderExportDoesNotRemoveExistingMorseProgress; testImportRollbackKeepsExistingDataWhenReplacementFails; testImportRollbackPropagatesMorseProgressRemovalFailure; testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress; testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt; testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues; testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates; testImportValidationRejectsInvalidMorseCourseProgress; testImportValidationRejectsMismatchedScoreBankId; testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt; testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure; testMockExamTimerRefreshPreservesFractionalRemainder; testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference; testNativeSettingsGeneralBindingsUpdatePracticePreferences; testProgressStoreRoundTripExportImportReset; testResetRollsBackWhenMorseProgressRemovalFails; testSharedAppleSettingsModelAppliesLivePreferenceUpdates.
  - macOS unit QuestionBankTests: testAdvancedBundledJSONDecodesExpectedCountsAndEnglishCategoryFallbacks; testAdvancedMockExamUsesFiftyQuestionsAndNoHonours; testBundledJSONDecodesExpectedCounts; testBundledLessonsAndExplanationsLoadThroughContentLibrary; testEngineQuestionDrawKeepsQuestionInsideRequestedCategory; testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion; testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes; testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons.
  - macOS unit ReadinessAndScoringTests: testAdvancedScoringAndReadinessSuppressHonours; testExamScoringBoundaries; testReadinessStates; testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate.
- tvOS and visionOS full suites were not rerun in this review-fix round because the review fixes did not change Localizable.xcstrings or platform-shared catalogue resources; previous branch validation already covered them.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Review round 1 fixes completed: per-test final run evidence was added to task notes, AppSettingsModel now tracks unfinished-work checks per window, and validation passed on web plus final iOS/macOS xbuild runs. Import-specific behavior from task-11.12 remains covered by same-export-twice and Advanced honours rejection tests.
<!-- SECTION:FINAL_SUMMARY:END -->
