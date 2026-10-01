---
id: TASK-18
title: 'backlog-sync: close review follow-ups before multi-repo inbox use'
status: Done
assignee: []
created_date: '2026-10-01 13:20'
updated_date: '2026-10-01 15:56'
labels:
  - ci
  - tooling
milestone: m-0
dependencies: []
references:
  - /tmp/ch-reviews/sync3.md
  - /tmp/ch-reviews/t17-2.md
ordinal: 28000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The task-16 and task-17 reviews approved the syncer with non-blocking notes. Most are rare edge cases, but a few could cause a duplicate marked issue or a whole-run abort once ArkhamHorror's multi-repo inbox and adoption are live, so they should be closed before that use grows.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An inbox-labelled issue that already carries a marker only becomes canonical when it is the issue the marker index chose; otherwise only the inbox label is removed
- [ ] #2 An inbox-created task whose ID already has a marked issue (e.g. an ID reused after a hand-deleted task file) gets no second marker; the run warns and only strips the label
- [ ] #3 The inbox import guards the marker-plus-body size against GitHub's limit and records a per-task failure instead of aborting the run
- [ ] #4 Expected sub-issue rejections warn once per run (a fixed warn-once key), and the rejection matching is confirmed against GitHub's real error responses or documented as unverified
- [ ] #5 RemoveSubIssue checks the parent repo against the allowlist inside the client
- [ ] #6 Tests cover the remove-error path, a real captured task list --json fixture (pagination fields) and a line-boundary truncation case that would fail without the line-boundary logic
- [ ] #7 A dry run is confirmed to write nothing to git (FETCH_HEAD and refs), or the README documents the backlog CLI fetch behaviour
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision for this repository: all acceptance criteria/follow-ups for this task moved to the standalone djensenius/backlog-sync repository as task-8, so this Canadian Ham task is closed without checking its criteria here.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Closed without local implementation because all backlog-sync follow-ups moved to djensenius/backlog-sync task-8; acceptance criteria remain unchecked in this repository by owner instruction.
<!-- SECTION:FINAL_SUMMARY:END -->
