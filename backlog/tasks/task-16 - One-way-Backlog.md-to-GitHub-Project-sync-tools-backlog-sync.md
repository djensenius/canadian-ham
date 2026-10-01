---
id: TASK-16
title: One-way Backlog.md to GitHub Project sync (tools/backlog-sync)
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:33'
updated_date: '2026-10-01 02:42'
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
- [x] #1 Reads task state through the backlog CLI across all local worktrees and picks the most recently updated copy of each task
- [x] #2 Creates or updates one issue per task, matched by a hidden <!-- backlog:task-N --> marker plus a 'task-N:' title prefix
- [x] #3 Sets the Project Status field via GraphQL; Done closes the issue and reopening a task reopens it
- [x] #4 Idempotent (a second run changes nothing) with a --dry-run flag
- [x] #5 Inbox: open issues labelled 'inbox' become new To Do tasks (create only), then the label is removed and the marker added
- [x] #6 launchd plist and install steps are documented, and logs go to a file
- [x] #7 Go unit tests cover resolution, rendering, marker matching, diffing and inbox import without network access
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a standard-library-only Go module under tools/backlog-sync with CLI flag parsing, timestamped logging, subprocess adapters for gh/backlog/git, cross-worktree task collection and deterministic task resolution.
2. Implement issue body rendering, strict marker matching, REST issue/label diffing, project-v2 GraphQL status synchronization, dry-run/no-op behavior, and guarded inbox import through backlog task create.
3. Add unit tests with fakes for resolution, rendering, marker parsing, diff/idempotency, issue state/project status changes, inbox import/guards, and empty-main abort safety.
4. Add README and launchd plist documenting flags, cross-branch behavior, build/install/operation, and log file paths.
5. Validate with go vet, go test, go build, and one read-only dry run; then update Backlog task evidence without marking coordinator-only real-run/install evidence complete.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented tools/backlog-sync in commit 8cf6f84281c2b4e3d7ed95de05cdfad8362668de. Validation passed: cd tools/backlog-sync && go test ./...; go vet ./...; go build -o /tmp/backlog-sync .
Read-only dry-run against /Users/david/Developer/canadian-ham and GitHub Project 8 succeeded. Representative output: "would create issue task-1: v1 release", "would add new issue for task-1 to project", "would set project status for new issue task-16 <unset>→In Progress". Summary line: "sync complete: 26 created, 0 updated, 26 status changes, 0 imported".
Coordinator follow-up after review: perform the real GitHub sync and install/bootstrap the launchd plist if desired; I did not perform real writes or install launchd.

Correction: implementation commit SHA is 8cf6f8488aa62ab39146524f623fce407f4890e7; final task-update commit SHA is adfbc9b290642477a751e1f1bb3b831766345b4e.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added a standard-library Go backlog-sync module that scans local worktrees through backlog CLI JSON, resolves task copies deterministically, mirrors tasks to GitHub Issues/Project v2 through gh, supports guarded inbox imports and dry-run no-op behavior, and documents/builds a launchd job. Verified with unit tests, vet, build, and a read-only dry run.
<!-- SECTION:FINAL_SUMMARY:END -->
