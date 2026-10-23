---
id: TASK-46.6.1
title: Apple lesson-quiz per-option concept-check feedback
status: Done
assignee:
  - '@worker'
created_date: '2026-10-20 14:35'
updated_date: '2026-10-23 18:07'
labels:
  - apple
dependencies:
  - TASK-50.14.2
parent_task_id: TASK-46.6
ordinal: 143000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-46.6 adds optional localized feedback to each concept-check choice and displays the chosen option feedback on web. Apple lesson quizzes currently show only the generic concept explanation. Follow the shared content contract after the Apple quiz-hints work, without changing official bank questions or mock exams.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 After answering a concept check, iOS/iPadOS/macOS lesson quizzes show the chosen option feedback plus the existing explanation; shuffled options map to the correct source feedback and legacy choices without feedback still work.
- [x] #2 Feedback uses EN/FR fallback with correct language metadata, accessible focus/VoiceOver and Dynamic Type, and colour-independent correctness; no feedback is disclosed before answering.
- [x] #3 Targeted unit/UI tests include correct and incorrect choices, shuffled mapping, absent feedback, EN/FR and light/dark accessibility audits without weakening existing tests; Apple localization/text checks and affected platform checks pass.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Gate concept feedback focus with a one-shot request from the choose action, cleared on navigation, and unit-test initial/restored answers and Previous/Next consumption.
2. Reuse Correct. and add missing Incorrect. with French translations using an exact Python JSON round-trip; update the feedback assertions.
3. Run the unchanged Practice LearnFlow light/dark audits on iPhone 17 Pro and iPad Pro 13-inch (M5) first via nohup xbuild; stop and report screenshots/labels if new feedback status fails.
4. Rerun the 12 lesson-quiz methods per device, documented macOS unit command, localization without catalogue rewrite, text sources and approved guard. Record per-test evidence, finalize, commit and push; no PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Final review follow-up validation, 2026-10-23 (supersedes all earlier Blocked/unchecked-AC3 investigation paragraphs; trimmed using the Backlog CLI):

Implemented source-indexed per-option feedback with explanation retained, content-language metadata/fallback, non-colour correctness and no pre-answer disclosure. Review fixes in a83d15fa arm a one-shot check-ID focus request only in the choice action, consume it once, clear on navigation/disappearance, and check cancellation before assigning accessibility focus. Added testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext (initial/restored answers, one-shot choice, Next/Previous, and mismatched requests). UI automation does not expose VoiceOver focus, so the requested flag-logic unit fallback was used; manual VoiceOver speech/focus is not claimed.

Status now starts with existing Correct. or new Incorrect. The existing Correct. catalogue entry (including its existing French Correct. translation) was reused unchanged as requested; only missing Incorrect. was added with fr/fr-CA Mauvaise réponse. via an exact Python JSON round-trip, retaining existing ordering and formatting. Only assertions in the task-added UI tests changed. No existing audit, shared helper, official question, mock exam, or content change was made in this review fix.

Both unchanged Practice LearnFlow full audits passed on both devices with no retry, no narrowing and no exceptions. CanadianHamPracticeUITests.swift and UITestContrastMeasurement.swift are byte-identical to origin/main 80ca2871ca087db2bfebb89e2ae94f38c8273024 (verified by git diff --exit-code).

| CanadianHamPracticeUITests method | iPhone 17 Pro | iPad Pro 13-inch (M5) |
|---|---|---|
| testAccessibilityAuditLearnFlowDark | PASSED 58.268 s | PASSED 40.890 s |
| testAccessibilityAuditLearnFlowLight | PASSED 42.903 s | PASSED 36.041 s |

All 12 requested lesson-quiz methods passed in a single selection on each device, no retries/skips:

