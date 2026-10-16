---
id: TASK-50.12
title: 'Apple hint tool on iOS, iPadOS and macOS'
status: To Do
assignee: []
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 08:12'
labels:
  - apple
dependencies:
  - TASK-44.3
  - TASK-50.11
  - TASK-50.15
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
<!-- AC:END -->
