# TASK-14.2 — watchOS quick Basic practice

2026-10-25. Branch: `task-14.2-watch-practice`. No PR or TestFlight upload was
created by this task. Final targeted watch run used
`640ddb3ed42017bd2d4b9f88b1c0f3f76eca17de`; later commits only record evidence and
Backlog completion. The app implementation last changed in `6ab36d0c` and the
UI navigation helpers in `9746cbff`.

## Implementation and acceptance evidence

- The watch target alone adds the unchanged `basic-2025-07-15` folder and
  explanations. It removes the authoring README after copying. No Advanced,
  hints, lessons, quizzes or figures are in its bundle. Existing targets' bank
  membership is unchanged.
- `WatchPracticeBank` decodes content-swift question, metadata and explanation
  models, validates the 984 unique questions/four bilingual answers and matching
  explanations, and uses `ExplanationBodyParser` without requiring lessons or
  `ContentLibrary.load`. Bundle tests compare the exact expected JSON path set.
  Independent installed-bundle inspection additionally compared **988 files
  byte-for-byte** with the repository: 4 Basic JSON files + 984 explanations.
- `WatchPracticeSession` uses engine-swift `Pcg32`/`shuffled` and grades the
  retained `sourceIndex`. Twenty seeded draws test correct and wrong shuffled
  positions, deterministic order, invalid submissions, locking and Next. Next
  excludes the previous question when more than one exists. Empty/throwing loads
  produce a localized unavailable state rather than an index error.
- Tapping an answer submits immediately. The separate Crown sheet attaches
  `digitalCrownRotation` to its **focusable scroll container**; selection alone
  cannot submit. It also exposes an accessibility-adjustable action. An explicit
  Confirm button submits, and touch scrolling can read long choices without
  changing the selection. Native nested Picker/Text focus prototypes let the
  containing scroll view consume Crown events; they were replaced, not shipped.
- The watchOS XCUIAutomation header exposes
  `XCUIDevice.shared.rotateDigitalCrown(delta:)`; the final UI test uses real
  Crown events and observes **all four answer texts before Confirm**, with no
  feedback/submission during rotation. `adjust(toPickerWheelValue:)` is not
  available on watchOS and is not used. No test-only submission/selection hook
  or runtime fallback replaces Crown input.
- Feedback locks the choices and gives textual correct/incorrect, selected
  answer, correct answer and the existing complete explanation, then Next.
  Content is scrollable, uses semantic fonts, and has no `minimumScaleFactor`,
  hints, lesson navigation or colour-only correctness. Answer accessibility
  labels contain the answer text and selected/not-selected values.
- All explanation bodies currently lack French. French UI labels the fallback
  **« Explication en anglais »**, and the attributed body is tagged **en-CA**.
  Unit tests check all 984 fallback bodies/language runs plus a translated-body
  fixture; French UI tests check actual feedback, fallback label and Next.
  No official EN/FR stem or answer and no explanation translation was authored.
- State is a view-owned in-memory session; no score/history/settings store,
  preferences, files written by the app, App Groups, network or transfer layer
  was added. Unit tests construct a fresh unanswered session and the UI test
  answers, advances, answers again, terminates/relaunches and verifies an
  unanswered practice screen. During the final watch run, `simctl listapps` on
  its automatically booted paired iPhone Air simulator confirmed that
  **`org.davidjensenius.CanadianHam` was not installed**. The watch loaded and
  practiced using only its own resources, with no phone counterpart. The bank
  and privacy guards verify no networking code/capability was introduced.

## Measurements (installed Debug WatchSimulator, not a hardware/release claim)

Destination: Apple Watch Series 12 (42mm), watchOS 27.0. The cold-load probe is
sorted first, before any other practice-bank test; its timed interval covers all
JSON decoding and validation, including the explanation parser. A keepAlways
attachment records its output. Resident bytes use `mach_task_basic_info` before
and after retaining the decoded bank; these are process-resident snapshots, not
peak allocations. The XCTest host/frameworks account for much of the process
baseline. A separate warm probe showed allocator reuse (0 incremental resident
bytes), so it is **not** used as the bank's memory estimate.

