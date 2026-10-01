---
id: TASK-19
title: >-
  backlog-sync: support a hidden .backlog folder and open inbox imports as pull
  requests
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 13:51'
updated_date: '2026-10-01 13:58'
labels:
  - ci
  - tooling
milestone: m-0
dependencies: []
ordinal: 29000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The owner moved to a pull-request-only workflow: nothing may be pushed to main directly, and every change goes through Copilot review and CI. The syncer's inbox import currently commits a new task on main and pushes it, which would bypass that. The project is also moving its Backlog folder from backlog/ to .backlog/, and the syncer currently assumes a 'backlog/' directory when it scans worktrees. ArkhamHorror (a separate meta repo with direct commits) still needs the existing push behaviour, so the mode must be configurable.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Worktree scanning finds the Backlog folder wherever the project's Backlog.md config puts it (backlog/, .backlog/ or a custom path), using the CLI or the config file read-only, with tests
- [x] #2 A config option selects the inbox mode: 'push' (current behaviour) or 'pr' (create the task on a new branch such as inbox/<repo>-<N> from origin's main in a temporary worktree, push the branch, open a PR titled '<task-id>: <title>', then link and unlabel the issue)
- [x] #3 In 'pr' mode nothing is committed to or pushed to main, the temporary worktree is removed, and a re-run never opens a second PR for the same issue (it finds the open PR or the task reference)
- [x] #4 canadian-ham's .backlog-sync.json uses 'pr' mode; the README documents both modes and the dry-run output shows the planned PR
- [x] #5 go test covers both modes, including the crash-replay case for 'pr' mode, without network access
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Teach backlog-sync to discover the Backlog data directory per worktree from Backlog.md config (supporting backlog/, .backlog/, and custom paths) and cover scanning with tests.\n2. Replace the legacy inbox push boolean with a configurable inbox.mode that preserves push mode and adds pr mode using temporary worktrees, explicit allowed gh repos, duplicate-PR detection, branch push, PR creation, and cleanup.\n3. Update Canadian Ham config and README examples for pr mode; add no-network fake tests for push/pr/crash-replay behavior and dry-run PR logging.\n4. Validate with go vet, go test ./..., go build, and one read-only Canadian Ham dry run saved to /tmp/ch-dry-task19.txt, then finalize task-19.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Backlog directory discovery for backlog/, .backlog/, and custom Backlog data dirs; added inbox.mode push/pr with temp-worktree PR imports, explicit root repo allowlist checks, duplicate PR detection, and cleanup. Validation passed: cd tools/backlog-sync && go vet ./... && go test ./... && go build -o /tmp/backlog-sync-19 .; read-only dry run saved to /tmp/ch-dry-task19.txt (no current inbox issues, so no real planned PR; unit test covers planned PR dry-run output).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
backlog-sync now discovers Backlog data directories instead of assuming backlog/, supports configurable inbox.mode push/pr, opens inbox imports as explicit-repo PRs from temporary worktrees with replay protection, and documents/configures Canadian Ham for pr mode. Verified with go vet, go test ./..., go build, and a read-only dry run against /Users/david/Developer/canadian-ham.
<!-- SECTION:FINAL_SUMMARY:END -->
