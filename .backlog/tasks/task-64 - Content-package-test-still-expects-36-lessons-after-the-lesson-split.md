---
id: TASK-64
title: Content package test still expects 36 lessons after the lesson split
status: Done
assignee: []
created_date: '2026-10-20 04:52'
updated_date: '2026-10-20 04:53'
labels:
  - bug
  - tests
dependencies: []
priority: high
ordinal: 139000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
PR #302 (TASK-46.10) added L-005-06 and QZ-L-005-06-A, so the real repository now has 37 lessons and 37 quizzes. packages/content-swift ContentLibraryTests.testLoadsRealRepositoryContent still asserted 36 and failed on main; CI does not run swift test for content-swift, so this was only caught by the TASK-46.12 worker.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 testLoadsRealRepositoryContent asserts the current 37 lessons, ordered lessons and quizzes, and swift test in packages/content-swift passes
- [x] #2 A follow-up note records that content-swift swift test is not run in CI
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Updated ContentLibraryTests counts 36 → 37 (lessons, orderedLessons, quizzes) to match the intended content from #302 (new L-005-06 / QZ-L-005-06-A). swift test in packages/content-swift: 23/23 passed. CI gap: content-swift swift test is not part of the GitHub CI or the targeted Apple runs. TASK-33 (UI test speed and test plans) should consider adding a content-swift step, or merges touching content counts should run it.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed the content-swift real-repository test to expect 37 lessons and quizzes after the TASK-46.10 split.
<!-- SECTION:FINAL_SUMMARY:END -->
