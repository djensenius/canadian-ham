# TASK-33: iPhone 17 Pro runtime evidence

All test output below was extracted with narrow `grep` patterns, not by reading full
Xcode logs or result bundles. No tests or audit implementations were disabled or
weakened. Plans preserve the coverage mapped in the [inventory](task-33-ui-audit-inventory.md).

## Outcome and timing summary

Acceptance wording approved by the supervisor: **full suite passed except unchanged
tests that passed targeted reruns**. Both full runs returned exit code 65; the failures
remain visible below and are not represented as clean full-run passes. Every isolated
rerun returned exit code 0 without changing its assertions or audit helpers.

| Run | Unit tests | UI methods | UI outcome | UI suite elapsed wall (s) | Outer xbuild wall (s) |
| --- | --- | --- | --- | --- | --- |
| Historical full baseline, including figures | 142 passed | 138 | 134 passed, 3 existing skips, 1 failure | 18233.683 | Not separately captured |
| Required after-default full run (superset of final default) | 190 passed | 126 | 121 passed, 3 existing skips, 2 failures | 11390.378 | 11533 |
| Required figure-plan full run | Not selected | 47 | 46 passed, 1 failure | 11444.382 | 11520 |

| Unchanged failure | Full-run evidence | Isolated passing evidence | Passing seconds | Rerun outer wall (s) |
| --- | --- | --- | --- | --- |
| `testAccessibilityAuditMorseSendingResultsLight`: 5-second heading wait after Grade, 78.654s | `/tmp/task-33-after.log` | `/tmp/task-33-sending-results-rerun.log` | 91.923 | 208 |
| `testOhmsLawLessonFiguresAndAccessibilityDark`: XCTest audit timeout Code=-56, 471.508s | `/tmp/task-33-after.log` | `/tmp/task-33-ohms-dark-rerun.log` | 1217.286 | 1253 |
| `testModule7LessonFigureDarkSample`: XCTest audit timeout Code=-56, 230.276s | `/tmp/task-33-figures.log` | `/tmp/task-33-m7-dark-rerun.log` | 257.999 | 402 |

The figure full run also passed both moved Ohm's-law methods (dark 1316.588s,
light 1321.591s). Low-priority **TASK-65** tracks all three residual flakes; this task
does not claim their underlying causes were fixed. The coordinator ran the final M7
isolated rerun after the original worker timed out and its queued script was killed.
No additional test runs were started during finalization.

## Method and limits

- The supervisor approved the historical full baseline at
  `029f2d4992f52df72fae258daf892a465cb53841` (`train-2026-10-17`,
  `/tmp/train1017-ios.log`) rather than another five-hour baseline. It predates the
  task branch point `e7a1dfa7978454d43dc4a0bde24046b2dd02bf7f` by more than two days
  and includes the figure tests. Its largest-text Enlarge failure remains in the
  table below, not treated as a pass.
- Current non-matrix UI membership was 128 methods before consolidation and 126
  after launch sharing. Moving the two pure-figure Ohm's-law integration methods
  makes final default membership **124**; the required 126-method full run is a
  superset of final default membership. Historical membership was 138 UI methods
  including 31 figure-class methods (107 other). No second default full run was needed.
- The figure class is now 45 methods (32 at current source baseline); its plan also
  includes the two unchanged Ohm's-law integration methods, for **47** total. All 47
  original light/dark matrix figure audit visits are preserved, alongside every
  integration assertion/audit. Unit tests grew from 142 historical to 190 current.
- Two completed current pre-consolidation medium-detent audits calibrate runtime:
  dark/light 322.972/311.446 seconds versus historical 281.381/286.590, combined
  11.7% slower. Only this task's own baseline xcodebuild process was interrupted,
  with supervisor approval. Its 848-second interrupted outer wall is not a full-suite timing.
- Suite summaries report elapsed wall clocks (the parenthesized `Executed` timing).
  Outer xbuild walls include build/install/cleanup and any lock wait. The historical
  full baseline has no separately captured outer wall clock.
- Historical-versus-current wall differences are **not a controlled speedup benchmark**:
  membership, content, and host conditions differ. Source-level launch reduction is
  exactly 22 to 8 for the changed flows (14 fewer). Historical changed-flow test
  durations totaled 390.689s versus 341.197s now, an observation with the same caveat.

### Machine load and shared build lock

At `2026-10-20T10:39:35Z`, near the M7 failure, `uptime` reported load averages
**81.94 / 81.56 / 88.02**. A process sample showed simulator `testmanagerd` 99.9% CPU,
two `lockf` processes 84.9% / 84.1%, host `diagnosticd` 55.8%, and simulator
`diagnosticd` 50.2%. Exactly one active xcodebuild was observed (this figure run).
The coordinator confirmed **FluxTerm builds shared the xbuild lock**. No other lane's
processes were stopped. These observations document contention/load, not proof that
load caused any particular failure.

## Run commands

The full runs used nohup-managed scripts and one simulator destination, serialized
by xbuild. The after-default and figure runs were each executed in full once without
method filters:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -testPlan CanadianHamDefault -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -resultBundlePath /tmp/task-33-after.xcresult test CODE_SIGNING_ALLOWED=NO
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -testPlan CanadianHamLessonFigures -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -resultBundlePath /tmp/task-33-figures.xcresult test CODE_SIGNING_ALLOWED=NO
```

Only the failed unchanged methods were rerun:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -testPlan CanadianHamDefault -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseSendingResultsLight -resultBundlePath /tmp/task-33-sending-results-rerun.xcresult test CODE_SIGNING_ALLOWED=NO
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -testPlan CanadianHamLessonFigures -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testOhmsLawLessonFiguresAndAccessibilityDark -resultBundlePath /tmp/task-33-ohms-dark-rerun.xcresult test CODE_SIGNING_ALLOWED=NO
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -testPlan CanadianHamLessonFigures -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamLessonFiguresUITests/testModule7LessonFigureDarkSample -resultBundlePath /tmp/task-33-m7-dark-rerun.xcresult test CODE_SIGNING_ALLOWED=NO
```

macOS, tvOS, and visionOS suites were not run: this diff changes only iOS UI tests
and CanadianHam test-plan routing; app/package/unit/non-iOS test sources are untouched.
Source/plan identity, test-guard, and XcodeGen determinism checks were run separately.
The eventual PR must retain the qualified acceptance wording and both failure/rerun
log paths above, plus the standalone `Test-guard-approved: task-33` marker justified
by the four assertion-preserving wrapper replacements in the inventory.

## Historical full baseline

Log: `/tmp/train1017-ios.log`.

Target/class suite summaries (including existing skips):

```text
Executed 142 tests, with 0 failures (0 unexpected) in 7.602 (7.657) seconds
Executed 142 tests, with 0 failures (0 unexpected) in 7.602 (7.658) seconds
Executed 18 tests, with 3 tests skipped and 0 failures (0 unexpected) in 1624.356 (1624.373) seconds
Executed 31 tests, with 0 failures (0 unexpected) in 7807.490 (7807.608) seconds
Executed 89 tests, with 1 failure (0 unexpected) in 8801.650 (8801.698) seconds
Executed 138 tests, with 3 tests skipped and 1 failure (0 unexpected) in 18233.496 (18233.683) seconds
Executed 138 tests, with 3 tests skipped and 1 failure (0 unexpected) in 18233.496 (18233.683) seconds
```

- `CanadianHamTests.ExamCalculatorViewModelTests`: 10 passed.
- `CanadianHamTests.LocalizationCatalogTests`: 5 passed.
- `CanadianHamTests.MorseTrainerTests`: 27 passed.
- `CanadianHamTests.ProgressStoreTests`: 85 passed.
- `CanadianHamTests.QuestionBankTests`: 11 passed.
- `CanadianHamTests.ReadinessAndScoringTests`: 4 passed.
- `CanadianHamUITests.CanadianHamExamToolsUITests`: 15 passed, 3 skipped.
- `CanadianHamUITests.CanadianHamLessonFiguresUITests`: 31 passed.
- `CanadianHamUITests.CanadianHamPracticeUITests`: 1 failed, 88 passed.

