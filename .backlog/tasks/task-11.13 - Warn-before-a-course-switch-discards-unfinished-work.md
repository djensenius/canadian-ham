---
id: TASK-11.13
title: Warn before a course switch discards unfinished work
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-05 13:33'
updated_date: '2026-10-05 18:49'
labels: []
dependencies:
  - TASK-11.5
parent_task_id: TASK-11
priority: low
ordinal: 66000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: switching course (Basic/Advanced) silently discards an unfinished mock exam or review session on web and Apple. Found in the task-11.5 review.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Switching course while a mock exam or review session is unfinished asks for confirmation on web and Apple (or keeps the session per course)
- [ ] #2 Tests on web and Apple; accessible, EN/FR
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Locate web and Apple course-switch paths and existing session state for mock exams and practice/review sessions.
2. Add localized, accessible confirmation before discarding unfinished sessions; Cancel leaves the current course and session intact.
3. Add web component coverage and iOS UI coverage including light/dark unfiltered accessibility audits.
4. Run targeted tests, localization checks, web checks, and one full Apple run for each affected platform.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Started implementation after reading task-execution/task-finalization guidance, AGENTS testing policy, task-11.5 review notes, and PR #141 discussion.

Implemented web and Apple course-switch confirmation before discarding unfinished practice/mock sessions, with EN/FR strings and web/iOS UI coverage. Web pnpm test, typecheck, build, dist URL/CSP audit, and Apple text-source check passed; iOS targeted UI/unit runs are queued behind the xbuild lock.
<!-- SECTION:NOTES:END -->
