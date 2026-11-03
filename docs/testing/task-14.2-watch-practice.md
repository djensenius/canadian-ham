# TASK-14.2 — watchOS quick Basic practice

2026-10-25, **review-fix evidence**. Branch: `task-14.2-watch-practice`.
Runtime/model/UI/test fixes: `d8790e996a55aa497e84d77fc733b0210957fb05`.
Final catalogue cleanup: `abdf6079` (only removes the now-unused “Not selected”
entry). Subsequent commits record task notes and evidence. No PR or TestFlight
upload was created by this task. Internal re-review is still required.

This replaces the original evidence. **The earlier 0.218668292-second “cold”
measurement and its resident-memory delta were not cold:** constructing the old
home navigation destination eagerly loaded the bank. Do not use those numbers.

## Implementation and acceptance evidence

- The watch bundles the unchanged full Basic bank and explanations directly from
  their original folders, without ContentLibrary's lesson dependencies. It has
  984 unique questions, four bilingual answers each, metadata and 984 matching
  explanations. The loader validates metadata, IDs, bilingual answers and parsed
  explanation bodies. No official text was rewritten or translated.
- Home uses value-based navigation destinations. `WatchPracticeView` starts with
  an **optional, nil session**, displaying a labelled, accessible
  `ProgressView("Loading question bank")`. Only its appearance `.task` requests
  `WatchPracticeBankLoader.shared`; the actor retains one detached task, sharing
  its result across concurrent calls and subsequent visits. JSON decoding and
  whole-bank validation happen off the main thread (also asserted in Debug).
  Home, Morse and Alphabet have no load request. Constructing home/practice
  views does not start the cache. Cancellation cannot install a stale session.
- The first-touch unit probe asserts the loader count is **0 before** and **1
  after** loading. The cache test makes concurrent requests and checks that the
  count remains 1. The final probe ran in a fresh test-host process with only
  itself and the later bundle test selected, before any other bank access.
- `WatchPracticeSession` uses engine-swift `Pcg32` and `shuffled`; whole `Answer`
  values retain `sourceIndex` for grading. Twenty seeded draws cover correct and
  wrong choices after shuffling, determinism, invalid indices, answer locking
  and Next. Next excludes the immediately previous question. Empty/throwing
  loads produce the localized unavailable state rather than an index error.
- Tapping submits immediately. A separate Crown sheet owns Crown focus on its
  scroll container and exposes an accessibility-adjustable answer control.
  Crown rotation changes selection only; Confirm submits. The French UI test
  uses actual `XCUIDevice.shared.rotateDigitalCrown(delta:)` events and observes
  **all four answer texts before Confirm**, without feedback/submission during
  rotation. Touch scrolling reads choices without changing selection. No
  test-only selection/submission hook replaces real Crown input.
- Feedback locks the choices and shows textual correctness, selected answer,
  correct answer, explanation and Next. All text remains scrollable and uses
  semantic fonts. There are no hints, dead lesson links, colour-only correctness
  or `minimumScaleFactor`. “Your answer”, “Correct answer” and “Explanation” have
  the header trait. Both submission paths post a localized Correct/Incorrect
  VoiceOver announcement. Unanswered buttons no longer claim a hard-coded “Not
  selected” value; the selected feedback/Crown control still report real state.
- `WatchExplanationText` now renders `ExplanationBodyParser`'s
  **correctAnswerParagraph**, then each distractor note labelled by its **quoted
  choice text**, never letters/positions or internal source indices. Its
  whole-bank test checks all 984 explanations in both language modes: the full
  rendered text contains neither `sourceIndex` nor `Question B-`, and exactly
  preserves the parsed paragraph and quoted-choice notes. UI tests check actual
  power-unit explanation prose and quoted distractors, not the raw authoring
  header. All existing bodies lack French: French UI clearly labels
  **« Explication en anglais »**, and every fallback attributed run, including
  quoted choices and notes, retains **en-CA**. The translated-body fixture
  verifies the French path and fr-CA runs without authoring a bank translation.
