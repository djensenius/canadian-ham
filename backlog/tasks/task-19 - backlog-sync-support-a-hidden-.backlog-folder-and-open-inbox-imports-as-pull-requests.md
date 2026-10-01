---
id: TASK-19
title: >-
  backlog-sync: support a hidden .backlog folder and open inbox imports as pull
  requests
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 13:51'
updated_date: '2026-10-01 13:51'
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
- [ ] #1 Worktree scanning finds the Backlog folder wherever the project's Backlog.md config puts it (backlog/, .backlog/ or a custom path), using the CLI or the config file read-only, with tests
- [ ] #2 A config option selects the inbox mode: 'push' (current behaviour) or 'pr' (create the task on a new branch such as inbox/<repo>-<N> from origin's main in a temporary worktree, push the branch, open a PR titled '<task-id>: <title>', then link and unlabel the issue)
- [ ] #3 In 'pr' mode nothing is committed to or pushed to main, the temporary worktree is removed, and a re-run never opens a second PR for the same issue (it finds the open PR or the task reference)
- [ ] #4 canadian-ham's .backlog-sync.json uses 'pr' mode; the README documents both modes and the dry-run output shows the planned PR
- [ ] #5 go test covers both modes, including the crash-replay case for 'pr' mode, without network access
<!-- AC:END -->
