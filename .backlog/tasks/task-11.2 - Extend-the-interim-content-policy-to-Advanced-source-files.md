---
id: TASK-11.2
title: Extend the interim content policy to Advanced source files
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
labels:
  - content
  - docs
milestone: m-1
dependencies: []
parent_task_id: TASK-11
priority: medium
ordinal: 34000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner approved (2026-10-02) extending the interim private-development policy so verbatim Advanced bank files can be vendored. Advanced ingestion is blocked until docs/content-licensing.md says so. See docs/proposals/advanced-course.md (owner decisions in task-11 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 docs/content-licensing.md covers verbatim Advanced source files under content/sources/ised/advanced-*/ with the same conditions as Basic (private repo, attribution, permission tracked by task-1.1)
- [ ] #2 AGENTS.md project notes no longer say the Basic 2025 bank is the only allowed source, and name the Advanced exception
- [ ] #3 pnpm check:links passes
<!-- AC:END -->
