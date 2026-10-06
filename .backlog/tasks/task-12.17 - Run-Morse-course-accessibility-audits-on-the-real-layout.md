---
id: TASK-12.17
title: Run Morse course accessibility audits on the real layout
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-04 13:22'
updated_date: '2026-10-06 18:21'
labels: []
milestone: m-1
dependencies: []
parent_task_id: TASK-12
ordinal: 64000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The current Morse course accessibility audit path uses the -CanadianHamMorseCourseAuditOnly launch argument to trim the Morse screen to course content. That kept the audit focused while the course shipped, but it means course audits do not exercise the real Morse section layout and surrounding content.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Morse course path, lesson, and summary accessibility audits launch the normal Morse section layout without -CanadianHamMorseCourseAuditOnly
- [x] #2 The audits still reach the course path, first lesson, and summary deterministically in light and dark without handlers or audit filters
- [x] #3 Regression tests or UI-test helpers are updated so the real-layout course audit remains stable
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the Morse course, Morse section navigation, and existing UI tests to identify the current route and accessibility audit seams.
2. Restructure Apple Morse navigation into real, short screens: Morse section home links to a Course home; Course home links to unit screens; unit screens link to lessons; lesson completion pushes summary, preserving progress, review, and playback registration.
3. Replace fixed course font sizing with Dynamic Type text styles/design tokens, avoiding hard-coded colors, LazyVStack, accessibilityHidden on visible text, and audit handlers.
4. Remove -CanadianHamMorseCourseAuditOnly and update iOS UI-test helpers/audits to exercise Morse home, Course home, a Unit screen, first lesson, and summary in light and dark, including scroll-and-reaudit coverage for long screens.
5. Run l10n/text checks, targeted iOS UI tests while iterating, then final platform checks per AGENTS.md task-execution and task-finalization policy; record per-test evidence before checking ACs and moving Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation notes after final code:
- `apps/apple/CanadianHam/Morse/MorseTrainerView.swift:61-74` changed the Morse home so it links to the course (`morse-course-open-button`) instead of embedding the course, while leaving copy, sending, quick listen, and settings on the real Morse layout.
- `apps/apple/CanadianHam/Morse/Course/MorseCourseView.swift:24-33` keeps the course in the app navigation stack without `-CanadianHamMorseCourseAuditOnly`; `:36-75` is the course home, `:157-187` is the unit screen, `:221-258` is the lesson/review session screen with playback coordinator register/unregister, and `:288-310` is the pushed summary screen.
- `apps/apple/CanadianHam/Morse/Course/MorseCourseView.swift:88-155` keeps the course home short enough for real-layout audits by using compact stats and two-column unit links; `:580-587` uses token-based opaque navigation-bar background on iOS. The prior audit failure was confirmed in `/tmp/t1217-ios-targeted-4.log:1678-1681`, where the lower-course audit sampled `Daily streak` and failed `Contrast failed` at `CanadianHamPracticeUITests.swift:1608`; after compacting the home, light/dark course audits passed.
- `apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:1407-1429` now audits the Morse home, course home, lower course home content, unit screen, lesson, and summary in light/dark with plain `performAccessibilityAudit()` and no handlers; `:1622-1681` contains the updated navigation/scroll helpers.
- `apps/apple/CanadianHam/Resources/Localizable.xcstrings:10008` adds `Lessons %lld–%lld` with en/fr/fr-CA through the required JSON round-trip.
Validation on final code commit `0fd1fd2c750267222668555e62006ff919410a3c`:
- `node scripts/check-apple-text-sources.ts` passed.
- `pnpm check:apple-l10n` passed, including French export plus tvOS and visionOS localization builds.
- Targeted iOS audits: `/tmp/t1217-ios-audits-6.log` passed `testAccessibilityAuditMorseCourseLessonAndSummaryDark` and `testAccessibilityAuditMorseCourseLessonAndSummaryLight`.
- Full iOS: `/tmp/t1217-ios-full.log` passed 124 tests (60 unit + 66 UI according to xbuild suite summaries/log test cases), including `testAccessibilityAuditMorseCourseLessonAndSummaryDark`, `testAccessibilityAuditMorseCourseLessonAndSummaryLight`, `testMorseStartingCourseAudioStopsCopyPlayback`, `testMorseStartingQuickListenStopsCopyPlayback`, `testMorseStartingQuickListenStopsCoursePlayback`, `testMorseQuickListenAfterFinishedCourseAudioDoesNotReportStop`, `testCompletesFirstMorseLessonSessionOnIOS`, and `testMorseLessonSummaryShowsCorrectAnswerForWrongFinalAnswerOnIOS`.
- Full macOS: `/tmp/t1217-macos-full.log` passed 60 unit tests.
- Full tvOS: `/tmp/t1217-tvos-full.log` passed 15 tests (3 unit + 12 UI).
- Full visionOS: `/tmp/t1217-visionos-full.log` passed 12 tests (3 unit + 9 UI).
- tvOS/visionOS were run because the string catalogue changed.

