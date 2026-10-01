---
id: TASK-19
title: 'backlog-sync: support a hidden .backlog folder and a manual inbox mode'
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 13:51'
updated_date: '2026-10-01 14:58'
labels:
  - ci
  - tooling
milestone: m-0
dependencies: []
ordinal: 29000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The owner moved to a pull-request-only workflow: nothing may be pushed to main directly. The syncer's inbox import commits a new task on main and pushes it, which would bypass that. An automated 'open the import as a PR' mode was tried over three review rounds and kept failing on crash recovery (temporary worktrees, stale remote refs, ID collisions), so the owner chose the simpler design: in PR-only repos the syncer only reports inbox issues and the coordinator triages them into normal task PRs. The project is also moving its Backlog folder from backlog/ to .backlog/, which the syncer must find. ArkhamHorror (a meta repo with direct commits) keeps the existing push mode.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Worktree scanning finds the Backlog folder wherever the project's Backlog.md config puts it (backlog/, .backlog/ or a custom path), using the CLI or the config file read-only, with tests
- [x] #2 inbox.mode accepts 'push' (current behaviour, unchanged for ArkhamHorror) and 'manual' (report open inbox-labelled issues in the log and summary, and never write anything for them: no task, label, marker, branch or push); invalid modes are rejected
- [x] #3 All 'pr'-mode code, config and docs from earlier rounds are removed
- [x] #4 canadian-ham's .backlog-sync.json uses 'manual' mode; the README documents both modes, and a dry run lists any open inbox issues as 'needs triage'
- [x] #5 go test covers both modes (manual mode makes zero writes with an inbox issue present) without network access
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Teach backlog-sync to discover the Backlog data directory per worktree from Backlog.md config (supporting backlog/, .backlog/, and custom paths) and cover scanning with tests.
2. Replace the legacy inbox push boolean with a configurable inbox.mode that preserves push mode and adds pr mode using temporary worktrees, explicit allowed gh repos, duplicate-PR detection, branch push, PR creation, and cleanup.
3. Update Canadian Ham config and README examples for pr mode; add no-network fake tests for push/pr/crash-replay behavior and dry-run PR logging.
4. Validate with go vet, go test ./..., go build, and one read-only Canadian Ham dry run saved to /tmp/ch-dry-task19.txt, then finalize task-19.

Round 2 fix steps:
1. Keep inbox labels while PR-mode imports have open PRs; after merge, let the reference path mark, retitle, and unlabel the original issue without creating duplicates; add merge-simulation tests and README notes for closed-unmerged PR retry.
2. Make PR-mode crash replay safe: prune stale worktrees, use detached temp worktrees from origin/<main>, push HEAD to the inbox branch with --force-with-lease, reuse existing remote branches without PRs, delete stale local branches, and skip temp inbox worktrees during collection.
3. Add focused tests for invalid inbox.mode, non-allowlisted origins, temp cleanup failure paths, stale local branch handling, start point/base selection, and PR lookup by branch/marker.
4. Document the autoCommit expectation/failure behavior, validate with the requested Go checks and one read-only dry run to /tmp/ch-dry-task19b.txt, then check only evidence-backed ACs and finalize appropriately.

Round 3 fix steps:
1. Resolve symlink-real temp/worktree paths and remove leftover PR-mode inbox worktrees before collection, with macOS-style symlink tests.
2. Harden inbox branch fetch/push leases using ls-remote SHAs/empty leases and + refspecs, and isolate per-issue PR-mode failures so sync continues.
3. Prevent checked-out PR branches from linking issues before merge, check new task IDs against origin/main before PR creation, document collision/rejection behavior, and revalidate with Go checks plus Canadian Ham dry run.

