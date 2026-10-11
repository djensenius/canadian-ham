---
id: TASK-39.6
title: Explanation readability pass
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 22:15'
updated_date: '2026-10-11 00:52'
labels:
  - content
dependencies:
  - TASK-39.1
parent_task_id: TASK-39
priority: low
ordinal: 89000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Review the 984 per-question explanations in content/explanations for readability against docs/teaching-guide.md: plain language, defined terms, a short real-world tie-in where it helps. Prioritise technical categories (B-004 to B-008). Keep the explanation checker passing and never restate ISED question text beyond what the rules allow.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every explanation in B-004 to B-008 is reviewed and revised where needed; B-001 to B-003 are reviewed for clarity
- [x] #2 Explanation checker, originality and allowlist checks pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Apply all review findings in body.en only, checking official question data for each touched answer.\n2. Use a script to flag abbreviation first-use issues across every explanation changed on task-39.6, then make targeted body.en edits by category.\n3. Commit content fixes one category at a time, run the requested explanation/link/web checks, and append finding-by-finding task notes without checking ACs or moving status.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
B-004/B-005 lane: reviewed all 205 explanations in scope against content/generated/basic-2025-07-15/questions.json. Updated only body.en prose in 56 B-005 files and 29 B-004 files for shorter sentences, clearer distractor reasons, SI spacing/unit style, and selective technical definitions/tie-ins. Accuracy fixes: none found; correct answers and existing quoted choice text were preserved. Checks: node packages/content-tools/src/check-explanations.ts --category B-005 (pass), --category B-004 (pass), pnpm --dir packages/content-tools check:explanations (pass), pnpm check:links (pass), TZ=UTC pnpm test initially hit two web timeout-related failures and passed on the requested rerun.

Fix round completed finding-by-finding (ACs intentionally not checked; status left In Progress):
- t39-6-a-r1 B-004/B-005: restored b-005-005-003 parallel-resistance formula and flip-back step; defined first-use abbreviations across changed B-004/B-005 explanations; made b-005-007-003 direct-conversion distractor more specific; changed b-005-006-009 to E x E / R notation.
- t39-6-b-r1 B-006/B-008: restored b-006-005-002 SWR reflection-coefficient worked step; linked b-006-008-005 loading-coil analogy to f = 1 / (2π√LC); changed b-006-010-009 to 2-metre-long; restored b-006-008-003 free-space wording; restored b-008-001-002 'when you transmit on several different HF bands'; changed b-008-005-005 to much higher-frequency signals; defined first-use abbreviations including SWR, RF, VHF, PA, CW; added isotropic-radiator equal-in-all-directions wording; restored b-008-003-003 'must be corrected'; cleaned VHF/UHF hyphenation wording.
- t39-6-c-r1 B-003/B-007: fixed b-007-006-008 to teach highest returning frequency / maximum usable frequency (MUF); fixed b-007-005-007 so 40 MHz is above the HF range; changed b-007-002-009 and b-007-004-001 to 'lower-frequency end of the HF range'; defined first-use abbreviations across changed B-003/B-007 explanations; made b-003-021-008 use 1/d squared consistently; split the flagged semicolon distractor notes.
- t39-6-d-r1 B-001/B-002: rewrote b-001-017-006 to avoid echoing the ERP/PEP question phrase; restored width comparisons in b-001-016-009; added ISED definitions where flagged; clarified b-001-003-005 notice/representation wording and b-001-023-005 written-notice/response wording; restored full break-in (QSK) wording; defined RS/S9 in b-002-006-005; tightened CTCSS tone wording.
- Verification: pnpm --dir packages/content-tools check:explanations passed; pnpm check:links passed; cd apps/web && npx vitest run passed (14 files, 152 tests).

r2 fix round completed (ACs intentionally not checked; status left In Progress):
- Fixed the high issue in b-002-009-010 by restoring the clock times 1 PM and 1 AM.
- Rewrote b-003-014-005 VOX/VXO/VCO/VFO notes to define once and avoid circular definitions.
- Replaced the garbled FT8 expansion with 'FT8, a narrow digital mode' in b-001-016-009, b-001-016-011, and b-003-015-006.
- Corrected garbled B-007 HF wording in b-007-001-004, b-007-002-004, b-007-007-008, b-007-008-008, and b-007-008-009.
- Defined BFO in b-003-005-004, b-003-005-005, b-003-005-008, and b-003-005-009.
- Hand-fixed each r2 grammar/duplication item: wrong articles, decibel adjective wording, hyphenated frequency nouns, repeated definitions, b-001-017-006 PEP wording, and the remaining semicolon notes in b-003-013-007 and b-007-006-003.
- Final report-only audit across content/explanations: before counts article=4, decibels-adjective=3, digit-expanded=2, doubled/nested-parentheses=5, hyphenated-frequency-noun=21, duplicate-expansion=12, tautology=3, total=50; after counts total=0.
- Verification after r2 fixes: pnpm --dir packages/content-tools check:explanations passed; pnpm check:links passed; cd apps/web && npx vitest run passed (14 files, 152 tests).

Review r3 (APPROVE WITH NOTES): coordinator fixed the remaining low items: CAT duplicate in b-003-007-006; RF defined in b-006-006-002; HF defined in b-003-013-009; hyphenated-noun forms in b-004-002-006, b-007-001-008, b-007-008-011, b-003-012-003, b-003-008-001 and b-008-002-007; FET order in b-004-003-003. Remaining cosmetic hyphenation inconsistency (adjective 'very high frequency (VHF) range' vs 'very-high-frequency (VHF) range') is accepted. Totals: all 984 explanations reviewed in 4 lanes, about 440 revised (body.en only), reviewed per category (4 reviewers) plus 2 fix-round re-reviews with bank checks; no explanation contradicts the bank, and no taught fact was lost (taught-facts checks in each review).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Readability pass over all 984 per-question explanations to docs/teaching-guide.md: plain language, abbreviations defined at first use, clearer distractor reasoning, SI number grouping, x for multiply, and a few accurate real-world tie-ins in technical categories. Technical categories B-004 to B-008 reviewed in depth; B-001 to B-003 reviewed for clarity and accuracy. Every changed explanation was checked against the ISED Basic bank by category reviewers; a mechanical abbreviation pass that broke text (for example '1 PM' read as phase modulation) was caught in review and fixed by hand, with a report-only audit across all explanations. Checks: check:explanations (schema, citations, TEMPLATE and duplicate-note lints), check:links, web vitest suite (152/152).
<!-- SECTION:FINAL_SUMMARY:END -->
