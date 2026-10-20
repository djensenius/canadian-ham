---
id: TASK-59
title: Generalize the Dynamic Type accessibility label to all secondary buttons
status: Done
assignee:
  - '@worker'
created_date: '2026-10-18 08:37'
updated_date: '2026-10-20 04:08'
labels:
  - apple
  - accessibility
dependencies:
  - TASK-57
ordinal: 134000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Follow-up from the PR #290 review (TASK-57). The Hint button's visible label already scaled; SwiftUI's synthesized accessibility node lacked font metadata, so the Dynamic Type audit flagged it. Other short-titled AccessibleSecondaryButtonLabel buttons (Next, Done, Play, Previous in StudyViews, MorseCourseView, LearnViews) could hit the same finding in some layouts.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 AccessibleSecondaryButtonLabel (or its style) carries an explicit localized Text accessibility label so every secondary button exposes a scalable label, and the per-call-site label added in TASK-57 is removed if redundant
- [x] #2 testLargestDynamicTypeKeepsHintToolButtonReachable additionally proves the visible Hint text grows (frame height at AX-XXXL greater than at the default size, or a targeted .dynamicType audit)
- [x] #3 Targeted audits on iPhone 17 Pro, iPad and macOS unit tests pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect secondary-label consumers, explicit accessibility overrides, and project target membership; preserve existing localized text and outer overrides.
2. Add the shared Text-backed accessibility label, remove the redundant exam-tool override, and strengthen largest-size Hint coverage with two-launch frame and exact-label assertions.
3. Run focused iPhone and iPad practice audits, exam-tool/hint tests, affected Morse/Learn UI tests, macOS units, and localization/source checks through nohup xbuild with grep-only log polling; run tvOS/visionOS only if target membership requires them.
4. Record per-test evidence, verify the unchanged audit helpers, finalize TASK-59, commit/push the branch, and obtain required independent review before PR creation.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented shared .accessibilityLabel(Text(title)) on AccessibleSecondaryButtonLabel (LocalizedStringKey); removed the redundant exam-tool override. Existing Morse Play/Stop overrides remain on outer Buttons, with exact-label UI assertions. Added exact Previous/Next assertions in Learn and two-launch default-L vs AX-XXXL Hint frame-height comparison. No audit/exception/positioning helpers, visible layout, colours, or localization keys changed.
Target membership: CanadianHam includes the full CanadianHam directory for iOS/macOS. CanadianHamTV and CanadianHamVision list only Design/Tokens.swift, not AccessibleSecondaryButtonStyle.swift or the changed exam-tool views, so their test suites are not affected.
Implementation commit: 0ba702fd0fa95c120c58b4fbd7770d2ae9577e11. Text-source gate and test-guard self-test/base diff check passed. Nohup sequential test runner /tmp/task-59-runs.sh (PID 56658), logs /tmp/task-59-*.log, is queued on the shared xbuild lock; no other builds interrupted. Localization gate reruns in that runner (the initial foreground invocation timed out while waiting on the lock, before export).

Final targeted validation (all run commands are in /tmp/task-59-runs.sh; all six steps exited 0):
- iPhone 17 Pro practice session audits Light/Dark: 2 passed, 0 failures.
- iPhone 17 Pro CanadianHamExamToolsUITests: 35 executed, 32 passed, 3 existing skips, 0 failures; includes the strengthened default-L vs AX-XXXL Hint height assertion (passed, 56.917 s) and all hint audits.
- iPhone 17 Pro Morse/Learn/Mock targeted UI coverage: 10 passed, 0 failures; exact Morse Play/Stop outer override and Learn Previous/Next label assertions passed.
- iPad Pro 13-inch (M5) practice session audits Light/Dark: 2 passed, 0 failures.
- macOS CanadianHamTests: 187 passed, 0 failures.
- pnpm check:apple-l10n: passed, including French export completeness, unchanged catalogue, and generic tvOS/visionOS localization builds. node scripts/check-apple-text-sources.ts, test-guard self-test/base diff check, and git diff --check passed.
Skipped platforms: tvOS/visionOS test suites do not compile any changed file (confirmed in project.yml); their localization builds still passed as part of the localization gate. No full four-platform suites run; those remain the coordinator merge-batch gate.
Existing iPhone ExamTools skips: optional screenshot-capture test; two iPad-only inspector tests. No new skips, exceptions, audit filtering, hidden text, scaling shortcuts, fixed widths, or visual changes.
Latest coordinator steering: do not open a PR; push final SHA for coordinator-owned independent review and PR creation after approval. No PR opened.

