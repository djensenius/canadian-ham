# TASK-73: rounded-control measurement

Owner-delegated decision 2026-10-22, coordinator: extend the TASK-71 measured
path with a native-pixel crop for **any button** (the gate is element type, not
shape recognition), not non-button multi-background elements.
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
- Before measuring the crop, require **every discarded pixel** to belong to the
  crop's dominant background cluster, the approved outside-background cluster,
  or a blend on the RGB line between their mean colours (projection 0…1,
  residual distance ≤8 RGB-8 units). Clusters use the base algorithm's 5-bit
  channel bins and deterministic ties. The crop background must cover >50%.
- The outside endpoint is the discarded strips' most-covered **non-crop-background**
  cluster, and its WCAG contrast against the crop background must be **≤1.5:1**.
  If there is no second cluster, only crop-background pixels are allowed.
  Transparency, an unsafe endpoint, or any unapproved strip pixel returns nil.
- Return only the validated crop's result, including nil if it cannot be measured.
  No search for a more flattering crop, threshold change or image resampling.

The supervisor explicitly refined the initially requested full-image-dominant
endpoint: the fixture's same beige cluster dominates the full image (**57,365**
pixels), crop (**51,226**) and discarded strips (**6,139**). That cannot explain
its **3,874** discarded cream pixels. The most-covered non-crop-background
strip cluster supplies cream, with the ≤1.5 guard preventing a secondary-grey
chevron from becoming an alleged background. This is an approved endpoint
refinement, not a change to the underlying text measurement.

The shared `auditVerifyingMeasuredContrast` passes the actual
`element.elementType == .button` flag and pixels per point computed as
`image.width / element.frame.width`. It retains the fully-visible/below-bars
gate, full default accessibility audit, contrast-only handling and keepAlways
label/frame/ratio-or-unmeasurable logging. `controlTextContrastMeasurement`
supplies the same ratio as `measuredControlTextContrast`, plus the original
full-image ratio, `cropUsed` flag and horizontal/vertical insets in native pixels;
the keepAlways attachment records all of them. `cropUsed=true` means the valid
crop passed strip validation and was measured (its ratio can still be nil).
Rejected strips or invalid crops log `cropUsed=false`; computed insets are logged
when available, otherwise `none`. TASK-73 is recorded under TASK-71 in AGENTS.md;
the future PR needs the standalone marker:

```text
Test-guard-approved: task-73
```

Local TASK-46.5/TASK-46.6.1 composite helpers must use the **same** function,
with real element type and screenshot scale, in their measured paths; use its
`controlTextContrastMeasurement` detail variant for the full/crop evidence log.
Their integration is separate; no existing live audit call site is changed here and
the TASK-71 exception's approved scope is not widened.

## Known crop limits and adversarial proofs

