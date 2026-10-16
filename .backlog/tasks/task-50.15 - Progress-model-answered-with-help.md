---
id: TASK-50.15
title: 'Progress model: answered with help'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 08:12'
updated_date: '2026-10-16 21:48'
labels:
  - engine
dependencies: []
parent_task_id: TASK-50
priority: high
type: task
ordinal: 129000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Question hints need a durable progress state before UI work records hinted answers. The model must represent answered-with-help consistently across TypeScript and Swift engines, parity fixtures, progress/export schemas, sync device rows, and import compatibility so web and Apple UI tasks do not each invent separate semantics.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 engine-ts and engine-swift store answered with help as a flag alongside correct/incorrect outcomes, preserving accuracy stats while withholding mastery credit and weak-area clearing
- [ ] #2 Shared parity fixtures cover hinted-answer scheduling and sooner spaced-review return behaviour
- [ ] #3 common progress schema, progress export schema, sync device rows, and import compatibility accept and preserve the answered-with-help state
- [ ] #4 Migration/backward-compatibility tests cover older progress exports or device rows that do not contain the new state
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Trace the TypeScript and Swift progress attempt models, scheduling, mastery, weak-area, export/import, and parity fixture flow.
2. Add an optional answered-with-help flag defaulting to false in schemas, fixtures, TS/Swift models, import/export, and any sync device rows while preserving older data.
3. Apply owner semantics consistently: hinted answers keep correct/incorrect accuracy, never grant mastery credit or clear weak areas, and use the incorrect/shortest review interval for spaced scheduling.
4. Add/update parity, migration/back-compat, TS and Swift tests for hinted correct, hinted incorrect, repeated hinted-to-unaided sequences, and older records without the field.
5. Document the semantics and run the requested package, schema, import, parity, Swift, and affected Apple checks before finalizing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented answered-with-help as an additional flag alongside correct/incorrect outcomes. Scheduling rule chosen and documented: any answered-with-help attempt is proficiency-no-credit and uses the same immediate review scheduling as an incorrect answer (box 0, dueAt = now), while correctAttempts/recentResults still preserve actual accuracy. Added parallel recentAnsweredWithHelp so weak-area logic can treat helped correct answers as not proficiency-correct.
<!-- SECTION:NOTES:END -->