| Measurement | Result |
|---|---:|
| Original resources, 988 files | 2,360,969 bytes (2.25 MiB) |
| Cold complete-bank load (final run) | 0.218668292 seconds |
| Cold resident before / after | 213,843,968 / 222,003,200 bytes |
| Cold retained-bank resident delta | 8,159,232 bytes (7.78 MiB) |
| Installed app regular-file logical size, including injected test PlugIns | 16,773,998 bytes |
| Installed app allocated size, including test PlugIns (`st_blocks × 512`) | 19,832,832 bytes |
| App excluding injected test PlugIns, logical / allocated | 10,025,821 / 13,062,144 bytes |

The installed app had 1,018 files. Inspection found zero forbidden content paths;
`WKApplication` and `WKRunsIndependentlyOfCompanionApp` were true, and both
`UIBackgroundModes` and `WKBackgroundModes` were absent. The installed path was
`~/Library/Developer/CoreSimulator/Devices/02C40D35-B5AD-40AF-B434-C63C5F294C27/data/Containers/Bundle/Application/CEEE271E-F42F-426F-A512-69E14BBCA029/CanadianHamWatch.app`.
Final inspection output: `/tmp/task-14.2-final-bundle-inspection.log`.

Physical-device startup/memory, VoiceOver listening, Dynamic Type sweeps and full
accessibility audits remain the already planned TASK-14.5/14.6 gates. Simulator
numbers do not establish a hardware memory budget or signed release size.

## Commands and results

All Apple commands used `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
and **xbuild**, never direct xcodebuild. Runners were launched with `nohup`, with
log/grep polling, and waited for the shared build lock (including TestFlight
work). No other build was killed and no extra simulator destination was booted
by this task. The watch runner automatically booted its required OS-paired phone;
this was not an app-level counterpart or transfer dependency.

```sh
# Initial full watch run; it exposed the UI/focus issues fixed above.
xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' \
  test CODE_SIGNING_ALLOWED=NO

# Practice unit class rerun: all 7 passed (the 3 skeleton units also passed above).
xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' \
  -only-testing:CanadianHamWatchTests/WatchPracticeTests \
  -only-testing:CanadianHamWatchUITests/WatchPracticeUITests \
  test CODE_SIGNING_ALLOWED=NO

# Final unchanged-source targeted run: cold measurement + both practice UI tests, 3/3 passed.
xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' \
  -only-testing:CanadianHamWatchTests/WatchPracticeTests/testAColdBundledPracticeLoadMeasurements \
  -only-testing:CanadianHamWatchUITests/WatchPracticeUITests \
  test CODE_SIGNING_ALLOWED=NO

pnpm check:apple-l10n
node scripts/check-apple-text-sources.ts --self-test
node scripts/check-apple-text-sources.ts
pnpm check:apple-network
pnpm test:apple-network
pnpm check:apple-icloud-gate
pnpm test:apple-icloud-gate
node scripts/check-test-guard.mjs --self-test
node scripts/check-test-guard.mjs --base main

xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build-for-testing CODE_SIGNING_ALLOWED=NO
xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests \
  test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES

(cd apps/apple && /opt/homebrew/bin/xcodegen generate --spec project.yml)
(cd apps/apple && /opt/homebrew/bin/xcodegen generate --spec project.yml)
git diff --exit-code -- apps/apple/CanadianHam.xcodeproj
git diff --check
```

- **14 distinct watch tests passed** across the focused runs below; the original
  full run was not green because of the subsequently fixed UI issues. Fix rounds
  ran only the affected class/methods, per repository policy. There are no
  unresolved test failures and no audit/skip exceptions were added.
- **223 macOS unit tests passed** (the full unit target, required because the
  shared string catalogue changed). iOS container **TEST BUILD SUCCEEDED**.
- Localization passed: complete French export, text-source check/self-test,
  tvOS/visionOS/watch generic simulator builds, and catalogue hashes unchanged.
  Catalogue edits used a Python JSON round-trip preserving existing key order.
- Network/iCloud guards and fixtures passed. Test guard/self-test passed, with no
  guarded changes/approval marker needed. Both XcodeGen passes matched the
  committed project; the determinism diff and whitespace check were empty.
- iOS UI/unit runtime suites and tvOS/visionOS runtime suites were not run for
  this watch feature; only the required embedded build, localization builds and
  macOS catalogue regression gate ran. Full affected-platform merge-batch suites
  are coordinator gates. Lesson figures/title sweeps were not relevant. Full
  watch accessibility audits belong to TASK-14.5, not this task.
- Existing plural-inference/AppIntents warnings and the test runner's failed
  optional diagnostic collection (`simctl` lookup in its subprocess) were
  non-fatal; the final xbuild returned 0 and reported TEST SUCCEEDED.

Logs: `/tmp/task-14.2-watch.log` (final),
`/tmp/task-14.2-watch-first-tests.log` (initial full),
`/tmp/task-14.2-watch-targeted-2.log` (practice units),
`/tmp/task-14.2-watch-crown-passed.log` (first successful focused Crown run),
`/tmp/task-14.2-{localization,ios-container,macos}.log`, and
`/tmp/task-14.2-checks.log` (all three exit 0).

## Watch per-test results

Skeleton tests below passed in the initial full run at app source `4706b2d8`.
Practice units passed at `2409d1bb`; model/loader code did not change afterward.
The cold probe and both practice UI rows use the final immutable `640ddb3e` run.

| Test | Result | Duration |
|---|---|---|
| `CanadianHamWatchTests.CanadianHamWatchTests.testIndependentOfflineBundle` | passed | 0.004 seconds |
| `CanadianHamWatchTests.CanadianHamWatchTests.testPlannedSections` | passed | 0.001 seconds |
| `CanadianHamWatchTests.CanadianHamWatchTests.testSharedPackagesOnWatch` | passed | 0.003 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testAColdBundledPracticeLoadMeasurements` | passed | 0.231 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testEmptyLoadErrorAndMissingResourcesFailSafely` | passed | 0.005 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testFrenchExplanationFallbackHasEnglishAccessibilityLanguage` | passed | 0.164 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testMeasureBundledPracticeLoad` | passed | 0.141 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testNewSessionRestoresNeitherAnswerNorQuestionSequence` | passed | 0.140 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testSeededShuffleGradesSourceIndexNotDisplayPositionAndLocksSubmission` | passed | 0.153 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testWatchBundleContainsCompleteBasicBankAndOnlyPracticeContent` | passed | 0.160 seconds |
| `CanadianHamWatchUITests.CanadianHamWatchUITests.testLaunchAndNavigateEnglish` | passed | 18.280 seconds |
| `CanadianHamWatchUITests.CanadianHamWatchUITests.testLaunchAndNavigateFrench` | passed | 14.932 seconds |
| `CanadianHamWatchUITests.WatchPracticeUITests.testCrownSelectionRequiresConfirmAndFrenchFeedbackLabelsEnglishFallback` | passed | 49.691 seconds |
| `CanadianHamWatchUITests.WatchPracticeUITests.testTapFeedbackNextAndRelaunchDoesNotRestoreAnswer` | passed | 42.304 seconds |

Result bundles (under `~/Library/Developer/Xcode/DerivedData/CanadianHam-gpcrwrqyugpkhugopywamwhwiyth/Logs/Test/`):
- Initial: `Test-CanadianHamWatch-2026.10.25_14-07-25--0400.xcresult`.
- Practice units: `Test-CanadianHamWatch-2026.10.25_14-16-30--0400.xcresult`.
- Final: `Test-CanadianHamWatch-2026.10.25_14-36-08--0400.xcresult`.

## Full macOS unit target per-test results (223)