Review round 1: reopening to replace tap-gesture-driven course session navigation with button-driven state pushes, rename/fix playback tests to match post-redesign behavior, correct validation evidence, and rerun final checks.

Review round 1 implementation notes after final code:
- Final code commit from `git rev-parse HEAD` before validation: `5a3889e06b70d16eeb26b5609a7e5f41f5ae8631`.
- `apps/apple/CanadianHam/Morse/Course/MorseCourseView.swift:25-35` now drives lesson/review pushes from `showingSession` state; `:63-70` uses a Review `Button` action that prepares the review session before pushing; `:195-207` uses a lesson `Button` action that prepares the lesson before pushing, disables locked lessons, and keeps the locked state in the accessibility label. The prior `simultaneousGesture`, `allowsHitTesting(false)`, and `accessibilityRespondsToUserInteraction(false)` hacks are removed.
- `apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:69-75` asserts locked lesson 2 is disabled and does not open a session, then verifies the enabled first-lesson button path opens `Lesson 1 session`.
- `apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:371-397` renames the copy-playback test to match the real behavior: leaving the Morse home for the pushed course flow stops copy playback before the course lesson. `:399-425` renames the course-playback test to verify that leaving the course lesson stops course audio before Quick listen starts.
- `apps/apple/CanadianHam/Morse/MorseTrainerView.swift:77-140` fixes the leftover indentation after removing the old `else` branch.
Validation on final code commit:
- `node scripts/check-apple-text-sources.ts` passed.
- `pnpm check:apple-l10n` passed, including French export plus tvOS and visionOS localization builds.
- Targeted iOS run `/tmp/t1217-r1-targeted.log` passed 7 tests: `testMorseSectionIsTopLevelShowsCourseAndOpensFirstLesson`, `testLeavingMorseHomeStopsCopyPlaybackBeforeCourseLesson`, `testLeavingCourseLessonStopsCoursePlaybackBeforeQuickListen`, `testCompletesFirstMorseLessonSessionOnIOS`, `testMorseLessonSummaryShowsCorrectAnswerForWrongFinalAnswerOnIOS`, `testAccessibilityAuditMorseCourseLessonAndSummaryLight`, and `testAccessibilityAuditMorseCourseLessonAndSummaryDark`.
- Full iOS `/tmp/t1217-r1-ios-full.log` passed 124 tests:
  - CanadianHamTests.LocalizationCatalogTests testEveryCatalogKeyHasFrenchTranslations
  - CanadianHamTests.LocalizationCatalogTests testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries
  - CanadianHamTests.LocalizationCatalogTests testLocalizedNullableTextAndLanguageFallsBackToEnglish
  - CanadianHamTests.LocalizationCatalogTests testQuestionBankLoadErrorDescriptionUsesFrenchLocale
  - CanadianHamTests.MorseTrainerTests testCompletedMorseCourseSessionIgnoresResubmittedAnswer
  - CanadianHamTests.MorseTrainerTests testFixedTimingProfilesUseEngineValues
  - CanadianHamTests.MorseTrainerTests testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp
  - CanadianHamTests.MorseTrainerTests testMorseAudioSessionStaysActiveUntilLastPlayerReleases
  - CanadianHamTests.MorseTrainerTests testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters
  - CanadianHamTests.MorseTrainerTests testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone
  - CanadianHamTests.MorseTrainerTests testMorseCourseProgressIgnoresStoredProgressForAnotherCourse
  - CanadianHamTests.MorseTrainerTests testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition
  - CanadianHamTests.MorseTrainerTests testMorseExamGeneratorMeetsReceivingExamConstraints
  - CanadianHamTests.MorseTrainerTests testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime
  - CanadianHamTests.MorseTrainerTests testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying
  - CanadianHamTests.MorseTrainerTests testMorseSendingClassifiesTimingAndErrorSignal
  - CanadianHamTests.MorseTrainerTests testMorseSendingRemainingExamSecondsUsesFixedDeadline
  - CanadianHamTests.MorseTrainerTests testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters
  - CanadianHamTests.MorseTrainerTests testMorseSettingsClampAndPreset
  - CanadianHamTests.MorseTrainerTests testMorseSettingsDecodesLegacyPayloadWithIsEnabled
  - CanadianHamTests.MorseTrainerTests testMorseSettingsRoundTripThroughUserDefaults
  - CanadianHamTests.MorseTrainerTests testMorseStopDelayDrainsFadeBeforeStoppingEngine
  - CanadianHamTests.ProgressStoreTests testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress
  - CanadianHamTests.ProgressStoreTests testAdvancedImportRejectsHonoursAttempts
  - CanadianHamTests.ProgressStoreTests testAppSettingsModelPublishesMorseSettingsForRootViewSync
  - CanadianHamTests.ProgressStoreTests testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement
  - CanadianHamTests.ProgressStoreTests testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows
  - CanadianHamTests.ProgressStoreTests testDecodesLegacyBasicExportWithoutBankIdFields
  - CanadianHamTests.ProgressStoreTests testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme
  - CanadianHamTests.ProgressStoreTests testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons
  - CanadianHamTests.ProgressStoreTests testImportOfOlderExportDoesNotRemoveExistingMorseProgress
  - CanadianHamTests.ProgressStoreTests testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses
  - CanadianHamTests.ProgressStoreTests testImportRollbackKeepsExistingDataWhenReplacementFails
  - CanadianHamTests.ProgressStoreTests testImportRollbackPropagatesMorseProgressRemovalFailure
  - CanadianHamTests.ProgressStoreTests testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress
  - CanadianHamTests.ProgressStoreTests testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt
  - CanadianHamTests.ProgressStoreTests testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues
  - CanadianHamTests.ProgressStoreTests testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates
  - CanadianHamTests.ProgressStoreTests testImportValidationRejectsInvalidMorseCourseProgress
  - CanadianHamTests.ProgressStoreTests testImportValidationRejectsMismatchedScoreBankId
  - CanadianHamTests.ProgressStoreTests testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt
  - CanadianHamTests.ProgressStoreTests testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure
  - CanadianHamTests.ProgressStoreTests testMockExamTimerRefreshPreservesFractionalRemainder
  - CanadianHamTests.ProgressStoreTests testProgressStoreRoundTripExportImportReset
  - CanadianHamTests.ProgressStoreTests testResetRollsBackWhenMorseProgressRemovalFails
  - CanadianHamTests.ProgressStoreTests testSharedAppleSettingsModelAppliesLivePreferenceUpdates
  - CanadianHamTests.QuestionBankTests testAdvancedBundledJSONDecodesExpectedCountsAndEnglishCategoryFallbacks
  - CanadianHamTests.QuestionBankTests testAdvancedMockExamUsesFiftyQuestionsAndNoHonours
  - CanadianHamTests.QuestionBankTests testBundledJSONDecodesExpectedCounts
  - CanadianHamTests.QuestionBankTests testBundledLessonsAndExplanationsLoadThroughContentLibrary
  - CanadianHamTests.QuestionBankTests testEngineQuestionDrawKeepsQuestionInsideRequestedCategory
  - CanadianHamTests.QuestionBankTests testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion
  - CanadianHamTests.QuestionBankTests testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes
  - CanadianHamTests.QuestionBankTests testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons
  - CanadianHamTests.ReadinessAndScoringTests testAdvancedScoringAndReadinessSuppressHonours
  - CanadianHamTests.ReadinessAndScoringTests testExamScoringBoundaries
  - CanadianHamTests.ReadinessAndScoringTests testReadinessStates
  - CanadianHamTests.ReadinessAndScoringTests testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate
  - CanadianHamUITests.CanadianHamPracticeUITests testAboutShowsReleaseAttributionDisclaimerAndBankVersion
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditAdvancedCourseScreensDark
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditAdvancedCourseScreensLight
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditCoreScreensDark
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditCoreScreensLight
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditLearnFlowDark
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditLearnFlowLight
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMockExamFlowDark
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMockExamFlowLight
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseCourseLessonAndSummaryDark
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseCourseLessonAndSummaryLight
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseExamGradedDiffDark
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseExamGradedDiffLight
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseSendingMainScreenDark
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseSendingMainScreenLight
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseSendingResultsDark
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseSendingResultsLight
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditPracticeSessionDark
  - CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditPracticeSessionLight
  - CanadianHamUITests.CanadianHamPracticeUITests testCanPracticeInFrenchAndSeeFeedback
  - CanadianHamUITests.CanadianHamPracticeUITests testCompactHomeStartPracticeAndMockExamBackReturnToHome
  - CanadianHamUITests.CanadianHamPracticeUITests testCompactMockExamEndExamDiscardsInProgressSession
  - CanadianHamUITests.CanadianHamPracticeUITests testCompactRootNavigationPreservesMockExamState
  - CanadianHamUITests.CanadianHamPracticeUITests testCompactRootNavigationPreservesPracticeSessionState
  - CanadianHamUITests.CanadianHamPracticeUITests testCompactTopLevelListPushesMorseThenLearn
  - CanadianHamUITests.CanadianHamPracticeUITests testCompletesFirstMorseLessonSessionOnIOS
  - CanadianHamUITests.CanadianHamPracticeUITests testCoursePickerSwitchesToAdvancedLessonsAndFiftyQuestionMockWithoutHonours
  - CanadianHamUITests.CanadianHamPracticeUITests testCourseSwitchConfirmationAuditsDark
  - CanadianHamUITests.CanadianHamPracticeUITests testCourseSwitchConfirmationKeepsMockExamWhenCancelledLight
  - CanadianHamUITests.CanadianHamPracticeUITests testDueReviewLaterSessionKeepsPositionTallyAndReviewAfterSubmit
  - CanadianHamUITests.CanadianHamPracticeUITests testExplanationAppearsAfterAnsweringInPractice
  - CanadianHamUITests.CanadianHamPracticeUITests testFrenchAboutKeepsLegalTextInEnglish
  - CanadianHamUITests.CanadianHamPracticeUITests testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice
  - CanadianHamUITests.CanadianHamPracticeUITests testLanguagePickerExistsOnCategoryListAndPractice
  - CanadianHamUITests.CanadianHamPracticeUITests testLanguagePickerExistsOnCompactQuestionScreensAndIsAbsentOnMorse
  - CanadianHamUITests.CanadianHamPracticeUITests testLearnOpensLessonAndShowsFirstHeading
  - CanadianHamUITests.CanadianHamPracticeUITests testLearnUserNavigationOpensLessonQuiz
  - CanadianHamUITests.CanadianHamPracticeUITests testLeavingCourseLessonStopsCoursePlaybackBeforeQuickListen
  - CanadianHamUITests.CanadianHamPracticeUITests testLeavingMorseHomeStopsCopyPlaybackBeforeCourseLesson
  - CanadianHamUITests.CanadianHamPracticeUITests testLessonQuizResultPersistsAfterRelaunch
  - CanadianHamUITests.CanadianHamPracticeUITests testLongestAnswerWrapsAtLargestAccessibilityTextSize
  - CanadianHamUITests.CanadianHamPracticeUITests testMockExamDoesNotShowCorrectnessBeforeSubmit
  - CanadianHamUITests.CanadianHamPracticeUITests testMockExamHeaderControlsSupportLargestAccessibilityTextSize
  - CanadianHamUITests.CanadianHamPracticeUITests testMockExamNextUnansweredJumpsAfterAnsweringFirstQuestion
  - CanadianHamUITests.CanadianHamPracticeUITests testMockExamResultHeadingCarriesVoiceOverSubmissionSummary
  - CanadianHamUITests.CanadianHamPracticeUITests testMorseCopyPracticeAndExamFlow
  - CanadianHamUITests.CanadianHamPracticeUITests testMorseCopyStartResetsAfterAudioStartupFailure
  - CanadianHamUITests.CanadianHamPracticeUITests testMorseExamGradingPushesResultsScreen
  - CanadianHamUITests.CanadianHamPracticeUITests testMorseExamStartResetsAfterAudioStartupFailure
  - CanadianHamUITests.CanadianHamPracticeUITests testMorseLessonSummaryShowsCorrectAnswerForWrongFinalAnswerOnIOS
  - CanadianHamUITests.CanadianHamPracticeUITests testMorseQuickListenAfterFinishedCourseAudioDoesNotReportStop
  - CanadianHamUITests.CanadianHamPracticeUITests testMorseResultsStartAgainActionsReturnToMorseOnce
  - CanadianHamUITests.CanadianHamPracticeUITests testMorseSectionIsTopLevelShowsCourseAndOpensFirstLesson
  - CanadianHamUITests.CanadianHamPracticeUITests testMorseSendingPracticeGradesImmediatelyAtDeadline
  - CanadianHamUITests.CanadianHamPracticeUITests testMorseSendingPracticeUsesDebugHookAndPushesResultsScreen
  - CanadianHamUITests.CanadianHamPracticeUITests testMorseStartingQuickListenStopsCopyPlayback
  - CanadianHamUITests.CanadianHamPracticeUITests testPracticeFlowSupportsLargestAccessibilityTextSize
  - CanadianHamUITests.CanadianHamPracticeUITests testPracticeImmediateFeedbackKeepsStateAfterFirstAnswer
  - CanadianHamUITests.CanadianHamPracticeUITests testPracticeModeChangeReopensCachedSessionFresh
  - CanadianHamUITests.CanadianHamPracticeUITests testRegularWidthMockExamEndExamDiscardsInProgressSession
  - CanadianHamUITests.CanadianHamPracticeUITests testRegularWidthMockExamResultPersistsAfterSubmit
  - CanadianHamUITests.CanadianHamPracticeUITests testReviewLaterHidesCorrectnessUntilSubmitAndResultsSurviveSave
  - CanadianHamUITests.CanadianHamPracticeUITests testSettingsResetClearsCompactMockExamCacheWithoutRelaunch
  - CanadianHamUITests.CanadianHamPracticeUITests testSettingsResetClearsSavedMockExamProgress
  - CanadianHamUITests.CanadianHamPracticeUITests testSubsectionPracticeOpensFromHubAndShowsReviewScreen
  - CanadianHamUITests.CanadianHamPracticeUITests testWeakAreasImmediateSessionKeepsFeedbackPositionAndTallyAfterAnswers
