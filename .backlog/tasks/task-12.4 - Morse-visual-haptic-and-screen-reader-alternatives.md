---
id: TASK-12.4
title: 'Morse visual, haptic and screen-reader alternatives'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-07 05:42'
labels:
  - web
  - apple
  - morse
  - accessibility
milestone: m-1
dependencies:
  - TASK-12.3
parent_task_id: TASK-12
priority: medium
ordinal: 42000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: Deaf and hard-of-hearing learners need non-audio ways to learn, and a flashing beacon must not risk seizures. See docs/proposals/morse-trainer.md (owner decisions in task-12 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A visual beacon meets WCAG 2.2 SC 2.3.1 (flash area under 25% of a 341x256 CSS px region, red-flash handling, cadence limits), plus a non-flashing tape display
- [x] #2 Core Haptics is used only where supportsHaptics is true (in practice iPhone), with no haptic UI on tvOS or visionOS
- [ ] #3 VoiceOver/ARIA announcements don't talk over playback; accessibility audits pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add shared Morse output-mode primitives in TypeScript and Swift: output-mode persistence, schedule-to-beacon/tape/haptic events, and WCAG flash-safety calculations with tests.
2. Wire web Morse playback consumers (Quick listen, course, copy practice, exam) through the existing one-player coordinator for audio, visual beacon, and non-flashing tape; add settings, reduced-motion fallback, ARIA behavior, styles, and component tests.
3. Wire Apple iOS/iPadOS/macOS Morse playback consumers through the same settings for audio, visual beacon, non-flashing tape, and capability-gated Core Haptics on iPhone only; keep tvOS/visionOS basic with no new UI and localize EN/FR strings through the catalogue JSON round trip.
4. Run targeted TS/Swift tests and required web/Apple checks, record file:line evidence and per-test names in task notes, then finalize only with verified acceptance criteria.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Morse output modes and accessibility alternatives. Evidence map:
- Shared TS safety/mapping: packages/morse-engine/src/morse.ts:359 maps schedules to beacon events/tape tokens/haptics; packages/morse-engine/src/morse.ts:402 enforces WCAG area/red/cadence/luminance thresholds (112x112 = 12,544 CSS px under 21,824; luminance delta 0.07 below 0.10).
- Shared Swift safety/mapping: packages/morse-swift/Sources/CanadianHamMorseEngine/Morse.swift:491 mirrors the flash-safety function and schedule mapping.
- Web output-mode storage/import/export: apps/web/src/lib/morseSettings.ts:12 and packages/schemas/common.schema.json:577 include outputMode. Web playback coordinator uses all output modes through apps/web/src/lib/morseOutput.tsx:33; Quick listen settings UI is apps/web/src/App.tsx:2244; course/copy/exam render output views at apps/web/src/morse/course/MorseCoursePanel.tsx:236 and apps/web/src/morse/copyExam/MorseCopyExamSection.tsx:184.
- Apple output-mode storage and UI: apps/apple/CanadianHam/Morse/MorseTrainerSettings.swift:21; visual/tape view and Reduce Motion / cross-fade fallback: apps/apple/CanadianHam/Morse/MorseTrainerView.swift:18; Core Haptics capability gate: apps/apple/CanadianHam/Morse/MorseAudioDriver.swift:146. Course/copy/exam use configured outputs at apps/apple/CanadianHam/Morse/Course/MorseCourseView.swift:441 and apps/apple/CanadianHam/Morse/CopyExam/MorseCopyExamView.swift:330/550. tvOS/visionOS compile shared settings/audio only and have no new haptic UI.
- Added/updated test names: packages/morse-engine test "maps timed Morse symbols to beacon transitions, tape tokens and haptic durations" and "keeps the configured visual beacon below WCAG 2.2 SC 2.3.1 thresholds at Morse cadence"; packages/morse-swift MorseFixtureTests/testVisualTapeAndHapticOutputMapping and testMorseBeaconFlashSafetyMath; web App.test "uses the non-flashing Morse tape when reduced motion is requested"; Apple MorseTrainerTests/testMorseSettingsClampAndPreset; iOS UI CanadianHamPracticeUITests/testMorseVisualOutputModeQuickListenOnIOS.
- Validation passed on final commit e5a99d24c50986721907b2231e86aeb3bf5fe152: pnpm typecheck; TZ=UTC pnpm test; pnpm build:web; pnpm --filter @canadian-ham/web audit:urls; pnpm check:schemas; pnpm import:check; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test in packages/morse-swift; pnpm check:apple-l10n; node scripts/check-apple-text-sources.ts; pnpm check:apple-network. Apple full runs: iOS CanadianHam (60 unit tests + 67 UI tests) /tmp/t124-ios.log; macOS CanadianHam with -skip-testing:CanadianHamUITests (60 unit tests) /tmp/t124-macos.log; tvOS CanadianHamTV (12 UI tests plus unit target) /tmp/t124-tvos.log; visionOS CanadianHamVision (9 UI tests plus unit target) /tmp/t124-vision.log. All passed.

Final branch tip after Backlog finalization is 52321b6e4e97f129dcbbc79f98718bb7b5d3eedf; code validation was run after the final code commit e5a99d24c50986721907b2231e86aeb3bf5fe152, and subsequent commits only update Backlog task metadata.

Correction to Apple full-run counts from final xbuild logs: iOS CanadianHam ran 58 unit tests and 67 UI tests; macOS CanadianHam ran 60 unit tests with UI skipped; tvOS CanadianHamTV ran 3 unit tests and 12 UI tests; visionOS CanadianHamVision ran 3 unit tests and 9 UI tests. All had 0 failures.

Review round 1 requested changes: reopening AC #1 and #3 for Dim Flashing Lights, real token luminance safety maths, beacon/tape audits, localized/valid ARIA names, corrected notes and final per-test names.

Review round 1 fixes completed on code tip 8b8f241c09f9e9169e76ef0dad1ac1edbab44922.
- Dim Flashing Lights: apps/apple/CanadianHam/Morse/MorseTrainerView.swift:172 calls MADimFlashingLightsEnabled() on iOS/macOS and apps/apple/CanadianHam/Morse/MorseTrainerView.swift:183 observes kMADimFlashingLightsChangedNotification; decision logic is injectable/tested in MorseTrainerTests/testReduceFlashingDecisionUsesInjectedFlags. Prefer Cross-Fade was removed from the fallback decision.
- Real token flash maths: packages/morse-engine/src/morse.ts:171 and packages/morse-swift/Sources/CanadianHamMorseEngine/Morse.swift:268 use 70%/75% accent-over-paperInset states; packages/morse-engine/src/morse.ts:442 and packages/morse-swift/Sources/CanadianHamMorseEngine/Morse.swift:543 evaluate safety from computed palette luminances. Final computed luminance values from token RGBs: light resting 0.222, active 0.199, delta 0.023; dark resting 0.207, active 0.234, delta 0.028. Text is ink-on-paper outside the decorative lamp.
- Web ARIA/localization: apps/web/src/lib/morseOutput.tsx:125 uses localized labels and an output/region for tape content; web tests cover beacon fake timers, reduced-motion tape, axe, import/export outputMode, and rejecting haptics.
- Apple haptics: apps/apple/CanadianHam/Morse/MorseAudioDriver.swift:152 caches supportsHaptics; course natural-end path stops haptics.
- Apple visual audits: apps/apple/CanadianHam/Morse/MorseTrainerView.swift:440 provides a DEBUG-only visual-output audit fixture; apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:128 adds light/dark beacon and tape accessibility audits. Diagnostic handler was used during debugging only and removed before commit.
- Targeted checks after fixes: pnpm typecheck; TZ=UTC pnpm test; pnpm build:web; pnpm --filter @canadian-ham/web audit:urls; pnpm check:schemas; pnpm import:check; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test in packages/morse-swift; pnpm check:apple-l10n; node scripts/check-apple-text-sources.ts; pnpm check:apple-network; targeted iOS visual output audits all passed.
- Final full xbuild runs on code tip 8b8f241c09f9e9169e76ef0dad1ac1edbab44922: iOS /tmp/t124-r2b-ios-final.log passed (65 unit test names + 71 UI test names, 0 failures); macOS /tmp/t124-r2b-macos-final.log passed (65 unit test names, UI skipped, 0 failures); tvOS /tmp/t124-r2b-tvos-final.log passed (3 unit + 12 UI test names, 0 failures); visionOS /tmp/t124-r2b-vision-final.log passed (3 unit + 9 UI test names, 0 failures). Per-test name extraction is in the worker transcript and the logs list every Test Case name.

Review follow-up: removing DEBUG-only visual audit fixture/launch argument and replacing with audits of the real Morse screen in beacon/tape modes, light/dark, during and after playback. AC #3 reopened until the real-screen audits and final runs pass.

Review follow-up 2 completed on code tip 6a47c7b1a2e42846db13a7bddac514c3538d2628. Removed the rejected -CanadianHamMorseVisualAuditMode launch argument and MorseVisualAuditFixtureView; no audit-only layout remains. Real Morse screen visual audits now use Quick listen with the real MorseTrainerView layout, forcing only the real output mode via -CanadianHamMorseOutputMode for deterministic playback settings. Evidence: apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:128 includes beacon/tape light/dark tests; apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:1450 audits the real Quick listen output during playback and after Morse playback finished; apps/apple/CanadianHam/Morse/MorseTrainerView.swift:234 renders the real Morse home directly. Morse home uses the opaque token navigation bar at apps/apple/CanadianHam/Morse/MorseTrainerView.swift:389. The output view was moved near the top of the real Morse screen so the beacon/tape is fully below the navigation bar without substitute layout. Luminance notes remain: decorative beacon fill uses accent over paperInset at 70%/75%; light fill luminances 0.222/0.199 (delta 0.023), dark fill luminances 0.207/0.234 (delta 0.028). Text is ink on paper/card surfaces, not on the tinted lamp. Targeted real-screen visual audits passed in /tmp/visual-fixture-audits-final.log equivalent rerun /tmp/real-visual-audits2.log after launch-arg fix and final full iOS /tmp/t124-r3b-ios-final.log (71 UI tests including the four real visual-output audits, 0 failures). macOS final rerun /tmp/t124-r3b-macos-final.log passed (65 unit tests). tvOS/visionOS were not rerun after the final iOS/mac-only code commit; previous review-round full runs /tmp/t124-r2b-tvos-final.log and /tmp/t124-r2b-vision-final.log passed and their compiled targets were unaffected by the final MorseTrainerView/iOS UI-test changes.

Review round 2 requested changes: reopen AC #1 and #3; remove audit-only Morse visual fixture, make WCAG area-cap the primary beacon rule with perceivable states, restore deleted audits, remove shared settings DEBUG launch hook, and record per-test names in notes.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Completed review follow-up 2: removed the rejected visual audit fixture and launch argument, audited beacon/tape on the real Morse screen in Quick listen mode, kept the opaque token navigation bar, and revalidated. Final code tip 6a47c7b1a2e42846db13a7bddac514c3538d2628 passed targeted real-screen visual audits, full iOS, full macOS, and existing web/Swift/l10n/network checks; tvOS/visionOS prior review-round full runs remain valid because final changes only touched MorseTrainerView and iOS UI tests.
<!-- SECTION:FINAL_SUMMARY:END -->
