---
id: TASK-58
title: Investigate Pro Max landscape calculator key reachability
status: Done
assignee:
  - '@worker'
created_date: '2026-10-18 06:03'
updated_date: '2026-10-20 01:41'
labels:
  - apple
dependencies: []
priority: low
type: bug
ordinal: 136000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The iPhone 17 Pro Max targeted run reproduced a main-branch failure in CanadianHamExamToolsUITests.testForcedRegularIPhoneLandscapeMediumSheetScrollsEveryCalculatorKey: the test could not find the calculator-key-percent control in the forced-regular landscape medium sheet. This is separate from TASK-15 Duo layout work and should be diagnosed without weakening the calculator reachability coverage.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The iPhone 17 Pro Max forced-regular landscape medium-sheet calculator-key-percent failure is reproduced or shown no longer reproducible with a targeted xbuild UI-test run
- [x] #2 The underlying calculator sheet reachability issue is fixed without deleting, skipping or weakening the calculator key reachability assertions
- [x] #3 Targeted iPhone 17 Pro Max CanadianHamExamToolsUITests validation is recorded with log paths
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Reproduce the existing targeted forced-regular landscape calculator failure on iPhone 17 Pro Max with xbuild.
2. Inspect calculator sheet layout and test-local scrolling to identify the root cause; apply the smallest adaptive layout or test-local helper fix without weakening reachability/44 pt assertions or changing guarded shared helpers.
3. Run targeted landscape/calculator tests on Pro Max and Pro, the landscape reachability test on Duo OS 27.1, and macOS unit tests; record per-test evidence.
4. Finalize task evidence, commit, and submit for required review before opening the requested PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Baseline reproduced at 79b47a9e (main after TASK-60): iPhone 17 Pro Max OS 27.0 targeted xbuild exited 65. Test failed after 132.787s at CanadianHamExamToolsUITests.swift:1352 with "Failed to get matching snapshot" for calculator-key-percent. Evidence: /tmp/task-58/reproduce.log, /tmp/task-58/reproduce.xcresult, /tmp/task-58/reproduce-attachments/. The test-local scrollCalculatorPanelUntilElementExists helper reads element.identifier in its context string while !element.exists, causing XCTest to fail before the first swipe. The failure hierarchy shows five lazy-grid rows through equals (y356.7...402.7) inside the calculator ScrollView (y86.7...408), with the sixth row not yet instantiated. Replaced only that premature identifier lookup with literal diagnostic context; no product layout change is warranted unless corrected scrolling reveals an actual reachability issue. All assertions and guarded shared helpers remain unchanged.

Corrected targeted Pro Max OS 27.0 reachability test passed (xbuild exit 0): /tmp/task-58/fixed-reachability.log and /tmp/task-58/fixed-reachability.xcresult. Product already scrolls every key correctly; this is a genuine test-helper snapshot bug, not a sheet/home-indicator/detent defect. Supervisor reviewed implementation commit 78a2857e33741199f2035e0110cf0b4aaedd8bdc and approved the test-only fix before PR creation. Test guard passed with no guarded changes. Remaining device matrix is running via /tmp/task-58/verify.sh.

Final acceptance evidence:
- AC #1: reproduced main baseline on Pro Max OS 27.0 with targeted xbuild (exit 65, 132.787s, missing calculator-key-percent snapshot at helper line 1352), then passed after the test-only correction (exit 0, 161.373s).
- AC #2: product reachability was already correct. The test-local helper no longer resolves element.identifier before scrolling an uninstantiated LazyVGrid row. No product code, assertions, swipe budgets, audit exceptions, skips, or guarded shared helpers changed. All 24 keys pass the original existence/hittability/44 pt checks on Pro Max, Pro, and Duo. Supervisor explicitly approved this test-only diagnosis and source commit 78a2857e33741199f2035e0110cf0b4aaedd8bdc before PR creation.
- AC #3: complete Pro Max targeted validation is 16/16 green; logs, result bundles, and per-test results below. Requested Pro regression 16/16, Duo OS 27.1 landscape 1/1, and macOS units 177/177 also pass. Every requested run is complete (the earlier queued/running note is superseded).

