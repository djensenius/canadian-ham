# TASK-14.1 watchOS skeleton validation

2026-10-25. Original implementation commit: `5ec2f699d37e41cef40044911158d1781e33bdee`.
The original runs below did **not** all use this commit; see the run provenance
section. Review-fix runs and signed exports are recorded separately below.
All Apple commands used `xbuild`, never a
direct build-tool invocation. Checks were launched using `nohup` and polled with
`grep`; all shared-lock waits were respected, including TASK-29's tvOS lane.

## Implementation and membership

- `CanadianHamWatch`, `CanadianHamWatchTests`, `CanadianHamWatchUITests` and the
  shared watch scheme target watchOS **27.0**, device family 4.
- App/test sources are watch-specific. All three local packages explicitly add
  `.watchOS(.v27)` while retaining iOS/macOS/tvOS/visionOS 27. Their Foundation/os
  sources needed no compatibility guards. Phone Core Haptics and CloudKit
  services are **not** watch source members.
- UI strings share `CanadianHam/Resources/Localizable.xcstrings` to reuse EN/FR
  translations without maintaining a second copy; only `Alphabet` is new.
  Watch bundle metadata uses its own `Resources/InfoPlist.xcstrings` with
  EN/fr/fr-CA values so Xcode exports the generated watch Info.plist consistently.
  Both catalogues are hash-checked against mutation by the localization script.
- XcodeGen's `destinationFilters: [iOS]` emits an iOS-only watch dependency and
  `Embed Watch Content` phase. macOS retains no watch build dependency. The iOS
  log confirms copying `CanadianHam.app/Watch/CanadianHamWatch.app` and successful
  `ValidateEmbeddedBinary`.
- Watch launch does not require an iOS app session, app-level pairing or any
  transfer framework. Direct watch UI launches passed in both languages.
- Watch privacy manifest has tracking false and empty tracking domains, collected
  data types and accessed API types. The recursive network guard scans watch
  sources/resources; watch paths do not receive the optional CloudKit exemption.
  Regression fixtures reject watch CloudKit even behind the gate, WatchConnectivity
  imports/session symbols, inherited cloud compilation flags, push background
  modes and non-empty watch entitlements. All watch configurations override
  `OTHER_SWIFT_FLAGS` and `CODE_SIGN_ENTITLEMENTS` to empty strings.

## Commands and outcomes

All `xbuild`/`swift` commands below ran with
`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. No full Apple UI suite
was run. The full macOS **unit target only** was explicitly requested.

| Check | Exact command / destination | Result |
|---|---|---|
| Watch unit and UI smoke | `xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' test CODE_SIGNING_ALLOWED=NO` | **5 passed**, 0 failures; final run 17:32 UTC |
| Engine package | `swift test --package-path packages/engine-swift` | **22 passed**, 0 failures |
| Content package | `swift test --package-path packages/content-swift` | **27 passed**, 0 failures |
| Morse package | `swift test --package-path packages/morse-swift` | **4 passed**, 0 failures |
| iOS embedded container | `xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build-for-testing CODE_SIGNING_ALLOWED=NO` | **TEST BUILD SUCCEEDED**, including embedded-watch validation; final run 17:32 UTC |
| Full macOS unit target | `xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES` | **223 passed**, 0 failures |
| French export and platform builds | `pnpm check:apple-l10n` | **Passed** 17:32:59 UTC; both catalogues unchanged, no stale UI keys or missing French targets |
| tvOS build (inside localization check) | `xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamTV -destination 'generic/platform=tvOS Simulator' -derivedDataPath <temporary>/DerivedData build CODE_SIGNING_ALLOWED=NO` | **BUILD SUCCEEDED** |
| visionOS build (inside localization check) | `xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamVision -destination 'generic/platform=visionOS Simulator' -derivedDataPath <temporary>/DerivedData build CODE_SIGNING_ALLOWED=NO` | **BUILD SUCCEEDED** |
| Watch localization build | `xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch -destination 'generic/platform=watchOS Simulator' -derivedDataPath <temporary>/DerivedData build CODE_SIGNING_ALLOWED=NO` | **BUILD SUCCEEDED** |
| Text sources | `node --no-warnings scripts/check-apple-text-sources.ts` (also `--self-test` inside localization check) | **Passed** |
| Network guard + fixtures | `pnpm check:apple-network`; `bash scripts/test-check-apple-no-network.sh` | **Passed**, 81 Swift / 6 plist/privacy / 2 project config files; all fixtures passed |
| iCloud guard + fixtures | `pnpm check:apple-icloud-gate`; `node scripts/test-check-apple-icloud-gate.mjs` | **Passed** |
| Test guard + self-test | `node scripts/check-test-guard.mjs --base main`; `node scripts/check-test-guard.mjs --self-test` | **Passed**, no guarded changes |
| Resolved watch cloud configuration | `xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch -configuration DebugCloudKit -destination 'generic/platform=watchOS Simulator' -showBuildSettings` | **Passed**; WatchSimulator27.0, watchos/watchsimulator, `SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG`, no cloud flags or entitlement path |
| Regeneration | `cd apps/apple && /opt/homebrew/bin/xcodegen generate --spec project.yml` twice; `git diff --exit-code -- apps/apple/CanadianHam.xcodeproj` | **Passed**, no generated changes; also compared PBX/scheme hashes during implementation |

The successful localization check used temporary directory
`/var/folders/vn/hq32qlg16_5fnfnkl35k6x0r0000gn/T/tmp.Pwb8ManLpo` (removed by its
cleanup trap). Its export command was `xbuild -exportLocalizations -project
<worktree>/apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -derivedDataPath
<temporary>/DerivedData -localizationPath <temporary>/Localization -exportLanguage fr`.

## Original run provenance

- Original package tests (22 engine / 27 content / 4 Morse) and full macOS unit
  run (223) used `632fcda59adf58541efbf0af6d3b4abea902b10b` (17:15–17:17 UTC),
  before the three later watch-localization changes. Package tests ran on the
  macOS host; on watchOS, packages were compiled and exercised by
  `testSharedPackagesOnWatch`, not by a standalone watch package test suite.
- Final watch smoke, iOS build-for-testing, localization (including tvOS,
  visionOS and watch builds), final network/iCloud guards and final test guard
  used `5ec2f699d37e41cef40044911158d1781e33bdee` (17:28–17:33 UTC).
- The initial watch run started at `541b0b64f9ca781e509a6021803ade7de9bf13ab`;
  only task notes and the localization-check script changed while it ran.
  The resolved watch DebugCloudKit inspection started at `632fcda5` and completed
  after `b672e100249a4e170d14e1bc469e3709a9bf7b96` (watch metadata-only changes).
  Those original iteration runs were not immutable-checkout runs.
- Original text-source check used `632fcda5`; final regeneration used `5ec2f699`.
  The original self-test invocations were not pinned/logged by commit; the review
  round reruns them all on a committed, unchanged implementation instead.

## Built bundle verification

The final iOS-container watch payload's Info.plist and manifest were decoded with
Python `plistlib`:

```text
CFBundleIdentifier: org.davidjensenius.CanadianHam.watchkitapp
CFBundleSupportedPlatforms: ['WatchSimulator']
MinimumOSVersion: 27.0
WKApplication: True
WKCompanionAppBundleIdentifier: org.davidjensenius.CanadianHam
WKRunsIndependentlyOfCompanionApp: True
UIBackgroundModes: absent
NSPrivacyTracking: False
NSPrivacyTrackingDomains: []
NSPrivacyCollectedDataTypes: []
NSPrivacyAccessedAPITypes: []
```