- Full macOS `/tmp/t1217-r1-macos-full.log` passed 60 tests:
  - CanadianHamTests.LocalizationCatalogTests testEveryCatalogKeyHasFrenchTranslations
  - CanadianHamTests.LocalizationCatalogTests testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries
  - CanadianHamTests.LocalizationCatalogTests testLocalizedNullableTextAndLanguageFallsBackToEnglish
  - CanadianHamTests.LocalizationCatalogTests testQuestionBankLoadErrorDescriptionUsesFrenchLocale
  - CanadianHamTests.MorseTrainerTests testCompletedMorseCourseSessionIgnoresResubmittedAnswer
  - CanadianHamTests.MorseTrainerTests testFixedTimingProfilesUseEngineValues
  - CanadianHamTests.MorseTrainerTests testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp
  - CanadianHamTests.MorseTrainerTests testMorseAudioSessionStaysActiveUntilLastPlayerReleases
  - CanadianHamTests.MorseTrainerTests testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters
  - CanadianHamTests.MorseTrainerTests testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone
  - CanadianHamTests.MorseTrainerTests testMorseCourseProgressIgnoresStoredProgressForAnotherCourse
  - CanadianHamTests.MorseTrainerTests testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition
  - CanadianHamTests.MorseTrainerTests testMorseExamGeneratorMeetsReceivingExamConstraints
  - CanadianHamTests.MorseTrainerTests testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime
  - CanadianHamTests.MorseTrainerTests testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying
  - CanadianHamTests.MorseTrainerTests testMorseSendingClassifiesTimingAndErrorSignal
  - CanadianHamTests.MorseTrainerTests testMorseSendingRemainingExamSecondsUsesFixedDeadline
  - CanadianHamTests.MorseTrainerTests testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters
  - CanadianHamTests.MorseTrainerTests testMorseSettingsClampAndPreset
  - CanadianHamTests.MorseTrainerTests testMorseSettingsDecodesLegacyPayloadWithIsEnabled
  - CanadianHamTests.MorseTrainerTests testMorseSettingsRoundTripThroughUserDefaults
  - CanadianHamTests.MorseTrainerTests testMorseStopDelayDrainsFadeBeforeStoppingEngine
  - CanadianHamTests.ProgressStoreTests testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress
  - CanadianHamTests.ProgressStoreTests testAdvancedImportRejectsHonoursAttempts
  - CanadianHamTests.ProgressStoreTests testAppSettingsModelPublishesMorseSettingsForRootViewSync
  - CanadianHamTests.ProgressStoreTests testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement
  - CanadianHamTests.ProgressStoreTests testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows
  - CanadianHamTests.ProgressStoreTests testDecodesLegacyBasicExportWithoutBankIdFields
  - CanadianHamTests.ProgressStoreTests testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme
  - CanadianHamTests.ProgressStoreTests testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons
  - CanadianHamTests.ProgressStoreTests testImportOfOlderExportDoesNotRemoveExistingMorseProgress
  - CanadianHamTests.ProgressStoreTests testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses
  - CanadianHamTests.ProgressStoreTests testImportRollbackKeepsExistingDataWhenReplacementFails
  - CanadianHamTests.ProgressStoreTests testImportRollbackPropagatesMorseProgressRemovalFailure
  - CanadianHamTests.ProgressStoreTests testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress
  - CanadianHamTests.ProgressStoreTests testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt
  - CanadianHamTests.ProgressStoreTests testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues
  - CanadianHamTests.ProgressStoreTests testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates
  - CanadianHamTests.ProgressStoreTests testImportValidationRejectsInvalidMorseCourseProgress
  - CanadianHamTests.ProgressStoreTests testImportValidationRejectsMismatchedScoreBankId
  - CanadianHamTests.ProgressStoreTests testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt
  - CanadianHamTests.ProgressStoreTests testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure
  - CanadianHamTests.ProgressStoreTests testMockExamTimerRefreshPreservesFractionalRemainder
  - CanadianHamTests.ProgressStoreTests testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference
  - CanadianHamTests.ProgressStoreTests testNativeSettingsGeneralBindingsUpdatePracticePreferences
  - CanadianHamTests.ProgressStoreTests testProgressStoreRoundTripExportImportReset
  - CanadianHamTests.ProgressStoreTests testResetRollsBackWhenMorseProgressRemovalFails
  - CanadianHamTests.ProgressStoreTests testSharedAppleSettingsModelAppliesLivePreferenceUpdates
  - CanadianHamTests.QuestionBankTests testAdvancedBundledJSONDecodesExpectedCountsAndEnglishCategoryFallbacks
  - CanadianHamTests.QuestionBankTests testAdvancedMockExamUsesFiftyQuestionsAndNoHonours
  - CanadianHamTests.QuestionBankTests testBundledJSONDecodesExpectedCounts
  - CanadianHamTests.QuestionBankTests testBundledLessonsAndExplanationsLoadThroughContentLibrary
  - CanadianHamTests.QuestionBankTests testEngineQuestionDrawKeepsQuestionInsideRequestedCategory
  - CanadianHamTests.QuestionBankTests testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion
  - CanadianHamTests.QuestionBankTests testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes
  - CanadianHamTests.QuestionBankTests testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons
  - CanadianHamTests.ReadinessAndScoringTests testAdvancedScoringAndReadinessSuppressHonours
  - CanadianHamTests.ReadinessAndScoringTests testExamScoringBoundaries
  - CanadianHamTests.ReadinessAndScoringTests testReadinessStates
  - CanadianHamTests.ReadinessAndScoringTests testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate
