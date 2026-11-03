# TASK-46.5 internal-review fix validation

Review-fix source commit: `2ae956c7`. Run date: 2026-10-23. This records the requested targeted review checks, not a new merge-batch full-suite claim.

## Review fixes

- Restored TASK-65's two TASK-46.6.1 investigation paragraphs verbatim from fetched `origin/main`, through the Backlog CLI, alongside the three TASK-46.5 paragraphs. A programmatic comparison checked both restored paragraphs byte-for-byte.
- Corrected the exception record and test comment: coordinator decision 2026-10-23 under the owner delegation of 2026-10-22; iPhone light/default-size and dark/largest-Dynamic-Type audits, French reveal/state only, iPad dark audit.
- Made the tvOS numbered prompt and revealed answer separate combined, focusable accessibility elements. The existing toggle stays focusable. The tvOS regression finds both as `staticTexts`, focuses the prompt without revealing the answer, reveals via toggle focus/select, retains toggle focus, then moves actual remote focus to the answer. It passes in both appearances. This is automated accessibility-tree/remote-focus evidence, not a manual VoiceOver session.
- Recast L-004-01 #5, L-004-02 #3 and L-004-03 #4 as transfer checks: filtering after rectification, switching-to-linear microphone operation, and the effect of wider replacement tolerance on timing. Original teaching facts remain unchanged in the body. No new regulatory claims or numeric examples were added.
- Capitalized the five remaining lowercase answer starts; the old lowercase L-004-02 #3 answer was replaced by its new original transfer answer. The scan of all 141 answer blocks found no remaining lowercase starts.
- Added a web regression that parses all 37 real lessons, verifies all 141 pairs in 31 Try-it lessons against independently counted authored prompts/answers, checks numbering/nonempty content, and rejects `:::` in paragraphs.

## Checks

All final checks below exited zero.

| Check | Result |
| --- | --- |
| `pnpm test` | content-tools 244/244; Morse 21/21; calculator 127/127; web 260/260; release/reference gates pass |
| `pnpm typecheck` | All packages and web pass |
| `node packages/content-tools/src/check-lesson-coverage.ts` | 100/100 subsections, 37 lessons, 8 modules; no duplicate coverage |
| `pnpm --dir packages/content-tools check:lesson-originality:all` | 37 lessons against 984 questions; 0 issues, 0 stale allow-list entries |
| `pnpm check:links` | All relative Markdown links verified |
| `pnpm check:hints -- --require-complete` | 984/984 Basic hint files, completeness enabled |
| `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift` | 26/26 tests |
| `pnpm check:apple-l10n` | Text-source self-test, French export, tvOS/visionOS builds and catalogue consistency/stale checks pass; catalogue unchanged |
| `node scripts/check-apple-text-sources.ts` | SwiftUI text localized or explicitly marked |
| `node scripts/check-test-guard.mjs --self-test` | Pass |
| `node scripts/check-test-guard.mjs --base origin/main --head HEAD` | Pass with `TEST_GUARD_PR_BODY` approval markers `Test-guard-approved: owner decision 2026-10-22` and `Test-guard-approved: task-73`; expected pre-existing branch audit findings logged |
| `git diff --check` | Pass |

The first full JS run caught the new regression's stale 36-lesson count (the current library has 37), plus an unchanged IndexedDB v6-upgrade test's 5-second timeout. The assertion was corrected; the full retry passed including that unchanged migration test. Initial typecheck caught the Node filesystem overload's implicit Buffer union; explicit UTF-8 encoding fixed it. Final typecheck and web rerun passed. An earlier focused web invocation hit its command timeout before completion; the subsequent completed full runs above are the acceptance evidence. No unrelated test timeout or assertion was relaxed. jsdom/axe retains the existing non-fatal canvas warning.

## Apple commands and per-test results

Apple runs used `nohup` with grep polling. The existing coordinator figure-plan run held the shared build lock for several hours; all waits were respected and no other build was stopped. These checks ran from the review-fix worktree after the lock became available.

### tvOS — Apple TV 4K (3rd generation)

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamTV -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' -only-testing:CanadianHamTVUITests/CanadianHamTVUITests/testLessonTryItRevealsOnRemoteFocusAndSelectWithAccessibilityLightAndDark -only-testing:CanadianHamTVUITests/CanadianHamTVUITests/testPracticeHintLadderLessonLinkAndAudit test CODE_SIGNING_ALLOWED=NO
```

| Test | Result | Seconds |
| --- | --- | --- |
| `CanadianHamTVUITests.CanadianHamTVUITests.testLessonTryItRevealsOnRemoteFocusAndSelectWithAccessibilityLightAndDark` | PASS | 93.632 |
| `CanadianHamTVUITests.CanadianHamTVUITests.testPracticeHintLadderLessonLinkAndAudit` | PASS | 56.296 |

Log: `/tmp/task-46.5-review-tvos.log`

Result bundle: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-ahvetaoiqlioxlhlgjmdognqogvd/Logs/Test/Test-CanadianHamTV-2026.10.23_19-36-42--0400.xcresult`