| Class | Test | Result | Seconds |
| --- | --- | --- | --- |
| `ExamCalculatorViewModelTests` | `testCalculatorToolLayoutDoesNotScrollAtOrAboveHelpThresholdForNonAccessibilitySizes` | passed | 0.002 |
| `ExamCalculatorViewModelTests` | `testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testCalculatorToolLayoutScrollsWhenCompactHeightCannotKeepMinimumKeys` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testKeyHandlingProducesEngineDisplayAndSpokenResult` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testQuestionCardFocusResetKeepsTextSelectionEnabled` | passed | 0.004 |
| `ExamCalculatorViewModelTests` | `testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately` | passed | 0.001 |
| `LocalizationCatalogTests` | `testEveryCatalogKeyHasFrenchTranslations` | passed | 0.007 |
| `LocalizationCatalogTests` | `testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` | passed | 0.010 |
| `LocalizationCatalogTests` | `testLanguagePreferenceResolvesSystemAndOverrides` | passed | 0.002 |
| `LocalizationCatalogTests` | `testLocalizedNullableTextAndLanguageFallsBackToEnglish` | passed | 0.002 |
| `LocalizationCatalogTests` | `testQuestionBankLoadErrorDescriptionUsesFrenchLocale` | passed | 0.005 |
| `MorseTrainerTests` | `testCompletedMorseCourseSessionIgnoresResubmittedAnswer` | passed | 0.001 |
| `MorseTrainerTests` | `testFixedTimingProfilesUseEngineValues` | passed | 0.001 |
| `MorseTrainerTests` | `testLessonBodyAndBulletContrastTokensMeetMinimumRatio` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseAudioSessionStaysActiveUntilLastPlayerReleases` | passed | 0.000 |
| `MorseTrainerTests` | `testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` | passed | 0.002 |
| `MorseTrainerTests` | `testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` | passed | 0.003 |
| `MorseTrainerTests` | `testMorseExamGeneratorMeetsReceivingExamConstraints` | passed | 0.002 |
| `MorseTrainerTests` | `testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` | passed | 0.001 |
| `MorseTrainerTests` | `testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseSendingClassifiesTimingAndErrorSignal` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseSendingPendingFinalizationHelperCancelsAndClears` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseSendingRemainingExamSecondsUsesFixedDeadline` | passed | 0.000 |
| `MorseTrainerTests` | `testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseSettingsClampAndPreset` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseSettingsCodableRoundTripPreservesOutputMode` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseSettingsDecodesLegacyPayloadWithIsEnabled` | passed | 0.000 |
| `MorseTrainerTests` | `testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` | passed | 0.005 |
| `MorseTrainerTests` | `testMorseSettingsRoundTripThroughUserDefaults` | passed | 0.012 |
| `MorseTrainerTests` | `testMorseStopDelayDrainsFadeBeforeStoppingEngine` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` | passed | 0.004 |
| `MorseTrainerTests` | `testReduceFlashingDecisionUsesInjectedFlags` | passed | 0.000 |
| `MorseTrainerTests` | `testReduceFlashingStopsOnlyRunningVisualBeacon` | passed | 0.001 |
| `MorseTrainerTests` | `testScheduleMorseVisualPlaybackInitialStateAndFallback` | passed | 0.001 |
| `ProgressStoreTests` | `testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` | passed | 0.163 |
| `ProgressStoreTests` | `testAdvancedImportRejectsHonoursAttempts` | passed | 0.033 |
| `ProgressStoreTests` | `testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` | passed | 0.005 |
| `ProgressStoreTests` | `testAppSettingsModelPublishesMorseSettingsForRootViewSync` | passed | 0.001 |
| `ProgressStoreTests` | `testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` | passed | 0.001 |
| `ProgressStoreTests` | `testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` | passed | 0.001 |
| `ProgressStoreTests` | `testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` | passed | 0.042 |
| `ProgressStoreTests` | `testDecodesLegacyBasicExportWithoutBankIdFields` | passed | 0.037 |
| `ProgressStoreTests` | `testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` | passed | 0.034 |
| `ProgressStoreTests` | `testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` | passed | 0.038 |
| `ProgressStoreTests` | `testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` | passed | 0.061 |
| `ProgressStoreTests` | `testFreshInstallDefaultsLanguageToSystem` | passed | 0.016 |
| `ProgressStoreTests` | `testICloudAccountSignalsUseInitInjectedFactory` | passed | 0.139 |
| `ProgressStoreTests` | `testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` | passed | 0.063 |
| `ProgressStoreTests` | `testICloudDeleteCanDeleteLocalDataAfterZoneDelete` | passed | 0.056 |
| `ProgressStoreTests` | `testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` | passed | 0.092 |
| `ProgressStoreTests` | `testICloudMergeFixtureIsPermutationIndependentAndIdempotent` | passed | 0.010 |
| `ProgressStoreTests` | `testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` | passed | 0.001 |
| `ProgressStoreTests` | `testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` | passed | 0.104 |
| `ProgressStoreTests` | `testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` | passed | 0.046 |
| `ProgressStoreTests` | `testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` | passed | 0.056 |
| `ProgressStoreTests` | `testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` | passed | 0.088 |
| `ProgressStoreTests` | `testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` | passed | 0.124 |
| `ProgressStoreTests` | `testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` | passed | 0.053 |
| `ProgressStoreTests` | `testImportOfOlderExportDoesNotRemoveExistingMorseProgress` | passed | 0.055 |
| `ProgressStoreTests` | `testImportRejectsInvalidSyncDeviceRows` | passed | 0.076 |
| `ProgressStoreTests` | `testImportRejectsUnsupportedLanguagePreferenceValues` | passed | 0.084 |
| `ProgressStoreTests` | `testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` | passed | 0.152 |
| `ProgressStoreTests` | `testImportRollbackKeepsExistingDataWhenReplacementFails` | passed | 0.119 |
| `ProgressStoreTests` | `testImportRollbackPropagatesMorseProgressRemovalFailure` | passed | 0.093 |
| `ProgressStoreTests` | `testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` | passed | 0.064 |
| `ProgressStoreTests` | `testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` | passed | 0.068 |
| `ProgressStoreTests` | `testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` | passed | 0.001 |
| `ProgressStoreTests` | `testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` | passed | 0.063 |
| `ProgressStoreTests` | `testImportValidationRejectsDuplicateMorseDailyActivityDates` | passed | 0.082 |
| `ProgressStoreTests` | `testImportValidationRejectsInvalidMorseCourseProgress` | passed | 0.089 |
| `ProgressStoreTests` | `testImportValidationRejectsMismatchedScoreBankId` | passed | 0.075 |
| `ProgressStoreTests` | `testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` | passed | 0.068 |
| `ProgressStoreTests` | `testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` | passed | 0.051 |
| `ProgressStoreTests` | `testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` | passed | 0.107 |
| `ProgressStoreTests` | `testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` | passed | 0.035 |
| `ProgressStoreTests` | `testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` | passed | 0.052 |
| `ProgressStoreTests` | `testLaunchIgnoresRegisteredAppleLanguagesValue` | passed | 0.029 |
| `ProgressStoreTests` | `testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` | passed | 0.122 |
| `ProgressStoreTests` | `testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` | passed | 0.025 |
| `ProgressStoreTests` | `testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` | passed | 0.025 |
| `ProgressStoreTests` | `testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` | passed | 0.018 |
| `ProgressStoreTests` | `testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` | passed | 0.013 |
| `ProgressStoreTests` | `testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` | passed | 0.032 |
| `ProgressStoreTests` | `testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` | passed | 0.053 |
| `ProgressStoreTests` | `testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` | passed | 0.070 |
| `ProgressStoreTests` | `testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` | passed | 0.041 |
| `ProgressStoreTests` | `testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` | passed | 0.015 |
| `ProgressStoreTests` | `testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` | passed | 0.041 |
| `ProgressStoreTests` | `testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` | passed | 0.116 |
| `ProgressStoreTests` | `testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` | passed | 0.020 |
| `ProgressStoreTests` | `testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` | passed | 0.100 |
| `ProgressStoreTests` | `testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` | passed | 0.125 |
| `ProgressStoreTests` | `testMockExamTimerRefreshPreservesFractionalRemainder` | passed | 0.002 |
| `ProgressStoreTests` | `testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` | passed | 0.039 |
| `ProgressStoreTests` | `testMorseExportMapsHapticsToWebCompatibleAudio` | passed | 0.000 |
| `ProgressStoreTests` | `testMorseImportDecodesMissingAndPartialMorsePreferences` | passed | 0.082 |
| `ProgressStoreTests` | `testMorseImportRejectsExplicitNullMorseValues` | passed | 0.001 |
| `ProgressStoreTests` | `testMorseImportRejectsUnsupportedMorsePreferenceEnums` | passed | 0.044 |
| `ProgressStoreTests` | `testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` | passed | 0.048 |
| `ProgressStoreTests` | `testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` | passed | 0.019 |
| `ProgressStoreTests` | `testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` | passed | 0.057 |
| `ProgressStoreTests` | `testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` | passed | 0.038 |
| `ProgressStoreTests` | `testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` | passed | 0.041 |
| `ProgressStoreTests` | `testProgressStoreRoundTripExportImportReset` | passed | 0.079 |
| `ProgressStoreTests` | `testResetAllDataTurnsICloudSyncOptInOff` | passed | 0.025 |
| `ProgressStoreTests` | `testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` | passed | 0.050 |
| `ProgressStoreTests` | `testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` | passed | 0.078 |
| `ProgressStoreTests` | `testResetClearsAppleLanguagesAndLanguagePreference` | passed | 0.018 |
| `ProgressStoreTests` | `testResetFailureKeepsPreviousAppleLanguagesAndPreference` | passed | 0.026 |
| `ProgressStoreTests` | `testResetRollsBackWhenMorseProgressRemovalFails` | passed | 0.029 |
| `ProgressStoreTests` | `testSavingLargeQuestionProgressBatchBuildsOneWriteContext` | passed | 1.283 |
| `ProgressStoreTests` | `testSharedAppleSettingsModelAppliesLivePreferenceUpdates` | passed | 0.026 |
| `ProgressStoreTests` | `testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` | passed | 0.004 |
| `ProgressStoreTests` | `testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` | passed | 0.037 |
| `ProgressStoreTests` | `testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` | passed | 0.208 |
| `ProgressStoreTests` | `testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` | passed | 0.157 |
| `ProgressStoreTests` | `testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` | passed | 0.036 |
| `ProgressStoreTests` | `testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` | passed | 0.017 |
| `ProgressStoreTests` | `testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` | passed | 0.071 |
| `QuestionBankTests` | `testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` | passed | 0.012 |
| `QuestionBankTests` | `testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` | passed | 0.013 |
| `QuestionBankTests` | `testAppBundleContainsNoReadmeFiles` | passed | 0.015 |
| `QuestionBankTests` | `testAppBundleContainsOnlyExpectedGeneratedBankDirectories` | passed | 0.001 |
| `QuestionBankTests` | `testBundledJSONDecodesExpectedCounts` | passed | 0.018 |
| `QuestionBankTests` | `testBundledLessonModelExposesPrerequisites` | passed | 0.455 |
| `QuestionBankTests` | `testBundledLessonsAndExplanationsLoadThroughContentLibrary` | passed | 0.459 |
| `QuestionBankTests` | `testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` | passed | 0.020 |
| `QuestionBankTests` | `testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` | passed | 0.076 |
| `QuestionBankTests` | `testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` | passed | 0.001 |
| `QuestionBankTests` | `testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` | passed | 0.327 |
| `ReadinessAndScoringTests` | `testAdvancedScoringAndReadinessSuppressHonours` | passed | 0.001 |
| `ReadinessAndScoringTests` | `testExamScoringBoundaries` | passed | 0.001 |
| `ReadinessAndScoringTests` | `testReadinessStates` | passed | 0.100 |
| `ReadinessAndScoringTests` | `testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` | passed | 0.068 |
| `CanadianHamExamToolsUITests` | `testAccessibilityAuditExamToolsDark` | passed | 281.381 |
| `CanadianHamExamToolsUITests` | `testAccessibilityAuditExamToolsLight` | passed | 286.590 |
| `CanadianHamExamToolsUITests` | `testCalculatorAutoFocusesHardwareKeyboardOnOpen` | passed | 16.450 |
| `CanadianHamExamToolsUITests` | `testCalculatorKeyboardInputIsFocusScoped` | passed | 109.925 |
| `CanadianHamExamToolsUITests` | `testCalculatorValueResetsForNewMockExam` | passed | 61.198 |
| `CanadianHamExamToolsUITests` | `testCalculatorValueSurvivesCloseAndReopenAndResetsForNewSession` | passed | 93.054 |
| `CanadianHamExamToolsUITests` | `testCaptureCalculatorEvidenceScreenshots` | skipped | 1.823 |
| `CanadianHamExamToolsUITests` | `testForcedRegularIPhoneLandscapeCalculatorUsesSheetAndKeepsSelection` | passed | 56.366 |
| `CanadianHamExamToolsUITests` | `testForcedRegularIPhoneLandscapeMediumSheetScrollsEveryCalculatorKey` | passed | 270.425 |
| `CanadianHamExamToolsUITests` | `testLargeDetentCalculatorRunsFullAccessibilityAuditLightAndDark` | passed | 57.358 |
| `CanadianHamExamToolsUITests` | `testLargestDynamicTypeKeepsCalculatorGridReachableLightAndDark` | passed | 67.125 |
| `CanadianHamExamToolsUITests` | `testMockExamCalculatorKeepsAnswersHittableAndTimerRuns` | passed | 82.330 |
| `CanadianHamExamToolsUITests` | `testMockExamQuestionsNavigatorPresentsAfterCalculatorSheet` | passed | 31.504 |
| `CanadianHamExamToolsUITests` | `testPracticeCalculatorSheetKeepsAnswersHittableAtMediumDetent` | passed | 82.754 |
| `CanadianHamExamToolsUITests` | `testPreciseScrollPositionsAnswerAboveToolSheet` | passed | 103.918 |
| `CanadianHamExamToolsUITests` | `testReferenceSheetToolHiddenUntilTask44Dot4` | passed | 18.028 |
| `CanadianHamExamToolsUITests` | `testRegularWidthInspectorAccessibilityAuditLightAndDark` | skipped | 1.911 |
| `CanadianHamExamToolsUITests` | `testRegularWidthUsesInspectorAndKeepsAnswersHittable` | skipped | 2.211 |
| `CanadianHamLessonFiguresUITests` | `testModule1LessonFigureDarkSample` | passed | 155.032 |
| `CanadianHamLessonFiguresUITests` | `testModule1LessonFiguresLightPart1` | passed | 311.226 |
| `CanadianHamLessonFiguresUITests` | `testModule1LessonFiguresLightPart2` | passed | 144.439 |
| `CanadianHamLessonFiguresUITests` | `testModule1LessonFiguresLightPart3` | passed | 153.078 |
| `CanadianHamLessonFiguresUITests` | `testModule1LessonFiguresLightPart4` | passed | 237.819 |
| `CanadianHamLessonFiguresUITests` | `testModule2LessonFigureDarkSample` | passed | 200.745 |
| `CanadianHamLessonFiguresUITests` | `testModule2LessonFiguresLightPart1` | passed | 366.317 |
| `CanadianHamLessonFiguresUITests` | `testModule2LessonFiguresLightPart2` | passed | 249.366 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFigureDarkSample` | passed | 147.121 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFiguresLightPart1` | passed | 256.098 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFiguresLightPart2` | passed | 242.042 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFiguresLightPart3` | passed | 248.540 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFiguresLightPart4` | passed | 314.792 |
| `CanadianHamLessonFiguresUITests` | `testModule4LessonFigureDarkSample` | passed | 197.488 |
| `CanadianHamLessonFiguresUITests` | `testModule4LessonFiguresLightPart1` | passed | 469.749 |
| `CanadianHamLessonFiguresUITests` | `testModule4LessonFiguresLightPart2` | passed | 188.382 |
| `CanadianHamLessonFiguresUITests` | `testModule5LessonFigureDarkSample` | passed | 133.586 |
| `CanadianHamLessonFiguresUITests` | `testModule5LessonFiguresLightPart1` | passed | 136.733 |
| `CanadianHamLessonFiguresUITests` | `testModule5LessonFiguresLightPart2` | passed | 564.982 |
| `CanadianHamLessonFiguresUITests` | `testModule5LessonFiguresLightPart3` | passed | 359.876 |
| `CanadianHamLessonFiguresUITests` | `testModule5LessonFiguresLightPart4` | passed | 248.554 |
| `CanadianHamLessonFiguresUITests` | `testModule6LessonFigureDarkSample` | passed | 160.613 |
| `CanadianHamLessonFiguresUITests` | `testModule6LessonFiguresLightPart1` | passed | 317.078 |
| `CanadianHamLessonFiguresUITests` | `testModule6LessonFiguresLightPart2` | passed | 320.189 |
| `CanadianHamLessonFiguresUITests` | `testModule6LessonFiguresLightPart3` | passed | 187.295 |
| `CanadianHamLessonFiguresUITests` | `testModule7LessonFigureDarkSample` | passed | 231.802 |
| `CanadianHamLessonFiguresUITests` | `testModule7LessonFiguresLightPart1` | passed | 388.614 |
| `CanadianHamLessonFiguresUITests` | `testModule7LessonFiguresLightPart2` | passed | 163.767 |
| `CanadianHamLessonFiguresUITests` | `testModule8LessonFigureDarkSample` | passed | 268.839 |
| `CanadianHamLessonFiguresUITests` | `testModule8LessonFiguresLightPart1` | passed | 258.603 |
| `CanadianHamLessonFiguresUITests` | `testModule8LessonFiguresLightPart2` | passed | 184.724 |
| `CanadianHamPracticeUITests` | `testAboutShowsReleaseAttributionDisclaimerAndBankVersion` | passed | 25.553 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditAdvancedCourseScreensDark` | passed | 94.326 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditAdvancedCourseScreensLight` | passed | 93.248 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditCoreScreensDark` | passed | 104.289 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditCoreScreensLight` | passed | 104.753 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditLearnFlowDark` | passed | 39.473 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditLearnFlowLight` | passed | 39.900 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMockExamFlowDark` | passed | 110.838 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMockExamFlowLight` | passed | 115.980 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseBeaconOutputDark` | passed | 44.101 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseBeaconOutputLight` | passed | 43.681 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseCourseLessonAndSummaryDark` | passed | 417.919 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseCourseLessonAndSummaryLight` | passed | 411.590 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseExamGradedDiffDark` | passed | 118.007 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseExamGradedDiffLight` | passed | 112.810 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseSendingExamScreenDark` | passed | 43.123 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseSendingExamScreenLight` | passed | 37.833 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseSendingMainScreenDark` | passed | 49.481 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseSendingMainScreenLight` | passed | 51.210 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseSendingResultsDark` | passed | 68.040 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseSendingResultsLight` | passed | 72.445 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseTapeOutputDark` | passed | 47.684 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseTapeOutputLight` | passed | 45.150 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditPracticeSessionDark` | passed | 105.449 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditPracticeSessionLight` | passed | 107.533 |
| `CanadianHamPracticeUITests` | `testCanPracticeInFrenchAndSeeFeedback` | passed | 40.030 |
| `CanadianHamPracticeUITests` | `testChoosingSystemDefaultAfterFrenchLaunchSwitchesQuestionsImmediatelyAndShowsRestartNote` | passed | 76.242 |
| `CanadianHamPracticeUITests` | `testCompactHomeStartPracticeAndMockExamBackReturnToHome` | passed | 26.353 |
| `CanadianHamPracticeUITests` | `testCompactMockExamEndExamDiscardsInProgressSession` | passed | 28.919 |
| `CanadianHamPracticeUITests` | `testCompactRootNavigationPreservesMockExamState` | passed | 40.053 |
| `CanadianHamPracticeUITests` | `testCompactRootNavigationPreservesPracticeSessionState` | passed | 40.720 |
| `CanadianHamPracticeUITests` | `testCompactTopLevelListPushesMorseThenLearn` | passed | 21.349 |
| `CanadianHamPracticeUITests` | `testCompletesFirstMorseLessonSessionOnIOS` | passed | 180.298 |
| `CanadianHamPracticeUITests` | `testCoursePickerSwitchesToAdvancedLessonsAndFiftyQuestionMockWithoutHonours` | passed | 47.593 |
| `CanadianHamPracticeUITests` | `testCourseSwitchCancelKeepsImmediatePracticeFeedbackAndConfirmOpensAdvancedPractice` | passed | 92.895 |
| `CanadianHamPracticeUITests` | `testCourseSwitchCancelKeepsUnsubmittedReviewLaterAnswersAndConfirmOpensAdvancedPractice` | passed | 98.132 |
| `CanadianHamPracticeUITests` | `testCourseSwitchConfirmationAuditsDark` | passed | 44.233 |
| `CanadianHamPracticeUITests` | `testCourseSwitchConfirmationKeepsMockExamWhenCancelledLight` | passed | 44.816 |
| `CanadianHamPracticeUITests` | `testDueReviewLaterSessionKeepsPositionTallyAndReviewAfterSubmit` | passed | 53.049 |
| `CanadianHamPracticeUITests` | `testExplanationAppearsAfterAnsweringInPractice` | passed | 27.084 |
| `CanadianHamPracticeUITests` | `testFrenchAboutKeepsLegalTextInEnglish` | passed | 11.220 |
| `CanadianHamPracticeUITests` | `testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice` | passed | 84.572 |
| `CanadianHamPracticeUITests` | `testLanguagePickerIsAbsentOnCategoryListAndPractice` | passed | 20.693 |
| `CanadianHamPracticeUITests` | `testLanguagePickerIsAbsentOnCompactQuestionScreensAndMorse` | passed | 41.878 |
| `CanadianHamPracticeUITests` | `testLanguageRestartNoteHiddenWhenLanguageMatchesInterface` | passed | 8.911 |
| `CanadianHamPracticeUITests` | `testLearnOpensLessonAndShowsFirstHeading` | passed | 7.705 |
| `CanadianHamPracticeUITests` | `testLearnUserNavigationOpensLessonQuiz` | passed | 163.234 |
| `CanadianHamPracticeUITests` | `testLeavingCourseLessonStopsCoursePlaybackBeforeQuickListen` | passed | 92.389 |
| `CanadianHamPracticeUITests` | `testLeavingMorseHomeStopsCopyPlaybackBeforeCourseLesson` | passed | 92.810 |
| `CanadianHamPracticeUITests` | `testLessonIllustrationBriefsAreHiddenInEnglishAndFrench` | passed | 17.489 |
| `CanadianHamPracticeUITests` | `testLessonPrerequisiteNavigationAndAccessibilityDark` | passed | 43.745 |
| `CanadianHamPracticeUITests` | `testLessonPrerequisiteNavigationAndAccessibilityLight` | passed | 42.509 |
| `CanadianHamPracticeUITests` | `testLessonQuizResultPersistsAfterRelaunch` | passed | 36.846 |
| `CanadianHamPracticeUITests` | `testLongestAnswerWrapsAtLargestAccessibilityTextSize` | passed | 29.063 |
| `CanadianHamPracticeUITests` | `testMockExamDoesNotShowCorrectnessBeforeSubmit` | passed | 19.523 |
| `CanadianHamPracticeUITests` | `testMockExamHeaderControlsSupportLargestAccessibilityTextSize` | passed | 53.943 |
| `CanadianHamPracticeUITests` | `testMockExamNextUnansweredJumpsAfterAnsweringFirstQuestion` | passed | 34.550 |
| `CanadianHamPracticeUITests` | `testMockExamResultHeadingCarriesVoiceOverSubmissionSummary` | passed | 30.947 |
| `CanadianHamPracticeUITests` | `testMorseCopyPracticeAndExamFlow` | passed | 74.814 |
| `CanadianHamPracticeUITests` | `testMorseCopyStartResetsAfterAudioStartupFailure` | passed | 14.897 |
| `CanadianHamPracticeUITests` | `testMorseCourseReviewAndFinishedLessonReentryOnIOS` | passed | 288.158 |
| `CanadianHamPracticeUITests` | `testMorseExamGradingPushesResultsScreen` | passed | 39.949 |
| `CanadianHamPracticeUITests` | `testMorseExamStartResetsAfterAudioStartupFailure` | passed | 30.433 |
| `CanadianHamPracticeUITests` | `testMorseLessonSummaryShowsCorrectAnswerForWrongFinalAnswerOnIOS` | passed | 179.500 |
| `CanadianHamPracticeUITests` | `testMorseQuickListenAfterFinishedCourseAudioDoesNotReportStop` | passed | 100.668 |
| `CanadianHamPracticeUITests` | `testMorseResultsStartAgainActionsReturnToMorseOnce` | passed | 67.238 |
| `CanadianHamPracticeUITests` | `testMorseSectionIsTopLevelShowsCourseAndOpensFirstLesson` | passed | 99.632 |
| `CanadianHamPracticeUITests` | `testMorseSendingPracticeBackFromRunningExamStopsDeadlineGrading` | passed | 53.928 |
| `CanadianHamPracticeUITests` | `testMorseSendingPracticeClearsPendingCharacterWhenLeaving` | passed | 47.936 |
| `CanadianHamPracticeUITests` | `testMorseSendingPracticeGradesHeldStraightKeyBeforeScoring` | passed | 60.015 |
| `CanadianHamPracticeUITests` | `testMorseSendingPracticeGradesImmediatelyAtDeadline` | passed | 36.255 |
| `CanadianHamPracticeUITests` | `testMorseSendingPracticeUsesDebugHookAndPushesResultsScreen` | passed | 68.123 |
| `CanadianHamPracticeUITests` | `testMorseStartingQuickListenStopsCopyPlayback` | passed | 24.244 |
| `CanadianHamPracticeUITests` | `testMorseVisualOutputModeQuickListenOnIOS` | passed | 61.040 |
| `CanadianHamPracticeUITests` | `testOhmsLawLessonFiguresAndAccessibilityDark` | passed | 1115.224 |
| `CanadianHamPracticeUITests` | `testOhmsLawLessonFiguresAndAccessibilityLight` | passed | 1108.671 |
| `CanadianHamPracticeUITests` | `testOhmsLawWheelFitsAndEnlargesAtLargestAccessibilityTextSize` | failed | 637.716 |
| `CanadianHamPracticeUITests` | `testPracticeFlowSupportsLargestAccessibilityTextSize` | passed | 57.558 |
| `CanadianHamPracticeUITests` | `testPracticeImmediateFeedbackKeepsStateAfterFirstAnswer` | passed | 17.592 |
| `CanadianHamPracticeUITests` | `testPracticeModeChangeReopensCachedSessionFresh` | passed | 54.314 |
| `CanadianHamPracticeUITests` | `testRegularWidthMockExamEndExamDiscardsInProgressSession` | passed | 34.090 |
| `CanadianHamPracticeUITests` | `testRegularWidthMockExamResultPersistsAfterSubmit` | passed | 48.682 |
| `CanadianHamPracticeUITests` | `testReviewLaterHidesCorrectnessUntilSubmitAndResultsSurviveSave` | passed | 21.399 |
| `CanadianHamPracticeUITests` | `testSettingsLanguageControlSupportsLargestAccessibilityTextSize` | passed | 46.981 |
| `CanadianHamPracticeUITests` | `testSettingsResetClearsCompactMockExamCacheWithoutRelaunch` | passed | 44.115 |
| `CanadianHamPracticeUITests` | `testSettingsResetClearsSavedMockExamProgress` | passed | 52.861 |
| `CanadianHamPracticeUITests` | `testSubmittedReviewLaterPracticeDoesNotWarnBeforeCourseSwitch` | passed | 39.564 |
| `CanadianHamPracticeUITests` | `testSubsectionPracticeOpensFromHubAndShowsReviewScreen` | passed | 29.578 |
| `CanadianHamPracticeUITests` | `testWeakAreasImmediateSessionKeepsFeedbackPositionAndTallyAfterAnswers` | passed | 48.266 |

Failure evidence:

```text
/Users/david/Developer/canadian-ham-train-1017/apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:1649: error: -[CanadianHamUITests.CanadianHamPracticeUITests testOhmsLawWheelFitsAndEnlargesAtLargestAccessibilityTextSize] : XCTAssertTrue failed - Tapping the largest-text Enlarge figure button should open the sheet
```


## Current pre-consolidation calibration (intentionally interrupted)

Log: `/tmp/task-33-baseline-v2.log`.

Timing metadata:

```text
start=1792472426
end=1792473274
wall_seconds=848
exit_code=75
```

Target/class suite summaries (including existing skips):

```text
Executed 190 tests, with 0 failures (0 unexpected) in 14.355 (14.956) seconds
Executed 190 tests, with 0 failures (0 unexpected) in 14.355 (14.984) seconds
```

Only completed UI calibration methods are listed below; 190 unit tests also passed.
The in-flight method was interrupted, not declared passed or failed.

- `CanadianHamUITests.CanadianHamExamToolsUITests`: 2 passed.

| Class | Test | Result | Seconds |
| --- | --- | --- | --- |
| `CanadianHamExamToolsUITests` | `testAccessibilityAuditExamToolsDark` | passed | 322.972 |
| `CanadianHamExamToolsUITests` | `testAccessibilityAuditExamToolsLight` | passed | 311.446 |


## After: CanadianHamDefault

Log: `/tmp/task-33-after.log`.

Timing metadata:

```text
plan=CanadianHamDefault
start=1792473275
end=1792484808
wall_seconds=11533
exit_code=65
```

Target/class suite summaries (including existing skips):

```text
Executed 190 tests, with 0 failures (0 unexpected) in 13.750 (13.914) seconds
Executed 190 tests, with 0 failures (0 unexpected) in 13.750 (13.915) seconds
Executed 39 tests, with 3 tests skipped and 0 failures (0 unexpected) in 2973.307 (2973.332) seconds
Executed 87 tests, with 2 failures (1 unexpected) in 8416.960 (8417.044) seconds
Executed 126 tests, with 3 tests skipped and 2 failures (1 unexpected) in 11390.267 (11390.378) seconds
Executed 126 tests, with 3 tests skipped and 2 failures (1 unexpected) in 11390.267 (11390.378) seconds
```

- `CanadianHamTests.DuoLayoutPolicyTests`: 6 passed.
- `CanadianHamTests.ExamCalculatorViewModelTests`: 11 passed.
- `CanadianHamTests.HintSessionStateTests`: 26 passed.
- `CanadianHamTests.LocalizationCatalogTests`: 5 passed.
- `CanadianHamTests.MorseTrainerTests`: 27 passed.
- `CanadianHamTests.ProgressStoreTests`: 95 passed.
- `CanadianHamTests.QuestionBankTests`: 11 passed.
- `CanadianHamTests.ReadinessAndScoringTests`: 4 passed.
- `CanadianHamTests.RootNavigationMappingTests`: 5 passed.
- `CanadianHamUITests.CanadianHamExamToolsUITests`: 36 passed, 3 skipped.
- `CanadianHamUITests.CanadianHamPracticeUITests`: 2 failed, 85 passed.

| Class | Test | Result | Seconds |
| --- | --- | --- | --- |
| `DuoLayoutPolicyTests` | `testCompactWidthIPhoneKeepsSheetPolicy` | passed | 0.001 |
| `DuoLayoutPolicyTests` | `testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact` | passed | 0.001 |
| `DuoLayoutPolicyTests` | `testIPadInspectorRuleRemainsSizeClassDriven` | passed | 0.001 |
| `DuoLayoutPolicyTests` | `testMacAndOtherIdiomsNeverUseIPhonePolicy` | passed | 0.000 |
| `DuoLayoutPolicyTests` | `testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy` | passed | 0.001 |
| `DuoLayoutPolicyTests` | `testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds` | passed | 0.000 |
| `ExamCalculatorViewModelTests` | `testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes` | passed | 0.000 |
| `ExamCalculatorViewModelTests` | `testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testKeyHandlingProducesEngineDisplayAndSpokenResult` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testQuestionCardFocusResetKeepsTextSelectionEnabled` | passed | 0.004 |
| `ExamCalculatorViewModelTests` | `testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet` | passed | 0.001 |
| `ExamCalculatorViewModelTests` | `testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately` | passed | 0.001 |
| `HintSessionStateTests` | `testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine` | passed | 0.001 |
| `HintSessionStateTests` | `testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer` | passed | 0.001 |
| `HintSessionStateTests` | `testHingePeekEndsWhenPhoneFullyOpensOrCloses` | passed | 0.001 |
| `HintSessionStateTests` | `testHingePeekFastUnfoldThroughBandNeverPeeks` | passed | 0.001 |
| `HintSessionStateTests` | `testHingePeekLeavingToleranceDoesNotResetDismissalSuppression` | passed | 0.000 |
| `HintSessionStateTests` | `testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression` | passed | 0.000 |
| `HintSessionStateTests` | `testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell` | passed | 0.000 |
| `HintSessionStateTests` | `testHingePeekPresentationDismissalSuppressesReopenUntilReset` | passed | 0.001 |
| `HintSessionStateTests` | `testHingePeekPresentationImmediateAnswerEndsEligibility` | passed | 0.001 |
| `HintSessionStateTests` | `testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` | passed | 0.001 |
| `HintSessionStateTests` | `testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` | passed | 0.000 |
| `HintSessionStateTests` | `testHingePeekPresentationStartsOnlyOnceUntilPostureReset` | passed | 0.000 |
| `HintSessionStateTests` | `testHingePeekRecheckPeeksWithoutNewSamples` | passed | 0.001 |
| `HintSessionStateTests` | `testHingePeekRequiresStableDwellInSlightOpenBand` | passed | 0.000 |
| `HintSessionStateTests` | `testHingePeekSlowCloseThroughBandNeverPeeks` | passed | 0.000 |
| `HintSessionStateTests` | `testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` | passed | 0.000 |
| `HintSessionStateTests` | `testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` | passed | 0.001 |
| `HintSessionStateTests` | `testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` | passed | 0.000 |
| `HintSessionStateTests` | `testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` | passed | 0.000 |
| `HintSessionStateTests` | `testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` | passed | 0.404 |
| `HintSessionStateTests` | `testHintVisibilityTimerDoesNotQualifyShortPeekRoute` | passed | 0.284 |
| `HintSessionStateTests` | `testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` | passed | 0.001 |
| `HintSessionStateTests` | `testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` | passed | 0.001 |
| `HintSessionStateTests` | `testReviewLaterHintAfterSelectionRecordsHelp` | passed | 0.000 |
| `HintSessionStateTests` | `testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` | passed | 0.000 |
| `HintSessionStateTests` | `testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` | passed | 2.710 |
| `LocalizationCatalogTests` | `testEveryCatalogKeyHasFrenchTranslations` | passed | 0.007 |
| `LocalizationCatalogTests` | `testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` | passed | 0.005 |
| `LocalizationCatalogTests` | `testLanguagePreferenceResolvesSystemAndOverrides` | passed | 0.001 |
| `LocalizationCatalogTests` | `testLocalizedNullableTextAndLanguageFallsBackToEnglish` | passed | 0.000 |
| `LocalizationCatalogTests` | `testQuestionBankLoadErrorDescriptionUsesFrenchLocale` | passed | 0.003 |
| `MorseTrainerTests` | `testCompletedMorseCourseSessionIgnoresResubmittedAnswer` | passed | 0.001 |
| `MorseTrainerTests` | `testFixedTimingProfilesUseEngineValues` | passed | 0.001 |
| `MorseTrainerTests` | `testLessonBodyAndBulletContrastTokensMeetMinimumRatio` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseAudioSessionStaysActiveUntilLastPlayerReleases` | passed | 0.000 |
| `MorseTrainerTests` | `testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` | passed | 0.002 |
| `MorseTrainerTests` | `testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` | passed | 0.000 |
| `MorseTrainerTests` | `testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` | passed | 0.004 |
| `MorseTrainerTests` | `testMorseExamGeneratorMeetsReceivingExamConstraints` | passed | 0.002 |
| `MorseTrainerTests` | `testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` | passed | 0.000 |
| `MorseTrainerTests` | `testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` | passed | 0.103 |
| `MorseTrainerTests` | `testMorseSendingClassifiesTimingAndErrorSignal` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseSendingPendingFinalizationHelperCancelsAndClears` | passed | 0.000 |
| `MorseTrainerTests` | `testMorseSendingRemainingExamSecondsUsesFixedDeadline` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseSettingsClampAndPreset` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseSettingsCodableRoundTripPreservesOutputMode` | passed | 0.001 |
| `MorseTrainerTests` | `testMorseSettingsDecodesLegacyPayloadWithIsEnabled` | passed | 0.000 |
| `MorseTrainerTests` | `testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` | passed | 0.006 |
| `MorseTrainerTests` | `testMorseSettingsRoundTripThroughUserDefaults` | passed | 0.005 |
| `MorseTrainerTests` | `testMorseStopDelayDrainsFadeBeforeStoppingEngine` | passed | 0.000 |
| `MorseTrainerTests` | `testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` | passed | 0.002 |
| `MorseTrainerTests` | `testReduceFlashingDecisionUsesInjectedFlags` | passed | 0.000 |
| `MorseTrainerTests` | `testReduceFlashingStopsOnlyRunningVisualBeacon` | passed | 0.001 |
| `MorseTrainerTests` | `testScheduleMorseVisualPlaybackInitialStateAndFallback` | passed | 0.001 |
| `ProgressStoreTests` | `testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` | passed | 0.160 |
| `ProgressStoreTests` | `testAdvancedImportRejectsHonoursAttempts` | passed | 0.035 |
| `ProgressStoreTests` | `testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` | passed | 0.005 |
| `ProgressStoreTests` | `testAppSettingsModelPublishesMorseSettingsForRootViewSync` | passed | 0.001 |
| `ProgressStoreTests` | `testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` | passed | 0.000 |
| `ProgressStoreTests` | `testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` | passed | 0.001 |
| `ProgressStoreTests` | `testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` | passed | 0.041 |
| `ProgressStoreTests` | `testDecodesLegacyBasicExportWithoutBankIdFields` | passed | 0.039 |
| `ProgressStoreTests` | `testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` | passed | 0.038 |
| `ProgressStoreTests` | `testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` | passed | 0.028 |
| `ProgressStoreTests` | `testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` | passed | 0.066 |
| `ProgressStoreTests` | `testFreshInstallDefaultsLanguageToSystem` | passed | 0.016 |
| `ProgressStoreTests` | `testICloudAccountSignalsUseInitInjectedFactory` | passed | 0.138 |
| `ProgressStoreTests` | `testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` | passed | 0.068 |
| `ProgressStoreTests` | `testICloudDeleteCanDeleteLocalDataAfterZoneDelete` | passed | 0.057 |
| `ProgressStoreTests` | `testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` | passed | 0.074 |
| `ProgressStoreTests` | `testICloudMergeFixtureIsPermutationIndependentAndIdempotent` | passed | 0.008 |
| `ProgressStoreTests` | `testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` | passed | 0.001 |
| `ProgressStoreTests` | `testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` | passed | 0.104 |
| `ProgressStoreTests` | `testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` | passed | 0.045 |
| `ProgressStoreTests` | `testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` | passed | 0.047 |
| `ProgressStoreTests` | `testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` | passed | 0.066 |
| `ProgressStoreTests` | `testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` | passed | 0.085 |
| `ProgressStoreTests` | `testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` | passed | 0.043 |
| `ProgressStoreTests` | `testImportLeavesTask4610Version2LessonSplitRowsUnchanged` | passed | 0.047 |
| `ProgressStoreTests` | `testImportMigratesMixedTask4610SyncRowsByRowVersion` | passed | 0.050 |
| `ProgressStoreTests` | `testImportMigratesTask4610LessonSplitProgressAndQuizAttempts` | passed | 0.047 |
| `ProgressStoreTests` | `testImportOfOlderExportDoesNotRemoveExistingMorseProgress` | passed | 0.045 |
| `ProgressStoreTests` | `testImportRejectsInvalidSyncDeviceRows` | passed | 0.056 |
| `ProgressStoreTests` | `testImportRejectsUnsupportedLanguagePreferenceValues` | passed | 0.054 |
| `ProgressStoreTests` | `testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` | passed | 0.092 |
| `ProgressStoreTests` | `testImportRollbackKeepsExistingDataWhenReplacementFails` | passed | 0.061 |
| `ProgressStoreTests` | `testImportRollbackPropagatesMorseProgressRemovalFailure` | passed | 0.045 |
| `ProgressStoreTests` | `testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` | passed | 0.044 |
| `ProgressStoreTests` | `testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` | passed | 0.047 |
| `ProgressStoreTests` | `testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` | passed | 0.001 |
| `ProgressStoreTests` | `testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` | passed | 0.060 |
| `ProgressStoreTests` | `testImportValidationRejectsDuplicateMorseDailyActivityDates` | passed | 0.053 |
| `ProgressStoreTests` | `testImportValidationRejectsInvalidMorseCourseProgress` | passed | 0.054 |
| `ProgressStoreTests` | `testImportValidationRejectsMismatchedScoreBankId` | passed | 0.065 |
| `ProgressStoreTests` | `testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` | passed | 0.040 |
| `ProgressStoreTests` | `testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` | passed | 0.040 |
| `ProgressStoreTests` | `testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` | passed | 0.053 |
| `ProgressStoreTests` | `testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` | passed | 0.017 |
| `ProgressStoreTests` | `testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` | passed | 0.023 |
| `ProgressStoreTests` | `testLaunchIgnoresRegisteredAppleLanguagesValue` | passed | 0.016 |
| `ProgressStoreTests` | `testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` | passed | 0.017 |
| `ProgressStoreTests` | `testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` | passed | 0.031 |
| `ProgressStoreTests` | `testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` | passed | 0.031 |
| `ProgressStoreTests` | `testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` | passed | 0.032 |
| `ProgressStoreTests` | `testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` | passed | 0.022 |
| `ProgressStoreTests` | `testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` | passed | 0.042 |
| `ProgressStoreTests` | `testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` | passed | 0.101 |
| `ProgressStoreTests` | `testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` | passed | 0.138 |
| `ProgressStoreTests` | `testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` | passed | 0.075 |
| `ProgressStoreTests` | `testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` | passed | 0.039 |
| `ProgressStoreTests` | `testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` | passed | 0.065 |
| `ProgressStoreTests` | `testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` | passed | 1.248 |
| `ProgressStoreTests` | `testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` | passed | 0.025 |
| `ProgressStoreTests` | `testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` | passed | 0.109 |
| `ProgressStoreTests` | `testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` | passed | 0.141 |
| `ProgressStoreTests` | `testMockExamTimerRefreshPreservesFractionalRemainder` | passed | 0.002 |
| `ProgressStoreTests` | `testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` | passed | 0.045 |
| `ProgressStoreTests` | `testMorseExportMapsHapticsToWebCompatibleAudio` | passed | 0.001 |
| `ProgressStoreTests` | `testMorseImportDecodesMissingAndPartialMorsePreferences` | passed | 0.094 |
| `ProgressStoreTests` | `testMorseImportRejectsExplicitNullMorseValues` | passed | 0.001 |
| `ProgressStoreTests` | `testMorseImportRejectsUnsupportedMorsePreferenceEnums` | passed | 0.052 |
| `ProgressStoreTests` | `testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` | passed | 0.047 |
| `ProgressStoreTests` | `testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` | passed | 0.020 |
| `ProgressStoreTests` | `testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` | passed | 0.097 |
| `ProgressStoreTests` | `testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` | passed | 0.061 |
| `ProgressStoreTests` | `testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` | passed | 0.063 |
| `ProgressStoreTests` | `testProgressStoreRoundTripExportImportReset` | passed | 0.133 |
| `ProgressStoreTests` | `testResetAllDataTurnsICloudSyncOptInOff` | passed | 0.050 |
| `ProgressStoreTests` | `testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` | passed | 0.078 |
| `ProgressStoreTests` | `testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` | passed | 0.142 |
| `ProgressStoreTests` | `testResetClearsAppleLanguagesAndLanguagePreference` | passed | 0.026 |
| `ProgressStoreTests` | `testResetFailureKeepsPreviousAppleLanguagesAndPreference` | passed | 0.034 |
| `ProgressStoreTests` | `testResetRollsBackWhenMorseProgressRemovalFails` | passed | 0.031 |
| `ProgressStoreTests` | `testSavingLargeQuestionProgressBatchBuildsOneWriteContext` | passed | 1.275 |
| `ProgressStoreTests` | `testSharedAppleSettingsModelAppliesLivePreferenceUpdates` | passed | 0.028 |
| `ProgressStoreTests` | `testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` | passed | 0.004 |
| `ProgressStoreTests` | `testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` | passed | 0.039 |
| `ProgressStoreTests` | `testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` | passed | 0.166 |
| `ProgressStoreTests` | `testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` | passed | 0.130 |
| `ProgressStoreTests` | `testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` | passed | 0.038 |
| `ProgressStoreTests` | `testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` | passed | 0.016 |
| `ProgressStoreTests` | `testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices` | passed | 0.058 |
| `ProgressStoreTests` | `testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports` | passed | 0.048 |
| `ProgressStoreTests` | `testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration` | passed | 0.034 |
| `ProgressStoreTests` | `testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds` | passed | 0.039 |
| `ProgressStoreTests` | `testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating` | passed | 0.167 |
| `ProgressStoreTests` | `testTask4610SharedConceptMappingAndConceptInclusiveScores` | passed | 0.335 |
| `ProgressStoreTests` | `testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows` | passed | 0.048 |
| `ProgressStoreTests` | `testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` | passed | 0.077 |
| `QuestionBankTests` | `testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` | passed | 0.012 |
| `QuestionBankTests` | `testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` | passed | 0.013 |
| `QuestionBankTests` | `testAppBundleContainsNoReadmeFiles` | passed | 0.026 |
| `QuestionBankTests` | `testAppBundleContainsOnlyExpectedGeneratedBankDirectories` | passed | 0.001 |
| `QuestionBankTests` | `testBundledJSONDecodesExpectedCounts` | passed | 0.018 |
| `QuestionBankTests` | `testBundledLessonModelExposesPrerequisites` | passed | 0.779 |
| `QuestionBankTests` | `testBundledLessonsAndExplanationsLoadThroughContentLibrary` | passed | 0.671 |
| `QuestionBankTests` | `testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` | passed | 0.018 |
| `QuestionBankTests` | `testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` | passed | 0.073 |
| `QuestionBankTests` | `testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` | passed | 0.000 |
| `QuestionBankTests` | `testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` | passed | 0.539 |
| `ReadinessAndScoringTests` | `testAdvancedScoringAndReadinessSuppressHonours` | passed | 0.001 |
| `ReadinessAndScoringTests` | `testExamScoringBoundaries` | passed | 0.001 |
| `ReadinessAndScoringTests` | `testReadinessStates` | passed | 0.093 |
| `ReadinessAndScoringTests` | `testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` | passed | 0.090 |
| `RootNavigationMappingTests` | `testCompactHomeSessionAndSectionPushesUseVisibleDestination` | passed | 0.001 |
| `RootNavigationMappingTests` | `testEmptyCompactPathMapsToHome` | passed | 0.059 |
| `RootNavigationMappingTests` | `testEveryLearnRouteRoundTripsWithItsWholeStack` | passed | 0.001 |
| `RootNavigationMappingTests` | `testEveryRootSelectionRoundTrips` | passed | 0.001 |
| `RootNavigationMappingTests` | `testPracticeHintLessonStackKeepsSessionAsSplitSelection` | passed | 0.002 |
| `CanadianHamExamToolsUITests` | `testAccessibilityAuditExamToolsDark` | passed | 355.675 |
| `CanadianHamExamToolsUITests` | `testAccessibilityAuditExamToolsLight` | passed | 347.062 |
| `CanadianHamExamToolsUITests` | `testAccessibilityAuditHintedAnswerResultLightAndDark` | passed | 164.921 |
| `CanadianHamExamToolsUITests` | `testAccessibilityAuditHintToolLightAndDark` | passed | 80.004 |
| `CanadianHamExamToolsUITests` | `testCalculatorAutoFocusesHardwareKeyboardOnOpen` | passed | 20.958 |
| `CanadianHamExamToolsUITests` | `testCalculatorKeyboardInputIsFocusScoped` | passed | 175.445 |
| `CanadianHamExamToolsUITests` | `testCalculatorValueResetsForNewMockExam` | passed | 72.919 |
| `CanadianHamExamToolsUITests` | `testCalculatorValueSurvivesCloseAndReopenAndResetsForNewSession` | passed | 110.578 |
| `CanadianHamExamToolsUITests` | `testCaptureCalculatorEvidenceScreenshots` | skipped | 0.669 |
| `CanadianHamExamToolsUITests` | `testCompactToSplitKeepsDeepLearnLesson` | passed | 31.856 |
| `CanadianHamExamToolsUITests` | `testCompactToSplitKeepsDeepLearnQuiz` | passed | 90.496 |
| `CanadianHamExamToolsUITests` | `testCompactWidthIPhoneKeepsCompactSheet` | passed | 25.329 |
| `CanadianHamExamToolsUITests` | `testForcedRegularIPhoneLandscapeCalculatorUsesSheetAndKeepsSelection` | passed | 82.885 |
| `CanadianHamExamToolsUITests` | `testForcedRegularIPhoneLandscapeMediumSheetScrollsEveryCalculatorKey` | passed | 315.079 |
| `CanadianHamExamToolsUITests` | `testHintToolLadderAndLessonLink` | passed | 52.139 |
| `CanadianHamExamToolsUITests` | `testLargeDetentCalculatorRunsFullAccessibilityAuditLightAndDark` | passed | 63.018 |
| `CanadianHamExamToolsUITests` | `testLargestDynamicTypeKeepsCalculatorGridReachableLightAndDark` | passed | 74.103 |
| `CanadianHamExamToolsUITests` | `testLargestDynamicTypeKeepsHintToolButtonReachable` | passed | 41.332 |
| `CanadianHamExamToolsUITests` | `testMockExamCalculatorKeepsAnswersHittableAndTimerRuns` | passed | 88.461 |
| `CanadianHamExamToolsUITests` | `testMockExamDoesNotExposeHints` | passed | 15.349 |
| `CanadianHamExamToolsUITests` | `testMockExamQuestionsNavigatorPresentsAfterCalculatorSheet` | passed | 37.808 |
| `CanadianHamExamToolsUITests` | `testOneLevelHintHasNoSecondHintAffordance` | passed | 21.690 |
| `CanadianHamExamToolsUITests` | `testPracticeCalculatorSheetKeepsAnswersHittableAtMediumDetent` | passed | 79.438 |
| `CanadianHamExamToolsUITests` | `testPreciseScrollPositionsAnswerAboveToolSheet` | passed | 115.514 |
| `CanadianHamExamToolsUITests` | `testReferenceSheetToolHiddenUntilTask44Dot4` | passed | 16.583 |
| `CanadianHamExamToolsUITests` | `testRegularWidthInspectorAccessibilityAuditLightAndDark` | skipped | 1.194 |
| `CanadianHamExamToolsUITests` | `testRegularWidthIPhoneUsesInspectorAndKeepsPracticeSelection` | passed | 30.109 |
| `CanadianHamExamToolsUITests` | `testRegularWidthMockExamUsesCalculatorInspectorWithoutHints` | passed | 29.737 |
| `CanadianHamExamToolsUITests` | `testRegularWidthUsesInspectorAndKeepsAnswersHittable` | skipped | 0.672 |
| `CanadianHamExamToolsUITests` | `testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` | passed | 62.374 |
| `CanadianHamExamToolsUITests` | `testSimulatedHingeDismissedPeekReopensOnlyAfterReset` | passed | 31.674 |
| `CanadianHamExamToolsUITests` | `testSimulatedHingeFastUnfoldDoesNotPeekHintOneInPractice` | passed | 13.157 |
| `CanadianHamExamToolsUITests` | `testSimulatedHingeNeverPeeksHintOneInMockExam` | passed | 23.201 |
| `CanadianHamExamToolsUITests` | `testSimulatedHingePeekStillWorksAfterHintLessonRoundTrip` | passed | 41.489 |
| `CanadianHamExamToolsUITests` | `testSimulatedHingeStableSlightOpenPeeksHintOneInPractice` | passed | 26.427 |
| `CanadianHamExamToolsUITests` | `testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` | passed | 68.295 |
| `CanadianHamExamToolsUITests` | `testSizeClassRegularInspectorAccessibilityAuditLightAndDark` | passed | 47.362 |
| `CanadianHamExamToolsUITests` | `testSplitToCompactKeepsDeepLearnLesson` | passed | 30.144 |
| `CanadianHamExamToolsUITests` | `testSplitToCompactKeepsDeepLearnQuiz` | passed | 88.164 |
| `CanadianHamPracticeUITests` | `testAboutShowsReleaseAttributionDisclaimerAndBankVersion` | passed | 32.255 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditAdvancedCourseScreensDark` | passed | 89.958 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditAdvancedCourseScreensLight` | passed | 101.059 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditCoreScreensDark` | passed | 90.380 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditCoreScreensLight` | passed | 95.254 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditLearnFlowDark` | passed | 40.044 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditLearnFlowLight` | passed | 41.093 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMockExamFlowDark` | passed | 118.734 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMockExamFlowLight` | passed | 121.543 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseBeaconOutputDark` | passed | 41.639 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseBeaconOutputLight` | passed | 45.693 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseCourseLessonAndSummaryDark` | passed | 447.067 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseCourseLessonAndSummaryLight` | passed | 436.621 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseExamGradedDiffDark` | passed | 123.280 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseExamGradedDiffLight` | passed | 115.295 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseSendingMainAndExamScreensDark` | passed | 77.450 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseSendingMainAndExamScreensLight` | passed | 78.113 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseSendingResultsDark` | passed | 67.311 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseSendingResultsLight` | failed | 78.654 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseTapeOutputDark` | passed | 46.440 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseTapeOutputLight` | passed | 44.142 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditPracticeSessionDark` | passed | 114.239 |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditPracticeSessionLight` | passed | 107.640 |
| `CanadianHamPracticeUITests` | `testCanPracticeInFrenchAndSeeFeedback` | passed | 38.769 |
| `CanadianHamPracticeUITests` | `testChoosingSystemDefaultAfterFrenchLaunchSwitchesQuestionsImmediatelyAndShowsRestartNote` | passed | 74.531 |
| `CanadianHamPracticeUITests` | `testCompactHomeStartPracticeAndMockExamBackReturnToHome` | passed | 28.574 |
| `CanadianHamPracticeUITests` | `testCompactMockExamEndExamDiscardsInProgressSession` | passed | 30.565 |
| `CanadianHamPracticeUITests` | `testCompactRootNavigationPreservesMockExamState` | passed | 39.647 |
| `CanadianHamPracticeUITests` | `testCompactRootNavigationPreservesPracticeSessionState` | passed | 41.862 |
| `CanadianHamPracticeUITests` | `testCompactTopLevelListPushesMorseThenLearn` | passed | 22.367 |
| `CanadianHamPracticeUITests` | `testCompletesFirstMorseLessonSessionOnIOS` | passed | 186.693 |
| `CanadianHamPracticeUITests` | `testCoursePickerSwitchesToAdvancedLessonsAndFiftyQuestionMockWithoutHonours` | passed | 48.412 |
| `CanadianHamPracticeUITests` | `testCourseSwitchCancelKeepsImmediatePracticeFeedbackAndConfirmOpensAdvancedPractice` | passed | 101.358 |
| `CanadianHamPracticeUITests` | `testCourseSwitchCancelKeepsUnsubmittedReviewLaterAnswersAndConfirmOpensAdvancedPractice` | passed | 100.313 |
| `CanadianHamPracticeUITests` | `testCourseSwitchConfirmationAuditsDark` | passed | 43.471 |
| `CanadianHamPracticeUITests` | `testCourseSwitchConfirmationKeepsMockExamWhenCancelledLight` | passed | 50.391 |
| `CanadianHamPracticeUITests` | `testDueReviewLaterSessionKeepsPositionTallyAndReviewAfterSubmit` | passed | 55.963 |
| `CanadianHamPracticeUITests` | `testExplanationAppearsAfterAnsweringInPractice` | passed | 24.972 |
| `CanadianHamPracticeUITests` | `testFrenchAboutKeepsLegalTextInEnglish` | passed | 12.083 |
| `CanadianHamPracticeUITests` | `testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice` | passed | 88.924 |
| `CanadianHamPracticeUITests` | `testLanguagePickerIsAbsentOnCategoryListAndPractice` | passed | 17.239 |
| `CanadianHamPracticeUITests` | `testLanguagePickerIsAbsentOnCompactQuestionScreensAndMorse` | passed | 40.524 |
| `CanadianHamPracticeUITests` | `testLanguageRestartNoteHiddenWhenLanguageMatchesInterface` | passed | 9.167 |
| `CanadianHamPracticeUITests` | `testLearnOpensLessonAndShowsFirstHeading` | passed | 8.031 |
| `CanadianHamPracticeUITests` | `testLearnUserNavigationOpensLessonQuiz` | passed | 163.026 |
| `CanadianHamPracticeUITests` | `testLeavingCourseLessonStopsCoursePlaybackBeforeQuickListen` | passed | 99.201 |
| `CanadianHamPracticeUITests` | `testLeavingMorseHomeStopsCopyPlaybackBeforeCourseLesson` | passed | 94.899 |
| `CanadianHamPracticeUITests` | `testLessonIllustrationBriefsAreHiddenInEnglishAndFrench` | passed | 17.118 |
| `CanadianHamPracticeUITests` | `testLessonPrerequisiteNavigationAndAccessibilityDark` | passed | 45.546 |
| `CanadianHamPracticeUITests` | `testLessonPrerequisiteNavigationAndAccessibilityLight` | passed | 40.725 |
| `CanadianHamPracticeUITests` | `testLessonQuizResultPersistsAfterRelaunch` | passed | 32.793 |
| `CanadianHamPracticeUITests` | `testLongestAnswerWrapsAtLargestAccessibilityTextSize` | passed | 27.687 |
| `CanadianHamPracticeUITests` | `testMockExamDoesNotShowCorrectnessBeforeSubmit` | passed | 19.005 |
| `CanadianHamPracticeUITests` | `testMockExamHeaderControlsSupportLargestAccessibilityTextSize` | passed | 51.137 |
| `CanadianHamPracticeUITests` | `testMockExamNextUnansweredJumpsAfterAnsweringFirstQuestion` | passed | 34.795 |
| `CanadianHamPracticeUITests` | `testMockExamResultHeadingCarriesVoiceOverSubmissionSummary` | passed | 31.036 |
| `CanadianHamPracticeUITests` | `testMorseCopyPracticeAndExamFlow` | passed | 81.515 |
| `CanadianHamPracticeUITests` | `testMorseCopyStartResetsAfterAudioStartupFailure` | passed | 14.920 |
| `CanadianHamPracticeUITests` | `testMorseCourseReviewAndFinishedLessonReentryOnIOS` | passed | 300.552 |
| `CanadianHamPracticeUITests` | `testMorseExamGradingPushesResultsScreen` | passed | 38.722 |
| `CanadianHamPracticeUITests` | `testMorseExamStartResetsAfterAudioStartupFailure` | passed | 30.632 |
| `CanadianHamPracticeUITests` | `testMorseLessonSummaryShowsCorrectAnswerForWrongFinalAnswerOnIOS` | passed | 190.594 |
| `CanadianHamPracticeUITests` | `testMorseQuickListenAfterFinishedCourseAudioDoesNotReportStop` | passed | 101.074 |
| `CanadianHamPracticeUITests` | `testMorseResultsStartAgainActionsReturnToMorseOnce` | passed | 69.442 |
| `CanadianHamPracticeUITests` | `testMorseSectionIsTopLevelShowsCourseAndOpensFirstLesson` | passed | 99.579 |
| `CanadianHamPracticeUITests` | `testMorseSendingPracticeBackFromRunningExamStopsDeadlineGrading` | passed | 61.242 |
| `CanadianHamPracticeUITests` | `testMorseSendingPracticeClearsPendingCharacterWhenLeaving` | passed | 49.693 |
| `CanadianHamPracticeUITests` | `testMorseSendingPracticeGradesHeldStraightKeyBeforeScoring` | passed | 54.581 |
| `CanadianHamPracticeUITests` | `testMorseSendingPracticeGradesImmediatelyAtDeadline` | passed | 39.203 |
| `CanadianHamPracticeUITests` | `testMorseSendingPracticeUsesDebugHookAndPushesResultsScreen` | passed | 70.219 |
| `CanadianHamPracticeUITests` | `testMorseStartingQuickListenStopsCopyPlayback` | passed | 24.273 |
| `CanadianHamPracticeUITests` | `testMorseVisualOutputModeQuickListenOnIOS` | passed | 62.049 |
| `CanadianHamPracticeUITests` | `testOhmsLawLessonFiguresAndAccessibilityDark` | failed | 471.508 |
| `CanadianHamPracticeUITests` | `testOhmsLawLessonFiguresAndAccessibilityLight` | passed | 1338.229 |
| `CanadianHamPracticeUITests` | `testOhmsLawWheelFitsAndEnlargesAtLargestAccessibilityTextSize` | passed | 460.190 |
| `CanadianHamPracticeUITests` | `testPracticeFlowSupportsLargestAccessibilityTextSize` | passed | 66.460 |
| `CanadianHamPracticeUITests` | `testPracticeImmediateFeedbackKeepsStateAfterFirstAnswer` | passed | 17.835 |
| `CanadianHamPracticeUITests` | `testPracticeModeChangeReopensCachedSessionFresh` | passed | 62.117 |
| `CanadianHamPracticeUITests` | `testRegularWidthMockExamEndExamDiscardsInProgressSession` | passed | 40.070 |
| `CanadianHamPracticeUITests` | `testRegularWidthMockExamResultPersistsAfterSubmit` | passed | 65.974 |
| `CanadianHamPracticeUITests` | `testReviewLaterHidesCorrectnessUntilSubmitAndResultsSurviveSave` | passed | 21.705 |
| `CanadianHamPracticeUITests` | `testSettingsLanguageControlSupportsLargestAccessibilityTextSize` | passed | 56.232 |
| `CanadianHamPracticeUITests` | `testSettingsResetClearsCompactMockExamCacheWithoutRelaunch` | passed | 55.555 |
| `CanadianHamPracticeUITests` | `testSettingsResetClearsSavedMockExamProgress` | passed | 60.608 |
| `CanadianHamPracticeUITests` | `testSubmittedReviewLaterPracticeDoesNotWarnBeforeCourseSwitch` | passed | 43.834 |
| `CanadianHamPracticeUITests` | `testSubsectionPracticeOpensFromHubAndShowsReviewScreen` | passed | 31.380 |
| `CanadianHamPracticeUITests` | `testWeakAreasImmediateSessionKeepsFeedbackPositionAndTallyAfterAnswers` | passed | 62.243 |

