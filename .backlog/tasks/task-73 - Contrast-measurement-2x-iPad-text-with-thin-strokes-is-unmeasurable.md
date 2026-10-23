---
id: TASK-73
title: 'Contrast measurement: rounded-control measurement'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-23 16:51'
updated_date: '2026-10-23 18:22'
labels:
  - accessibility
  - tests
dependencies: []
priority: high
ordinal: 152000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner-delegated decision 2026-10-22, coordinator, plus supervisor-approved review hardening: extend TASK-71 measured contrast only for any button whose full-image measurement is nil or below4.5. The unaltered iPhone17Pro3x Hide answer1 fixture measures1.199:1 full and13.620:1 with the smallest passing swept cap6pt horizontal/2pt vertical. Keep the conservative base algorithm unchanged. Validate every discarded strip pixel as crop-background cluster, optional page-like outside cluster (most-covered non-crop-background strip cluster, contrast<=1.5), or RGB-line blend (residual<=8); otherwise nil. This endpoint refinement is explicitly supervisor-approved because beige dominates both full/crop/strips and the real cream corners would otherwise fail. Record full/final ratios, crop-used flag and pixel insets. Non-buttons and audit scope stay unchanged. Retained corners are tolerated only below2%; narrow capsules/larger Dynamic Type may still fail. Earlier2x iPad thin-stroke investigation remains unresolved in docs/testing/task-73-contrast-2x-blocked.md; no unsafe prototype ships.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The unaltered 3× rounded-button fixture measures at least4.5 using the smallest passing horizontal cap from4/6/8/12/16pt and vertical2pt; crop and audit path apply only to buttons after a nil or below4.5 full-image measurement
- [x] #2 Low-contrast #9A9A9A pill text and retained low-contrast text beside high-contrast text fail safe; add explicit end-inset exclusion proof and document the limit
- [x] #3 All existing measurements/adversarial regressions remain unchanged for non-buttons; document fixture provenance, inset sweep and unresolved2× thin-stroke limitation without loosening the conservative algorithm
- [ ] #4 iPhone17Pro UITestContrastMeasurementTests and the documented macOS unit command pass via nohup/xbuild with grep polling; commit and push branch without a PR
- [x] #5 Discarded-strip hardening rejects the prior excluded-end false pass and More trailing-grey-chevron (2-3% coverage) while preserving the real fixture13.62039; full/final ratio, crop-used and pixel-inset metadata are logged keepAlways
- [x] #6 Meaningful nil non-button test has a measurable button counterpart; matched dark-text positive controls cover each synthetic low-contrast crop plus2x/3x fallback; a positive-size crop with no text returns nil; AGENTS records TASK-73 and docs state any-button and sub-2% retained-corner limits
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Retain the prior blocked2x investigation unchanged; preserve the unaltered3x fixture and smallest-passing-cap sweep (6pt horizontal,2pt vertical).
2. Preserve measuredTextContrast byte-for-byte and any-button/full-image gating; require every discarded pixel to be crop-background, the approved <=1.5 most-covered non-crop-background strip cluster, or their RGB-8 line blend before accepting a crop.
3. Log full/final ratios, crop-used and pixel insets; add meaningful nil/non-button, matched dark-text controls,2x/3x positive, no-text crop and More-chevron/excluded-end rejection proofs. Correct docs and AGENTS TASK-73 exception/guard marker.
4. Run the final full44-method iPhone17Pro measurement class and documented macOS210-test unit command through nohup/xbuild and grep polling; record every test, run source/diff/guard checks, commit and push without PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Pre-fix host diagnostics /tmp/task-73-diagnostics.log: only lower equals-sign component295 (16px at296,26...311,26) fails: boundary16,supported4,otherRetained0. Edge bin8422 count183 has1 pixel elsewhere without radius2 background; bin14796 count35 has1 elsewhere without radius2 core. Thus global bin veto, not label or low ratio. Supervisor approved per-pixel subthreshold support refinement under unchanged colour/distance/reachability/share/ratio constraints; invalid pixels cannot bridge. Red xbuild fixture proof queued with nohup; no source-helper edits until it completes.

