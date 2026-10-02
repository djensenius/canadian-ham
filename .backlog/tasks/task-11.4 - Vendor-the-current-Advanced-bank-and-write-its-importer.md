---
id: TASK-11.4
title: Vendor the current Advanced bank and write its importer
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
labels:
  - content
milestone: m-1
dependencies:
  - TASK-11.2
  - TASK-11.3
parent_task_id: TASK-11
priority: medium
ordinal: 36000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: multi-course practice needs the official Advanced bank as generated data, imported with the same verbatim guarantees as Basic. See docs/proposals/advanced-course.md (owner decisions in task-11 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The current Advanced ZIP and PDFs are vendored verbatim under content/sources/ised/advanced-<title-page-date>/ with SHA-256 recorded, and the title-page date is the bank ID
- [ ] #2 The importer decodes the legacy encoding explicitly, handles the header row, and validates 549 questions, 7 categories and 50 subsections against the live file
- [ ] #3 A fixture covers a 50-question exam and no-Honours scoring; pnpm import:check and pnpm check:schemas pass
<!-- AC:END -->
