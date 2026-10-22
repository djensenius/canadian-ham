---
id: TASK-60
title: Replace point-width layout thresholds with adaptive SwiftUI layouts
status: Done
assignee:
  - '@worker'
created_date: '2026-10-18 23:49'
updated_date: '2026-10-19 23:48'
labels:
  - apple
  - layout
dependencies: []
priority: high
ordinal: 137000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner decision 2026-10-18: use modern SwiftUI adaptive layouts instead of hard-coded point widths whenever possible. Targets: the iPhone Duo unfolded layout policy (800/780/600 pt thresholds, hysteresis and the window-size measurement plumbing from #286), the iPad/unfolded sidebar collapse width estimates (320/380/420 pt in RootView), and the calculator help-text height threshold (440 pt in CalculatorToolLayout). Prefer system size classes, native .inspector and NavigationSplitView adaptivity, ViewThatFits, containerRelativeFrame and the Layout protocol. API parameters like inspectorColumnWidth, the macOS window minimum and readable-width caps may stay.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The Duo unfolded layout is driven by system size classes and native inspector/NavigationSplitView adaptivity, with no app-defined point-width thresholds or hysteresis; the window-size measurement plumbing is removed if no longer needed
- [x] #2 The sidebar collapse for the exam tools uses NavigationSplitView or other adaptive behaviour instead of estimated column widths
- [x] #3 The calculator layout chooses fitting vs scrolling and help-text visibility via ViewThatFits or another adaptive mechanism instead of point-height thresholds, keeping keys at least 44 pt
- [x] #4 Behaviour on ordinary iPhones, iPad and Mac is unchanged or improved, verified by targeted UI tests and accessibility audits on iPhone 17 Pro, iPhone Duo, iPad Pro 13-inch and macOS unit tests; no tests are weakened
- [x] #5 TASK-54 real-device checks are updated for the size-class-based Duo behaviour
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Replace the Duo unfolded policy with size-class-driven decisions: remove window-size thresholds/hysteresis, root geometry measurement, custom environment plumbing, and DEBUG window-size launch hooks; keep the existing forced-regular iPhone landscape sheet behaviour by preserving compact navigation on compact-vertical phones.\n2. Update RootView sidebar collapse to rely on NavigationSplitView column visibility/style plus size class/exam-tool presentation instead of estimated column widths, preserving the iPad narrow regular-width collapse-and-restore tests.\n3. Refactor CalculatorToolView/CalculatorToolLayout so ViewThatFits selects calculator-with-help, calculator-without-help, then scrollable content, while layout metrics keep 44 pt key targets and accessibility-size scrolling.\n4. Replace threshold/window-size unit and UI tests with size-class policy and DEBUG size-class-change coverage, keep state-preservation and hinge-peek coverage, and update TASK-54 notes for size-class-based real-Duo checks.\n5. Run targeted unit/UI tests and backlog finalization commands with per-test evidence before committing/pushing/opening the PR.

Regression follow-up: reproduce 2–3 iPad exam-tool presentation failures; replace runtime split-style changes with stable native column visibility and restore the user sidebar state; run full iPad ExamTools, targeted iPhone inspector/transitions, and macOS units; record results and update PR #301.

PR #301 final review fixes: parse the DEBUG initial simulated horizontal size class after the runtime override; explicitly start each transition test in its opposite size class and assert the inspector/compact layout mode on iPad as well as phones; gate light/dark inspector audits by actual presentation, keeping full default audit and unchanged exception/shared helpers. Add reopen geometry/hittability checks. Run requested targeted iPhone 17 Pro, iPad Pro 13-inch (M5), iPhone Duo and macOS unit checks via sequential nohup xbuild; update PR body, reply/resolve three threads, append evidence, commit/push and re-request Copilot.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Coordinator completion 2026-10-19 (head 6fb5d9cc): no point-width thresholds remain (grep for unfoldedIPhoneMinimum*/ExitWidth/estimatedSidebarWidth/minimumExamColumnWidth/compactHelpVisibilityHeight/SimulatedWindowSize/isPortrait in app code returns nothing). Duo policy = phone + regular horizontal + non-compact vertical size class; iPad sidebar uses NavigationSplitView .automatic while a tool is open (orientation helper removed); calculator uses ViewThatFits fitting/without-help/scroll, with explicit scroll on compact sheets and phone inspectors, keys at the 46 pt floor (56 pt reverted). Final validation (/tmp/task-60-final3.out HANDOFF4, all exit 0):
- iPhone 17 Pro targeted ExamTools regression set (large-detent calculator audit, both size-class transitions, landscape medium-sheet keys) passed.
- iPhone Duo landscape medium-sheet calculator passed.
- iPad Pro 13 sidebar/inspector passed.
- macOS calculator-layout units passed; text-source check passed.
Earlier full-class runs: iPhone 17 Pro matrix + practice audits + Learn passed; iPad full class only the TASK-61 hinge flake; Duo full class only the known TASK-54 items + TASK-61 flake; Pro Max landscape calculator = TASK-58 (pre-existing on main). TASK-54 updated with size-class real-device checks.

PR #301 regression follow-up: iPad full ExamTools at cccb5e68 failed 24/35 while iPhone passed. Three representative failures queued in /tmp/task-60-ipad-regression-repro.log. The runtime split-style modifier changes structural identity when a tool opens; investigating stable .balanced with temporary native detailOnly and saved sidebar restoration.

Reproduced all three representative iPad failures (keyboard-focus key missing, largest-type Hint missing, regular-width inspector missing): /tmp/task-60-ipad-regression-repro.log, 3 executed/3 failures, xbuild exit 65. Removed runtime split-style branching; NavigationSplitView now stays balanced, with temporary detailOnly on iPad and regular-width iPhone and restoration of the saved user visibility. Inspector scenario retains all geometry/hittability checks, expects temporary sidebar collapse and additionally checks calculator interactivity/value preservation through close/reopen and a second sidebar restoration. Full iPad class + targeted iPhone inspector/transitions + macOS units queued under /tmp/task-60-ipad-regression-checks.out.

iPad full-class follow-up: all tool presentation/accessibility/keyboard-focus regressions passed, but the new hidden-sidebar landscape scenario caught a DEBUG launch-hook race (detailOnly applied in onAppear after split construction). Initialize split visibility @State from that existing launch argument instead; no release-policy change. Only the affected inspector scenario is requeued in /tmp/task-60-ipad-regression-sidebar-retry.log. The full class also encountered the known TASK-61 hinge playback failure at 7.500 vs expected 60.4; no hinge tests changed.

PR #301 iPad regression follow-up complete. Product fix 150bea42bbf0921dee53121cbff9d51067bd3328 keeps NavigationSplitView structurally stable with .balanced; native .detailOnly while an iPad/regular-width phone inspector is open preserves exam space and restores saved visibility on close, including an initially hidden sidebar. No calculator code changed. DEBUG hook follow-up 86088782 initializes existing launch visibility before split construction, fixing the landscape-hidden-sidebar setup race. Inspector coverage retains all geometry/hittability checks and adds interactivity, reopen/value preservation and second restoration in all four visible/hidden portrait/landscape cases.
Validation: old-head reproduction 3/3 failed as expected. Post-fix full iPad ExamTools: 35 executed, 6 existing skips, 2 failures (DEBUG setup race subsequently fixed and targeted retry passed; known TASK-61 hinge playback flake remains at 7.500 vs 60.4). Targeted four-scenario inspector retry: 1 executed/0 failures. iPhone 17 Pro inspector/transitions: 4 executed/1 existing iPad-only skip/0 failures. macOS full units: 177 executed/0 failures. Text-source check, follow-up test guard (base cccb5e68), and git diff --check passed. Logs: /tmp/task-60-ipad-regression-{repro,ipadpro-examtools,sidebar-retry,iphone17pro-inspector-transitions,macos-unit,text-sources}.log; scripts /tmp/task-60-ipad-regression-{repro,checks,sidebar-retry}.sh. Only targeted failed inspector test rerun after the DEBUG-only fix, per review testing policy. Full application suites deferred to merge batch; no tvOS/visionOS runs because these targets do not compile RootView/UI tests. Independent review, Copilot and CI remain merge gates. No test weakening.
Per-test results (full runs and targeted checks; original failing run retained for transparency):
iPad reproduction before fix (cccb5e68): CanadianHamExamToolsUITests FAILED: testCalculatorKeyboardInputIsFocusScoped, testLargestDynamicTypeKeepsHintToolButtonReachable, testRegularWidthUsesInspectorAndKeepsAnswersHittable

iPad Pro 13-inch (M5) full CanadianHamExamToolsUITests (150bea42): CanadianHamExamToolsUITests SKIPPED: testAccessibilityAuditExamToolsDark, testAccessibilityAuditExamToolsLight, testCaptureCalculatorEvidenceScreenshots, testForcedRegularIPhoneLandscapeCalculatorUsesSheetAndKeepsSelection, testForcedRegularIPhoneLandscapeMediumSheetScrollsEveryCalculatorKey, testMockExamQuestionsNavigatorPresentsAfterCalculatorSheet; CanadianHamExamToolsUITests PASSED: testAccessibilityAuditHintedAnswerResultLightAndDark, testAccessibilityAuditHintToolLightAndDark, testCalculatorAutoFocusesHardwareKeyboardOnOpen, testCalculatorKeyboardInputIsFocusScoped, testCalculatorValueResetsForNewMockExam, testCalculatorValueSurvivesCloseAndReopenAndResetsForNewSession, testCompactWidthIPhoneKeepsCompactSheet, testHintToolLadderAndLessonLink, testLargeDetentCalculatorRunsFullAccessibilityAuditLightAndDark, testLargestDynamicTypeKeepsCalculatorGridReachableLightAndDark, testLargestDynamicTypeKeepsHintToolButtonReachable, testMockExamCalculatorKeepsAnswersHittableAndTimerRuns, testMockExamDoesNotExposeHints, testOneLevelHintHasNoSecondHintAffordance, testPracticeCalculatorSheetKeepsAnswersHittableAtMediumDetent, testPreciseScrollPositionsAnswerAboveToolSheet, testReferenceSheetToolHiddenUntilTask44Dot4, testRegularWidthInspectorAccessibilityAuditLightAndDark, testRegularWidthIPhoneUsesInspectorAndKeepsPracticeSelection, testRegularWidthMockExamUsesCalculatorInspectorWithoutHints, testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue, testSimulatedHingeDismissedPeekReopensOnlyAfterReset, testSimulatedHingeFastUnfoldDoesNotPeekHintOneInPractice, testSimulatedHingeNeverPeeksHintOneInMockExam, testSimulatedHingeStableSlightOpenPeeksHintOneInPractice, testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue, testSizeClassRegularInspectorAccessibilityAuditLightAndDark; CanadianHamExamToolsUITests FAILED: testRegularWidthUsesInspectorAndKeepsAnswersHittable, testSimulatedHingePeekStillWorksAfterHintLessonRoundTrip

iPad hidden/visible sidebar inspector retry (86088782): CanadianHamExamToolsUITests PASSED: testRegularWidthUsesInspectorAndKeepsAnswersHittable

iPhone 17 Pro targeted inspector and transitions (86088782): CanadianHamExamToolsUITests PASSED: testRegularWidthIPhoneUsesInspectorAndKeepsPracticeSelection, testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue, testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue; CanadianHamExamToolsUITests SKIPPED: testRegularWidthUsesInspectorAndKeepsAnswersHittable

macOS full unit tests (86088782): DuoLayoutPolicyTests PASSED: testCompactWidthIPhoneKeepsSheetPolicy, testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact, testIPadInspectorRuleRemainsSizeClassDriven, testMacAndOtherIdiomsNeverUseIPhonePolicy, testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy, testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact; ExamCalculatorViewModelTests PASSED: testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp, testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys, testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere, testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds, testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes, testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale, testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString, testKeyHandlingProducesEngineDisplayAndSpokenResult, testQuestionCardFocusResetKeepsTextSelectionEnabled, testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet, testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately; HintSessionStateTests PASSED: testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine, testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer, testHingePeekEndsWhenPhoneFullyOpensOrCloses, testHingePeekFastUnfoldThroughBandNeverPeeks, testHingePeekLeavingToleranceDoesNotResetDismissalSuppression, testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression, testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell, testHingePeekPresentationDismissalSuppressesReopenUntilReset, testHingePeekPresentationImmediateAnswerEndsEligibility, testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset, testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear, testHingePeekPresentationStartsOnlyOnceUntilPostureReset, testHingePeekRecheckPeeksWithoutNewSamples, testHingePeekRequiresStableDwellInSlightOpenBand, testHingePeekSlowCloseThroughBandNeverPeeks, testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek, testHingePeekToleratesSmallJitterOnlyAfterPeekStarts, testHingePeekUnavailableSampleDoesNotResetDismissalSuppression, testHintQualificationMarksUnansweredQuestionAsQualifiedOnly, testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp, testHintVisibilityTimerDoesNotQualifyShortPeekRoute, testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp, testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable, testReviewLaterHintAfterSelectionRecordsHelp, testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission, testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange; LocalizationCatalogTests PASSED: testEveryCatalogKeyHasFrenchTranslations, testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries, testLanguagePreferenceResolvesSystemAndOverrides, testLocalizedNullableTextAndLanguageFallsBackToEnglish, testQuestionBankLoadErrorDescriptionUsesFrenchLocale; MorseTrainerTests PASSED: testCompletedMorseCourseSessionIgnoresResubmittedAnswer, testFixedTimingProfilesUseEngineValues, testLessonBodyAndBulletContrastTokensMeetMinimumRatio, testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp, testMorseAudioSessionStaysActiveUntilLastPlayerReleases, testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins, testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters, testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone, testMorseCourseProgressIgnoresStoredProgressForAnotherCourse, testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition, testMorseExamGeneratorMeetsReceivingExamConstraints, testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime, testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying, testMorseSendingClassifiesTimingAndErrorSignal, testMorseSendingPendingFinalizationHelperCancelsAndClears, testMorseSendingRemainingExamSecondsUsesFixedDeadline, testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters, testMorseSettingsClampAndPreset, testMorseSettingsCodableRoundTripPreservesOutputMode, testMorseSettingsDecodesLegacyPayloadWithIsEnabled, testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast, testMorseSettingsRoundTripThroughUserDefaults, testMorseStopDelayDrainsFadeBeforeStoppingEngine, testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced, testReduceFlashingDecisionUsesInjectedFlags, testReduceFlashingStopsOnlyRunningVisualBeacon, testScheduleMorseVisualPlaybackInitialStateAndFallback; ProgressStoreTests PASSED: testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress, testAdvancedImportRejectsHonoursAttempts, testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch, testAppSettingsModelPublishesMorseSettingsForRootViewSync, testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement, testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows, testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore, testDecodesLegacyBasicExportWithoutBankIdFields, testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme, testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker, testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt, testFreshInstallDefaultsLanguageToSystem, testICloudAccountSignalsUseInitInjectedFactory, testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot, testICloudDeleteCanDeleteLocalDataAfterZoneDelete, testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload, testICloudMergeFixtureIsPermutationIndependentAndIdempotent, testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal, testICloudSyncToggleAndAccountSignalsPreserveLocalProgress, testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing, testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields, testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount, testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons, testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange, testImportOfOlderExportDoesNotRemoveExistingMorseProgress, testImportRejectsInvalidSyncDeviceRows, testImportRejectsUnsupportedLanguagePreferenceValues, testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses, testImportRollbackKeepsExistingDataWhenReplacementFails, testImportRollbackPropagatesMorseProgressRemovalFailure, testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress, testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt, testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues, testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates, testImportValidationRejectsDuplicateMorseDailyActivityDates, testImportValidationRejectsInvalidMorseCourseProgress, testImportValidationRejectsMismatchedScoreBankId, testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt, testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges, testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults, testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference, testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault, testLaunchIgnoresRegisteredAppleLanguagesValue, testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue, testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries, testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun, testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting, testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce, testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure, testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead, testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution, testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution, testMigratesArchivedLessonProgressKeepsMaxOwnReadCount, testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist, testMigratesCommittedPreV2StoreFixtureWithAllDataIntact, testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity, testMigratesProgressStoreV1ToV2WithoutUniqueConstraints, testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields, testMockExamTimerRefreshPreservesFractionalRemainder, testMorseCourseProgressRoundTripsTwentyRecentCharacterResults, testMorseExportMapsHapticsToWebCompatibleAudio, testMorseImportDecodesMissingAndPartialMorsePreferences, testMorseImportRejectsExplicitNullMorseValues, testMorseImportRejectsUnsupportedMorsePreferenceEnums, testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference, testNativeSettingsGeneralBindingsUpdatePracticePreferences, testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows, testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt, testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences, testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse, testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints, testProgressStoreRoundTripExportImportReset, testResetAllDataTurnsICloudSyncOptInOff, testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData, testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure, testResetClearsAppleLanguagesAndLanguagePreference, testResetFailureKeepsPreviousAppleLanguagesAndPreference, testResetRollsBackWhenMorseProgressRemovalFails, testSavingLargeQuestionProgressBatchBuildsOneWriteContext, testSharedAppleSettingsModelAppliesLivePreferenceUpdates, testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules, testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries, testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress, testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists, testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite, testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration, testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync; QuestionBankTests PASSED: testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames, testAdvancedMockExamUsesFiftyQuestionsAndNoHonours, testAppBundleContainsNoReadmeFiles, testAppBundleContainsOnlyExpectedGeneratedBankDirectories, testBundledJSONDecodesExpectedCounts, testBundledLessonModelExposesPrerequisites, testBundledLessonsAndExplanationsLoadThroughContentLibrary, testEngineQuestionDrawKeepsQuestionInsideRequestedCategory, testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion, testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes, testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons; ReadinessAndScoringTests PASSED: testAdvancedScoringAndReadinessSuppressHonours, testExamScoringBoundaries, testReadinessStates, testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate

PR #301 final review round: implemented DEBUG initial simulated size-class parsing (runtime override first), explicit opposite initial classes in both transitions, iPad layout-mode assertions, actual-presentation gating for the full light/dark inspector audit, and reopen geometry/answer-hittability checks. Shared/exception helpers remain byte-identical to 74289f16. iPhone 17 Pro requested 7 tests passed, including all four keyboard-focus/value-reset tests. Both audit appearances correctly detected an actual native sheet and bypassed only inspector auditing. iPad reopen/sidebar test and regular-to-compact transition passed; genuine compact-to-regular exposed an existing assertion-order bug (inspector checked before the existing reopen-if-missing block). Coordinator approved moving the reopen/existence block before the inspector assertion, preserving every assertion and matching the reverse/phone tests; automatic tool continuation is deferred, with the requested note appended to TASK-56. Source commits 06fbd836 and c21d5dd4. Remaining Duo/macOS, supported-geometry iPad audit and failing-transition-only retry are queued via /tmp/task-60-review-final7*.sh and polled with grep; xbuild lock waits are allowed to finish without cancellation.

PR #301 final review validation completed. Initial DEBUG class parsing, actual-presentation inspector audit gating, iPad layout-mode assertions and strengthened reopen geometry/hittability are implemented. All requested targeted checks are green after the approved assertion-order correction; no assertions or shared/exception helpers removed or weakened. iPhone audit test correctly bypassed only actual native sheets; extra iPad light/dark run exercised both full-default inspector audits. TASK-56 tracks automatic tool continuation across transitions; current preserved values survive reopening. Full app suites deferred to merge batch; tvOS/visionOS membership unaffected. Independent review, Copilot and CI remain merge gates. Static checks passed. Logs/scripts: /tmp/task-60-review-final7*.

iPhone 17 Pro: 7 targeted tests:
- PASSED: `CanadianHamExamToolsUITests.testCalculatorAutoFocusesHardwareKeyboardOnOpen` (34.672 seconds)
- PASSED: `CanadianHamExamToolsUITests.testCalculatorKeyboardInputIsFocusScoped` (125.290 seconds)
- PASSED: `CanadianHamExamToolsUITests.testCalculatorValueResetsForNewMockExam` (68.603 seconds)
- PASSED: `CanadianHamExamToolsUITests.testCalculatorValueSurvivesCloseAndReopenAndResetsForNewSession` (117.285 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` (85.581 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` (96.513 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSizeClassRegularInspectorAccessibilityAuditLightAndDark` (80.325 seconds)

iPad Pro 13-inch (M5): initial targeted run (ordering failure retained):
- PASSED: `CanadianHamExamToolsUITests.testRegularWidthUsesInspectorAndKeepsAnswersHittable` (348.260 seconds)
- FAILED: `CanadianHamExamToolsUITests.testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` (32.899 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` (40.095 seconds)

iPhone Duo (27.1): both transitions:
- PASSED: `CanadianHamExamToolsUITests.testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` (50.324 seconds)
- PASSED: `CanadianHamExamToolsUITests.testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` (38.200 seconds)

macOS: full 177-unit suite:
- PASSED: `DuoLayoutPolicyTests.testCompactWidthIPhoneKeepsSheetPolicy` (0.001 seconds)
- PASSED: `DuoLayoutPolicyTests.testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact` (0.001 seconds)
- PASSED: `DuoLayoutPolicyTests.testIPadInspectorRuleRemainsSizeClassDriven` (0.001 seconds)
- PASSED: `DuoLayoutPolicyTests.testMacAndOtherIdiomsNeverUseIPhonePolicy` (0.001 seconds)
- PASSED: `DuoLayoutPolicyTests.testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy` (0.001 seconds)
- PASSED: `DuoLayoutPolicyTests.testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact` (0.000 seconds)
- PASSED: `ExamCalculatorViewModelTests.testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds` (0.000 seconds)
- PASSED: `ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testKeyHandlingProducesEngineDisplayAndSpokenResult` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testQuestionCardFocusResetKeepsTextSelectionEnabled` (0.004 seconds)
- PASSED: `ExamCalculatorViewModelTests.testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet` (0.001 seconds)
- PASSED: `ExamCalculatorViewModelTests.testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately` (0.001 seconds)
- PASSED: `HintSessionStateTests.testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekEndsWhenPhoneFullyOpensOrCloses` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekFastUnfoldThroughBandNeverPeeks` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekLeavingToleranceDoesNotResetDismissalSuppression` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` (0.000 seconds)
- PASSED: `HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` (0.001 seconds)
- PASSED: `HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` (0.400 seconds)
- PASSED: `HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute` (0.290 seconds)
- PASSED: `HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` (0.002 seconds)
- PASSED: `HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` (0.002 seconds)
- PASSED: `HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp` (0.002 seconds)
- PASSED: `HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` (0.002 seconds)
- PASSED: `HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` (2.544 seconds)
- PASSED: `LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations` (0.021 seconds)
- PASSED: `LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` (0.007 seconds)
- PASSED: `LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides` (0.001 seconds)
- PASSED: `LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish` (0.001 seconds)
- PASSED: `LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale` (0.007 seconds)
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
- PASSED: `MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints` (0.003 seconds)
- PASSED: `MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline` (0.000 seconds)
- PASSED: `MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSettingsClampAndPreset` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` (0.006 seconds)
- PASSED: `MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults` (0.006 seconds)
- PASSED: `MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine` (0.001 seconds)
- PASSED: `MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` (0.001 seconds)
- PASSED: `MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags` (0.001 seconds)
- PASSED: `MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon` (0.001 seconds)
- PASSED: `MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback` (0.001 seconds)
- PASSED: `ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` (0.105 seconds)
- PASSED: `ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts` (0.024 seconds)
- PASSED: `ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` (0.004 seconds)
- PASSED: `ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync` (0.001 seconds)
- PASSED: `ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` (0.001 seconds)
- PASSED: `ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` (0.001 seconds)
- PASSED: `ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` (0.019 seconds)
- PASSED: `ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields` (0.033 seconds)
- PASSED: `ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` (0.033 seconds)
- PASSED: `ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` (0.016 seconds)
- PASSED: `ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` (0.059 seconds)
- PASSED: `ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem` (0.010 seconds)
- PASSED: `ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory` (0.079 seconds)
- PASSED: `ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` (0.034 seconds)
- PASSED: `ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete` (0.028 seconds)
- PASSED: `ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` (0.037 seconds)
- PASSED: `ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent` (0.002 seconds)
- PASSED: `ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` (0.001 seconds)
- PASSED: `ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` (0.057 seconds)
- PASSED: `ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` (0.033 seconds)
- PASSED: `ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` (0.040 seconds)
- PASSED: `ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` (0.046 seconds)
- PASSED: `ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` (0.066 seconds)
- PASSED: `ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` (0.036 seconds)
- PASSED: `ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress` (0.035 seconds)
- PASSED: `ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows` (0.043 seconds)
- PASSED: `ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues` (0.039 seconds)
- PASSED: `ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` (0.074 seconds)
- PASSED: `ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails` (0.046 seconds)
- PASSED: `ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure` (0.033 seconds)
- PASSED: `ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` (0.038 seconds)
- PASSED: `ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` (0.036 seconds)
- PASSED: `ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` (0.001 seconds)
- PASSED: `ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` (0.029 seconds)
- PASSED: `ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates` (0.045 seconds)
- PASSED: `ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress` (0.038 seconds)
- PASSED: `ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId` (0.039 seconds)
- PASSED: `ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` (0.035 seconds)
- PASSED: `ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` (0.038 seconds)
- PASSED: `ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` (0.038 seconds)
- PASSED: `ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` (0.012 seconds)
- PASSED: `ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` (0.013 seconds)
- PASSED: `ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue` (0.009 seconds)
- PASSED: `ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` (0.009 seconds)
- PASSED: `ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` (0.011 seconds)
- PASSED: `ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` (0.012 seconds)
- PASSED: `ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` (0.015 seconds)
- PASSED: `ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` (0.008 seconds)
- PASSED: `ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` (0.031 seconds)
- PASSED: `ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` (0.047 seconds)
- PASSED: `ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` (0.050 seconds)
- PASSED: `ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` (0.034 seconds)
- PASSED: `ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` (0.011 seconds)
- PASSED: `ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` (0.032 seconds)
- PASSED: `ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` (0.764 seconds)
- PASSED: `ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` (0.018 seconds)
- PASSED: `ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` (0.067 seconds)
- PASSED: `ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` (0.071 seconds)
- PASSED: `ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder` (0.001 seconds)
- PASSED: `ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` (0.030 seconds)
- PASSED: `ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio` (0.001 seconds)
- PASSED: `ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences` (0.057 seconds)
- PASSED: `ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues` (0.001 seconds)
- PASSED: `ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums` (0.038 seconds)
- PASSED: `ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference` (0.014 seconds)
- PASSED: `ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences` (0.012 seconds)
- PASSED: `ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` (0.040 seconds)
- PASSED: `ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` (0.013 seconds)
- PASSED: `ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` (0.042 seconds)
- PASSED: `ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` (0.034 seconds)
- PASSED: `ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` (0.042 seconds)
- PASSED: `ProgressStoreTests.testProgressStoreRoundTripExportImportReset` (0.063 seconds)
- PASSED: `ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff` (0.016 seconds)
- PASSED: `ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` (0.031 seconds)
- PASSED: `ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` (0.152 seconds)
- PASSED: `ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference` (0.014 seconds)
- PASSED: `ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference` (0.016 seconds)
- PASSED: `ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails` (0.016 seconds)
- PASSED: `ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext` (1.897 seconds)
- PASSED: `ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates` (0.113 seconds)
- PASSED: `ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` (0.001 seconds)
- PASSED: `ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` (0.008 seconds)
- PASSED: `ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` (0.089 seconds)
- PASSED: `ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` (0.062 seconds)
- PASSED: `ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` (0.034 seconds)
- PASSED: `ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` (0.013 seconds)
- PASSED: `ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` (0.056 seconds)
- PASSED: `QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` (0.013 seconds)
- PASSED: `QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` (0.014 seconds)
- PASSED: `QuestionBankTests.testAppBundleContainsNoReadmeFiles` (0.013 seconds)
- PASSED: `QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories` (0.001 seconds)
- PASSED: `QuestionBankTests.testBundledJSONDecodesExpectedCounts` (0.022 seconds)
- PASSED: `QuestionBankTests.testBundledLessonModelExposesPrerequisites` (0.567 seconds)
- PASSED: `QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary` (0.729 seconds)
- PASSED: `QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` (0.020 seconds)
- PASSED: `QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` (0.081 seconds)
- PASSED: `QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` (0.001 seconds)
- PASSED: `QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` (0.565 seconds)
- PASSED: `ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours` (0.001 seconds)
- PASSED: `ReadinessAndScoringTests.testExamScoringBoundaries` (0.001 seconds)
- PASSED: `ReadinessAndScoringTests.testReadinessStates` (0.001 seconds)
- PASSED: `ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` (0.037 seconds)

iPad Pro 13-inch (M5): full-default light/dark inspector audit:
- PASSED: `CanadianHamExamToolsUITests.testSizeClassRegularInspectorAccessibilityAuditLightAndDark` (41.860 seconds)

iPad Pro 13-inch (M5): compact-to-regular ordering-fix retry:
- PASSED: `CanadianHamExamToolsUITests.testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue` (36.993 seconds)
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced point-width/height heuristics with system size classes, native NavigationSplitView/inspector adaptation and ViewThatFits calculator candidates (keys at least 44 pt). Fixed PR #301 iPad inspector regression by keeping a stable balanced split view and temporarily collapsing/restoring native column visibility, preserving hidden-sidebar intent. Strengthened inspector close/reopen and calculator-state coverage. iPad full class rerun, failed sidebar setup corrected and targeted retry green; iPhone targeted tests and 177 macOS units green. Known TASK-61 hinge flake remains; independent review/Copilot/CI pending.

Final PR review fixes complete: DEBUG initial size-class argument implemented, real transitions asserted on iPad and phones, inspector audits gated by actual presentation rather than idiom, and iPad reopen geometry/hittability strengthened. iPhone 17 Pro 7/7, iPhone Duo 2/2, macOS 177/177, supported iPad light/dark inspector audit, and iPad transition/sidebar checks passed after the approved existing-reopen ordering correction. Every assertion retained; shared/exception helpers unchanged. TASK-56 records automatic tool-continuation follow-up; independent/Copilot/CI review remains pending.
<!-- SECTION:FINAL_SUMMARY:END -->
