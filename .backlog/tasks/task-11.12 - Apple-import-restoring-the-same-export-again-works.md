---
id: TASK-11.12
title: 'Apple import: restoring the same export again works'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-05 13:33'
updated_date: '2026-10-05 18:49'
labels: []
dependencies:
  - TASK-11.5
parent_task_id: TASK-11
priority: medium
ordinal: 65000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: ProgressModels marks questionId and attempt id as @Attribute(.unique). Since task-11.5, Apple import deletes the imported bank's records and reinserts them in one save. Re-importing the same export (the usual 'restore backup' case) has no test and could hit a uniqueness conflict. Found in the task-11.5 review (~/.cache/canadian-ham-reviews/t115-r2.md).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A unit test exports progress, then imports that same file twice; progress, exam attempts and lesson data are identical afterwards
- [ ] #2 Any uniqueness conflict found is fixed; the macOS and iOS suites pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add Apple import regression coverage for exporting then importing the same file twice, and compare progress, attempts, lessons, Morse and preferences snapshots after each restore.
2. Fix any SwiftData uniqueness conflicts found by the regression and add import validation for Advanced attempts with honours=true on Apple and web.
3. Add focused Apple and web tests for rejecting honours=true when the target bank has no Honours result.
4. Run targeted import tests, then required web and Apple validation before checking acceptance criteria.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Started implementation. Added scope from PR #141 Copilot final summary: Advanced imports must reject attempts marked honours=true on Apple and web because Advanced has no Honours result.

Implemented Apple same-export-twice regression and Advanced honours import rejection on Apple/web. Web pnpm test, typecheck, build, dist URL/CSP audit, and Apple text-source check passed; iOS targeted ProgressStoreTests are queued behind the xbuild lock in /tmp/t1112-ios-progressstore.log.
<!-- SECTION:NOTES:END -->
