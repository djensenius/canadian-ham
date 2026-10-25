---
id: TASK-46.7
title: Interleaved review items in lesson quizzes
status: In Progress
assignee:
  - '@worker'
created_date: 2026-10-12 14:57
updated_date: '2026-10-25T01:26:00Z'
labels:
  - web
  - apple
dependencies: []
parent_task_id: TASK-46
priority: medium
ordinal: 105000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Lesson quizzes reuse no earlier material. Add 1-2 review items per lesson quiz drawn from earlier lessons in the recommended order (data-driven, in both the web and Swift engines, with shared fixtures), clearly marked as review.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Each lesson quiz after the first includes 1-2 review items from earlier lessons, deterministic per attempt seed
- [x] #2 TS and Swift engines agree on shared fixtures; the UI marks review items accessibly
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Use Learn recommended lesson order and all active-bank questions in each lesson taught subsections; exclude the current taught pool and quiz IDs. Select up to two seeded reviews from the previous three lessons, then earlier fallback, in pure TS/Swift functions with shared fixtures. 2. Preserve disjoint sorted reviewQuestionIds in web/Apple attempts, schemas, payloads and import/sync; validate incorrect/help IDs against the union. Reject non-empty review IDs on missing/v1 lesson-ID versions before existing 46.10 migration; current v2 attempts pass through unchanged. 3. Append accessible EN/FR source-lesson review headers, existing hint/progress semantics and final M1 Review/Révision round without changing mock exams. 4. Add shared engine, schema, web model/axe/round/resume and Apple unit/UI tests; use the unchanged coordinator-approved composite only for new review audits, leaving all existing helpers/tests unchanged. 5. Commit before nohup validation and poll grep logs: full macOS units plus final-source targeted compile check, TS/Swift parity, 22 distinct UI methods on each requested device, workspace tests/typecheck, schemas/import, web build/URL-CSP, l10n/text and test guard. Record per-test results, finalize verified ACs, push without PR.

Review fixes: 1. Derive web pools from synchronous Basic subsections and regress delayed bank rendering/deterministic IDs. 2. Mark English titles in French review headings, align hint attribution/card count/Basic validation and add legacy empty-review coverage on all platforms. 3. Run requested nohup validation, record per-test results, commit and push without PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Coordinator decisions 2026-10-24: pools are all active-bank official questions in earlier lessons taught subsections; exclude the entire current taught pool plus current quiz IDs. Prefer previous three lessons, then fallback. Incorrect/help ID fields accept officialQuestionIds union reviewQuestionIds. Non-empty review IDs require lessonIdVersion 2; legacy (missing/v1) attempts are rejected before 46.10 migration, while v2 records pass through unchanged. Existing TASK-71/73 composite authorized unchanged only for NEW TASK-46.7 review-item audits; AGENTS.md records dated scope, new test comment cites it; existing helpers/audits stay unchanged. Initial implementation committed as 84753a18; full macOS units and parity queued via nohup behind shared lock, no full Apple app suites requested.

Web and static validation PASS on 3b97481b: pnpm test (content-tools 250/250, Morse 21/21, calculator 127/127, web 278/278); targeted App round/review coverage 12/12 including EN/FR light/dark axe; ProgressStore 43/43; quiz data 5/5; shared TS review fixtures 9/9. pnpm check:schemas 60/60 plus all targets; import:check; typecheck; build:web; Apple text-source gate; test-guard self-test and approved base diff; git diff --check all pass. Initial full web run exposed expected old M1 count assertions plus an unrelated load/upgrade timing flake under concurrent runners; updated M1 assertions now include all review answers (35/35), corrected new French-only test choice lookup, reran final full pnpm test cleanly without weakening existing assertions. Full macOS and requested iPhone/iPad 22 methods/device, parity and l10n checks remain queued behind another task shared xbuild lock.

## Full macOS unit validation

Documented full command PASS, 220 tests / 0 failures. Command: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES. UI-test target compiled; all UIKit-only test imports remain guarded. Log: /tmp/task-46.7-runs/macos.log.

