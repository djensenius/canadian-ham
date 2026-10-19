---
id: TASK-46.10
title: >-
  Split overloaded lessons and move coverage (L-005-04, M8, B-001-014, L-004-03
  first in M4)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:58'
updated_date: '2026-10-19 18:35'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
priority: medium
ordinal: 108000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Needs an owner decision; see docs/lesson-review/README.md. Once decided, add the implementation plan and acceptance criteria, or close as declined.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Owner decision recorded
- [ ] #2 Splits and moves done with coverage, quizzes, explanations, figures and links updated; saved lesson progress migrates on web and Apple
- [ ] #3 L-005-04 and M8 are split into smaller lessons, B-001-014 moves to L-001-05, and L-004-03 comes first in M4
- [ ] #4 Lesson coverage shows every question still covered exactly as intended, and all content checks pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the current lesson/review files, existing lesson IDs, quizzes, explanations, hints, figures, links, and progress-storage code paths.\n2. Restructure the affected lessons mechanically: split L-005-04 into AC/dB and reactance/resonance lessons, split M8 receiver/transmitter lessons, move B-001-014 coverage into L-001-05, and reorder M4 so L-004-03 is taught first.\n3. Update dependent content metadata and references: quizzes, explanations lesson links, hint lessonLink anchors, figure directives, cross-links, schemas, and tests that name changed lesson IDs/titles.\n4. Add explicit old-to-new lesson ID migration for web and Apple progress/quiz references, including import/load tests and documented split behavior.\n5. Run the requested content, web, and targeted Apple checks; record evidence, finalize the Backlog task, commit, push, and open the PR with migration notes.

6. Finish the inherited test decoder helper and add only the two version-validation localizations, verifying the catalogue preserves origin/main entries and key order. Run full macOS units, the eight affected iOS Learn/figure tests, and requested web/content checks; record per-test evidence before finalization and PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision 2026-10-12: YES. Split L-005-04 (AC and dB vs reactance and resonance), split M8 (receiver-side vs transmitter-side), move B-001-014 to L-001-05, teach L-004-03 first in M4. Lesson IDs may change; migrate saved progress and quiz references. Start after the 38.x figure branches merge.

Owner decision 2026-10-12: yes, do it, including migrating saved lesson progress for moved or split lessons.
<!-- SECTION:NOTES:END -->
