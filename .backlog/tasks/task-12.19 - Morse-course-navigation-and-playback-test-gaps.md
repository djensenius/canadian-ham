---
id: TASK-12.19
title: Morse course navigation and playback test gaps
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-06 18:25'
updated_date: '2026-10-08 13:34'
labels: []
dependencies:
  - TASK-12.17
parent_task_id: TASK-12
priority: low
ordinal: 69000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the task-12.17 re-review approved the course redesign but listed untested paths. Back-stack placement of the state-driven lesson screen is unverified. The course-playback UI test doesn't observe course audio stopping. One locked-lesson assertion is vacuous. Review weakest characters and re-entering a finished lesson have no UI test. See ~/.cache/canadian-ham-reviews/t1217-r2.md.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 UI test: open lesson 1, go Back, see Unit 1 and the lesson list, reopen lesson 1 and get a fresh session (exercise 1)
- [ ] #2 The course-playback test observes course audio stopping (for example, via a DEBUG status) instead of a check that can never fail; the locked-lesson test taps the disabled button before asserting no session
- [ ] #3 UI tests for 'Review weakest characters' and re-entering a finished lesson
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect existing Morse course UI tests and course playback/status hooks.\n2. Add UI coverage for opening lesson 1, Back to Unit 1/list, reopening with a fresh exercise 1 session.\n3. Make course playback stop observable in the UI test path and tap the disabled locked lesson before asserting no session.\n4. Add UI tests for Review weakest characters and re-entering a finished lesson.\n5. Run focused UI tests when the xbuild lock is available, then finalize with evidence.
<!-- SECTION:PLAN:END -->
