---
id: TASK-11.8
title: Accept future Basic bank IDs or derive rules from manifests
status: Done
assignee:
  - '@worker'
created_date: '2026-10-02 13:59'
updated_date: '2026-10-09 06:00'
labels:
  - content
  - apple
  - web
milestone: m-1
dependencies: []
parent_task_id: TASK-11
type: task
ordinal: 54000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Review note 2 from task-11.3 found that bank-rule lookup accepts any advanced-* id but only the exact Basic id basic-2025-07-15. A future ISED Basic refresh would make generateExam, scoreExam and computeReadiness fail until code is updated, even when the bank manifest contains enough shape information. Track this separately so task-11.3 can stay focused on the approved multi-bank plumbing.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Future Basic bank identifiers, e.g. basic-YYYY-MM-DD, are accepted or bank rules are derived from the loaded/generated manifest without hard-coding only basic-2025-07-15.
- [x] #2 Basic and Advanced exam generation, scoring and readiness still reject truly unsupported bank IDs with clear errors.
- [x] #3 Tests cover a future Basic id or manifest-derived Basic rules in TS and Swift.
- [x] #4 Advanced readiness has a fixture with two exams at exactly 70% that expects pass-ready, pinning the inclusive threshold in TS and Swift
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Generalize Basic bank-rule lookup across content-tools, engine-ts, and engine-swift without changing active basic-2025-07-15 data.\n2. Add TS/Swift tests and fixtures for future Basic ids, unsupported ids, and Advanced 70% readiness.\n3. Run targeted package/Swift checks and record evidence before finalizing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented future Basic bank ids in content-tools packages/content-tools/src/banks.ts:75 and engine-ts packages/engine-ts/src/banks.ts:36 plus Swift packages/engine-swift/Sources/CanadianHamEngine/Banks.swift:54. Added future-Basic and unsupported-id tests in packages/content-tools/test/bank-rules.test.ts:48, packages/engine-ts/test/validation.test.ts:58, and packages/engine-swift/Tests/CanadianHamEngineTests/ValidationTests.swift:69. Added Advanced two-70%-exam readiness fixture via packages/engine-ts/src/generate-fixtures.ts:445 and fixtures/engine/readiness.json:1438. Validation: pnpm --filter @canadian-ham/content-tools test; pnpm --filter @canadian-ham/engine-ts test; pnpm --filter @canadian-ham/engine-ts generate-fixtures:check; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test in packages/engine-swift; pnpm typecheck; pnpm test; Apple iOS/macOS/tvOS/visionOS xbuild chain passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Generalized Basic bank-rule lookup to accept basic-YYYY-MM-DD while retaining Basic/Advanced unsupported-id errors. Added TS/Swift/content-tools tests and an Advanced 70%+70% pass-ready fixture; verified with package, web, schema/content, Swift, and Apple platform checks.
<!-- SECTION:FINAL_SUMMARY:END -->
