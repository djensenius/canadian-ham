# TASK-73: rounded-control measurement

Owner-delegated decision 2026-10-22, coordinator: extend the TASK-71 measured
path narrowly for rounded **buttons**, not general multi-background elements.
The earlier [2× thin-stroke investigation](task-73-contrast-2x-blocked.md) remains
**unresolved**. Its unsafe per-pixel prototypes are not part of this change.

## Fixture and smallest-inset sweep

Unaltered element screenshot supplied for this task:

- Source: `/tmp/t73-fixtures/iphone-hide-answer-button-light-3x.png`.
- Fully visible secondary button, label **Hide answer 1**, iPhone 17 Pro, 3×.
- Size: **452 × 151 native pixels**; dark text on a beige pill with cream page
  corners. The two substantial background tones produce a low full-image ratio.
- Bundled resource:
  `apps/apple/CanadianHamUITests/Resources/ContrastMeasurement/iphone-hide-answer-button-light-3x.png`.
- SHA-256: `1d17fa526497f384ce5de88375dbe24eb7cf0aa239437c4ff60982cd4e768c2a`.

The supervisor refined the initially proposed 16 pt horizontal cap: test caps
**4, 6, 8, 12, 16 pt**, always with **2 pt vertical inset**, and choose the
**smallest** passing cap. Host-only measurements used the unchanged base
algorithm, native CGImage crops, no resampling:

| Horizontal cap | Native crop (x, y, width, height) | Ratio |
| --- | --- | ---: |
| Full image | 0, 0, 452, 151 | 1.1993729121750754 |
| 4 pt | 12, 6, 428, 139 | 1.1994004247924492 |
| **6 pt (selected)** | **18, 6, 416, 139** | **13.620392055674973** |
| 8 pt | 24, 6, 404, 139 | 13.620385825726265 |
| 12 pt | 36, 6, 380, 139 | 13.620313173154122 |
| 16 pt | 48, 6, 356, 139 | 13.620293214245946 |

Sweep command: `swift /tmp/task-73-control-inset-sweep.swift`, log
`/tmp/task-73-control-inset-sweep.log`. This is diagnostic evidence, not XCTest.
The bundled fixture has a separate XCTest regression for the selected 6 pt cap.

## Implementation and constraints

`measuredControlTextContrast(in:scale:isButton:)` first runs
`measuredTextContrast(in:)` over the entire image. A non-button always returns
that unchanged result. A passing (≥4.5) full image also returns unchanged,
without a crop. Only a button with a nil or below-4.5 full image may retry:

- Horizontal native-pixel inset: `ceil(min(image.height / 2, 6 × scale))`.
- Vertical native-pixel inset: `ceil(2 × scale)`.
- Scale must be finite and positive; the crop must have positive dimensions.
- The retry runs **the exact same base algorithm** on a native crop. Background
  dominance, significant coverage, minimum-ratio semantics, retained-core/blend
  rules, radius-two checks and component-boundary validation are unchanged.
- Return only the crop's result, including nil if it cannot be measured. No
  search for a more flattering crop, threshold change or image resampling.

The shared `auditVerifyingMeasuredContrast` passes the actual
`element.elementType == .button` flag and pixels per point computed as
`image.width / element.frame.width`. It retains the fully-visible/below-bars
gate, full default accessibility audit, contrast-only handling and keepAlways
label/frame/ratio-or-unmeasurable logging. Owner decision 2026-10-22 approves
this guarded wrapper modification; the future PR needs the standalone marker:

```text
Test-guard-approved: owner decision 2026-10-22
```

Local TASK-46.5/TASK-46.6.1 composite helpers must use the **same** function,
with real element type and screenshot scale, in their measured paths. Their
integration is separate; no existing live audit call site is changed here and
the TASK-71 exception's approved scope is not widened.

## Known crop limits and adversarial proofs

