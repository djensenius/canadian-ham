# watchOS companion

**TASK-14 · 2026-10-25 · Proposal, not an implementation.** Owner decision on
2026-10-25: **yes, build it** ("go ahead and get started on watch"). Recommend a
small, independently usable watchOS 27 app; implementation belongs to TASK-14's
subtasks. Keep the coordinator's four use cases, with the hardware caveat below.

## Wrist-sized v1

- **Quick practice:** one random Basic question, four shuffled answers. Turn the
  Digital Crown to select, then explicitly confirm, or tap an answer. Crown
  scrolling must not accidentally submit. Immediately show correct/incorrect,
  the correct answer and the existing explanation in a scrollable feedback view;
  Next starts another question. No hints or saved scores. Follow tvOS's in-memory
  session model, not its full lesson/hint UI.
- **Morse on the wrist:** play one A–Z character as WatchKit `WKHapticType`
  patterns, optionally with locally generated tones; pick the letter from four
  choices, get feedback, replay or advance. Reuse `morse-swift`'s
  `textToTimedMorse` / `TimedMorseSequence`, not a second timing algorithm.
  WatchKit supplies fixed haptic presets, **not arbitrary-duration pulses**:
  validate a distinguishable dot/dash mapping and achievable cadence on hardware
  before claiming timing fidelity. Haptic practice is not an ISED exam simulator.
- **Alphabet reference:** a scrollable A–Z phonetic/Morse list plus Morse digits
  0–9. Use the phonetic spellings already in
  [L-002-01](../../content/lessons/m2-operating-procedures/l-002-01-voice-repeater-and-simplex-procedure.md)
  and the shared Morse character map. No lesson navigation.
- **EN/FR interface:** follow system language; a Settings override changes the
  current session. Official questions/answers are bilingual and stay verbatim.
  All 984 existing explanations currently have English bodies only: clearly label
  the English fallback in French and give it the English VoiceOver language.
  Translating the bank's explanations is not part of this watch implementation.

**Explicitly out of v1:** progress sync (needs durable identity, reconciliation
and data-transfer policy); app-level iPhone pairing (adds setup and companion
state); WatchConnectivity (cross-device transfer violates this deliberately
self-contained boundary); data-bearing complications (background refresh and
stale-data/state handling); mock exams (long timed sessions and review on a tiny
screen); lessons (long-form navigation, figures and a much larger resource/UI
surface). None is needed for these short offline interactions. OS watch setup
and App Store installation are not app-level pairing features.

## Bundled data and reuse

**Recommend the full Basic bank**, not a maintained subset. Measured from this
checkout on 2026-10-25, using file byte counts, excluding authoring READMEs:

| Resource | Raw bytes |
|---|---:|
| `content/generated/basic-2025-07-15/questions.json` (984 questions, EN/FR) | 1,259,626 |
| `categories.json`, `subsections.json`, `manifest.json` in that directory | 48,992 |
| `content/explanations/**/*.json` (984 files) | 1,052,351 |
| **Total** | **2,360,969 (2.25 MiB)** |

This is small enough to avoid a divergent subset/manifest; measure installed size,
decode time and memory in the skeleton/practice tasks. Exclude Advanced, hints,
lessons, quizzes and figures. Use `content-swift`'s Codable question/explanation
models and `ExplanationBodyParser`, and `engine-swift`'s seeded shuffle while
preserving answer `sourceIndex` for grading. The existing `ContentLibrary.load`
also validates lessons/modules; **do not bundle lessons just to satisfy it**.
A narrow bundled-data loader can decode the existing models without that loader.

All three package manifests currently declare iOS/macOS/tvOS/visionOS 27 but
**not watchOS**; their sources use Foundation (content also uses `os`). Explicit
watchOS 27 support and simulator compilation/tests are the first gate, not an
assumed compatibility claim. Use a watch-specific output adapter: the current
`MorseHapticDriver` is iOS Core Haptics, not WatchKit.

