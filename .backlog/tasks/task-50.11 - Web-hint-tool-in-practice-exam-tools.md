---
id: TASK-50.11
title: Web hint tool in practice exam tools
status: To Do
assignee: []
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 15:31'
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
- [ ] #1 Practice and review sessions show a localized Hint tool in the existing exam-tools panel; mock exams never expose hints.
- [ ] #2 Opening Hint 1 then Hint 2 follows the approved ladder, announces state accessibly, and does not reveal official answer text.
- [ ] #3 Answering after any opened hint records answered with help, does not advance mastery or weak-area clearing, and schedules the question sooner in spaced review.
- [ ] #4 Web tests cover availability by session type, accessibility/keyboard behaviour, EN/FR display, and progress/spaced-review effects.
- [ ] #5 Reference-sheet pointer labels from referenceSheetSection are shown only when the web reference sheet is available for the session and hidden otherwise.
- [ ] #6 Hint data is bundled into the web build so practice/review hints work offline with the active Basic bank.
- [ ] #7 A localized "Review in lesson" link from lessonLink appears with the last available hint level (Hint 2 for two-level files, Hint 1 for one-level files), notes in French UI that current lesson bodies are English-only, opens the linked lesson at sectionAnchor without discarding the in-progress practice/review session, and the web lesson reader renders the computed id on the target heading element using the shared fixtures/lesson-heading-anchors.json algorithm, keeps heading IDs unique per page, and moves focus to the target heading after navigation.
- [ ] #8 The hint tool handles one-level hint files by presenting only Hint 1, with no empty or broken Hint 2 affordance.
- [ ] #9 The lesson link uses a generic localized label ("Review in lesson" / « Revoir dans la leçon ») and never shows the linked section heading or lesson title before the question is answered, because some headings contain answer words (e.g. "Sporadic E and six metres")
<!-- AC:END -->
