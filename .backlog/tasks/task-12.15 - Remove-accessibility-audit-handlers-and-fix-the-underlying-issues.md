---
id: TASK-12.15
title: Remove accessibility audit handlers and fix the underlying issues
status: To Do
assignee: []
created_date: '2026-10-04 07:02'
labels:
  - apple
  - accessibility
  - morse
milestone: m-1
dependencies:
  - TASK-12.5
parent_task_id: TASK-12
priority: high
ordinal: 62000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the project rule is full default accessibility audits with no handlers or exclusions. Two Morse audits now filter issues: the graded copy/exam diff audit ignores contrast issues on morse-diff tokens (from task-12.6), which can hide real contrast failures in the error highlights, and the course-path audit ignores Dynamic Type issues on lesson labels (from task-12.5). Both need the underlying issues fixed so the audits can run unfiltered.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 No performAccessibilityAudit call in any UI test target uses an issue handler or a restricted audit-type set; all audits run the full default audit
- [ ] #2 The graded Morse diff tokens meet contrast in light and dark (colours from adaptive design tokens, not colour alone) and the course path passes Dynamic Type without filtering
- [ ] #3 The iOS light and dark audits for the Morse course path, lesson, summary and graded diff pass; the iOS and macOS suites pass
<!-- AC:END -->
