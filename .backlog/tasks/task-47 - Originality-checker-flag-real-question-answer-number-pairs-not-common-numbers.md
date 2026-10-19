---
id: TASK-47
title: >-
  Originality checker: flag real question-answer number pairs, not common
  numbers
status: Done
assignee:
  - '@worker'
created_date: '2026-10-12 15:48'
updated_date: '2026-10-19 13:32'
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

Added tests in `packages/content-tools/test/check-lesson-originality.test.ts` for allowed common dB/ratio examples, allowed standalone common numbers, rejected real numeric leaks with distinctive numbers/units/multi-number sets, common-number leaks with capacitor/series context, plural context normalization, French decimal commas, scaled prefixes, and number words with attached or following units.

Before/after all-lessons comparison for the original numeric heuristic change: normal checker output stayed at 36 lesson files, 984 official questions, 39 allowlisted blocks, and 0 issues. The empty-allowlist audit dropped from 83 total findings / 46 numeric findings to 61 total findings / 24 numeric findings; the 22 disappearing numeric findings were reviewed as false positives involving common standalone numeric facts or standard dB/power-ratio teaching.

Review fixes before this final round added number+unit context evidence for common-number leaks, including µF/uF, mH, ohm/Ω, V and W examples from review; regression fixtures for one-context vs two-context boundary, low-context unit copies, French decimal commas, k/Hz scaling, and normalized -ces/-ges plurals such as voltages and resistances; and follow-up TASK-62 for stale allowlist auditing/reporting recommended by review.

Final Copilot/review follow-up:
- Replaced the corrupted pasted-log task notes with this summarized notes section via `backlog task edit task-47 --notes`.
- Added spelled-out number+unit evidence for NUMBER_WORDS entries followed by unit words, including hyphenated forms such as `ten-ohm` and `twenty-microfarad`; added missing tens including `fifty` and `seventy-five`.
- Added a word boundary after recognized unit words so strings such as `20 wires` no longer produce `20:watt` evidence.
- Added a low-context metric-conversion fixture confirming that general teaching such as `A kilohertz is 1000 hertz` is not treated as a leak without additional question context.
- Expanded unit handling for hertz as a unit word, pF/picofarads as their own family, kilohms/megohms, milliwatts, microhenries, and mV; scaled numeric normalization now rounds with `toPrecision(12)` before formatting.
- Re-ran the checker across all lessons. The stricter spelled-out unit handling surfaced five L-006-01/B-006-001-006 fifty-ohm coax matches. Each was classified against the official stem (`transmitter`, `coaxial cable`, `characteristic impedance of 50 ohms`, `purely resistive load`, `absorb all RF energy`) and all five were teaching facts rather than mirrored leaks:
  - `In the real world: cutting coax does not change Z0` teaches characteristic impedance and cable length with an original cut-coax scenario.
  - `Coaxial cable` contrasts amateur fifty-ohm coax with seventy-five-ohm TV coax and station hardware expectations.
  - `In the real world: TV coax and radio coax` explains practical radio-vs-TV coax expectations.
  - `Try it` asks about length changes and characteristic impedance in an original jumper scenario.
  - `Summary` states amateur/TV coax norms.
  These blocks were added to `content/lessons/originality-allowlist.json` with specific justifications; no lesson prose was edited.

Commands run for this final round:
- `pnpm --filter @canadian-ham/content-tools test -- check-lesson-originality.test.ts` — 143/143 tests passed after adding the final fixtures.
- `pnpm typecheck` — passed for all workspace packages/apps (TypeScript no-emit checks completed; schemas package has no TypeScript sources).
- `pnpm test` — passed: release-permission self-test passed; content-tools 143/143 tests passed; morse-engine 21/21 tests passed; calculator-ts 127/127 tests passed; web 208/208 tests passed.
- `pnpm --dir packages/content-tools check:lesson-originality:all` — passed after reviewing and allowlisting the five L-006-01 teaching-fact blocks; 36 lesson files, 984 official questions, 44 allowlisted blocks, 0 issues.
- `pnpm --dir packages/content-tools check:explanations` — passed: 984 explanation files verified, 984 question references verified, 2952 per-choice notes verified, 984/984 question explanations present.
- `pnpm check:hints -- --require-complete` — passed: 984 hint files checked for 984 active Basic questions with completeness required.
- `pnpm check:links` — passed: Markdown relative links verified.
- `pnpm check:schemas` — passed: 2033 validation targets checked and 52/52 schema tests passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Refined the lesson originality numeric-overlap rule so common numeric values do not fail unless they are paired with distinctive question numbers or at least two distinctive question context words; near-verbatim checks remain unchanged. Added self-test fixtures covering allowed 10 dB/3 dB shortcut examples, standalone common numbers, and rejected real leaks with distinctive numbers, units, multi-number sets, and common-number capacitor/series context.

Validation passed: `pnpm --filter @canadian-ham/content-tools test -- check-lesson-originality.test.ts`, `pnpm --filter @canadian-ham/content-tools typecheck`, `pnpm typecheck`, `pnpm test`, `pnpm --dir packages/content-tools check:lesson-originality:all`, `pnpm --dir packages/content-tools check:explanations`, `pnpm check:hints -- --require-complete`, `pnpm check:links`, and `pnpm check:schemas`. Normal all-lessons originality output remained 0 issues before and after. Empty-allowlist comparison found 22 reviewed numeric false positives removed and no new findings.
<!-- SECTION:FINAL_SUMMARY:END -->
