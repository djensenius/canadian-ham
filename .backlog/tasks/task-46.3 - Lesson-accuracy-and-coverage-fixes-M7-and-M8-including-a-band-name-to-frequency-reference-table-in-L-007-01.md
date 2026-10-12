---
id: TASK-46.3
title: >-
  Lesson accuracy and coverage fixes: M7 and M8 (including a band-name to
  frequency reference table in L-007-01)
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
ordinal: 101000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apply the High findings (and Medium ones that are a sentence or two) from docs/lesson-review/m7-m8.md. Follow docs/teaching-guide.md and content/lessons/README.md. Verify every new fact against the bank and primary sources (RBR-4, RIC-1, NRC and so on), and check the reference-sheet claims the reviewer could not verify against the ISED reference PDF. Never restate ISED question or answer text. Fix matching explanation files where the review flags them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every High finding in docs/lesson-review/m7-m8.md is fixed (or declined with a recorded reason), with question IDs listed in the notes
- [ ] #2 Every covered question flagged as untaught or answer-key only is now taught with a reason
- [ ] #3 Coverage, quizzes, originality, explanations and links checks pass; the taught-facts check finds no regressions
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read M7/M8 lessons, quizzes, explanations, generated bank, and primary/source references.\n2. Apply narrow prose fixes for each High finding plus approved quick Medium fixes, including compact band-name/frequency reference in L-007-01 and pointer from L-008-02.\n3. Update flagged explanation text and any quick concept-check replacements without restating official bank text.\n4. Run requested content/web/Swift checks, record findings-to-fixes and verified sources in task notes, check ACs, finalize Done.
<!-- SECTION:PLAN:END -->
