# TASK-14.5 — watchOS EN/FR and accessibility

2026-10-25. Branch `task-14.5-watch-a11y`. Implementation and automated evidence,
**not a completed owner listening/hardware check**. TASK-14.5 remains In Progress;
AC4 is **Blocked: owner manual check**. No PR, upload or distribution was performed.

## Changes and carried-over review items

- Home now links to **Settings → Language → System / English / Français**.
  The selected language and Morse output preferences live in home `@State` only.
  They survive navigation but not process relaunch. Output settings remain in the
  Morse sheet; there is no second source of truth or persistent preference.
- The phone's `ProgressStore.applyInterfaceLanguagePreference` writes
  `AppleLanguages` and Native Settings explicitly requires a restart for interface
  changes. That persistence/restart mechanism is not compatible with this watch
  session-only contract and was not imported. The watch instead applies the
  selected **environment locale**, and `WatchLanguage.bundle(for:)` selects the
  actual EN/FR **lproj** for Foundation strings, announcements and Morse presets.
  A locale argument alone formats values without changing bundle lookup.
  System resolves from the app bundle's preferred localization, including French
  Canadian and fallback to supported English. The override/reset UI test starts
  in English, switches live to French, verifies real French content and explicit
  bundle lookups, switches back to English/System, then confirms relaunch resets.
- Smallest-watch testing found a real watchOS navigation-title cache issue:
  revisiting Settings in French and selecting English changed the list but left
  its localized-key title French. Settings now resolves its title explicitly with
  the selected bundle. The regression still checks the actual navigation bar.
- **French dah term: Tiret.** The existing iOS trainer uses Dash → Tiret,
  “Palette de tirets…” and “ratio point/tiret”. Retain that established app-wide
  vocabulary rather than changing all platforms to Trait in this watch task.
  The three watch haptic-style descriptions now also say **tiret**. Morse and
  reference spoken patterns both use **`, `** between symbols (for example
  `A, Alfa, Point, Tiret`), without changing international ITU words or patterns.
- The catalogue was edited through an ordered Python JSON round-trip. All prior
  key order is retained; only those three French descriptions changed, and five
  keys were appended: English, Français (language autonyms), the session note,
  Letter %@ and Answer choices available. `pnpm check:apple-l10n` passed without
  rewriting either catalogue. The existing localization checker covers watch
  membership; no new exclusion was needed.
- Morse choices and post-answer letters have **Letter A / Lettre A** labels,
  without identifying the target before submission. Completion/requesting the
  text alternative announces **Answer choices available. / Choix de réponse
  disponibles.** The requested pattern is still static and does not name the
  answer. Selected feedback now has the selected trait as well as the existing
  selected value. UI tests assert the actual trait for practice and Morse.
- When VoiceOver is enabled, Play/Replay schedules **both tone and haptics after
  a 1.5-second lead-in**, or the haptic cooldown if that is longer. There is no
  additional delay with VoiceOver off. A fake-clock unit test proves neither
  output starts early and cancellation during this delay prevents both outputs.
  This allowance addresses activation speech versus the first tone; it is **not
  a claim that every user speech-rate setting has finished**. The owner must
  listen in both languages and report any remaining overlap (checklist below).
- Crown Confirm defers its correctness announcement to the sheet's **onDismiss**,
  avoiding speech being interrupted by dismissal. Tap submission announces
  immediately. Practice source order is question/controls, textual correctness, your answer,
  correct answer, explanation, Next. Morse puts the requested/post-answer pattern
  after Play, then correctness, selected/correct letters and Next. Crown
  selection remains adjustable and never submits without Confirm; ordinary tap
  alternatives remain available. No custom focus ordering hides content.
- Question and answer strings remain verbatim official EN/FR data; their rendered
  attributed text now explicitly carries the correct speech language, including
  in the Crown sheet. English-only explanation fallback still displays
  **Explication en anglais** and its complete attributed body stays **en-CA**.
  Existing whole-bank tests verify all 984 fallbacks and translated-body fixtures.