- Practice UI tests use DEBUG-only `-watchPracticeSeed 3121`. The unit test pins
  its first two question IDs to `B-005-003-006` (short power-units question) and
  `B-001-016-001`, including their shuffled choices. English UI deliberately
  answers “ohms”, checks Incorrect / correct answer “watts”, advances to the
  known second stem, answers again, relaunches and verifies that the first
  question/choices restart unanswered and remain actionable. Reveal helpers no
  longer depend on a random long question or a 24-attempt budget. Session reset
  units compare the complete initial question/choices and replay the second
  draw, rather than merely relying on Next's no-repeat rule.
- All session state is in memory: no history, scores, preferences, files written
  by the app, UserDefaults, App Groups, network or transfers. During the review
  UI run, `simctl listapps` on the paired iPhone Air confirmed that
  `org.davidjensenius.CanadianHam` was **not installed**. Practice used only the
  watch's own resources; no phone counterpart was needed.

## Independent bundle/verbatim checks

The unit bundle test compares the exact JSON path set and a known official
question's EN/FR stem plus all four EN/FR answers against literals (power units),
not a second decode of the same file. It rejects loose SVG/PNG resources and
excluded content paths. This replaces the ineffective `figureassets.car` check.

Final installed-bundle inspection independently checked:

- **988 JSON files byte-for-byte identical to source**: four generated Basic JSON
  files plus 984 original explanations, with no extra JSON paths.
- **Zero loose SVG/PNG resources.** Host `assetutil --info` on the actual compiled
  **Assets.car** reported three metadata/rendition entries, whose only named
  asset was **AppIcon**; no figure names or images were compiled into it.
- `WKApplication` and `WKRunsIndependentlyOfCompanionApp` true; UIBackgroundModes
  and WKBackgroundModes absent. “Answer” and “Not selected” absent from every
  compiled Localizable.strings language table.

Inspection log: `/tmp/task-14.2-review-bundle-inspection-final.log`.
Compiled asset metadata: `/tmp/task-14.2-review-assets-final.json`.
Installed app:
`~/Library/Developer/CoreSimulator/Devices/02C40D35-B5AD-40AF-B434-C63C5F294C27/data/Containers/Bundle/Application/47B6EFBC-8B99-4A40-BB4B-09F2E3B5C6B0/CanadianHamWatch.app`.

Reproduce against the installed app (`APP` is that path):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun --sdk macosx assetutil --info "$APP/Assets.car"
APP="$APP" python3 - <<'PY'
import os, json
from pathlib import Path
root = Path(os.environ['APP'])
expected = {Path('basic-2025-07-15') / p.name: p
            for p in Path('content/generated/basic-2025-07-15').glob('*.json')}
expected.update({Path('explanations') / p.relative_to('content/explanations'): p
                 for p in Path('content/explanations').rglob('*.json')})
