---
id: TASK-78
title: Run the Swift package tests in GitHub CI
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-27T13:24:00Z'
updated_date: '2026-10-27T13:45:00Z'
labels:
  - ci
dependencies: []
priority: medium
ordinal: 163000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The Swift packages (content-swift, engine-swift, morse-swift, calculator-swift) and the Swift half of scripts/check-engine-parity.sh only run locally. TASK-64 showed a content-swift test can fall out of date on main without CI noticing. Run them in CI on Linux (the official Swift Docker image; macOS runners cost about 10x for a private repo). Apple-only imports such as os get minimal canImport guards, with no behaviour change on Apple platforms. Apple app suites stay local (xbuild/simulators).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A CI job runs swift test for every Swift package that can build on Linux, plus the Swift half of the engine-parity check if feasible, triggered when those packages, their fixtures or the content they read change
- [ ] #2 Any package that can't run on Linux is documented with the reason, and the ci.yml local-only comment is updated
- [ ] #3 Source guards are minimal (canImport), the Apple-platform behaviour is unchanged, and local swift test plus the macOS app unit command still pass
- [ ] #4 The job passes on the PR, and a deliberately broken test was shown to fail it (recorded in the notes, then reverted)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect Linux portability and fixture/content inputs for all four Swift packages; verify an official Swift image and Docker availability.
2. Add minimal conditional imports/logging and a path-classified Linux Swift CI job covering all portable packages and engine fixture parity; update local-only documentation.
3. Run Linux and macOS package tests, macOS app unit tests, iOS build-for-testing, pnpm test, and focused workflow/test-guard checks.
4. Commit/push a temporary failing test to a draft verification PR, capture the failing job, revert the assertion and capture the passing run; record evidence, finalize task, commit and push.

5. Approved coordinator refinement: keep content-swift in Linux CI by conditionally compiling its Apple-Foundation Markdown renderer and heading anchors; move only the 10 renderer-dependent tests into one Darwin-only file. Keep all 17 loader/model/validation/front-matter/explanation tests in Linux CI and preserve all 27 tests on macOS.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Docker available via OrbStack. Official swift:6.4 and swift:6.4.1 manifests exist; swift:6.4 currently supplies Swift 6.4.1. Initial Linux run: morse-swift and calculator-swift pass unchanged; engine fixture comparator needs explicit CoreFoundation import. content-swift needs both os logging guards and an Apple-only renderer split because Linux Foundation has no AttributedString(markdown:options:) or MarkdownParsingOptions. Coordinator approved preserving Linux content coverage via a minimal Darwin-only source/test split; no fake Markdown renderer, skips or new dependencies. Before split: macOS content-swift 27/27 tests pass. No package is excluded; only the 10 renderer/heading-anchor tests stay Darwin-only.

Validation so far: all four packages pass in OrbStack Linux swift:6.4 (Swift 6.4.1): content 17/17, engine 22/22 including every engine-parity fixture, morse 4/4, calculator 4/4. Local macOS Swift 6.4: content 27/27 before and after the renderer split (17 loader etc + 10 renderer tests); engine 22/22, morse 4/4, calculator 4/4. A byte-for-byte method comparison confirms all 27 original content test bodies were preserved. pnpm test passes. actionlint 1.7.12 passes; 16 isolated-git classification cases pass (all packages, fixtures, content, workflow/parity script, mixed paths, backlog-only, unrelated web/docs, push and empty-diff fallback). No cache added: all packages have no external dependencies and cold Linux compilation/tests finish in about a minute. macOS app unit and iOS build-for-testing commands are queued through xbuild and waiting safely on the shared lock.

Required red proof: draft PR https://github.com/djensenius/canadian-ham/pull/1042 (workflow only triggers pushes to main or pull requests). Temporary failure commit 5ef95554795cfdfd3d6e882a40cdd7149b2e3618 deliberately expected -1 lessons in ContentLibraryTests.testLoadsRealRepositoryContent. CI run 40513031309, Swift package tests job 122219519485, conclusively failed at Test content-swift: XCTAssertEqual failed (37 is not equal to -1), 17 tests / 1 failure. Job ran 2026-10-27 13:33:35–13:34:31 UTC (~56 seconds). Verified via gh run view plus downloaded job logs. Reverted the assertion using git revert; no deliberate failure remains. Green rerun follows.

Required green proof after revert: CI run 40513662713 at aa296b7f619c211bfc87aa339de0b0d72a6dde2a passed (all three jobs green; Swift package tests job 122221910336). Test guard run 40513662300 also passed. Official swift:6.4 Linux x86_64 tests pass: content 17, engine 22 including every engine fixture, morse 4, calculator 4. Failure run 40513031309 is completed with conclusion failure (Node/content job passed, only the deliberately broken Swift content test failed). Source returned to the already locally validated state. pnpm typecheck also passes. Awaiting Apple xbuild lock, with no build interruptions.

