---
id: TASK-36
title: Apple bundles exclude content README.md files
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 17:18'
updated_date: '2026-10-11 17:38'
labels:
  - apple
dependencies: []
ordinal: 76000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Release archives copy content/lessons/README.md and content/explanations/README.md into the app bundle (seen in fastlane/archives/mac/.../Contents/Resources/{lessons,explanations}/README.md). They are authoring docs with repo-relative links, not app content.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 iOS/macOS/tvOS/visionOS app bundles contain no README.md (or other authoring Markdown) from content/
- [x] #2 The bundle guard tests (11.11) assert it
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Confirm Apple content resource layout and which Markdown files are runtime lesson content versus authoring docs.\n2. Update apps/apple/project.yml so CanadianHam app/test content resources continue bundling runtime lesson Markdown while excluding content README.md/authoring Markdown, then regenerate the Xcode project twice and verify deterministic output.\n3. Extend bundle guard tests for iOS/macOS, tvOS, and visionOS to fail on bundled README.md files while preserving existing ContentLibrary load coverage.\n4. Prove the guard fails without the exclusion, restore the final code, run targeted tests, then commit and run the required full Apple suites, recording per-test evidence in Backlog.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Validation update for task-36 after commit 8e467e29b17e312a0f59b5d4c3a80dd555db3fe5:
- XcodeGen was run twice after editing project.yml; repeat runs left apps/apple/CanadianHam.xcodeproj/project.pbxproj unchanged (sha b31ff2fac7f8139183d022dc50131a8b90f6f5ed during verification).
- Negative proof: temporarily removed the README-pruning build phase, regenerated, and ran the targeted iOS bundle guard. It failed as expected with bundled README.md paths, then project.yml/project.pbxproj were restored before commit. Evidence: /Users/david/Developer/canadian-ham-task-36/apps/apple/CanadianHamTests/QuestionBankTests.swift:14: error: -[CanadianHamTests.QuestionBankTests testAppBundleContainsNoReadmeFiles] : XCTAssertEqual failed: ("["PlugIns/CanadianHamTests.xctest/explanations/README.md", "PlugIns/CanadianHamTests.xctest/lessons/README.md", "explanations/README.md", "lessons/README.md"]") is not equal to ("[]") - App bundle must not contain README.md files
- iOS final-code full suite: FAILED in existing Morse UI accessibility audits unrelated to this diff. The task-36 diff touches project resources and bundle guard tests only; it does not touch Morse app/UI implementation or CanadianHamPracticeUITests. Failing full-suite names: CanadianHamPracticeUITests.testAccessibilityAuditMorseCourseLessonAndSummaryDark(), CanadianHamPracticeUITests.testAccessibilityAuditMorseCourseLessonAndSummaryLight(), CanadianHamPracticeUITests.testAccessibilityAuditMorseExamGradedDiffDark(), CanadianHamPracticeUITests.testAccessibilityAuditMorseExamGradedDiffLight(). Targeted rerun passed the two MorseExamGradedDiff audits and still failed MorseCourseLessonAndSummaryDark/Light at apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:1895: "Expected final Morse course unit to be fully visible below the navigation bar". Per supervisor, leave task In Progress until Morse branch merges and full iOS can be rerun.
- macOS, tvOS and visionOS full suites passed on final code after waiting for the shared xbuild lock.