| CanadianHamExamToolsUITests method | iPhone 17 Pro | iPad Pro 13-inch (M5) |
|---|---|---|
| testLessonQuizConceptCheckHasNoHintOrOtherTools | PASSED 21.995 s | PASSED 14.837 s |
| testLessonQuizConceptOptionCorrectDarkAndFullAccessibilityAudit | PASSED 59.158 s | PASSED 33.103 s |
| testLessonQuizConceptOptionCorrectLightAndFullAccessibilityAudit | PASSED 62.297 s | PASSED 40.069 s |
| testLessonQuizConceptOptionFeedbackLargestDynamicType | PASSED 193.520 s | PASSED 42.818 s |
| testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit | PASSED 67.509 s | PASSED 37.952 s |
| testLessonQuizConceptOptionIncorrectFrenchFallbackLightAndFullAccessibilityAudit | PASSED 70.816 s | PASSED 33.720 s |
| testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip | PASSED 284.070 s | PASSED 127.442 s |
| testLessonQuizHintsDarkAndFullAccessibilityAudits | PASSED 163.794 s | PASSED 60.071 s |
| testLessonQuizHintsFrenchAndCurrentLessonRoundTrip | PASSED 167.119 s | PASSED 58.995 s |
| testLessonQuizHintsLightAndFullAccessibilityAudits | PASSED 164.682 s | PASSED 58.205 s |
| testLessonQuizOneLevelHintAndHelpCountPersistsAfterRelaunch | PASSED 111.100 s | PASSED 38.042 s |
| testLessonQuizPostChoiceHintsDoNotChangeSavedHelpAndRelaunchKeepsHelpCount | PASSED 123.103 s | PASSED 46.050 s |

The full documented macOS unit command passed 214/214, 0 failures/skips (17.130 s test-suite wall time). This kept building CanadianHamUITests as required; only UI test execution was excluded. The four concept-feedback units passed: French/fallback metadata 0.003 s, legacy/no disclosure 0.002 s, shuffled source mapping 0.003 s, new focus-request logic 0.001 s. The complete per-test results follow below.

Ancillary checks all PASS: pnpm check:apple-l10n (French export and its generic tvOS/visionOS localization builds; no catalogue rewrite); node scripts/check-apple-text-sources.ts; node scripts/check-test-guard.mjs --self-test; approved branch guard against origin/main using Test-guard-approved: owner decision 2026-10-22; unapproved guard for review-only da0ef283...HEAD reports no guarded changes; git diff --check. Catalogue SHA-256 before/after localization remains 38a3bf34138ea0e601b88d25e555210024e111548070520c7a037f5bb73599d3. The branch guard still reports only the already-approved TASK-71 composite audit/context findings; this follow-up did not edit any audit/helper.

Raw evidence: /tmp/task-46.6.1-{iphone,ipad}-review-audits.{log,xcresult}, /tmp/task-46.6.1-{iphone,ipad,macos}-review.{log,xcresult}, matching -tests.json and -summary.json, /tmp/task-46.6.1-{iphone,ipad}-review-attachments/manifest.json with all keepAlways text payloads. Ancillary /tmp/task-46.6.1-{l10n,text,guard-self,guard,diff}-review.log and /tmp/task-46.6.1-guard-review-delta.log. Literal commands and ordering are /tmp/task-46.6.1-review-audits.sh and /tmp/task-46.6.1-review-checks.sh; runners ended REVIEW_AUDITS_EXIT=0 and REVIEW_CHECKS_EXIT=0. All Apple invocations used nohup xbuild, one destination at a time, grep polling, normal shared-lock waits and natural completion; no builds killed. No PR opened.

No full iOS/iPadOS suites were run; merge-batch suite validation remains coordinator-owned. tvOS/visionOS suites skipped because LearnViews.swift belongs only to CanadianHam (iOS/macOS), not those targets; their localization builds did run inside the required l10n check. Earlier investigation evidence remains in branch history and /tmp/task-46.6.1-*; prior blocked statements are superseded, AC1-3 are now verified.

Every ignored contrast finding from these final selections (unchanged TASK-71 local helper, only new feedback methods; unchanged existing hint helper for the existing hint methods):

