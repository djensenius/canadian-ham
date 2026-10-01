---
id: TASK-16
title: One-way Backlog.md to GitHub Project sync (tools/backlog-sync)
status: To Do
assignee: []
created_date: '2026-10-01 02:33'
updated_date: '2026-10-01 02:34'
labels:
  - ci
  - tooling
milestone: m-0
dependencies: []
ordinal: 26000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
We moved tracking to Backlog.md, but the owner wants to see work on GitHub, and Backlog.md's own cross-branch view is limited: task list/view read only the current checkout, and backlog board lets the current checkout's copy win, so an In Progress task in another worktree still shows as To Do on main. A small local sync gives a GitHub Project that reflects the real state of every worktree on this machine, while keeping Backlog.md the single source of truth. GitHub stays read-only except for one narrow inbox path for proposing new tasks. Target: users/djensenius/projects/8.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Reads task state through the backlog CLI across all local worktrees and picks the most recently updated copy of each task
- [ ] #2 Creates or updates one issue per task, matched by a hidden <!-- backlog:task-N --> marker plus a 'task-N:' title prefix
- [ ] #3 Sets the Project Status field via GraphQL; Done closes the issue and reopening a task reopens it
- [ ] #4 Idempotent (a second run changes nothing) with a --dry-run flag
- [ ] #5 Inbox: open issues labelled 'inbox' become new To Do tasks (create only), then the label is removed and the marker added
- [ ] #6 launchd plist and install steps are documented, and logs go to a file
- [ ] #7 Go unit tests cover resolution, rendering, marker matching, diffing and inbox import without network access
<!-- AC:END -->
