---
id: TASK-50.12
title: 'Apple hint tool on iOS, iPadOS and macOS'
status: To Do
assignee: []
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 15:31'
labels:
  - apple
dependencies:
  - TASK-44.3
  - TASK-50.11
  - TASK-50.15
  - TASK-53
parent_task_id: TASK-50
priority: high
type: task
ordinal: 126000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add the Hint tool to iOS/iPadOS/macOS practice and review sessions after task-44.3 supplies the Apple exam-tools surface and after the web behaviour is established. Hints must be hidden in mock exams and share the same progress semantics as web.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 iOS, iPadOS, and macOS practice/review sessions expose localized hints in the exam-tools UI created by task-44.3; mock exams do not.
- [ ] #2 Opening a hint and answering records answered with help and applies the same mastery, weak-area, and spaced-review semantics as web.
- [ ] #3 Apple accessibility tests cover the tool open state and hinted-answer flow on the affected platforms without widening to tvOS/visionOS.
- [ ] #4 Reference-sheet pointer labels from referenceSheetSection are shown only on Apple surfaces where the reference sheet is available and hidden otherwise.
- [ ] #5 Hint data is bundled into the Apple content package for iOS, iPadOS, and macOS offline use with the active Basic bank.
- [ ] #6 A localized "Review in lesson" link from lessonLink appears with the last available hint level (Hint 2 for two-level files, Hint 1 for one-level files), notes in French UI that current lesson bodies are English-only, opens the linked lesson at sectionAnchor without discarding the in-progress practice/review session, and the Apple lesson reader renders the computed id on the target heading element using the shared fixtures/lesson-heading-anchors.json algorithm and Swift fixture test, keeps heading IDs unique per page, and moves focus to the target heading after navigation.
- [ ] #7 The hint tool handles one-level hint files by presenting only Hint 1, with no empty or broken Hint 2 affordance.
- [ ] #8 The lesson link uses a generic localized label ("Review in lesson" / « Revoir dans la leçon ») and never shows the linked section heading or lesson title before the question is answered, because some headings contain answer words (e.g. "Sporadic E and six metres")
<!-- AC:END -->