This is a heuristic over retained image pixels, **not a contrast proof for the
entire button**. The fixed insets **do not remove all rounded corners**: the real
fixture retains **873 cream pixels**, about **1.51%** of the 416×139 crop, plus
its antialiased edge bins. These corners are tolerated only because each
remaining cluster is below the unchanged **2%** significant-colour cutoff. (The
review's geometric estimate was about 1.7%.) Narrower capsules or larger Dynamic
Type can retain ≥2% corners and still fail. The 6 pt choice is a measured fit for
this fixture, not a universal capsule fix, and **any button** can reach the retry.

Text/chevrons in the discarded 6 pt horizontal or 2 pt vertical strips are not
assigned a contrast ratio. Instead, the entire retry is rejected unless every
strip pixel satisfies the background-only rule. This closes the prior exclusion
false pass without attempting semantic text recognition or guaranteeing padding.
Content indistinguishable from the allowed background clusters/blends can still
escape; the unchanged sub-2% foreground limits inside the crop also remain.

`testRoundedButtonTextEntirelyWithinEndInsetsIsNotMeasured` now proves that the
raw crop would pass after hiding two #9A9A9A 4×30 pt end strokes, **but the
hardened measurement returns nil**. `testMoreButtonTrailingLowContrastChevronInStripsIsRejected`
uses a borderless **More ›**-style button with a secondary-grey chevron whose
cluster covers **2–3%** of the full image. The full image fails, its raw crop
passes, and strip validation returns **nil** (the grey cannot be the outside
background because its contrast exceeds 1.5).

Fail-safe proofs retain actual 15 pt bold #9A9A9A text:

- Low-contrast **Hide answer 1** on beige at both 2× and 3× must be nil or <4.5.
- Low-contrast M glyphs near both ends, starting at x=6 and x=108, remain in
  the crop beside high-contrast middle text and must be nil or <4.5.
- Low-contrast middle text beside high-contrast text must also be nil or <4.5.

Matched dark-text positive controls show that each low-contrast geometry's raw
crop is measurable. A separate positive control proves the actual fallback
passes dark text at **2× and 3×**, and records 12×4 / 18×6 px insets. The
non-button nil regression now uses a full-image nil / measurable-button-crop
image, so it actually proves the gate. A positive-size crop with no text is nil.
Other proofs cover non-button fixture equality, passing full-image preservation,
logging metadata, invalid scales and empty crops. All 31
pre-existing test methods and all three pre-existing PNG fixtures are retained;
`measuredTextContrast(in:)` itself is byte-identical to the starting revision.
Its existing sub-2% foreground, tiny-component, quantization, multi-background
and thin-stroke limits remain documented in the TASK-71 and blocked 2× notes.
The narrow approved audit scope, logged evidence and independent token-level
contrast checks remain essential mitigations.

## Final adversarial-review validation (2026-10-23)

Both commands ran **after the final helper/test edits**, through
`nohup bash <script> > <log> 2>&1 < /dev/null &`, polled with grep. Both initially
waited for the shared xbuild lock; no builds or simulators were killed.

### iPhone 17 Pro — full measurement class

Script `/tmp/task-73-review-iphone.sh`, log `/tmp/task-73-review-iphone.log`,
result bundle `/tmp/task-73-review-iphone.xcresult`:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -testPlan CanadianHamDefault -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/UITestContrastMeasurementTests -resultBundlePath /tmp/task-73-review-iphone.xcresult test CODE_SIGNING_ALLOWED=NO
```

**44 passed / 0 failed / 0 skipped**, **24.802 s**, exit **0**, `TEST SUCCEEDED`.
This is a single final full-class run, superseding the earlier 39-test class
plus two-method fix run. The fixture assertion still pins **13.62039:1** (full
**1.19937:1**). All five added methods and the revised regressions passed.

### macOS — documented unit command, UI-test sources also compiled

Script `/tmp/task-73-review-macos.sh`, log `/tmp/task-73-review-macos.log`,
result bundle `/tmp/task-73-review-macos.xcresult`:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests -resultBundlePath /tmp/task-73-review-macos.xcresult test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

**210 passed / 0 failed / 0 skipped**, **17.034 s**, exit **0**, `TEST SUCCEEDED`.
Both builds have no changed-source compiler warnings; the logs include the
unrelated AppIntents metadata warning. macOS has expected corrupt-store recovery
diagnostics in passing migration tests, not build/test failures.

### Other checks and scope

- `git diff --check` and `node scripts/check-test-guard.mjs --self-test` passed.
  The focused base-to-HEAD guard check uses `Test-guard-approved: task-73` for
  the intentional audit-wrapper hunk (see task notes for the checked commit).
- Source comparison confirms `measuredTextContrast(in:)` byte-identical to
  `c7e7dc36`, and all **31** pre-existing test methods byte-identical to
  `57f7991a`. Final class has **44** methods, five more than the reviewed head.
- Diagnostic host harness `/tmp/task-73-review-host-tests.swift` also reports
  `HOST_FAILURES=0` over all 44 methods; this is not the XCTest acceptance proof.
  Direct host fixture probe reports **13.620392055674973:1**, full
  **1.1993729121750754:1**, `cropUsed=true`, **18×6 px** symmetric insets.
- tvOS, visionOS, full iOS app suites, figure/title plans and web checks were
  skipped: only UI-test measurement code/tests, instructions and docs changed.
  No app/package source, target membership, live audit call site or strings
  changed; no XcodeGen was needed. Live TASK-46.5/TASK-46.6.1 integration and
  independent review remain separate; no PR was opened.
- Initial validation remains historical: `/tmp/task-73-control-iphone` had
  37 pass / 2 fail before the raw negative-dimension/exclusion-proof fixes,
  `/tmp/task-73-control-iphone-fix` passed both, and
  `/tmp/task-73-control-macos` passed 210. Their per-test tables are preserved
  in commit `ddcedc84`; all current methods now passed together above.

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