assert {p.relative_to(root) for p in root.rglob('*.json')} == set(expected)
assert len(expected) == 988
assert all((root / rel).read_bytes() == src.read_bytes() for rel, src in expected.items())
assert not any(p.suffix.lower() in {'.svg', '.png'} for p in root.rglob('*'))
print('988 exact source-byte matches; no loose figure images')
PY
```

## Measurements (installed Debug WatchSimulator, not hardware/release)

Destination: Apple Watch Series 12 (42mm), watchOS 27.0. Final measurement used
`abdf6079` sources, in a **fresh XCTest host process** with only
`testAColdBundledPracticeLoadMeasurements` and the later bundle test selected.
The host does not open Practice. The first probe asserts zero cache starts,
then measures the real actor loader's **first** request, including detached-task
scheduling, all JSON decoding and validation/parser work. It then verifies one
cache start. The later bundle test cannot warm this timed interval. This is a
**cold process/decoder/cache**, not a claim that the OS filesystem cache was
flushed. A keepAlways XCTest attachment records the report.

Resident bytes use `mach_task_basic_info` immediately before/after awaiting the
retained cached bank; these are resident snapshots, **not peak allocations**.
The test host/frameworks account for much of the baseline. Concurrent builds
and the simulator affect timing. Earlier review-run first-touch probes measured
0.249593 and 0.324053916 seconds; the final report below is not a best-of sample.
The warm-cache probe in the full review run took 0.000029125 seconds and added
zero resident bytes; it is not used as the bank's memory estimate.

| Measurement | Final result |
|---|---:|
| Original resources, 988 files | 2,360,969 bytes (2.25 MiB) |
| First complete-bank load through actor cache | 0.3650345 seconds |
| Resident before / after | 213,499,904 / 221,757,440 bytes |
| Retained-bank resident delta | 8,257,536 bytes (7.88 MiB) |
| Installed regular files | 1,018 |
| Installed logical / allocated bytes, including injected test PlugIns | 17,064,210 / 20,119,552 |
| App excluding test PlugIns, logical / allocated bytes | 10,162,513 / 13,197,312 |

Allocated sizes use `st_blocks × 512`. All size numbers are Debug simulator
artifacts, not signed-release sizes. Physical-watch startup/memory, VoiceOver
listening, Dynamic Type sweeps and full accessibility audits remain the planned
TASK-14.5/14.6 gates. Posting the announcement is implemented; this is not a
claim of a physical VoiceOver listening check.

## Commands and results

All Apple commands ran through **xbuild**, never direct xcodebuild. Shell
runners waited on its shared build lock; no other build was killed and no extra
simulator destination was manually booted. The watch runner booted its required
OS-paired phone; this is not an app-level counterpart/transfer dependency.

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# Full requested watch scheme run: 14/15 passed; corrected assertion described below.
xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' \
  test CODE_SIGNING_ALLOWED=NO

# Fix-round rerun: 3/3 passed.
xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' \
  -only-testing:CanadianHamWatchTests/WatchPracticeTests/testAColdBundledPracticeLoadMeasurements \
  -only-testing:CanadianHamWatchTests/WatchPracticeTests/testWatchBundleContainsCompleteBasicBankAndOnlyPracticeContent \
  -only-testing:CanadianHamWatchUITests/WatchPracticeUITests/testTapFeedbackNextAndRelaunchDoesNotRestoreAnswer \
  test CODE_SIGNING_ALLOWED=NO

# Final catalogue-stable fresh-process measurement/bundle rerun: 2/2 passed.
xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' \
  -only-testing:CanadianHamWatchTests/WatchPracticeTests/testAColdBundledPracticeLoadMeasurements \
  -only-testing:CanadianHamWatchTests/WatchPracticeTests/testWatchBundleContainsCompleteBasicBankAndOnlyPracticeContent \
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

git diff --check
```

- **15 distinct watch tests (11 unit + 4 UI) passed across these scoped runs.**
  The full review run's one failure was an overly strict new assertion that
  rejected any Assets.car, including the existing AppIcon. The final test
  rejects actual loose SVG/PNG resources instead, and independent assetutil
  inspection verifies that compiled Assets.car contains only AppIcon. The
  corrected bundle test passed in both scoped reruns. No unresolved failures,
  audits removed, exception helpers, or skips were added.
- **223/223 macOS units passed** on the final catalogue (rerun because a shared
  file changed). Embedded-watch iOS container **TEST BUILD SUCCEEDED**.
- **pnpm check:apple-l10n passed**: complete French export, text checks, generic
  tvOS/visionOS/watch builds and unchanged catalogue hashes. The first attempt
  exposed the now-unused “Not selected” key after its hard-coded value was
  removed; it was deleted, like unused “Answer”, using a Python JSON round-trip
  preserving existing key order. The repeat passed without Xcode catalogue
  mutation. No other catalogue keys or translations were changed.