iOS full (failed)
Command: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test CODE_SIGNING_ALLOWED=NO
Started per-test names observed: 145
XCTest summary lines (tail): [('74', '4', '3'), ('74', '4', '3'), ('74', '4', '3')]
Failing tests: CanadianHamPracticeUITests.testAccessibilityAuditMorseCourseLessonAndSummaryDark(), CanadianHamPracticeUITests.testAccessibilityAuditMorseCourseLessonAndSummaryLight(), CanadianHamPracticeUITests.testAccessibilityAuditMorseExamGradedDiffDark(), CanadianHamPracticeUITests.testAccessibilityAuditMorseExamGradedDiffLight()
Per-test names:
  - CanadianHamTests.LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations
  - CanadianHamTests.LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries
  - CanadianHamTests.LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish
  - CanadianHamTests.LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale
  - CanadianHamTests.MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer
  - CanadianHamTests.MorseTrainerTests.testFixedTimingProfilesUseEngineValues
  - CanadianHamTests.MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp
  - CanadianHamTests.MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases
  - CanadianHamTests.MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins
  - CanadianHamTests.MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters
  - CanadianHamTests.MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone
  - CanadianHamTests.MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse
  - CanadianHamTests.MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition
  - CanadianHamTests.MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints
  - CanadianHamTests.MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime
  - CanadianHamTests.MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying
  - CanadianHamTests.MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal
  - CanadianHamTests.MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline
  - CanadianHamTests.MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters
  - CanadianHamTests.MorseTrainerTests.testMorseSettingsClampAndPreset
  - CanadianHamTests.MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode
  - CanadianHamTests.MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled
  - CanadianHamTests.MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults
  - CanadianHamTests.MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine
  - CanadianHamTests.MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced
  - CanadianHamTests.MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags
  - CanadianHamTests.MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback
  - CanadianHamTests.ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress
  - CanadianHamTests.ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts
  - CanadianHamTests.ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync
  - CanadianHamTests.ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement
  - CanadianHamTests.ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows
  - CanadianHamTests.ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields
  - CanadianHamTests.ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme
  - CanadianHamTests.ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal
  - CanadianHamTests.ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress
  - CanadianHamTests.ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons
  - CanadianHamTests.ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress
  - CanadianHamTests.ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses
  - CanadianHamTests.ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails
  - CanadianHamTests.ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure
  - CanadianHamTests.ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress
  - CanadianHamTests.ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt
  - CanadianHamTests.ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues
  - CanadianHamTests.ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates
  - CanadianHamTests.ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress
  - CanadianHamTests.ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId
  - CanadianHamTests.ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt
  - CanadianHamTests.ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure
  - CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints
  - CanadianHamTests.ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder
  - CanadianHamTests.ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints
  - CanadianHamTests.ProgressStoreTests.testProgressStoreRoundTripExportImportReset
  - CanadianHamTests.ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff
  - CanadianHamTests.ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails
  - CanadianHamTests.ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates
  - CanadianHamTests.ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress
  - CanadianHamTests.QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames
  - CanadianHamTests.QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours
  - CanadianHamTests.QuestionBankTests.testAppBundleContainsNoReadmeFiles
  - CanadianHamTests.QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories
  - CanadianHamTests.QuestionBankTests.testBundledJSONDecodesExpectedCounts
  - CanadianHamTests.QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary
  - CanadianHamTests.QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory
  - CanadianHamTests.QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion
  - CanadianHamTests.QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes
  - CanadianHamTests.QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons
  - CanadianHamTests.ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours
  - CanadianHamTests.ReadinessAndScoringTests.testExamScoringBoundaries
  - CanadianHamTests.ReadinessAndScoringTests.testReadinessStates
  - CanadianHamTests.ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate
  - CanadianHamUITests.CanadianHamPracticeUITests.testAboutShowsReleaseAttributionDisclaimerAndBankVersion
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditAdvancedCourseScreensDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditAdvancedCourseScreensLight
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditCoreScreensDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditCoreScreensLight
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditLearnFlowDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditLearnFlowLight
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMockExamFlowDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMockExamFlowLight
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseBeaconOutputDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseBeaconOutputLight
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseCourseLessonAndSummaryDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseCourseLessonAndSummaryLight
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseExamGradedDiffDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseExamGradedDiffLight
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseSendingMainScreenDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseSendingMainScreenLight
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseSendingResultsDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseSendingResultsLight
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseTapeOutputDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseTapeOutputLight
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditPracticeSessionDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditPracticeSessionLight
  - CanadianHamUITests.CanadianHamPracticeUITests.testCanPracticeInFrenchAndSeeFeedback
  - CanadianHamUITests.CanadianHamPracticeUITests.testCompactHomeStartPracticeAndMockExamBackReturnToHome
  - CanadianHamUITests.CanadianHamPracticeUITests.testCompactMockExamEndExamDiscardsInProgressSession
  - CanadianHamUITests.CanadianHamPracticeUITests.testCompactRootNavigationPreservesMockExamState
  - CanadianHamUITests.CanadianHamPracticeUITests.testCompactRootNavigationPreservesPracticeSessionState
  - CanadianHamUITests.CanadianHamPracticeUITests.testCompactTopLevelListPushesMorseThenLearn
  - CanadianHamUITests.CanadianHamPracticeUITests.testCompletesFirstMorseLessonSessionOnIOS
  - CanadianHamUITests.CanadianHamPracticeUITests.testCoursePickerSwitchesToAdvancedLessonsAndFiftyQuestionMockWithoutHonours
  - CanadianHamUITests.CanadianHamPracticeUITests.testCourseSwitchCancelKeepsImmediatePracticeFeedbackAndConfirmOpensAdvancedPractice
  - CanadianHamUITests.CanadianHamPracticeUITests.testCourseSwitchCancelKeepsUnsubmittedReviewLaterAnswersAndConfirmOpensAdvancedPractice
  - CanadianHamUITests.CanadianHamPracticeUITests.testCourseSwitchConfirmationAuditsDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testCourseSwitchConfirmationKeepsMockExamWhenCancelledLight
  - CanadianHamUITests.CanadianHamPracticeUITests.testDueReviewLaterSessionKeepsPositionTallyAndReviewAfterSubmit
  - CanadianHamUITests.CanadianHamPracticeUITests.testExplanationAppearsAfterAnsweringInPractice
  - CanadianHamUITests.CanadianHamPracticeUITests.testFrenchAboutKeepsLegalTextInEnglish
  - CanadianHamUITests.CanadianHamPracticeUITests.testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice
  - CanadianHamUITests.CanadianHamPracticeUITests.testLanguagePickerExistsOnCategoryListAndPractice
  - CanadianHamUITests.CanadianHamPracticeUITests.testLanguagePickerExistsOnCompactQuestionScreensAndIsAbsentOnMorse
  - CanadianHamUITests.CanadianHamPracticeUITests.testLearnOpensLessonAndShowsFirstHeading
  - CanadianHamUITests.CanadianHamPracticeUITests.testLearnUserNavigationOpensLessonQuiz
  - CanadianHamUITests.CanadianHamPracticeUITests.testLeavingCourseLessonStopsCoursePlaybackBeforeQuickListen
  - CanadianHamUITests.CanadianHamPracticeUITests.testLeavingMorseHomeStopsCopyPlaybackBeforeCourseLesson
  - CanadianHamUITests.CanadianHamPracticeUITests.testLessonQuizResultPersistsAfterRelaunch
  - CanadianHamUITests.CanadianHamPracticeUITests.testLongestAnswerWrapsAtLargestAccessibilityTextSize
  - CanadianHamUITests.CanadianHamPracticeUITests.testMockExamDoesNotShowCorrectnessBeforeSubmit
  - CanadianHamUITests.CanadianHamPracticeUITests.testMockExamHeaderControlsSupportLargestAccessibilityTextSize
  - CanadianHamUITests.CanadianHamPracticeUITests.testMockExamNextUnansweredJumpsAfterAnsweringFirstQuestion
  - CanadianHamUITests.CanadianHamPracticeUITests.testMockExamResultHeadingCarriesVoiceOverSubmissionSummary
  - CanadianHamUITests.CanadianHamPracticeUITests.testMorseCopyPracticeAndExamFlow
  - CanadianHamUITests.CanadianHamPracticeUITests.testMorseCopyStartResetsAfterAudioStartupFailure
  - CanadianHamUITests.CanadianHamPracticeUITests.testMorseExamGradingPushesResultsScreen
  - CanadianHamUITests.CanadianHamPracticeUITests.testMorseExamStartResetsAfterAudioStartupFailure
  - CanadianHamUITests.CanadianHamPracticeUITests.testMorseLessonSummaryShowsCorrectAnswerForWrongFinalAnswerOnIOS
  - CanadianHamUITests.CanadianHamPracticeUITests.testMorseQuickListenAfterFinishedCourseAudioDoesNotReportStop
  - CanadianHamUITests.CanadianHamPracticeUITests.testMorseResultsStartAgainActionsReturnToMorseOnce
  - CanadianHamUITests.CanadianHamPracticeUITests.testMorseSectionIsTopLevelShowsCourseAndOpensFirstLesson
  - CanadianHamUITests.CanadianHamPracticeUITests.testMorseSendingPracticeGradesImmediatelyAtDeadline
  - CanadianHamUITests.CanadianHamPracticeUITests.testMorseSendingPracticeUsesDebugHookAndPushesResultsScreen
  - CanadianHamUITests.CanadianHamPracticeUITests.testMorseStartingQuickListenStopsCopyPlayback
  - CanadianHamUITests.CanadianHamPracticeUITests.testMorseVisualOutputModeQuickListenOnIOS
  - CanadianHamUITests.CanadianHamPracticeUITests.testPracticeFlowSupportsLargestAccessibilityTextSize
  - CanadianHamUITests.CanadianHamPracticeUITests.testPracticeImmediateFeedbackKeepsStateAfterFirstAnswer
  - CanadianHamUITests.CanadianHamPracticeUITests.testPracticeModeChangeReopensCachedSessionFresh
  - CanadianHamUITests.CanadianHamPracticeUITests.testRegularWidthMockExamEndExamDiscardsInProgressSession
  - CanadianHamUITests.CanadianHamPracticeUITests.testRegularWidthMockExamResultPersistsAfterSubmit
  - CanadianHamUITests.CanadianHamPracticeUITests.testReviewLaterHidesCorrectnessUntilSubmitAndResultsSurviveSave
  - CanadianHamUITests.CanadianHamPracticeUITests.testSettingsResetClearsCompactMockExamCacheWithoutRelaunch
  - CanadianHamUITests.CanadianHamPracticeUITests.testSettingsResetClearsSavedMockExamProgress
  - CanadianHamUITests.CanadianHamPracticeUITests.testSubmittedReviewLaterPracticeDoesNotWarnBeforeCourseSwitch
  - CanadianHamUITests.CanadianHamPracticeUITests.testSubsectionPracticeOpensFromHubAndShowsReviewScreen
  - CanadianHamUITests.CanadianHamPracticeUITests.testWeakAreasImmediateSessionKeepsFeedbackPositionAndTallyAfterAnswers