### visionOS — Apple Vision Pro

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamVision -destination 'platform=visionOS Simulator,name=Apple Vision Pro' -only-testing:CanadianHamVisionUITests/CanadianHamVisionUITests/testLessonTryItDisclosureAndAccessibilityLightAndDark test CODE_SIGNING_ALLOWED=NO
```

| Test | Result | Seconds |
| --- | --- | --- |
| `CanadianHamVisionUITests.CanadianHamVisionUITests.testLessonTryItDisclosureAndAccessibilityLightAndDark` | PASS | 86.469 |

Log: `/tmp/task-46.5-review-visionos.log`

Result bundle: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-ahvetaoiqlioxlhlgjmdognqogvd/Logs/Test/Test-CanadianHamVision-2026.10.23_19-40-11--0400.xcresult`

### iOS — iPhone 17 Pro

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testLessonTryItRevealAndAccessibilityLight test CODE_SIGNING_ALLOWED=NO
```

| Test | Result | Seconds |
| --- | --- | --- |
| `CanadianHamUITests.CanadianHamPracticeUITests.testLessonTryItRevealAndAccessibilityLight` | PASS | 179.308 |

Log: `/tmp/task-46.5-review-iphone.log`

Result bundle: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-ahvetaoiqlioxlhlgjmdognqogvd/Logs/Test/Test-CanadianHam-2026.10.23_19-43-01--0400.xcresult`

### macOS — arm64 unit suite

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