Keep question, shuffled choices, selection, feedback and Morse playback state in
memory. Settings also remain in memory for v1 (language/output/speed); relaunch
uses defaults/system language. No SwiftData, files, UserDefaults, App Groups,
export, device identifiers or progress store.

## Offline, data-free and accessible

Everything needed ships in the app. No networking frameworks/code (including
Network, URLSession or WebKit), remote SDKs, analytics, accounts, microphone,
HealthKit, WatchConnectivity, push or iCloud. Existing optional iCloud code stays
confined to `DebugCloudKit`; the watch links none of it, even in that configuration.
Default Debug/Release must have no cloud/push entitlements or background network
modes. Bundle a privacy manifest with no tracking/collected data; extend the
[privacy evidence](../release/privacy-label-evidence.md) and keep App Privacy
**Data Not Collected**. Run the network/iCloud guards on future watch changes.

Use native scrollable controls and semantic fonts: VoiceOver labels include
answer text, selection and feedback, with no colour-only correctness. Support
Dynamic Type without shrinking/truncating official text, sensible focus order,
and tap alternatives to Crown selection. Haptics and tones are independently
optional; a non-flashing dot/dash text alternative makes Morse usable without
either. Reduce Motion removes ornamental animation; no flashing beacon. Replay
must not speak/reveal the answer prematurely. Cancel output on exit/inactivity;
no workout, location or extended background sessions to keep playback alive.

## Build, test and release gates

Add XcodeGen target/scheme **`CanadianHamWatch`**, watchOS 27, watch-specific
sources/resources, unit and UI test targets; regenerate the committed project
twice and check determinism. Recommend bundle ID
`org.davidjensenius.CanadianHam.watchkitapp`, display name **Canadian Ham**, and a
watch-sized circular-safe AppIcon derived from the existing icon family. Validate
signing/embedding constraints in the skeleton; don't reuse the phone bundle ID.

**Simulator check:** `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcrun simctl list runtimes` confirms watchOS 27.0 installed (24R5355a and 24R362);
a Series 12 (42mm) device is available. Future targeted runs, one destination:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' \
  test CODE_SIGNING_ALLOWED=NO
```

Test bundled data integrity, shuffled grading, in-memory reset, Morse scheduling
and cancellation; UI-test Crown/tap, feedback, replay and reference in EN/FR at
large text sizes. The installed WatchSimulator XCUIAutomation header declares
`performAccessibilityAudit` available from watchOS 10: run full audits on supported
screens, recording actual tool/runtime limits rather than silently skipping them.
Manually check VoiceOver, smallest supported watch layout and haptic/optional-tone
recognisability on hardware; the simulator cannot establish tactile fidelity.
No Apple suites were run for this proposal-only change.

**Distribution recommendation:** independent operation
(`WKRunsIndependentlyOfCompanionApp`), with the watch app embedded in the existing
iOS distribution container. No phone app or app-level pairing is required to use
its features. The existing `fastlane ios beta` must archive/export that container
with the watch payload and matching timestamp build numbers; an explicit watch
beta entry point may delegate to this path, not invent a separate ASC watchOS
platform upload. Keep `CanadianHamWatch` for watch build/test. TASK-14.6 validates
packaging, dedicated-keychain signing, icon and installed offline behaviour;
update the [TestFlight runbook](../release/testflight.md). Internal team-member
TestFlight only; no external groups, public links or App Store submission before
TASK-1.7/licensing gates. No upload in this lane.

## Risks and delivery

Primary risks are package API/platform compatibility, installed-bank memory/startup
cost (raw size is not runtime memory), long French SwiftUI watch layouts, fixed
haptic presets/cadence, and iOS-container signing/TestFlight packaging. If haptics
cannot distinguish characters reliably, escalate the measured result rather than
silently replace the promised use case. Deliver in order: **TASK-14.1** target and
packages → **14.2** quick practice → **14.3** Morse haptics → **14.4** alphabet
reference → **14.5** EN/FR and accessibility → **14.6** TestFlight lane and icon.
TASK-14 closes the proposal/owner decision only, not the app build.
