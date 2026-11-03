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

The **Haptic style** picker in Output settings offers three session-only candidates.
Their names and descriptions are localized in EN/FR; relaunch restores Style 1.
`WatchMorseHapticStyle.presets` is the single table used by the WatchKit adapter.

| Style | UI description | Dot preset | Dash preset | Candidate rationale |
| --- | --- | --- | --- | --- |
| Style 1 (unchanged default) | Light dot, rising dash | `.click` | `.directionUp` | Baseline: a light click versus a directional preset. |
| Style 2 | Light dot, firm dash | `.click` | `.start` | Keeps the same dot while comparing a different dash signature. |
| Style 3 | Stronger dot, firm dash | `.retry` | `.start` | Compares a potentially more noticeable dot against Style 2's dash. |

These descriptions are **candidate sensations**, not measured hardware claims.
A `.click` may be too faint, and `.directionUp`, `.retry` or `.start` may feel like
multiple taps: the owner must establish whether each is recognized as one Morse
symbol rather than assuming a single buzz. No pair claims a dash lasts three times
as long as a dot. WatchKit supplies fixed patterns, not arbitrary-duration Morse
pulses, and does not expose a preset-duration/completion API or a way to stop an
issued preset. Style 1 remains the default even if another wins this comparison;
only a later coordinator decision changes it.

For every style:

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

Leaving the view, scene inactivity, a **began** audio-session interruption,
media-services reset, settings presentation/changes and Next all cancel playback.
An **ended** interruption does not cancel a newly started Play. There is no
workout, location or extended runtime session. No persistence APIs are introduced.

## Owner hardware check

1. **Install locally from Xcode or via internal TestFlight**:
   - To check hardware before TASK-14.6, open
     `apps/apple/CanadianHam.xcodeproj` in Xcode, select the `CanadianHamWatch`
     scheme, choose the owner's **physical paired watch** (not a simulator), use
     the Debug configuration and the owner's normal development signing, then
     Product > Run. Enable Developer Mode/pairing if Xcode requests it. This is a
     direct development install on the owner's watch, **not distribution**; do not
     archive, upload, enable external testing or change release capabilities.
   - Alternatively, install the internal TestFlight watch payload once it is
     available through TASK-14.6's approved lane.
   Record commit/build number, installation method, watch model, watchOS version,
   wrist/strap fit, system haptic strength, Silent Mode and audio route. Start with
   the watch foregrounded, tone off and haptics on. No upload or hardware validation
   was performed for this implementation.
2. **Compare all three styles in the same session**: open Output settings > Haptic
   style, try Style 1, Style 2 and Style 3, and record which, if any, reliably
   distinguishes characters. Changing style keeps the current letter, so Replay
   can compare the exact same known example without relaunching. At 2 WPM, try
   representative short characters **E, T, I, M**; long characters **O and H**
   (digits such as 0 are not part of this A–Z drill); mixed characters **A, N, K, R,
   C**. Answer a round to reveal its letter, then use Replay for known examples and
   Next to find another example. Repeat at 1.5 and 1 WPM for each style.
   - Optional **Debug-only repeatable rounds**: in Product > Scheme > Edit Scheme >
     Run > Arguments Passed On Launch, enable `-watchMorseSeed` and a following seed
     value such as `3121` (the current first target is R). Stop and Run again with
     the same seed to return to the same initial letter/choice order. Answer once
     to confirm the known letter, then Replay it with each style; other seed values
     give other deterministic sequences. The seed chooses the random sequence,
     not a literal target-letter argument, and does not reveal the answer before
     submission. Remove the argument for blind randomized recognition checks.
     This argument is ignored outside DEBUG; do not add a letter-reveal mechanism
     to TestFlight.
3. “**Distinguishable**” means that, after learning which preset is dot and dash,
   the owner can recover the correct ordered dot/dash count from touch alone for
   every representative example, without a dot vanishing into a dash, adjacent
   presets merging, a dash being mistaken for extra dots, or a replay overlapping
   the previous character. Repeat each known representative at least three times,
   then use randomized pre-answer rounds to check recognition without looking at
   the pattern or enabling tone. Record confusions/retries, not just a subjective
   “felt OK”. No supported speed may depend on guessing an overlapping pattern.