macOS app unit validation: 224/224 tests passed, zero failures, via the documented command (after waiting for the shared lock; no builds interrupted):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

Per-test results (all PASS):
- PASS `DuoLayoutPolicyTests.testCompactWidthIPhoneKeepsSheetPolicy` (0.001 seconds)
- PASS `DuoLayoutPolicyTests.testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact` (0.001 seconds)
- PASS `DuoLayoutPolicyTests.testIPadInspectorRuleRemainsSizeClassDriven` (0.001 seconds)
- PASS `DuoLayoutPolicyTests.testMacAndOtherIdiomsNeverUseIPhonePolicy` (0.001 seconds)
- PASS `DuoLayoutPolicyTests.testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy` (0.001 seconds)
- PASS `DuoLayoutPolicyTests.testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact` (0.001 seconds)
- PASS `ExamCalculatorViewModelTests.testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp` (0.001 seconds)
- PASS `ExamCalculatorViewModelTests.testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys` (0.001 seconds)
- PASS `ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` (0.001 seconds)
- PASS `ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds` (0.001 seconds)
- PASS `ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes` (0.000 seconds)
- PASS `ExamCalculatorViewModelTests.testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale` (0.001 seconds)
- PASS `ExamCalculatorViewModelTests.testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString` (0.001 seconds)
- PASS `ExamCalculatorViewModelTests.testKeyHandlingProducesEngineDisplayAndSpokenResult` (0.001 seconds)
- PASS `ExamCalculatorViewModelTests.testOfficialReferenceSheetGateAndBundledPages` (0.001 seconds)
- PASS `ExamCalculatorViewModelTests.testQuestionCardFocusResetKeepsTextSelectionEnabled` (0.004 seconds)
- PASS `ExamCalculatorViewModelTests.testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet` (0.001 seconds)
- PASS `ExamCalculatorViewModelTests.testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately` (0.001 seconds)
- PASS `HintSessionStateTests.testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine` (0.001 seconds)
- PASS `HintSessionStateTests.testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer` (0.001 seconds)
- PASS `HintSessionStateTests.testHingePeekEndsWhenPhoneFullyOpensOrCloses` (0.001 seconds)
- PASS `HintSessionStateTests.testHingePeekFastUnfoldThroughBandNeverPeeks` (0.001 seconds)
- PASS `HintSessionStateTests.testHingePeekLeavingToleranceDoesNotResetDismissalSuppression` (0.001 seconds)
- PASS `HintSessionStateTests.testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression` (0.001 seconds)
- PASS `HintSessionStateTests.testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell` (0.001 seconds)
- PASS `HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset` (0.001 seconds)
- PASS `HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility` (0.000 seconds)
- PASS `HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` (0.000 seconds)
- PASS `HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` (0.000 seconds)
- PASS `HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset` (0.000 seconds)
- PASS `HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples` (0.001 seconds)
- PASS `HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand` (0.000 seconds)
- PASS `HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks` (0.001 seconds)
- PASS `HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` (0.000 seconds)
- PASS `HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` (0.001 seconds)
- PASS `HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` (0.001 seconds)
- PASS `HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` (0.001 seconds)
- PASS `HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` (0.395 seconds)
- PASS `HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute` (0.292 seconds)
- PASS `HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` (0.002 seconds)
- PASS `HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` (0.001 seconds)
- PASS `HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp` (0.002 seconds)
- PASS `HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` (0.001 seconds)
- PASS `HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` (2.570 seconds)
- PASS `LocalizationCatalogTests.testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata` (0.003 seconds)
- PASS `LocalizationCatalogTests.testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection` (0.002 seconds)
- PASS `LocalizationCatalogTests.testConceptCheckAnswerStatusMapsShuffledSourceChoices` (0.003 seconds)
- PASS `LocalizationCatalogTests.testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext` (0.002 seconds)
- PASS `LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations` (0.014 seconds)
- PASS `LocalizationCatalogTests.testFrenchMorseCopyUsesPointsAndTraitsInBothLocales` (0.006 seconds)
- PASS `LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` (0.003 seconds)
- PASS `LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides` (0.001 seconds)
- PASS `LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish` (0.001 seconds)
- PASS `LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale` (0.001 seconds)
- PASS `LocalizationCatalogTests.testReviewHeadingMarksEnglishFallbackTitleInsideFrenchText` (0.001 seconds)
- PASS `LocalizationCatalogTests.testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench` (0.001 seconds)
- PASS `MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer` (0.001 seconds)
- PASS `MorseTrainerTests.testFixedTimingProfilesUseEngineValues` (0.001 seconds)
- PASS `MorseTrainerTests.testLessonBodyAndBulletContrastTokensMeetMinimumRatio` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession` (1.731 seconds)
- PASS `MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` (0.002 seconds)
- PASS `MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints` (0.002 seconds)
- PASS `MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` (0.001 seconds)
- PASS `MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` (0.003 seconds)
- PASS `MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseSendingKeyerClassifiesPressWhenAudioFails` (0.003 seconds)
- PASS `MorseTrainerTests.testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError` (0.102 seconds)
- PASS `MorseTrainerTests.testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone` (0.005 seconds)
- PASS `MorseTrainerTests.testMorseSendingKeyerReleaseCannotBeSupersededBySilence` (0.004 seconds)
- PASS `MorseTrainerTests.testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress` (0.002 seconds)
- PASS `MorseTrainerTests.testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError` (0.106 seconds)
- PASS `MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseSettingsClampAndPreset` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode` (0.002 seconds)
- PASS `MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled` (0.002 seconds)
- PASS `MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` (0.012 seconds)
- PASS `MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults` (0.004 seconds)
- PASS `MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine` (0.001 seconds)
- PASS `MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` (0.001 seconds)
- PASS `MorseTrainerTests.testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` (0.043 seconds)
- PASS `MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags` (0.001 seconds)
- PASS `MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon` (0.001 seconds)
- PASS `MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback` (0.001 seconds)
- PASS `MorseTrainerTests.testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` (0.040 seconds)
- PASS `ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` (0.080 seconds)
- PASS `ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts` (0.025 seconds)
- PASS `ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` (0.004 seconds)
- PASS `ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync` (0.001 seconds)
- PASS `ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` (0.001 seconds)
- PASS `ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` (0.000 seconds)
- PASS `ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` (0.023 seconds)
- PASS `ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields` (0.031 seconds)
- PASS `ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` (0.030 seconds)
- PASS `ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` (0.025 seconds)
- PASS `ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` (0.060 seconds)
- PASS `ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem` (0.010 seconds)
- PASS `ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory` (0.076 seconds)
- PASS `ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` (0.033 seconds)
- PASS `ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete` (0.027 seconds)
- PASS `ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` (0.040 seconds)
- PASS `ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent` (0.002 seconds)
- PASS `ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` (0.001 seconds)
- PASS `ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` (0.050 seconds)
- PASS `ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` (0.034 seconds)
- PASS `ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` (0.036 seconds)
- PASS `ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` (0.048 seconds)
- PASS `ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` (0.065 seconds)
- PASS `ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` (0.034 seconds)
- PASS `ProgressStoreTests.testImportLeavesTask4610Version2LessonSplitRowsUnchanged` (0.036 seconds)
- PASS `ProgressStoreTests.testImportMigratesMixedTask4610SyncRowsByRowVersion` (0.038 seconds)
- PASS `ProgressStoreTests.testImportMigratesTask4610LessonSplitProgressAndQuizAttempts` (0.037 seconds)
- PASS `ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress` (0.033 seconds)
- PASS `ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows` (0.038 seconds)
- PASS `ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues` (0.039 seconds)
- PASS `ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` (0.072 seconds)
- PASS `ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails` (0.046 seconds)
- PASS `ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure` (0.036 seconds)
- PASS `ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` (0.033 seconds)
- PASS `ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` (0.036 seconds)
- PASS `ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` (0.001 seconds)
- PASS `ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` (0.038 seconds)
- PASS `ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates` (0.039 seconds)
- PASS `ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress` (0.039 seconds)
- PASS `ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId` (0.038 seconds)
- PASS `ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` (0.034 seconds)
- PASS `ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` (0.034 seconds)
- PASS `ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` (0.039 seconds)
- PASS `ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` (0.011 seconds)
- PASS `ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` (0.015 seconds)
- PASS `ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue` (0.009 seconds)
- PASS `ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` (0.009 seconds)
- PASS `ProgressStoreTests.testLegacyEmptyReviewQuestionIdsImportAtTopLevelAndInSyncRows` (0.094 seconds)
- PASS `ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` (0.012 seconds)
- PASS `ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` (0.012 seconds)
- PASS `ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` (0.010 seconds)
- PASS `ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` (0.009 seconds)
- PASS `ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` (0.031 seconds)
- PASS `ProgressStoreTests.testLessonQuizHelpFixtureValidationAndPayloadRoundTrips` (0.141 seconds)
- PASS `ProgressStoreTests.testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix` (0.032 seconds)
- PASS `ProgressStoreTests.testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice` (2.643 seconds)
- PASS `ProgressStoreTests.testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation` (0.002 seconds)
- PASS `ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` (0.061 seconds)
- PASS `ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` (0.052 seconds)
- PASS `ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` (0.033 seconds)
- PASS `ProgressStoreTests.testM1QuizRoundBoundariesPreserveOneSessionAnswersHelpAndDismissedCheckpoint` (0.561 seconds)
- PASS `ProgressStoreTests.testM1QuizRoundsRetainEveryItemAndSeededOrderWithinTeachingSections` (0.554 seconds)
- PASS `ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` (0.012 seconds)
- PASS `ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` (0.033 seconds)
- PASS `ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` (0.424 seconds)
- PASS `ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` (0.019 seconds)
- PASS `ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` (0.072 seconds)
- PASS `ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` (0.073 seconds)
- PASS `ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder` (0.001 seconds)
- PASS `ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` (0.030 seconds)
- PASS `ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio` (0.001 seconds)
- PASS `ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences` (0.056 seconds)
- PASS `ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues` (0.001 seconds)
- PASS `ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums` (0.038 seconds)
- PASS `ProgressStoreTests.testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender` (0.966 seconds)
- PASS `ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference` (0.015 seconds)
- PASS `ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences` (0.011 seconds)
- PASS `ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` (0.039 seconds)
- PASS `ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` (0.012 seconds)
- PASS `ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` (0.041 seconds)
- PASS `ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` (0.038 seconds)
- PASS `ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` (0.040 seconds)
- PASS `ProgressStoreTests.testProgressStoreRoundTripExportImportReset` (0.060 seconds)
- PASS `ProgressStoreTests.testQuizRoundsWithConceptChecksKeepTheCompleteUngroupedOrder` (0.548 seconds)
- PASS `ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff` (0.013 seconds)
- PASS `ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` (0.030 seconds)
- PASS `ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` (0.052 seconds)
- PASS `ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference` (0.013 seconds)
- PASS `ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference` (0.015 seconds)
- PASS `ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails` (0.016 seconds)
- PASS `ProgressStoreTests.testReviewAttemptPayloadImportSyncAndLegacyVersionRejection` (0.058 seconds)
- PASS `ProgressStoreTests.testReviewItemsUseEarlierTaughtPoolsAndFinalM1Round` (1.662 seconds)
- PASS `ProgressStoreTests.testReviewSourceMayDifferFromCanonicalHintLessonWithAuthoredSectionAnchor` (0.552 seconds)
- PASS `ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext` (1.729 seconds)
- PASS `ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates` (0.012 seconds)
- PASS `ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` (0.001 seconds)
- PASS `ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` (0.006 seconds)
- PASS `ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` (0.087 seconds)
- PASS `ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` (0.062 seconds)
- PASS `ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` (0.046 seconds)
- PASS `ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` (0.009 seconds)
- PASS `ProgressStoreTests.testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices` (0.043 seconds)
- PASS `ProgressStoreTests.testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports` (0.039 seconds)
- PASS `ProgressStoreTests.testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration` (0.030 seconds)
- PASS `ProgressStoreTests.testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds` (0.029 seconds)
- PASS `ProgressStoreTests.testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating` (0.111 seconds)
- PASS `ProgressStoreTests.testTask4610SharedConceptMappingAndConceptInclusiveScores` (0.248 seconds)
- PASS `ProgressStoreTests.testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows` (0.040 seconds)
- PASS `ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` (0.056 seconds)
- PASS `QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` (0.012 seconds)
- PASS `QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` (0.013 seconds)
- PASS `QuestionBankTests.testAppBundleContainsNoReadmeFiles` (0.013 seconds)
- PASS `QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories` (0.001 seconds)
- PASS `QuestionBankTests.testBundledJSONDecodesExpectedCounts` (0.019 seconds)
- PASS `QuestionBankTests.testBundledLessonModelExposesPrerequisites` (0.559 seconds)
- PASS `QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary` (0.742 seconds)
- PASS `QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` (0.020 seconds)
- PASS `QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` (0.079 seconds)
- PASS `QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` (0.001 seconds)
- PASS `QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` (0.570 seconds)
- PASS `ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours` (0.001 seconds)
- PASS `ReadinessAndScoringTests.testExamScoringBoundaries` (0.001 seconds)
- PASS `ReadinessAndScoringTests.testReadinessStates` (0.001 seconds)
- PASS `ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` (0.035 seconds)
- PASS `RootNavigationMappingTests.testCompactHomeSessionAndSectionPushesUseVisibleDestination` (0.001 seconds)
- PASS `RootNavigationMappingTests.testEmptyCompactPathMapsToHome` (0.000 seconds)
- PASS `RootNavigationMappingTests.testEveryLearnRouteRoundTripsWithItsWholeStack` (0.001 seconds)
- PASS `RootNavigationMappingTests.testEveryRootSelectionRoundTrips` (0.001 seconds)
- PASS `RootNavigationMappingTests.testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts` (0.001 seconds)
- PASS `RootNavigationMappingTests.testPracticeHintLessonStackKeepsSessionAsSplitSelection` (0.001 seconds)
<!-- SECTION:NOTES:END -->
