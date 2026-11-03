---
id: TASK-84
title: 'Configure GitHub Project #8 fields, views and README'
status: In Progress
assignee:
  - '@coordinator'
created_date: '2026-11-03T02:32:00Z'
updated_date: '2026-11-03T06:39:00Z'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Create Project #8 fields with the keyring gh login (project scope): single-select Priority (High, Medium, Low) and Backlog milestone (v1 release, Post-v1), text Task ID and Branch.
2. Map them in .backlog-sync.json under fields (priority, milestone, taskId, branch); leave area unmapped because tasks have no project value.
3. Dry-run backlog-sync with the branch config against the main checkout root and check for missing-field or missing-option diagnostics.
4. Real run with a temporary copy of the branch config that shares the launchd job's lock file, so it cannot overlap the scheduled sync; then confirm every canonical item has Priority (where the task has one), Backlog milestone (where set) and Task ID filled.
5. Create views through the Projects REST API: Status board (board by Status), Agent-ready (table, not Done, no owner-gate, blocked:owner or inbox labels), Owner gates (table, owner-gate or blocked:owner labels) and v1 release (table, Backlog milestone v1 release); verify each filter with the REST items q parameter.
6. Set the Project README and short description: Backlog.md is the source of truth, how the one-way sync and inbox label work, what owner-gate means, link AGENTS.md.
7. Record evidence, check the acceptance criteria, and open the PR with the config change.
<!-- SECTION:PLAN:END -->