Built simulator/debug bundle files total **6,767,393 bytes**, not an installed,
stripped or release-size claim. The skeleton has no bank/lessons/explanations;
TASK-14.2 must measure bank decode/startup/memory and installed size with the real
bundled data. No storage, networking, CloudKit, push or background session was added.

## Iteration history and limits

- Initial watch run and the resource-fix smoke run also passed all 5 tests; final
  results below are from the final metadata-catalogue version.
- Initial localization completeness failed for the two new generated watch bundle
  metadata keys. An initial legacy `*-InfoPlist.strings` approach compiled/bundled
  but did not match Xcode's synthetic export path. Replacing only watch metadata
  with `InfoPlist.xcstrings` fixed the export; the temporary strings were removed.
- One intermediate localization invocation exited 127 because the running shell
  script was edited while waiting inside the export command (stale shell byte
  offset). The final unchanged-script invocation completed successfully, including
  both catalogue stability checks and all three simulator builds.
- Existing shared-catalogue plural-inference warnings, existing Morse audio API
  deprecation warnings and AppIntents extraction-without-dependency warnings remain
  non-fatal; these sources/keys were not changed by this task.
- Original validation did not include iOS/tvOS/visionOS full test suites,
  figure/title plans, web/TypeScript content-tools suites, physical-watch
  VoiceOver/haptic checks, signing archives, TestFlight upload or release validation.
  The review round below adds a real existing-family watch icon and signed
  archive/export checks without uploading. TASK-14.6 retains icon refinement,
  final release validation and hardware install; feature, haptic hardware and
  accessibility work remains TASK-14.2–14.5.
- Affected merge-batch platforms: **iOS, macOS, tvOS, visionOS and watchOS**, because
  the three local packages are linked by all of them. Coordinator owns full-suite
  timing; this task does not replace those merge-batch gates.

## Retained local artifacts

Logs: `/tmp/task-14.1-checks.log`, `/tmp/task-14.1-fix-checks.log`,
`/tmp/task-14.1-final-checks.log`, `/tmp/task-14.1-l10n-stability-status.log`, plus
per-command `/tmp/task-14.1-<name>.log`. Final command logs are `watch-final`,
`ios-container-final`, `localization-stability`, `icloud-final`, `privacy-final`,
`test-guard-final`; package logs are `package-engine`, `package-content`,
`package-morse`; macOS is `macos`. Local artifacts are not committed; the tables
below preserve the per-test results needed for review/PR notes.

## Per-test results: watchOS final smoke (5)

| Test | Result | Duration |
|---|---|---|
| `CanadianHamWatchTests.CanadianHamWatchTests testIndependentOfflineBundle` | passed | 0.005 seconds |
| `CanadianHamWatchTests.CanadianHamWatchTests testPlannedSections` | passed | 0.001 seconds |
| `CanadianHamWatchTests.CanadianHamWatchTests testSharedPackagesOnWatch` | passed | 0.003 seconds |
| `CanadianHamWatchUITests.CanadianHamWatchUITests testLaunchAndNavigateEnglish` | passed | 14.881 seconds |
| `CanadianHamWatchUITests.CanadianHamWatchUITests testLaunchAndNavigateFrench` | passed | 14.834 seconds |

Result bundle: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-dpltaiphkatayyaghnxlaebxkmtj/Logs/Test/Test-CanadianHamWatch-2026.10.25_13-30-38--0400.xcresult`.

## Per-test results: engine-swift on macOS (22)

| Test | Result | Duration |
|---|---|---|
| `CanadianHamEngineTests.FixtureTests testEveryEngineFixtureMatchesSwiftEngine` | passed | 0.028 seconds |
| `CanadianHamEngineTests.FixtureTests testJSONComparatorRejectsExtraExpectedOutputKey` | passed | 0.000 seconds |
| `CanadianHamEngineTests.LessonReviewTests testSharedLessonReviewFixtures` | passed | 0.001 seconds |
| `CanadianHamEngineTests.PCG32Tests testPCG32SrandomDemoMatchesPublishedCOutputs` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testAdvancedReadinessDoesNotCountExamsBelowSeventyPercent` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testAdvancedReadinessTreatsSeventyPercentPassThresholdAsInclusive` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testApplyAnswerRejectsOutOfRangeLeitnerBoxes` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testBankRulesAcceptFutureSchemaValidBasicIds` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testBankRulesAcceptOnlySchemaValidBasicAndAdvancedIds` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testEngineTimestampInputsRequireCanonicalMillisecondUTCFormat` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testExamGenerationRequiresCanonicalAnswerSourceIndexes` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testFullMockExamGenerationUsesActiveBankSubsectionCount` | passed | 0.001 seconds |
| `CanadianHamEngineTests.ValidationTests testHintedCorrectPreservesAccuracyWithoutMasteryCredit` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testOlderProgressJsonDecodesHelpFieldsAsFalse` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testPracticeExamGenerationDoesNotRequireKnownBankRulesUnlessFullMockIsRequested` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testReadinessRejectsDuplicateSubmittedAtTimestamps` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testScoreExamRejectsUnsupportedBankIds` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testSharedBankRulesFixtureAgreesWithSwiftEngine` | passed | 0.001 seconds |
| `CanadianHamEngineTests.ValidationTests testTimestampAdditionCrossesMonthAndYearBoundaries` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testTimestampFormattingRejectsYearsOutsideCanonicalRange` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testTimestampParserAcceptsLeapDayInLeapYears` | passed | 0.000 seconds |
| `CanadianHamEngineTests.ValidationTests testTimestampParserRejectsImpossibleDatesAndNonAsciiDigits` | passed | 0.000 seconds |

## Per-test results: content-swift on macOS (27)