Failure evidence:

```text
/Users/david/Developer/canadian-ham-task-33/apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:1708: error: -[CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseSendingResultsLight] : XCTAssertTrue failed
/Users/david/Developer/canadian-ham-task-33/apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:2293: error: -[CanadianHamUITests.CanadianHamPracticeUITests testOhmsLawLessonFiguresAndAccessibilityDark] : failed: caught error: "Error Domain=com.apple.xcode.xctest.accessibilityAudit Code=-56 "Audit failed to complete in time" UserInfo={NSLocalizedDescription=Audit failed to complete in time}"
```


## After: CanadianHamLessonFigures

Log: `/tmp/task-33-figures.log`.

Timing metadata:

```text
plan=CanadianHamLessonFigures
start=1792484808
end=1792496328
wall_seconds=11520
exit_code=65
```

Target/class suite summaries (including existing skips):

```text
Executed 45 tests, with 1 failure (1 unexpected) in 8806.115 (8806.160) seconds
Executed 2 tests, with 0 failures (0 unexpected) in 2638.179 (2638.180) seconds
Executed 47 tests, with 1 failure (1 unexpected) in 11444.293 (11444.380) seconds
Executed 47 tests, with 1 failure (1 unexpected) in 11444.293 (11444.382) seconds
```