Per-test results: iphone-practice (/tmp/task-59-iphone-practice.log)
```text
CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditPracticeSessionDark: passed (130.906 seconds).
CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditPracticeSessionLight: passed (113.752 seconds).
```

Per-test results: iphone-examtools (/tmp/task-59-iphone-examtools.log)
```text
CanadianHamUITests.CanadianHamExamToolsUITests testAccessibilityAuditExamToolsDark: passed (553.315 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testAccessibilityAuditExamToolsLight: passed (585.171 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testAccessibilityAuditHintedAnswerResultLightAndDark: passed (209.600 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testAccessibilityAuditHintToolLightAndDark: passed (92.404 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testCalculatorAutoFocusesHardwareKeyboardOnOpen: passed (18.253 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testCalculatorKeyboardInputIsFocusScoped: passed (155.931 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testCalculatorValueResetsForNewMockExam: passed (121.584 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testCalculatorValueSurvivesCloseAndReopenAndResetsForNewSession: passed (128.046 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testCaptureCalculatorEvidenceScreenshots: skipped (2.688 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testCompactWidthIPhoneKeepsCompactSheet: passed (27.411 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testForcedRegularIPhoneLandscapeCalculatorUsesSheetAndKeepsSelection: passed (102.362 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testForcedRegularIPhoneLandscapeMediumSheetScrollsEveryCalculatorKey: passed (700.757 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testHintToolLadderAndLessonLink: passed (102.578 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testLargeDetentCalculatorRunsFullAccessibilityAuditLightAndDark: passed (80.893 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testLargestDynamicTypeKeepsCalculatorGridReachableLightAndDark: passed (99.469 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testLargestDynamicTypeKeepsHintToolButtonReachable: passed (56.917 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testMockExamCalculatorKeepsAnswersHittableAndTimerRuns: passed (283.445 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testMockExamDoesNotExposeHints: passed (17.820 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testMockExamQuestionsNavigatorPresentsAfterCalculatorSheet: passed (47.677 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testOneLevelHintHasNoSecondHintAffordance: passed (26.121 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testPracticeCalculatorSheetKeepsAnswersHittableAtMediumDetent: passed (111.157 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testPreciseScrollPositionsAnswerAboveToolSheet: passed (163.882 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testReferenceSheetToolHiddenUntilTask44Dot4: passed (20.199 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testRegularWidthInspectorAccessibilityAuditLightAndDark: skipped (0.733 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testRegularWidthIPhoneUsesInspectorAndKeepsPracticeSelection: passed (40.083 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testRegularWidthMockExamUsesCalculatorInspectorWithoutHints: passed (39.869 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testRegularWidthUsesInspectorAndKeepsAnswersHittable: skipped (2.213 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue: passed (66.859 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testSimulatedHingeDismissedPeekReopensOnlyAfterReset: passed (37.221 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testSimulatedHingeFastUnfoldDoesNotPeekHintOneInPractice: passed (13.739 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testSimulatedHingeNeverPeeksHintOneInMockExam: passed (28.979 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testSimulatedHingePeekStillWorksAfterHintLessonRoundTrip: passed (54.010 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testSimulatedHingeStableSlightOpenPeeksHintOneInPractice: passed (25.647 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue: passed (96.886 seconds).
CanadianHamUITests.CanadianHamExamToolsUITests testSizeClassRegularInspectorAccessibilityAuditLightAndDark: passed (51.864 seconds).
```