| Test | Result | Seconds |
| --- | --- | --- |
| `CanadianHamTests.DuoLayoutPolicyTests.testCompactWidthIPhoneKeepsSheetPolicy` | PASSED | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact` | PASSED | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testIPadInspectorRuleRemainsSizeClassDriven` | PASSED | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testMacAndOtherIdiomsNeverUseIPhonePolicy` | PASSED | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy` | PASSED | 0.000 |
| `CanadianHamTests.DuoLayoutPolicyTests.testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact` | PASSED | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp` | PASSED | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys` | PASSED | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` | PASSED | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds` | PASSED | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes` | PASSED | 0.000 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale` | PASSED | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString` | PASSED | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testKeyHandlingProducesEngineDisplayAndSpokenResult` | PASSED | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testOfficialReferenceSheetGateAndBundledPages` | PASSED | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testQuestionCardFocusResetKeepsTextSelectionEnabled` | PASSED | 0.004 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet` | PASSED | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekEndsWhenPhoneFullyOpensOrCloses` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekFastUnfoldThroughBandNeverPeeks` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekLeavingToleranceDoesNotResetDismissalSuppression` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility` | PASSED | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset` | PASSED | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples` | PASSED | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand` | PASSED | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks` | PASSED | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` | PASSED | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` | PASSED | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` | PASSED | 0.405 |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute` | PASSED | 0.296 |
| `CanadianHamTests.HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` | PASSED | 0.002 |
| `CanadianHamTests.HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` | PASSED | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` | PASSED | 2.559 |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata` | PASSED | 0.003 |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection` | PASSED | 0.002 |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusMapsShuffledSourceChoices` | PASSED | 0.002 |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext` | PASSED | 0.001 |
| `CanadianHamTests.LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations` | PASSED | 0.015 |
| `CanadianHamTests.LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` | PASSED | 0.004 |
| `CanadianHamTests.LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides` | PASSED | 0.001 |
| `CanadianHamTests.LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish` | PASSED | 0.001 |
| `CanadianHamTests.LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale` | PASSED | 0.003 |
| `CanadianHamTests.LocalizationCatalogTests.testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testFixedTimingProfilesUseEngineValues` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testLessonBodyAndBulletContrastTokensMeetMinimumRatio` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession` | PASSED | 1.672 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` | PASSED | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases` | PASSED | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` | PASSED | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas` | PASSED | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` | PASSED | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` | PASSED | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints` | PASSED | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` | PASSED | 0.106 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal` | PASSED | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesPressWhenAudioFails` | PASSED | 0.005 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended` | PASSED | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError` | PASSED | 0.106 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone` | PASSED | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReleaseCannotBeSupersededBySilence` | PASSED | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress` | PASSED | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError` | PASSED | 0.108 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears` | PASSED | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline` | PASSED | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` | PASSED | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsClampAndPreset` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode` | PASSED | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` | PASSED | 0.014 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults` | PASSED | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | PASSED | 0.041 |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback` | PASSED | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | PASSED | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` | PASSED | 0.076 |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts` | PASSED | 0.025 |
| `CanadianHamTests.ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` | PASSED | 0.003 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync` | PASSED | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` | PASSED | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` | PASSED | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` | PASSED | 0.023 |
| `CanadianHamTests.ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields` | PASSED | 0.031 |
| `CanadianHamTests.ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` | PASSED | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` | PASSED | 0.021 |
| `CanadianHamTests.ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` | PASSED | 0.058 |
| `CanadianHamTests.ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem` | PASSED | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory` | PASSED | 0.066 |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` | PASSED | 0.027 |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete` | PASSED | 0.025 |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` | PASSED | 0.136 |
| `CanadianHamTests.ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent` | PASSED | 0.002 |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` | PASSED | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` | PASSED | 0.048 |
| `CanadianHamTests.ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` | PASSED | 0.034 |
| `CanadianHamTests.ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` | PASSED | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` | PASSED | 0.047 |
| `CanadianHamTests.ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` | PASSED | 0.065 |
| `CanadianHamTests.ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` | PASSED | 0.032 |
| `CanadianHamTests.ProgressStoreTests.testImportLeavesTask4610Version2LessonSplitRowsUnchanged` | PASSED | 0.034 |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesMixedTask4610SyncRowsByRowVersion` | PASSED | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesTask4610LessonSplitProgressAndQuizAttempts` | PASSED | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress` | PASSED | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows` | PASSED | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues` | PASSED | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` | PASSED | 0.072 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails` | PASSED | 0.046 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure` | PASSED | 0.034 |
| `CanadianHamTests.ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` | PASSED | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` | PASSED | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` | PASSED | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` | PASSED | 0.041 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates` | PASSED | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress` | PASSED | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId` | PASSED | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` | PASSED | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` | PASSED | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` | PASSED | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` | PASSED | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` | PASSED | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue` | PASSED | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` | PASSED | 0.009 |
| `CanadianHamTests.ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` | PASSED | 0.012 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` | PASSED | 0.012 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` | PASSED | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` | PASSED | 0.009 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` | PASSED | 0.030 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpFixtureValidationAndPayloadRoundTrips` | PASSED | 0.131 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix` | PASSED | 0.030 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice` | PASSED | 2.602 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation` | PASSED | 0.002 |
| `CanadianHamTests.ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` | PASSED | 0.055 |
| `CanadianHamTests.ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` | PASSED | 0.051 |
| `CanadianHamTests.ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` | PASSED | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testM1QuizRoundBoundariesPreserveOneSessionAnswersHelpAndDismissedCheckpoint` | PASSED | 0.561 |
| `CanadianHamTests.ProgressStoreTests.testM1QuizRoundsRetainEveryItemAndSeededOrderWithinTeachingSections` | PASSED | 0.552 |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` | PASSED | 0.012 |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` | PASSED | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` | PASSED | 0.408 |
| `CanadianHamTests.ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` | PASSED | 0.018 |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` | PASSED | 0.069 |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` | PASSED | 0.076 |
| `CanadianHamTests.ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder` | PASSED | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` | PASSED | 0.030 |
| `CanadianHamTests.ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio` | PASSED | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences` | PASSED | 0.053 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues` | PASSED | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums` | PASSED | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender` | PASSED | 0.965 |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference` | PASSED | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences` | PASSED | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` | PASSED | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` | PASSED | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` | PASSED | 0.045 |
| `CanadianHamTests.ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` | PASSED | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` | PASSED | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreRoundTripExportImportReset` | PASSED | 0.060 |
| `CanadianHamTests.ProgressStoreTests.testQuizRoundsWithConceptChecksKeepTheCompleteUngroupedOrder` | PASSED | 0.542 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff` | PASSED | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` | PASSED | 0.028 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` | PASSED | 0.044 |
| `CanadianHamTests.ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference` | PASSED | 0.014 |
| `CanadianHamTests.ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference` | PASSED | 0.014 |
| `CanadianHamTests.ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails` | PASSED | 0.015 |
| `CanadianHamTests.ProgressStoreTests.testReviewAttemptPayloadImportSyncAndLegacyVersionRejection` | PASSED | 0.056 |
| `CanadianHamTests.ProgressStoreTests.testReviewItemsUseEarlierTaughtPoolsAndFinalM1Round` | PASSED | 1.662 |
| `CanadianHamTests.ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext` | PASSED | 1.730 |
| `CanadianHamTests.ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates` | PASSED | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` | PASSED | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` | PASSED | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` | PASSED | 0.099 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` | PASSED | 0.066 |
| `CanadianHamTests.ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` | PASSED | 0.031 |
| `CanadianHamTests.ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` | PASSED | 0.009 |
| `CanadianHamTests.ProgressStoreTests.testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices` | PASSED | 0.043 |
| `CanadianHamTests.ProgressStoreTests.testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports` | PASSED | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration` | PASSED | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds` | PASSED | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating` | PASSED | 0.101 |
| `CanadianHamTests.ProgressStoreTests.testTask4610SharedConceptMappingAndConceptInclusiveScores` | PASSED | 0.237 |
| `CanadianHamTests.ProgressStoreTests.testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows` | PASSED | 0.040 |
| `CanadianHamTests.ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` | PASSED | 0.055 |
| `CanadianHamTests.QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` | PASSED | 0.012 |
| `CanadianHamTests.QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` | PASSED | 0.013 |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsNoReadmeFiles` | PASSED | 0.014 |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories` | PASSED | 0.001 |
| `CanadianHamTests.QuestionBankTests.testBundledJSONDecodesExpectedCounts` | PASSED | 0.019 |
| `CanadianHamTests.QuestionBankTests.testBundledLessonModelExposesPrerequisites` | PASSED | 0.562 |
| `CanadianHamTests.QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary` | PASSED | 0.751 |
| `CanadianHamTests.QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` | PASSED | 0.020 |
| `CanadianHamTests.QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` | PASSED | 0.081 |
| `CanadianHamTests.QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` | PASSED | 0.001 |
| `CanadianHamTests.QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` | PASSED | 0.585 |
| `CanadianHamTests.ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours` | PASSED | 0.001 |
| `CanadianHamTests.ReadinessAndScoringTests.testExamScoringBoundaries` | PASSED | 0.001 |
| `CanadianHamTests.ReadinessAndScoringTests.testReadinessStates` | PASSED | 0.001 |
| `CanadianHamTests.ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` | PASSED | 0.036 |
| `CanadianHamTests.RootNavigationMappingTests.testCompactHomeSessionAndSectionPushesUseVisibleDestination` | PASSED | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testEmptyCompactPathMapsToHome` | PASSED | 0.000 |
| `CanadianHamTests.RootNavigationMappingTests.testEveryLearnRouteRoundTripsWithItsWholeStack` | PASSED | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testEveryRootSelectionRoundTrips` | PASSED | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts` | PASSED | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testPracticeHintLessonStackKeepsSessionAsSplitSelection` | PASSED | 0.001 |

Engine parity PASS: bash scripts/check-engine-parity.sh ran TypeScript 32/32 and Swift 22/22, including all nine shared review selection cases. iPhone initial run: 21/22 PASS, including all 12 unchanged lesson-quiz methods, all five unchanged M1 methods and four new EN/FR light/dark full review audits. New persistence test failed an immediate disappearance assertion after asynchronous hint-sheet dismissal; corrected only the new test to wait for the exact earlier-lesson heading and assert seeded review ID B-002-007-003 (33e5b247). Production, existing audits and helpers unchanged. Failing-only iPhone rerun, full requested iPad selection and one final-source macOS build-check/unit method are queued. UI test suffix from original first M1 test to EOF is byte-identical to base (SHA256 c0e7bd13eb4a8e90a298aa5103e73dab86f958e2685b9376e0187edd8de02f16).

## iPad Pro 13-inch (M5): targeted validation PASS 22/22

Five new review methods, five unchanged M1-round methods and twelve unchanged lesson-quiz methods. Ran xbuild on one iPad destination, with explicit -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/<method> for every method below. No full app suite. Log: /tmp/task-46.7-runs/pad.log; exact runner: /tmp/task-46.7-ui.sh. Source includes test-only async destination fix 33e5b247.

| Test | Result | Seconds |
| --- | --- | --- |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizConceptCheckHasNoHintOrOtherTools` | PASSED | 17.875 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizConceptOptionCorrectDarkAndFullAccessibilityAudit` | PASSED | 37.305 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizConceptOptionCorrectLightAndFullAccessibilityAudit` | PASSED | 56.021 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizConceptOptionFeedbackLargestDynamicType` | PASSED | 45.086 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit` | PASSED | 35.946 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizConceptOptionIncorrectFrenchFallbackLightAndFullAccessibilityAudit` | PASSED | 35.714 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip` | PASSED | 91.928 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizHintsDarkAndFullAccessibilityAudits` | PASSED | 59.487 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizHintsFrenchAndCurrentLessonRoundTrip` | PASSED | 60.667 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizHintsLightAndFullAccessibilityAudits` | PASSED | 64.235 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizOneLevelHintAndHelpCountPersistsAfterRelaunch` | PASSED | 40.898 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizPostChoiceHintsDoNotChangeSavedHelpAndRelaunchKeepsHelpCount` | PASSED | 48.962 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testM1QuizRoundsDarkAndFullAccessibilityAudits` | PASSED | 90.619 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testM1QuizRoundsFrenchLargestTypeDarkAndFullAccessibilityAudits` | PASSED | 104.202 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testM1QuizRoundsFrenchLargestTypeLightAndFullAccessibilityAudits` | PASSED | 99.997 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testM1QuizRoundsKeepHelpAnswersResumeAndOneSavedAttempt` | PASSED | 226.462 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testM1QuizRoundsLightAndFullAccessibilityAudits` | PASSED | 94.631 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testReviewItemsEnglishDarkAccessibility` | PASSED | 69.496 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testReviewItemsEnglishLightAccessibility` | PASSED | 106.303 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testReviewItemsFrenchLargestTypeDarkAccessibility` | PASSED | 109.439 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testReviewItemsFrenchLargestTypeLightAccessibility` | PASSED | 89.377 |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testReviewItemsOwnLessonResumeScoreHelpAndPersistence` | PASSED | 90.578 |

Final-source macOS build-check + targeted review pool/round method PASS 1/1 after the new UI-test async assertion fix. Full macOS 220/220 remains valid for unchanged production code. All four new iPad review audits and the own-lesson/resume/score/help/persistence method pass; unchanged 17 regression methods also pass. Localization generic visionOS build and failing-only iPhone persistence rerun are the final pending checks.

## iPhone 17 Pro: final targeted validation PASS 22/22 distinct methods

Initial run passed 21/22; only the new async-navigation assertion was corrected. Failing-only persistence recheck PASS 205.448 seconds, with no production/audit/helper change. Every initial passing method remains valid. Commands: /tmp/task-46.7-ui.sh and /tmp/task-46.7-phone-r2.sh, using one named iPhone destination and explicit -only-testing filters. Logs: /tmp/task-46.7-runs/phone.log and phone-r2.log. No full iOS suite.

| Test | Result | Seconds | Log |
| --- | --- | --- | --- |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizConceptCheckHasNoHintOrOtherTools` | PASSED | 24.329 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizConceptOptionCorrectDarkAndFullAccessibilityAudit` | PASSED | 82.427 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizConceptOptionCorrectLightAndFullAccessibilityAudit` | PASSED | 74.081 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizConceptOptionFeedbackLargestDynamicType` | PASSED | 200.057 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit` | PASSED | 77.826 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizConceptOptionIncorrectFrenchFallbackLightAndFullAccessibilityAudit` | PASSED | 80.381 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip` | PASSED | 306.583 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizHintsDarkAndFullAccessibilityAudits` | PASSED | 176.550 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizHintsFrenchAndCurrentLessonRoundTrip` | PASSED | 178.112 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizHintsLightAndFullAccessibilityAudits` | PASSED | 170.854 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizOneLevelHintAndHelpCountPersistsAfterRelaunch` | PASSED | 115.133 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testLessonQuizPostChoiceHintsDoNotChangeSavedHelpAndRelaunchKeepsHelpCount` | PASSED | 128.083 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testM1QuizRoundsDarkAndFullAccessibilityAudits` | PASSED | 190.507 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testM1QuizRoundsFrenchLargestTypeDarkAndFullAccessibilityAudits` | PASSED | 271.876 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testM1QuizRoundsFrenchLargestTypeLightAndFullAccessibilityAudits` | PASSED | 285.001 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testM1QuizRoundsKeepHelpAnswersResumeAndOneSavedAttempt` | PASSED | 415.599 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testM1QuizRoundsLightAndFullAccessibilityAudits` | PASSED | 190.865 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testReviewItemsEnglishDarkAccessibility` | PASSED | 145.772 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testReviewItemsEnglishLightAccessibility` | PASSED | 137.975 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testReviewItemsFrenchLargestTypeDarkAccessibility` | PASSED | 238.098 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testReviewItemsFrenchLargestTypeLightAccessibility` | PASSED | 232.633 | phone.log |
| `CanadianHamUITests.CanadianHamExamToolsUITests.testReviewItemsOwnLessonResumeScoreHelpAndPersistence` | PASSED | 205.448 | phone-r2.log |

