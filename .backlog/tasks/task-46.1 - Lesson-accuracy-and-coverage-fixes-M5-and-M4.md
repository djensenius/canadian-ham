---
id: TASK-46.1
title: 'Lesson accuracy and coverage fixes: M5 and M4'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:57'
updated_date: '2026-10-12 15:14'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
priority: high
ordinal: 99000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apply the High findings (and Medium ones that are a sentence or two) from docs/lesson-review/m5-m4.md. Follow docs/teaching-guide.md and content/lessons/README.md. Verify every new fact against the bank and primary sources (RBR-4, RIC-1, NRC and so on), and check the reference-sheet claims the reviewer could not verify against the ISED reference PDF. Never restate ISED question or answer text. Fix matching explanation files where the review flags them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every High finding in docs/lesson-review/m5-m4.md is fixed (or declined with a recorded reason), with question IDs listed in the notes
- [ ] #2 Every covered question flagged as untaught or answer-key only is now taught with a reason
- [ ] #3 Coverage, quizzes, originality, explanations and links checks pass; the taught-facts check finds no regressions
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Verify m5-m4 findings against the active bank and reference sheet/source material before adding facts.
2. Make focused paragraph-level fixes in each affected M5/M4 lesson and any flagged quizzes without changing coverage or lesson structure.
3. Commit after each lesson slice, record finding-to-fix notes with question IDs and sources.
4. Run coverage, quiz, originality, explanation, link, web vitest, and content-swift checks; then finalize task ACs and Done.
<!-- SECTION:PLAN:END -->
