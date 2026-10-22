---
id: TASK-50.11
title: Web hint tool in practice exam tools
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-17 01:26'
labels:
  - web
dependencies:
  - TASK-50.3
  - TASK-50.4
  - TASK-50.5
  - TASK-50.6
  - TASK-50.7
  - TASK-50.8
  - TASK-50.9
  - TASK-50.10
  - TASK-50.15
  - TASK-53
parent_task_id: TASK-50
priority: high
type: task
ordinal: 125000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add the Hint tool to the existing web practice/review exam-tools panel after Basic hint content exists. Hints must be hidden in mock exams, localized EN/FR, accessible, and integrated with progress so hinted answers are treated as answered with help.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Practice and review sessions show a localized Hint tool in the existing exam-tools panel; mock exams never expose hints.
- [x] #2 Opening Hint 1 then Hint 2 follows the approved ladder, announces state accessibly, and does not reveal official answer text.
- [x] #3 Answering after any opened hint records answered with help, does not advance mastery or weak-area clearing, and schedules the question sooner in spaced review.
- [x] #4 Web tests cover availability by session type, accessibility/keyboard behaviour, EN/FR display, and progress/spaced-review effects.
- [x] #5 Reference-sheet pointer labels from referenceSheetSection are shown only when the web reference sheet is available for the session and hidden otherwise.
- [x] #6 Hint data is bundled into the web build so practice/review hints work offline with the active Basic bank.
- [x] #7 A localized "Review in lesson" link from lessonLink appears with the last available hint level (Hint 2 for two-level files, Hint 1 for one-level files), notes in French UI that current lesson bodies are English-only, opens the linked lesson at sectionAnchor without discarding the in-progress practice/review session, and the web lesson reader renders the computed id on the target heading element using the shared fixtures/lesson-heading-anchors.json algorithm, keeps heading IDs unique per page, and moves focus to the target heading after navigation.
- [x] #8 The hint tool handles one-level hint files by presenting only Hint 1, with no empty or broken Hint 2 affordance.
- [x] #9 The lesson link uses a generic localized label ("Review in lesson" / « Revoir dans la leçon ») and never shows the linked section heading or lesson title before the question is answered, because some headings contain answer words (e.g. "Sporadic E and six metres")
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a bundled web hint data loader for the active Basic bank, including localized hint text, one/two-level metadata, reference-sheet section labels, and lesson-link metadata.\n2. Add a Hint tool to the existing web exam-tools panel for practice/review only, with the approved ladder, accessibility announcements/focus, reference-sheet gating, lesson links, and 0.5 s answered-with-help qualification.\n3. Wire practice answer submission to pass answeredWithHelp through the 50.15 progress API while leaving mock exams and lesson quizzes unchanged.\n4. Render shared lesson heading anchors in the web lesson reader and focus linked headings after hint-link navigation without discarding the session.\n5. Add web/unit tests covering session availability, keyboard/accessibility, EN/FR, one-level hints, 0.5 s rule, progress scheduling, reference gating, bundled offline data, lesson-link focus, and heading IDs; then run the requested checks.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented web hint data bundling and the practice/review Hint exam tool. Validation: pnpm typecheck; pnpm test; pnpm build:web; pnpm --filter @canadian-ham/web audit:urls; pnpm check:hints -- --require-complete; pnpm check:links; pnpm check:schemas. Web tests cover practice/due-review vs mock availability, keyboard/liveness, EN/FR and one-level ladders, 0.5 s answered-with-help timing, progress scheduling, reference-sheet label gating, bundled Basic hints, lesson-link focus, unique heading anchors, and generic lesson labels.

Review fix round for PR #278: lifted web hint state into PracticeSession so lesson-link round trips preserve help; removed section anchors from link hrefs; stabilized 0.5 s qualification across re-renders; implemented review-later post-selection help counting while keeping immediate post-score hints non-mutating; fixed French note styling/live messages/focus cleanup/empty hint panel/heading empty-slug robustness. Validation passed: pnpm typecheck; pnpm test; pnpm build:web; pnpm --filter @canadian-ham/web audit:urls; pnpm check:hints -- --require-complete; pnpm check:links; pnpm check:schemas.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added a bundled Basic hint loader and web Hint tool in the existing practice/review exam-tools panel, wired 0.5 s qualified hints into answeredWithHelp progress, added shared lesson heading IDs/focus for hint lesson links, and verified with the requested web/content/schema checks.
<!-- SECTION:FINAL_SUMMARY:END -->
