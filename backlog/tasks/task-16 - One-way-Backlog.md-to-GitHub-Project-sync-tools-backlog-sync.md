---
id: TASK-16
title: One-way Backlog.md to GitHub Project sync (tools/backlog-sync)
status: To Do
assignee: []
created_date: '2026-10-01 02:33'
labels:
  - ci
  - tooling
milestone: m-0
dependencies: []
ordinal: 26000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Go command that mirrors Backlog.md tasks one-way to GitHub issues and Project #8 (users/djensenius/projects/8), plus an inbox import path (issues labelled 'inbox' become new tasks). Runs on this machine via launchd every few minutes. Backlog.md is the source of truth; the tool never writes into backlog/ except creating inbox tasks through the CLI.
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