Blocked after supervisor-authorized single bounded attempt. Real iPhone red fixture proof:1test failed at XCTUnwrap(nil),exit65,test0.978s,/tmp/task-73-before.log and .xcresult; no build killed. Per-pixel support prototype restores iPad16.336427704401043:1 but falsely passes existing subthreshold-panel15.9942758247219 and cross-core14.426790204267782 fixtures, plus new sparse-edge2x15.9942758247219. Supervisor permitted one final attempt banning ALL significant-bin support/bridge pixels. Full37-method host harness still has same3failures (34pass): offending panel bins are already sub2% (0.92%,0.60%,1.21% respectively), so restriction cannot address it. Bounded prototype /tmp/task-73-bounded-host-tests.swift SHA256 f59ceeb695320b8bed3d37d35f93fb202d83e4f844169ccb6f02d1dbc3ef9bf3; output /tmp/task-73-bounded-host-tests.log. Stopped as instructed. Removed temporary failing test and fixture from worktree; helper/app/tests/resources remain unchanged. No skipped/failing test pushed; evidence docs only. Remains In Progress with all ACs unchecked. Final iPhone class and macOS command not run because no safe implementation was retained.

Evidence retained in docs/testing/task-73-contrast-2x-blocked.md; TASK-71 measurement doc links the blocked investigation. git diff --check passed; git diff67c69cf6 --exit-code -- apps/apple confirms all Apple source/tests/resources/project files byte-identical to start. Test-guard self-test passed. No staged files before documentation commit. No final green class/macOS results claimed. Stopped under the explicit supervisor bounded-attempt instruction, leaving all ACs unchecked and task In Progress.

New approved scope: rounded-control measurement only; previous2× notes remain historical unresolved evidence. Supervisor explicitly requested smallest passing cap among4/6/8/12/16pt. Host-only unchanged-algorithm sweep on452×151px fixture at3×: full1.1993729121750754;4pt1.1994004247924492;6pt13.620392055674973;8pt13.620385825726265;12pt13.620313173154122;16pt13.620293214245946. Selected6pt; vertical2pt. Sweep/log /tmp/task-73-control-inset-sweep.{swift,log}. No base-algorithm changes approved.

Rounded-control implementation0a617ef6 and per-test evidence ddcedc84 committed and pushed to origin/task-73-contrast-2x (no PR). Added measuredControlTextContrast(in:scale:isButton:) with6pt horizontal/2pt vertical native crop only for buttons after nil/below4.5 full measurement. Base measuredTextContrast and all31 old test methods byte-identical to57f7991a; no app/project membership changes. Actual452×151 fixture: full1.1993729121750754, selected6pt crop13.620392055674973. Eight new methods cover fixture/non-button equality, low contrast2×/3×, retained end/middle text, excluded-end false-pass, passing full-image preservation, invalid scale/empty crop and nil non-button. Excluded6pt ends/2pt top-bottom remain an explicit false-pass limit, not a full-control proof;2× thin-stroke limitation is still unresolved. Shared wrapper passes actual.button type and screenshot/frame scale; TASK-46.5/46.6.1 composites must call the same function in their own integration changes.

Validation via nohup/xbuild with grep polling; no builds killed. Initial iPhone17Pro class /tmp/task-73-control-iphone.{log,xcresult}:37passed/2failed methods/0skipped (39total), exit65. Fixed raw negative CGRect dimension validation and exclusion proof nil expectation; targeted two-method rerun /tmp/task-73-control-iphone-fix.{log,xcresult}:2passed/0failed/0skipped,exit0. All39 methods now have green results across full+targeted fix runs, not a claimed single final full-class run. macOS documented unit command /tmp/task-73-control-macos.{log,xcresult}:210passed/0failed/0skipped,exit0; UI-test target compiled too. Added@MainActor to platform-safe screenshot bridge to eliminate isolation warning. No changed-source warnings in final commands; unrelated deprecation/plural/AppIntents warnings and expected corrupt-store diagnostics remain. tvOS/visionOS/full iOS suites skipped because only UI-test helper/proofs changed. Complete per-test tables and commands are in docs/testing/task-73-rounded-control-measurement.md. Test-guard self-test passed; focused57f7991a...0a617ef6 check passed with Test-guard-approved: owner decision 2026-10-22, reporting intended wrapper findings. git diff --check passed. Independent branch review remains required; no live audit integration claimed.

Reopened for supervisor-requested review fixes, including explicitly approved discarded-strip hardening (option 5). PR marker will be Test-guard-approved: task-73; AGENTS TASK-71 entry will record the TASK-73 button crop refinement. No base-algorithm or audit-scope widening.

Supervisor refinement during review fixes: literal full-image/strip dominant background endpoint rejects the real fixture because beige dominates full (57,365px), crop (51,226px), and discarded strips (6,139px); cream is 3,874 strip pixels. Explicitly approved selecting the most-covered NON-crop-background strip cluster as optional second endpoint, requiring WCAG contrast <=1.5 against crop background. Reject otherwise. Validate every discarded pixel as crop-background cluster, outside-background cluster, or RGB-line blend (residual <=8); without second cluster allow only crop-background pixels. Keep More-chevron nil and fixture13.62 requirements.

