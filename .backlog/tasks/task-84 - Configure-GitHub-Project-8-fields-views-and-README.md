---
id: TASK-84
title: 'Configure GitHub Project #8 fields, views and README'
status: To Do
assignee: []
created_date: '2026-11-03T02:32:00Z'
labels:
  - tooling
  - github
dependencies:
  - TASK-83
priority: medium
type: chore
ordinal: 167000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Project #8 (https://github.com/users/djensenius/projects/8) mirrors the backlog through backlog-sync, but it only has the default table view and built-in fields. Add the fields backlog-sync can populate, map them in .backlog-sync.json, and create views that show agent-ready work, owner gates and the v1 release path. Backlog.md stays the source of truth.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Project #8 has single-select Priority (High, Medium, Low) and Backlog milestone (v1 release, Post-v1) fields plus text Task ID and Branch fields, and .backlog-sync.json maps them
- [ ] #2 A backlog-sync dry run with the new mapping reports no missing fields or options, and a real run fills the fields on every canonical item
- [ ] #3 The Project has a status board, an agent-ready table that excludes Done and owner-gate items, an owner-gates table, and a v1 release table
- [ ] #4 The Project README and short description say Backlog.md is the source of truth, describe the sync and owner-gate label, and link AGENTS.md
<!-- AC:END -->