4. With **tone off**, listen for and record any system sounds from **each haptic
   preset/style**, both with Silent Mode off and with **Silent Mode on**. Note
   whether any sound remains; do not assume haptics-only is inaudible. Independently
   enable tone with haptics off, then both on; check the same examples and note
   route/latency and any perceptible alignment problem. The tone session uses
   `.playback`, which can sound despite Silent Mode; record that behaviour too.
   Test Replay, immediate Next, navigating back, lowering the wrist/scene
   inactivity, and an
   actual system/audio interruption. No later pending output should arrive.
   A preset already in flight is allowed to finish; a new Play must not collapse
   into it. Check the static text alternative with both outputs off.
5. With VoiceOver, check that Play/Replay and the initial prompt never speak the
   letter/pattern, all four choices can be reached, feedback is announced only
   after submission, and the requested/post-answer pattern reads dot/dash words.
   Check smallest-watch layout and large text during the companion polish task.
6. If any example/speed/style is unreliable, record the model/style/speed/letter
   and exact symptom, **leave AC2 unchecked and escalate**. State which of the three
   pairs, if any, distinguishes all representative characters, and whether it is
   better than the default. Do not silently substitute tone for haptic fidelity,
   change the default or mark the task Done. The coordinator decides next steps
   (including any later default change) from these observations.

### Hardware observations (owner to fill after testing)

No observations yet. Suggested record fields: date/commit/build/install method/
model/watchOS; system haptic configuration and strap fit; **style/preset pair**;
speed; letter; correct ordered pattern on three known replays; randomized-round
confusions; overlap/collapse; **preset sounds with tone off, Silent Mode off/on**;
tone route and alignment; cancellation and VoiceOver results; pass/fail with
reproduction notes. Finish with a comparison of **all three styles from the same
session** and name the reliable pair(s), if any.

| Style | Speeds/letters tried | Touch-only recognition/confusions | Preset sounds, Silent Mode off/on | Distinguishes all examples? |
| --- | --- | --- | --- | --- |
| Style 1: `.click` / `.directionUp` | Not tested | Not tested | Not tested | Unknown |
| Style 2: `.click` / `.start` | Not tested | Not tested | Not tested | Unknown |
| Style 3: `.retry` / `.start` | Not tested | Not tested | Not tested | Unknown |

## Automated evidence

Validation date: 2026-10-25.
The Morse package itself is unchanged; its existing timing fixture is bundled
only into the watch unit-test target, not into the app's practice content.

### Watch per-test results

Destination: `platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0`.
The approved-review follow-up complete scheme run passed **23 unit tests and
6 UI tests (29/29), zero failures and zero skipped tests**, in one run. This
supersedes the earlier 27-test evidence combined from initial/fix runs. All three
preset pairs and forwarding of the selected style to playback are unit-tested.
The output-settings UI test now selects Styles 2 and 3, verifies the visible sheet
title, retains Style 3 across navigation and restores Style 1 on relaunch.

The real-tone regression no longer relies on a fixed sleep: an internal relaxed
atomic counts render callbacks only when they run **off the main thread**, and the
test polls for a positive count (bounded to 3 seconds) on each of two real engine
starts. Each stop must release the engine/source/session and reset the probe.
On this run **both starts rendered off-main**; the unavailable-session branch was
not taken. On a host where session category/activation throws, the driver wraps
that failure as `WatchMorseToneError.audioSessionUnavailable`, cleans up and
rethrows; the test instead asserts the playback controller's `outputFailed`,
not-playing/not-completed state and no active tone resources, and prints the
underlying error. Unexpected engine failures still fail the test; no `XCTSkip`
or silent return is used. The existing independent-output/fake-failure test also
asserts the user-facing unavailable-output state deterministically.

The new interruption test confirms that only `.began` cancels pending output;
`.ended`, missing and invalid interruption values leave a new Play running.

Earlier fix history: content validation excluded only the timing fixture inside
the injected test bundle (retaining the exact app JSON allowlist); settings
interaction uses native watch switch targets and lazy Form positioning; source
node callback construction moved outside the main actor to avoid a Swift 6
isolation trap. No failing test was removed or skipped.