| Test | Result | Duration |
|---|---|---|
| `CanadianHamContentTests.ContentLibraryTests testAllAuthoredTryItAnswersParseWithoutExposingDirectiveText` | passed | 0.689 seconds |
| `CanadianHamContentTests.ContentLibraryTests testBadHintFileDropsHintsWithoutDroppingLessonContent` | passed | 0.022 seconds |
| `CanadianHamContentTests.ContentLibraryTests testBundledQuestionHintSectionAnchorsResolveInLessons` | passed | 5.446 seconds |
| `CanadianHamContentTests.ContentLibraryTests testConceptCheckChoiceDecodesOptionalFeedbackAndRoundTrips` | passed | 0.000 seconds |
| `CanadianHamContentTests.ContentLibraryTests testContentLibraryRejectsCoversOutsideLessonCategoryIds` | passed | 0.019 seconds |
| `CanadianHamContentTests.ContentLibraryTests testContentLibraryRejectsEmptyModuleListWithoutCrashing` | passed | 0.004 seconds |
| `CanadianHamContentTests.ContentLibraryTests testContentLibraryRejectsExplanationIdMismatch` | passed | 0.017 seconds |
| `CanadianHamContentTests.ContentLibraryTests testContentLibraryRejectsMissingExplanationForQuestion` | passed | 0.016 seconds |
| `CanadianHamContentTests.ContentLibraryTests testContentLibraryRejectsMissingSubsectionCoverage` | passed | 0.016 seconds |
| `CanadianHamContentTests.ContentLibraryTests testContentLibraryRejectsUnknownOfficialQuestionInQuiz` | passed | 0.016 seconds |
| `CanadianHamContentTests.ContentLibraryTests testContentLibraryRejectsUnknownPrerequisite` | passed | 0.016 seconds |
| `CanadianHamContentTests.ContentLibraryTests testExplanationNoteParsingForSampleInEachCategory` | passed | 0.351 seconds |
| `CanadianHamContentTests.ContentLibraryTests testExplanationParserRejectsDuplicateAndCorrectSourceIndexNotes` | passed | 0.000 seconds |
| `CanadianHamContentTests.ContentLibraryTests testFigureDirectivesForOhmsLawLesson` | passed | 0.338 seconds |
| `CanadianHamContentTests.ContentLibraryTests testFrontMatterParserMatchesNumericAndASCIIKeyRules` | passed | 0.000 seconds |
| `CanadianHamContentTests.ContentLibraryTests testLessonIdRegexRejectsMalformedIds` | passed | 0.016 seconds |
| `CanadianHamContentTests.ContentLibraryTests testLoadFromBundleFindsBundledContentDirectory` | passed | 0.020 seconds |
| `CanadianHamContentTests.ContentLibraryTests testLoadsRealRepositoryContent` | passed | 0.354 seconds |
| `CanadianHamContentTests.ContentLibraryTests testM1QuizRoundsDecodeAndRoundTripWithoutChangingLegacyQuizzes` | passed | 0.335 seconds |
| `CanadianHamContentTests.ContentLibraryTests testMarkdownInlineHandlingKeepsRawHTMLLiteralButPreservesCodeAndAutolinks` | passed | 0.002 seconds |
| `CanadianHamContentTests.ContentLibraryTests testMarkdownRendererParsesEveryRealLesson` | passed | 0.480 seconds |
| `CanadianHamContentTests.ContentLibraryTests testSharedFigureDirectiveFixtures` | passed | 0.002 seconds |
| `CanadianHamContentTests.ContentLibraryTests testSharedLessonHeadingAnchorFixtures` | passed | 0.002 seconds |
| `CanadianHamContentTests.ContentLibraryTests testStrictFrontMatterParserRejectsMalformedInput` | passed | 0.000 seconds |
| `CanadianHamContentTests.ContentLibraryTests testTableIllustrationBriefAndBlockOrderForL00501` | passed | 0.340 seconds |
| `CanadianHamContentTests.ContentLibraryTests testTableParserHandlesAlignmentEscapedPipesAndFencedCode` | passed | 0.000 seconds |
| `CanadianHamContentTests.ContentLibraryTests testTryItAnswersAreSeparateBlocksAndDoNotLeakIntoFlattenedLessonText` | passed | 0.001 seconds |

## Per-test results: morse-swift on macOS (4)

| Test | Result | Duration |
|---|---|---|
| `CanadianHamMorseEngineTests.MorseFixtureTests testEveryMorseFixtureMatchesSwiftEngine` | passed | 0.015 seconds |
| `CanadianHamMorseEngineTests.MorseFixtureTests testGenerateMorseExamTextReportsUnsatisfiedConstraintsDistinctly` | passed | 1.344 seconds |
| `CanadianHamMorseEngineTests.MorseFixtureTests testMorseBeaconFlashSafetyMath` | passed | 0.000 seconds |
| `CanadianHamMorseEngineTests.MorseFixtureTests testVisualTapeAndHapticOutputMapping` | passed | 0.000 seconds |

## Per-test results: macOS full unit target (223)