- Native scrolling, semantic fonts and vertically wrapping answer/home labels
  support large text without shrinking, fixed row heights or hidden controls.
  The new AX walks reach all four answers, long second question, Crown Confirm,
  feedback/Next, Morse choices and both settings controls; the reference tests
  reach all 36 rows through 9. Keeper screenshots show wrapping, not ellipses,
  on the SE 3 40mm (long prose is intentionally taller than one screen and scrolls).
- There are **no app-authored ornamental animations**, animation modifiers,
  flashing beacons or animated scroll transitions in the watch source. Native
  navigation observes system accessibility settings. Reduce Motion therefore
  needs no separate app animation branch; the owner still verifies it on device.
  Existing inactivity/navigation/interruption/reset cancellation remains intact.
- The cold-load/cache probes each use a **fresh loader**, so no alphabetical test
  order or nonrandomized plan is required. The construction probe additionally
  asserts that constructing home/practice does not change the shared loader's
  count. The cold measurement means a new app loader, not a flushed OS file cache.
- The alphabet unit test now obtains Dot/Dash from real compiled EN/FR bundles for **en, fr,
  fr-CA** locales, asserts their expected translations, then checks every spoken
  row. It no longer merely passes hard-coded words into a formatter.
  `scripts/check-watch-alphabet-reference.mjs --self-test` rejects alternate
  Alfa/Juliett spellings, duplicate/missing letters and a missing lesson table;
  the pnpm test entry point runs the self-test and source parity check.

## Full default accessibility audits

`WatchAccessibilityUITests` calls **`try app.performAccessibilityAudit()`** with
**no argument mask, handler, exception, catch/return or skip**. Sixteen separate
EN/FR tests cover home, question, feedback, Morse choices before an answer, Morse
after an answer, Morse output settings sheet, alphabet reference and Settings.
Every audit launches at `UICTContentSizeCategoryAccessibilityXXXL` and keeps a
pre-audit screenshot. No existing platform audit/helper was weakened.

**Actual runtime result:** all 16 API calls returned successfully, with no reported
issues, on **watchOS 27.0** for both **Series 12 42mm** and **SE 3 40mm**. There was
no unsupported-audit error or finding needing an exception/escalation. This is
an automated API result, not evidence that VoiceOver was heard or hardware felt.
If a later runtime reports unsupported behavior or a genuine framework finding,
retain the full failing call, record the exact error/runtime here, and escalate
in the task notes; do not add a handler or skip.

The guard flags the enclosing function of the **new** audit helper. Without a PR
marker it correctly reports this finding; with the owner-authorized task marker
it exits 0. A later PR needs the following line, outside a fence in its body:

```text
Test-guard-approved: task-14
```

That approval covers these newly added full audits only, not an exception.

## Destinations, provenance and commands

All Apple builds/tests used **xbuild**, one destination per invocation. No other
build was killed. The smallest simulator was created once with `simctl create`,
then used as the sole destination for each targeted run; it was not kept booting
alongside other test destinations.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devicetypes
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl create 'TASK-14.5 Apple Watch SE 3 (40mm)' com.apple.CoreSimulator.SimDeviceType.Apple-Watch-SE-3-40mm com.apple.CoreSimulator.SimRuntime.watchOS-27-0
# Created UUID: 596608F4-525A-4BED-8642-151C0E69842D

# Full watch scheme, no test exclusions:
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' -resultBundlePath /tmp/task-14.5-evidence/watch-full.xcresult test CODE_SIGNING_ALLOWED=NO

# Series 12 fix round, only the failing tests:
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' -only-testing:CanadianHamWatchUITests/WatchAlphabetUITests -only-testing:CanadianHamWatchUITests/WatchAccessibilityUITests/testSessionLanguageOverrideUpdatesSwiftUIAndBundleLookupsAndResets -resultBundlePath /tmp/task-14.5-evidence/watch-ui-fixes.xcresult test CODE_SIGNING_ALLOWED=NO

