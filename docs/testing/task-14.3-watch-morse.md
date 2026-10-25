# TASK-14.3 — watchOS Morse practice

## Status and scope

**Blocked: owner hardware check.** AC2 is not satisfied by simulator tests.
No physical-watch observations have been made by the implementation agent.
Keep TASK-14.3 In Progress and AC2 unchecked until the owner records them here.

This is an offline, in-memory A–Z identification drill, not a course, progress
tracker or ISED exam. Four shuffled, distinct letter answers unlock after playback
(or after requesting the text alternative). Feedback grades the submitted letter;
Replay keeps the same letter and Next draws a different one. Settings live above
the destination for the current process only; relaunch restores defaults.

## Fixed-preset mapping and supported cadence

- Dot: `WKInterfaceDevice.current().play(.click)`.
- Dash: `WKInterfaceDevice.current().play(.directionUp)`.
- Rationale: a brief click versus a directional preset should provide different
  tactile signatures without adding multiple dot-like taps for one dash. This is
  a **candidate mapping**, not an assertion that the dash lasts three times as long.
  WatchKit supplies fixed patterns, not arbitrary-duration Morse pulses, and does
  not expose a preset-duration/completion API or a way to stop an issued preset.
- `textToTimedMorse` / `TimedMorseSequence` supplies every symbol onset and duration.
  Selectable speeds are **1, 1.5 and 2 WPM** (default 2). All inputs are clamped to
  1–2 WPM, including when only tone is on. This deliberately slow preset practice
  makes no exam timing/fidelity claim.
- At the fastest speed, dot = 0.6 s, dash = 1.8 s, intra-character gap = 0.6 s.
  The minimum nominal dot-to-next-symbol onset spacing is therefore **1.2 s**;
  dash-to-next-symbol spacing is at least 2.4 s. Slower speeds widen these gaps.
- The controller enforces a **1.2 s actual onset spacing floor**, including across
  cancellation/Next/replay. A delayed main actor reschedules the next preset
  instead of dumping overdue events in a burst. This is a conservative engineering
  floor, **not an Apple-guaranteed minimum**: only hardware can establish that these
  particular presets finish without overlap/collapse. If they do not, AC2 stays
  blocked and the measured result must be escalated rather than claiming success.
- One character does not need the engine's trailing word gap; playback finishes
  after its last symbol's full duration. Replay is disabled during playback.
  Cancellation invalidates scheduled callbacks and stops/detaches tone synthesis;
  an already issued WatchKit preset may finish, but no pending preset continues.
- Optional 600 Hz tones are independently enabled and generated from the same
  sequence using a local `AVAudioEngine` / `AVAudioSourceNode`, 5 ms edge envelopes
  and fixed 0.2 amplitude. No audio input, recording, files or network are used.
  Tones follow sample timing; under a main-actor stall, safety spacing can delay
  haptics relative to tone. Test both together on hardware, not just separately.

The dot/dash text pattern is static, not flashing, and has localized spoken
“Dot”/“Dash” labels. It is absent from the pre-answer accessibility tree while an
output is enabled. With both outputs off, an accessible message explains the state
and a button requests the pattern without revealing the letter. Output failures
show an accessible recovery message. Only grading announces correctness; playback
labels/identifiers never encode the target letter or pattern.

Leaving the view, scene inactivity, audio-session interruption/media-services
reset, settings presentation/changes and Next all cancel playback. There is no
workout, location or extended runtime session. No persistence APIs are introduced.

## Owner hardware check

1. **Install via internal TestFlight** once the watch payload is available through
   TASK-14.6's approved distribution lane. Record build number, watch model, watchOS
   version, wrist/strap fit, system haptic strength, Silent Mode and audio route.
   Start with the watch foregrounded, tone off and haptics on. No upload or hardware
   validation was performed for this implementation.
2. At 2 WPM, try representative short characters **E, T, I, M**; long characters
   **O and H** (digits such as 0 are not part of this A–Z drill); mixed characters
   **A, N, K, R, C**. The drill is random: answer a round to reveal its letter, then
   use Replay for known examples and Next to find the next example. Do not add
   a letter-reveal launch argument to TestFlight. Repeat at 1.5 and 1 WPM.
3. “**Distinguishable**” means that, after learning which preset is dot and dash,
   the owner can recover the correct ordered dot/dash count from touch alone for
   every representative example, without a dot vanishing into a dash, adjacent
   presets merging, a dash being mistaken for extra dots, or a replay overlapping
   the previous character. Repeat each known representative at least three times,
   then use randomized pre-answer rounds to check recognition without looking at
   the pattern or enabling tone. Record confusions/retries, not just a subjective
   “felt OK”. No supported speed may depend on guessing an overlapping pattern.
