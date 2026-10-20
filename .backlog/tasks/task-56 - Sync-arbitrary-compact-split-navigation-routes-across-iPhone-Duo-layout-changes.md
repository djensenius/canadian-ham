---
id: TASK-56
title: >-
  Sync arbitrary compact/split navigation routes across iPhone Duo layout
  changes
status: Done
assignee:
  - '@worker'
created_date: '2026-10-18 03:22'
updated_date: '2026-10-20 02:02'
labels:
  - apple
dependencies:
  - TASK-15
priority: high
ordinal: 135000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
PR #286 preserves practice and mock exam session state across simulated Duo fold/unfold and syncs the root selection for routes controlled by RootView. Arbitrary NavigationStack pushes created inside compact Learn still cannot be introspected from SwiftUI NavigationPath, so folding or unfolding from a deep Learn route can still lose the exact lesson/quiz stack.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Starting from a compact Learn lesson or quiz route and unfolding to split keeps the same lesson or quiz visible
- [x] #2 Starting from a split Learn lesson or quiz route and folding to compact keeps the same lesson or quiz visible
- [x] #3 UI or unit coverage exercises at least one compact-to-split and one split-to-compact deep Learn route without weakening existing navigation tests
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Keep the typed compact/split navigation mapping and exhaustive route unit tests.
2. Preserve arbitrary Learn stacks in both directions with explicit sidebar-only stack resets.
3. Add strict DEBUG size-class transition UI tests for Learn lessons and quizzes in both directions; leave all pre-existing tests and shared/exception helpers byte-identical.
4. Per coordinator decision 2026-10-19, revert selected-tool restoration and native-host gating, retaining stable dismiss/reopen/value behavior; track open-tool continuity as low-priority TASK-63 dependent on TASK-54 real-device results.
5. Validate navigation on iPhone 17 Pro, iPad Pro 13-inch (M5), iPhone Duo (27.1), and macOS units, then record evidence and open the PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Also keep the open exam tool (calculator/hint) presented across size-class transitions; currently it dismisses and must be reopened (value is preserved).

Implementation: compact navigation now uses a typed route array shared with Learn NavigationLinks, with a pure RootNavigationMapping compact/split conversion that preserves module/lesson/section/quiz stacks and practice/mock destinations. Selected calculator/hint is retained in the root-owned session models. Added six mapping/session-state unit tests and eight strict UI tests (both directions for lesson, quiz, calculator and hint). Existing ExamTools tests and shared/exception helpers are byte-identical, verified by reconstructing the pre-insertion source. XcodeGen output was deterministic over two runs. Targeted xbuild validation is queued in /tmp/task-56-initial.sh and /tmp/task-56-macos.sh; waiting on the shared build lock without interruption. No app strings changed.

Validation iteration: initial iPhone build exposed two remaining DEBUG category/subsection references to the removed compact enum; fixed. Retry compiled and all six RootNavigationMappingTests passed. The first strict calculator compact-to-split UI test then reproduced a real native inspector/AttributeGraph render loop (app 100% CPU, sample /tmp/task-56-hang.sample). Interrupted only this task-owned xbuild child after confirming its parent script/PID; no other builds interrupted. Added a presentation-host lifecycle gate so a retained tool is presented after the new native host attaches, and disappearing hosts cannot clear its selected state. Strict test assertions are unchanged. Targeted two-direction calculator retry is queued in /tmp/task-56-tool-retry.sh; macOS units and remaining platforms are queued. pnpm typecheck and pnpm test passed (144 content, 21 Morse, 127 calculator, 209 web tests). Test guard self-test and merge-base diff check passed without an approval marker; no guarded changes.

Coordinator decision 2026-10-19: open-tool persistence was an add-on note, not AC1–AC3, and is explicitly descoped from TASK-56 after both immediate restoration and host-readiness gating reproduced a native inspector render loop. Reverted all ExamToolViews/StudyViews changes to the stable main baseline; tools dismiss across root switches but calculator values and hint levels remain preserved for reopening. Removed only the newly added out-of-scope tool-continuation tests; every pre-existing test and helper is unchanged. Created low-priority TASK-63, dependent on TASK-54 real-device results, recording the render-loop evidence and the two unapproved alternatives (two-phase native handoff vs lifting the presenter above RootView). TASK-56 continues with pure navigation mapping, five mapping units, and four strict lesson/quiz transition UI tests.