- Network/iCloud guards plus fixtures, text-source check/self-test, test guard
  and its self-test passed. Test guard found no guarded changes against main;
  no approval marker is needed. Whitespace check passed. Project membership and
  XcodeGen files did not change in this fix round (original task double-generation
  evidence still applies).
- iOS runtime suites, tvOS/visionOS runtime suites, lesson-figure and title-sweep
  plans were not run: no corresponding Swift source/layout/content changed.
  Shared-catalogue macOS regression and the requested localization/generic and
  embedded iOS builds ran. Full affected-platform merge-batch suites and watch
  accessibility polish remain coordinator gates.
- Existing AppIntents/plural-inference and operatingSystemBuild warnings were
  non-fatal. Optional watch diagnostic collection still logged a subprocess
  `simctl` lookup error, but both final watch commands returned 0 and reported
  **TEST SUCCEEDED**.

### Logs and result bundles

Logs under `/tmp/`:
- `task-14.2-review-watch.log` — full requested run, initial 14/15.
- `task-14.2-review-watch-targeted.log` — corrected cold/bundle/tap, 3/3.
- `task-14.2-review-cold-final.log` — final first-touch/bundle, 2/2.
- `task-14.2-review-localization.log` — first stale-key discovery.
- `task-14.2-review-localization-final.log` — successful localization repeat.
- `task-14.2-review-ios.log` / `task-14.2-review-macos.log` — successful platform gates.

Result bundles under
`~/Library/Developer/Xcode/DerivedData/CanadianHam-gpcrwrqyugpkhugopywamwhwiyth/Logs/Test/`:
- Full watch: `Test-CanadianHamWatch-2026.10.25_14-48-08--0400.xcresult`.
- Corrected watch: `Test-CanadianHamWatch-2026.10.25_14-52-12--0400.xcresult`.
- Final measurement: `Test-CanadianHamWatch-2026.10.25_14-55-08--0400.xcresult`.
- Full macOS unit target: `Test-CanadianHam-2026.10.25_14-56-06--0400.xcresult`.

## Watch per-test results

Latest successful result for each test; cold/bundle use the final measurement
run, tap uses the corrected targeted run, and all other rows use the full review
run. The app's Swift implementation is identical across them; only test cleanup
and unused catalogue-key removal followed the first run.

