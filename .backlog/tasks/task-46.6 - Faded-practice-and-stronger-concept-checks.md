---
id: TASK-46.6
title: Faded practice and stronger concept checks
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:57'
updated_date: '2026-10-20 14:53'
labels:
  - content
dependencies:
  - TASK-46.1
  - TASK-46.2
  - TASK-46.3
  - TASK-46.4
parent_task_id: TASK-46
priority: medium
ordinal: 104000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
For quantitative lessons, add one partly worked practice problem after each worked-example set. Replace giveaway concept checks (especially M6) with diagnostic ones, avoid NOT stems, and give each concept check per-option feedback explaining why each wrong option is wrong. Turn story-only 'worked examples' into stepwise ones or rename them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every lesson with calculations has at least one faded practice problem
- [ ] #2 No concept check can be answered by eliminating absurd options (reviewed); each has per-option feedback
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Part A (this branch):
1. Add optional localized concept-choice feedback in schemas and content-swift, a staged require-feedback quiz-checker flag, and accessible web chosen-option feedback with regression/EN-FR light-dark axe tests. Validate, commit, and push this foundation FIRST; notify coordinator with its SHA so Part B can branch from it.
2. Revise M1-M4 content within existing formats: M1 remains reference-only with no concept checks; add faded problems after calculation worked-example sets in M2-M4, rename narrative worked examples, and make all M2-M4 concept choices diagnostic with per-option feedback. Validate, commit, and push each coherent step.
3. Search then create Apple feedback-display subtask under 46.6 depending on TASK-50.14.2. No Apple app edits. Run content-swift tests (37 lessons) and requested content/web checks; list edited lessons containing figures for coordinator figure-plan tests.
Part B: coordinator starts M5-M8 content branch from the pushed foundation commit. Require feedback in the default checker once all quizzes are converted at end of 46.6. Parent stays In Progress pending Part B and Apple subtask.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
From task-46.3 r463-2 review: QZ-L-007-03-A C1 and C3 were rewritten to avoid copying bank questions, but they should receive a stronger technical redesign in the faded-practice/stronger-concept-check pass. Also check EXP-B-008-004-004's spurious-emissions distractor note: the current 'broad category' wording may conflict with the cause-based out-of-band vs spurious distinction.

Part A foundation pushed at 93d75d3330bc4474f59409edbf4550e9579df1dc; coordinator notified for Part B branch. Added optional feedback schema, staged --require-feedback checker, focused chosen-option web feedback and EN/FR light/dark axe regressions, optional Swift decoding/round-trip test (37 lessons retained). Apple display tracked in TASK-46.6.1, blocked on TASK-50.14.2. M1 audited and deliberately unchanged: reference-only tables and empty conceptChecks remain required by the teaching guide. M2 now has faded completion problems immediately after offset, S-meter, battery-runtime, long-path-bearing and UTC worked-example sets; story-only headings renamed or converted to steps. All 12 M2 checks now have plausible misconception-based options and 48 per-option notes. M2 strict feedback checker, originality, links and complete hints passed; all example arithmetic recomputed. No new regulatory claims or real channel recommendations.

M3 complete: 24 diagnostic checks with 96 choice-specific notes; removed every NOT/spot-the-error stem and replaced unrelated/giveaway options with plausible block-role, arithmetic, control, rating, or safety misconceptions. Added 19 faded problems across all 8 lessons, covering each quantitative worked-example set (including newly stepwise peak/RMS, product-detection and inverse-square examples); supplied conversions, blanks, separate solutions, and model limits. Story-only examples renamed; two b-003-015 hint anchors updated to retain the same target after heading rename. Recomputed examples and choices, including 15.6 W regulator loss, 11.4 kHz Carson estimate, 46-trace planning count, and squared distance ratios. Strict M3 feedback checker, originality, lesson coverage, links, and complete hints passed. Existing coverage/front matter/quiz IDs/figure directives retained.

M4 complete: 5 faded problems after voltage gain, LED sizing, relay base-current, resistor value/tolerance, and multiplier-comparison sets. All 9 checks now have four plausible options and 36 per-option notes; no absurd off-topic choices or negative stems. Verified gain 30, LED ideal 300 ohms / 0.0588 W, base current 3.8 mA, 7 500 ohm ±10% range 6 750–8 250, and 100:1 multiplier change. Strict M4 feedback checker, originality, links, and complete hints passed. Added source-named content regressions for all 29 faded sets in the 15 edited lessons, complete and distinct M2-M4 feedback, no negative stems, and unchanged M1 reference-only format. The regression pass caught and fixed a missing M2 sanity-check cue and made one M3 prompt positive.
<!-- SECTION:NOTES:END -->
