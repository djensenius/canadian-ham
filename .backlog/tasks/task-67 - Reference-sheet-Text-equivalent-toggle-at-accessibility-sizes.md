---
id: TASK-67
title: Reference sheet Text equivalent toggle at accessibility sizes
status: Done
assignee:
  - '@worker'
created_date: '2026-10-22 03:34'
updated_date: '2026-10-24 22:10'
labels:
  - accessibility
  - tests
dependencies: []
modified_files:
  - apps/apple/CanadianHam/ExamTools/ExamToolViews.swift
  - apps/apple/CanadianHamUITests/CanadianHamExamToolsUITests.swift
ordinal: 147000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-44.4 review note: in the stacked accessibility-size layout VoiceOver reads 'Text equivalent' twice (visible text then switch) and tapping the text does not toggle; no test taps the switch at AX sizes. Also the medium-detent test's local textClipped handler hits its cap of 5 every run; list the ignored elements and consider a test-stable layout.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 At accessibility sizes the toggle exposes one accessible element with its label, the label is tappable, and a UI test toggles it at AX-XXXL
- [x] #2 The medium-detent test's ignored findings are listed in the task notes; the cap has headroom or the cause is reduced
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the reference toggle and scoped medium audit; preserve the approved audit rules and default-size appearance.
2. Implement a single native labelled Toggle with an adaptive accessibility-size layout; add AX-XXXL label-tap, single-element and state coverage.
3. Inventory medium-detent ignored findings and reduce their cause or provide bounded headroom without widening exception eligibility.
4. Run targeted iPhone/iPad reference-sheet tests, documented macOS unit command, localization, text-source and test-guard checks via nohup/polling. Record per-test evidence, complete ACs, commit and push without opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented a native labelled Toggle with a custom accessibility-size style: stacked visible label/native switch, tappable label, one native accessibility representation. Default-size switch remains native. AX-XXXL now checks one switch, exact label/no duplicate static text, and taps the label on/off with state/content assertions. Medium audit eligibility is unchanged; bounded cap 5→8 adds three findings of headroom, and each accepted finding now records identifier, label and frame in a keepAlways attachment. Targeted iPhone/iPad, documented macOS unit command, l10n/text/guard runner started with nohup (/tmp/task67-checks.log); no full simulator suites.

First iPhone pass: matrix PASS (259.739s), medium PASS (118.246s) with five findings and three findings of cap headroom. Inventory: reference-sheet-version-title / Official sheet; reference-sheet-page-number / Page 1 of 5; three nil-element findings (two generic element and one SwiftUI.AccessibilityNode, no identifiers supplied by XCTest). Named frames/labels and all nil descriptions are retained in keepAlways attachments and /tmp/task67-iphone.log. Initial AX test stopped at the over-strict zero-StaticText assertion: native labelled Toggles expose an internal StaticText child. Refined regression to require every matching label to be inside the one switch (no separate external label/focus stop), preserving exact-label, count, label-tap/state/content checks, and retaining the switch hierarchy attachment. Targeted AX-only reruns queued on both devices; iPad matrix/medium and macOS/l10n runner continue without interruption.

After the shared build lock released, the documented macOS unit command passed 215/215 and built the UI-test target. The next iPhone AX-only attempt exposed simulator-language contamination from another task (Équivalent textuel rather than the expected English label); it stopped before label taps. Pinned this English AX regression to AppleLanguages=(en), AppleLocale=en_CA rather than relying on inherited simulator language. Final iPhone AX rerun plus macOS affected-unit/UI-test-compilation check queued; already-queued iPad AX will build the pinned-language source. No app code or audit eligibility changed in this setup fix.

FINAL VALIDATION — 2026-10-24

Source commit: f33df5abb94ec35ca45e2b7cc32ed2f81a949d34; branch task-67-sheet-toggle-ax. All final requested checks PASS, accumulated across targeted fix rounds. The first iPhone AX attempt failed an over-strict zero-StaticText assertion; the next inherited French simulator language. Both setup issues are recorded above and fixed. Final iPhone/iPad AX tests verify an exact English native-switch label, no same-text label outside that switch, and physical label-coordinate taps on/off with switch-value and official text/image state assertions. Native accessibility hierarchy attachments are keepAlways. There was no manual physical-device VoiceOver listening session; the evidence is native semantics plus simulator accessibility-tree and interaction assertions.

