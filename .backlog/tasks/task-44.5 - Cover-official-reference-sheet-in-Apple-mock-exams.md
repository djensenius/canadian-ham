---
id: TASK-44.5
title: Cover official reference sheet in Apple mock exams
status: To Do
assignee: []
created_date: '2026-10-22 02:16'
labels:
  - apple
  - testing
dependencies:
  - TASK-44.4
parent_task_id: TASK-44
priority: medium
ordinal: 146000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-44.4 internal review noted that the reference-sheet integration is exercised from practice but not mock exams. Cover the actual Basic mock-exam tool path without changing approved accessibility exceptions or exposing hints in mock exams. Official assets remain internal-only and Advanced has no Basic sheet.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An Apple UI test opens the official sheet from a Basic mock exam and verifies page, zoom, accessible text and Study sheet fallback.
- [ ] #2 Using and closing the sheet preserves the current mock question, selected answer and exam progress.
- [ ] #3 Targeted iPhone and iPad checks and full-default accessibility audits pass, with only already-approved exception scopes if required.
- [ ] #4 Advanced mock exams still do not offer the Basic reference sheet and no mock exam offers hints.
<!-- AC:END -->