iOS targeted rerun (failed)
Command: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseCourseLessonAndSummaryDark -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseCourseLessonAndSummaryLight -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseExamGradedDiffDark -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseExamGradedDiffLight test CODE_SIGNING_ALLOWED=NO
Started per-test names observed: 4
XCTest summary lines (tail): [('4', '2', '0'), ('4', '2', '0'), ('4', '2', '0')]
Failing tests: CanadianHamPracticeUITests.testAccessibilityAuditMorseCourseLessonAndSummaryDark(), CanadianHamPracticeUITests.testAccessibilityAuditMorseCourseLessonAndSummaryLight()
Per-test names:
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseCourseLessonAndSummaryDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseCourseLessonAndSummaryLight
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseExamGradedDiffDark
  - CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMorseExamGradedDiffLight

macOS full (passed)
Command: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
Started per-test names observed: 73
XCTest summary lines (tail): [('4', '0', '0'), ('73', '0', '0'), ('73', '0', '0')]
Per-test names:
  - CanadianHamTests.LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations
  - CanadianHamTests.LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries
  - CanadianHamTests.LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish
  - CanadianHamTests.LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale
  - CanadianHamTests.MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer
  - CanadianHamTests.MorseTrainerTests.testFixedTimingProfilesUseEngineValues
  - CanadianHamTests.MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp
  - CanadianHamTests.MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases
  - CanadianHamTests.MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins
  - CanadianHamTests.MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters
  - CanadianHamTests.MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone
  - CanadianHamTests.MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse
  - CanadianHamTests.MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition
  - CanadianHamTests.MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints
  - CanadianHamTests.MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime
  - CanadianHamTests.MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying
  - CanadianHamTests.MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal
  - CanadianHamTests.MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline
  - CanadianHamTests.MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters
  - CanadianHamTests.MorseTrainerTests.testMorseSettingsClampAndPreset
  - CanadianHamTests.MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode
  - CanadianHamTests.MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled
  - CanadianHamTests.MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults
  - CanadianHamTests.MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine
  - CanadianHamTests.MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced
  - CanadianHamTests.MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags
  - CanadianHamTests.MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback
  - CanadianHamTests.ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress
  - CanadianHamTests.ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts
  - CanadianHamTests.ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync
  - CanadianHamTests.ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement
  - CanadianHamTests.ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows
  - CanadianHamTests.ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields
  - CanadianHamTests.ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme
  - CanadianHamTests.ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal
  - CanadianHamTests.ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress
  - CanadianHamTests.ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons
  - CanadianHamTests.ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress
  - CanadianHamTests.ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses
  - CanadianHamTests.ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails
  - CanadianHamTests.ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure
  - CanadianHamTests.ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress
  - CanadianHamTests.ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt
  - CanadianHamTests.ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues
  - CanadianHamTests.ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates
  - CanadianHamTests.ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress
  - CanadianHamTests.ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId
  - CanadianHamTests.ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt
  - CanadianHamTests.ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure
  - CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints
  - CanadianHamTests.ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder
  - CanadianHamTests.ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference
  - CanadianHamTests.ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences
  - CanadianHamTests.ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints
  - CanadianHamTests.ProgressStoreTests.testProgressStoreRoundTripExportImportReset
  - CanadianHamTests.ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff
  - CanadianHamTests.ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails
  - CanadianHamTests.ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates
  - CanadianHamTests.ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress
  - CanadianHamTests.QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames
  - CanadianHamTests.QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours
  - CanadianHamTests.QuestionBankTests.testAppBundleContainsNoReadmeFiles
  - CanadianHamTests.QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories
  - CanadianHamTests.QuestionBankTests.testBundledJSONDecodesExpectedCounts
  - CanadianHamTests.QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary
  - CanadianHamTests.QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory
  - CanadianHamTests.QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion
  - CanadianHamTests.QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes
  - CanadianHamTests.QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons
  - CanadianHamTests.ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours
  - CanadianHamTests.ReadinessAndScoringTests.testExamScoringBoundaries
  - CanadianHamTests.ReadinessAndScoringTests.testReadinessStates
  - CanadianHamTests.ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate

