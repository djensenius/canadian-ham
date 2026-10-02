---
id: TASK-11.6
title: Ingest the new ISED Advanced bank when published
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
labels:
  - content
  - blocked
milestone: m-1
dependencies:
  - TASK-11.4
parent_task_id: TASK-11
priority: low
ordinal: 38000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: ISED is expected to revise the Advanced bank; the app must switch to the official new edition and re-verify everything that depends on it. Blocked until ISED publishes it. See docs/proposals/advanced-course.md (owner decisions in task-11 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The new bank is vendored verbatim with SHA-256 and imported, with counts, categories, exam rules and effective date re-verified against ISED
- [ ] #2 The active-bank switch and pnpm diff:banks report are committed, and progress for retired questions is handled per docs/content-update-process (or equivalent)
<!-- AC:END -->
