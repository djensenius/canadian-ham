---
id: TASK-12.5
title: Duolingo-style Morse course (Koch method) with local progress
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-04 00:08'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.12
parent_task_id: TASK-12
priority: medium
ordinal: 43000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner wants formal, Duolingo-like training where you really learn Morse by ear (2026-10-02 decision in task-12), not just a player. The Koch method with Farnsworth spacing is the proven approach (docs/proposals/morse-trainer.md); progress must stay on-device.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A course path of 40 Koch lessons (G4FON order adapted to the ISED character set) grouped into units, shown as a visual path with locked, current and completed lessons; each lesson introduces 1-2 new characters and unlocks the next at 90% accuracy
- [x] #2 Lessons are short sessions mixing exercise types: meet the character (hear it, see its dits and dahs), listen and choose from options, listen and type single characters, and listen and type 5-character groups at Farnsworth speed, with instant feedback and a lesson summary
- [x] #3 A review session practises the weakest characters (by recent accuracy) and a local daily streak and lesson count encourage regular practice, with no accounts, notifications or network
- [x] #4 Per-character mastery and course progress are stored locally (IndexedDB on web, the Apple progress store) and included in progress export/import with schema and shared TS/Swift fixture updates
- [x] #5 Fully accessible: keyboard and VoiceOver/screen-reader operable, announcements don't talk over audio, Reduce Motion respected, French UI; web axe and Apple light/dark audits pass on web, iOS/iPadOS, macOS (unit) , tvOS and visionOS (tvOS/visionOS may offer a simplified lesson flow)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect existing Morse web/Apple entry points, settings/audio/progress stores, schemas and shared fixture/package patterns.\n2. Add a shared Morse course fixture (40 Koch lessons/units) and TS/Swift loaders with parity and unlock/weakest-character tests.\n3. Implement local course progress persistence and export/import schema compatibility on web and Apple.\n4. Add accessible course path, lesson and review flows using existing Morse audio/settings; wire from the Morse home with minimal touches.\n5. Add targeted web, Swift and UI tests, run required checks, update task notes/ACs/final summary, and commit logical changes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented shared Morse course fixture and TS/Swift course logic using the G4FON/ISED order from docs/proposals/morse-trainer.md section 3A. Added web and Apple course path/session/review persistence and progress export/import. Validation run: pnpm typecheck (passed after pnpm install; initial root run failed before workspace bins were linked), pnpm test (passed), pnpm build:web (passed), web dist URL/CSP audit (passed), pnpm check:schemas (passed), DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/morse-swift (passed), targeted iOS xbuild CanadianHamTests/MorseTrainerTests (6 tests passed), targeted iOS xbuild CanadianHamTests/ProgressStoreTests (13 tests passed, including Morse course export/import/reset evidence), targeted iOS UI test CanadianHamPracticeUITests/testMorseSectionIsTopLevelShowsCourseAndOpensFirstLesson (passed after two selector-fix failures), pnpm check:apple-l10n (passed after fixing catalogue/localization build issues), pnpm check:apple-network (passed). Web App.test now includes the first Morse lesson flow and axe coverage; tvOS/visionOS remain the existing simplified Morse preview/home per owner decision.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented a shared 40-lesson Koch Morse course with local progress on web and Apple. Added fixtures/morse/course.json, TS/Swift course logic/tests, web course path/session/review UI using WebMorsePlayer, Apple course path/session/review UI using MorseAudioDriver, and progress export/import schema/store support. Verified with TS/web/schema/Swift package tests, targeted iOS unit/UI tests, web build URL audit, Apple localization/network checks, and XcodeGen regeneration.
<!-- SECTION:FINAL_SUMMARY:END -->
