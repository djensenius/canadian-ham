---
id: TASK-84
title: 'Configure GitHub Project #8 fields, views and README'
status: In Progress
assignee:
  - '@coordinator'
created_date: '2026-11-03T02:32:00Z'
updated_date: '2026-11-03T07:00:00Z'
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-11-03 (EST): Created Project #8 fields with the keyring gh login, because the GH_TOKEN environment token lacks the project scope: single-select Priority (High, Medium, Low) and Backlog milestone (v1 release, Post-v1), and text fields Task ID and Branch. Mapped them in .backlog-sync.json under fields (priority, milestone, taskId, branch). The optional area field stays unmapped because no task sets a project value.

Dry run (backlog-sync --dry-run --verbose, branch config, main checkout root) at 01:42 EST printed no missing-field, missing-option or skipped-field diagnostics. It planned Task ID on 195 items, Priority on 135, Backlog milestone on 84 and Branch on 4, which matches the task data: 195 tasks, 36 high, 67 medium and 32 low priorities, and 40 m-0 and 44 m-1 milestones. Its only other writes were the routine body and status updates the scheduled sync would also make.

The real run (01:45 to 01:57 EST) used a copy of the branch config whose lockFile is the launchd job's lock, so it could not overlap the scheduled sync. It reported 'sync complete: 0 created, 1 updated, 0 status changes, 0 imported, 0 inbox issues need triage, 0 failed operations' and set the same 195/135/84/4 field values.

Verification by GraphQL over all 195 Project items:
- Task ID equals the item's issue marker on all 195.
- Priority: 36 High, 67 Medium, 32 Low, and 60 empty for tasks without a priority.
- Backlog milestone: 40 v1 release, 44 Post-v1, and 111 empty for tasks without a milestone.
- Branch is set only for task-1.7, 84, 85 and 91, from the worktrees then present.

Views were created through the REST endpoint POST /users/djensenius/projectsV2/8/views, which takes the login; the numeric user ID returned 404. Filters were checked first with the REST items q parameter.
- View 2 'Status board': board grouped by Status, sorted by Priority.
- View 3 'Agent-ready': table, filter -status:Done -label:owner-gate,"blocked:owner",inbox, 13 items. That is the 25 not-Done tasks on this branch, less TASK-85 and TASK-91 (Done on their own branches), less the 10 owner-gate tasks.
- View 4 'Owner gates': table, filter label:owner-gate,"blocked:owner" -status:Done, 10 items.
- View 5 'v1 release': table, filter backlog-milestone:"v1 release", grouped by Status, 40 items. The quoted '"backlog milestone":' form matches 0 items, so the filter uses the hyphenated field name.
- The default 'View 1' table stays; the API has no view rename or delete.

Set the Project README (fields, labels, views, sync rules, inbox and owner-gate labels, link to AGENTS.md and owner-gates.md) and the short description through updateProjectV2. Project visibility is unchanged (private).

Note: until this config reaches main, the scheduled sync (main checkout config) neither writes nor clears these fields. After the merge it keeps them current, including clearing Branch when a worktree is removed.
<!-- SECTION:NOTES:END -->