| Test | Result | Duration |
|---|---|---|
| `CanadianHamTests.DuoLayoutPolicyTests testCompactWidthIPhoneKeepsSheetPolicy` | passed | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact` | passed | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests testIPadInspectorRuleRemainsSizeClassDriven` | passed | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests testMacAndOtherIdiomsNeverUseIPhonePolicy` | passed | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy` | passed | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testKeyHandlingProducesEngineDisplayAndSpokenResult` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testOfficialReferenceSheetGateAndBundledPages` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testQuestionCardFocusResetKeepsTextSelectionEnabled` | passed | 0.004 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekEndsWhenPhoneFullyOpensOrCloses` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekFastUnfoldThroughBandNeverPeeks` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekLeavingToleranceDoesNotResetDismissalSuppression` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationDismissalSuppressesReopenUntilReset` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationImmediateAnswerEndsEligibility` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationStartsOnlyOnceUntilPostureReset` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekRecheckPeeksWithoutNewSamples` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekRequiresStableDwellInSlightOpenBand` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekSlowCloseThroughBandNeverPeeks` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` | passed | 0.405 seconds |
| `CanadianHamTests.HintSessionStateTests testHintVisibilityTimerDoesNotQualifyShortPeekRoute` | passed | 0.294 seconds |
| `CanadianHamTests.HintSessionStateTests testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` | passed | 0.002 seconds |
| `CanadianHamTests.HintSessionStateTests testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` | passed | 0.002 seconds |
| `CanadianHamTests.HintSessionStateTests testReviewLaterHintAfterSelectionRecordsHelp` | passed | 0.002 seconds |
| `CanadianHamTests.HintSessionStateTests testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` | passed | 0.004 seconds |
| `CanadianHamTests.HintSessionStateTests testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` | passed | 2.571 seconds |
| `CanadianHamTests.LocalizationCatalogTests testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata` | passed | 0.003 seconds |
| `CanadianHamTests.LocalizationCatalogTests testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection` | passed | 0.002 seconds |
| `CanadianHamTests.LocalizationCatalogTests testConceptCheckAnswerStatusMapsShuffledSourceChoices` | passed | 0.003 seconds |
| `CanadianHamTests.LocalizationCatalogTests testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext` | passed | 0.002 seconds |
| `CanadianHamTests.LocalizationCatalogTests testEveryCatalogKeyHasFrenchTranslations` | passed | 0.019 seconds |
| `CanadianHamTests.LocalizationCatalogTests testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` | passed | 0.009 seconds |
| `CanadianHamTests.LocalizationCatalogTests testLanguagePreferenceResolvesSystemAndOverrides` | passed | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests testLocalizedNullableTextAndLanguageFallsBackToEnglish` | passed | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests testQuestionBankLoadErrorDescriptionUsesFrenchLocale` | passed | 0.006 seconds |
| `CanadianHamTests.LocalizationCatalogTests testReviewHeadingMarksEnglishFallbackTitleInsideFrenchText` | passed | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testCompletedMorseCourseSessionIgnoresResubmittedAnswer` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testFixedTimingProfilesUseEngineValues` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testLessonBodyAndBulletContrastTokensMeetMinimumRatio` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession` | passed | 1.702 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseAudioSessionStaysActiveUntilLastPlayerReleases` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseExamGeneratorMeetsReceivingExamConstraints` | passed | 0.003 seconds |
| `CanadianHamTests.MorseTrainerTests testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` | passed | 0.004 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingClassifiesTimingAndErrorSignal` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerClassifiesPressWhenAudioFails` | passed | 0.004 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError` | passed | 0.105 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone` | passed | 0.004 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerReleaseCannotBeSupersededBySilence` | passed | 0.004 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress` | passed | 0.107 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError` | passed | 0.114 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingPendingFinalizationHelperCancelsAndClears` | passed | 0.003 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingRemainingExamSecondsUsesFixedDeadline` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSettingsClampAndPreset` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSettingsCodableRoundTripPreservesOutputMode` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSettingsDecodesLegacyPayloadWithIsEnabled` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` | passed | 0.014 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSettingsRoundTripThroughUserDefaults` | passed | 0.007 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseStopDelayDrainsFadeBeforeStoppingEngine` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | passed | 0.053 seconds |
| `CanadianHamTests.MorseTrainerTests testReduceFlashingDecisionUsesInjectedFlags` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testReduceFlashingStopsOnlyRunningVisualBeacon` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testScheduleMorseVisualPlaybackInitialStateAndFallback` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` | passed | 0.071 seconds |
| `CanadianHamTests.ProgressStoreTests testAdvancedImportRejectsHonoursAttempts` | passed | 0.024 seconds |
| `CanadianHamTests.ProgressStoreTests testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` | passed | 0.003 seconds |
| `CanadianHamTests.ProgressStoreTests testAppSettingsModelPublishesMorseSettingsForRootViewSync` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` | passed | 0.028 seconds |
| `CanadianHamTests.ProgressStoreTests testDecodesLegacyBasicExportWithoutBankIdFields` | passed | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` | passed | 0.028 seconds |
| `CanadianHamTests.ProgressStoreTests testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` | passed | 0.021 seconds |
| `CanadianHamTests.ProgressStoreTests testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` | passed | 0.056 seconds |
| `CanadianHamTests.ProgressStoreTests testFreshInstallDefaultsLanguageToSystem` | passed | 0.009 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudAccountSignalsUseInitInjectedFactory` | passed | 0.060 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` | passed | 0.028 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudDeleteCanDeleteLocalDataAfterZoneDelete` | passed | 0.024 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` | passed | 0.133 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudMergeFixtureIsPermutationIndependentAndIdempotent` | passed | 0.004 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` | passed | 0.054 seconds |
| `CanadianHamTests.ProgressStoreTests testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` | passed | 0.033 seconds |
| `CanadianHamTests.ProgressStoreTests testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` | passed | 0.044 seconds |
| `CanadianHamTests.ProgressStoreTests testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` | passed | 0.059 seconds |
| `CanadianHamTests.ProgressStoreTests testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` | passed | 0.032 seconds |
| `CanadianHamTests.ProgressStoreTests testImportLeavesTask4610Version2LessonSplitRowsUnchanged` | passed | 0.033 seconds |
| `CanadianHamTests.ProgressStoreTests testImportMigratesMixedTask4610SyncRowsByRowVersion` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests testImportMigratesTask4610LessonSplitProgressAndQuizAttempts` | passed | 0.035 seconds |
| `CanadianHamTests.ProgressStoreTests testImportOfOlderExportDoesNotRemoveExistingMorseProgress` | passed | 0.031 seconds |
| `CanadianHamTests.ProgressStoreTests testImportRejectsInvalidSyncDeviceRows` | passed | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests testImportRejectsUnsupportedLanguagePreferenceValues` | passed | 0.036 seconds |
| `CanadianHamTests.ProgressStoreTests testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` | passed | 0.070 seconds |
| `CanadianHamTests.ProgressStoreTests testImportRollbackKeepsExistingDataWhenReplacementFails` | passed | 0.042 seconds |
| `CanadianHamTests.ProgressStoreTests testImportRollbackPropagatesMorseProgressRemovalFailure` | passed | 0.032 seconds |
| `CanadianHamTests.ProgressStoreTests testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` | passed | 0.031 seconds |
| `CanadianHamTests.ProgressStoreTests testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests testImportValidationRejectsDuplicateMorseDailyActivityDates` | passed | 0.035 seconds |
| `CanadianHamTests.ProgressStoreTests testImportValidationRejectsInvalidMorseCourseProgress` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests testImportValidationRejectsMismatchedScoreBankId` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` | passed | 0.032 seconds |
| `CanadianHamTests.ProgressStoreTests testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` | passed | 0.036 seconds |
| `CanadianHamTests.ProgressStoreTests testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` | passed | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` | passed | 0.014 seconds |
| `CanadianHamTests.ProgressStoreTests testLaunchIgnoresRegisteredAppleLanguagesValue` | passed | 0.009 seconds |
| `CanadianHamTests.ProgressStoreTests testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` | passed | 0.009 seconds |
| `CanadianHamTests.ProgressStoreTests testLegacyEmptyReviewQuestionIdsImportAtTopLevelAndInSyncRows` | passed | 0.089 seconds |
| `CanadianHamTests.ProgressStoreTests testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` | passed | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` | passed | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` | passed | 0.009 seconds |
| `CanadianHamTests.ProgressStoreTests testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` | passed | 0.008 seconds |
| `CanadianHamTests.ProgressStoreTests testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` | passed | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests testLessonQuizHelpFixtureValidationAndPayloadRoundTrips` | passed | 0.127 seconds |
| `CanadianHamTests.ProgressStoreTests testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix` | passed | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice` | passed | 2.604 seconds |
| `CanadianHamTests.ProgressStoreTests testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation` | passed | 0.003 seconds |
| `CanadianHamTests.ProgressStoreTests testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` | passed | 0.063 seconds |
| `CanadianHamTests.ProgressStoreTests testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` | passed | 0.051 seconds |
| `CanadianHamTests.ProgressStoreTests testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` | passed | 0.032 seconds |
| `CanadianHamTests.ProgressStoreTests testM1QuizRoundBoundariesPreserveOneSessionAnswersHelpAndDismissedCheckpoint` | passed | 0.548 seconds |
| `CanadianHamTests.ProgressStoreTests testM1QuizRoundsRetainEveryItemAndSeededOrderWithinTeachingSections` | passed | 0.549 seconds |
| `CanadianHamTests.ProgressStoreTests testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` | passed | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` | passed | 0.032 seconds |
| `CanadianHamTests.ProgressStoreTests testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` | passed | 0.377 seconds |
| `CanadianHamTests.ProgressStoreTests testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` | passed | 0.018 seconds |
| `CanadianHamTests.ProgressStoreTests testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` | passed | 0.069 seconds |
| `CanadianHamTests.ProgressStoreTests testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` | passed | 0.074 seconds |
| `CanadianHamTests.ProgressStoreTests testMockExamTimerRefreshPreservesFractionalRemainder` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` | passed | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests testMorseExportMapsHapticsToWebCompatibleAudio` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testMorseImportDecodesMissingAndPartialMorsePreferences` | passed | 0.050 seconds |
| `CanadianHamTests.ProgressStoreTests testMorseImportRejectsExplicitNullMorseValues` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testMorseImportRejectsUnsupportedMorsePreferenceEnums` | passed | 0.040 seconds |
| `CanadianHamTests.ProgressStoreTests testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender` | passed | 0.955 seconds |
| `CanadianHamTests.ProgressStoreTests testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference` | passed | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests testNativeSettingsGeneralBindingsUpdatePracticePreferences` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` | passed | 0.036 seconds |
| `CanadianHamTests.ProgressStoreTests testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` | passed | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` | passed | 0.033 seconds |
| `CanadianHamTests.ProgressStoreTests testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests testProgressStoreRoundTripExportImportReset` | passed | 0.055 seconds |
| `CanadianHamTests.ProgressStoreTests testQuizRoundsWithConceptChecksKeepTheCompleteUngroupedOrder` | passed | 0.530 seconds |
| `CanadianHamTests.ProgressStoreTests testResetAllDataTurnsICloudSyncOptInOff` | passed | 0.015 seconds |
| `CanadianHamTests.ProgressStoreTests testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` | passed | 0.028 seconds |
| `CanadianHamTests.ProgressStoreTests testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` | passed | 0.044 seconds |
| `CanadianHamTests.ProgressStoreTests testResetClearsAppleLanguagesAndLanguagePreference` | passed | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests testResetFailureKeepsPreviousAppleLanguagesAndPreference` | passed | 0.013 seconds |
| `CanadianHamTests.ProgressStoreTests testResetRollsBackWhenMorseProgressRemovalFails` | passed | 0.014 seconds |
| `CanadianHamTests.ProgressStoreTests testReviewAttemptPayloadImportSyncAndLegacyVersionRejection` | passed | 0.052 seconds |
| `CanadianHamTests.ProgressStoreTests testReviewItemsUseEarlierTaughtPoolsAndFinalM1Round` | passed | 1.631 seconds |
| `CanadianHamTests.ProgressStoreTests testReviewSourceMayDifferFromCanonicalHintLessonWithAuthoredSectionAnchor` | passed | 0.566 seconds |
| `CanadianHamTests.ProgressStoreTests testSavingLargeQuestionProgressBatchBuildsOneWriteContext` | passed | 1.753 seconds |
| `CanadianHamTests.ProgressStoreTests testSharedAppleSettingsModelAppliesLivePreferenceUpdates` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` | passed | 0.006 seconds |
| `CanadianHamTests.ProgressStoreTests testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` | passed | 0.108 seconds |
| `CanadianHamTests.ProgressStoreTests testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` | passed | 0.057 seconds |
| `CanadianHamTests.ProgressStoreTests testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` | passed | 0.031 seconds |
| `CanadianHamTests.ProgressStoreTests testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` | passed | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices` | passed | 0.043 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports` | passed | 0.040 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration` | passed | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds` | passed | 0.028 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating` | passed | 0.100 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610SharedConceptMappingAndConceptInclusiveScores` | passed | 0.239 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows` | passed | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` | passed | 0.054 seconds |
| `CanadianHamTests.QuestionBankTests testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` | passed | 0.012 seconds |
| `CanadianHamTests.QuestionBankTests testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` | passed | 0.013 seconds |
| `CanadianHamTests.QuestionBankTests testAppBundleContainsNoReadmeFiles` | passed | 0.014 seconds |
| `CanadianHamTests.QuestionBankTests testAppBundleContainsOnlyExpectedGeneratedBankDirectories` | passed | 0.001 seconds |
| `CanadianHamTests.QuestionBankTests testBundledJSONDecodesExpectedCounts` | passed | 0.019 seconds |
| `CanadianHamTests.QuestionBankTests testBundledLessonModelExposesPrerequisites` | passed | 0.545 seconds |
| `CanadianHamTests.QuestionBankTests testBundledLessonsAndExplanationsLoadThroughContentLibrary` | passed | 0.713 seconds |
| `CanadianHamTests.QuestionBankTests testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` | passed | 0.020 seconds |
| `CanadianHamTests.QuestionBankTests testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` | passed | 0.078 seconds |
| `CanadianHamTests.QuestionBankTests testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` | passed | 0.001 seconds |
| `CanadianHamTests.QuestionBankTests testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` | passed | 0.552 seconds |
| `CanadianHamTests.ReadinessAndScoringTests testAdvancedScoringAndReadinessSuppressHonours` | passed | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests testExamScoringBoundaries` | passed | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests testReadinessStates` | passed | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` | passed | 0.034 seconds |
| `CanadianHamTests.RootNavigationMappingTests testCompactHomeSessionAndSectionPushesUseVisibleDestination` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests testEmptyCompactPathMapsToHome` | passed | 0.000 seconds |
| `CanadianHamTests.RootNavigationMappingTests testEveryLearnRouteRoundTripsWithItsWholeStack` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests testEveryRootSelectionRoundTrips` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests testPracticeHintLessonStackKeepsSessionAsSplitSelection` | passed | 0.001 seconds |