Final validation on navigation-only scope at ee290d86 (all accepted source changes): iPhone 17 Pro 6/6 targeted UI tests; iPad Pro 13-inch (M5) 7/7 targeted UI tests; iPhone Duo OS=27.1 6/6 targeted UI tests; macOS 182/182 units, including all five mapping tests. Each UI platform passed both strict lesson/quiz directions and both unchanged practice/calculator transitions; iPad additionally passed the unchanged inspector/sidebar regression. All xbuild commands ran via nohup scripts, with grep-only log polling and normal shared-lock waits. The xbuild wrapper emitted a simctl cleanup lookup warning after successful test actions; test commands exited 0 and all per-test results are recorded below.

AC1 evidence: testCompactToSplitKeepsDeepLearnLesson and testCompactToSplitKeepsDeepLearnQuiz pass on all three requested iOS destinations using real Learn module/lesson/quiz pushes and the DEBUG size-class control, asserting the same visible heading. AC2 evidence: the corresponding SplitToCompact tests pass on all three destinations. AC3 evidence: five exhaustive mapping units pass, all four strict UI directions pass, and reconstructing the pre-insertion UI source proves every pre-existing transition test and shared/exception helper is byte-identical to main baseline 79b47a9e.

Other checks: pnpm typecheck passed; pnpm test passed (144 content tests, 21 Morse, 127 calculator, 209 web); Apple text-source gate passed; test-guard self-test and merge-base diff passed with no guarded findings/approval marker; XcodeGen was run twice again and generated project diff was empty; git diff --check passed. Tool presentation sources and the string catalogue are byte-identical to the stable baseline. No new strings, colours, accessibility hiding or scaling workarounds. No full iOS app suites or figure audits (navigation values only; figure/reader rendering unchanged); full app suites wait for the merge batch. tvOS/visionOS skipped because none of their compiled source/linked package membership changed. Real Duo fold/unfold remains TASK-54; open-tool continuation is explicitly deferred to TASK-63, per coordinator decision.

Per-test Apple results:

### iPhone 17 Pro: 6/6 passed
Log: `/tmp/task-56-nav-final-iphone.log`

