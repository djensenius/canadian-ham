---
id: TASK-11.3
title: Multi-bank engine and schema plumbing
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-02 11:51'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect current bank constants, content-tools importer, engine-ts scoring/readiness/exam/progress export, Swift CanadianHamEngine/progress code, schemas and shared fixtures.\n2. Add shared per-bank configuration (Basic default plus synthetic Advanced metadata for tests) and thread bankId through TS content-tools/engine score, readiness, progress, export/import while preserving Basic behaviour and legacy Basic export imports.\n3. Mirror the bank configuration and bankId-bearing score/progress/export changes in Swift CanadianHamEngine, suppressing Honours for no-Honours banks.\n4. Update JSON Schemas and TS/Swift fixtures/tests for bankId, Advanced-shaped mock exam behaviour, no-Honours readiness/scoring and legacy Basic import compatibility.\n5. Run the requested checks, record evidence, check acceptance criteria only after validation, add final summary, and move task-11.3 to Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner override noted: task-11.3 formally depends on task-1 (v1 release), but the owner asked to start multi-bank engine/schema plumbing now.
<!-- SECTION:NOTES:END -->
