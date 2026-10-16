---
id: TASK-50.13
title: tvOS and visionOS hint follow-up
status: To Do
assignee: []
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 08:12'
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
- [ ] #1 tvOS and visionOS practice/review sessions expose the localized Hint tool with platform-appropriate focus/interaction.
- [ ] #2 Mock exams on tvOS and visionOS do not expose hints.
- [ ] #3 Progress and spaced-review semantics match the web and iOS/iPadOS/macOS implementations.
- [ ] #4 Reference-sheet pointer labels from referenceSheetSection are shown only on tvOS/visionOS surfaces where the reference sheet is available and hidden otherwise.
- [ ] #5 tvOS and visionOS consume the bundled Apple content-package hint data for offline use with the active Basic bank.
<!-- AC:END -->
