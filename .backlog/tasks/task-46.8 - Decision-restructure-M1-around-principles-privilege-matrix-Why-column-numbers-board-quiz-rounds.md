---
id: TASK-46.8
title: >-
  Restructure M1 around principles (privilege matrix, Why column, numbers board,
  quiz rounds)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:58'
updated_date: '2026-10-21 15:04'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
priority: medium
ordinal: 106000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Needs an owner decision; see docs/lesson-review/README.md. Once decided, add the implementation plan and acceptance criteria, or close as declined.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Owner decision recorded
- [ ] #2 M1 lessons are organised around stated principles with the privilege matrix, Why column and numbers board; every covered question remains taught (taught-facts check)
- [ ] #3 Lesson quizzes are delivered in section-sized rounds on web and Apple
- [ ] #4 Lesson coverage, originality, quiz and link checks pass, and a taught-facts comparison shows no fact was lost
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Split section-sized quiz rounds into a UI subtask depending on TASK-50.14.2; keep this branch content-only.
2. Inventory every M1 taught fact before rewriting and retain the principles-led reference style with exhaustive official quizzes and no concept checks.
3. Rewrite each lesson around named principles, short Why columns, a shared privilege matrix across L-001-02/L-001-04 and an M1 numbers board; preserve front matter, coverage, figures and quiz IDs. Retarget B-001 hint anchors and keep originality allowlist entries current. Commit and push after each lesson.
4. Record before/after taught-facts evidence, run requested content/package/Swift checks, check ACs 2 and 4 only, and leave the parent In Progress for UI rounds.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision 2026-10-12: YES. Restructure M1 around a few generating principles, a qualification-by-privilege matrix spanning L-001-02/L-001-04, a short Why column, an M1 numbers board, and quiz rounds per section. Start after the 38.x figure branches merge (they edit M1 lessons).

Owner decision 2026-10-12: yes, do it. See docs/lesson-review/README.md and docs/lesson-review/m1-m2.md.

Created TASK-46.8.1 for web/Apple quiz rounds, dependent on TASK-50.14.2. Format decision: retain principles-led M1 reference-only rules and exhaustive official-only quizzes; no concept checks. Captured all baseline reference facts before rewriting. L-001-01 and L-001-02 rewritten and pushed separately; numbers board and station-work qualification matrix added, hint anchors retargeted, originality/hints/coverage checks green so far.
<!-- SECTION:NOTES:END -->
