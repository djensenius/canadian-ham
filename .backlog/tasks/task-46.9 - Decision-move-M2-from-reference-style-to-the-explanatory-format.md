---
id: TASK-46.9
title: Move M2 from reference style to the explanatory format
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:58'
updated_date: '2026-10-20 13:04'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
priority: medium
ordinal: 107000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Needs an owner decision; see docs/lesson-review/README.md. Once decided, add the implementation plan and acceptance criteria, or close as declined.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Owner decision recorded
- [ ] #2 M2 lessons use the explanatory format from content/lessons/README.md with no loss of covered facts
- [ ] #3 Lesson coverage, originality, quiz and link checks pass, and a taught-facts comparison shows no fact was lost
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Extract the taught facts and all 99 covered bank-question IDs from the four current M2 lessons into a review ledger before rewriting; preserve IDs, front matter, figure directives, and official quiz mappings.
2. Rewrite each lesson around concepts, worked/faded examples, separate Try-it prompts and feedback, common mistakes, and original plain-language concept checks; commit and push each lesson/group. Keep any existing French versions aligned and remove stale M2 originality exceptions.
3. Compare every ledger fact against the revised lessons, update format guidance for the approved M2 change, run all requested content/web and content-swift checks (37 lessons), and record evidence. No Apple UI suites; flag the figure-only test plan for coordinator follow-up.
4. Check acceptance criteria with evidence, finalize the task, commit and push; report branch, full SHA, files and checks without opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision 2026-10-12: YES. Move M2 to the explanatory lesson format (concept sections, worked examples, Try it, common mistakes, concept checks). Start after the 38.x figure branches merge.

Owner decision 2026-10-12: yes, do it. See docs/lesson-review/README.md and docs/lesson-review/m1-m2.md.

Before rewriting: extracted teaching from all four M2 lessons and checked all 99 official questions (44/33/11/11). Baseline ledger: docs/lesson-review/m2-explanatory-taught-facts.md. No FR versions exist (all title.fr fields are null). Preserve all front matter, 99 official quiz IDs and four figure directives. Existing review gaps in sideband convention and S-unit reasoning will be taught explicitly.
<!-- SECTION:NOTES:END -->
