---
id: TASK-13.3
title: SwiftData schema V2 for CloudKit compatibility
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
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