## Swift engine parity suite: PASS 22/22

Run by bash scripts/check-engine-parity.sh (TS 32/32 and Swift 22/22). The new LessonReviewTests method reads the same nine fixtures as TS: first, unknown lesson, recent pool, seed variation, fallback, one candidate, no candidates, nearest duplicate attribution, and recent-plus-fallback.

| Test | Result | Seconds |
| --- | --- | --- |
| `CanadianHamEngineTests.FixtureTests.testEveryEngineFixtureMatchesSwiftEngine` | PASSED | 0.027 |
| `CanadianHamEngineTests.FixtureTests.testJSONComparatorRejectsExtraExpectedOutputKey` | PASSED | 0.001 |
| `CanadianHamEngineTests.LessonReviewTests.testSharedLessonReviewFixtures` | PASSED | 0.001 |
| `CanadianHamEngineTests.PCG32Tests.testPCG32SrandomDemoMatchesPublishedCOutputs` | PASSED | 0.001 |
| `CanadianHamEngineTests.ValidationTests.testAdvancedReadinessDoesNotCountExamsBelowSeventyPercent` | PASSED | 0.001 |
| `CanadianHamEngineTests.ValidationTests.testAdvancedReadinessTreatsSeventyPercentPassThresholdAsInclusive` | PASSED | 0.001 |
| `CanadianHamEngineTests.ValidationTests.testApplyAnswerRejectsOutOfRangeLeitnerBoxes` | PASSED | 0.001 |
| `CanadianHamEngineTests.ValidationTests.testBankRulesAcceptFutureSchemaValidBasicIds` | PASSED | 0.001 |
| `CanadianHamEngineTests.ValidationTests.testBankRulesAcceptOnlySchemaValidBasicAndAdvancedIds` | PASSED | 0.001 |
| `CanadianHamEngineTests.ValidationTests.testEngineTimestampInputsRequireCanonicalMillisecondUTCFormat` | PASSED | 0.001 |
| `CanadianHamEngineTests.ValidationTests.testExamGenerationRequiresCanonicalAnswerSourceIndexes` | PASSED | 0.000 |
| `CanadianHamEngineTests.ValidationTests.testFullMockExamGenerationUsesActiveBankSubsectionCount` | PASSED | 0.001 |
| `CanadianHamEngineTests.ValidationTests.testHintedCorrectPreservesAccuracyWithoutMasteryCredit` | PASSED | 0.001 |
| `CanadianHamEngineTests.ValidationTests.testOlderProgressJsonDecodesHelpFieldsAsFalse` | PASSED | 0.001 |
| `CanadianHamEngineTests.ValidationTests.testPracticeExamGenerationDoesNotRequireKnownBankRulesUnlessFullMockIsRequested` | PASSED | 0.000 |
| `CanadianHamEngineTests.ValidationTests.testReadinessRejectsDuplicateSubmittedAtTimestamps` | PASSED | 0.000 |
| `CanadianHamEngineTests.ValidationTests.testScoreExamRejectsUnsupportedBankIds` | PASSED | 0.000 |
| `CanadianHamEngineTests.ValidationTests.testSharedBankRulesFixtureAgreesWithSwiftEngine` | PASSED | 0.002 |
| `CanadianHamEngineTests.ValidationTests.testTimestampAdditionCrossesMonthAndYearBoundaries` | PASSED | 0.001 |
| `CanadianHamEngineTests.ValidationTests.testTimestampFormattingRejectsYearsOutsideCanonicalRange` | PASSED | 0.000 |
| `CanadianHamEngineTests.ValidationTests.testTimestampParserAcceptsLeapDayInLeapYears` | PASSED | 0.000 |
| `CanadianHamEngineTests.ValidationTests.testTimestampParserRejectsImpossibleDatesAndNonAsciiDigits` | PASSED | 0.000 |

