---
id: TASK-47
title: >-
  Originality checker: flag real question-answer number pairs, not common
  numbers
status: Done
assignee:
  - '@worker'
created_date: '2026-10-12 15:48'
updated_date: '2026-10-19 13:14'
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
- [x] #1 A worked example using 10 dB + 3 dB steps passes; copying a bank question's numbers with its keyed answer still fails (self-test cases)
- [x] #2 All lessons on main still pass; any newly allowed lines are reviewed
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the existing lesson-originality numeric heuristic and tests, then capture the current all-lessons checker output for before/after comparison.
2. Refine numeric-overlap so a keyed numeric answer only fails when the block also carries a distinctive question number set or distinctive question context, while preserving near-verbatim word-overlap checks.
3. Add fixture tests for allowed common dB/ratio step values and rejected real leaks, including multi-number and unit scenarios.
4. Run targeted content-tools tests plus the required repository checks, compare all-lesson results before/after, record reviewed disappearing findings in task notes, then finalize the Backlog task and PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented numeric-overlap refinement in `packages/content-tools/src/check-lesson-originality.ts`: a block must still contain all numeric tokens from the question and keyed answer, but now the question side must contribute either at least one non-common/distinctive numeric token or at least two distinctive context words from the question. Near-verbatim 5-gram/longest-run checks are unchanged, so copied question wording still fails independently.

Added tests in `packages/content-tools/test/check-lesson-originality.test.ts` for:
- allowed common dB/ratio examples using +10 dB and -3 dB steps plus repeated +3 dB steps;
- allowed standalone common numbers (`5`/`10`) without question context;
- rejected real numeric leaks with distinctive numbers, units, multi-number scenarios, and common numeric values when capacitor/series context is also present.

Before/after all-lessons comparison:
- Normal checker with committed allowlist: before `pnpm --dir packages/content-tools check:lesson-originality:all` passed with 36 lesson files, 984 questions, 39 allowlisted blocks, 0 issues; after it also passed with 36 lesson files, 984 questions, 39 allowlisted blocks, 0 issues.
- Empty-allowlist audit for review: current checker output dropped from 83 total findings / 46 numeric findings to 61 total findings / 24 numeric findings; no new findings appeared. The 22 disappearing numeric findings were reviewed as false positives because they are common/standalone numeric facts without the specific question context:
  - `L-001-04` Bandwidth and mode-fit cues vs `B-001-024-010` (`6`/`6`): unrelated Safety Code 6 number appearing in a bandwidth/mode reference block.
  - `L-002-04` grid locator code length vs `B-002-006-008` (`6`/`4`): standalone Maidenhead locator lengths, not copied question context.
  - `L-005-04` Decibels as power ratios vs `B-005-001-003`, `B-005-004-001`, `B-005-005-008`, `B-005-005-010`, `B-005-006-006`, `B-005-006-009`, `B-005-008-001`, `B-005-008-002`, `B-005-008-003`, `B-005-008-007`, `B-005-009-001`, `B-005-009-002`, `B-005-009-003`, `B-005-009-004`, `B-005-009-009`, `B-005-009-010`, and `B-005-011-007`: standard dB/power-ratio step values (`0.5`, `1`, `2`, `3`, `4`, `5`, `10`, `20`, `100`, `1000`) taught as estimating shortcuts rather than any one question scenario.
  - `L-006-02` reflected-power estimates vs `B-006-009-002`, `B-006-011-010`, and `B-006-013-010`: common ratio/SWR/Yagi-spacing numbers overlap the reflected-power table, but the lesson block lacks the source questions' matching contexts.

Review fix: added number+unit context evidence for common-number leaks, including µF/uF, mH, ohm/Ω, V and W examples from review, plus regression fixtures for one-context vs two-context boundary, low-context unit copies, French decimal commas, and k/Hz scaling. Normal all-lessons checker before this fix passed with 36 lesson files, 984 questions, 39 allowlisted blocks, 0 issues; after this fix it still passes with the same counts and 0 issues. Empty-allowlist audit before and after remained 61 total findings / 24 numeric / 37 five-gram, so no current lesson findings were newly added or removed by this review fix. The retained suppressed dB/ratio findings remain justified because dB unit matches are not context evidence by themselves; current metric conversion teaching is also not treated as a leak without additional question context. Created follow-up TASK-62 for stale allowlist auditing/reporting recommended by review.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Refined the lesson originality numeric-overlap rule so common numeric values do not fail unless they are paired with distinctive question numbers or at least two distinctive question context words; near-verbatim checks remain unchanged. Added self-test fixtures covering allowed 10 dB/3 dB shortcut examples, standalone common numbers, and rejected real leaks with distinctive numbers, units, multi-number sets, and common-number capacitor/series context.

Validation passed: `pnpm --filter @canadian-ham/content-tools test -- check-lesson-originality.test.ts`, `pnpm --filter @canadian-ham/content-tools typecheck`, `pnpm typecheck`, `pnpm test`, `pnpm --dir packages/content-tools check:lesson-originality:all`, `pnpm --dir packages/content-tools check:explanations`, `pnpm check:hints -- --require-complete`, `pnpm check:links`, and `pnpm check:schemas`. Normal all-lessons originality output remained 0 issues before and after. Empty-allowlist comparison found 22 reviewed numeric false positives removed and no new findings.
<!-- SECTION:FINAL_SUMMARY:END -->