tvOS full (passed)
Command: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamTV -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' test CODE_SIGNING_ALLOWED=NO
Started per-test names observed: 16
XCTest summary lines (tail): [('12', '0', '0'), ('12', '0', '0'), ('12', '0', '0')]
Per-test names:
  - CanadianHamTVTests.CanadianHamTVTests.testAppBundleContainsOnlyBasicQuestionBankResources
  - CanadianHamTVTests.CanadianHamTVTests.testBundledQuestionBankLoadsForTVApp
  - CanadianHamTVTests.CanadianHamTVTests.testTVPracticeQuestionDrawStaysInCategoryAndShufflesAnswers
  - CanadianHamTVTests.CanadianHamTVTests.testTVPracticeSeedsVaryAcrossSessionIDs
  - CanadianHamTVUITests.CanadianHamTVUITests.testAboutAccessibilityAuditLightAndDark
  - CanadianHamTVUITests.CanadianHamTVUITests.testAboutLowerSectionsReachableWithRemote
  - CanadianHamTVUITests.CanadianHamTVUITests.testAboutShowsReleaseAttributionDisclaimerAndBankVersion
  - CanadianHamTVUITests.CanadianHamTVUITests.testCategoryGridAccessibilityAuditLightAndDark
  - CanadianHamTVUITests.CanadianHamTVUITests.testCategoryGridNavigatesToMorse
  - CanadianHamTVUITests.CanadianHamTVUITests.testFocusRingEvidenceScreenshots
  - CanadianHamTVUITests.CanadianHamTVUITests.testLayoutEvidenceScreenshots
  - CanadianHamTVUITests.CanadianHamTVUITests.testMorseAccessibilityAuditLightAndDark
  - CanadianHamTVUITests.CanadianHamTVUITests.testMorseScreenShowsPlaybackControls
  - CanadianHamTVUITests.CanadianHamTVUITests.testPracticeAccessibilityAuditLightAndDark
  - CanadianHamTVUITests.CanadianHamTVUITests.testPracticeInteractionSwitchesLanguageShowsFeedbackAndAdvances
  - CanadianHamTVUITests.CanadianHamTVUITests.testRemoteMenuReturnsPracticeAndAboutToCategoryGrid