- Full tvOS `/tmp/t1217-r1-tvos-full.log` passed 15 tests:
  - CanadianHamTVTests.CanadianHamTVTests testBundledQuestionBankLoadsForTVApp
  - CanadianHamTVTests.CanadianHamTVTests testTVPracticeQuestionDrawStaysInCategoryAndShufflesAnswers
  - CanadianHamTVTests.CanadianHamTVTests testTVPracticeSeedsVaryAcrossSessionIDs
  - CanadianHamTVUITests.CanadianHamTVUITests testAboutAccessibilityAuditLightAndDark
  - CanadianHamTVUITests.CanadianHamTVUITests testAboutLowerSectionsReachableWithRemote
  - CanadianHamTVUITests.CanadianHamTVUITests testAboutShowsReleaseAttributionDisclaimerAndBankVersion
  - CanadianHamTVUITests.CanadianHamTVUITests testCategoryGridAccessibilityAuditLightAndDark
  - CanadianHamTVUITests.CanadianHamTVUITests testCategoryGridNavigatesToMorse
  - CanadianHamTVUITests.CanadianHamTVUITests testFocusRingEvidenceScreenshots
  - CanadianHamTVUITests.CanadianHamTVUITests testLayoutEvidenceScreenshots
  - CanadianHamTVUITests.CanadianHamTVUITests testMorseAccessibilityAuditLightAndDark
  - CanadianHamTVUITests.CanadianHamTVUITests testMorseScreenShowsPlaybackControls
  - CanadianHamTVUITests.CanadianHamTVUITests testPracticeAccessibilityAuditLightAndDark
  - CanadianHamTVUITests.CanadianHamTVUITests testPracticeInteractionSwitchesLanguageShowsFeedbackAndAdvances
  - CanadianHamTVUITests.CanadianHamTVUITests testRemoteMenuReturnsPracticeAndAboutToCategoryGrid