All required validation complete. pnpm check:apple-l10n PASS (no catalogue rewrite, SHA256 fbce70ce3a6379189b0132df0ad3437b0cfd1fc8d6cc97923c1de4a9f41bc34d), complete French localization export and generic CanadianHamTV/CanadianHamVision simulator builds PASS. tvOS/visionOS lesson quiz UI is N/A by approved scope; no new surfaces were added. Full iOS/tvOS/visionOS suites, title sweeps and lesson-figure plans were intentionally skipped: assignment requires targeted quiz methods only; category/card/sidebar and lesson/figure rendering are unchanged. New audits alone use the unchanged coordinator-approved TASK-71/73 composite; all original tests/helpers remain byte-identical. Source last changed in 33e5b247; subsequent commits record evidence only. No PR opened; independent review remains required.

Internal review fixes in progress: web review IDs now derive synchronously from Basic subsections, independent of bank text loading; delayed versus undelayed seeded render passes. Added English language runs in French headings, Apple card count including reviews, Basic-only review-ID validation, canonical hint-anchor overlap documentation tests and legacy empty-review import tests (top-level/sync, missing/v1) on web, Apple and schema. Targeted web 15/15 PASS. First full pnpm test hit unchanged v6 upgrade 5-second timeout during concurrent runners; rerunning full suite alone without test weakening. Schema test initially modeled missing version as own undefined JS field; corrected to actually omit it, matching JSON. Other initial checks PASS: import, typecheck, web build/URL audit, text sources and guard self-test. Full macOS queued on shared xbuild lock; chained 25-method/device iPhone/iPad, parity and l10n runners use nohup and grep polling.

