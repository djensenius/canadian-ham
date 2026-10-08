---
id: TASK-11.10
title: Verify official French Advanced category names
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 17:03'
updated_date: '2026-10-08 12:09'
labels:
  - content
  - l10n
milestone: m-1
dependencies:
  - TASK-11.4
parent_task_id: TASK-11
ordinal: 56000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The Advanced bank importer currently stores null French category names with pending-verification notes to avoid guessing official wording. Future Advanced course/app work needs verified French category names from the official CIR-3 headings, following the task-26 rule that official labels are used only when sourced rather than inferred.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Each Advanced category in content/categories-advanced.json has an official French name verified against CIR-3 headings or an explicit documented reason for remaining pending
- [ ] #2 The source and verification method for each French category name are recorded in code comments, task notes, or project documentation
- [ ] #3 Schema/import checks and category negative tests pass after any category metadata updates
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Update Advanced category metadata with the seven audited official French names and source citations from CIR-3 §5.3 plus the ISED Exam Generator.\n2. Add or update negative/category tests only as needed to prove metadata and pending-status behavior.\n3. Run schema/import/category checks, then finalize with file:line evidence and audited source notes.
<!-- SECTION:PLAN:END -->