visionOS full (passed)
Command: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamVision -destination 'platform=visionOS Simulator,name=Apple Vision Pro' test CODE_SIGNING_ALLOWED=NO
Started per-test names observed: 13
XCTest summary lines (tail): [('9', '0', '0'), ('9', '0', '0'), ('9', '0', '0')]
Per-test names:
  - CanadianHamVisionTests.CanadianHamVisionTests.testAppBundleContainsOnlyBasicQuestionBankResources
  - CanadianHamVisionTests.CanadianHamVisionTests.testBundledQuestionBankLoadsForVisionApp
  - CanadianHamVisionTests.CanadianHamVisionTests.testVisionPracticeQuestionDrawStaysInCategoryAndShufflesAnswers
  - CanadianHamVisionTests.CanadianHamVisionTests.testVisionPracticeSeedsVaryAcrossSessionIDs
  - CanadianHamVisionUITests.CanadianHamVisionUITests.testAboutAccessibilityAuditLightAndDark
  - CanadianHamVisionUITests.CanadianHamVisionUITests.testAboutShowsReleaseAttributionDisclaimerAndBankVersion
  - CanadianHamVisionUITests.CanadianHamVisionUITests.testCategoryGridAccessibilityAuditLightAndDark
  - CanadianHamVisionUITests.CanadianHamVisionUITests.testCategoryGridNavigatesToMorse
  - CanadianHamVisionUITests.CanadianHamVisionUITests.testLongestQuestionSupportsLargestDynamicType
  - CanadianHamVisionUITests.CanadianHamVisionUITests.testMorseAccessibilityAuditLightAndDark
  - CanadianHamVisionUITests.CanadianHamVisionUITests.testMorseScreenShowsPlaybackControls
  - CanadianHamVisionUITests.CanadianHamVisionUITests.testPracticeAccessibilityAuditLightAndDark
  - CanadianHamVisionUITests.CanadianHamVisionUITests.testPracticeInteractionSwitchesLanguageShowsFeedbackAndAdvances

