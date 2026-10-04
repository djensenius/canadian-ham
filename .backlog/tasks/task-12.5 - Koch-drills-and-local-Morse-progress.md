---
id: TASK-12.5
title: Duolingo-style Morse course (Koch method) with local progress
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-04 05:14'
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

6. Fix review blockers: restore the Apple string catalogue then append only task-specific keys; isolate Morse progress file URLs for tests/import; lock completed lesson sessions; replace stub lesson generation with seeded/shuffled Koch exercises and add resubmit/import/upgrade/UI/audit coverage; run targeted checks during iteration and one final full affected-platform suite per AGENTS.md.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented shared Morse course fixture and TS/Swift course logic using the G4FON/ISED order from docs/proposals/morse-trainer.md section 3A. Added web and Apple course path/session/review persistence and progress export/import. Validation run: pnpm typecheck (passed after pnpm install; initial root run failed before workspace bins were linked), pnpm test (passed), pnpm build:web (passed), web dist URL/CSP audit (passed), pnpm check:schemas (passed), DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/morse-swift (passed), targeted iOS xbuild CanadianHamTests/MorseTrainerTests (6 tests passed), targeted iOS xbuild CanadianHamTests/ProgressStoreTests (13 tests passed, including Morse course export/import/reset evidence), targeted iOS UI test CanadianHamPracticeUITests/testMorseSectionIsTopLevelShowsCourseAndOpensFirstLesson (passed after two selector-fix failures), pnpm check:apple-l10n (passed after fixing catalogue/localization build issues), pnpm check:apple-network (passed). Web App.test now includes the first Morse lesson flow and axe coverage; tvOS/visionOS remain the existing simplified Morse preview/home per owner decision.

Fix round started from review b68ecf00 vs base 1196c04. Reopened AC #2-#5 pending evidence for lesson depth, local progress import isolation, completed-session answer locking, and required accessibility/platform test runs.

Fix round implementation committed in d6e9061: restored the Apple string catalogue to the 1196c04 base and appended only Morse-course keys (French plurals for existing count strings verified intact; %lld days now has one/other plural variations); added seeded shared TS/Swift Koch lesson generation with 20 scored exercises; hid/disabled completed sessions and made web/Apple answers no-op after done; isolated Apple Morse progress files for in-memory stores and added separate-location export/import tests; added web older-export and IndexedDB v3→v4 tests; added Apple invalid-Morse import tests and progress reload after import; added web and Apple feedback/accessibility refinements. Validation: pnpm typecheck passed; pnpm test passed; pnpm build:web plus apps/web audit:urls passed; pnpm check:schemas passed; node scripts/check-apple-text-sources.ts passed; bash scripts/check-apple-no-network.sh passed; swift test --package-path packages/morse-swift passed; targeted iOS xbuild CanadianHamTests/MorseTrainerTests and ProgressStoreTests passed (21 tests). Apple UI/full platform runs are still pending because xbuild is currently serialized behind other long-running builds; one targeted UI iteration before final fixes failed and the subsequent retry timed out waiting for the xbuild lock.

Fix round 3: fetched origin/main until PR #123/task-12.6 appeared, merged origin/main into task-12.5-morse-course, resolved copy-exam/course conflicts, and preserved 12.6 catalogue keys. Removed stale Morse catalogue keys with the required JSON recipe and made %lld days variations-only. Wrapped iOS-only text input capitalization; added local-date Morse streak recording, learned-only distractors, TS/Swift course-exercise parity fixture, web/Apple completed-session no-op tests, deterministic Apple course UI completion, and course-session audit coverage. Validation passed: pnpm typecheck; pnpm test; pnpm --filter @canadian-ham/morse-engine test; pnpm --filter @canadian-ham/web test -- --runInBand; pnpm check:apple-l10n; node scripts/check-apple-text-sources.ts; swift test --package-path packages/morse-swift; targeted iOS UI tests testCompletesFirstMorseLessonSessionOnIOS, testAccessibilityAuditMorseCourseLessonAndSummaryLight, testAccessibilityAuditMorseCourseLessonAndSummaryDark; full iOS CanadianHam suite (49 UI tests); full macOS CanadianHam unit suite (LocalizationCatalogTests, MorseTrainerTests, ProgressStoreTests, QuestionBankTests, ReadinessAndScoringTests; 39 tests); full tvOS CanadianHamTV suite (12 UI tests); full visionOS CanadianHamVision suite (3 unit tests and 9 UI tests).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented the Morse course with task-12.6 merge compatibility and fixed review blockers: macOS-safe modifiers, catalogue cleanup, deterministic passing course UI tests/audits, learned-only distractors, shared TS/Swift exercise parity, local-date streaks, restart focus, and web/Apple completed-session resubmit no-ops. Verified with web/package checks, Apple localization/text checks, Swift package tests, targeted iOS UI tests, and full iOS/macOS/tvOS/visionOS xbuild suites.
<!-- SECTION:FINAL_SUMMARY:END -->
