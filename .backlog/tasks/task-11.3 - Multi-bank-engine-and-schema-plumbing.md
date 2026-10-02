---
id: TASK-11.3
title: Multi-bank engine and schema plumbing
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
labels:
  - content
  - web
  - apple
milestone: m-1
dependencies:
  - TASK-1
parent_task_id: TASK-11
priority: medium
ordinal: 35000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: Advanced has 549 questions, 7 categories, 50 subsections, 50-question exams and no Honours, while every layer today assumes the Basic bank. Parameterising the bank first lets Advanced reuse the engines, schemas and progress store. See docs/proposals/advanced-course.md (owner decisions in task-11 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 bankId is a parameter in content-tools, engine-ts and CanadianHamEngine, with per-bank subsection count (50/100), category set and Honours flag
- [ ] #2 Mock exams draw one question per subsection for the active bank; Honours and honours-ready are suppressed when the bank has no Honours
- [ ] #3 Scores, progress records and the progress export carry bankId, with JSON Schemas and shared TS/Swift fixtures updated and existing Basic exports still importing
- [ ] #4 All web tests, schema checks and the iOS and macOS xbuild suites pass
<!-- AC:END -->