Review follow-up after APPROVE WITH NOTES:
- Commit fe2dbd85628714aa9460dc3ce8a9dda269a13b75 updates README pruning to use `find "${destination}" -type f -iname README.md -delete` across lessons/quizzes/explanations and updates bundle guard helpers to match README.md case-insensitively.
- Tried to keep ENABLE_USER_SCRIPT_SANDBOXING at the project default. With no declarations, the final `find` mechanism failed under the sandbox: `Sandbox: find(...) deny(1) file-read-data .../CanadianHam.app/lessons` and `find: .../lessons: Operation not permitted`. With the destination directories declared as inputFiles, the sandbox still denied recursive directory reads/deletion, e.g. `Sandbox: find(...) deny(1) file-read-data .../CanadianHam.app/lessons/m5-basic-electronics` plus `find: -delete: unlink(.../lessons/README.md): Operation not permitted`. With the three explicit README paths declared as inputFiles/outputFiles, Xcode refused with a dependency cycle: `Cycle inside CanadianHam ... script phase “Remove content authoring README files” ... node .../CanadianHam.app/explanations/README.md`. Because Xcode refused the sandboxed forms, the fallback keeps ENABLE_USER_SCRIPT_SANDBOXING=NO only on CanadianHam and CanadianHamTests where the post-resource pruning phase runs.
- Regenerated with `cd apps/apple && /opt/homebrew/bin/xcodegen generate --spec project.yml` repeatedly; the final no-op repeat kept project.pbxproj unchanged (sha a75012cd8f8f85e07dd628a84124e245894c6752).
- Targeted final-code bundle guard passed on iOS: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamTests/QuestionBankTests/testAppBundleContainsNoReadmeFiles test CODE_SIGNING_ALLOWED=NO` -> 1 test, 0 failures.
- Targeted final-code bundle guard passed on macOS: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests -only-testing:CanadianHamTests/QuestionBankTests/testAppBundleContainsNoReadmeFiles test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES` -> 1 test, 0 failures.
- Negative proof rerun on the final mechanism: temporarily removed the pruning script and regenerated, then ran the iOS bundle guard. It failed as expected with `XCTAssertEqual failed: (["PlugIns/CanadianHamTests.xctest/explanations/README.md", "PlugIns/CanadianHamTests.xctest/lessons/README.md", "explanations/README.md", "lessons/README.md"]) is not equal to ([])`. Restored project.yml and project.pbxproj afterward; worktree clean.