Review-fix source commits: 798095c7 (pool race, metadata, count and regression coverage), 5ac4ef35 (compose localized prefix separately from English title), d949ddd9 (assert non-English prefix, allowing Foundation’s correct French language run). Final full pnpm test PASS: content-tools250/250, Morse21/21, calculator127/127, web281/281. Schemas61/61 PASS; import/typecheck/build/URL audit and final text/guard PASS. Full macOS 223 methods: 222 passed; the new heading method exposed attributed interpolation applying English to the entire phrase. Prefix/title composition fixed; failing-only method now PASS on final source (macos-heading-r3.log, 0.006s); all223 distinct methods pass across full run and targeted recheck. Second targeted iteration corrected the test’s overly strict nil-only prefix expectation: Foundation correctly marks the localized prefix French. No existing tests/audits/helpers weakened. iPhone/iPad25 methods each, parity and l10n now running sequentially via /tmp/task-46.7-review-apple-r3.sh.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented deterministic 1–2 earlier-lesson official review items in both engines and on web/iOS/iPadOS/macOS, with taught-pool preference/fallback, accessible EN/FR source labels, final M1 Review/Révision rounds, existing hint/help scoring and question-progress behavior. Added optional disjoint reviewQuestionIds persistence and import/sync validation, legacy-version rejection and v2 migration pass-through. Shared fixtures and regression tests cover selection, scoring, source-lesson resume, help and compatibility. Validation PASS: TS engine32/32, Swift engine22/22, macOS220/220 plus final-source1/1, iPhone22/22 distinct and iPad22/22, full pnpm test (content-tools250/Morse21/calculator127/web278), schemas60/60 across2071 targets, import, typecheck, web build/URL-CSP, unchanged-catalogue Apple localization plus TV/vision builds, text sources, test guard and diff checks. One new UI-only async navigation assertion was corrected and rerun alone successfully. Existing audits/helpers and mock exams unchanged. tvOS/visionOS quiz UI N/A; no full iOS/tvOS/visionOS suites or PR. Per-test Apple/engine results are recorded in notes; independent review remains required.
<!-- SECTION:FINAL_SUMMARY:END -->