AC1 evidence: ReferenceSheetTextEquivalentToggleStyle uses the actual Toggle label, stacks only at semantic accessibility Dynamic Type sizes, gives the visible label a tap action, and supplies one native Toggle accessibility representation. Default size still uses the platform's automatic native Toggle style. No point-based layout thresholds or new strings/catalogue changes. iPhone AX-XXXL PASS (142.339s); iPad AX-XXXL PASS (45.700s).

AC2 final inventory from the medium audit (/tmp/task67-iphone.log), each retained with a keepAlways finding attachment:
1. nil element; generic element textClipped description; XCTest supplies no identifier/label/frame.
2. nil element; generic element textClipped description; XCTest supplies no identifier/label/frame.
3. nil element; SwiftUI.AccessibilityNode textClipped description; XCTest supplies no identifier/label/frame.
4. reference-sheet-page-number, label “Page 1 of 5”, frame x=23.3632 y=694.4444 width=83.5373 height=19.5240.
5. reference-sheet-version-title, label “Official sheet”, frame x=23.3632 y=563.5373 width=101.1410 height=19.5240.
The cap is now eight, leaving three findings of headroom at the observed count of five. This is bounded headroom, not a new exception: iPhone-only, medium asserted immediately before audit, textClipped-only; named elements must remain descendants of the explicit reference-sheet-scroll, missing scroll fails, nil elements use the existing approved rule. All other issue types still fail. No shared audit/positioning helpers or TASK-71/73 measured-contrast code changed.

Apple UI per-test results (CanadianHamUITests.CanadianHamExamToolsUITests):
- iPhone 17 Pro: testOfficialReferenceSheetLightAndDarkEnglishAndFrench PASS (259.739s).
- iPhone 17 Pro: testOfficialReferenceSheetMediumDetentControlsAndShowFullSheet PASS (118.246s), 5/8 approved findings.
- iPhone 17 Pro: testReferenceSheetLargestDynamicTypeKeepsControlsReachable PASS (142.339s), final pinned-English test.
- iPad Pro 13-inch (M5): testOfficialReferenceSheetLightAndDarkEnglishAndFrench PASS (184.032s).
- iPad Pro 13-inch (M5): testReferenceSheetLargestDynamicTypeKeepsControlsReachable PASS (45.700s), final pinned-English test. Earlier same-source behavior pass before locale pin: 39.761s.
- iPad Pro 13-inch (M5): testOfficialReferenceSheetMediumDetentControlsAndShowFullSheet SKIPPED by its existing unchanged iPhone-only guard (0.669s); iPad uses the inspector matrix instead of a medium sheet.

macOS: the documented unit command passed 215/215 and built CanadianHamUITests. After the final test-only locale pin, the same platform/signing command with only ExamCalculatorViewModelTests passed 12/12 and rebuilt the changed UI-test source. Per-test results follow below.

Other checks:
- pnpm check:apple-l10n PASS; French export complete, catalogue unchanged, tvOS and visionOS localization builds PASS.
- node scripts/check-apple-text-sources.ts PASS.
- node scripts/check-test-guard.mjs --self-test PASS.
- TEST_GUARD_PR_BODY='Test-guard-approved: task-67' node scripts/check-test-guard.mjs --base origin/main --head HEAD PASS with intentional medium-test handler/function findings. Without the marker the guard correctly fails on those two ranges. Eventual PR needs exactly Test-guard-approved: task-67 on its own line, and reviewer verification of the unchanged eligibility / approved headroom and logging diff.
- git diff origin/main --check PASS; no staged files.

Commands used (all Apple commands through xbuild, DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer; nohup runners with grep polling, one destination per run; no builds killed):
- xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testOfficialReferenceSheetLightAndDarkEnglishAndFrench -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testReferenceSheetLargestDynamicTypeKeepsControlsReachable -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testOfficialReferenceSheetMediumDetentControlsAndShowFullSheet test CODE_SIGNING_ALLOWED=NO
- Same three selectors and flags with destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'.
- Final AX-only fix rounds on each of those destinations: xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination '<destination above>' -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testReferenceSheetLargestDynamicTypeKeepsControlsReachable test CODE_SIGNING_ALLOWED=NO
- xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
- Final macOS compile / relevant-unit rerun: same command with -only-testing:CanadianHamTests/ExamCalculatorViewModelTests.
- pnpm check:apple-l10n; node scripts/check-apple-text-sources.ts; node scripts/check-test-guard.mjs --self-test; approved branch-diff guard command above; git diff origin/main --check.