- PASSED: `CanadianHamExamToolsUITests.testCompactToSplitKeepsDeepLearnLesson` (53.427 seconds)
- PASSED: `CanadianHamExamToolsUITests.testCompactToSplitKeepsDeepLearnQuiz` (96.437 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` (69.224 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` (69.788 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSplitToCompactKeepsDeepLearnLesson` (28.984 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSplitToCompactKeepsDeepLearnQuiz` (90.027 seconds)

### iPad Pro 13-inch (M5): 7/7 passed
Log: `/tmp/task-56-nav-final-ipad.log`

- PASSED: `CanadianHamExamToolsUITests.testCompactToSplitKeepsDeepLearnLesson` (24.512 seconds)
- PASSED: `CanadianHamExamToolsUITests.testCompactToSplitKeepsDeepLearnQuiz` (43.681 seconds)
- PASSED: `CanadianHamExamToolsUITests.testRegularWidthUsesInspectorAndKeepsAnswersHittable` (333.189 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` (34.320 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` (40.469 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSplitToCompactKeepsDeepLearnLesson` (19.434 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSplitToCompactKeepsDeepLearnQuiz` (38.722 seconds)

### iPhone Duo (OS=27.1): 6/6 passed
Log: `/tmp/task-56-nav-final-duo.log`

- PASSED: `CanadianHamExamToolsUITests.testCompactToSplitKeepsDeepLearnLesson` (29.788 seconds)
- PASSED: `CanadianHamExamToolsUITests.testCompactToSplitKeepsDeepLearnQuiz` (56.179 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` (35.184 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` (35.513 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSplitToCompactKeepsDeepLearnLesson` (26.917 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSplitToCompactKeepsDeepLearnQuiz` (55.503 seconds)

### macOS unit tests: 182/182 passed
Log: `/tmp/task-56-macos.log`

- PASSED: `DuoLayoutPolicyTests.testCompactWidthIPhoneKeepsSheetPolicy` (0.001 seconds)
- PASSED: `DuoLayoutPolicyTests.testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact` (0.001 seconds)
- PASSED: `DuoLayoutPolicyTests.testIPadInspectorRuleRemainsSizeClassDriven` (0.001 seconds)
- PASSED: `DuoLayoutPolicyTests.testMacAndOtherIdiomsNeverUseIPhonePolicy` (0.001 seconds)
- PASSED: `DuoLayoutPolicyTests.testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy` (0.001 seconds)
- PASSED: `DuoLayoutPolicyTests.testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testKeyHandlingProducesEngineDisplayAndSpokenResult` (0.000 seconds)
- PASSED: `ExamCalculatorViewModelTests.testQuestionCardFocusResetKeepsTextSelectionEnabled` (0.005 seconds)
- PASSED: `ExamCalculatorViewModelTests.testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately` (0.001 seconds)
- PASSED: `HintSessionStateTests.testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekEndsWhenPhoneFullyOpensOrCloses` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekFastUnfoldThroughBandNeverPeeks` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekLeavingToleranceDoesNotResetDismissalSuppression` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` (0.397 seconds)
- PASSED: `HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute` (0.293 seconds)
- PASSED: `HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` (0.002 seconds)
- PASSED: `HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` (0.002 seconds)
- PASSED: `HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp` (0.002 seconds)
- PASSED: `HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` (0.002 seconds)
- PASSED: `HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` (2.676 seconds)
- PASSED: `LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations` (0.020 seconds)
- PASSED: `LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` (0.004 seconds)
- PASSED: `LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides` (0.001 seconds)
- PASSED: `LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish` (0.001 seconds)
- PASSED: `LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale` (0.003 seconds)
- PASSED: `MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer` (0.001 seconds)
- PASSED: `MorseTrainerTests.testFixedTimingProfilesUseEngineValues` (0.001 seconds)
- PASSED: `MorseTrainerTests.testLessonBodyAndBulletContrastTokensMeetMinimumRatio` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` (0.002 seconds)
- PASSED: `MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints` (0.002 seconds)
- PASSED: `MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline` (0.000 seconds)
- PASSED: `MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSettingsClampAndPreset` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` (0.005 seconds)
- PASSED: `MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults` (0.004 seconds)
- PASSED: `MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` (0.001 seconds)
- PASSED: `MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags` (0.001 seconds)
- PASSED: `MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon` (0.001 seconds)
- PASSED: `MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback` (0.001 seconds)
- PASSED: `ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` (0.077 seconds)
- PASSED: `ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts` (0.023 seconds)
- PASSED: `ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` (0.004 seconds)
- PASSED: `ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync` (0.001 seconds)
- PASSED: `ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` (0.000 seconds)
- PASSED: `ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` (0.000 seconds)
- PASSED: `ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` (0.029 seconds)
- PASSED: `ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields` (0.028 seconds)
- PASSED: `ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` (0.028 seconds)
- PASSED: `ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` (0.020 seconds)
- PASSED: `ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` (0.057 seconds)
- PASSED: `ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem` (0.010 seconds)
- PASSED: `ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory` (0.064 seconds)
- PASSED: `ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` (0.027 seconds)
- PASSED: `ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete` (0.023 seconds)
- PASSED: `ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` (0.150 seconds)
- PASSED: `ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent` (0.002 seconds)
- PASSED: `ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` (0.001 seconds)
- PASSED: `ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` (0.049 seconds)
- PASSED: `ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` (0.031 seconds)
- PASSED: `ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` (0.034 seconds)
- PASSED: `ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` (0.044 seconds)
- PASSED: `ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` (0.060 seconds)
- PASSED: `ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` (0.031 seconds)
- PASSED: `ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress` (0.032 seconds)
- PASSED: `ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows` (0.038 seconds)
- PASSED: `ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues` (0.036 seconds)
- PASSED: `ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` (0.071 seconds)
- PASSED: `ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails` (0.044 seconds)
- PASSED: `ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure` (0.032 seconds)
- PASSED: `ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` (0.032 seconds)
- PASSED: `ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` (0.034 seconds)
- PASSED: `ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` (0.001 seconds)
- PASSED: `ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` (0.029 seconds)
- PASSED: `ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates` (0.035 seconds)
- PASSED: `ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress` (0.035 seconds)
- PASSED: `ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId` (0.036 seconds)
- PASSED: `ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` (0.032 seconds)
- PASSED: `ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` (0.031 seconds)
- PASSED: `ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` (0.035 seconds)
- PASSED: `ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` (0.009 seconds)
- PASSED: `ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` (0.012 seconds)
- PASSED: `ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue` (0.008 seconds)
- PASSED: `ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` (0.008 seconds)
- PASSED: `ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` (0.011 seconds)
- PASSED: `ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` (0.011 seconds)
- PASSED: `ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` (0.008 seconds)
- PASSED: `ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` (0.008 seconds)
- PASSED: `ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` (0.031 seconds)
- PASSED: `ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` (0.044 seconds)
- PASSED: `ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` (0.047 seconds)
- PASSED: `ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` (0.033 seconds)
- PASSED: `ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` (0.010 seconds)
- PASSED: `ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` (0.031 seconds)
- PASSED: `ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` (0.437 seconds)
- PASSED: `ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` (0.016 seconds)
- PASSED: `ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` (0.074 seconds)
- PASSED: `ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` (0.068 seconds)
- PASSED: `ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder` (0.001 seconds)
- PASSED: `ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` (0.028 seconds)
- PASSED: `ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio` (0.001 seconds)
- PASSED: `ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences` (0.050 seconds)
- PASSED: `ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues` (0.001 seconds)
- PASSED: `ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums` (0.037 seconds)
- PASSED: `ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference` (0.012 seconds)
- PASSED: `ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences` (0.011 seconds)
- PASSED: `ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` (0.039 seconds)
- PASSED: `ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` (0.011 seconds)
- PASSED: `ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` (0.038 seconds)
- PASSED: `ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` (0.037 seconds)
- PASSED: `ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` (0.038 seconds)
- PASSED: `ProgressStoreTests.testProgressStoreRoundTripExportImportReset` (0.058 seconds)
- PASSED: `ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff` (0.011 seconds)
- PASSED: `ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` (0.127 seconds)
- PASSED: `ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` (0.147 seconds)
- PASSED: `ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference` (0.014 seconds)
- PASSED: `ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference` (0.014 seconds)
- PASSED: `ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails` (0.014 seconds)
- PASSED: `ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext` (1.817 seconds)
- PASSED: `ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates` (0.113 seconds)
- PASSED: `ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` (0.001 seconds)
- PASSED: `ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` (0.015 seconds)
- PASSED: `ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` (0.093 seconds)
- PASSED: `ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` (0.068 seconds)
- PASSED: `ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` (0.031 seconds)
- PASSED: `ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` (0.009 seconds)
- PASSED: `ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` (0.054 seconds)
- PASSED: `QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` (0.013 seconds)
- PASSED: `QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` (0.013 seconds)
- PASSED: `QuestionBankTests.testAppBundleContainsNoReadmeFiles` (0.013 seconds)
- PASSED: `QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories` (0.001 seconds)
- PASSED: `QuestionBankTests.testBundledJSONDecodesExpectedCounts` (0.022 seconds)
- PASSED: `QuestionBankTests.testBundledLessonModelExposesPrerequisites` (0.559 seconds)
- PASSED: `QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary` (0.705 seconds)
- PASSED: `QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` (0.019 seconds)
- PASSED: `QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` (0.080 seconds)
- PASSED: `QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` (0.001 seconds)
- PASSED: `QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` (0.559 seconds)
- PASSED: `ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours` (0.001 seconds)
- PASSED: `ReadinessAndScoringTests.testExamScoringBoundaries` (0.001 seconds)
- PASSED: `ReadinessAndScoringTests.testReadinessStates` (0.001 seconds)
- PASSED: `ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` (0.035 seconds)
- PASSED: `RootNavigationMappingTests.testCompactHomeSessionAndSectionPushesUseVisibleDestination` (0.001 seconds)
- PASSED: `RootNavigationMappingTests.testEmptyCompactPathMapsToHome` (0.000 seconds)
- PASSED: `RootNavigationMappingTests.testEveryLearnRouteRoundTripsWithItsWholeStack` (0.001 seconds)
- PASSED: `RootNavigationMappingTests.testEveryRootSelectionRoundTrips` (0.000 seconds)
- PASSED: `RootNavigationMappingTests.testPracticeHintLessonStackKeepsSessionAsSplitSelection` (0.001 seconds)
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented typed RootNavigationRoute paths and pure compact/split mapping, preserving complete module/lesson/section/quiz stacks and practice/mock roots in both directions. Sidebar-only resets no longer erase restored routes. Four strict deep Learn UI tests and five mapping units added; every pre-existing test/helper unchanged. Validation: iPhone 17 Pro 6/6, iPad M5 7/7, Duo 27.1 6/6, macOS 182/182; static/web checks green. Open-tool restoration was explicitly descoped after native inspector render loops; stable tool/value behavior restored byte-for-byte, with low-priority TASK-63 dependent on TASK-54. Independent PR review, Copilot and CI remain merge gates.
<!-- SECTION:FINAL_SUMMARY:END -->
