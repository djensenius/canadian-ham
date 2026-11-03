---
id: TASK-83
title: Repair duplicate GitHub mirror issues and Project items
status: Done
assignee:
  - '@coordinator'
created_date: '2026-11-03T02:32:00Z'
updated_date: '2026-11-03T06:20:00Z'
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
- [x] #1 Each Backlog task maps to exactly one GitHub issue whose first line carries its `<!-- backlog:task-N -->` marker (the lowest-numbered existing copy); no other issue carries that marker
- [x] #2 Before any write, a dry-run map of every task to its canonical and duplicate issues is saved, and the repair verifies the paginated issue count against an independent total and refuses to run if they differ
- [x] #3 Every open duplicate is closed as a duplicate with a comment linking its canonical issue; closed duplicates keep their comments and link to the canonical issue
- [x] #4 Project #8 has exactly one item per canonical task issue (plus legacy and inbox issues), and closed canonical issues show Done
- [x] #5 The duplicate root cause is recorded in the task notes, with a follow-up guard against mass recreation filed as an issue in djensenius/backlog-sync
- [x] #6 A backlog-sync run after the repair reports 0 created and logs no duplicate-marker warnings
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read-only planner: list all issues (state=all), verify the count against the Search API total, group by first-line marker, keep the lowest number as canonical, and map Project #8 items; save mirror-plan.json.
2. Paced executor (7.5 s between writes, resumable log): for each duplicate, re-read it and its canonical; replace the duplicate marker line with a retired marker and a visible note linking the canonical issue; close open duplicates as duplicates with a comment.
3. Remove the duplicates' Project #8 items.
4. Re-run the planner to verify one marker per task and one item per canonical issue; confirm the next backlog-sync run reports 0 created and no duplicate-marker warnings.
5. Record the root cause and file the upstream guard in djensenius/backlog-sync.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Root cause (2026-11-03): the launchd job com.djensenius.canadian-ham.backlog-sync (backlog-sync 0eca8d7c, every 300 s, config in the main checkout) logged 'create issue' for every task right after normal scans on 2026-10-22 at 09:43, 10:04, 11:13, 11:39 and 12:59 EDT, plus smaller batches on 2026-10-01 and 2026-10-02. djensenius/backlog-sync's own mirror shows 10 copies per task, created in the same windows. So GitHub's issue listing (gh api --paginate --slurp issues?state=all) intermittently returned a successful response without the marked issues, and backlog-sync has no guard against mass creation. Filed djensenius/backlog-sync#114 (mass-creation guard, completeness check, pre-create marker search, quieter logs). Each run logged about 670 duplicate-marker warnings, so ~/Library/Logs/canadian-ham-backlog-sync.log (owner's file, left in place) has grown to 205 MB.

Dry-run plan (2026-11-03 02:35 UTC): 870 issues, matching the Search API total; 186 tasks; 668 duplicates (84 open, 41 with comments); 16 unmarked legacy T-xxx issues (#1-#16, closed, never on the Project, left as is); 851 Project items, 665 of them for duplicates. Every canonical issue is on the Project with Status matching its state. The pilot on #334 (task-1, canonical #17) checked out: CLOSED as DUPLICATE, marker retired, visible note and comment link #17. Full paced run started; 31 operations logged so far. The launchd sync was not paused: it edits only canonical (lowest-numbered) issues and the repair edits only higher-numbered duplicates, after re-reading each duplicate and confirming its canonical issue still has the marker.

Repair finished 2026-11-03 01:09 EST: 1,417 logged operations (668 duplicates retired, 84 open duplicates closed as DUPLICATE with a comment, 665 duplicate Project items deleted), 0 errors. Verification at 01:10 EST and 01:2x EST: 879 issues (paginated GraphQL count matches); 195 tasks, each with exactly one issue carrying its backlog marker; 0 duplicates; all 668 duplicates CLOSED, none lost comments, each body starts with a visible 'Duplicate mirror of #N' note linking its canonical issue; Project #8 has 195 items, one per canonical issue, 0 status mismatches, 0 issues with multiple items. The 684 unmarked issues are the 668 retired duplicates plus legacy #1-#16, none on the Project, as intended. No open inbox issues. The first full launchd sync after the repair (scan from 01:15:22, finished 01:19:40 EST) logged 'sync complete: 0 created, 0 updated, 0 status changes, 0 imported, 0 inbox issues need triage, 0 failed operations' and no warnings. A stack trace from an earlier scan (ENOENT uv_cwd) came from the TASK-89 worktree being removed mid-scan; it was harmless and later runs were clean.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Repaired the GitHub issue mirror after backlog-sync mass-created duplicate issues. Saved a dry-run plan first (870 issues, verified against the Search API total), then ran a paced, resumable repair that retired 668 duplicate issues (removed the marker, added a visible note linking the canonical issue, closed the 84 open ones as duplicates with a comment) and removed 665 duplicate Project #8 items. Now every Backlog task has exactly one marked issue and one Project item, statuses match, and a post-repair backlog-sync run created nothing and logged no duplicate warnings. Root cause (GitHub listing intermittently returning incomplete results and no mass-creation guard in backlog-sync) is recorded above and filed as djensenius/backlog-sync#114. Follow-up: TASK-84 adds Project fields and views.
<!-- SECTION:FINAL_SUMMARY:END -->
