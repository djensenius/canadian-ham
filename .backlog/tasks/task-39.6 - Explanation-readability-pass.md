---
id: TASK-39.6
title: Explanation readability pass
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 22:15'
updated_date: '2026-10-11 00:35'
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
- [ ] #1 Every explanation in B-004 to B-008 is reviewed and revised where needed; B-001 to B-003 are reviewed for clarity
- [ ] #2 Explanation checker, originality and allowlist checks pass
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
<!-- SECTION:NOTES:END -->