Logs: /tmp/task67-checks.log, /tmp/task67-iphone.log, /tmp/task67-ipad.log, /tmp/task67-iphone-ax-final.log, /tmp/task67-ipad-ax.log, /tmp/task67-macos.log, /tmp/task67-macos-final.log, /tmp/task67-l10n.log, /tmp/task67-text-sources.log, /tmp/task67-guard-self-test.log, /tmp/task67-guard-approved.log. Final AX xcresults: Test-CanadianHam-2026.10.24_17-56-52--0400.xcresult (iPhone) and Test-CanadianHam-2026.10.24_17-54-04--0400.xcresult (iPad), under /Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-bekmdsdcnnfszpepwvceaowrzcuo/Logs/Test/.

No full simulator suites ran. tvOS/visionOS test suites skipped because neither target compiles ExamToolViews.swift or offers this reference tool (project.yml membership checked); their localization builds passed. No web/package code changed, so web/package suites were not run. No PR, TestFlight build/upload or public distribution. Independent branch/commit review is still required.

Documented macOS unit command — 215 individual PASS results:
- CanadianHamTests.DuoLayoutPolicyTests.testCompactWidthIPhoneKeepsSheetPolicy: PASS (0.001 seconds).
- CanadianHamTests.DuoLayoutPolicyTests.testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact: PASS (0.001 seconds).
- CanadianHamTests.DuoLayoutPolicyTests.testIPadInspectorRuleRemainsSizeClassDriven: PASS (0.001 seconds).
- CanadianHamTests.DuoLayoutPolicyTests.testMacAndOtherIdiomsNeverUseIPhonePolicy: PASS (0.001 seconds).
- CanadianHamTests.DuoLayoutPolicyTests.testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy: PASS (0.001 seconds).
- CanadianHamTests.DuoLayoutPolicyTests.testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact: PASS (0.000 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes: PASS (0.000 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString: PASS (0.003 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testKeyHandlingProducesEngineDisplayAndSpokenResult: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testOfficialReferenceSheetGateAndBundledPages: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testQuestionCardFocusResetKeepsTextSelectionEnabled: PASS (0.004 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately: PASS (0.001 seconds).
- CanadianHamTests.HintSessionStateTests.testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine: PASS (0.001 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer: PASS (0.001 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekEndsWhenPhoneFullyOpensOrCloses: PASS (0.001 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekFastUnfoldThroughBandNeverPeeks: PASS (0.000 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekLeavingToleranceDoesNotResetDismissalSuppression: PASS (0.001 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression: PASS (0.001 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell: PASS (0.001 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset: PASS (0.001 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility: PASS (0.002 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset: PASS (0.000 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear: PASS (0.000 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset: PASS (0.000 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples: PASS (0.000 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand: PASS (0.001 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks: PASS (0.002 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek: PASS (0.000 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts: PASS (0.000 seconds).
- CanadianHamTests.HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression: PASS (0.001 seconds).
- CanadianHamTests.HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly: PASS (0.001 seconds).
- CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp: PASS (0.390 seconds).
- CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute: PASS (0.288 seconds).
- CanadianHamTests.HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp: PASS (0.002 seconds).
- CanadianHamTests.HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable: PASS (0.002 seconds).
- CanadianHamTests.HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp: PASS (0.002 seconds).
- CanadianHamTests.HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission: PASS (0.001 seconds).
- CanadianHamTests.HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange: PASS (2.518 seconds).
- CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata: PASS (0.003 seconds).
- CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection: PASS (0.001 seconds).
- CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusMapsShuffledSourceChoices: PASS (0.001 seconds).
- CanadianHamTests.LocalizationCatalogTests.testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext: PASS (0.001 seconds).
- CanadianHamTests.LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations: PASS (0.007 seconds).
- CanadianHamTests.LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries: PASS (0.004 seconds).
- CanadianHamTests.LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides: PASS (0.001 seconds).
- CanadianHamTests.LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish: PASS (0.000 seconds).
- CanadianHamTests.LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale: PASS (0.003 seconds).
- CanadianHamTests.LocalizationCatalogTests.testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testFixedTimingProfilesUseEngineValues: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testLessonBodyAndBulletContrastTokensMeetMinimumRatio: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession: PASS (1.710 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone: PASS (0.004 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse: PASS (0.002 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition: PASS (0.002 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints: PASS (0.003 seconds).
- CanadianHamTests.MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying: PASS (0.004 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesPressWhenAudioFails: PASS (0.003 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError: PASS (0.106 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone: PASS (0.004 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReleaseCannotBeSupersededBySilence: PASS (0.004 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress: PASS (0.105 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError: PASS (0.108 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears: PASS (0.002 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline: PASS (0.002 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters: PASS (0.002 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSettingsClampAndPreset: PASS (0.002 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode: PASS (0.002 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled: PASS (0.002 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast: PASS (0.012 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults: PASS (0.004 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess: PASS (0.045 seconds).
- CanadianHamTests.MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback: PASS (0.001 seconds).
- CanadianHamTests.MorseTrainerTests.testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess: PASS (0.041 seconds).
- CanadianHamTests.ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress: PASS (0.081 seconds).
- CanadianHamTests.ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts: PASS (0.025 seconds).
- CanadianHamTests.ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch: PASS (0.005 seconds).
- CanadianHamTests.ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync: PASS (0.001 seconds).
- CanadianHamTests.ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement: PASS (0.001 seconds).
- CanadianHamTests.ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows: PASS (0.000 seconds).
- CanadianHamTests.ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore: PASS (0.024 seconds).
- CanadianHamTests.ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields: PASS (0.031 seconds).
- CanadianHamTests.ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme: PASS (0.030 seconds).
- CanadianHamTests.ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker: PASS (0.020 seconds).
- CanadianHamTests.ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt: PASS (0.059 seconds).
- CanadianHamTests.ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem: PASS (0.012 seconds).
- CanadianHamTests.ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory: PASS (0.078 seconds).
- CanadianHamTests.ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot: PASS (0.033 seconds).
- CanadianHamTests.ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete: PASS (0.027 seconds).
- CanadianHamTests.ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload: PASS (0.041 seconds).
- CanadianHamTests.ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent: PASS (0.003 seconds).
- CanadianHamTests.ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal: PASS (0.001 seconds).
- CanadianHamTests.ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress: PASS (0.053 seconds).
- CanadianHamTests.ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing: PASS (0.036 seconds).
- CanadianHamTests.ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields: PASS (0.041 seconds).
- CanadianHamTests.ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount: PASS (0.049 seconds).
- CanadianHamTests.ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons: PASS (0.067 seconds).
- CanadianHamTests.ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange: PASS (0.034 seconds).
- CanadianHamTests.ProgressStoreTests.testImportLeavesTask4610Version2LessonSplitRowsUnchanged: PASS (0.036 seconds).
- CanadianHamTests.ProgressStoreTests.testImportMigratesMixedTask4610SyncRowsByRowVersion: PASS (0.040 seconds).
- CanadianHamTests.ProgressStoreTests.testImportMigratesTask4610LessonSplitProgressAndQuizAttempts: PASS (0.039 seconds).
- CanadianHamTests.ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress: PASS (0.034 seconds).
- CanadianHamTests.ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows: PASS (0.041 seconds).
- CanadianHamTests.ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues: PASS (0.040 seconds).
- CanadianHamTests.ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses: PASS (0.075 seconds).
- CanadianHamTests.ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails: PASS (0.047 seconds).
- CanadianHamTests.ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure: PASS (0.038 seconds).
- CanadianHamTests.ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress: PASS (0.033 seconds).
- CanadianHamTests.ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt: PASS (0.037 seconds).
- CanadianHamTests.ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues: PASS (0.001 seconds).
- CanadianHamTests.ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates: PASS (0.042 seconds).
- CanadianHamTests.ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates: PASS (0.040 seconds).
- CanadianHamTests.ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress: PASS (0.042 seconds).
- CanadianHamTests.ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId: PASS (0.040 seconds).
- CanadianHamTests.ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt: PASS (0.036 seconds).
- CanadianHamTests.ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges: PASS (0.034 seconds).
- CanadianHamTests.ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults: PASS (0.038 seconds).
- CanadianHamTests.ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference: PASS (0.013 seconds).
- CanadianHamTests.ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault: PASS (0.015 seconds).
- CanadianHamTests.ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue: PASS (0.010 seconds).
- CanadianHamTests.ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue: PASS (0.010 seconds).
- CanadianHamTests.ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries: PASS (0.012 seconds).
- CanadianHamTests.ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun: PASS (0.013 seconds).
- CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting: PASS (0.010 seconds).
- CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce: PASS (0.012 seconds).
- CanadianHamTests.ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure: PASS (0.031 seconds).
- CanadianHamTests.ProgressStoreTests.testLessonQuizHelpFixtureValidationAndPayloadRoundTrips: PASS (0.144 seconds).
- CanadianHamTests.ProgressStoreTests.testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix: PASS (0.031 seconds).
- CanadianHamTests.ProgressStoreTests.testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice: PASS (2.596 seconds).
- CanadianHamTests.ProgressStoreTests.testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation: PASS (0.003 seconds).
- CanadianHamTests.ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead: PASS (0.061 seconds).
- CanadianHamTests.ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution: PASS (0.052 seconds).
- CanadianHamTests.ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution: PASS (0.038 seconds).
- CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount: PASS (0.011 seconds).
- CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist: PASS (0.034 seconds).
- CanadianHamTests.ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact: PASS (0.427 seconds).
- CanadianHamTests.ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity: PASS (0.022 seconds).
- CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints: PASS (0.072 seconds).
- CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields: PASS (0.077 seconds).
- CanadianHamTests.ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder: PASS (0.001 seconds).
- CanadianHamTests.ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults: PASS (0.031 seconds).
- CanadianHamTests.ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio: PASS (0.001 seconds).
- CanadianHamTests.ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences: PASS (0.063 seconds).
- CanadianHamTests.ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues: PASS (0.001 seconds).
- CanadianHamTests.ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums: PASS (0.039 seconds).
- CanadianHamTests.ProgressStoreTests.testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender: PASS (0.947 seconds).
- CanadianHamTests.ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference: PASS (0.016 seconds).
- CanadianHamTests.ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences: PASS (0.013 seconds).
- CanadianHamTests.ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows: PASS (0.039 seconds).
- CanadianHamTests.ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt: PASS (0.012 seconds).
- CanadianHamTests.ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences: PASS (0.043 seconds).
- CanadianHamTests.ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse: PASS (0.037 seconds).
- CanadianHamTests.ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints: PASS (0.042 seconds).
- CanadianHamTests.ProgressStoreTests.testProgressStoreRoundTripExportImportReset: PASS (0.058 seconds).
- CanadianHamTests.ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff: PASS (0.013 seconds).
- CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData: PASS (0.031 seconds).
- CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure: PASS (0.046 seconds).
- CanadianHamTests.ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference: PASS (0.013 seconds).
- CanadianHamTests.ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference: PASS (0.013 seconds).
- CanadianHamTests.ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails: PASS (0.016 seconds).
- CanadianHamTests.ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext: PASS (1.811 seconds).
- CanadianHamTests.ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates: PASS (0.012 seconds).
- CanadianHamTests.ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules: PASS (0.001 seconds).
- CanadianHamTests.ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries: PASS (0.006 seconds).
- CanadianHamTests.ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress: PASS (0.094 seconds).
- CanadianHamTests.ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists: PASS (0.072 seconds).
- CanadianHamTests.ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite: PASS (0.032 seconds).
- CanadianHamTests.ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration: PASS (0.012 seconds).
- CanadianHamTests.ProgressStoreTests.testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices: PASS (0.045 seconds).
- CanadianHamTests.ProgressStoreTests.testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports: PASS (0.039 seconds).
- CanadianHamTests.ProgressStoreTests.testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration: PASS (0.030 seconds).
- CanadianHamTests.ProgressStoreTests.testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds: PASS (0.032 seconds).
- CanadianHamTests.ProgressStoreTests.testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating: PASS (0.109 seconds).
- CanadianHamTests.ProgressStoreTests.testTask4610SharedConceptMappingAndConceptInclusiveScores: PASS (0.253 seconds).
- CanadianHamTests.ProgressStoreTests.testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows: PASS (0.040 seconds).
- CanadianHamTests.ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync: PASS (0.059 seconds).
- CanadianHamTests.QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames: PASS (0.012 seconds).
- CanadianHamTests.QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours: PASS (0.013 seconds).
- CanadianHamTests.QuestionBankTests.testAppBundleContainsNoReadmeFiles: PASS (0.013 seconds).
- CanadianHamTests.QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories: PASS (0.001 seconds).
- CanadianHamTests.QuestionBankTests.testBundledJSONDecodesExpectedCounts: PASS (0.019 seconds).
- CanadianHamTests.QuestionBankTests.testBundledLessonModelExposesPrerequisites: PASS (0.558 seconds).
- CanadianHamTests.QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary: PASS (0.741 seconds).
- CanadianHamTests.QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory: PASS (0.019 seconds).
- CanadianHamTests.QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion: PASS (0.080 seconds).
- CanadianHamTests.QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes: PASS (0.001 seconds).
- CanadianHamTests.QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons: PASS (0.565 seconds).
- CanadianHamTests.ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours: PASS (0.001 seconds).
- CanadianHamTests.ReadinessAndScoringTests.testExamScoringBoundaries: PASS (0.001 seconds).
- CanadianHamTests.ReadinessAndScoringTests.testReadinessStates: PASS (0.001 seconds).
- CanadianHamTests.ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate: PASS (0.037 seconds).
- CanadianHamTests.RootNavigationMappingTests.testCompactHomeSessionAndSectionPushesUseVisibleDestination: PASS (0.001 seconds).
- CanadianHamTests.RootNavigationMappingTests.testEmptyCompactPathMapsToHome: PASS (0.000 seconds).
- CanadianHamTests.RootNavigationMappingTests.testEveryLearnRouteRoundTripsWithItsWholeStack: PASS (0.001 seconds).
- CanadianHamTests.RootNavigationMappingTests.testEveryRootSelectionRoundTrips: PASS (0.001 seconds).
- CanadianHamTests.RootNavigationMappingTests.testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts: PASS (0.001 seconds).
- CanadianHamTests.RootNavigationMappingTests.testPracticeHintLessonStackKeepsSessionAsSplitSelection: PASS (0.001 seconds).

Final macOS relevant-unit / UI-test-source compile rerun — 12 individual PASS results:
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds: PASS (0.000 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testKeyHandlingProducesEngineDisplayAndSpokenResult: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testOfficialReferenceSheetGateAndBundledPages: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testQuestionCardFocusResetKeepsTextSelectionEnabled: PASS (0.004 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet: PASS (0.001 seconds).
- CanadianHamTests.ExamCalculatorViewModelTests.testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately: PASS (0.001 seconds).

Coordinator, after the internal review (approve with notes): tightened the medium-detent cap from 8 to 6 (5 stable observed findings plus 1 headroom), since three of the five findings are element-less and can't be proven to be reference-scroll content. Ignore-eligibility rules unchanged. iPhone 17 Pro testOfficialReferenceSheetMediumDetentControlsAndShowFullSheet passed with cap 6 (136.4 s).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Unified the accessibility-size Text equivalent row as one labelled native Toggle representation with tappable text, preserving default native appearance. AX-XXXL tests on iPhone and iPad verify no external duplicate label and label-driven on/off state/content changes. Inventoried the medium audit’s two named and three nil findings, retained eligibility, added keepAlways evidence and bounded cap headroom (5 observed / 8 maximum). Targeted reference UI checks, 215 documented macOS units plus final 12-unit/UI-test compile, localization/text and approved test guard pass. No full simulator suites, PR or upload. Independent review and eventual task-67 guard marker remain required.
<!-- SECTION:FINAL_SUMMARY:END -->