- Full visionOS `/tmp/t1217-r1-visionos-full.log` passed 12 tests:
  - CanadianHamVisionTests.CanadianHamVisionTests testBundledQuestionBankLoadsForVisionApp
  - CanadianHamVisionTests.CanadianHamVisionTests testVisionPracticeQuestionDrawStaysInCategoryAndShufflesAnswers
  - CanadianHamVisionTests.CanadianHamVisionTests testVisionPracticeSeedsVaryAcrossSessionIDs
  - CanadianHamVisionUITests.CanadianHamVisionUITests testAboutAccessibilityAuditLightAndDark
  - CanadianHamVisionUITests.CanadianHamVisionUITests testAboutShowsReleaseAttributionDisclaimerAndBankVersion
  - CanadianHamVisionUITests.CanadianHamVisionUITests testCategoryGridAccessibilityAuditLightAndDark
  - CanadianHamVisionUITests.CanadianHamVisionUITests testCategoryGridNavigatesToMorse
  - CanadianHamVisionUITests.CanadianHamVisionUITests testLongestQuestionSupportsLargestDynamicType
  - CanadianHamVisionUITests.CanadianHamVisionUITests testMorseAccessibilityAuditLightAndDark
  - CanadianHamVisionUITests.CanadianHamVisionUITests testMorseScreenShowsPlaybackControls
  - CanadianHamVisionUITests.CanadianHamVisionUITests testPracticeAccessibilityAuditLightAndDark
  - CanadianHamVisionUITests.CanadianHamVisionUITests testPracticeInteractionSwitchesLanguageShowsFeedbackAndAdvances
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented real-layout Morse course audits by turning the Morse home course entry into pushed Course home, Unit, Lesson, and Summary screens, removing -CanadianHamMorseCourseAuditOnly from app/test paths, and updating helpers to run plain performAccessibilityAudit() on Morse home, course home (top/lower), unit, lesson, and summary in light/dark. Verified with node scripts/check-apple-text-sources.ts, pnpm check:apple-l10n, targeted light/dark Morse course audits, full iOS, macOS, tvOS, and visionOS xbuild suites on final code commit 0fd1fd2c750267222668555e62006ff919410a3c.
<!-- SECTION:FINAL_SUMMARY:END -->
