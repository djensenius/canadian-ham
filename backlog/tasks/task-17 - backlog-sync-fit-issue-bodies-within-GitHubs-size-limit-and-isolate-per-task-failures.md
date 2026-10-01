---
id: TASK-17
title: >-
  backlog-sync: fit issue bodies within GitHub's size limit and isolate per-task
  failures
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 12:57'
updated_date: '2026-10-01 13:03'
labels:
  - ci
  - tooling
milestone: m-0
dependencies: []
ordinal: 27000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The first real sync run aborted at task-16: its implementation notes (about 75,000 characters of pasted dry-run output) made the rendered issue body exceed GitHub's 65,536-character limit (HTTP 422). Because one failed issue aborts the whole run, the remaining tasks, Project items and statuses were never synced, and any long task would block the mirror for every repo in the config (including ArkhamHorror).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Rendered issue bodies never exceed GitHub's limit: long sections (notes first, then plan, then description) are truncated deterministically with a visible note pointing to 'backlog task view <id>', so the output is identical on every run
- [x] #2 A failure on one task (create, update, project or field write) is logged with the task ID and the run continues with the other tasks; the run still exits non-zero and reports the failure count in the summary line
- [x] #3 Unit tests cover the truncation boundary (exactly at, just over and far over the limit, including multi-byte characters) and per-task failure isolation
- [ ] #4 A real run against canadian-ham completes, and a second run reports 0 created, 0 updated and 0 status changes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add deterministic issue-body fitting in tools/backlog-sync/render.go using a 60,000-rune budget so GitHub's 65,536-character body limit has margin; keep the marker/metadata/acceptance criteria intact and shrink implementation notes, then plan, then description, then final summary at line boundaries where possible with a visible omitted-character marker pointing to backlog task view <id> --plain.\n2. Update tools/backlog-sync/sync.go to isolate per-task write failures during create/update/project field/sub-issue work: log each failure with the task ID, count it, continue remaining tasks, include the failure count in the summary, and return a non-zero error after the run when failures occurred while keeping pre-write global errors aborting.\n3. Add unit tests for truncation boundaries including multi-byte runes and for one task create failure not blocking other tasks; run gofmt, go test ./..., go vet ./..., go build, and the required dry-run only.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented tools/backlog-sync issue-body truncation using a 60,000-rune budget with deterministic shrink order (implementation notes, plan, description, final summary) and task-view markers. Isolated per-task sync write failures with task-ID logs, failure counts in the summary, and non-zero return when failures occur. Validation passed: cd tools/backlog-sync && go vet ./... && go test ./... && go build -o /tmp/backlog-sync-17 .; dry-run saved to /tmp/ch-dry-task17.txt with summary 'sync complete: 10 created, 4 updated, 27 status changes, 0 imported, 0 failed'. AC #4 intentionally left unchecked for the coordinator's real run.
<!-- SECTION:NOTES:END -->