## Validation

All Apple builds/tests used `xbuild`, launched through `nohup` scripts with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Shared build locks were respected; no builds were killed. Logs were polled only with the requested error/failure/summary grep; per-test results below come from `xcresulttool get test-results tests`.

| Run | Destination | Result | Evidence |
| --- | --- | --- | --- |
| reproduce | iPhone 17 Pro Max, OS 27.0 (baseline) | 0 passed / 1 failed / 0 skipped (expected baseline reproduction) | `/tmp/task-58/reproduce.log`, `/tmp/task-58/reproduce.xcresult` |
| fixed-reachability | iPhone 17 Pro Max, OS 27.0 (corrected helper) | 1 passed / 0 failed / 0 skipped | `/tmp/task-58/fixed-reachability.log`, `/tmp/task-58/fixed-reachability.xcresult` |
| promax-calculator | iPhone 17 Pro Max, OS 27.0 (remaining calculator/landscape) | 15 passed / 0 failed / 0 skipped | `/tmp/task-58/promax-calculator.log`, `/tmp/task-58/promax-calculator.xcresult` |
| pro-calculator | iPhone 17 Pro, OS 27.0 (calculator/landscape) | 16 passed / 0 failed / 0 skipped | `/tmp/task-58/pro-calculator.log`, `/tmp/task-58/pro-calculator.xcresult` |
| duo-landscape | iPhone Duo, OS 27.1 (landscape reachability) | 1 passed / 0 failed / 0 skipped | `/tmp/task-58/duo-landscape.log`, `/tmp/task-58/duo-landscape.xcresult` |
| macos-unit | macOS arm64 (unit tests only) | 177 passed / 0 failed / 0 skipped | `/tmp/task-58/macos-unit.log`, `/tmp/task-58/macos-unit.xcresult` |

### UI per-test results

All rows are in `CanadianHamUITests/CanadianHamExamToolsUITests`. Pro Max combines the corrected single-test run with the 15-test remaining calculator/landscape run. Each of these runs has zero skipped tests.

| Test | Pro Max OS 27.0 | Pro OS 27.0 |
| --- | --- | --- |
| `testAccessibilityAuditExamToolsDark` | Passed (137.094s) | Passed (430.249s) |
| `testAccessibilityAuditExamToolsLight` | Passed (136.111s) | Passed (453.855s) |
| `testCalculatorAutoFocusesHardwareKeyboardOnOpen` | Passed (12.876s) | Passed (24.250s) |
| `testCalculatorKeyboardInputIsFocusScoped` | Passed (57.036s) | Passed (139.352s) |
| `testCalculatorValueResetsForNewMockExam` | Passed (40.963s) | Passed (79.550s) |
| `testCalculatorValueSurvivesCloseAndReopenAndResetsForNewSession` | Passed (57.952s) | Passed (129.849s) |
| `testForcedRegularIPhoneLandscapeCalculatorUsesSheetAndKeepsSelection` | Passed (34.092s) | Passed (78.847s) |
| `testForcedRegularIPhoneLandscapeMediumSheetScrollsEveryCalculatorKey` | Passed (161.373s) | Passed (481.309s) |
| `testLargeDetentCalculatorRunsFullAccessibilityAuditLightAndDark` | Passed (40.902s) | Passed (69.932s) |
| `testLargestDynamicTypeKeepsCalculatorGridReachableLightAndDark` | Passed (49.418s) | Passed (94.478s) |
| `testMockExamCalculatorKeepsAnswersHittableAndTimerRuns` | Passed (43.038s) | Passed (114.918s) |
| `testMockExamQuestionsNavigatorPresentsAfterCalculatorSheet` | Passed (26.327s) | Passed (45.750s) |
| `testPracticeCalculatorSheetKeepsAnswersHittableAtMediumDetent` | Passed (54.219s) | Passed (111.815s) |
| `testRegularWidthMockExamUsesCalculatorInspectorWithoutHints` | Passed (19.784s) | Passed (46.738s) |
| `testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` | Passed (35.826s) | Passed (70.087s) |
| `testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` | Passed (39.622s) | Passed (81.472s) |

