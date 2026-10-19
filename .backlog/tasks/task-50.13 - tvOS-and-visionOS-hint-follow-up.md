---
id: TASK-50.13
title: tvOS and visionOS hint follow-up
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-19 15:49'
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

Final TASK-50.13 handoff pass: reproduced the tvOS one-level failure in /tmp/task-50.13-tvos-onelevel-repro.log, fixed tvOS answer-column left navigation to scroll/focus the current hint action, and verified the one-level test in /tmp/task-50.13-tvos-onelevel-fix.log plus the tvOS hint ladder in /tmp/task-50.13-tvos-ladder-after-focusguide.log. Merged origin/main (#296) with a merge commit. Post-merge validation passed: full tvOS scheme (CanadianHamTVTests 6 + CanadianHamTVUITests 15, /tmp/task-50.13-postmerge-tvos-full.log), full visionOS scheme (CanadianHamVisionTests 6 + CanadianHamVisionUITests 12, /tmp/task-50.13-postmerge-vision-full.log), iPhone 17 Pro Learn targeted tests (2, /tmp/task-50.13-postmerge-iphone-learn-targeted.log), pnpm check:apple-l10n (/tmp/task-50.13-postmerge-apple-l10n.log), node scripts/check-apple-text-sources.ts (/tmp/task-50.13-postmerge-apple-text-sources.log), and git diff --check (/tmp/task-50.13-postmerge-git-diff-check.log). The pre-merge iPhone ExamTools+Learn final chain had the known TASK-61 hinge flake in CanadianHamExamToolsUITests.testSimulatedHingeDismissedPeekReopensOnlyAfterReset; no hinge tests were changed here and the PR body lists the flake with /tmp/task-50.13-final-iphone-examtools-learn.log.

Copilot re-review after SHA 1dd9c8c5 raised Reduce Motion findings for tvOS and visionOS linked-lesson scrolling. Fixed both lesson readers to use nil animation when Reduce Motion is active (tvOS also honors the existing test override). Validation passed: tvOS lesson-link targeted test /tmp/task-50.13-tvos-ladder-reducemotion-fix.log, visionOS lesson-link targeted test /tmp/task-50.13-vision-ladder-reducemotion-fix.log, node scripts/check-apple-text-sources.ts /tmp/task-50.13-reducemotion-apple-text-sources.log, and git diff --check /tmp/task-50.13-reducemotion-git-diff-check.log.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented tvOS and visionOS hint support and completed review fixes. This final pass adds tvOS directional focus guidance so learners starting from answer focus can reach the current hint action on short one-level questions, honors Reduce Motion for tvOS/visionOS linked-lesson scrolling, merges origin/main, and refreshes PR/task evidence. Verified full tvOS and visionOS schemes after the merge, the requested iPhone 17 Pro Learn tests, Apple localization/text-source checks, git diff --check, targeted tvOS/visionOS lesson-link tests after the Reduce Motion fix, plus prior macOS unit and pnpm typecheck/test passes. The only residual issue is the known TASK-61 hinge UI-test flake, documented in the PR and outside this task.
<!-- SECTION:FINAL_SUMMARY:END -->
