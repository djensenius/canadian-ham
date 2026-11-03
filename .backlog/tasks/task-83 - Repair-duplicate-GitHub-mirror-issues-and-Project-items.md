---
id: TASK-83
title: Repair duplicate GitHub mirror issues and Project items
status: To Do
assignee: []
created_date: '2026-11-03T02:32:00Z'
labels:
  - tooling
  - github
dependencies: []
priority: high
type: chore
ordinal: 166000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
backlog-sync mirrors 186 Backlog tasks into 854 marked GitHub issues: 668 surplus copies (84 open, 584 closed) were created in batches, most recently five times on 2026-10-22, because a launchd sync run received an issue listing with no marker matches but no error and recreated every task. Every run now logs about 670 duplicate-marker warnings, and Project #8 contains duplicate items, stale statuses on closed issues, and missing canonical issues. Keep the lowest-numbered issue per task as canonical, retire the duplicates without losing their comments, and leave the Project with one item per task.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Each Backlog task maps to exactly one GitHub issue whose first line carries its `<!-- backlog:task-N -->` marker (the lowest-numbered existing copy); no other issue carries that marker
- [ ] #2 Every open duplicate is closed as a duplicate with a comment linking its canonical issue; closed duplicates keep their comments and link to the canonical issue
- [ ] #3 Project #8 has exactly one item per canonical task issue (plus legacy and inbox issues), and closed canonical issues show Done
- [ ] #4 The duplicate root cause is recorded in the task notes, with a follow-up filed for a backlog-sync guard against mass recreation
- [ ] #5 A backlog-sync run after the repair reports 0 created and logs no duplicate-marker warnings
<!-- AC:END -->