Duo OS 27.1: `testForcedRegularIPhoneLandscapeMediumSheetScrollsEveryCalculatorKey()` — Passed (269.700s).

<details>
<summary>macOS unit per-test results</summary>

| Test | Result |
| --- | --- |
| `DuoLayoutPolicyTests/testCompactWidthIPhoneKeepsSheetPolicy()` | Passed (0.001s) |
| `DuoLayoutPolicyTests/testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact()` | Passed (0.001s) |
| `DuoLayoutPolicyTests/testIPadInspectorRuleRemainsSizeClassDriven()` | Passed (0.000s) |
| `DuoLayoutPolicyTests/testMacAndOtherIdiomsNeverUseIPhonePolicy()` | Passed (0.002s) |
| `DuoLayoutPolicyTests/testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy()` | Passed (0.001s) |
| `DuoLayoutPolicyTests/testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact()` | Passed (0.000s) |
| `ExamCalculatorViewModelTests/testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp()` | Passed (0.001s) |
| `ExamCalculatorViewModelTests/testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys()` | Passed (0.001s) |
| `ExamCalculatorViewModelTests/testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere()` | Passed (0.001s) |
| `ExamCalculatorViewModelTests/testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds()` | Passed (0.001s) |
| `ExamCalculatorViewModelTests/testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes()` | Passed (0.001s) |
| `ExamCalculatorViewModelTests/testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale()` | Passed (0.001s) |
| `ExamCalculatorViewModelTests/testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString()` | Passed (0.001s) |
| `ExamCalculatorViewModelTests/testKeyHandlingProducesEngineDisplayAndSpokenResult()` | Passed (0.001s) |
| `ExamCalculatorViewModelTests/testQuestionCardFocusResetKeepsTextSelectionEnabled()` | Passed (0.004s) |
| `ExamCalculatorViewModelTests/testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet()` | Passed (0.001s) |
| `ExamCalculatorViewModelTests/testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately()` | Passed (0.001s) |
| `HintSessionStateTests/testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine()` | Passed (0.001s) |
| `HintSessionStateTests/testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer()` | Passed (0.000s) |
| `HintSessionStateTests/testHingePeekEndsWhenPhoneFullyOpensOrCloses()` | Passed (0.000s) |
| `HintSessionStateTests/testHingePeekFastUnfoldThroughBandNeverPeeks()` | Passed (0.000s) |
| `HintSessionStateTests/testHingePeekLeavingToleranceDoesNotResetDismissalSuppression()` | Passed (0.000s) |
| `HintSessionStateTests/testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression()` | Passed (0.000s) |
| `HintSessionStateTests/testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell()` | Passed (0.000s) |
| `HintSessionStateTests/testHingePeekPresentationDismissalSuppressesReopenUntilReset()` | Passed (0.001s) |
| `HintSessionStateTests/testHingePeekPresentationImmediateAnswerEndsEligibility()` | Passed (0.001s) |
| `HintSessionStateTests/testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset()` | Passed (0.000s) |
| `HintSessionStateTests/testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear()` | Passed (0.006s) |
| `HintSessionStateTests/testHingePeekPresentationStartsOnlyOnceUntilPostureReset()` | Passed (0.000s) |
| `HintSessionStateTests/testHingePeekRecheckPeeksWithoutNewSamples()` | Passed (0.000s) |
| `HintSessionStateTests/testHingePeekRequiresStableDwellInSlightOpenBand()` | Passed (0.000s) |
| `HintSessionStateTests/testHingePeekSlowCloseThroughBandNeverPeeks()` | Passed (0.001s) |
| `HintSessionStateTests/testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek()` | Passed (0.001s) |
| `HintSessionStateTests/testHingePeekToleratesSmallJitterOnlyAfterPeekStarts()` | Passed (0.001s) |
| `HintSessionStateTests/testHingePeekUnavailableSampleDoesNotResetDismissalSuppression()` | Passed (0.000s) |
| `HintSessionStateTests/testHintQualificationMarksUnansweredQuestionAsQualifiedOnly()` | Passed (0.000s) |
| `HintSessionStateTests/testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp()` | Passed (0.500s) |
| `HintSessionStateTests/testHintVisibilityTimerDoesNotQualifyShortPeekRoute()` | Passed (0.293s) |
| `HintSessionStateTests/testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp()` | Passed (0.002s) |
| `HintSessionStateTests/testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable()` | Passed (0.001s) |
| `HintSessionStateTests/testReviewLaterHintAfterSelectionRecordsHelp()` | Passed (0.001s) |
| `HintSessionStateTests/testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission()` | Passed (0.002s) |
| `HintSessionStateTests/testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange()` | Passed (2.668s) |
| `LocalizationCatalogTests/testEveryCatalogKeyHasFrenchTranslations()` | Passed (0.020s) |
| `LocalizationCatalogTests/testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries()` | Passed (0.004s) |
| `LocalizationCatalogTests/testLanguagePreferenceResolvesSystemAndOverrides()` | Passed (0.001s) |
| `LocalizationCatalogTests/testLocalizedNullableTextAndLanguageFallsBackToEnglish()` | Passed (0.000s) |
| `LocalizationCatalogTests/testQuestionBankLoadErrorDescriptionUsesFrenchLocale()` | Passed (0.003s) |
| `MorseTrainerTests/testCompletedMorseCourseSessionIgnoresResubmittedAnswer()` | Passed (0.001s) |
| `MorseTrainerTests/testFixedTimingProfilesUseEngineValues()` | Passed (0.001s) |
| `MorseTrainerTests/testLessonBodyAndBulletContrastTokensMeetMinimumRatio()` | Passed (0.001s) |
| `MorseTrainerTests/testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp()` | Passed (0.002s) |
| `MorseTrainerTests/testMorseAudioSessionStaysActiveUntilLastPlayerReleases()` | Passed (0.000s) |
| `MorseTrainerTests/testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins()` | Passed (0.001s) |
| `MorseTrainerTests/testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters()` | Passed (0.001s) |
| `MorseTrainerTests/testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone()` | Passed (0.002s) |
| `MorseTrainerTests/testMorseCourseProgressIgnoresStoredProgressForAnotherCourse()` | Passed (0.001s) |
| `MorseTrainerTests/testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition()` | Passed (0.001s) |
| `MorseTrainerTests/testMorseExamGeneratorMeetsReceivingExamConstraints()` | Passed (0.002s) |
| `MorseTrainerTests/testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime()` | Passed (0.001s) |
| `MorseTrainerTests/testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying()` | Passed (0.001s) |
| `MorseTrainerTests/testMorseSendingClassifiesTimingAndErrorSignal()` | Passed (0.001s) |
| `MorseTrainerTests/testMorseSendingPendingFinalizationHelperCancelsAndClears()` | Passed (0.001s) |
| `MorseTrainerTests/testMorseSendingRemainingExamSecondsUsesFixedDeadline()` | Passed (0.001s) |
| `MorseTrainerTests/testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters()` | Passed (0.001s) |
| `MorseTrainerTests/testMorseSettingsClampAndPreset()` | Passed (0.000s) |
| `MorseTrainerTests/testMorseSettingsCodableRoundTripPreservesOutputMode()` | Passed (0.001s) |
| `MorseTrainerTests/testMorseSettingsDecodesLegacyPayloadWithIsEnabled()` | Passed (0.001s) |
| `MorseTrainerTests/testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast()` | Passed (0.005s) |
| `MorseTrainerTests/testMorseSettingsRoundTripThroughUserDefaults()` | Passed (0.004s) |
| `MorseTrainerTests/testMorseStopDelayDrainsFadeBeforeStoppingEngine()` | Passed (0.001s) |
| `MorseTrainerTests/testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced()` | Passed (0.001s) |
| `MorseTrainerTests/testReduceFlashingDecisionUsesInjectedFlags()` | Passed (0.000s) |
| `MorseTrainerTests/testReduceFlashingStopsOnlyRunningVisualBeacon()` | Passed (0.000s) |
| `MorseTrainerTests/testScheduleMorseVisualPlaybackInitialStateAndFallback()` | Passed (0.001s) |
| `ProgressStoreTests/testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress()` | Passed (0.080s) |
| `ProgressStoreTests/testAdvancedImportRejectsHonoursAttempts()` | Passed (0.023s) |
| `ProgressStoreTests/testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch()` | Passed (0.003s) |
| `ProgressStoreTests/testAppSettingsModelPublishesMorseSettingsForRootViewSync()` | Passed (0.001s) |
| `ProgressStoreTests/testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement()` | Passed (0.001s) |
| `ProgressStoreTests/testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows()` | Passed (0.001s) |
| `ProgressStoreTests/testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore()` | Passed (0.019s) |
| `ProgressStoreTests/testDecodesLegacyBasicExportWithoutBankIdFields()` | Passed (0.030s) |
| `ProgressStoreTests/testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme()` | Passed (0.027s) |
| `ProgressStoreTests/testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker()` | Passed (0.015s) |
| `ProgressStoreTests/testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt()` | Passed (0.055s) |
| `ProgressStoreTests/testFreshInstallDefaultsLanguageToSystem()` | Passed (0.008s) |
| `ProgressStoreTests/testICloudAccountSignalsUseInitInjectedFactory()` | Passed (0.069s) |
| `ProgressStoreTests/testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot()` | Passed (0.028s) |
| `ProgressStoreTests/testICloudDeleteCanDeleteLocalDataAfterZoneDelete()` | Passed (0.024s) |
| `ProgressStoreTests/testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload()` | Passed (0.131s) |
| `ProgressStoreTests/testICloudMergeFixtureIsPermutationIndependentAndIdempotent()` | Passed (0.003s) |
| `ProgressStoreTests/testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal()` | Passed (0.001s) |
| `ProgressStoreTests/testICloudSyncToggleAndAccountSignalsPreserveLocalProgress()` | Passed (0.051s) |
| `ProgressStoreTests/testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing()` | Passed (0.033s) |
| `ProgressStoreTests/testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields()` | Passed (0.034s) |
| `ProgressStoreTests/testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount()` | Passed (0.045s) |
| `ProgressStoreTests/testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons()` | Passed (0.061s) |
| `ProgressStoreTests/testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange()` | Passed (0.032s) |
| `ProgressStoreTests/testImportOfOlderExportDoesNotRemoveExistingMorseProgress()` | Passed (0.032s) |
| `ProgressStoreTests/testImportRejectsInvalidSyncDeviceRows()` | Passed (0.037s) |
| `ProgressStoreTests/testImportRejectsUnsupportedLanguagePreferenceValues()` | Passed (0.036s) |
| `ProgressStoreTests/testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses()` | Passed (0.070s) |
| `ProgressStoreTests/testImportRollbackKeepsExistingDataWhenReplacementFails()` | Passed (0.044s) |
| `ProgressStoreTests/testImportRollbackPropagatesMorseProgressRemovalFailure()` | Passed (0.032s) |
| `ProgressStoreTests/testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress()` | Passed (0.031s) |
| `ProgressStoreTests/testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt()` | Passed (0.032s) |
| `ProgressStoreTests/testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues()` | Passed (0.001s) |
| `ProgressStoreTests/testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates()` | Passed (0.028s) |
| `ProgressStoreTests/testImportValidationRejectsDuplicateMorseDailyActivityDates()` | Passed (0.036s) |
| `ProgressStoreTests/testImportValidationRejectsInvalidMorseCourseProgress()` | Passed (0.037s) |
| `ProgressStoreTests/testImportValidationRejectsMismatchedScoreBankId()` | Passed (0.032s) |
| `ProgressStoreTests/testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt()` | Passed (0.032s) |
| `ProgressStoreTests/testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges()` | Passed (0.030s) |
| `ProgressStoreTests/testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults()` | Passed (0.036s) |
| `ProgressStoreTests/testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference()` | Passed (0.008s) |
| `ProgressStoreTests/testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault()` | Passed (0.011s) |
| `ProgressStoreTests/testLaunchIgnoresRegisteredAppleLanguagesValue()` | Passed (0.009s) |
| `ProgressStoreTests/testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue()` | Passed (0.009s) |
| `ProgressStoreTests/testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries()` | Passed (0.010s) |
| `ProgressStoreTests/testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun()` | Passed (0.013s) |
| `ProgressStoreTests/testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting()` | Passed (0.009s) |
| `ProgressStoreTests/testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce()` | Passed (0.007s) |
| `ProgressStoreTests/testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure()` | Passed (0.029s) |
| `ProgressStoreTests/testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead()` | Passed (0.041s) |
| `ProgressStoreTests/testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution()` | Passed (0.048s) |
| `ProgressStoreTests/testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution()` | Passed (0.032s) |
| `ProgressStoreTests/testMigratesArchivedLessonProgressKeepsMaxOwnReadCount()` | Passed (0.010s) |
| `ProgressStoreTests/testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist()` | Passed (0.031s) |
| `ProgressStoreTests/testMigratesCommittedPreV2StoreFixtureWithAllDataIntact()` | Passed (0.298s) |
| `ProgressStoreTests/testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity()` | Passed (0.020s) |
| `ProgressStoreTests/testMigratesProgressStoreV1ToV2WithoutUniqueConstraints()` | Passed (0.068s) |
| `ProgressStoreTests/testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields()` | Passed (0.075s) |
| `ProgressStoreTests/testMockExamTimerRefreshPreservesFractionalRemainder()` | Passed (0.001s) |
| `ProgressStoreTests/testMorseCourseProgressRoundTripsTwentyRecentCharacterResults()` | Passed (0.034s) |
| `ProgressStoreTests/testMorseExportMapsHapticsToWebCompatibleAudio()` | Passed (0.001s) |
| `ProgressStoreTests/testMorseImportDecodesMissingAndPartialMorsePreferences()` | Passed (0.049s) |
| `ProgressStoreTests/testMorseImportRejectsExplicitNullMorseValues()` | Passed (0.001s) |
| `ProgressStoreTests/testMorseImportRejectsUnsupportedMorsePreferenceEnums()` | Passed (0.034s) |
| `ProgressStoreTests/testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference()` | Passed (0.010s) |
| `ProgressStoreTests/testNativeSettingsGeneralBindingsUpdatePracticePreferences()` | Passed (0.010s) |
| `ProgressStoreTests/testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows()` | Passed (0.037s) |
| `ProgressStoreTests/testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt()` | Passed (0.012s) |
| `ProgressStoreTests/testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences()` | Passed (0.036s) |
| `ProgressStoreTests/testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse()` | Passed (0.035s) |
| `ProgressStoreTests/testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints()` | Passed (0.038s) |
| `ProgressStoreTests/testProgressStoreRoundTripExportImportReset()` | Passed (0.055s) |
| `ProgressStoreTests/testResetAllDataTurnsICloudSyncOptInOff()` | Passed (0.010s) |
| `ProgressStoreTests/testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData()` | Passed (0.126s) |
| `ProgressStoreTests/testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure()` | Passed (0.047s) |
| `ProgressStoreTests/testResetClearsAppleLanguagesAndLanguagePreference()` | Passed (0.012s) |
| `ProgressStoreTests/testResetFailureKeepsPreviousAppleLanguagesAndPreference()` | Passed (0.014s) |
| `ProgressStoreTests/testResetRollsBackWhenMorseProgressRemovalFails()` | Passed (0.015s) |
| `ProgressStoreTests/testSavingLargeQuestionProgressBatchBuildsOneWriteContext()` | Passed (1.787s) |
| `ProgressStoreTests/testSharedAppleSettingsModelAppliesLivePreferenceUpdates()` | Passed (0.112s) |
| `ProgressStoreTests/testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules()` | Passed (0.001s) |
| `ProgressStoreTests/testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries()` | Passed (0.041s) |
| `ProgressStoreTests/testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress()` | Passed (0.089s) |
| `ProgressStoreTests/testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists()` | Passed (0.060s) |
| `ProgressStoreTests/testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite()` | Passed (0.030s) |
| `ProgressStoreTests/testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration()` | Passed (0.009s) |
| `ProgressStoreTests/testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync()` | Passed (0.054s) |
| `QuestionBankTests/testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames()` | Passed (0.013s) |
| `QuestionBankTests/testAdvancedMockExamUsesFiftyQuestionsAndNoHonours()` | Passed (0.014s) |
| `QuestionBankTests/testAppBundleContainsNoReadmeFiles()` | Passed (0.013s) |
| `QuestionBankTests/testAppBundleContainsOnlyExpectedGeneratedBankDirectories()` | Passed (0.001s) |
| `QuestionBankTests/testBundledJSONDecodesExpectedCounts()` | Passed (0.019s) |
| `QuestionBankTests/testBundledLessonModelExposesPrerequisites()` | Passed (0.564s) |
| `QuestionBankTests/testBundledLessonsAndExplanationsLoadThroughContentLibrary()` | Passed (0.711s) |
| `QuestionBankTests/testEngineQuestionDrawKeepsQuestionInsideRequestedCategory()` | Passed (0.019s) |
| `QuestionBankTests/testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion()` | Passed (0.081s) |
| `QuestionBankTests/testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes()` | Passed (0.001s) |
| `QuestionBankTests/testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons()` | Passed (0.568s) |
| `ReadinessAndScoringTests/testAdvancedScoringAndReadinessSuppressHonours()` | Passed (0.001s) |
| `ReadinessAndScoringTests/testExamScoringBoundaries()` | Passed (0.001s) |
| `ReadinessAndScoringTests/testReadinessStates()` | Passed (0.001s) |
| `ReadinessAndScoringTests/testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate()` | Passed (0.034s) |

