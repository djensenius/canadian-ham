---
id: TASK-11.1
title: Source-check the Advanced course brief and record decisions
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 22:38'
labels:
  - content
  - docs
milestone: m-1
dependencies: []
parent_task_id: TASK-11
ordinal: 19000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Verify the claims and citations in the Advanced course research brief (bank format, structure, pass mark, privileges, revision timeline), commit it to docs/proposals/advanced-course.md, and record the owner's decisions (multi-bank now vs content later; one app with a course switcher vs a separate app).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every factual claim in the brief has a verified source or is marked unverified
- [x] #2 The brief is committed under docs/proposals/
- [ ] #3 The owner's decisions are recorded in the parent task notes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Copy the source-checked Advanced brief into docs/proposals with only light formatting/link cleanup.
2. Ensure proposals README exists and links to the brief without breaking existing links.
3. Run pnpm check:links, record verification summary/open owner decisions in task notes, check only proven ACs, and commit the changes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Validation: committed docs/proposals/advanced-course.md and docs/proposals/README.md in commit 0a43865; pnpm check:links passed. Verification summary table has 38 claims: Verified 22, Corrected 10, Unverified 4, New finding 1, Not applicable 1. Open owner decisions (AC #3 left unchecked): launch timing vs ISED rewrite/review date; one app with course switcher vs separate Advanced app; confirm and send ISED permission-request scope for current/future Advanced and adapted/structured formats; approve or decline extending the interim private-development policy to Advanced source files.
<!-- SECTION:NOTES:END -->
