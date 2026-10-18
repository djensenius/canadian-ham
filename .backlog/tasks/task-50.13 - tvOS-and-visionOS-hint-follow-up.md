---
id: TASK-50.13
title: tvOS and visionOS hint follow-up
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-18 23:55'
labels:
  - apple
dependencies:
  - TASK-50.12
parent_task_id: TASK-50
priority: low
type: task
ordinal: 127000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Bring the Hint tool to tvOS and visionOS after the first Apple iOS/iPadOS/macOS implementation has settled, using platform-appropriate exam-tools presentation and the same no-mock-exam and progress rules.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 tvOS and visionOS practice/review sessions expose the localized Hint tool with platform-appropriate focus/interaction.
- [x] #2 Mock exams on tvOS and visionOS do not expose hints.
- [x] #3 Progress and spaced-review semantics match the web and iOS/iPadOS/macOS implementations.
- [x] #4 Reference-sheet pointer labels from referenceSheetSection are shown only on tvOS/visionOS surfaces where the reference sheet is available and hidden otherwise.
- [x] #5 tvOS and visionOS consume the bundled Apple content-package hint data for offline use with the active Basic bank.
- [x] #6 A localized "Review in lesson" link from lessonLink appears with the last available hint level (Hint 2 for two-level files, Hint 1 for one-level files), notes in French UI that current lesson bodies are English-only, opens the linked lesson at sectionAnchor without discarding the in-progress practice/review session, and the tvOS/visionOS lesson readers generate anchors with the shared fixtures/lesson-heading-anchors.json algorithm and Swift fixture test.
- [x] #7 The hint tool handles one-level hint files by presenting only Hint 1, with no empty or broken Hint 2 affordance.
- [x] #8 The lesson link uses a generic localized label ("Review in lesson" / « Revoir dans la leçon ») and never shows the linked section heading or lesson title before the question is answered, because some headings contain answer words (e.g. "Sporadic E and six metres")
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the shipped task-50.12 hint/session/content and lesson-anchor code, plus tvOS/visionOS practice/mock/lesson surfaces and target membership.\n2. Reuse shared hint/content/engine files by adding them to CanadianHamTV and CanadianHamVision targets, then add minimal platform-specific Hint presentation to tvOS/visionOS practice only with mock exams excluded.\n3. Wire help recording, ladder/timer/lesson-link/session-retention behavior through existing practice state without touching iOS-only views unless needed.\n4. Add or extend tvOS/visionOS unit/UI/accessibility tests for availability/absence, ladder/one-level files, lesson links, help recording, and audits.\n5. Regenerate the Apple project twice with XcodeGen, verify determinism, run targeted xbuild and JS/localization/content checks, then finalize Backlog, commit, push, and open the PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Coordinator decision recorded: tvOS and visionOS practice sessions remain in memory only, matching their About privacy text; AC3 is satisfied by applying the same shared engine rules to in-session progress (answeredWithHelp qualification, due scheduling, and weak-area semantics), with no new persistence.
Validation evidence:
- Full tvOS scheme passed: CanadianHamTVTests 6 tests and CanadianHamTVUITests 14 tests, 0 failures (/tmp/task-50.13-tvos-full.log).
- Full visionOS scheme passed: CanadianHamVisionTests 6 tests and CanadianHamVisionUITests 11 tests, 0 failures (/tmp/task-50.13-vision-full.log).
- iPhone 17 Pro CanadianHamExamToolsUITests passed after merging origin/main: 35 tests, 3 expected skips, 0 failures (/tmp/task-50.13-ios-examtools-after-merge.log). The pre-merge class run had one hinge-test failure; origin/main single-method passed and the branch single-method passed after merge.
- macOS unit run passed: CanadianHamTests 176 tests, 0 failures (/tmp/task-50.13-macos-units.log).
- pnpm typecheck, pnpm test, pnpm check:apple-l10n, node scripts/check-apple-text-sources.ts, XcodeGen twice plus git diff --check all passed.
AC evidence:
1. tvOS/visionOS UI tests exercise focused platform hint panels in practice sessions, including the hint ladder and accessibility audits.
2. tvOS/visionOS mockExam launch-argument tests fall back to the non-practice grid and assert no hint action exists.
3. tvOS/visionOS unit tests assert shared PracticeHintRules qualification, answeredWithHelp recording, 0.5 s visibility delay, due scheduling, and weak-area behavior through CanadianHamEngine.
4. tvOS/visionOS unit and UI tests assert reference-sheet pointers are hidden when reference sheets are unavailable.
5. tvOS/visionOS unit tests load the built app bundles and assert active Basic generated data plus 984 bundled question hints, offline.
6. tvOS/visionOS UI tests open the generic French Review in lesson link, assert the English-only notice, land on lesson-heading-wavelength-and-frequency, and return to the same in-progress session; unit tests verify LessonHeadingAnchors against the linked sectionAnchor.
7. tvOS/visionOS unit and UI tests cover B-001-002-002 one-level hints, asserting no Hint 2 action.
8. tvOS/visionOS UI tests assert the localized generic lesson-link label and that the lesson title/section heading are absent before the question is answered.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented tvOS and visionOS hint support for practice/review sessions using the shared Apple hint content, visibility qualification, lesson-anchor rendering, and CanadianHamEngine progress semantics while keeping platform sessions in memory only. Added platform lesson readers for hint links, hid reference-sheet pointers where no sheet exists, excluded hints from mock exams, and added/updated unit and UI coverage for ladder, one-level hints, French English-only lesson notice, generic link text, bundled data, session retention, 0.5 s qualification, due scheduling, and weak areas. Validation passed across full tvOS and visionOS schemes, iPhone ExamTools UI tests, macOS unit tests, pnpm typecheck/test, Apple localization checks, text-source checks, XcodeGen determinism, and git diff --check.
<!-- SECTION:FINAL_SUMMARY:END -->
