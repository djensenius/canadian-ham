---
id: TASK-13.1
title: Source-check the iCloud sync brief and record decisions
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 22:37'
labels:
  - apple
  - docs
milestone: m-1
dependencies: []
parent_task_id: TASK-13
ordinal: 23000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Verify the iCloud sync research claims (Apple's definition of 'collect' for the privacy label, SwiftData/CloudKit model constraints, platform support), commit it to docs/proposals/icloud-sync.md, and record the owner's decisions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The privacy-label claim is verified against Apple's current documentation
- [ ] #2 The brief is committed under docs/proposals/
- [ ] #3 The owner's decisions are recorded in the parent task notes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review the source-checked iCloud brief and existing docs/proposals structure. 2. Commit the brief to docs/proposals/icloud-sync.md with only formatting/link/project-scope cleanup. 3. Run link validation, record evidence, check only verified ACs, and leave owner-decision AC open.
<!-- SECTION:PLAN:END -->