| Test | Result | Seconds | Passing run |
| --- | --- | ---: | --- |
| `CanadianHamWatchTests.CanadianHamWatchTests.testIndependentOfflineBundle` | PASS | 0.004 | review follow-up scheme |
| `CanadianHamWatchTests.CanadianHamWatchTests.testPlannedSections` | PASS | 0.001 | review follow-up scheme |
| `CanadianHamWatchTests.CanadianHamWatchTests.testSharedPackagesOnWatch` | PASS | 0.002 | review follow-up scheme |
| `CanadianHamWatchTests.WatchMorseTests.testCancelBeforeStartAndMidSequenceInvalidatesEvenStaleCallbacks` | PASS | 0.005 | review follow-up scheme |
| `CanadianHamWatchTests.WatchMorseTests.testDelayedSchedulerDoesNotCollapsePresets` | PASS | 0.001 | review follow-up scheme |
| `CanadianHamWatchTests.WatchMorseTests.testFourDistinctSeededChoicesGradingAndNextReset` | PASS | 0.006 | review follow-up scheme |
| `CanadianHamWatchTests.WatchMorseTests.testHapticStylesMapEveryPairAndReachOutput` | PASS | 0.002 | review follow-up scheme |
| `CanadianHamWatchTests.WatchMorseTests.testLocalToneDriverRendersOffMainActorAndRestartsAfterStop` | PASS | 0.368 | review follow-up scheme |
| `CanadianHamWatchTests.WatchMorseTests.testNextCancelsAndPreservesPresetCooldown` | PASS | 0.001 | review follow-up scheme |
| `CanadianHamWatchTests.WatchMorseTests.testOnlyBeganAudioInterruptionCancelsPlayback` | PASS | 0.001 | review follow-up scheme |
| `CanadianHamWatchTests.WatchMorseTests.testOutputsAreIndependentOffDoesNotStartAndToneFailureStops` | PASS | 0.004 | review follow-up scheme |
| `CanadianHamWatchTests.WatchMorseTests.testReplayCannotOverlapAndCompletedReplayUsesSameSequence` | PASS | 0.001 | review follow-up scheme |
| `CanadianHamWatchTests.WatchMorseTests.testSpeedClampsAndAllLettersRespectCadenceFloor` | PASS | 0.002 | review follow-up scheme |
| `CanadianHamWatchTests.WatchMorseTests.testTimingFixturesMapToWatchPresetsAndToneSegments` | PASS | 0.005 | review follow-up scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testAColdBundledPracticeLoadMeasurements` | PASS | 0.361 | review follow-up scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testDistractorNotesFollowDisplayedOrderWithOfficialChoiceText` | PASS | 0.297 | review follow-up scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testEmptyLoadErrorAndMissingResourcesFailSafely` | PASS | 0.002 | review follow-up scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testFrenchExplanationFallbackHasEnglishAccessibilityLanguage` | PASS | 0.292 | review follow-up scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testMeasureBundledPracticeLoad` | PASS | 0.008 | review follow-up scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testNewSessionRestoresNeitherAnswerNorQuestionSequence` | PASS | 0.137 | review follow-up scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testRenderedExplanationsNeverExposeAuthoringLabels` | PASS | 0.411 | review follow-up scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testSeededShuffleGradesSourceIndexNotDisplayPositionAndLocksSubmission` | PASS | 0.157 | review follow-up scheme |
| `CanadianHamWatchTests.WatchPracticeTests.testWatchBundleContainsCompleteBasicBankAndOnlyPracticeContent` | PASS | 0.148 | review follow-up scheme |
| `CanadianHamWatchUITests.CanadianHamWatchUITests.testLaunchAndNavigateEnglish` | PASS | 18.108 | review follow-up scheme |
| `CanadianHamWatchUITests.CanadianHamWatchUITests.testLaunchAndNavigateFrench` | PASS | 14.750 | review follow-up scheme |
| `CanadianHamWatchUITests.WatchMorseUITests.testIndependentOutputsTextAlternativeAndSessionOnlySettings` | PASS | 136.414 | review follow-up scheme |
| `CanadianHamWatchUITests.WatchMorseUITests.testPlayReplayAnswerNextAndNoEarlyReveal` | PASS | 49.423 | review follow-up scheme |
| `CanadianHamWatchUITests.WatchPracticeUITests.testCrownSelectionRequiresConfirmAndFrenchFeedbackLabelsEnglishFallback` | PASS | 53.887 | review follow-up scheme |
| `CanadianHamWatchUITests.WatchPracticeUITests.testTapFeedbackNextAndRelaunchDoesNotRestoreAnswer` | PASS | 32.606 | review follow-up scheme |