Result bundle: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-dpltaiphkatayyaghnxlaebxkmtj/Logs/Test/Test-CanadianHam-2026.10.25_13-17-03--0400.xcresult`.


## Review fixes and immutable rerun (2026-10-25)

All runs in this section used **`126fce65fa264e1423c45324871ee93d758a123d`**,
with no source edits or checkout changes during the runner (17:42:17–17:48:46 UTC).
Later commits only record evidence/task notes. No PR was opened and **nothing
was uploaded to TestFlight**.

### Review fixes

- Added the watch `Assets.xcassets/AppIcon.appiconset` using an exact copy of
  `design/app-icon/exports/app-icon-1024.png`: **1024×1024 RGB, no alpha**.
  The existing brushstroke/hexagon art remains entirely legible under a circular
  mask; inspected a 256px circular preview at `/tmp/task-14.1-watch-icon-circle.png`.
  Watch `ASSETCATALOG_COMPILER_APPICON_NAME` explicitly resolves to `AppIcon`.
  No missing/unassigned icon or watch asset-compiler warning appeared.
  TASK-14.6 notes retain later icon refinement and physical-watch review.
- `upload_beta` accepts `export_only:true` (Ruby boolean or CLI string); after
  normal signed archive/export it prints the artifact path and returns before
  `upload_to_testflight`. Absent/false options preserve the default upload path.
  Three isolated Ruby tests/27 assertions cover iOS/macOS, default/false and
  existing-artifact behavior, without invoking signing or upload APIs.
- Watch bundle smoke asserts both `UIBackgroundModes` and `WKBackgroundModes`
  absent. Privacy scripts reject `WKBackgroundModes` and its `INFOPLIST_KEY_`
  form, including watch DebugCloudKit settings; fixtures cover these leaks.
  The iCloud gate requires exactly **9** watch build-configuration blocks and
  fixtures reject zero, missing and duplicate blocks.
- UI smoke waits for links to exist before reading `isHittable` or swiping.
  AGENTS.md documents the watch test command, watch/shared-package suite scope
  and the watch SDK requirement for iOS builds.
- XcodeGen ran twice before the implementation commit (identical PBX/scheme
  hashes), then twice after all checks; `git diff --exit-code --
  apps/apple/CanadianHam.xcodeproj` was empty.

### Rerun commands/results

Apple commands below use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
Beta commands also use `FASTLANE_SKIP_UPDATE_CHECK=1`; only the configured dedicated
build keychain and API key were used. No password was prompted for, printed or
recorded, and the login keychain was not handled.

| Check | Command | Result |
|---|---|---|
| Watch smoke | `xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' test CODE_SIGNING_ALLOWED=NO` | **5 passed**, zero failures |
| Full macOS unit target | `xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES` | **223 passed**, zero failures |
| iOS container | `xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build-for-testing CODE_SIGNING_ALLOWED=NO` | **TEST BUILD SUCCEEDED** |
| Localization + tvOS/visionOS/watch builds | `pnpm check:apple-l10n` | **Passed**; three generic simulator builds, complete French export, source check/self-test and unchanged catalogues |
| Network guard / fixtures | `pnpm check:apple-network`; `pnpm test:apple-network` | **Passed** |
| iCloud guard / fixtures | `pnpm check:apple-icloud-gate`; `pnpm test:apple-icloud-gate` | **Passed** |
| Test guard / self-test | `node scripts/check-test-guard.mjs --base main`; `node scripts/check-test-guard.mjs --self-test` | **Passed**, no guarded changes |
| Fastlane safety tests | `ruby scripts/test-fastlane-export-only.rb`; `ruby -c fastlane/Fastfile` | **3 tests / 27 assertions passed**; Syntax OK |
| iOS archive/export | `fastlane ios beta export_only:true` | **ARCHIVE SUCCEEDED / EXPORT SUCCEEDED**, upload explicitly skipped |
| macOS archive/export | `fastlane mac beta export_only:true` | **ARCHIVE SUCCEEDED / EXPORT SUCCEEDED**, upload explicitly skipped |