# Smallest-watch targeted run (all new audits and AX walks, reference, practice):
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch -destination 'platform=watchOS Simulator,id=596608F4-525A-4BED-8642-151C0E69842D' -only-testing:CanadianHamWatchTests/CanadianHamWatchTests/testSessionLanguageUsesRealBundlesForLabelsFeedbackAndErrors -only-testing:CanadianHamWatchUITests/WatchAccessibilityUITests -only-testing:CanadianHamWatchUITests/WatchAlphabetUITests -only-testing:CanadianHamWatchUITests/WatchPracticeUITests -resultBundlePath /tmp/task-14.5-evidence/watch-smallest.xcresult test CODE_SIGNING_ALLOWED=NO

# Smallest-watch Settings fix round, including both affected full audits:
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch -destination 'platform=watchOS Simulator,id=596608F4-525A-4BED-8642-151C0E69842D' -only-testing:CanadianHamWatchUITests/WatchAccessibilityUITests/testSessionLanguageOverrideUpdatesSwiftUIAndBundleLookupsAndResets -only-testing:CanadianHamWatchUITests/WatchAccessibilityUITests/testEnglishSettingsAudit -only-testing:CanadianHamWatchUITests/WatchAccessibilityUITests/testFrenchSettingsAudit -resultBundlePath /tmp/task-14.5-evidence/watch-smallest-settings-fixed.xcresult test CODE_SIGNING_ALLOWED=NO
```

Local evidence root: **`/tmp/task-14.5-evidence/`**, same basename `.log` and
`.xcresult`. The initial home probe `home-probe` failed compilation because
LocalizedStringResource.bundle is get-only; its corrected `home-probe-fixed`
passed. Presets now resolve from the actual selected bundle.

- `watch-full`, commit **ff25c9fe**: **28/28 units**, **24/27 UI** passed, zero
  skips. Three UI failures were test expectation typos: Vibrations versus
  Haptique, and two omitted commas in Juliett's expected label. All 16 audits and
  both largest-text walks passed in that full run.
- `watch-ui-fixes`: all three failing UI tests passed after expectation fixes.
  This run predates b145d4f8's explicit speech-language/selected-trait additions.
- `watch-smallest`, commit **b145d4f8**: new localization unit **1/1**, UI **22/23**
  passed. The one failure was the real cached Settings title, fixed in
  **0117281388732b309b70aaa83b3580d391f8da49**. Both EN/FR walks verify the new
  selected traits; both original practice tests and both reference tests passed.
- `watch-smallest-language-fixed` and `watch-smallest-language-diagnostic` still
  failed that title assertion, establishing it was not a short wait or partial
  tap: the hierarchy showed English/Selected content under Réglages. The final
  `watch-smallest-settings-fixed` run passed **3/3**, including EN/FR Settings
  audits, after explicitly resolving the title. The positioning helper also now
  requires full visible controls when they fit, not just a hittable first edge.

Thus **all 29 watch units and all 27 UI tests have passing task evidence across
the full and targeted fix runs**, not a claim of a single all-green final full
scheme. Per the fix-round policy, unaffected tests were not rerun wholesale.
The table below records the complete full-scheme result and subsequent passes.

## Other validation

| Check | Result |
|---|---|
| `pnpm check:apple-l10n` | PASS on 01172813; French export plus tvOS/visionOS/watch builds; both catalogues unchanged |
| `node scripts/check-apple-text-sources.ts --self-test` and normal check | PASS; all watch source paths included |
| `pnpm check:apple-network` / `pnpm test:apple-network` | PASS; 98 Swift files, privacy/plist/project membership and negative fixtures |
| `pnpm check:apple-icloud-gate` / `pnpm test:apple-icloud-gate` | PASS |
| `node scripts/check-test-guard.mjs --self-test` | PASS |
| `node scripts/check-test-guard.mjs --base main --head HEAD` | Expected approval-required finding on the new full audit helper; PASS (exit 0) with `TEST_GUARD_PR_BODY='Test-guard-approved: task-14'` |
| `pnpm test:watch-alphabet-reference` | PASS; self-test and all 26 exact lesson spellings |
| `pnpm test` | Final idle run PASS: content-tools 250, Morse 21, calculator 127, web 281 plus root guards. First concurrent run had two unrelated web timing failures; unchanged rerun passed all 281. No web tests/config were changed |
| `pnpm typecheck` | PASS |
| XcodeGen twice, compare generated project | PASS, identical; directory membership includes new Settings and UI-test files; project.yml unchanged |
| Ordered Python comparison against main | PASS; previous key order intact, only three description values and five additive keys |
| `git diff --check` | PASS |
| iOS build-for-testing, iPhone 17 Pro | PASS, embedded watch compiled/validated |
| iOS `LocalizationCatalogTests` | PASS, 11/11, no skips; per-test table below |
| macOS full unit target, arm64 | PASS, 223/223, no skips; [per-test report](task-14.5-macos-unit-results.md) |

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build-for-testing CODE_SIGNING_ALLOWED=NO
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamTests/LocalizationCatalogTests -resultBundlePath /tmp/task-14.5-evidence/ios-l10n-tests.xcresult test-without-building CODE_SIGNING_ALLOWED=NO
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests -resultBundlePath /tmp/task-14.5-evidence/macos-units.xcresult test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

iOS/macOS validation used **01172813**. Nonfatal existing warnings include SDK
build-number/debugger metadata, catalogue plural substitutions, audio API
deprecations, and simulator post-test diagnostics saying simctl could not be found.
The actual tests/results were collected. Corrupt-store macOS fixtures deliberately
log CoreData errors but all unit tests passed. The web canvas warnings are existing.

No full iOS/tvOS/visionOS suite was run: app Swift changes belong only to the watch
target, shared packages and non-watch app code are unchanged. The shared catalogue
received localization builds for the other targets, iOS localization runtime tests
and the explicitly requested full macOS units. Merge-batch platform suites remain
coordinator-owned. Figure/title-sweep plans do not apply. No physical watch or
manual VoiceOver listening pass was performed by the implementation agent.

## Owner manual checks — pending, do not mark AC4 complete

Use a direct development install or the later internal TestFlight payload as
described in [TASK-14.3](task-14.3-watch-morse.md#owner-hardware-check). Do not change
release capabilities or upload a new build for this checklist. Record **date,
commit/build, installation method, watch model, watchOS version, size, language,
Dynamic Type, VoiceOver speech rate/voice, audio route, Silent Mode and haptic
strength/fit**. Where possible use the smallest supported physical watch as well
as the usual device. The simulator's passing APIs cannot substitute for hearing
VoiceOver or feeling a preset.

1. **Language and home order:** start with system English, enable VoiceOver in
   watch Settings → Accessibility (or the configured accessibility shortcut).
   Swipe through Practice, Morse, Alphabet, Settings in that order. Open Settings,
   select Français, hear the selected state, and confirm the interface changes
   immediately, including the title after revisiting Settings. Verify System,
   English and Français remain reachable at largest text. Repeat from system
   French and choose English. End by force-quitting/relaunching: System must be
   selected and no answer/output preference restored.
2. **Practice/tap and Crown:** in both languages, read a complete long official
   question and every answer, including the text beyond the first screen. Tap one
   answer and hear Correct/Incorrect only after submission. Check header/selected
   order, correct answer, explanation and Next. In French, the fallback label
   must precede the English body, and speech must switch to English for that body.
   On another question, open Select with Crown. Swipe-adjust the selected answer
   up/down and rotate the Crown across all four choices: neither submits. Touch
   scroll long text without changing selection, then Confirm. **Listen for the
   entire correctness announcement after dismissal**, not just its first syllable.
   Check the close/cancel path never announces a submission.
3. **Morse/VoiceOver and sound:** before first Play, inspect the available elements:
   no target letter or pattern. Enable tone in Output settings and return. Hear
   Play/Replay activation speech, then the first tone **after** it; test slow and
   fast speech rates in EN/FR and report if the 1.5 s lead-in is insufficient. Stop
   moving focus during playback when checking this overlap. After playback, hear
   “Answer choices available” and reach all four **Letter A**-style choices.
   Submit, hear textual correctness, selected letter and correct letter, then the
   static dot/dash pattern in the chosen language. Replay keeps the same character;
   Next clears feedback. With both outputs off, request the text pattern and
   complete the round with no sound/haptic input. There must be no flashing light
   or animation conveying essential information.
4. **Alphabet:** read A/Alfa, J/Juliett, Z/Zulu and digits 0–9. Spoken symbols must
   pause between Dot/Dash or Point/Tiret words. Verify the whole phonetic word and
   pattern are reachable at largest text; no early/lost characters, ellipses or
   shrinking. Use tap/scroll and Crown paths back to home.
5. **Reduce Motion:** turn it on in watch system Accessibility settings, repeat
   home navigation, question → Crown → feedback, Morse/Replay/Next and reference.
   Confirm there is no app-authored ornamental motion or flashing alternative;
   native transitions must remain comfortable. Return to the prior preference
   afterwards. Record the actual observed device/OS result rather than “no code
   animation found”.
6. **Physical output and cancellation:** run all three style comparisons and
   speeds/representative letters from the detailed TASK-14.3 hardware checklist.
   Record touch-only recognition, preset sounds with tone off/Silent Mode on/off,
   tone route and combined alignment. During playback and during the 1.5 s speech
   lead-in, navigate back, change settings/Next, lower the wrist, and induce an
   actual audio interruption. No pending output may continue; an already-issued
   fixed WatchKit preset may finish. Escalate any unreliable symbol distinction,
   collapsed presets, remaining speech overlap or output continuing offscreen.

| Owner observation | Device / OS / configuration | Result / reproduction |
|---|---|---|
| EN/FR VoiceOver order, labels, choices and selected state | Pending owner | Not performed |
| Crown correctness announcement survives dismissal | Pending owner | Not performed |
| Play/Replay speech versus first tone, EN/FR speech rates | Pending owner | Not performed |
| Long official text, English fallback voice, smallest physical layout | Pending owner | Not performed |
| Reduce Motion, no flashing requirement | Pending owner | Not performed |
| Physical haptic styles, sound, cancellation and alignment | Pending owner; also TASK-14.3 AC2 | Not performed |

**AC4 remains unchecked and the task remains In Progress until the owner records
these observations.** Automated structure, screenshots and audit success are not
reported as a manual listening pass.

## Watch per-test results

Full = Series 12 `watch-full` at ff25c9fe. Follow-up = the latest passing targeted run for that test; `watch-smallest*` is SE 3 40mm. No tests were skipped.

| Test | Full result (seconds) | Passing follow-up (seconds) |
|---|---|---|
| `CanadianHamWatchTests.testIndependentOfflineBundle` | PASSED (0.003) | — |
| `CanadianHamWatchTests.testPlannedSections` | PASSED (0.001) | — |
| `CanadianHamWatchTests.testSharedPackagesOnWatch` | PASSED (0.003) | — |
| `WatchAlphabetReferenceTests.testAllDigitsMatchSharedMorseTableWithoutPhonetics` | PASSED (0.001) | — |
| `WatchAlphabetReferenceTests.testAllLettersMatchL00201PhoneticsAndSharedMorseTable` | PASSED (0.001) | — |
| `WatchAlphabetReferenceTests.testSpokenPatternsUseLocalizedWordsAndKeepInternationalPhonetics` | PASSED (0.003) | — |
| `WatchMorseTests.testCancelBeforeStartAndMidSequenceInvalidatesEvenStaleCallbacks` | PASSED (0.002) | — |
| `WatchMorseTests.testDelayedSchedulerDoesNotCollapsePresets` | PASSED (0.001) | — |
| `WatchMorseTests.testFourDistinctSeededChoicesGradingAndNextReset` | PASSED (0.033) | — |
| `WatchMorseTests.testHapticSpacingSurvivesLeavingAndReenteringMorse` | PASSED (0.001) | — |
| `WatchMorseTests.testHapticStylesMapEveryPairAndReachOutput` | PASSED (0.002) | — |
| `WatchMorseTests.testLocalToneDriverRendersOffMainActorAndRestartsAfterStop` | PASSED (0.448) | — |
| `WatchMorseTests.testNextCancelsAndPreservesPresetCooldown` | PASSED (0.001) | — |
| `WatchMorseTests.testOnlyBeganAudioInterruptionCancelsPlayback` | PASSED (0.001) | — |
| `WatchMorseTests.testOutputsAreIndependentOffDoesNotStartAndToneFailureStops` | PASSED (0.005) | — |
| `WatchMorseTests.testReplayCannotOverlapAndCompletedReplayUsesSameSequence` | PASSED (0.001) | — |
| `WatchMorseTests.testSpeedClampsAndAllLettersRespectCadenceFloor` | PASSED (0.002) | — |
| `WatchMorseTests.testTimingFixturesMapToWatchPresetsAndToneSegments` | PASSED (0.006) | — |
| `WatchMorseTests.testVoiceOverStartDelayAppliesToBothOutputsAndCanBeCancelled` | PASSED (0.001) | — |
| `WatchPracticeTests.testAColdBundledPracticeLoadMeasurements` | PASSED (0.332) | — |
| `WatchPracticeTests.testDistractorNotesFollowDisplayedOrderWithOfficialChoiceText` | PASSED (0.315) | — |
| `WatchPracticeTests.testEmptyLoadErrorAndMissingResourcesFailSafely` | PASSED (0.002) | — |
| `WatchPracticeTests.testFrenchExplanationFallbackHasEnglishAccessibilityLanguage` | PASSED (0.305) | — |
| `WatchPracticeTests.testMeasureBundledPracticeLoad` | PASSED (0.175) | — |
| `WatchPracticeTests.testNewSessionRestoresNeitherAnswerNorQuestionSequence` | PASSED (0.148) | — |
| `WatchPracticeTests.testRenderedExplanationsNeverExposeAuthoringLabels` | PASSED (0.422) | — |
| `WatchPracticeTests.testSeededShuffleGradesSourceIndexNotDisplayPositionAndLocksSubmission` | PASSED (0.160) | — |
| `WatchPracticeTests.testWatchBundleContainsCompleteBasicBankAndOnlyPracticeContent` | PASSED (0.158) | — |
| `CanadianHamWatchUITests.testLaunchAndNavigateEnglish` | PASSED (16.117) | — |
| `CanadianHamWatchUITests.testLaunchAndNavigateFrench` | PASSED (19.201) | — |
| `WatchAccessibilityUITests.testEnglishHomeAudit` | PASSED (5.266) | `watch-smallest` PASS (4.677) |
| `WatchAccessibilityUITests.testEnglishLargestTextControlsAndLongQuestion` | PASSED (76.565) | `watch-smallest` PASS (69.023) |
| `WatchAccessibilityUITests.testEnglishMorseAfterAnswerAudit` | PASSED (14.119) | `watch-smallest` PASS (13.112) |
| `WatchAccessibilityUITests.testEnglishMorseBeforeAnswerAudit` | PASSED (12.648) | `watch-smallest` PASS (12.526) |
| `WatchAccessibilityUITests.testEnglishMorseSettingsAudit` | PASSED (11.570) | `watch-smallest` PASS (10.348) |
| `WatchAccessibilityUITests.testEnglishPracticeFeedbackAudit` | PASSED (8.505) | `watch-smallest` PASS (8.572) |
| `WatchAccessibilityUITests.testEnglishPracticeQuestionAudit` | PASSED (6.997) | `watch-smallest` PASS (7.103) |
| `WatchAccessibilityUITests.testEnglishReferenceAudit` | PASSED (5.944) | `watch-smallest` PASS (6.062) |
| `WatchAccessibilityUITests.testEnglishSettingsAudit` | PASSED (7.152) | `watch-smallest-settings-fixed` PASS (9.359) |
| `WatchAccessibilityUITests.testFrenchHomeAudit` | PASSED (5.256) | `watch-smallest` PASS (5.306) |
| `WatchAccessibilityUITests.testFrenchLargestTextControlsAndLongQuestion` | PASSED (69.013) | `watch-smallest` PASS (79.536) |
| `WatchAccessibilityUITests.testFrenchMorseAfterAnswerAudit` | PASSED (13.358) | `watch-smallest` PASS (14.295) |
| `WatchAccessibilityUITests.testFrenchMorseBeforeAnswerAudit` | PASSED (12.593) | `watch-smallest` PASS (12.620) |
| `WatchAccessibilityUITests.testFrenchMorseSettingsAudit` | PASSED (10.272) | `watch-smallest` PASS (11.433) |
| `WatchAccessibilityUITests.testFrenchPracticeFeedbackAudit` | PASSED (9.565) | `watch-smallest` PASS (9.695) |
| `WatchAccessibilityUITests.testFrenchPracticeQuestionAudit` | PASSED (7.006) | `watch-smallest` PASS (7.023) |
| `WatchAccessibilityUITests.testFrenchReferenceAudit` | PASSED (5.934) | `watch-smallest` PASS (5.992) |
| `WatchAccessibilityUITests.testFrenchSettingsAudit` | PASSED (6.956) | `watch-smallest-settings-fixed` PASS (8.288) |
| `WatchAccessibilityUITests.testSessionLanguageOverrideUpdatesSwiftUIAndBundleLookupsAndResets` | FAILED (23.453) | `watch-smallest-settings-fixed` PASS (68.787) |
| `WatchAlphabetUITests.testEnglishReferenceScrollsToNineAndBack` | FAILED (19.122) | `watch-smallest` PASS (61.523) |
| `WatchAlphabetUITests.testFrenchReferenceAtLargeDynamicTypeScrollsToNineAndBack` | FAILED (25.447) | `watch-smallest` PASS (87.086) |
| `WatchMorseUITests.testIndependentOutputsTextAlternativeAndSessionOnlySettings` | PASSED (135.471) | — |
| `WatchMorseUITests.testPlayReplayAnswerNextAndNoEarlyReveal` | PASSED (49.427) | — |
| `WatchPracticeUITests.testCrownSelectionRequiresConfirmAndFrenchFeedbackLabelsEnglishFallback` | PASSED (53.985) | `watch-smallest` PASS (53.450) |
| `WatchPracticeUITests.testTapFeedbackNextAndRelaunchDoesNotRestoreAnswer` | PASSED (32.427) | `watch-smallest` PASS (37.930) |
| `CanadianHamWatchTests.testSessionLanguageUsesRealBundlesForLabelsFeedbackAndErrors` | Added after full run | `watch-smallest` PASS (0.005) |

## iOS localization per-test results

`ios-l10n-tests`, iPhone 17 Pro, implementation 01172813. All 11 passed.

| Test | Result | Seconds |
|---|---|---:|
| `LocalizationCatalogTests.testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata` | PASSED | 0.007 |
| `LocalizationCatalogTests.testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection` | PASSED | 0.001 |
| `LocalizationCatalogTests.testConceptCheckAnswerStatusMapsShuffledSourceChoices` | PASSED | 0.002 |
| `LocalizationCatalogTests.testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext` | PASSED | 0.001 |
| `LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations` | PASSED | 0.007 |
| `LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` | PASSED | 0.012 |
| `LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides` | PASSED | 0.001 |
| `LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish` | PASSED | 0.001 |
| `LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale` | PASSED | 0.004 |
| `LocalizationCatalogTests.testReviewHeadingMarksEnglishFallbackTitleInsideFrenchText` | PASSED | 0.002 |
| `LocalizationCatalogTests.testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench` | PASSED | 0.001 |
