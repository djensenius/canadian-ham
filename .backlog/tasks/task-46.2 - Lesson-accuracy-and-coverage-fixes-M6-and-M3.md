---
id: TASK-46.2
title: 'Lesson accuracy and coverage fixes: M6 and M3'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:57'
updated_date: '2026-10-12 15:01'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
priority: high
ordinal: 100000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apply the High findings (and Medium ones that are a sentence or two) from docs/lesson-review/m6-m3.md. Follow docs/teaching-guide.md and content/lessons/README.md. Verify every new fact against the bank and primary sources (RBR-4, RIC-1, NRC and so on), and check the reference-sheet claims the reviewer could not verify against the ISED reference PDF. Never restate ISED question or answer text. Fix matching explanation files where the review flags them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every High finding in docs/lesson-review/m6-m3.md is fixed (or declined with a recorded reason), with question IDs listed in the notes
- [ ] #2 Every covered question flagged as untaught or answer-key only is now taught with a reason
- [ ] #3 Coverage, quizzes, originality, explanations and links checks pass; the taught-facts check finds no regressions
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Verify M6/M3 findings against the bank, extracted ISED reference material, and primary sources before changing prose.\n2. Patch only local lesson paragraphs, quizzes, and flagged explanations for High findings plus quick Medium fixes; skip structural follow-up tasks with recorded reasons.\n3. Run content/web/Swift checks, record finding-to-fix notes with sources and question IDs, then finalize task-46.2.
<!-- SECTION:PLAN:END -->