- iphone CanadianHamExamToolsUITests/testLessonQuizConceptOptionCorrectDarkAndFullAccessibilityAudit()
  label=A parts list needs 0.82 A. A meter on the same accessory reads 820 mA. What should the learner conclude? frame=x: 40.0, y: 92.63623046874994, width: 313.33333333333326, height: 98.99999999999997 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true
  Attachment: /tmp/task-46.6.1-iphone-review-attachments/89084F88-EF48-40A3-B888-31E66A7CB140.txt

- iphone CanadianHamExamToolsUITests/testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit()
  label=The readings differ by a factor of one hundred. frame=(110.0, 257.60579427083337, 233.66666666666669, 42.33333333333337) ratio=12.204207186018708:1
  Attachment: /tmp/task-46.6.1-iphone-review-attachments/B0141213-4675-45EE-9344-9A84F7DD4F03.txt

- iphone CanadianHamExamToolsUITests/testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit()
  label=A parts list needs 0.82 A. A meter on the same accessory reads 820 mA. What should the learner conclude? frame=(40.0, 130.60579427083337, 313.33333333333326, 99.0) ratio=12.628753100147408:1
  Attachment: /tmp/task-46.6.1-iphone-review-attachments/60FDBEF8-1C2D-4AD8-871E-63B0CAFEC0AB.txt

- iphone CanadianHamExamToolsUITests/testLessonQuizHintsDarkAndFullAccessibilityAudits()
  label=1 questions: official bank questions update practice progress; concept checks do not. frame=x: 40.0, y: 26.666666666666544, width: 201.66666666666666, height: 86.33333333333334 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true
  Attachment: /tmp/task-46.6.1-iphone-review-attachments/5103E596-4267-46CD-874C-277D16F88063.txt

- iphone CanadianHamExamToolsUITests/testLessonQuizHintsDarkAndFullAccessibilityAudits()
  label=QZ-L-005-01-A frame=x: 40.0, y: -7.666666666666785, width: 160.0, height: 26.33333333333333 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true
  Attachment: /tmp/task-46.6.1-iphone-review-attachments/1CE46773-56CF-4E52-A912-0150E9ED4E7D.txt

- iphone CanadianHamExamToolsUITests/testLessonQuizHintsLightAndFullAccessibilityAudits()
  label=1 questions: official bank questions update practice progress; concept checks do not. frame=x: 40.0, y: 26.666666666666544, width: 201.66666666666666, height: 86.33333333333334 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true
  Attachment: /tmp/task-46.6.1-iphone-review-attachments/883EB462-2689-4529-805F-234DFE7C3892.txt

- ipad CanadianHamExamToolsUITests/testLessonQuizConceptOptionFeedbackLargestDynamicType()
  label=Concept check · QZ-L-005-01-A-C1 frame=(76.0, 643.0, 678.5, 51.5) ratio=7.0846875417190045:1
  Attachment: /tmp/task-46.6.1-ipad-review-attachments/E9AD1A92-4F10-4DCD-8A5E-6BDAB501D499.txt

- ipad CanadianHamExamToolsUITests/testLessonQuizConceptOptionFeedbackLargestDynamicType()
  label=Concept check · QZ-L-005-01-A-C1 frame=(76.0, 643.0, 678.5, 51.5) ratio=7.0846875417190045:1
  Attachment: /tmp/task-46.6.1-ipad-review-attachments/FC7009D0-247D-478A-9F6F-0686295CB905.txt

Complete macOS unit per-test results (documented command, 214/214 PASS):

