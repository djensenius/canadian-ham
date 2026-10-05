---
id: TASK-12.13
title: 'Copy practice shows practice results, not exam grading'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-04 03:37'
updated_date: '2026-10-05 00:01'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect web and Apple Morse copy results/generator code and existing tests to locate mode-specific grading paths.
2. Update copy-practice result summaries to show accuracy plus wrong/missing/inserted counts only, while preserving exam pass/fail and mark displays.
3. Add or update web tests and Apple unit/UI tests for practice versus exam results and Swift generator constraint errors.
4. Run targeted tests while iterating, then the required final web checks and full Apple platform suites selected from apps/apple/project.yml; record per-test names/results in task notes.
5. Finalize task acceptance criteria with objective evidence, write final summary, mark Done, and commit the work.
<!-- SECTION:PLAN:END -->
