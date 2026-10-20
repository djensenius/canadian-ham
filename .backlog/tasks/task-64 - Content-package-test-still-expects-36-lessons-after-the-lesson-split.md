---
id: TASK-64
title: Content package test still expects 36 lessons after the lesson split
status: To Do
assignee: []
created_date: '2026-10-20 04:52'
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
- [ ] #1 testLoadsRealRepositoryContent asserts the current 37 lessons, ordered lessons and quizzes, and swift test in packages/content-swift passes
- [ ] #2 A follow-up note records that content-swift swift test is not run in CI
<!-- AC:END -->