</details>

### Commands and scope

- `/tmp/task-58/reproduce.sh`: baseline `xbuild` selecting only `CanadianHamUITests/CanadianHamExamToolsUITests/testForcedRegularIPhoneLandscapeMediumSheetScrollsEveryCalculatorKey` on `platform=iOS Simulator,name=iPhone 17 Pro Max,OS=27.0` (expected failure).
- `/tmp/task-58/fixed-reachability.sh`: the same targeted `xbuild` after the helper fix (passed).
- `/tmp/task-58/verify.sh`: `xbuild` with `-only-testing:` for the UI methods in the table above on the stated destinations; Pro Max excludes the already-validated reachability method, Pro includes all 16, Duo selects only the reachability method. `CODE_SIGNING_ALLOWED=NO` for simulator runs.
- macOS command: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination "platform=macOS,arch=arm64" -skip-testing:CanadianHamUITests -resultBundlePath /tmp/task-58/macos-unit.xcresult test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES`.
- `node scripts/check-test-guard.mjs --self-test` — passed.
- `node scripts/check-test-guard.mjs --base main --head HEAD` — passed, no guarded changes.
- `git diff --check` — passed.
- Full iOS suites were not run: targeted landscape/calculator tests exercise this test-only fix. Screenshot-export test was not selected (requires opt-in evidence directory). macOS UI tests were excluded as documented. tvOS/visionOS suites and web/content checks were not run because no product code, packages, content, strings, or those platform targets changed.

No known code risks. CI and Copilot review remain the normal pre-merge gates.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed a test-local XCTest snapshot bug: avoid reading the identifier of a not-yet-instantiated offscreen calculator key before scrolling it into view. Product layout was already correct, so no layout workaround was added. All existing reachability/44 pt assertions and guarded shared helpers remain unchanged. Reproduced the baseline Pro Max failure, then validated Pro Max 16/16, Pro 16/16, Duo OS 27.1 landscape 1/1, macOS units 177/177, test-guard self-test/check, and diff hygiene. Internal review approved the source commit; CI/Copilot are the normal remaining PR merge gates.
<!-- SECTION:FINAL_SUMMARY:END -->
