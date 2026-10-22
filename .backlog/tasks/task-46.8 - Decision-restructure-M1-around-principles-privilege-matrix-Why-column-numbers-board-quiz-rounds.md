---
id: TASK-46.8
title: >-
  Restructure M1 around principles (privilege matrix, Why column, numbers board,
  quiz rounds)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:58'
updated_date: '2026-10-21 15:22'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
priority: medium
ordinal: 106000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner approved 2026-10-12: organize M1 around generating principles, companion qualification-by-privilege matrices, short Why columns, a numbers board and section-sized quiz rounds. The content rewrite is on task-46.8-m1-principles; UI round delivery is split into TASK-46.8.1 after TASK-50.14.2 so it does not conflict with Apple quiz-hint work. Preserve lesson identities, coverage and every taught bank fact.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Owner decision recorded
- [x] #2 M1 lessons are organised around stated principles with the privilege matrix, Why column and numbers board; every covered question remains taught (taught-facts check)
- [ ] #3 Lesson quizzes are delivered in section-sized rounds on web and Apple
- [x] #4 Lesson coverage, originality, quiz and link checks pass, and a taught-facts comparison shows no fact was lost
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

Content complete: all six M1 lessons now teach stated principles with original reference facts and short Why columns. Companion qualification matrices in L-001-02/L-001-04 distinguish station work, frequency access and power; L-001-01 contains the M1 numbers board. Each lesson was committed and pushed separately. Reference-only policy retained consistently in README/teaching guide; no concept checks or quiz changes.

Evidence: docs/lesson-review/m1-principles-taught-facts.md extracts all 202 baseline table rows, compares prose-only facts and indexes all 199 B-001 questions with teaching destinations. Before/after script against 8a82709b verifies all six entire front matters, figure directives/text equivalents, illustration briefs and full quiz JSON unchanged; only sectionAnchor changed in all 199 hint JSON files (including French text unchanged). New m1-principles.test.ts adds 10 regression tests for Why tables, companion matrices, numbers board, every hint teaching target and ledger completeness.

Checks passed: coverage 100/100, originality all 0 issues/0 stale (15 active allowlist blocks, M1 down from 18 to 7), explanations 984/2 952 notes, quizzes 37/521 official refs/92 concepts, links, figures 53 fixtures/39 SVGs, hints 984/984 complete, schemas 2 071 targets/58 tests, Basic+Advanced import and 34 reference-sheet entries, pnpm typecheck, pnpm test (content-tools 226, Morse 21, calculator 127, web 245 all passed), content-swift swift test 24/24. Initial missing workspace vitest/tsc failures were resolved by pnpm install --frozen-lockfile; no tracked dependency change.

ISED live RBR-4/RIC-3 pages returned HTTP 503 on canonical/www hosts; preserved repository-verified regulatory facts and cross-checked against the active bank instead of adding new legal claims. All six changed lessons contain unchanged figure directives: L-001-01 authority-records-exams, L-001-02 station-control-decision-tree, L-001-03 communications-flowchart, L-001-04 privileges-station-checklist, L-001-05 international-location-checklist, L-001-06 antenna-rf-emc-checklists. Coordinator runs the separate iOS lesson-figure plan. No Apple app suite run; no Apple source, renderer or assets changed. Parent remains In Progress; AC #3 is deliberately open for TASK-46.8.1, which depends on TASK-50.14.2. No PR opened.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Content portion complete: six principles-led reference lessons, companion privilege matrices, Why columns and M1 numbers board. All 199 covered questions remain taught; all 199 hint anchors retargeted. IDs, coverage, figures and quizzes unchanged; content checks, workspace tests/typecheck and 24 content-swift tests pass. Parent stays In Progress pending section-sized web/Apple quiz rounds in TASK-46.8.1 and coordinator figure audit; live ISED page refresh was unavailable (HTTP 503), so existing verified regulatory facts were retained.
<!-- SECTION:FINAL_SUMMARY:END -->
