---
id: TASK-44.1
title: 'Calculator engine (TS and Swift, shared fixtures)'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-12 14:38'
updated_date: '2026-10-12 14:48'
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
- [x] #1 TS and Swift engines pass the same shared fixture file (at least 60 cases including chained operations, repeated equals, backspace, sign, percent, errors and rounding)
- [x] #2 No storage of formulas or text; state is only the current calculation
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a pure calculator engine package pair under packages/calculator-ts and packages/calculator-swift with matching public key/state APIs and documented basic-calculator semantics (left-to-right chaining, repeated equals, percent rules, error recovery, display formatting).
2. Add one shared fixtures/calculator/sequences.json file with 60+ key-sequence cases and run it from both TS node tests and Swift XCTest.
3. Wire the TS package into pnpm root test/typecheck and CI; keep the Swift package standalone because UI tasks will link it later.
4. Run pnpm typecheck, TZ=UTC pnpm test, and DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test in packages/calculator-swift, then update task notes/ACs/final status.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented packages/calculator-ts and packages/calculator-swift, plus fixtures/calculator/sequences.json with 80 shared key-sequence cases. Documented left-to-right immediate execution, repeated equals, percent behaviour, errors, locale display and no formula/history storage. Wired @canadian-ham/calculator-engine into root pnpm test and CI. Validation: pnpm --filter @canadian-ham/calculator-engine test passed; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test in packages/calculator-swift passed; pnpm typecheck passed after pnpm install; TZ=UTC pnpm test passed. Apple app suites skipped because no app target/project.yml changes.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added pure TypeScript and Swift calculator engine packages using one shared 80-case fixture file, documented the calculator semantics and no-formula state constraint, and wired TS checks into pnpm/CI. Verified with shared TS fixture tests, Swift package tests, pnpm typecheck, and TZ=UTC pnpm test.
<!-- SECTION:FINAL_SUMMARY:END -->
