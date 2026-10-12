---
id: TASK-44.1
title: 'Calculator engine (TS and Swift, shared fixtures)'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:38'
updated_date: '2026-10-12 14:40'
labels:
  - web
  - apple
dependencies: []
parent_task_id: TASK-44
priority: medium
ordinal: 94000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A pure, deterministic basic-calculator engine in TypeScript (packages/) and Swift (packages/): digits, decimal point, + - x ÷, √, x², 1/x, ±, %, clear, all-clear and backspace, with conventional immediate-execution behaviour like a basic calculator, sensible display formatting (significant digits, no binary float artefacts such as 0.1+0.2), error states (÷0, √ of a negative), locale-aware decimal separator for display. Shared JSON fixtures of key sequences and expected displays run in both test suites.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 TS and Swift engines pass the same shared fixture file (at least 60 cases including chained operations, repeated equals, backspace, sign, percent, errors and rounding)
- [ ] #2 No storage of formulas or text; state is only the current calculation
<!-- AC:END -->
