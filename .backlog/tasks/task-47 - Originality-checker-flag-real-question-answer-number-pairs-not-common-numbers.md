---
id: TASK-47
title: >-
  Originality checker: flag real question-answer number pairs, not common
  numbers
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 15:48'
updated_date: '2026-10-19 12:51'
labels:
  - content
dependencies: []
priority: medium
ordinal: 110000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
check-lesson-originality rejects any worked-example block whose only numeric tokens are common values (2, 3, 10, 0.5) because some bank answer contains them. This pushed workers to delete dB working (task-46.1) instead of teaching it. Refine the rule so it flags reuse of a bank question's distinctive number set together with its keyed answer, while allowing ubiquitous values and standard step values (3 dB, 10 dB, x 2, x 10) in worked examples.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A worked example using 10 dB + 3 dB steps passes; copying a bank question's numbers with its keyed answer still fails (self-test cases)
- [ ] #2 All lessons on main still pass; any newly allowed lines are reviewed
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the existing lesson-originality numeric heuristic and tests, then capture the current all-lessons checker output for before/after comparison.
2. Refine numeric-overlap so a keyed numeric answer only fails when the block also carries a distinctive question number set or distinctive question context, while preserving near-verbatim word-overlap checks.
3. Add fixture tests for allowed common dB/ratio step values and rejected real leaks, including multi-number and unit scenarios.
4. Run targeted content-tools tests plus the required repository checks, compare all-lesson results before/after, record reviewed disappearing findings in task notes, then finalize the Backlog task and PR.
<!-- SECTION:PLAN:END -->