Current watch log (local): `/tmp/task-14.3-review-watch.log`.
Result bundle (local):
`/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-ctwbvwzbkppqojfjszadlzwmugrn/Logs/Test/Test-CanadianHamWatch-2026.10.25_15-41-43--0400.xcresult`.
The run reports `TEST SUCCEEDED`. Simulator diagnostic collection still emits an
unrelated `xcrun ... simctl` lookup warning after testing on this host. Compiler
warnings include the existing catalogue plural substitutions, the watchOS 27
`AVAudioEngine.connect` deprecation and the requested legacy interruption-type
API's deprecation. The audio session also warns about synchronous main-thread
activation; no callback isolation crash or failed test occurred.

### Other checks

| Check | Result |
| --- | --- |
| XcodeGen generation twice, byte compare | Prior implementation PASS, deterministic project; no membership changes in review follow-up |
| `pnpm check:apple-l10n` | PASS again after review follow-up; complete French export and tvOS/visionOS/watchOS builds; both catalogues unchanged by check |
| `node scripts/check-apple-text-sources.ts --self-test` and normal check | PASS |
| `pnpm check:apple-network` and `pnpm test:apple-network` | PASS |
| `pnpm check:apple-icloud-gate` and `pnpm test:apple-icloud-gate` | PASS |
| `node scripts/check-test-guard.mjs --self-test` and `--base origin/main --head HEAD` | PASS, no guarded changes |
| iOS `CanadianHam` build-for-testing, iPhone 17 Pro | PASS again after review follow-up; embedded watch compiles |
| macOS `CanadianHam` unit tests, arm64 | Prior implementation PASS, 223/223; [per-test report](task-14.3-macos-unit-results.md); not rerun for this watch-only fix round |
| `git diff --check` | PASS |

During the earlier implementation, the first localization export discovered the
missing Replay key and therefore rewrote catalogue ordering. The catalogue was restored from the ordered Python
round-trip and Replay received fr/fr-CA translations; the final localization check
passes without any rewrite. The review follow-up adds only seven keys with
fr/fr-CA translations, preserving existing order and values; its full localization
check also made no changes. Review-follow-up logs (local):
`/tmp/task-14.3-review-l10n.log` and `/tmp/task-14.3-review-ios-build.log`.
TASK-14.5 notes explicitly track full Practice/Morse accessibility audits,
“Letter A” labels, announcing choices and VoiceOver/tone overlap; those deferred
polish items are not claimed as completed here.

Exact Apple commands (all through `xbuild`, no direct `xcodebuild`):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' test CODE_SIGNING_ALLOWED=NO
# Earlier implementation fix rounds added only the affected -only-testing selectors:
# CanadianHamWatchTests/WatchPracticeTests/testWatchBundleContainsCompleteBasicBankAndOnlyPracticeContent
# CanadianHamWatchTests/WatchMorseTests
# CanadianHamWatchUITests/WatchMorseUITests/testIndependentOutputsTextAlternativeAndSessionOnlySettings
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build-for-testing CODE_SIGNING_ALLOWED=NO
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

macOS units were run during the earlier implementation because the string
catalogue is shared; they were not repeated for this watch-only review fix round.
No shared Swift source/package changed, so `packages/morse-swift` `swift test` was
not required. No full iOS/tvOS/visionOS suites ran: app source changes belong only
to the watch target; other platforms only consume additive watch strings. Their
localization builds and iOS test compilation passed again in this round. Full platform merge-batch
suites remain coordinator-owned. Figure/title-sweep plans do not apply. No
TestFlight upload, physical-watch run or manual VoiceOver listening check was made.
