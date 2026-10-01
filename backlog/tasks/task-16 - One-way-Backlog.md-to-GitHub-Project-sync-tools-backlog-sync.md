---
id: TASK-16
title: One-way Backlog.md to GitHub Project sync (tools/backlog-sync)
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:33'
updated_date: '2026-10-01 02:48'
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
- [ ] #3 Sets the Project Status field via GraphQL; Done closes the issue and reopening a task reopens it
- [ ] #4 Idempotent (a second run changes nothing) with a --dry-run flag
- [x] #5 Inbox: open issues labelled 'inbox' become new To Do tasks (create only), then the label is removed and the marker added
- [x] #6 launchd plist and install steps are documented, and logs go to a file
- [x] #7 Go unit tests cover resolution, rendering, marker matching, diffing and inbox import without network access
- [ ] #8 ArkhamHorror multi-repo placement maps Backlog project values to configured issue repos, searches all configured repos for existing markers, refuses all GitHub reads/writes outside the allowlist, and never duplicates issues when a task moves repos.
- [ ] #9 Nested task IDs such as TASK-1.2.7 normalize consistently for markers, title prefixes, branch ownership and matching.
- [ ] #10 Referenced GitHub issues can be adopted behind adoptReferencedIssues without adopting pull requests, mismatched repos, or issues carrying a different marker.
- [ ] #11 Managed-label sync supports exact/prefix/* allowlists, addAlways, priority labels, case-insensitive comparison, missing-label creation, and never touches the inbox label or unmanaged labels.
- [ ] #12 Optional extra Project fields for priority, milestone title, area, task ID and branch are updated only when configured and safe, with absent fields/options handled without data loss.
- [ ] #13 Configured sub-issues link child issues under parent issues when needed and warn once on unsupported cross-repo linking.
- [ ] #14 Inbox import scans every configured repo, guards against existing references before creating tasks, writes only from a clean main worktree, removes inbox labels, marks imported issues, and pushes main only when configured.
- [ ] #15 One binary works for multiple config files with per-config launchd install and per-config locking so independent configs can run side by side.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a standard-library-only Go module under tools/backlog-sync with CLI flag parsing, timestamped logging, subprocess adapters for gh/backlog/git, cross-worktree task collection and deterministic task resolution.
2. Implement issue body rendering, strict marker matching, REST issue/label diffing, project-v2 GraphQL status synchronization, dry-run/no-op behavior, and guarded inbox import through backlog task create.
3. Add unit tests with fakes for resolution, rendering, marker parsing, diff/idempotency, issue state/project status changes, inbox import/guards, and empty-main abort safety.
4. Add README and launchd plist documenting flags, cross-branch behavior, build/install/operation, and log file paths.
5. Validate with go vet, go test, go build, and one read-only dry run; then update Backlog task evidence without marking coordinator-only real-run/install evidence complete.

6. Fix review blockers and correctness/test gaps, generalize configuration for reuse in other repos, validate with tests/build/vet plus one read-only dry run, then leave task-16 In Progress for coordinator real-run evidence.

7. Generalize backlog-sync around JSON configuration, multi-repo allowlists, task-prefix normalization, managed labels/fields/sub-issues/inbox behavior, per-config locking and launchd install, then validate with unit tests/build/vet and read-only dry runs only.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented tools/backlog-sync in code commit 8cf6f8488aa62ab39146524f623fce407f4890e7; Backlog finalization commits follow it on branch task-16-backlog-sync. Validation passed: cd tools/backlog-sync && go test ./...; go vet ./...; go build -o /tmp/backlog-sync .
Read-only dry-run against /Users/david/Developer/canadian-ham and GitHub Project 8 succeeded. Representative output: "would create issue task-1: v1 release", "would add new issue for task-1 to project", "would set project status for new issue task-16 <unset>→In Progress". Summary line: "sync complete: 26 created, 0 updated, 26 status changes, 0 imported".
Coordinator follow-up after review: perform the real GitHub sync and install/bootstrap the launchd plist if desired; I did not perform real writes or install launchd.

Fix round 2 workflow correction: AC #3 and #4 are unchecked and remain pending until the coordinator performs a real GitHub sync/no-op verification; this round will provide only read-only dry-run evidence.

Round 2 start: AC #3 and #4 remain unchecked pending the coordinator's real-run status/no-op evidence. ArkhamHorror scope is owner-approved; adding explicit ACs before implementation.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added a standard-library Go backlog-sync module that scans local worktrees through backlog CLI JSON, resolves task copies deterministically, mirrors tasks to GitHub Issues/Project v2 through gh, supports guarded inbox imports and dry-run no-op behavior, and documents/builds a launchd job. Verified with unit tests, vet, build, and a read-only dry run.
<!-- SECTION:FINAL_SUMMARY:END -->