Result bundle: `~/Library/Developer/Xcode/DerivedData/CanadianHam-gpcrwrqyugpkhugopywamwhwiyth/Logs/Test/Test-CanadianHam-2026.10.25_14-35-03--0400.xcresult`.
App and catalogue code were unchanged during this run.

| Test | Result | Duration |
|---|---|---|
| `CanadianHamTests.DuoLayoutPolicyTests.testCompactWidthIPhoneKeepsSheetPolicy` | passed | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests.testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact` | passed | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests.testIPadInspectorRuleRemainsSizeClassDriven` | passed | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests.testMacAndOtherIdiomsNeverUseIPhonePolicy` | passed | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests.testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy` | passed | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests.testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` | passed | 0.000 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes` | passed | 0.000 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testKeyHandlingProducesEngineDisplayAndSpokenResult` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testOfficialReferenceSheetGateAndBundledPages` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testQuestionCardFocusResetKeepsTextSelectionEnabled` | passed | 0.004 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekEndsWhenPhoneFullyOpensOrCloses` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekFastUnfoldThroughBandNeverPeeks` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekLeavingToleranceDoesNotResetDismissalSuppression` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression` | passed | 0.000 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` | passed | 0.391 seconds |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute` | passed | 0.298 seconds |
| `CanadianHamTests.HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` | passed | 0.002 seconds |
| `CanadianHamTests.HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` | passed | 2.569 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata` | passed | 0.003 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection` | passed | 0.002 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusMapsShuffledSourceChoices` | passed | 0.002 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext` | passed | 0.002 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations` | passed | 0.012 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` | passed | 0.004 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides` | passed | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish` | passed | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale` | passed | 0.003 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testReviewHeadingMarksEnglishFallbackTitleInsideFrenchText` | passed | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testFixedTimingProfilesUseEngineValues` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testLessonBodyAndBulletContrastTokensMeetMinimumRatio` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession` | passed | 1.712 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` | passed | 0.003 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` | passed | 0.106 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesPressWhenAudioFails` | passed | 0.007 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError` | passed | 0.104 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone` | passed | 0.005 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReleaseCannotBeSupersededBySilence` | passed | 0.005 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError` | passed | 0.106 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsClampAndPreset` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` | passed | 0.011 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults` | passed | 0.003 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | passed | 0.040 seconds |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` | passed | 0.078 seconds |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts` | passed | 0.023 seconds |
| `CanadianHamTests.ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` | passed | 0.003 seconds |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` | passed | 0.019 seconds |
| `CanadianHamTests.ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields` | passed | 0.031 seconds |
| `CanadianHamTests.ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` | passed | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` | passed | 0.016 seconds |
| `CanadianHamTests.ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` | passed | 0.056 seconds |
| `CanadianHamTests.ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem` | passed | 0.014 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory` | passed | 0.067 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` | passed | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete` | passed | 0.026 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` | passed | 0.140 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent` | passed | 0.003 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` | passed | 0.049 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` | passed | 0.035 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` | passed | 0.043 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` | passed | 0.061 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportLeavesTask4610Version2LessonSplitRowsUnchanged` | passed | 0.036 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesMixedTask4610SyncRowsByRowVersion` | passed | 0.040 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesTask4610LessonSplitProgressAndQuizAttempts` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues` | passed | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` | passed | 0.069 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails` | passed | 0.043 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure` | passed | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` | passed | 0.033 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress` | passed | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` | passed | 0.031 seconds |
| `CanadianHamTests.ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` | passed | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` | passed | 0.013 seconds |
| `CanadianHamTests.ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue` | passed | 0.009 seconds |
| `CanadianHamTests.ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` | passed | 0.008 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyEmptyReviewQuestionIdsImportAtTopLevelAndInSyncRows` | passed | 0.092 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` | passed | 0.008 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` | passed | 0.007 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` | passed | 0.028 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpFixtureValidationAndPayloadRoundTrips` | passed | 0.129 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix` | passed | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice` | passed | 2.748 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation` | passed | 0.002 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` | passed | 0.051 seconds |
| `CanadianHamTests.ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` | passed | 0.049 seconds |
| `CanadianHamTests.ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testM1QuizRoundBoundariesPreserveOneSessionAnswersHelpAndDismissedCheckpoint` | passed | 0.548 seconds |
| `CanadianHamTests.ProgressStoreTests.testM1QuizRoundsRetainEveryItemAndSeededOrderWithinTeachingSections` | passed | 0.554 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` | passed | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` | passed | 0.033 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` | passed | 0.400 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` | passed | 0.019 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` | passed | 0.072 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` | passed | 0.075 seconds |
| `CanadianHamTests.ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` | passed | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences` | passed | 0.053 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests.testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender` | passed | 0.965 seconds |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` | passed | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` | passed | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreRoundTripExportImportReset` | passed | 0.059 seconds |
| `CanadianHamTests.ProgressStoreTests.testQuizRoundsWithConceptChecksKeepTheCompleteUngroupedOrder` | passed | 0.537 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff` | passed | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` | passed | 0.027 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` | passed | 0.043 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference` | passed | 0.013 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference` | passed | 0.013 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails` | passed | 0.014 seconds |
| `CanadianHamTests.ProgressStoreTests.testReviewAttemptPayloadImportSyncAndLegacyVersionRejection` | passed | 0.055 seconds |
| `CanadianHamTests.ProgressStoreTests.testReviewItemsUseEarlierTaughtPoolsAndFinalM1Round` | passed | 1.647 seconds |
| `CanadianHamTests.ProgressStoreTests.testReviewSourceMayDifferFromCanonicalHintLessonWithAuthoredSectionAnchor` | passed | 0.552 seconds |
| `CanadianHamTests.ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext` | passed | 1.749 seconds |
| `CanadianHamTests.ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` | passed | 0.006 seconds |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` | passed | 0.088 seconds |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` | passed | 0.063 seconds |
| `CanadianHamTests.ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` | passed | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` | passed | 0.009 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices` | passed | 0.042 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports` | passed | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration` | passed | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds` | passed | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating` | passed | 0.098 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610SharedConceptMappingAndConceptInclusiveScores` | passed | 0.236 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows` | passed | 0.040 seconds |
| `CanadianHamTests.ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` | passed | 0.053 seconds |
| `CanadianHamTests.QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` | passed | 0.012 seconds |
| `CanadianHamTests.QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` | passed | 0.013 seconds |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsNoReadmeFiles` | passed | 0.014 seconds |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories` | passed | 0.001 seconds |
| `CanadianHamTests.QuestionBankTests.testBundledJSONDecodesExpectedCounts` | passed | 0.019 seconds |
| `CanadianHamTests.QuestionBankTests.testBundledLessonModelExposesPrerequisites` | passed | 0.564 seconds |
| `CanadianHamTests.QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary` | passed | 0.730 seconds |
| `CanadianHamTests.QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` | passed | 0.019 seconds |
| `CanadianHamTests.QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` | passed | 0.078 seconds |
| `CanadianHamTests.QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` | passed | 0.001 seconds |
| `CanadianHamTests.QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` | passed | 0.555 seconds |
| `CanadianHamTests.ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours` | passed | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests.testExamScoringBoundaries` | passed | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests.testReadinessStates` | passed | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` | passed | 0.035 seconds |
| `CanadianHamTests.RootNavigationMappingTests.testCompactHomeSessionAndSectionPushesUseVisibleDestination` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests.testEmptyCompactPathMapsToHome` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests.testEveryLearnRouteRoundTripsWithItsWholeStack` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests.testEveryRootSelectionRoundTrips` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests.testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests.testPracticeHintLessonStackKeepsSessionAsSplitSelection` | passed | 0.001 seconds |
