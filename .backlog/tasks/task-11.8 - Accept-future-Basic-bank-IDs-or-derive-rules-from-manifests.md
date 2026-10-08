---
id: TASK-11.8
title: Accept future Basic bank IDs or derive rules from manifests
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 13:59'
updated_date: '2026-10-08 12:06'
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
- [ ] #1 Future Basic bank identifiers, e.g. basic-YYYY-MM-DD, are accepted or bank rules are derived from the loaded/generated manifest without hard-coding only basic-2025-07-15.
- [ ] #2 Basic and Advanced exam generation, scoring and readiness still reject truly unsupported bank IDs with clear errors.
- [ ] #3 Tests cover a future Basic id or manifest-derived Basic rules in TS and Swift.
- [ ] #4 Advanced readiness has a fixture with two exams at exactly 70% that expects pass-ready, pinning the inclusive threshold in TS and Swift
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Generalize Basic bank-rule lookup across content-tools, engine-ts, and engine-swift without changing active basic-2025-07-15 data.\n2. Add TS/Swift tests and fixtures for future Basic ids, unsupported ids, and Advanced 70% readiness.\n3. Run targeted package/Swift checks and record evidence before finalizing.
<!-- SECTION:PLAN:END -->
