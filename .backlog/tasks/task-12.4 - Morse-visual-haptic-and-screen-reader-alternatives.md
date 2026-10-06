---
id: TASK-12.4
title: 'Morse visual, haptic and screen-reader alternatives'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-06 20:26'
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
- [x] #1 A visual beacon meets WCAG 2.2 SC 2.3.1 (flash area under 25% of a 341x256 CSS px region, red-flash handling, cadence limits), plus a non-flashing tape display
- [x] #2 Core Haptics is used only where supportsHaptics is true (in practice iPhone), with no haptic UI on tvOS or visionOS
- [x] #3 VoiceOver/ARIA announcements don't talk over playback; accessibility audits pass
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
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented Morse output modes for audio, WCAG-bounded low-contrast visual beacon, non-flashing tape, and Core Haptics where supported. Settings persist/export/import outputMode on web and Apple; web and iOS/iPadOS/macOS Quick listen, course, copy practice, and receiving exam now share one coordinator across output modes; tvOS/visionOS received no new output UI. Verified with TS/Swift unit tests, web component/reduced-motion coverage, Apple unit and iOS UI tests, l10n/text/network gates, and final full iOS/macOS/tvOS/visionOS xbuild runs.
<!-- SECTION:FINAL_SUMMARY:END -->