Round 4 rescope steps: 1. Remove all inbox pr-mode implementation, config fields, tests, and README text while preserving existing push behavior and Backlog data-dir discovery. 2. Add report-only inbox.mode manual that logs each open inbox-labelled issue as needing triage, summarizes the count, and performs zero writes for those issues; reject invalid modes. 3. Update Canadian Ham config to manual and README mode docs, add no-network tests for manual zero-writes/reporting plus unchanged push behavior, then run requested validation and finalize with evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Backlog directory discovery for backlog/, .backlog/, and custom Backlog data dirs; added inbox.mode push/pr with temp-worktree PR imports, explicit root repo allowlist checks, duplicate PR detection, and cleanup. Validation passed: cd tools/backlog-sync && go vet ./... && go test ./... && go build -o /tmp/backlog-sync-19 .; read-only dry run saved to /tmp/ch-dry-task19.txt (no current inbox issues, so no real planned PR; unit test covers planned PR dry-run output).

Round 2 fixes implemented: PR mode now keeps the inbox label while an import PR is open, links/retitles/unlabels the original issue after the task reaches main, reuses existing open PRs, recovers by opening a PR from an already-pushed inbox branch, prunes stale worktrees, skips temp inbox worktrees during collection, creates detached temp worktrees from origin/<main>, pushes HEAD:refs/heads/<branch> with --force-with-lease, deletes stale local inbox branches, and fails clearly if Backlog autoCommit leaves temp-worktree changes. Added no-network tests for merge linking/no duplicate issue, branch-pushed/no-PR replay, stale local branch cleanup, temp cleanup on failure, invalid inbox.mode, origin allowlist refusal, temp worktree skipping, ambiguous non-root Backlog folders, start point/base selection, and PR lookup by head plus marker. Validation passed: cd tools/backlog-sync && go vet ./... && go test ./... && go build -o /tmp/backlog-sync-19b . && /tmp/backlog-sync-19b --config /Users/david/Developer/canadian-ham/.backlog-sync.json --dry-run > /tmp/ch-dry-task19b.txt. The live dry run had no inbox issue, so it could not show a planned PR line for AC #4; /tmp/ch-dry-task19b.txt records the read-only run and AC #4 live planned-PR evidence is left for the coordinator.

Owner decision (2026-10-01): replace the 'pr' inbox mode with a report-only 'manual' mode after three review rounds (reviews t19-1 and t19-2 in ~/.cache/canadian-ham-reviews). The coordinator triages inbox issues at session start into normal task PRs.

Round 4 rescope implemented: removed the failed inbox 'pr' mode and its temp-worktree/branch/PR helpers and tests; added inbox.mode manual as report-only triage logging plus summary counts while preserving push mode. Validation passed: cd tools/backlog-sync && go vet ./... && go test ./... && go build -o /tmp/backlog-sync-19d .; read-only dry run against /Users/david/Developer/canadian-ham saved to /tmp/ch-dry-task19d.txt (0 current inbox issues, summary reports 0 inbox issues need triage). Verified git diff main -- tools/backlog-sync has no pr-mode helper terms.

Review cleanup: merged main, removed dead sync_test scaffolding, clarified manual inbox triage label handling, and reran Go validation.

Copilot review fix: DiscoverBacklogDir now honors root backlog.config.yml backlog_directory before folder-local and bounded-search fallbacks.

Second Copilot review fix: removed bounded Backlog directory search, aligned discovery with CLI-visible root config/backlog/.backlog layouts, added requested fallbacks/tests, and validation passed (go vet/test/build plus dry run with 0 failed ops).

Copilot third review fix: manual inbox mode now skips marked inbox issues and claims unmarked inbox issues so adoption never writes to them.

Follow-up review notes: restored manual inbox label guidance, skipped sub-issue writes for manual inbox triage parents, and added project-add/test coverage.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Rescoped backlog-sync inbox handling: kept Backlog data-dir discovery, removed the failed inbox PR mode and helpers, added report-only inbox.mode manual, kept push mode behavior, set Canadian Ham config to manual, and documented both modes. Verified with no-network Go tests covering push/manual/invalid modes, go vet ./..., go test ./..., go build -o /tmp/backlog-sync-19d ., git diff main -- tools/backlog-sync PR-helper grep, and a read-only Canadian Ham dry run saved to /tmp/ch-dry-task19d.txt.
<!-- SECTION:FINAL_SUMMARY:END -->
