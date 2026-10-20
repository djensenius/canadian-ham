---
id: TASK-46.9
title: Move M2 from reference style to the explanatory format
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:58'
updated_date: '2026-10-20 13:13'
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

L-002-01 complete: concept-led path/access, calling and spectrum-sharing sections; worked offset and join-in examples; faded positive-offset Try it with separate feedback; three original concept checks (including signal-quality retrieval). All 44 mapped bank questions retained and compared in the ledger. Removed its now-stale calling-pattern originality exception. Targeted checks passed: coverage (37 lessons), M2 quizzes (99 official IDs, 3 concept checks), all-lesson originality (0 issues/stale entries).

L-002-02 complete: Morse contact sequence and group jobs, honest RS/RST interpretation, explicit two-doubling S-unit derivation plus upward/downward worked examples, faded reduction Try it and three original checks. All 33 mapped questions plus the old extra Q signals retained in the ledger. Removed its stale calling-pattern exception. Targeted M2 quiz check passed (99 official, 6 concept checks); originality initially flagged the standard 6 dB/fourfold pair repeated in the new worked example, so removed the redundant dB restatement from that example while retaining the derivation in the concept section. All-lesson originality rerun passed with no issues or stale entries.

L-002-03 complete: priority decisions, a worked break-in response, accurate relaying and whole-station readiness; explicit battery formula with original values, faded practice and three original checks. All 11 mapped questions and additional record/readiness teaching retained in the comparison ledger. M2 quizzes passed (99 official, 9 concept checks); all-lesson originality passed with 0 issues/stale entries. Distress signals and priority order checked against the active bank; runtime estimate 12 Ah / 1.5 A = 8 h, practice 9 Ah / 1.5 A = 6 h, with reserve/cold/age caveats.

L-002-04 complete: confirmation/log evidence, locator versus bearing, station-centred maps, worked reciprocal heading, UTC conversions with AM/PM and date rollover, faded practice and three original checks. All 11 mapped questions retained in the ledger. M2 quiz check passed (99 official, 12 concept checks). Originality first caught incidental 6 and 4 in the UTC example as the S-unit fact; changed the illustrative time-zone offset to minus 5 rather than adding an exception. All-lesson originality now passes (0 issues/stale entries). Numbers recomputed: 65 + 180 = 245 degrees; 2245 - 0500 = 1745 / 5:45 PM; 0210 - 0500 = 2110 previous day / 9:10 PM; practice 0145 - 0500 = 2045 previous day / 8:45 PM and 235 + 180 - 360 = 55 degrees.
<!-- SECTION:NOTES:END -->
