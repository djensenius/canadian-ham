---
id: TASK-50.13
title: tvOS and visionOS hint follow-up
status: To Do
assignee: []
created_date: '2026-10-16 07:58'
updated_date: '2026-10-16 12:07'
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
- [ ] #6 A localized "Review in lesson" link from lessonLink appears with the last available hint level (Hint 2 for two-level files, Hint 1 for one-level files), notes in French UI that current lesson bodies are English-only, opens the linked lesson at sectionAnchor without discarding the in-progress practice/review session, and the tvOS/visionOS lesson readers generate anchors with the shared fixtures/lesson-heading-anchors.json algorithm and Swift fixture test.
- [ ] #7 The hint tool handles one-level hint files by presenting only Hint 1, with no empty or broken Hint 2 affordance.
<!-- AC:END -->
