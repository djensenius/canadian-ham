---
id: TASK-12.16
title: 'Morse course correctness follow-ups from PR #127'
status: To Do
assignee: []
created_date: '2026-10-04 09:12'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.5
parent_task_id: TASK-12
priority: high
ordinal: 63000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: Copilot's final review of PR #127 found six issues in the new course code: the summary claims the next lesson unlocked after review sessions and after lesson 40; the daily streak resets to 0 at midnight until today's first lesson (TS and Swift); Apple builds progress dates with Calendar.current, so non-Gregorian calendars produce dates that don't match web; and the TypeScript course parser doesn't validate unit IDs while Swift does.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Summary copy depends on session mode and lesson position: reviews and lesson 40 never claim an unlock (web and Apple), with tests
- [ ] #2 The daily streak counts back from today if there's activity today, otherwise from yesterday, so it only breaks after a missed day; identical in TS and Swift with a shared fixture
- [ ] #3 Apple progress dates use a Gregorian calendar in the current time zone; the TS parser validates unit IDs unit-01..unit-08 like Swift; tests cover both
<!-- AC:END -->