This is a heuristic over retained image pixels, **not a contrast proof for the
entire button**. Text entirely within the horizontal 6 pt end strips or the
vertical 2 pt strips is excluded. A 6 pt cap is smaller than a typical 15 pt
wide glyph (the regression's M), reducing but not eliminating this risk: narrow
letters, punctuation, truncated labels, icons or very small text can fit there.
No semantic text recognition or control-padding safety guarantee is claimed.

`testRoundedButtonTextEntirelyWithinEndInsetsIsNotMeasured` deliberately shows
the false-pass limit: two low-contrast #9A9A9A glyph-width strokes, 4 × 30 pt,
lie wholly at x=1…5 and 145…149 in a 150 × 50 pt pill, with high-contrast text
in the middle. The full image fails; the cropped retry passes because those
strokes are gone. This test documents exclusion, not safety.

Fail-safe proofs retain actual 15 pt bold #9A9A9A text:

- Low-contrast **Hide answer 1** on beige at both 2× and 3× must be nil or <4.5.
- Low-contrast M glyphs near both ends, starting at x=6 and x=108, remain in
  the crop beside high-contrast middle text and must be nil or <4.5.
- Low-contrast middle text beside high-contrast text must also be nil or <4.5.

Other new proofs cover non-button fixture equality, nil non-button results,
passing full-image preservation, invalid scales and empty crops. All 31
pre-existing test methods and all three pre-existing PNG fixtures are retained;
`measuredTextContrast(in:)` itself is byte-identical to the starting revision.
Its existing sub-2% foreground, tiny-component, quantization, multi-background
and thin-stroke limits remain documented in the TASK-71 and blocked 2× notes.
The narrow approved audit scope, logged evidence and independent token-level
contrast checks remain essential mitigations.

## Validation (2026-10-23)

Commands below ran through `nohup bash <script> > <log> 2>&1 < /dev/null &`
and were polled with grep. xbuild serialized platforms; macOS waited for the
lock. No builds or simulators owned by others were killed. No XcodeGen was
needed: the existing folder resource reference includes the new PNG.

### iphone command

Script: `/tmp/task-73-control-iphone.sh`.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -testPlan CanadianHamDefault -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/UITestContrastMeasurementTests -resultBundlePath /tmp/task-73-control-iphone.xcresult test CODE_SIGNING_ALLOWED=NO
```

### iphone-fix command

Script: `/tmp/task-73-control-iphone-fix.sh`.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -testPlan CanadianHamDefault -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/UITestContrastMeasurementTests/testControlMeasurementRejectsInvalidScaleAndEmptyCrop -only-testing:CanadianHamUITests/UITestContrastMeasurementTests/testRoundedButtonTextEntirelyWithinEndInsetsIsNotMeasured -resultBundlePath /tmp/task-73-control-iphone-fix.xcresult test CODE_SIGNING_ALLOWED=NO
```

### macos command

Script: `/tmp/task-73-control-macos.sh`.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests -resultBundlePath /tmp/task-73-control-macos.xcresult test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```


- Initial iPhone class: **37 passed, 2 failed methods, 0 skipped**, exit65,
  39 methods total, 19.505 s. The invalid-scale test exposed CGRect's
  standardization of negative crop dimensions; raw dimensions are now checked
  **before** constructing CGRect. The exclusion proof incorrectly required a
  non-nil failing full image; it now accepts nil or <4.5, exactly as the fallback
  contract specifies. Both changes are covered by the targeted rerun.
- Fix run: **2 passed, 0 failed, 0 skipped**, exit0, 1.767 s. Per policy only
  failed/changed tests were rerun, not the full class. Thus **all 39 methods have
  green results across the class run plus targeted fix run**, not a claimed
  single final 39-test run. All 31 pre-existing methods passed unchanged.
- macOS unit command: **210 passed, 0 failed, 0 skipped**, exit0, 16.649 s.
  It also compiled the UI-test target, including the platform-specific image
  bridge. Added `@MainActor` to that bridge to match XCUIScreenshot.image's
  isolation; no changed-source Swift warnings remain in the fix/macOS runs.
- Logs are `/tmp/task-73-control-{iphone,iphone-fix,macos}.log`; result bundles
  have the same basename with `.xcresult`. The initial red run printed a
  post-test xbuild simctl lookup warning, separate from its recorded assertions.
  Both final green commands exited0. macOS emitted pre-existing MorseAudioDriver
  deprecation, plural-catalogue and AppIntents warnings, plus expected corrupt-store
  recovery diagnostics from passing migration tests.
- tvOS/visionOS and full iOS suites were not run: only the UI-test helper/proof
  target changed; no app or Swift package source changed. No live audit/app
  integration is claimed. Independent review remains required.
- `git diff --check` passed. A source comparison confirmed the base algorithm
  and all 31 pre-existing test methods byte-identical to `57f7991a`.
- Test-guard self-test passed; the focused `57f7991a...0a617ef6` check passed
  with the dated approval marker, reporting the intended shared audit-wrapper
  changes at lines307/315. The future PR must retain the marker above.

### iPhone per-test results

Last recorded result per method; the two fix-run methods are marked below.

| UITestContrastMeasurementTests method | Result | Seconds | Run |
| --- | --- | ---: | --- |
| `testAntialiased15PointBoldEdgeCoverageAt3x` | PASS | 1.482 | iphone |
| `testAntialiased15PointBoldMixedContrastLinesFailAt3x` | PASS | 0.170 | iphone |
| `testAntialiased15PointLowContrastTextStillFails` | PASS | 0.241 | iphone |
| `testAntialiased15PointTextMeasuresExpectedContrast` | PASS | 0.207 | iphone |
| `testBlackOffscreenBandDoesNotRescueMidGreyText` | PASS | 0.075 | iphone |
| `testChainedBlendsCannotUseAnExcludedCore` | PASS | 0.074 | iphone |
| `testContrastMeasurementRejectsInvisibleFrames` | PASS | 0.079 | iphone |
| `testControlMeasurementPreservesPassingFullImage` | PASS | 0.070 | iphone |
| `testControlMeasurementRejectsInvalidScaleAndEmptyCrop` | PASS | 1.409 | iphone-fix |
| `testDarkIconDoesNotRescueMidGreyText` | PASS | 4.419 | iphone |
| `testDifferentCoreBlendsCannotBridgeInsetDarkStrokesToBackground` | PASS | 0.557 | iphone |
| `testDisconnectedDarkBlockCannotRescueInsetLowContrastText` | PASS | 0.070 | iphone |
| `testEqualLargeTonesAreUnmeasurable` | PASS | 0.071 | iphone |
| `testExportedCorrectFeedbackDarkPasses` | PASS | 0.272 | iphone |
| `testExportedCorrectFeedbackLightPasses` | PASS | 0.189 | iphone |
| `testExportedRoundedButtonPassesOnlyWithButtonFallback` | PASS | 0.400 | iphone |
| `testExportedTryItParagraphLightPasses` | PASS | 2.627 | iphone |
| `testFourPixelInsetGlyphCannotBorrowAnotherComponentsBoundary` | PASS | 0.340 | iphone |
| `testInsetPanelCannotUseTheSurroundingCreamAsTextBackground` | PASS | 0.389 | iphone |
| `testInterleavedNearIdenticalGreysCannotHideEachOtherBesideDarkText` | PASS | 0.514 | iphone |
| `testMidGreyOnCreamFails` | PASS | 0.337 | iphone |
| `testNearBlackOnCreamPasses` | PASS | 0.362 | iphone |
| `testNonButtonUnmeasurableImageDoesNotRetry` | PASS | 0.219 | iphone |
| `testOnlyTinyForegroundIsUnmeasurable` | PASS | 1.127 | iphone |
| `testPaleOnDarkGreenPasses` | PASS | 0.087 | iphone |
| `testPartiallyOverlappingStrokesCannotPassAgainstCream` | PASS | 0.069 | iphone |
| `testRoundedButtonLowContrastTextFailsAt2xAnd3x` | PASS | 0.253 | iphone |
| `testRoundedButtonRetainedLowContrastMiddleTextFails` | PASS | 0.200 | iphone |
| `testRoundedButtonRetainedLowContrastTextNearEndsFails` | PASS | 0.188 | iphone |
| `testRoundedButtonTextEntirelyWithinEndInsetsIsNotMeasured` | PASS | 0.357 | iphone-fix |
| `testSignificantAntialiasedEdgeBandsMeasureCoreContrast` | PASS | 0.069 | iphone |
| `testSignificantNearBackgroundNoiseIsUnmeasurable` | PASS | 0.085 | iphone |
| `testSignificantNearBlackAndMidGreyBlocksDoNotPass` | PASS | 0.549 | iphone |
| `testSolidBlendColourIsNotMistakenForAntialiasing` | PASS | 0.105 | iphone |
| `testSubthresholdAntialiasedPanelEdgeCannotSupportInsetDarkStrokes` | PASS | 0.220 | iphone |
| `testTinyHighContrastTailDoesNotRescueLowContrastText` | PASS | 0.515 | iphone |
| `testTransparentImageIsUnmeasurable` | PASS | 0.832 | iphone |
| `testTwoTonePanelWithDarkTextIsUnmeasurable` | PASS | 0.686 | iphone |
| `testUniformImageIsUnmeasurable` | PASS | 0.157 | iphone |

### macOS per-test results

| Class.method | Result | Seconds |
| --- | --- | ---: |
| `CanadianHamTests.DuoLayoutPolicyTests.testCompactWidthIPhoneKeepsSheetPolicy` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testIPadInspectorRuleRemainsSizeClassDriven` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testMacAndOtherIdiomsNeverUseIPhonePolicy` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy` | PASS | 0.001 |
| `CanadianHamTests.DuoLayoutPolicyTests.testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact` | PASS | 0.000 |
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
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` | PASS | 0.000 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` | PASS | 0.398 |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute` | PASS | 0.288 |
| `CanadianHamTests.HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` | PASS | 0.001 |
| `CanadianHamTests.HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` | PASS | 2.562 |
| `CanadianHamTests.LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations` | PASS | 0.009 |
| `CanadianHamTests.LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` | PASS | 0.004 |
| `CanadianHamTests.LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides` | PASS | 0.001 |
| `CanadianHamTests.LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish` | PASS | 0.001 |
| `CanadianHamTests.LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale` | PASS | 0.003 |
| `CanadianHamTests.MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testFixedTimingProfilesUseEngineValues` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testLessonBodyAndBulletContrastTokensMeetMinimumRatio` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession` | PASS | 1.658 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` | PASS | 0.106 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesPressWhenAudioFails` | PASS | 0.007 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError` | PASS | 0.105 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone` | PASS | 0.006 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReleaseCannotBeSupersededBySilence` | PASS | 0.004 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError` | PASS | 0.107 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsClampAndPreset` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled` | PASS | 0.002 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` | PASS | 0.010 |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults` | PASS | 0.004 |
| `CanadianHamTests.MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | PASS | 0.041 |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback` | PASS | 0.001 |
| `CanadianHamTests.MorseTrainerTests.testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | PASS | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` | PASS | 0.075 |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts` | PASS | 0.024 |
| `CanadianHamTests.ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` | PASS | 0.003 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` | PASS | 0.027 |
| `CanadianHamTests.ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields` | PASS | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` | PASS | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` | PASS | 0.017 |
| `CanadianHamTests.ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` | PASS | 0.055 |
| `CanadianHamTests.ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem` | PASS | 0.009 |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory` | PASS | 0.066 |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` | PASS | 0.027 |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete` | PASS | 0.024 |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` | PASS | 0.134 |
| `CanadianHamTests.ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent` | PASS | 0.003 |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` | PASS | 0.049 |
| `CanadianHamTests.ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` | PASS | 0.044 |
| `CanadianHamTests.ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` | PASS | 0.061 |
| `CanadianHamTests.ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportLeavesTask4610Version2LessonSplitRowsUnchanged` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesMixedTask4610SyncRowsByRowVersion` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesTask4610LessonSplitProgressAndQuizAttempts` | PASS | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress` | PASS | 0.031 |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows` | PASS | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues` | PASS | 0.036 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` | PASS | 0.071 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails` | PASS | 0.043 |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure` | PASS | 0.031 |
| `CanadianHamTests.ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` | PASS | 0.033 |
| `CanadianHamTests.ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` | PASS | 0.036 |
| `CanadianHamTests.ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress` | PASS | 0.037 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` | PASS | 0.032 |
| `CanadianHamTests.ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` | PASS | 0.009 |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` | PASS | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue` | PASS | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` | PASS | 0.008 |
| `CanadianHamTests.ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` | PASS | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` | PASS | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` | PASS | 0.010 |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` | PASS | 0.008 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` | PASS | 0.028 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpFixtureValidationAndPayloadRoundTrips` | PASS | 0.134 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix` | PASS | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice` | PASS | 2.737 |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation` | PASS | 0.003 |
| `CanadianHamTests.ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` | PASS | 0.050 |
| `CanadianHamTests.ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` | PASS | 0.057 |
| `CanadianHamTests.ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` | PASS | 0.032 |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` | PASS | 0.011 |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` | PASS | 0.406 |
| `CanadianHamTests.ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` | PASS | 0.021 |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` | PASS | 0.073 |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` | PASS | 0.069 |
| `CanadianHamTests.ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` | PASS | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences` | PASS | 0.052 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender` | PASS | 0.946 |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference` | PASS | 0.012 |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences` | PASS | 0.012 |
| `CanadianHamTests.ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` | PASS | 0.038 |
| `CanadianHamTests.ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` | PASS | 0.013 |
| `CanadianHamTests.ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` | PASS | 0.042 |
| `CanadianHamTests.ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` | PASS | 0.035 |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` | PASS | 0.041 |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreRoundTripExportImportReset` | PASS | 0.064 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff` | PASS | 0.014 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` | PASS | 0.032 |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` | PASS | 0.049 |
| `CanadianHamTests.ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference` | PASS | 0.014 |
| `CanadianHamTests.ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference` | PASS | 0.015 |
| `CanadianHamTests.ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails` | PASS | 0.017 |
| `CanadianHamTests.ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext` | PASS | 1.742 |
| `CanadianHamTests.ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates` | PASS | 0.012 |
| `CanadianHamTests.ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` | PASS | 0.001 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` | PASS | 0.006 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` | PASS | 0.090 |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` | PASS | 0.060 |
| `CanadianHamTests.ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` | PASS | 0.034 |
| `CanadianHamTests.ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` | PASS | 0.009 |
| `CanadianHamTests.ProgressStoreTests.testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices` | PASS | 0.044 |
| `CanadianHamTests.ProgressStoreTests.testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports` | PASS | 0.040 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration` | PASS | 0.029 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds` | PASS | 0.032 |
| `CanadianHamTests.ProgressStoreTests.testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating` | PASS | 0.108 |
| `CanadianHamTests.ProgressStoreTests.testTask4610SharedConceptMappingAndConceptInclusiveScores` | PASS | 0.238 |
| `CanadianHamTests.ProgressStoreTests.testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows` | PASS | 0.039 |
| `CanadianHamTests.ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` | PASS | 0.055 |
| `CanadianHamTests.QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` | PASS | 0.012 |
| `CanadianHamTests.QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` | PASS | 0.013 |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsNoReadmeFiles` | PASS | 0.013 |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories` | PASS | 0.001 |
| `CanadianHamTests.QuestionBankTests.testBundledJSONDecodesExpectedCounts` | PASS | 0.019 |
| `CanadianHamTests.QuestionBankTests.testBundledLessonModelExposesPrerequisites` | PASS | 0.544 |
| `CanadianHamTests.QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary` | PASS | 0.700 |
| `CanadianHamTests.QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` | PASS | 0.019 |
| `CanadianHamTests.QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` | PASS | 0.076 |
| `CanadianHamTests.QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` | PASS | 0.001 |
| `CanadianHamTests.QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` | PASS | 0.561 |
| `CanadianHamTests.ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours` | PASS | 0.001 |
| `CanadianHamTests.ReadinessAndScoringTests.testExamScoringBoundaries` | PASS | 0.001 |
| `CanadianHamTests.ReadinessAndScoringTests.testReadinessStates` | PASS | 0.001 |
| `CanadianHamTests.ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` | PASS | 0.034 |
| `CanadianHamTests.RootNavigationMappingTests.testCompactHomeSessionAndSectionPushesUseVisibleDestination` | PASS | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testEmptyCompactPathMapsToHome` | PASS | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testEveryLearnRouteRoundTripsWithItsWholeStack` | PASS | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testEveryRootSelectionRoundTrips` | PASS | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts` | PASS | 0.001 |
| `CanadianHamTests.RootNavigationMappingTests.testPracticeHintLessonStackKeepsSessionAsSplitSelection` | PASS | 0.001 |