| macOS unit test | Result | Seconds |
|---|---|---|
| CanadianHamTests.DuoLayoutPolicyTests.testCompactWidthIPhoneKeepsSheetPolicy | PASSED | 0.001 |
| CanadianHamTests.DuoLayoutPolicyTests.testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact | PASSED | 0.001 |
| CanadianHamTests.DuoLayoutPolicyTests.testIPadInspectorRuleRemainsSizeClassDriven | PASSED | 0.001 |
| CanadianHamTests.DuoLayoutPolicyTests.testMacAndOtherIdiomsNeverUseIPhonePolicy | PASSED | 0.001 |
| CanadianHamTests.DuoLayoutPolicyTests.testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy | PASSED | 0.001 |
| CanadianHamTests.DuoLayoutPolicyTests.testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact | PASSED | 0.001 |
| CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp | PASSED | 0.001 |
| CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys | PASSED | 0.001 |
| CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere | PASSED | 0.001 |
| CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds | PASSED | 0.001 |
| CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes | PASSED | 0.001 |
| CanadianHamTests.ExamCalculatorViewModelTests.testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale | PASSED | 0.001 |
| CanadianHamTests.ExamCalculatorViewModelTests.testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString | PASSED | 0.001 |
| CanadianHamTests.ExamCalculatorViewModelTests.testKeyHandlingProducesEngineDisplayAndSpokenResult | PASSED | 0.001 |
| CanadianHamTests.ExamCalculatorViewModelTests.testOfficialReferenceSheetGateAndBundledPages | PASSED | 0.001 |
| CanadianHamTests.ExamCalculatorViewModelTests.testQuestionCardFocusResetKeepsTextSelectionEnabled | PASSED | 0.004 |
| CanadianHamTests.ExamCalculatorViewModelTests.testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet | PASSED | 0.001 |
| CanadianHamTests.ExamCalculatorViewModelTests.testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekEndsWhenPhoneFullyOpensOrCloses | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekFastUnfoldThroughBandNeverPeeks | PASSED | 0.000 |
| CanadianHamTests.HintSessionStateTests.testHingePeekLeavingToleranceDoesNotResetDismissalSuppression | PASSED | 0.000 |
| CanadianHamTests.HintSessionStateTests.testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly | PASSED | 0.000 |
| CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp | PASSED | 0.394 |
| CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute | PASSED | 0.292 |
| CanadianHamTests.HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp | PASSED | 0.002 |
| CanadianHamTests.HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable | PASSED | 0.001 |
| CanadianHamTests.HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp | PASSED | 0.002 |
| CanadianHamTests.HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission | PASSED | 0.002 |
| CanadianHamTests.HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange | PASSED | 2.558 |
| CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata | PASSED | 0.003 |
| CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection | PASSED | 0.002 |
| CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusMapsShuffledSourceChoices | PASSED | 0.003 |
| CanadianHamTests.LocalizationCatalogTests.testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext | PASSED | 0.001 |
| CanadianHamTests.LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations | PASSED | 0.013 |
| CanadianHamTests.LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries | PASSED | 0.004 |
| CanadianHamTests.LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides | PASSED | 0.001 |
| CanadianHamTests.LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish | PASSED | 0.001 |
| CanadianHamTests.LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale | PASSED | 0.003 |
| CanadianHamTests.MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer | PASSED | 0.001 |
| CanadianHamTests.MorseTrainerTests.testFixedTimingProfilesUseEngineValues | PASSED | 0.001 |
| CanadianHamTests.MorseTrainerTests.testLessonBodyAndBulletContrastTokensMeetMinimumRatio | PASSED | 0.001 |
| CanadianHamTests.MorseTrainerTests.testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession | PASSED | 1.674 |
| CanadianHamTests.MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp | PASSED | 0.002 |
| CanadianHamTests.MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases | PASSED | 0.002 |
| CanadianHamTests.MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins | PASSED | 0.002 |
| CanadianHamTests.MorseTrainerTests.testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas | PASSED | 0.002 |
| CanadianHamTests.MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters | PASSED | 0.002 |
| CanadianHamTests.MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone | PASSED | 0.002 |
| CanadianHamTests.MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse | PASSED | 0.001 |
| CanadianHamTests.MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition | PASSED | 0.001 |
| CanadianHamTests.MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints | PASSED | 0.002 |
| CanadianHamTests.MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime | PASSED | 0.001 |
| CanadianHamTests.MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying | PASSED | 0.107 |
| CanadianHamTests.MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal | PASSED | 0.003 |
| CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesPressWhenAudioFails | PASSED | 0.006 |
| CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended | PASSED | 0.002 |
| CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError | PASSED | 0.105 |
| CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone | PASSED | 0.004 |
| CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReleaseCannotBeSupersededBySilence | PASSED | 0.006 |
| CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress | PASSED | 0.110 |
| CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError | PASSED | 0.108 |
| CanadianHamTests.MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears | PASSED | 0.002 |
| CanadianHamTests.MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline | PASSED | 0.001 |
| CanadianHamTests.MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters | PASSED | 0.001 |
| CanadianHamTests.MorseTrainerTests.testMorseSettingsClampAndPreset | PASSED | 0.002 |
| CanadianHamTests.MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode | PASSED | 0.002 |
| CanadianHamTests.MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled | PASSED | 0.002 |
| CanadianHamTests.MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast | PASSED | 0.007 |
| CanadianHamTests.MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults | PASSED | 0.004 |
| CanadianHamTests.MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine | PASSED | 0.001 |
| CanadianHamTests.MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced | PASSED | 0.001 |
| CanadianHamTests.MorseTrainerTests.testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess | PASSED | 0.044 |
| CanadianHamTests.MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags | PASSED | 0.001 |
| CanadianHamTests.MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon | PASSED | 0.001 |
| CanadianHamTests.MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback | PASSED | 0.001 |
| CanadianHamTests.MorseTrainerTests.testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess | PASSED | 0.035 |
| CanadianHamTests.ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress | PASSED | 0.072 |
| CanadianHamTests.ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts | PASSED | 0.024 |
| CanadianHamTests.ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch | PASSED | 0.004 |
| CanadianHamTests.ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync | PASSED | 0.001 |
| CanadianHamTests.ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement | PASSED | 0.001 |
| CanadianHamTests.ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows | PASSED | 0.000 |
| CanadianHamTests.ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore | PASSED | 0.021 |
| CanadianHamTests.ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields | PASSED | 0.032 |
| CanadianHamTests.ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme | PASSED | 0.029 |
| CanadianHamTests.ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker | PASSED | 0.017 |
| CanadianHamTests.ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt | PASSED | 0.056 |
| CanadianHamTests.ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem | PASSED | 0.011 |
| CanadianHamTests.ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory | PASSED | 0.061 |
| CanadianHamTests.ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot | PASSED | 0.031 |
| CanadianHamTests.ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete | PASSED | 0.026 |
| CanadianHamTests.ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload | PASSED | 0.139 |
| CanadianHamTests.ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent | PASSED | 0.002 |
| CanadianHamTests.ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal | PASSED | 0.001 |
| CanadianHamTests.ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress | PASSED | 0.044 |
| CanadianHamTests.ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing | PASSED | 0.033 |
| CanadianHamTests.ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields | PASSED | 0.034 |
| CanadianHamTests.ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount | PASSED | 0.045 |
| CanadianHamTests.ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons | PASSED | 0.068 |
| CanadianHamTests.ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange | PASSED | 0.034 |
| CanadianHamTests.ProgressStoreTests.testImportLeavesTask4610Version2LessonSplitRowsUnchanged | PASSED | 0.034 |
| CanadianHamTests.ProgressStoreTests.testImportMigratesMixedTask4610SyncRowsByRowVersion | PASSED | 0.038 |
| CanadianHamTests.ProgressStoreTests.testImportMigratesTask4610LessonSplitProgressAndQuizAttempts | PASSED | 0.036 |
| CanadianHamTests.ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress | PASSED | 0.032 |
| CanadianHamTests.ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows | PASSED | 0.037 |
| CanadianHamTests.ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues | PASSED | 0.040 |
| CanadianHamTests.ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses | PASSED | 0.072 |
| CanadianHamTests.ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails | PASSED | 0.044 |
| CanadianHamTests.ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure | PASSED | 0.031 |
| CanadianHamTests.ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress | PASSED | 0.032 |
| CanadianHamTests.ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt | PASSED | 0.035 |
| CanadianHamTests.ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues | PASSED | 0.001 |
| CanadianHamTests.ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates | PASSED | 0.042 |
| CanadianHamTests.ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates | PASSED | 0.046 |
| CanadianHamTests.ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress | PASSED | 0.037 |
| CanadianHamTests.ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId | PASSED | 0.036 |
| CanadianHamTests.ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt | PASSED | 0.032 |
| CanadianHamTests.ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges | PASSED | 0.031 |
| CanadianHamTests.ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults | PASSED | 0.038 |
| CanadianHamTests.ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference | PASSED | 0.012 |
| CanadianHamTests.ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault | PASSED | 0.017 |
| CanadianHamTests.ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue | PASSED | 0.012 |
| CanadianHamTests.ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue | PASSED | 0.012 |
| CanadianHamTests.ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries | PASSED | 0.011 |
| CanadianHamTests.ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun | PASSED | 0.011 |
| CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting | PASSED | 0.010 |
| CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce | PASSED | 0.008 |
| CanadianHamTests.ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure | PASSED | 0.030 |
| CanadianHamTests.ProgressStoreTests.testLessonQuizHelpFixtureValidationAndPayloadRoundTrips | PASSED | 0.133 |
| CanadianHamTests.ProgressStoreTests.testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix | PASSED | 0.034 |
| CanadianHamTests.ProgressStoreTests.testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice | PASSED | 2.764 |
| CanadianHamTests.ProgressStoreTests.testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation | PASSED | 0.002 |
| CanadianHamTests.ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead | PASSED | 0.057 |
| CanadianHamTests.ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution | PASSED | 0.049 |
| CanadianHamTests.ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution | PASSED | 0.033 |
| CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount | PASSED | 0.011 |
| CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist | PASSED | 0.033 |
| CanadianHamTests.ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact | PASSED | 0.508 |
| CanadianHamTests.ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity | PASSED | 0.019 |
| CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints | PASSED | 0.067 |
| CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields | PASSED | 0.074 |
| CanadianHamTests.ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder | PASSED | 0.001 |
| CanadianHamTests.ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults | PASSED | 0.035 |
| CanadianHamTests.ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio | PASSED | 0.001 |
| CanadianHamTests.ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences | PASSED | 0.051 |
| CanadianHamTests.ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues | PASSED | 0.001 |
| CanadianHamTests.ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums | PASSED | 0.036 |
| CanadianHamTests.ProgressStoreTests.testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender | PASSED | 0.953 |
| CanadianHamTests.ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference | PASSED | 0.014 |
| CanadianHamTests.ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences | PASSED | 0.014 |
| CanadianHamTests.ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows | PASSED | 0.036 |
| CanadianHamTests.ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt | PASSED | 0.010 |
| CanadianHamTests.ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences | PASSED | 0.039 |
| CanadianHamTests.ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse | PASSED | 0.033 |
| CanadianHamTests.ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints | PASSED | 0.039 |
| CanadianHamTests.ProgressStoreTests.testProgressStoreRoundTripExportImportReset | PASSED | 0.065 |
| CanadianHamTests.ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff | PASSED | 0.013 |
| CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData | PASSED | 0.028 |
| CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure | PASSED | 0.045 |
| CanadianHamTests.ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference | PASSED | 0.013 |
| CanadianHamTests.ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference | PASSED | 0.013 |
| CanadianHamTests.ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails | PASSED | 0.013 |
| CanadianHamTests.ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext | PASSED | 1.795 |
| CanadianHamTests.ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates | PASSED | 0.010 |
| CanadianHamTests.ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules | PASSED | 0.001 |
| CanadianHamTests.ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries | PASSED | 0.010 |
| CanadianHamTests.ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress | PASSED | 0.083 |
| CanadianHamTests.ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists | PASSED | 0.059 |
| CanadianHamTests.ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite | PASSED | 0.036 |
| CanadianHamTests.ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration | PASSED | 0.009 |
| CanadianHamTests.ProgressStoreTests.testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices | PASSED | 0.043 |
| CanadianHamTests.ProgressStoreTests.testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports | PASSED | 0.037 |
| CanadianHamTests.ProgressStoreTests.testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration | PASSED | 0.029 |
| CanadianHamTests.ProgressStoreTests.testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds | PASSED | 0.029 |
| CanadianHamTests.ProgressStoreTests.testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating | PASSED | 0.109 |
| CanadianHamTests.ProgressStoreTests.testTask4610SharedConceptMappingAndConceptInclusiveScores | PASSED | 0.237 |
| CanadianHamTests.ProgressStoreTests.testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows | PASSED | 0.041 |
| CanadianHamTests.ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync | PASSED | 0.062 |
| CanadianHamTests.QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames | PASSED | 0.012 |
| CanadianHamTests.QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours | PASSED | 0.013 |
| CanadianHamTests.QuestionBankTests.testAppBundleContainsNoReadmeFiles | PASSED | 0.013 |
| CanadianHamTests.QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories | PASSED | 0.001 |
| CanadianHamTests.QuestionBankTests.testBundledJSONDecodesExpectedCounts | PASSED | 0.018 |
| CanadianHamTests.QuestionBankTests.testBundledLessonModelExposesPrerequisites | PASSED | 0.561 |
| CanadianHamTests.QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary | PASSED | 0.746 |
| CanadianHamTests.QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory | PASSED | 0.019 |
| CanadianHamTests.QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion | PASSED | 0.078 |
| CanadianHamTests.QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes | PASSED | 0.001 |
| CanadianHamTests.QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons | PASSED | 0.567 |
| CanadianHamTests.ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours | PASSED | 0.001 |
| CanadianHamTests.ReadinessAndScoringTests.testExamScoringBoundaries | PASSED | 0.001 |
| CanadianHamTests.ReadinessAndScoringTests.testReadinessStates | PASSED | 0.001 |
| CanadianHamTests.ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate | PASSED | 0.037 |
| CanadianHamTests.RootNavigationMappingTests.testCompactHomeSessionAndSectionPushesUseVisibleDestination | PASSED | 0.001 |
| CanadianHamTests.RootNavigationMappingTests.testEmptyCompactPathMapsToHome | PASSED | 0.001 |
| CanadianHamTests.RootNavigationMappingTests.testEveryLearnRouteRoundTripsWithItsWholeStack | PASSED | 0.001 |
| CanadianHamTests.RootNavigationMappingTests.testEveryRootSelectionRoundTrips | PASSED | 0.001 |
| CanadianHamTests.RootNavigationMappingTests.testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts | PASSED | 0.001 |
| CanadianHamTests.RootNavigationMappingTests.testPracticeHintLessonStackKeepsSessionAsSplitSelection | PASSED | 0.001 |
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented source-indexed post-answer option feedback with retained explanation and EN/FR fallback metadata. Review fixes restrict accessibility focus to a newly chosen answer via a tested one-shot request and use sentence correctness keys (existing Correct.; new Incorrect. with French translations). Trimmed superseded blocked notes. Final validation passed without retries/skips: unchanged LearnFlow light/dark audits 2/2 on each iPhone/iPad, all 12 targeted lesson-quiz methods on each device, full documented macOS units 214/214, localization with unchanged catalogue hash, text sources, guard self-test, approved whole-branch guard, clean review-delta guard and diff checks. Existing tests/shared helpers unchanged. All per-test results and all eight contrast attachment payloads are recorded in notes; four measured findings >=4.5:1 and four occlusion-only findings. No PR opened. Manual VoiceOver speech/focus remains unexercised; full iOS suites remain for coordinator merge-batch validation.
<!-- SECTION:FINAL_SUMMARY:END -->