| Test | Result | Duration |
|---|---|---|
| `CanadianHamWatchTests.CanadianHamWatchTests.testIndependentOfflineBundle` | passed | 0.003 seconds |
| `CanadianHamWatchTests.CanadianHamWatchTests.testPlannedSections` | passed | 0.001 seconds |
| `CanadianHamWatchTests.CanadianHamWatchTests.testSharedPackagesOnWatch` | passed | 0.001 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testAColdBundledPracticeLoadMeasurements` | passed | 0.375 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testEmptyLoadErrorAndMissingResourcesFailSafely` | passed | 0.004 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testFrenchExplanationFallbackHasEnglishAccessibilityLanguage` | passed | 0.285 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testMeasureBundledPracticeLoad` | passed | 0.008 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testNewSessionRestoresNeitherAnswerNorQuestionSequence` | passed | 0.139 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testRenderedExplanationsNeverExposeAuthoringLabels` | passed | 0.417 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testSeededShuffleGradesSourceIndexNotDisplayPositionAndLocksSubmission` | passed | 0.166 seconds |
| `CanadianHamWatchTests.WatchPracticeTests.testWatchBundleContainsCompleteBasicBankAndOnlyPracticeContent` | passed | 0.170 seconds |
| `CanadianHamWatchUITests.CanadianHamWatchUITests.testLaunchAndNavigateEnglish` | passed | 15.710 seconds |
| `CanadianHamWatchUITests.CanadianHamWatchUITests.testLaunchAndNavigateFrench` | passed | 14.570 seconds |
| `CanadianHamWatchUITests.WatchPracticeUITests.testCrownSelectionRequiresConfirmAndFrenchFeedbackLabelsEnglishFallback` | passed | 56.310 seconds |
| `CanadianHamWatchUITests.WatchPracticeUITests.testTapFeedbackNextAndRelaunchDoesNotRestoreAnswer` | passed | 36.074 seconds |

## Full macOS unit target per-test results (223)

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
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds` | passed | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes` | passed | 0.001 seconds |
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
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility` | passed | 0.000 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples` | passed | 0.000 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` | passed | 0.395 seconds |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute` | passed | 0.289 seconds |
| `CanadianHamTests.HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` | passed | 0.003 seconds |
| `CanadianHamTests.HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp` | passed | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` | passed | 0.002 seconds |
| `CanadianHamTests.HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` | passed | 2.666 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata` | passed | 0.003 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection` | passed | 0.002 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusMapsShuffledSourceChoices` | passed | 0.002 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext` | passed | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations` | passed | 0.015 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` | passed | 0.004 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides` | passed | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish` | passed | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale` | passed | 0.004 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testReviewHeadingMarksEnglishFallbackTitleInsideFrenchText` | passed | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testFixedTimingProfilesUseEngineValues` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testLessonBodyAndBulletContrastTokensMeetMinimumRatio` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession` | passed | 1.663 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas` | passed | 0.003 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` | passed | 0.004 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints` | passed | 0.003 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` | passed | 0.003 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesPressWhenAudioFails` | passed | 0.003 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReleaseCannotBeSupersededBySilence` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError` | passed | 0.106 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsClampAndPreset` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode` | passed | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` | passed | 0.011 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults` | passed | 0.004 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | passed | 0.045 seconds |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback` | passed | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` | passed | 0.076 seconds |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts` | passed | 0.024 seconds |
| `CanadianHamTests.ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` | passed | 0.004 seconds |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` | passed | 0.024 seconds |
| `CanadianHamTests.ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields` | passed | 0.031 seconds |
| `CanadianHamTests.ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` | passed | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` | passed | 0.022 seconds |
| `CanadianHamTests.ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` | passed | 0.058 seconds |
| `CanadianHamTests.ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem` | passed | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory` | passed | 0.068 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` | passed | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete` | passed | 0.026 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` | passed | 0.136 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent` | passed | 0.002 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` | passed | 0.047 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` | passed | 0.035 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` | passed | 0.046 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` | passed | 0.064 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportLeavesTask4610Version2LessonSplitRowsUnchanged` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesMixedTask4610SyncRowsByRowVersion` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesTask4610LessonSplitProgressAndQuizAttempts` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress` | passed | 0.032 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows` | passed | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues` | passed | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` | passed | 0.071 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails` | passed | 0.044 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` | passed | 0.033 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` | passed | 0.035 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` | passed | 0.042 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId` | passed | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` | passed | 0.032 seconds |
| `CanadianHamTests.ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` | passed | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` | passed | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` | passed | 0.013 seconds |
| `CanadianHamTests.ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue` | passed | 0.009 seconds |
| `CanadianHamTests.ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` | passed | 0.008 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyEmptyReviewQuestionIdsImportAtTopLevelAndInSyncRows` | passed | 0.097 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` | passed | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` | passed | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` | passed | 0.009 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` | passed | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpFixtureValidationAndPayloadRoundTrips` | passed | 0.132 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix` | passed | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice` | passed | 2.769 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation` | passed | 0.002 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` | passed | 0.059 seconds |
| `CanadianHamTests.ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` | passed | 0.052 seconds |
| `CanadianHamTests.ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` | passed | 0.035 seconds |
| `CanadianHamTests.ProgressStoreTests.testM1QuizRoundBoundariesPreserveOneSessionAnswersHelpAndDismissedCheckpoint` | passed | 0.560 seconds |
| `CanadianHamTests.ProgressStoreTests.testM1QuizRoundsRetainEveryItemAndSeededOrderWithinTeachingSections` | passed | 0.553 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` | passed | 0.013 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` | passed | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` | passed | 0.405 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` | passed | 0.019 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` | passed | 0.076 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` | passed | 0.079 seconds |
| `CanadianHamTests.ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` | passed | 0.031 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences` | passed | 0.054 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender` | passed | 0.976 seconds |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference` | passed | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences` | passed | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` | passed | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` | passed | 0.041 seconds |
| `CanadianHamTests.ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` | passed | 0.036 seconds |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` | passed | 0.040 seconds |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreRoundTripExportImportReset` | passed | 0.060 seconds |
| `CanadianHamTests.ProgressStoreTests.testQuizRoundsWithConceptChecksKeepTheCompleteUngroupedOrder` | passed | 0.545 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff` | passed | 0.013 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` | passed | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` | passed | 0.045 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference` | passed | 0.014 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference` | passed | 0.014 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails` | passed | 0.016 seconds |
| `CanadianHamTests.ProgressStoreTests.testReviewAttemptPayloadImportSyncAndLegacyVersionRejection` | passed | 0.056 seconds |
| `CanadianHamTests.ProgressStoreTests.testReviewItemsUseEarlierTaughtPoolsAndFinalM1Round` | passed | 1.660 seconds |
| `CanadianHamTests.ProgressStoreTests.testReviewSourceMayDifferFromCanonicalHintLessonWithAuthoredSectionAnchor` | passed | 0.551 seconds |
| `CanadianHamTests.ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext` | passed | 1.802 seconds |
| `CanadianHamTests.ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates` | passed | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` | passed | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` | passed | 0.006 seconds |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` | passed | 0.093 seconds |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` | passed | 0.067 seconds |
| `CanadianHamTests.ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` | passed | 0.032 seconds |
| `CanadianHamTests.ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` | passed | 0.009 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices` | passed | 0.044 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports` | passed | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration` | passed | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds` | passed | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating` | passed | 0.104 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610SharedConceptMappingAndConceptInclusiveScores` | passed | 0.265 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows` | passed | 0.040 seconds |
| `CanadianHamTests.ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` | passed | 0.057 seconds |
| `CanadianHamTests.QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` | passed | 0.012 seconds |
| `CanadianHamTests.QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` | passed | 0.013 seconds |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsNoReadmeFiles` | passed | 0.013 seconds |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories` | passed | 0.001 seconds |
| `CanadianHamTests.QuestionBankTests.testBundledJSONDecodesExpectedCounts` | passed | 0.019 seconds |
| `CanadianHamTests.QuestionBankTests.testBundledLessonModelExposesPrerequisites` | passed | 0.556 seconds |
| `CanadianHamTests.QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary` | passed | 0.727 seconds |
| `CanadianHamTests.QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` | passed | 0.019 seconds |
| `CanadianHamTests.QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` | passed | 0.079 seconds |
| `CanadianHamTests.QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` | passed | 0.001 seconds |
| `CanadianHamTests.QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` | passed | 0.559 seconds |
| `CanadianHamTests.ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours` | passed | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests.testExamScoringBoundaries` | passed | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests.testReadinessStates` | passed | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` | passed | 0.034 seconds |
| `CanadianHamTests.RootNavigationMappingTests.testCompactHomeSessionAndSectionPushesUseVisibleDestination` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests.testEmptyCompactPathMapsToHome` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests.testEveryLearnRouteRoundTripsWithItsWholeStack` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests.testEveryRootSelectionRoundTrips` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests.testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts` | passed | 0.001 seconds |
| `CanadianHamTests.RootNavigationMappingTests.testPracticeHintLessonStackKeepsSessionAsSplitSelection` | passed | 0.001 seconds |
