---
id: TASK-12.13
title: 'Copy practice shows practice results, not exam grading'
status: To Do
assignee: []
created_date: '2026-10-04 03:37'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.6
parent_task_id: TASK-12
priority: low
ordinal: 60000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: Copilot's final review of PR #123 noted that copy practice displays exam-style grading (pass/fail and the RIC-1 mark), which belongs to exam mode only and can confuse learners practising at their own speed. It also noted the Swift generator reports generation-constraint failures as invalid-speed errors.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Copy practice results show accuracy and the error breakdown (wrong, missing, inserted) without pass/fail or the exam mark; exam mode is unchanged; web and Apple tests cover both
- [ ] #2 Swift exam-text generation reports constraint failures with a distinct error (not invalid speed), matching TS, with a test
<!-- AC:END -->