The localization script's build commands use `-scheme CanadianHamTV`,
`CanadianHamVision` and `CanadianHamWatch`, respectively, with destinations
`generic/platform=tvOS Simulator`, `generic/platform=visionOS Simulator` and
`generic/platform=watchOS Simulator`, `-derivedDataPath <temporary>/DerivedData`,
`build CODE_SIGNING_ALLOWED=NO` (same project and developer directory).

### Signed export artifacts and inspection

- iOS archive: `/Users/david/Developer/canadian-ham-task-14.1/fastlane/archives/ios/CanadianHam-202610251346.xcarchive`
- **IPA:** `/Users/david/Developer/canadian-ham-task-14.1/fastlane/builds/ios/202610251346/CanadianHam.ipa`
- macOS archive: `/Users/david/Developer/canadian-ham-task-14.1/fastlane/archives/mac/CanadianHam-202610251347.xcarchive`
- **PKG:** `/Users/david/Developer/canadian-ham-task-14.1/fastlane/builds/mac/202610251347/CanadianHam.pkg`

The IPA was expanded with `ditto -x -k` to `/tmp/task-14.1-review-ipa`.
It contains **`Payload/CanadianHam.app/Watch/CanadianHamWatch.app`**.
Python `plistlib` assertions, `/usr/bin/assetutil --info`, `security cms -D -i`
(profile decode only), `codesign -dv --verbose=4` and
`codesign --verify --deep --strict --verbose=2` establish:

```text
Phone ID: org.davidjensenius.CanadianHam
Watch ID: org.davidjensenius.CanadianHam.watchkitapp
Watch supported platform: WatchOS
Phone/watch marketing version: 1.0.0
Phone/watch build number: 202610251346 (matching)
WKApplication: true
WKRunsIndependentlyOfCompanionApp: true
WKCompanionAppBundleIdentifier: org.davidjensenius.CanadianHam
Watch UIBackgroundModes / WKBackgroundModes: absent / absent
Watch Assets.car: present, 154392 bytes
Watch CFBundlePrimaryIcon.CFBundleIconName: AppIcon
Assets.car AppIcon: 1024×1024 Icon Image plus MultiSized Image rendition
embedded.mobileprovision: present in phone and watch apps
Watch profile application-identifier: 9JALHNGRBQ.org.davidjensenius.CanadianHam.watchkitapp
Watch profile expiration: 2027-10-10T16:51:06Z
Phone/watch codesign --verify: exit 0, valid on disk, satisfies Designated Requirement
Phone/watch signature authority: Apple Distribution: david jensenius (9JALHNGRBQ)
Certificate chain: Apple Worldwide Developer Relations Certification Authority / Apple Root CA
TeamIdentifier: 9JALHNGRBQ
Watch signed time: Oct 25, 2026 at 13:47:36 (local)
Signed phone/watch entitlements: no iCloud or push
Watch privacy: tracking false; tracking domains, collected data and accessed API types empty
```

`pkgutil --check-signature` passed for the macOS pkg (3rd Party Mac Developer
Installer: david jensenius, team 9JALHNGRBQ). `pkgutil --expand-full` expanded
**all** package payloads to `/tmp/task-14.1-review-mac-pkg`. Recursive inspection
found one `CanadianHam.app` (MacOSX, bundle ID `org.davidjensenius.CanadianHam`,
version 1.0.0 / build 202610251347) and **zero** `Watch` directories,
`CanadianHamWatch` entries or watchkit-named files. Its Apple Distribution app
signature also passes deep/strict verification.

Both beta logs contain the explicit `Export only; skipping TestFlight upload`
message and no `upload_to_testflight` step. Automatic signing/provisioning and
App Store Connect-method export succeeded with the watch embedding intact;
no signing workaround or embedding change was needed.

Logs: `/tmp/task-14.1-review-checks.log` and
`/tmp/task-14.1-review-{watch,macos,ios-container,localization,ios-export,mac-export}.log`,
plus similarly named guard and fastlane-test logs. Inspection summaries are
`/tmp/task-14.1-review-ipa-inspection.log`,
`/tmp/task-14.1-review-mac-inspection.log`,
`/tmp/task-14.1-review-mac-signature.log`, and
`/tmp/task-14.1-review-watch-assets.json`.

Remaining gates: App Store Connect processing, physical-watch installation,
VoiceOver/haptics and final feature/icon/release checks remain TASK-14.2–14.6.
No iOS/tvOS/visionOS full suites were rerun in this review round (targeted builds
only); all five affected platforms retain the merge-batch suite gate. Existing
plural-inference, Morse audio deprecation and AppIntents warnings remain non-fatal.
No watch icon/signing error was observed.

### Review rerun per-test results: watch smoke (5)

| Test | Result | Duration |
|---|---|---|
| `CanadianHamWatchTests.CanadianHamWatchTests testIndependentOfflineBundle` | passed | 0.004 seconds |
| `CanadianHamWatchTests.CanadianHamWatchTests testPlannedSections` | passed | 0.001 seconds |
| `CanadianHamWatchTests.CanadianHamWatchTests testSharedPackagesOnWatch` | passed | 0.003 seconds |
| `CanadianHamWatchUITests.CanadianHamWatchUITests testLaunchAndNavigateEnglish` | passed | 18.224 seconds |
| `CanadianHamWatchUITests.CanadianHamWatchUITests testLaunchAndNavigateFrench` | passed | 14.256 seconds |

