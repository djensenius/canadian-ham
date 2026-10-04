---
id: TASK-12.6
title: Morse copy practice and simulated Canadian 5 wpm exam
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-04 01:32'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.12
parent_task_id: TASK-12
priority: medium
ordinal: 44000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: learners need to listen to whole passages and type what they hear, and candidates need practice in the real ISED format: 3 minutes of uninterrupted copy, a 2-minute review, and the RIC-1/RIC-3 pass rule (owner decision 2026-10-02 in task-12). See docs/proposals/morse-trainer.md.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The text generator follows RIC-1 section 8.2 (at least 75 weighted characters and 180 s for the chosen profile); the default profile is isedParis 12/5 with ric1Literal as a harder option
- [x] #2 Playback is uninterrupted, followed by a 2-minute review; grading is 5 or fewer errors = pass (100%), otherwise fail, with a diff view
- [ ] #3 Web and Apple tests cover generation, timing and grading with the shared fixtures
- [ ] #4 Copy practice: listen to a full passage (plain-language sentences or QSO-style text) at the user's settings, type it, and see a character-level diff with wrong, missing and inserted characters highlighted, accessible to screen readers
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add shared Morse copy/exam generation and diff support to packages/morse-engine and packages/morse-swift with shared fixtures for timing/weighted constraints.\n2. Add web copy-practice and simulated-exam UI in new apps/web/src/morse/copyExam files, wiring only the Morse home placeholders and using the existing WebMorsePlayer/settings.\n3. Add Apple iOS/macOS copy-practice and exam views in new apps/apple/CanadianHam/Morse/CopyExam files, using the existing MorseAudioDriver/settings with DEBUG launch-argument timing overrides for UI tests.\n4. Add focused TS, Swift unit, web component, iOS UI, localization/text-source, accessibility, and affected-platform validation per testing policy; keep results in task notes before finalization.

5. Fix review findings: localize web diff screen-reader labels, reset Apple exam state on audio startup failure, add deterministic/shared fixture coverage and accessibility checks, then record per-test Apple full-run names before re-finalizing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented shared Morse exam generation/diff in packages/morse-engine and packages/morse-swift, web copy practice/exam panels, and iOS/macOS Apple copy practice/exam views. tvOS/visionOS were left on their existing simplified Morse preview per owner decision; shared package coverage still ran through their linked app suites. Validation: pnpm typecheck; pnpm test (content-tools 100, morse-engine 7, web 112); pnpm build:web; web URL/CSP audit; DEVELOPER_DIR swift test in packages/morse-swift (MorseFixtureTests/testEveryMorseFixtureMatchesSwiftEngine); node scripts/check-apple-text-sources.ts; pnpm check:apple-l10n; pnpm check:apple-network. Apple targeted: iOS MorseTrainerTests 8 tests passed; iOS CanadianHamPracticeUITests/testMorseCopyPracticeAndExamFlow passed. Full affected-platform suites: iOS CanadianHam passed (36 unit tests + 41 UI tests); macOS CanadianHam passed (36 unit tests, UI skipped); tvOS CanadianHamTV passed (12 UI tests); visionOS CanadianHamVision passed (3 unit tests + 9 UI tests). XcodeGen regenerated twice with deterministic project diff.

Review fix round started from tip 6619207542954c5ebd4b27a554cd1277f7ee5248 after merging origin/main (already up to date; git fetch reported credential storage warning fatal: failed to store: -25308). Unchecked AC3 and AC4 until fixture/accessibility coverage and localized screen-reader labels are verified.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added Morse copy practice and the simulated Canadian 5 wpm receiving exam across shared engines, web, and Apple iOS/macOS. Verified generator constraints, scoring/diff, web UI, Apple UI, localization, network policy, and full affected Apple suites with evidence in implementation notes.
<!-- SECTION:FINAL_SUMMARY:END -->
