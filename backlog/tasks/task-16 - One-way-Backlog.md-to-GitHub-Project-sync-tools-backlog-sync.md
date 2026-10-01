---
id: TASK-16
title: One-way Backlog.md to GitHub Project sync (tools/backlog-sync)
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:33'
updated_date: '2026-10-01 02:36'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a standard-library-only Go module under tools/backlog-sync with CLI flag parsing, timestamped logging, subprocess adapters for gh/backlog/git, cross-worktree task collection and deterministic task resolution.
2. Implement issue body rendering, strict marker matching, REST issue/label diffing, project-v2 GraphQL status synchronization, dry-run/no-op behavior, and guarded inbox import through backlog task create.
3. Add unit tests with fakes for resolution, rendering, marker parsing, diff/idempotency, issue state/project status changes, inbox import/guards, and empty-main abort safety.
4. Add README and launchd plist documenting flags, cross-branch behavior, build/install/operation, and log file paths.
5. Validate with go vet, go test, go build, and one read-only dry run; then update Backlog task evidence without marking coordinator-only real-run/install evidence complete.
<!-- SECTION:PLAN:END -->