Result bundle: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-dpltaiphkatayyaghnxlaebxkmtj/Logs/Test/Test-CanadianHamWatch-2026.10.25_13-42-33--0400.xcresult`.

### Review rerun per-test results: full macOS unit target (223)

| Test | Result | Duration |
|---|---|---|
| `CanadianHamTests.DuoLayoutPolicyTests testCompactWidthIPhoneKeepsSheetPolicy` | passed | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact` | passed | 0.000 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests testIPadInspectorRuleRemainsSizeClassDriven` | passed | 0.000 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests testMacAndOtherIdiomsNeverUseIPhonePolicy` | passed | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy` | passed | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact` | passed | 0.000 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes` | passed | 0.000 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale` | passed | 0.012 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testKeyHandlingProducesEngineDisplayAndSpokenResult` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testOfficialReferenceSheetGateAndBundledPages` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testQuestionCardFocusResetKeepsTextSelectionEnabled` | passed | 0.004 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekEndsWhenPhoneFullyOpensOrCloses` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekFastUnfoldThroughBandNeverPeeks` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekLeavingToleranceDoesNotResetDismissalSuppression` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationDismissalSuppressesReopenUntilReset` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationImmediateAnswerEndsEligibility` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekPresentationStartsOnlyOnceUntilPostureReset` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekRecheckPeeksWithoutNewSamples` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekRequiresStableDwellInSlightOpenBand` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekSlowCloseThroughBandNeverPeeks` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` | passed | 0.395 seconds |
| `CanadianHamTests.HintSessionStateTests testHintVisibilityTimerDoesNotQualifyShortPeekRoute` | passed | 0.295 seconds |
| `CanadianHamTests.HintSessionStateTests testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` | passed | 0.002 seconds |
| `CanadianHamTests.HintSessionStateTests testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testReviewLaterHintAfterSelectionRecordsHelp` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` | passed | 0.004 seconds |
| `CanadianHamTests.HintSessionStateTests testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` | passed | 2.673 seconds |
| `CanadianHamTests.LocalizationCatalogTests testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata` | passed | 0.003 seconds |
| `CanadianHamTests.LocalizationCatalogTests testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection` | passed | 0.002 seconds |
| `CanadianHamTests.LocalizationCatalogTests testConceptCheckAnswerStatusMapsShuffledSourceChoices` | passed | 0.002 seconds |
| `CanadianHamTests.LocalizationCatalogTests testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext` | passed | 0.002 seconds |
| `CanadianHamTests.LocalizationCatalogTests testEveryCatalogKeyHasFrenchTranslations` | passed | 0.013 seconds |
| `CanadianHamTests.LocalizationCatalogTests testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` | passed | 0.004 seconds |
| `CanadianHamTests.LocalizationCatalogTests testLanguagePreferenceResolvesSystemAndOverrides` | passed | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests testLocalizedNullableTextAndLanguageFallsBackToEnglish` | passed | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests testQuestionBankLoadErrorDescriptionUsesFrenchLocale` | passed | 0.004 seconds |
| `CanadianHamTests.LocalizationCatalogTests testReviewHeadingMarksEnglishFallbackTitleInsideFrenchText` | passed | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testCompletedMorseCourseSessionIgnoresResubmittedAnswer` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testFixedTimingProfilesUseEngineValues` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testLessonBodyAndBulletContrastTokensMeetMinimumRatio` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession` | passed | 1.667 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseAudioSessionStaysActiveUntilLastPlayerReleases` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas` | passed | 0.003 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` | passed | 0.004 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseExamGeneratorMeetsReceivingExamConstraints` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` | passed | 0.003 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingClassifiesTimingAndErrorSignal` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerClassifiesPressWhenAudioFails` | passed | 0.003 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError` | passed | 0.105 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone` | passed | 0.003 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerReleaseCannotBeSupersededBySilence` | passed | 0.004 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress` | passed | 0.104 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError` | passed | 0.108 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingPendingFinalizationHelperCancelsAndClears` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingRemainingExamSecondsUsesFixedDeadline` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSettingsClampAndPreset` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSettingsCodableRoundTripPreservesOutputMode` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSettingsDecodesLegacyPayloadWithIsEnabled` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` | passed | 0.012 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseSettingsRoundTripThroughUserDefaults` | passed | 0.004 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseStopDelayDrainsFadeBeforeStoppingEngine` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | passed | 0.046 seconds |
| `CanadianHamTests.MorseTrainerTests testReduceFlashingDecisionUsesInjectedFlags` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testReduceFlashingStopsOnlyRunningVisualBeacon` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testScheduleMorseVisualPlaybackInitialStateAndFallback` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` | passed | 0.075 seconds |
| `CanadianHamTests.ProgressStoreTests testAdvancedImportRejectsHonoursAttempts` | passed | 0.024 seconds |
| `CanadianHamTests.ProgressStoreTests testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` | passed | 0.004 seconds |
| `CanadianHamTests.ProgressStoreTests testAppSettingsModelPublishesMorseSettingsForRootViewSync` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` | passed | 0.020 seconds |
| `CanadianHamTests.ProgressStoreTests testDecodesLegacyBasicExportWithoutBankIdFields` | passed | 0.031 seconds |
| `CanadianHamTests.ProgressStoreTests testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` | passed | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` | passed | 0.021 seconds |
| `CanadianHamTests.ProgressStoreTests testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` | passed | 0.059 seconds |
| `CanadianHamTests.ProgressStoreTests testFreshInstallDefaultsLanguageToSystem` | passed | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudAccountSignalsUseInitInjectedFactory` | passed | 0.073 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` | passed | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudDeleteCanDeleteLocalDataAfterZoneDelete` | passed | 0.025 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` | passed | 0.033 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudMergeFixtureIsPermutationIndependentAndIdempotent` | passed | 0.002 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` | passed | 0.045 seconds |
| `CanadianHamTests.ProgressStoreTests testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` | passed | 0.045 seconds |
| `CanadianHamTests.ProgressStoreTests testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` | passed | 0.061 seconds |
| `CanadianHamTests.ProgressStoreTests testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` | passed | 0.033 seconds |
| `CanadianHamTests.ProgressStoreTests testImportLeavesTask4610Version2LessonSplitRowsUnchanged` | passed | 0.036 seconds |
| `CanadianHamTests.ProgressStoreTests testImportMigratesMixedTask4610SyncRowsByRowVersion` | passed | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests testImportMigratesTask4610LessonSplitProgressAndQuizAttempts` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests testImportOfOlderExportDoesNotRemoveExistingMorseProgress` | passed | 0.032 seconds |
| `CanadianHamTests.ProgressStoreTests testImportRejectsInvalidSyncDeviceRows` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests testImportRejectsUnsupportedLanguagePreferenceValues` | passed | 0.040 seconds |
| `CanadianHamTests.ProgressStoreTests testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` | passed | 0.071 seconds |
| `CanadianHamTests.ProgressStoreTests testImportRollbackKeepsExistingDataWhenReplacementFails` | passed | 0.044 seconds |
| `CanadianHamTests.ProgressStoreTests testImportRollbackPropagatesMorseProgressRemovalFailure` | passed | 0.032 seconds |
| `CanadianHamTests.ProgressStoreTests testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` | passed | 0.031 seconds |
| `CanadianHamTests.ProgressStoreTests testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` | passed | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests testImportValidationRejectsDuplicateMorseDailyActivityDates` | passed | 0.042 seconds |
| `CanadianHamTests.ProgressStoreTests testImportValidationRejectsInvalidMorseCourseProgress` | passed | 0.048 seconds |
| `CanadianHamTests.ProgressStoreTests testImportValidationRejectsMismatchedScoreBankId` | passed | 0.051 seconds |
| `CanadianHamTests.ProgressStoreTests testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` | passed | 0.036 seconds |
| `CanadianHamTests.ProgressStoreTests testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` | passed | 0.035 seconds |
| `CanadianHamTests.ProgressStoreTests testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` | passed | 0.017 seconds |
| `CanadianHamTests.ProgressStoreTests testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` | passed | 0.017 seconds |
| `CanadianHamTests.ProgressStoreTests testLaunchIgnoresRegisteredAppleLanguagesValue` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` | passed | 0.009 seconds |
| `CanadianHamTests.ProgressStoreTests testLegacyEmptyReviewQuestionIdsImportAtTopLevelAndInSyncRows` | passed | 0.098 seconds |
| `CanadianHamTests.ProgressStoreTests testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` | passed | 0.019 seconds |
| `CanadianHamTests.ProgressStoreTests testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` | passed | 0.013 seconds |
| `CanadianHamTests.ProgressStoreTests testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` | passed | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` | passed | 0.031 seconds |
| `CanadianHamTests.ProgressStoreTests testLessonQuizHelpFixtureValidationAndPayloadRoundTrips` | passed | 0.138 seconds |
| `CanadianHamTests.ProgressStoreTests testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix` | passed | 0.031 seconds |
| `CanadianHamTests.ProgressStoreTests testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice` | passed | 2.749 seconds |
| `CanadianHamTests.ProgressStoreTests testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation` | passed | 0.002 seconds |
| `CanadianHamTests.ProgressStoreTests testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` | passed | 0.047 seconds |
| `CanadianHamTests.ProgressStoreTests testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` | passed | 0.051 seconds |
| `CanadianHamTests.ProgressStoreTests testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests testM1QuizRoundBoundariesPreserveOneSessionAnswersHelpAndDismissedCheckpoint` | passed | 0.569 seconds |
| `CanadianHamTests.ProgressStoreTests testM1QuizRoundsRetainEveryItemAndSeededOrderWithinTeachingSections` | passed | 0.571 seconds |
| `CanadianHamTests.ProgressStoreTests testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` | passed | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` | passed | 0.035 seconds |
| `CanadianHamTests.ProgressStoreTests testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` | passed | 0.407 seconds |
| `CanadianHamTests.ProgressStoreTests testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` | passed | 0.019 seconds |
| `CanadianHamTests.ProgressStoreTests testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` | passed | 0.072 seconds |
| `CanadianHamTests.ProgressStoreTests testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` | passed | 0.076 seconds |
| `CanadianHamTests.ProgressStoreTests testMockExamTimerRefreshPreservesFractionalRemainder` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` | passed | 0.032 seconds |
| `CanadianHamTests.ProgressStoreTests testMorseExportMapsHapticsToWebCompatibleAudio` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testMorseImportDecodesMissingAndPartialMorsePreferences` | passed | 0.054 seconds |
| `CanadianHamTests.ProgressStoreTests testMorseImportRejectsExplicitNullMorseValues` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testMorseImportRejectsUnsupportedMorsePreferenceEnums` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender` | passed | 0.962 seconds |
| `CanadianHamTests.ProgressStoreTests testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests testNativeSettingsGeneralBindingsUpdatePracticePreferences` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` | passed | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` | passed | 0.041 seconds |
| `CanadianHamTests.ProgressStoreTests testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` | passed | 0.035 seconds |
| `CanadianHamTests.ProgressStoreTests testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` | passed | 0.040 seconds |
| `CanadianHamTests.ProgressStoreTests testProgressStoreRoundTripExportImportReset` | passed | 0.060 seconds |
| `CanadianHamTests.ProgressStoreTests testQuizRoundsWithConceptChecksKeepTheCompleteUngroupedOrder` | passed | 0.556 seconds |
| `CanadianHamTests.ProgressStoreTests testResetAllDataTurnsICloudSyncOptInOff` | passed | 0.014 seconds |
| `CanadianHamTests.ProgressStoreTests testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` | passed | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` | passed | 0.046 seconds |
| `CanadianHamTests.ProgressStoreTests testResetClearsAppleLanguagesAndLanguagePreference` | passed | 0.014 seconds |
| `CanadianHamTests.ProgressStoreTests testResetFailureKeepsPreviousAppleLanguagesAndPreference` | passed | 0.015 seconds |
| `CanadianHamTests.ProgressStoreTests testResetRollsBackWhenMorseProgressRemovalFails` | passed | 0.016 seconds |
| `CanadianHamTests.ProgressStoreTests testReviewAttemptPayloadImportSyncAndLegacyVersionRejection` | passed | 0.057 seconds |
| `CanadianHamTests.ProgressStoreTests testReviewItemsUseEarlierTaughtPoolsAndFinalM1Round` | passed | 1.660 seconds |
| `CanadianHamTests.ProgressStoreTests testReviewSourceMayDifferFromCanonicalHintLessonWithAuthoredSectionAnchor` | passed | 0.570 seconds |
| `CanadianHamTests.ProgressStoreTests testSavingLargeQuestionProgressBatchBuildsOneWriteContext` | passed | 1.783 seconds |
| `CanadianHamTests.ProgressStoreTests testSharedAppleSettingsModelAppliesLivePreferenceUpdates` | passed | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` | passed | 0.006 seconds |
| `CanadianHamTests.ProgressStoreTests testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` | passed | 0.090 seconds |
| `CanadianHamTests.ProgressStoreTests testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` | passed | 0.066 seconds |
| `CanadianHamTests.ProgressStoreTests testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` | passed | 0.033 seconds |
| `CanadianHamTests.ProgressStoreTests testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` | passed | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices` | passed | 0.044 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports` | passed | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration` | passed | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds` | passed | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating` | passed | 0.104 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610SharedConceptMappingAndConceptInclusiveScores` | passed | 0.255 seconds |
| `CanadianHamTests.ProgressStoreTests testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows` | passed | 0.040 seconds |
| `CanadianHamTests.ProgressStoreTests testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` | passed | 0.056 seconds |
| `CanadianHamTests.QuestionBankTests testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` | passed | 0.012 seconds |
| `CanadianHamTests.QuestionBankTests testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` | passed | 0.014 seconds |
| `CanadianHamTests.QuestionBankTests testAppBundleContainsNoReadmeFiles` | passed | 0.013 seconds |
| `CanadianHamTests.QuestionBankTests testAppBundleContainsOnlyExpectedGeneratedBankDirectories` | passed | 0.001 seconds |
| `CanadianHamTests.QuestionBankTests testBundledJSONDecodesExpectedCounts` | passed | 0.019 seconds |
| `CanadianHamTests.QuestionBankTests testBundledLessonModelExposesPrerequisites` | passed | 0.558 seconds |
| `CanadianHamTests.QuestionBankTests testBundledLessonsAndExplanationsLoadThroughContentLibrary` | passed | 0.733 seconds |
| `CanadianHamTests.QuestionBankTests testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` | passed | 0.020 seconds |
| `CanadianHamTests.QuestionBankTests testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` | passed | 0.080 seconds |
| `CanadianHamTests.QuestionBankTests testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` | passed | 0.001 seconds |
| `CanadianHamTests.QuestionBankTests testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` | passed | 0.569 seconds |
| `CanadianHamTests.ReadinessAndScoringTests testAdvancedScoringAndReadinessSuppressHonours` | passed | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests testExamScoringBoundaries` | passed | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests testReadinessStates` | passed | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` | passed | 0.036 seconds |
| `CanadianHamTests.RootNavigationMappingTests testCompactHomeSessionAndSectionPushesUseVisibleDestination` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests testEmptyCompactPathMapsToHome` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests testEveryLearnRouteRoundTripsWithItsWholeStack` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests testEveryRootSelectionRoundTrips` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests testPracticeHintLessonStackKeepsSessionAsSplitSelection` | passed | 0.001 seconds |

Result bundle: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-dpltaiphkatayyaghnxlaebxkmtj/Logs/Test/Test-CanadianHam-2026.10.25_13-43-46--0400.xcresult`.