Post-merge validation after merging origin/main at 3906eee5 (Morse polish blocker now merged):
- iOS targeted bundle/content tests passed: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamTests/QuestionBankTests/testAppBundleContainsNoReadmeFiles -only-testing:CanadianHamTests/QuestionBankTests/testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons test CODE_SIGNING_ALLOWED=NO` -> 2 tests, 0 failures.\n- macOS targeted bundle/content tests passed: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests -only-testing:CanadianHamTests/QuestionBankTests/testAppBundleContainsNoReadmeFiles -only-testing:CanadianHamTests/QuestionBankTests/testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES` -> 2 tests, 0 failures.\n- tvOS targeted bundle guard passed: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamTV -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' -only-testing:CanadianHamTVTests/CanadianHamTVTests/testAppBundleContainsOnlyBasicQuestionBankResources test CODE_SIGNING_ALLOWED=NO` -> 1 test, 0 failures; this test includes the no-README assertion.\n- visionOS targeted bundle guard passed: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamVision -destination 'platform=visionOS Simulator,name=Apple Vision Pro' -only-testing:CanadianHamVisionTests/CanadianHamVisionTests/testAppBundleContainsOnlyBasicQuestionBankResources test CODE_SIGNING_ALLOWED=NO` -> 1 test, 0 failures; this test includes the no-README assertion.\n- Full Apple suites are intentionally left to the coordinator at merge time per the current testing policy.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented README pruning for Apple bundles and guard coverage across iOS/macOS/tvOS/visionOS. The merged branch keeps the reviewed sandboxing fallback: `ENABLE_USER_SCRIPT_SANDBOXING=NO` only on CanadianHam and CanadianHamTests because Xcode sandboxed variants either denied recursive find/delete of copied content README files or introduced an Xcode dependency cycle when declaring explicit README paths. Verified after merging origin/main with targeted xbuild runs for the iOS/macOS no-README and real-bundle lesson coverage tests plus the tvOS/visionOS basic bundle guards that include no-README assertions; all targeted tests passed. Full Apple suites are deferred to merge-time coordination per AGENTS.md testing policy.
<!-- SECTION:FINAL_SUMMARY:END -->