| Test | Result | Seconds |
| --- | --- | --- |
| `CanadianHamTests.DuoLayoutPolicyTests.testCompactWidthIPhoneKeepsSheetPolicy` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testIPadInspectorRuleRemainsSizeClassDriven` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testMacAndOtherIdiomsNeverUseIPhonePolicy` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` | PASS | 0.000 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds` | PASS | 0.000 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testKeyHandlingProducesEngineDisplayAndSpokenResult` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testOfficialReferenceSheetGateAndBundledPages` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testQuestionCardFocusResetKeepsTextSelectionEnabled` | PASS | 0.004 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekEndsWhenPhoneFullyOpensOrCloses` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekFastUnfoldThroughBandNeverPeeks` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekLeavingToleranceDoesNotResetDismissalSuppression` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset` | PASS | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples` | PASS | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` | PASS | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` | PASS | 0.396 |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute` | PASS | 0.287 |
| `CanadianHamTests.HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` | PASS | 0.002 |
| `CanadianHamTests.HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` | PASS | 2.521 |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata` | PASS | 0.004 |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection` | PASS | 0.003 |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusMapsShuffledSourceChoices` | PASS | 0.004 |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext` | PASS | 0.001 |
| `CanadianHamTests.LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations` | PASS | 0.011 |
| `CanadianHamTests.LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` | PASS | 0.006 |
| `CanadianHamTests.LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides` | PASS | 0.001 |
| `CanadianHamTests.LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish` | PASS | 0.001 |
| `CanadianHamTests.LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale` | PASS | 0.004 |
| `CanadianHamTests.LocalizationCatalogTests.testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testFixedTimingProfilesUseEngineValues` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testLessonBodyAndBulletContrastTokensMeetMinimumRatio` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession` | PASS | 1.747 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints` | PASS | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` | PASS | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesPressWhenAudioFails` | PASS | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReleaseCannotBeSupersededBySilence` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress` | PASS | 0.105 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError` | PASS | 0.115 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears` | PASS | 0.004 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline` | PASS | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsClampAndPreset` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` | PASS | 0.005 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults` | PASS | 0.004 |
| `CanadianHamTests.MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | PASS | 0.046 |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` | PASS | 0.079 |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts` | PASS | 0.025 |
| `CanadianHamTests.ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` | PASS | 0.004 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` | PASS | 0.023 |
| `CanadianHamTests.ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields` | PASS | 0.031 |
| `CanadianHamTests.ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` | PASS | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` | PASS | 0.022 |
| `CanadianHamTests.ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` | PASS | 0.060 |
| `CanadianHamTests.ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem` | PASS | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory` | PASS | 0.071 |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` | PASS | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete` | PASS | 0.027 |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` | PASS | 0.036 |
| `CanadianHamTests.ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent` | PASS | 0.002 |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` | PASS | 0.050 |
| `CanadianHamTests.ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` | PASS | 0.034 |
| `CanadianHamTests.ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` | PASS | 0.052 |
| `CanadianHamTests.ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` | PASS | 0.065 |
| `CanadianHamTests.ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testImportLeavesTask4610Version2LessonSplitRowsUnchanged` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesMixedTask4610SyncRowsByRowVersion` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesTask4610LessonSplitProgressAndQuizAttempts` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress` | PASS | 0.032 |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows` | PASS | 0.041 |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues` | PASS | 0.040 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` | PASS | 0.072 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails` | PASS | 0.045 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` | PASS | 0.036 |
| `CanadianHamTests.ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` | PASS | 0.041 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId` | PASS | 0.040 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` | PASS | 0.036 |
| `CanadianHamTests.ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` | PASS | 0.032 |
| `CanadianHamTests.ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` | PASS | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` | PASS | 0.014 |
| `CanadianHamTests.ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue` | PASS | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` | PASS | 0.009 |
| `CanadianHamTests.ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` | PASS | 0.012 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` | PASS | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` | PASS | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` | PASS | 0.009 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpFixtureValidationAndPayloadRoundTrips` | PASS | 0.137 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix` | PASS | 0.031 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice` | PASS | 2.625 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation` | PASS | 0.009 |
| `CanadianHamTests.ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` | PASS | 0.053 |
| `CanadianHamTests.ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` | PASS | 0.050 |
| `CanadianHamTests.ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` | PASS | 0.034 |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` | PASS | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` | PASS | 0.454 |
| `CanadianHamTests.ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` | PASS | 0.019 |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` | PASS | 0.072 |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` | PASS | 0.080 |
| `CanadianHamTests.ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` | PASS | 0.030 |
| `CanadianHamTests.ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences` | PASS | 0.058 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums` | PASS | 0.040 |
| `CanadianHamTests.ProgressStoreTests.testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender` | PASS | 0.967 |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference` | PASS | 0.019 |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences` | PASS | 0.012 |
| `CanadianHamTests.ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` | PASS | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` | PASS | 0.042 |
| `CanadianHamTests.ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` | PASS | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreRoundTripExportImportReset` | PASS | 0.059 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff` | PASS | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` | PASS | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` | PASS | 0.046 |
| `CanadianHamTests.ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference` | PASS | 0.014 |
| `CanadianHamTests.ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference` | PASS | 0.015 |
| `CanadianHamTests.ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails` | PASS | 0.016 |
| `CanadianHamTests.ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext` | PASS | 1.786 |
| `CanadianHamTests.ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates` | PASS | 0.018 |
| `CanadianHamTests.ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` | PASS | 0.007 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` | PASS | 0.091 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` | PASS | 0.068 |
| `CanadianHamTests.ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` | PASS | 0.032 |
| `CanadianHamTests.ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` | PASS | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices` | PASS | 0.044 |
| `CanadianHamTests.ProgressStoreTests.testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports` | PASS | 0.040 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration` | PASS | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds` | PASS | 0.030 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating` | PASS | 0.106 |
| `CanadianHamTests.ProgressStoreTests.testTask4610SharedConceptMappingAndConceptInclusiveScores` | PASS | 0.247 |
| `CanadianHamTests.ProgressStoreTests.testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows` | PASS | 0.041 |
| `CanadianHamTests.ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` | PASS | 0.056 |
| `CanadianHamTests.QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` | PASS | 0.013 |
| `CanadianHamTests.QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` | PASS | 0.014 |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsNoReadmeFiles` | PASS | 0.013 |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories` | PASS | 0.001 |
| `CanadianHamTests.QuestionBankTests.testBundledJSONDecodesExpectedCounts` | PASS | 0.019 |
| `CanadianHamTests.QuestionBankTests.testBundledLessonModelExposesPrerequisites` | PASS | 0.559 |
| `CanadianHamTests.QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary` | PASS | 0.739 |
| `CanadianHamTests.QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` | PASS | 0.020 |
| `CanadianHamTests.QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` | PASS | 0.079 |
| `CanadianHamTests.QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` | PASS | 0.001 |
| `CanadianHamTests.QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` | PASS | 0.579 |
| `CanadianHamTests.ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours` | PASS | 0.001 |
| `CanadianHamTests.ReadinessAndScoringTests.testExamScoringBoundaries` | PASS | 0.001 |
| `CanadianHamTests.ReadinessAndScoringTests.testReadinessStates` | PASS | 0.001 |
| `CanadianHamTests.ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` | PASS | 0.036 |
| `CanadianHamTests.RootNavigationMappingTests.testCompactHomeSessionAndSectionPushesUseVisibleDestination` | PASS | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testEmptyCompactPathMapsToHome` | PASS | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testEveryLearnRouteRoundTripsWithItsWholeStack` | PASS | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testEveryRootSelectionRoundTrips` | PASS | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts` | PASS | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testPracticeHintLessonStackKeepsSessionAsSplitSelection` | PASS | 0.001 |

Log: `/tmp/task-46.5-review-macos.log`

Result bundle: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-ahvetaoiqlioxlhlgjmdognqogvd/Logs/Test/Test-CanadianHam-2026.10.23_19-47-25--0400.xcresult`

## Scope and residual risks

- tvOS and visionOS run the relevant light/dark lesson audits, not their full suites. iPhone runs the requested light Try-it method once (179.308 s), including both collapsed/expanded full audits; M4 text does not affect its L-005-04 audit fixture.
- iPad, iPhone dark and French were not rerun in this fix round, per the targeted request; prior task evidence remains in the task notes. No audit invocation, handler or shared positioning helper changed in this fix round.
- The existing approved iPad English-light audit limitation remains until TASK-73 can safely measure thin 2x strokes. French remains reveal/state-only; no French audit is claimed.
- The separate coordinator figure-plan result is not included as this worker's run. Review/merge-batch policy and independent reviewer approval remain the coordinator's responsibility. No PR was opened.
- The unchanged inline-answer content-check heuristic remains an acknowledged backstop, as accepted by the reviewer.
