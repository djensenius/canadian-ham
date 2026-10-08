---
id: TASK-11.14
title: >-
  Course-switch warning: regression tests for answered practice and review
  sessions
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-06 03:22'
updated_date: '2026-10-08 12:06'
labels: []
dependencies:
  - TASK-11.13
parent_task_id: TASK-11
priority: low
ordinal: 67000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: PR #142 (task-11.13) tests the course-switch warning for mock exams and unanswered practice only. Copilot asked for coverage of the answered-practice paths on web and Apple.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Web tests: partially answered immediate practice and fully answered but unsubmitted review-later practice both prompt; Cancel keeps the answers; Confirm discards the session; a submitted review session does not prompt
- [ ] #2 Apple UI tests cover the same cases on iOS (targeted runs plus the policy's full runs)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add web course-switch regression tests for answered immediate practice, unsubmitted review-later practice, confirm discard, cancel preserve, and submitted-review no prompt.\n2. Add matching iOS UI coverage for Apple course switching.\n3. Run targeted web and Apple UI tests, then final affected platform suites.
<!-- SECTION:PLAN:END -->