4. Independently enable tone with haptics off, then both on; check the same examples
   and note route/latency and any perceptible alignment problem. Test Replay,
   immediate Next, navigating back, lowering the wrist/scene inactivity, and an
   actual system/audio interruption. No later pending output should arrive.
   A preset already in flight is allowed to finish; a new Play must not collapse
   into it. Check the static text alternative with both outputs off.
5. With VoiceOver, check that Play/Replay and the initial prompt never speak the
   letter/pattern, all four choices can be reached, feedback is announced only
   after submission, and the requested/post-answer pattern reads dot/dash words.
   Check smallest-watch layout and large text during the companion polish task.
6. If any example/speed is unreliable, record the model/speed/letter and exact
   symptom, **leave AC2 unchecked and escalate**. Do not silently substitute tone
   for haptic fidelity or mark the task Done. If successful, append actual
   observations before checking AC2.

### Hardware observations (owner to fill after testing)

No observations yet. Suggested record fields: date/build/model/watchOS; system
haptic configuration and strap fit; speed; letter; correct ordered pattern on
three known replays; randomized-round confusions; overlap/collapse; tone route and
alignment; cancellation and VoiceOver results; pass/fail with reproduction notes.

## Automated evidence

Validation date: 2026-10-25.
The Morse package itself is unchanged; its existing timing fixture is bundled
only into the watch unit-test target, not into the app's practice content.

### Watch per-test results

Destination: `platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0`.
The requested complete scheme run initially had 24 passes and 2 failures out of
26 tests. Fix rounds reran only affected tests, per repository policy. The table
combines the unchanged tests' scheme-run passes with the targeted final passes:
**21 unit tests and 6 UI tests (27 distinct tests), all passing**. One new real-tone
regression test was added after the initial run.

The initial content check counted the timing fixture in the injected test plug-in
as app data; the fix excludes only that injected test bundle, retaining the exact
app JSON allowlist. Settings automation was corrected for native watch switch
thumb hit targets, a button-style Picker and lazy Form rows. The tone-only UI path
then exposed a Swift 6 actor-isolation trap on the audio callback; moving callback
construction into the non-main-actor renderer fixed it, and a real-driver
render/restart unit test now guards it. No failing test was skipped or removed.

| Test | Result | Seconds | Passing run |
| --- | --- | ---: | --- |
| `CanadianHamWatchTests.CanadianHamWatchTests.testIndependentOfflineBundle` | PASS | 0.006 | scheme |
| `CanadianHamWatchTests.CanadianHamWatchTests.testPlannedSections` | PASS | 0.001 | scheme |
| `CanadianHamWatchTests.CanadianHamWatchTests.testSharedPackagesOnWatch` | PASS | 0.003 | scheme |
| `CanadianHamWatchTests.WatchMorseTests.testCancelBeforeStartAndMidSequenceInvalidatesEvenStaleCallbacks` | PASS | 0.003 | targeted final |
| `CanadianHamWatchTests.WatchMorseTests.testDelayedSchedulerDoesNotCollapsePresets` | PASS | 0.001 | targeted final |
| `CanadianHamWatchTests.WatchMorseTests.testFourDistinctSeededChoicesGradingAndNextReset` | PASS | 0.006 | targeted final |
| `CanadianHamWatchTests.WatchMorseTests.testLocalToneDriverRendersOffMainActorAndRestartsAfterStop` | PASS | 0.549 | targeted final |
| `CanadianHamWatchTests.WatchMorseTests.testNextCancelsAndPreservesPresetCooldown` | PASS | 0.001 | targeted final |
| `CanadianHamWatchTests.WatchMorseTests.testOutputsAreIndependentOffDoesNotStartAndToneFailureStops` | PASS | 0.004 | targeted final |
| `CanadianHamWatchTests.WatchMorseTests.testReplayCannotOverlapAndCompletedReplayUsesSameSequence` | PASS | 0.001 | targeted final |
| `CanadianHamWatchTests.WatchMorseTests.testSpeedClampsAndAllLettersRespectCadenceFloor` | PASS | 0.002 | targeted final |
| `CanadianHamWatchTests.WatchMorseTests.testTimingFixturesMapToWatchPresetsAndToneSegments` | PASS | 0.006 | targeted final |
| `CanadianHamWatchTests.WatchPracticeTests.testAColdBundledPracticeLoadMeasurements` | PASS | 0.255 | scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testDistractorNotesFollowDisplayedOrderWithOfficialChoiceText` | PASS | 0.307 | scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testEmptyLoadErrorAndMissingResourcesFailSafely` | PASS | 0.001 | scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testFrenchExplanationFallbackHasEnglishAccessibilityLanguage` | PASS | 0.293 | scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testMeasureBundledPracticeLoad` | PASS | 0.010 | scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testNewSessionRestoresNeitherAnswerNorQuestionSequence` | PASS | 0.142 | scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testRenderedExplanationsNeverExposeAuthoringLabels` | PASS | 0.434 | scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testSeededShuffleGradesSourceIndexNotDisplayPositionAndLocksSubmission` | PASS | 0.161 | scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testWatchBundleContainsCompleteBasicBankAndOnlyPracticeContent` | PASS | 0.256 | targeted practice fix |
| `CanadianHamWatchUITests.CanadianHamWatchUITests.testLaunchAndNavigateEnglish` | PASS | 16.007 | scheme |
| `CanadianHamWatchUITests.CanadianHamWatchUITests.testLaunchAndNavigateFrench` | PASS | 14.808 | scheme |
| `CanadianHamWatchUITests.WatchMorseUITests.testIndependentOutputsTextAlternativeAndSessionOnlySettings` | PASS | 106.607 | targeted final |
| `CanadianHamWatchUITests.WatchMorseUITests.testPlayReplayAnswerNextAndNoEarlyReveal` | PASS | 60.071 | scheme |
| `CanadianHamWatchUITests.WatchPracticeUITests.testCrownSelectionRequiresConfirmAndFrenchFeedbackLabelsEnglishFallback` | PASS | 53.490 | scheme |
| `CanadianHamWatchUITests.WatchPracticeUITests.testTapFeedbackNextAndRelaunchDoesNotRestoreAnswer` | PASS | 32.264 | scheme |