Per-test results: iphone-morse-learn (/tmp/task-59-iphone-morse-learn.log)
```text
CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditLearnFlowDark: passed (62.143 seconds).
CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditLearnFlowLight: passed (44.220 seconds).
CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMockExamFlowDark: passed (128.224 seconds).
CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMockExamFlowLight: passed (117.105 seconds).
CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseBeaconOutputDark: passed (46.171 seconds).
CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseBeaconOutputLight: passed (43.102 seconds).
CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseCourseLessonAndSummaryDark: passed (454.040 seconds).
CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditMorseCourseLessonAndSummaryLight: passed (533.905 seconds).
CanadianHamUITests.CanadianHamPracticeUITests testLearnUserNavigationOpensLessonQuiz: passed (181.148 seconds).
CanadianHamUITests.CanadianHamPracticeUITests testMorseVisualOutputModeQuickListenOnIOS: passed (61.487 seconds).
```

Per-test results: ipad-practice (/tmp/task-59-ipad-practice.log)
```text
CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditPracticeSessionDark: passed (81.616 seconds).
CanadianHamUITests.CanadianHamPracticeUITests testAccessibilityAuditPracticeSessionLight: passed (66.568 seconds).
```

Per-test results: macos-units (/tmp/task-59-macos-units.log)
```text
CanadianHamTests.DuoLayoutPolicyTests testCompactWidthIPhoneKeepsSheetPolicy: passed (0.001 seconds).
CanadianHamTests.DuoLayoutPolicyTests testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact: passed (0.001 seconds).
CanadianHamTests.DuoLayoutPolicyTests testIPadInspectorRuleRemainsSizeClassDriven: passed (0.001 seconds).
CanadianHamTests.DuoLayoutPolicyTests testMacAndOtherIdiomsNeverUseIPhonePolicy: passed (0.001 seconds).
CanadianHamTests.DuoLayoutPolicyTests testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy: passed (0.001 seconds).
CanadianHamTests.DuoLayoutPolicyTests testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact: passed (0.001 seconds).
CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp: passed (0.001 seconds).
CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys: passed (0.001 seconds).
CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere: passed (0.001 seconds).
CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds: passed (0.001 seconds).
CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes: passed (0.001 seconds).
CanadianHamTests.ExamCalculatorViewModelTests testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale: passed (0.001 seconds).
CanadianHamTests.ExamCalculatorViewModelTests testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString: passed (0.001 seconds).
CanadianHamTests.ExamCalculatorViewModelTests testKeyHandlingProducesEngineDisplayAndSpokenResult: passed (0.001 seconds).
CanadianHamTests.ExamCalculatorViewModelTests testQuestionCardFocusResetKeepsTextSelectionEnabled: passed (0.004 seconds).
CanadianHamTests.ExamCalculatorViewModelTests testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet: passed (0.001 seconds).
CanadianHamTests.ExamCalculatorViewModelTests testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekEndsWhenPhoneFullyOpensOrCloses: passed (0.000 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekFastUnfoldThroughBandNeverPeeks: passed (0.000 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekLeavingToleranceDoesNotResetDismissalSuppression: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekPresentationDismissalSuppressesReopenUntilReset: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekPresentationImmediateAnswerEndsEligibility: passed (0.000 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekPresentationStartsOnlyOnceUntilPostureReset: passed (0.000 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekRecheckPeeksWithoutNewSamples: passed (0.000 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekRequiresStableDwellInSlightOpenBand: passed (0.000 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekSlowCloseThroughBandNeverPeeks: passed (0.000 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek: passed (0.000 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekToleratesSmallJitterOnlyAfterPeekStarts: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testHingePeekUnavailableSampleDoesNotResetDismissalSuppression: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testHintQualificationMarksUnansweredQuestionAsQualifiedOnly: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp: passed (0.397 seconds).
CanadianHamTests.HintSessionStateTests testHintVisibilityTimerDoesNotQualifyShortPeekRoute: passed (0.287 seconds).
CanadianHamTests.HintSessionStateTests testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp: passed (0.002 seconds).
CanadianHamTests.HintSessionStateTests testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable: passed (0.002 seconds).
CanadianHamTests.HintSessionStateTests testReviewLaterHintAfterSelectionRecordsHelp: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission: passed (0.001 seconds).
CanadianHamTests.HintSessionStateTests testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange: passed (2.575 seconds).
CanadianHamTests.LocalizationCatalogTests testEveryCatalogKeyHasFrenchTranslations: passed (0.018 seconds).
CanadianHamTests.LocalizationCatalogTests testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries: passed (0.004 seconds).
CanadianHamTests.LocalizationCatalogTests testLanguagePreferenceResolvesSystemAndOverrides: passed (0.001 seconds).
CanadianHamTests.LocalizationCatalogTests testLocalizedNullableTextAndLanguageFallsBackToEnglish: passed (0.001 seconds).
CanadianHamTests.LocalizationCatalogTests testQuestionBankLoadErrorDescriptionUsesFrenchLocale: passed (0.003 seconds).
CanadianHamTests.MorseTrainerTests testCompletedMorseCourseSessionIgnoresResubmittedAnswer: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testFixedTimingProfilesUseEngineValues: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testLessonBodyAndBulletContrastTokensMeetMinimumRatio: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseAudioSessionStaysActiveUntilLastPlayerReleases: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone: passed (0.002 seconds).
CanadianHamTests.MorseTrainerTests testMorseCourseProgressIgnoresStoredProgressForAnotherCourse: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseExamGeneratorMeetsReceivingExamConstraints: passed (0.002 seconds).
CanadianHamTests.MorseTrainerTests testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseSendingClassifiesTimingAndErrorSignal: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseSendingPendingFinalizationHelperCancelsAndClears: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseSendingRemainingExamSecondsUsesFixedDeadline: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseSettingsClampAndPreset: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseSettingsCodableRoundTripPreservesOutputMode: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseSettingsDecodesLegacyPayloadWithIsEnabled: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast: passed (0.005 seconds).
CanadianHamTests.MorseTrainerTests testMorseSettingsRoundTripThroughUserDefaults: passed (0.003 seconds).
CanadianHamTests.MorseTrainerTests testMorseStopDelayDrainsFadeBeforeStoppingEngine: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testReduceFlashingDecisionUsesInjectedFlags: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testReduceFlashingStopsOnlyRunningVisualBeacon: passed (0.001 seconds).
CanadianHamTests.MorseTrainerTests testScheduleMorseVisualPlaybackInitialStateAndFallback: passed (0.001 seconds).
CanadianHamTests.ProgressStoreTests testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress: passed (0.076 seconds).
CanadianHamTests.ProgressStoreTests testAdvancedImportRejectsHonoursAttempts: passed (0.023 seconds).
CanadianHamTests.ProgressStoreTests testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch: passed (0.003 seconds).
CanadianHamTests.ProgressStoreTests testAppSettingsModelPublishesMorseSettingsForRootViewSync: passed (0.001 seconds).
CanadianHamTests.ProgressStoreTests testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement: passed (0.001 seconds).
CanadianHamTests.ProgressStoreTests testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows: passed (0.001 seconds).
CanadianHamTests.ProgressStoreTests testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore: passed (0.023 seconds).
CanadianHamTests.ProgressStoreTests testDecodesLegacyBasicExportWithoutBankIdFields: passed (0.030 seconds).
CanadianHamTests.ProgressStoreTests testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme: passed (0.028 seconds).
CanadianHamTests.ProgressStoreTests testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker: passed (0.019 seconds).
CanadianHamTests.ProgressStoreTests testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt: passed (0.055 seconds).
CanadianHamTests.ProgressStoreTests testFreshInstallDefaultsLanguageToSystem: passed (0.009 seconds).
CanadianHamTests.ProgressStoreTests testICloudAccountSignalsUseInitInjectedFactory: passed (0.063 seconds).
CanadianHamTests.ProgressStoreTests testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot: passed (0.024 seconds).
CanadianHamTests.ProgressStoreTests testICloudDeleteCanDeleteLocalDataAfterZoneDelete: passed (0.025 seconds).
CanadianHamTests.ProgressStoreTests testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload: passed (0.031 seconds).
CanadianHamTests.ProgressStoreTests testICloudMergeFixtureIsPermutationIndependentAndIdempotent: passed (0.002 seconds).
CanadianHamTests.ProgressStoreTests testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal: passed (0.001 seconds).
CanadianHamTests.ProgressStoreTests testICloudSyncToggleAndAccountSignalsPreserveLocalProgress: passed (0.045 seconds).
CanadianHamTests.ProgressStoreTests testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing: passed (0.033 seconds).
CanadianHamTests.ProgressStoreTests testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields: passed (0.036 seconds).
CanadianHamTests.ProgressStoreTests testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount: passed (0.043 seconds).
CanadianHamTests.ProgressStoreTests testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons: passed (0.063 seconds).
CanadianHamTests.ProgressStoreTests testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange: passed (0.033 seconds).
CanadianHamTests.ProgressStoreTests testImportLeavesTask4610Version2LessonSplitRowsUnchanged: passed (0.037 seconds).
CanadianHamTests.ProgressStoreTests testImportMigratesMixedTask4610SyncRowsByRowVersion: passed (0.046 seconds).
CanadianHamTests.ProgressStoreTests testImportMigratesTask4610LessonSplitProgressAndQuizAttempts: passed (0.038 seconds).
CanadianHamTests.ProgressStoreTests testImportOfOlderExportDoesNotRemoveExistingMorseProgress: passed (0.033 seconds).
CanadianHamTests.ProgressStoreTests testImportRejectsInvalidSyncDeviceRows: passed (0.041 seconds).
CanadianHamTests.ProgressStoreTests testImportRejectsUnsupportedLanguagePreferenceValues: passed (0.039 seconds).
CanadianHamTests.ProgressStoreTests testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses: passed (0.071 seconds).
CanadianHamTests.ProgressStoreTests testImportRollbackKeepsExistingDataWhenReplacementFails: passed (0.043 seconds).
CanadianHamTests.ProgressStoreTests testImportRollbackPropagatesMorseProgressRemovalFailure: passed (0.033 seconds).
CanadianHamTests.ProgressStoreTests testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress: passed (0.032 seconds).
CanadianHamTests.ProgressStoreTests testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt: passed (0.035 seconds).
CanadianHamTests.ProgressStoreTests testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues: passed (0.001 seconds).
CanadianHamTests.ProgressStoreTests testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates: passed (0.038 seconds).
CanadianHamTests.ProgressStoreTests testImportValidationRejectsDuplicateMorseDailyActivityDates: passed (0.038 seconds).
CanadianHamTests.ProgressStoreTests testImportValidationRejectsInvalidMorseCourseProgress: passed (0.039 seconds).
CanadianHamTests.ProgressStoreTests testImportValidationRejectsMismatchedScoreBankId: passed (0.038 seconds).
CanadianHamTests.ProgressStoreTests testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt: passed (0.033 seconds).
CanadianHamTests.ProgressStoreTests testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges: passed (0.032 seconds).
CanadianHamTests.ProgressStoreTests testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults: passed (0.037 seconds).
CanadianHamTests.ProgressStoreTests testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference: passed (0.010 seconds).
CanadianHamTests.ProgressStoreTests testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault: passed (0.013 seconds).
CanadianHamTests.ProgressStoreTests testLaunchIgnoresRegisteredAppleLanguagesValue: passed (0.009 seconds).
CanadianHamTests.ProgressStoreTests testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue: passed (0.009 seconds).
CanadianHamTests.ProgressStoreTests testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries: passed (0.011 seconds).
CanadianHamTests.ProgressStoreTests testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun: passed (0.012 seconds).
CanadianHamTests.ProgressStoreTests testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting: passed (0.010 seconds).
CanadianHamTests.ProgressStoreTests testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce: passed (0.009 seconds).
CanadianHamTests.ProgressStoreTests testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure: passed (0.031 seconds).
CanadianHamTests.ProgressStoreTests testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead: passed (0.045 seconds).
CanadianHamTests.ProgressStoreTests testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution: passed (0.050 seconds).
CanadianHamTests.ProgressStoreTests testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution: passed (0.033 seconds).
CanadianHamTests.ProgressStoreTests testMigratesArchivedLessonProgressKeepsMaxOwnReadCount: passed (0.011 seconds).
CanadianHamTests.ProgressStoreTests testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist: passed (0.033 seconds).
CanadianHamTests.ProgressStoreTests testMigratesCommittedPreV2StoreFixtureWithAllDataIntact: passed (0.317 seconds).
CanadianHamTests.ProgressStoreTests testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity: passed (0.016 seconds).
CanadianHamTests.ProgressStoreTests testMigratesProgressStoreV1ToV2WithoutUniqueConstraints: passed (0.072 seconds).
CanadianHamTests.ProgressStoreTests testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields: passed (0.078 seconds).
CanadianHamTests.ProgressStoreTests testMockExamTimerRefreshPreservesFractionalRemainder: passed (0.001 seconds).
CanadianHamTests.ProgressStoreTests testMorseCourseProgressRoundTripsTwentyRecentCharacterResults: passed (0.030 seconds).
CanadianHamTests.ProgressStoreTests testMorseExportMapsHapticsToWebCompatibleAudio: passed (0.001 seconds).
CanadianHamTests.ProgressStoreTests testMorseImportDecodesMissingAndPartialMorsePreferences: passed (0.053 seconds).
CanadianHamTests.ProgressStoreTests testMorseImportRejectsExplicitNullMorseValues: passed (0.001 seconds).
CanadianHamTests.ProgressStoreTests testMorseImportRejectsUnsupportedMorsePreferenceEnums: passed (0.037 seconds).
CanadianHamTests.ProgressStoreTests testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference: passed (0.012 seconds).
CanadianHamTests.ProgressStoreTests testNativeSettingsGeneralBindingsUpdatePracticePreferences: passed (0.011 seconds).
CanadianHamTests.ProgressStoreTests testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows: passed (0.036 seconds).
CanadianHamTests.ProgressStoreTests testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt: passed (0.010 seconds).
CanadianHamTests.ProgressStoreTests testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences: passed (0.038 seconds).
CanadianHamTests.ProgressStoreTests testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse: passed (0.035 seconds).
CanadianHamTests.ProgressStoreTests testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints: passed (0.036 seconds).
CanadianHamTests.ProgressStoreTests testProgressStoreRoundTripExportImportReset: passed (0.056 seconds).
CanadianHamTests.ProgressStoreTests testResetAllDataTurnsICloudSyncOptInOff: passed (0.011 seconds).
CanadianHamTests.ProgressStoreTests testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData: passed (0.029 seconds).
CanadianHamTests.ProgressStoreTests testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure: passed (0.142 seconds).
CanadianHamTests.ProgressStoreTests testResetClearsAppleLanguagesAndLanguagePreference: passed (0.013 seconds).
CanadianHamTests.ProgressStoreTests testResetFailureKeepsPreviousAppleLanguagesAndPreference: passed (0.014 seconds).
CanadianHamTests.ProgressStoreTests testResetRollsBackWhenMorseProgressRemovalFails: passed (0.014 seconds).
CanadianHamTests.ProgressStoreTests testSavingLargeQuestionProgressBatchBuildsOneWriteContext: passed (1.799 seconds).
CanadianHamTests.ProgressStoreTests testSharedAppleSettingsModelAppliesLivePreferenceUpdates: passed (0.113 seconds).
CanadianHamTests.ProgressStoreTests testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules: passed (0.001 seconds).
CanadianHamTests.ProgressStoreTests testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries: passed (0.010 seconds).
CanadianHamTests.ProgressStoreTests testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress: passed (0.089 seconds).
CanadianHamTests.ProgressStoreTests testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists: passed (0.059 seconds).
CanadianHamTests.ProgressStoreTests testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite: passed (0.030 seconds).
CanadianHamTests.ProgressStoreTests testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration: passed (0.009 seconds).
CanadianHamTests.ProgressStoreTests testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices: passed (0.042 seconds).
CanadianHamTests.ProgressStoreTests testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports: passed (0.036 seconds).
CanadianHamTests.ProgressStoreTests testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration: passed (0.030 seconds).
CanadianHamTests.ProgressStoreTests testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds: passed (0.033 seconds).
CanadianHamTests.ProgressStoreTests testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating: passed (0.096 seconds).
CanadianHamTests.ProgressStoreTests testTask4610SharedConceptMappingAndConceptInclusiveScores: passed (0.226 seconds).
CanadianHamTests.ProgressStoreTests testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows: passed (0.037 seconds).
CanadianHamTests.ProgressStoreTests testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync: passed (0.053 seconds).
CanadianHamTests.QuestionBankTests testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames: passed (0.012 seconds).
CanadianHamTests.QuestionBankTests testAdvancedMockExamUsesFiftyQuestionsAndNoHonours: passed (0.013 seconds).
CanadianHamTests.QuestionBankTests testAppBundleContainsNoReadmeFiles: passed (0.013 seconds).
CanadianHamTests.QuestionBankTests testAppBundleContainsOnlyExpectedGeneratedBankDirectories: passed (0.001 seconds).
CanadianHamTests.QuestionBankTests testBundledJSONDecodesExpectedCounts: passed (0.019 seconds).
CanadianHamTests.QuestionBankTests testBundledLessonModelExposesPrerequisites: passed (0.555 seconds).
CanadianHamTests.QuestionBankTests testBundledLessonsAndExplanationsLoadThroughContentLibrary: passed (0.697 seconds).
CanadianHamTests.QuestionBankTests testEngineQuestionDrawKeepsQuestionInsideRequestedCategory: passed (0.020 seconds).
CanadianHamTests.QuestionBankTests testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion: passed (0.080 seconds).
CanadianHamTests.QuestionBankTests testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes: passed (0.001 seconds).
CanadianHamTests.QuestionBankTests testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons: passed (0.562 seconds).
CanadianHamTests.ReadinessAndScoringTests testAdvancedScoringAndReadinessSuppressHonours: passed (0.001 seconds).
CanadianHamTests.ReadinessAndScoringTests testExamScoringBoundaries: passed (0.001 seconds).
CanadianHamTests.ReadinessAndScoringTests testReadinessStates: passed (0.001 seconds).
CanadianHamTests.ReadinessAndScoringTests testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate: passed (0.034 seconds).
```
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Generalized TASK-57’s localized Text-backed accessibility metadata into AccessibleSecondaryButtonLabel and removed the exam-tool call-site duplicate without changing visible UI. Strengthened the largest-size Hint test to prove its frame grows from default L to AX-XXXL, and verified exact Morse outer overrides and Learn Previous/Next labels. Targeted validation passed: iPhone practice 2/0, ExamTools 35 executed (3 existing skips)/0, Morse/Learn/Mock 10/0; iPad practice 2/0; macOS units 187/0; localization/text-source/test-guard gates passed. Audit/exception helpers are untouched. Coordinator owns independent review and subsequent PR creation; nothing merged.
<!-- SECTION:FINAL_SUMMARY:END -->