- `CanadianHamUITests.CanadianHamLessonFiguresUITests`: 1 failed, 44 passed.
- `CanadianHamUITests.CanadianHamPracticeUITests`: 2 passed.

| Class | Test | Result | Seconds |
| --- | --- | --- | --- |
| `CanadianHamLessonFiguresUITests` | `testModule1LessonFigureDarkSample` | passed | 192.886 |
| `CanadianHamLessonFiguresUITests` | `testModule1LessonFiguresLightPart1` | passed | 165.015 |
| `CanadianHamLessonFiguresUITests` | `testModule1LessonFiguresLightPart1NextLesson` | passed | 191.522 |
| `CanadianHamLessonFiguresUITests` | `testModule1LessonFiguresLightPart2` | passed | 174.813 |
| `CanadianHamLessonFiguresUITests` | `testModule1LessonFiguresLightPart3` | passed | 166.943 |
| `CanadianHamLessonFiguresUITests` | `testModule1LessonFiguresLightPart4` | passed | 153.025 |
| `CanadianHamLessonFiguresUITests` | `testModule1LessonFiguresLightPart4NextLesson` | passed | 135.332 |
| `CanadianHamLessonFiguresUITests` | `testModule2LessonFigureDarkSample` | passed | 200.259 |
| `CanadianHamLessonFiguresUITests` | `testModule2LessonFiguresLightPart1` | passed | 204.852 |
| `CanadianHamLessonFiguresUITests` | `testModule2LessonFiguresLightPart1NextLesson` | passed | 177.648 |
| `CanadianHamLessonFiguresUITests` | `testModule2LessonFiguresLightPart2` | passed | 106.570 |
| `CanadianHamLessonFiguresUITests` | `testModule2LessonFiguresLightPart2NextLesson` | passed | 139.860 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFigureDarkSample` | passed | 160.617 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFiguresLightPart1` | passed | 162.444 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFiguresLightPart1NextLesson` | passed | 128.028 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFiguresLightPart2` | passed | 126.188 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFiguresLightPart2NextLesson` | passed | 136.768 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFiguresLightPart3` | passed | 145.765 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFiguresLightPart3NextLesson` | passed | 130.951 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFiguresLightPart4` | passed | 151.948 |
| `CanadianHamLessonFiguresUITests` | `testModule3LessonFiguresLightPart4NextLesson` | passed | 182.959 |
| `CanadianHamLessonFiguresUITests` | `testModule4LessonFigureDarkSample` | passed | 208.514 |
| `CanadianHamLessonFiguresUITests` | `testModule4LessonFiguresLightPart1` | passed | 205.998 |
| `CanadianHamLessonFiguresUITests` | `testModule4LessonFiguresLightPart1NextLesson` | passed | 219.718 |
| `CanadianHamLessonFiguresUITests` | `testModule4LessonFiguresLightPart2` | passed | 275.376 |
| `CanadianHamLessonFiguresUITests` | `testModule5LessonFigureDarkSample` | passed | 143.993 |
| `CanadianHamLessonFiguresUITests` | `testModule5LessonFiguresLightPart1` | passed | 137.742 |
| `CanadianHamLessonFiguresUITests` | `testModule5LessonFiguresLightPart2` | passed | 628.620 |
| `CanadianHamLessonFiguresUITests` | `testModule5LessonFiguresLightPart3` | passed | 203.393 |
| `CanadianHamLessonFiguresUITests` | `testModule5LessonFiguresLightPart3NextLesson` | passed | 174.241 |
| `CanadianHamLessonFiguresUITests` | `testModule5LessonFiguresLightPart4` | passed | 182.394 |
| `CanadianHamLessonFiguresUITests` | `testModule5LessonFiguresLightPart5` | passed | 236.195 |
| `CanadianHamLessonFiguresUITests` | `testModule6LessonFigureDarkSample` | passed | 171.692 |
| `CanadianHamLessonFiguresUITests` | `testModule6LessonFiguresLightPart1` | passed | 170.210 |
| `CanadianHamLessonFiguresUITests` | `testModule6LessonFiguresLightPart1NextLesson` | passed | 183.355 |
| `CanadianHamLessonFiguresUITests` | `testModule6LessonFiguresLightPart2` | passed | 148.998 |
| `CanadianHamLessonFiguresUITests` | `testModule6LessonFiguresLightPart2NextLesson` | passed | 195.524 |
| `CanadianHamLessonFiguresUITests` | `testModule6LessonFiguresLightPart3` | passed | 193.673 |
| `CanadianHamLessonFiguresUITests` | `testModule7LessonFigureDarkSample` | failed | 230.276 |
| `CanadianHamLessonFiguresUITests` | `testModule7LessonFiguresLightPart1` | passed | 274.234 |
| `CanadianHamLessonFiguresUITests` | `testModule7LessonFiguresLightPart1NextLesson` | passed | 191.171 |
| `CanadianHamLessonFiguresUITests` | `testModule7LessonFiguresLightPart2` | passed | 217.086 |
| `CanadianHamLessonFiguresUITests` | `testModule8LessonFigureDarkSample` | passed | 360.560 |
| `CanadianHamLessonFiguresUITests` | `testModule8LessonFiguresLightPart1` | passed | 361.740 |
| `CanadianHamLessonFiguresUITests` | `testModule8LessonFiguresLightPart2` | passed | 157.020 |
| `CanadianHamPracticeUITests` | `testOhmsLawLessonFiguresAndAccessibilityDark` | passed | 1316.588 |
| `CanadianHamPracticeUITests` | `testOhmsLawLessonFiguresAndAccessibilityLight` | passed | 1321.591 |