Watch logs (local): `/tmp/task-14.3-watch.log` (initial),
`/tmp/task-14.3-watch-fix1.log` (practice correction), and
`/tmp/task-14.3-watch-fix4.log` (final Morse unit/settings UI).
The final targeted run reports `TEST SUCCEEDED`; simulator diagnostic collection
emits an unrelated `xcrun ... simctl` lookup warning after testing on this host.

### Other checks

| Check | Result |
| --- | --- |
| XcodeGen generation twice, byte compare | PASS, deterministic project |
| `pnpm check:apple-l10n` | PASS, complete French export and tvOS/visionOS/watchOS builds; catalogue unchanged by final check |
| `node scripts/check-apple-text-sources.ts --self-test` and normal check | PASS |
| `pnpm check:apple-network` and `pnpm test:apple-network` | PASS |
| `pnpm check:apple-icloud-gate` and `pnpm test:apple-icloud-gate` | PASS |
| `node scripts/check-test-guard.mjs --self-test` and `--base origin/main --head HEAD` | PASS, no guarded changes |
| iOS `CanadianHam` build-for-testing, iPhone 17 Pro | PASS, embedded watch compiles |
| macOS `CanadianHam` unit tests, arm64 | PASS, 223/223; [per-test report](task-14.3-macos-unit-results.md) |
| `git diff --check` | PASS |

The first localization export discovered the missing Replay key and therefore
rewrote catalogue ordering. The catalogue was restored from the ordered Python
round-trip and Replay received fr/fr-CA translations; the final localization check
passes without any rewrite. No unrelated catalogue values changed.

Exact Apple commands (all through `xbuild`, no direct `xcodebuild`):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' test CODE_SIGNING_ALLOWED=NO
# Fix rounds added only the affected -only-testing selectors:
# CanadianHamWatchTests/WatchPracticeTests/testWatchBundleContainsCompleteBasicBankAndOnlyPracticeContent
# CanadianHamWatchTests/WatchMorseTests
# CanadianHamWatchUITests/WatchMorseUITests/testIndependentOutputsTextAlternativeAndSessionOnlySettings
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build-for-testing CODE_SIGNING_ALLOWED=NO
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

macOS units were run because the string catalogue is shared. No shared Swift
source/package changed, so `packages/morse-swift` `swift test` was not required.
No full iOS/tvOS/visionOS suites ran: app source changes belong only to the watch
target; other platforms only consume additive watch strings. Their localization
builds (plus iOS test compilation and macOS units) passed. Full platform merge-batch
suites remain coordinator-owned. Figure/title-sweep plans do not apply. No
TestFlight upload, physical-watch run or manual VoiceOver listening check was made.
