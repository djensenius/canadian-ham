---
id: TASK-11.3
title: Multi-bank engine and schema plumbing
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-02 13:59'
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
- [x] #1 bankId is a parameter in content-tools, engine-ts and CanadianHamEngine, with per-bank subsection count (50/100), category set and Honours flag
- [x] #2 Mock exams draw one question per subsection for the active bank; Honours and honours-ready are suppressed when the bank has no Honours
- [x] #3 Scores, progress records and the progress export carry bankId, with JSON Schemas and shared TS/Swift fixtures updated and existing Basic exports still importing
- [x] #4 All web tests, schema checks and the iOS and macOS xbuild suites pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect current bank constants, content-tools importer, engine-ts scoring/readiness/exam/progress export, Swift CanadianHamEngine/progress code, schemas and shared fixtures.\n2. Add shared per-bank configuration (Basic default plus synthetic Advanced metadata for tests) and thread bankId through TS content-tools/engine score, readiness, progress, export/import while preserving Basic behaviour and legacy Basic export imports.\n3. Mirror the bank configuration and bankId-bearing score/progress/export changes in Swift CanadianHamEngine, suppressing Honours for no-Honours banks.\n4. Update JSON Schemas and TS/Swift fixtures/tests for bankId, Advanced-shaped mock exam behaviour, no-Honours readiness/scoring and legacy Basic import compatibility.\n5. Run the requested checks, record evidence, check acceptance criteria only after validation, add final summary, and move task-11.3 to Done.

Fix-round plan: 1. Make Swift scoreExam throw on unsupported bankId and limit bank rule lookups in exam generation to full mock requests in TS and Swift. 2. Add TS/Swift coverage for mock subsection count mismatches, unsupported bankIds, unknown-bank practice generation, Advanced readiness 70/68 boundary, import score bankId mismatches, legacy schema exports without bankId, and shared bank-rule fixture agreement. 3. Create requested task-11 follow-ups for Basic bank refresh and loose bankId/question-ID schema coupling, document the older web score.bankId export gap as known, run required checks, and commit without changing task-11.3 Done status.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner override noted: task-11.3 formally depends on task-1 (v1 release), but the owner asked to start multi-bank engine/schema plumbing now.

Validation on final commit e593b2863d7f0b2d87843058835a535f32b9cf77: pnpm typecheck; pnpm test; pnpm build:web; pnpm import:check; pnpm check:schemas; pnpm check:links; pnpm --filter @canadian-ham/engine-ts test; cd packages/engine-swift && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test; iOS xbuild suite passed on iPhone 17 Pro with 28 UI/unit tests; macOS xbuild suite passed with 23 unit tests.

Fix round started from review /Users/david/.cache/canadian-ham-reviews/t11.3.md. Known gap retained from review note 5: older web exam attempts saved before task-11.3 may still export without score.bankId; schemas and import normalization keep those exports compatible, so this remains documented instead of being fixed in this round.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented multi-bank engine/schema plumbing while keeping apps on the Basic bank. Added Basic/Advanced bank rules across content-tools, engine-ts and CanadianHamEngine, parameterized mock-exam subsection counts and no-Honours scoring/readiness for Advanced, added bankId to scores/progress exports with legacy Basic import defaults, refreshed shared TS/Swift fixtures and JSON Schemas, and verified with the requested pnpm, SwiftPM and xbuild checks.
<!-- SECTION:FINAL_SUMMARY:END -->
