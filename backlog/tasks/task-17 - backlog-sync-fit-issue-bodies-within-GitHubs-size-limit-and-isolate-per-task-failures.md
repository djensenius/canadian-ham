---
id: TASK-17
title: >-
  backlog-sync: fit issue bodies within GitHub's size limit and isolate per-task
  failures
status: To Do
assignee: []
created_date: '2026-10-01 12:57'
labels:
  - ci
  - tooling
milestone: m-0
dependencies:
  - TASK-16
ordinal: 27000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The first real sync run aborted at task-16: its implementation notes (about 75,000 characters of pasted dry-run output) made the rendered issue body exceed GitHub's 65,536-character limit (HTTP 422). Because one failed issue aborts the whole run, the remaining tasks, Project items and statuses were never synced, and any long task would block the mirror for every repo in the config (including ArkhamHorror).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Rendered issue bodies never exceed GitHub's limit: long sections (notes first, then plan, then description) are truncated deterministically with a visible note pointing to 'backlog task view <id>', so the output is identical on every run
- [ ] #2 A failure on one task (create, update, project or field write) is logged with the task ID and the run continues with the other tasks; the run still exits non-zero and reports the failure count in the summary line
- [ ] #3 Unit tests cover the truncation boundary (exactly at, just over and far over the limit, including multi-byte characters) and per-task failure isolation
- [ ] #4 A real run against canadian-ham completes, and a second run reports 0 created, 0 updated and 0 status changes
<!-- AC:END -->