Implemented requested docs/comment corrections (any-button gate, retained sub-2% corners, narrow capsules/Dynamic Type may fail), full/final/crop-used/pixel-inset keepAlways logging, all requested test controls, and background-only discarded strips with the explicitly refined <=1.5 outside endpoint. AGENTS TASK-71 exception now includes TASK-73 and the PR marker is Test-guard-approved: task-73. Host fixture remains13.620392055674973, full1.1993729121750754. Diagnostic host class harness44methods HOST_FAILURES=0; final iPhone full class and macOS unit commands launched via nohup/xbuild and grep polling, currently waiting on shared build lock; no builds killed.

Final post-review commands passed, no helper/test edits after launch: /tmp/task-73-review-iphone.{sh,log,xcresult}: single full44-method class44passed/0failed/0skipped,24.802s,exit0. /tmp/task-73-review-macos.{sh,log,xcresult}:210passed/0failed/0skipped,17.034s,exit0; both UI-test files compiled on macOS. Both waited for xbuild lock; grep polling, no builds killed. No changed-source warnings; AppIntents warning and expected macOS corrupt-store diagnostics only. Source comparison confirms base algorithm unchanged fromc7e7dc36 and all31 original methods unchanged from57f7991a; fixture SHA unchanged. Host44-method harness HOST_FAILURES=0; real fixture13.620392055674973,full1.1993729121750754. More-chevron and end-stroke raw crops pass but hardened result is nil; requested dark controls,2x positive, actual measurable-button/nil-nonbutton pair and valid-no-text nil all pass. tvOS/visionOS/full-iOS/figures/title/web skipped because no app/package/strings/live-audit integration changed. Final per-test tables follow and are also in docs/testing/task-73-rounded-control-measurement.md. Independent reviewer remains required before PR; marker Test-guard-approved: task-73.

### Final iPhone per-test results

| Method | Result | Seconds |
| --- | --- | ---: |
| `testAntialiased15PointBoldEdgeCoverageAt3x` | PASS | 0.923 |
| `testAntialiased15PointBoldMixedContrastLinesFailAt3x` | PASS | 0.207 |
| `testAntialiased15PointLowContrastTextStillFails` | PASS | 0.197 |
| `testAntialiased15PointTextMeasuresExpectedContrast` | PASS | 0.188 |
| `testBlackOffscreenBandDoesNotRescueMidGreyText` | PASS | 0.077 |
| `testChainedBlendsCannotUseAnExcludedCore` | PASS | 0.077 |
| `testContrastMeasurementRejectsInvisibleFrames` | PASS | 0.083 |
| `testControlMeasurementPreservesPassingFullImage` | PASS | 0.083 |
| `testControlMeasurementRejectsInvalidScaleAndEmptyCrop` | PASS | 0.476 |
| `testDarkIconDoesNotRescueMidGreyText` | PASS | 0.186 |
| `testDifferentCoreBlendsCannotBridgeInsetDarkStrokesToBackground` | PASS | 0.165 |
| `testDisconnectedDarkBlockCannotRescueInsetLowContrastText` | PASS | 5.812 |
| `testEqualLargeTonesAreUnmeasurable` | PASS | 0.777 |
| `testExportedCorrectFeedbackDarkPasses` | PASS | 0.279 |
| `testExportedCorrectFeedbackLightPasses` | PASS | 0.195 |
| `testExportedRoundedButtonPassesOnlyWithButtonFallback` | PASS | 0.383 |
| `testExportedTryItParagraphLightPasses` | PASS | 0.287 |
| `testFourPixelInsetGlyphCannotBorrowAnotherComponentsBoundary` | PASS | 0.078 |
| `testInsetPanelCannotUseTheSurroundingCreamAsTextBackground` | PASS | 0.078 |
| `testInterleavedNearIdenticalGreysCannotHideEachOtherBesideDarkText` | PASS | 0.073 |
| `testMidGreyOnCreamFails` | PASS | 0.165 |
| `testMoreButtonTrailingLowContrastChevronInStripsIsRejected` | PASS | 0.178 |
| `testNearBlackOnCreamPasses` | PASS | 0.137 |
| `testNonButtonUnmeasurableImageDoesNotRetry` | PASS | 1.600 |
| `testOnlyTinyForegroundIsUnmeasurable` | PASS | 1.004 |
| `testPaleOnDarkGreenPasses` | PASS | 3.809 |
| `testPartiallyOverlappingStrokesCannotPassAgainstCream` | PASS | 0.110 |
| `testRoundedButtonDarkTextPassesAt2xAnd3x` | PASS | 0.490 |
| `testRoundedButtonLowContrastTextFailsAt2xAnd3x` | PASS | 0.288 |
| `testRoundedButtonMiddleDarkTextCropIsMeasurable` | PASS | 0.112 |
| `testRoundedButtonNearEndDarkTextCropIsMeasurable` | PASS | 0.126 |
| `testRoundedButtonRetainedLowContrastMiddleTextFails` | PASS | 0.221 |
| `testRoundedButtonRetainedLowContrastTextNearEndsFails` | PASS | 0.181 |
| `testRoundedButtonTextEntirelyWithinEndInsetsIsNotMeasured` | PASS | 0.459 |
| `testSignificantAntialiasedEdgeBandsMeasureCoreContrast` | PASS | 1.959 |
| `testSignificantNearBackgroundNoiseIsUnmeasurable` | PASS | 2.622 |
| `testSignificantNearBlackAndMidGreyBlocksDoNotPass` | PASS | 0.094 |
| `testSolidBlendColourIsNotMistakenForAntialiasing` | PASS | 0.070 |
| `testSubthresholdAntialiasedPanelEdgeCannotSupportInsetDarkStrokes` | PASS | 0.082 |
| `testTinyHighContrastTailDoesNotRescueLowContrastText` | PASS | 0.090 |
| `testTransparentImageIsUnmeasurable` | PASS | 0.073 |
| `testTwoTonePanelWithDarkTextIsUnmeasurable` | PASS | 0.077 |
| `testUniformImageIsUnmeasurable` | PASS | 0.074 |
| `testValidButtonCropWithoutTextIsUnmeasurable` | PASS | 0.158 |

