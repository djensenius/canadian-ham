---
id: TASK-13.3
title: SwiftData schema V2 for CloudKit compatibility
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-08 12:07'
labels:
  - apple
  - privacy
milestone: m-1
dependencies:
  - TASK-13.2
parent_task_id: TASK-13
priority: medium
ordinal: 47000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: CloudKit cannot mirror models with unique constraints or non-defaulted properties, so the progress schema must change and uniqueness move into ProgressStore. See docs/proposals/icloud-sync.md (owner decisions in task-13 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 CanadianHamProgressSchemaV2 removes @Attribute(.unique) from all three entities and gives every non-optional property a declaration-level default, with a SchemaMigrationPlan stage
- [ ] #2 ProgressStore dedups by questionId, exam id and preferences key, with query-before-insert
- [ ] #3 V1-to-V2 migration and dedup tests pass via xbuild on iOS and macOS
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Refactor SwiftData progress models into VersionedSchema V1/V2 types where V2 removes unique constraints and adds declaration-level defaults while keeping local-only ModelContainer configuration.\n2. Update ProgressStore query-before-insert paths so question progress, exam attempts, and preferences are deduplicated without SwiftData unique constraints, preserving import replace-all, rollback, and reset semantics.\n3. Add V1-to-V2 migration and duplicate-store tests for iOS/macOS, then run targeted and final xbuild validation.
<!-- SECTION:PLAN:END -->