Failure evidence:

```text
/Users/david/Developer/canadian-ham-task-33/apps/apple/CanadianHamUITests/CanadianHamLessonFiguresUITests.swift:293: error: -[CanadianHamUITests.CanadianHamLessonFiguresUITests testModule7LessonFigureDarkSample] : failed: caught error: "Error Domain=com.apple.xcode.xctest.accessibilityAudit Code=-56 "Audit failed to complete in time" UserInfo={NSLocalizedDescription=Audit failed to complete in time}"
```


## Targeted unchanged sending-results flake rerun

Log: `/tmp/task-33-sending-results-rerun.log`.

Timing metadata:

```text
start=1792496337
end=1792496545
wall_seconds=208
exit_code=0
```

- `CanadianHamUITests.CanadianHamPracticeUITests`: 1 passed.

| Class | Test | Result | Seconds |
| --- | --- | --- | --- |
| `CanadianHamPracticeUITests` | `testAccessibilityAuditMorseSendingResultsLight` | passed | 91.923 |


## Targeted unchanged Ohms-law dark timeout rerun

Log: `/tmp/task-33-ohms-dark-rerun.log`.

Timing metadata:

```text
start=1792496553
end=1792497806
wall_seconds=1253
exit_code=0
```

- `CanadianHamUITests.CanadianHamPracticeUITests`: 1 passed.

| Class | Test | Result | Seconds |
| --- | --- | --- | --- |
| `CanadianHamPracticeUITests` | `testOhmsLawLessonFiguresAndAccessibilityDark` | passed | 1217.286 |


## Targeted unchanged M7 dark timeout rerun

Log: `/tmp/task-33-m7-dark-rerun.log`.

Timing metadata:

```text
start=1792497848
end=1792498250
wall_seconds=402
exit_code=0
```

- `CanadianHamUITests.CanadianHamLessonFiguresUITests`: 1 passed.

| Class | Test | Result | Seconds |
| --- | --- | --- | --- |
| `CanadianHamLessonFiguresUITests` | `testModule7LessonFigureDarkSample` | passed | 257.999 |