### Final macOS per-test results

| Class.method | Result | Seconds |
| --- | --- | ---: |
| `CanadianHamTests.DuoLayoutPolicyTests.testCompactWidthIPhoneKeepsSheetPolicy` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testIPadInspectorRuleRemainsSizeClassDriven` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testMacAndOtherIdiomsNeverUseIPhonePolicy` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` | PASS | 0.001 |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds` | PASS | 0.001 |
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
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` | PASS | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` | PASS | 0.391 |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute` | PASS | 0.297 |
| `CanadianHamTests.HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` | PASS | 0.002 |
| `CanadianHamTests.HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` | PASS | 2.563 |
| `CanadianHamTests.LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations` | PASS | 0.019 |
| `CanadianHamTests.LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` | PASS | 0.005 |
| `CanadianHamTests.LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides` | PASS | 0.001 |
| `CanadianHamTests.LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish` | PASS | 0.001 |
| `CanadianHamTests.LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale` | PASS | 0.004 |
| `CanadianHamTests.MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testFixedTimingProfilesUseEngineValues` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testLessonBodyAndBulletContrastTokensMeetMinimumRatio` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession` | PASS | 1.670 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints` | PASS | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` | PASS | 0.106 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal` | PASS | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesPressWhenAudioFails` | PASS | 0.006 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended` | PASS | 0.004 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError` | PASS | 0.106 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone` | PASS | 0.006 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReleaseCannotBeSupersededBySilence` | PASS | 0.005 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress` | PASS | 0.105 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError` | PASS | 0.109 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsClampAndPreset` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` | PASS | 0.008 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults` | PASS | 0.004 |
| `CanadianHamTests.MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | PASS | 0.047 |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | PASS | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` | PASS | 0.078 |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts` | PASS | 0.024 |
| `CanadianHamTests.ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` | PASS | 0.004 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` | PASS | 0.026 |
| `CanadianHamTests.ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields` | PASS | 0.031 |
| `CanadianHamTests.ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` | PASS | 0.030 |
| `CanadianHamTests.ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` | PASS | 0.022 |
| `CanadianHamTests.ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` | PASS | 0.058 |
| `CanadianHamTests.ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem` | PASS | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory` | PASS | 0.067 |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` | PASS | 0.028 |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete` | PASS | 0.026 |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` | PASS | 0.137 |
| `CanadianHamTests.ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent` | PASS | 0.002 |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` | PASS | 0.048 |
| `CanadianHamTests.ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` | PASS | 0.034 |
| `CanadianHamTests.ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` | PASS | 0.046 |
| `CanadianHamTests.ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` | PASS | 0.064 |
| `CanadianHamTests.ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportLeavesTask4610Version2LessonSplitRowsUnchanged` | PASS | 0.034 |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesMixedTask4610SyncRowsByRowVersion` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesTask4610LessonSplitProgressAndQuizAttempts` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` | PASS | 0.071 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails` | PASS | 0.044 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` | PASS | 0.034 |
| `CanadianHamTests.ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` | PASS | 0.036 |
| `CanadianHamTests.ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` | PASS | 0.040 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates` | PASS | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress` | PASS | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId` | PASS | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` | PASS | 0.032 |
| `CanadianHamTests.ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` | PASS | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` | PASS | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue` | PASS | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` | PASS | 0.009 |
| `CanadianHamTests.ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` | PASS | 0.012 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` | PASS | 0.014 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` | PASS | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` | PASS | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` | PASS | 0.031 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpFixtureValidationAndPayloadRoundTrips` | PASS | 0.136 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix` | PASS | 0.030 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice` | PASS | 2.737 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation` | PASS | 0.002 |
| `CanadianHamTests.ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` | PASS | 0.057 |
| `CanadianHamTests.ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` | PASS | 0.050 |
| `CanadianHamTests.ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` | PASS | 0.012 |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` | PASS | 0.034 |
| `CanadianHamTests.ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` | PASS | 0.475 |
| `CanadianHamTests.ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` | PASS | 0.018 |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` | PASS | 0.069 |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` | PASS | 0.079 |
| `CanadianHamTests.ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` | PASS | 0.031 |
| `CanadianHamTests.ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences` | PASS | 0.055 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender` | PASS | 0.966 |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference` | PASS | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences` | PASS | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` | PASS | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` | PASS | 0.043 |
| `CanadianHamTests.ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` | PASS | 0.046 |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreRoundTripExportImportReset` | PASS | 0.062 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff` | PASS | 0.014 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` | PASS | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` | PASS | 0.048 |
| `CanadianHamTests.ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference` | PASS | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference` | PASS | 0.015 |
| `CanadianHamTests.ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails` | PASS | 0.014 |
| `CanadianHamTests.ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext` | PASS | 1.758 |
| `CanadianHamTests.ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates` | PASS | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` | PASS | 0.002 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` | PASS | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` | PASS | 0.098 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` | PASS | 0.062 |
| `CanadianHamTests.ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` | PASS | 0.031 |
| `CanadianHamTests.ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` | PASS | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices` | PASS | 0.044 |
| `CanadianHamTests.ProgressStoreTests.testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration` | PASS | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds` | PASS | 0.028 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating` | PASS | 0.103 |
| `CanadianHamTests.ProgressStoreTests.testTask4610SharedConceptMappingAndConceptInclusiveScores` | PASS | 0.235 |
| `CanadianHamTests.ProgressStoreTests.testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows` | PASS | 0.040 |
| `CanadianHamTests.ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` | PASS | 0.054 |
| `CanadianHamTests.QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` | PASS | 0.012 |
| `CanadianHamTests.QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` | PASS | 0.013 |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsNoReadmeFiles` | PASS | 0.013 |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories` | PASS | 0.001 |
| `CanadianHamTests.QuestionBankTests.testBundledJSONDecodesExpectedCounts` | PASS | 0.019 |
| `CanadianHamTests.QuestionBankTests.testBundledLessonModelExposesPrerequisites` | PASS | 0.560 |
| `CanadianHamTests.QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary` | PASS | 0.731 |
| `CanadianHamTests.QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` | PASS | 0.020 |
| `CanadianHamTests.QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` | PASS | 0.080 |
| `CanadianHamTests.QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` | PASS | 0.001 |
| `CanadianHamTests.QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` | PASS | 0.582 |
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
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented rounded-control measurement under the narrowed owner-delegated scope. Smallest passing tested horizontal cap6pt plus2pt vertical inset raises the unaltered Hide answer1 fixture from1.199:1 to13.620:1 while leaving the conservative base algorithm and non-button behavior unchanged. Added8 regression methods; all39 iPhone methods have green results across class+two-method fix runs; macOS210 unit tests pass and UI-test sources compile. Documented excluded-end false-pass risk and retained all blocked2× diagnostics as unresolved. Code/evidence committed and pushed on task-73-contrast-2x; no PR. TASK-46.5/46.6.1 composite-helper integration and independent review remain separate.
<!-- SECTION:FINAL_SUMMARY:END -->
