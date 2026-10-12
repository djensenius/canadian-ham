---
id: TASK-46.1
title: 'Lesson accuracy and coverage fixes: M5 and M4'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-12 14:57'
updated_date: '2026-10-12 15:15'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
priority: high
ordinal: 99000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apply the High findings (and Medium ones that are a sentence or two) from docs/lesson-review/m5-m4.md. Follow docs/teaching-guide.md and content/lessons/README.md. Verify every new fact against the bank and primary sources (RBR-4, RIC-1, NRC and so on), and check the reference-sheet claims the reviewer could not verify against the ISED reference PDF. Never restate ISED question or answer text. Fix matching explanation files where the review flags them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every High finding in docs/lesson-review/m5-m4.md is fixed (or declined with a recorded reason), with question IDs listed in the notes
- [x] #2 Every covered question flagged as untaught or answer-key only is now taught with a reason
- [x] #3 Coverage, quizzes, originality, explanations and links checks pass; the taught-facts check finds no regressions
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Verify m5-m4 findings against the active bank and reference sheet/source material before adding facts.
2. Make focused paragraph-level fixes in each affected M5/M4 lesson and any flagged quizzes without changing coverage or lesson structure.
3. Commit after each lesson slice, record finding-to-fix notes with question IDs and sources.
4. Run coverage, quiz, originality, explanation, link, web vitest, and content-swift checks; then finalize task ACs and Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Finding-to-fix notes for task-46.1:
- L-005-01 High B-005-002-004/B-005-002-002: expanded conductors/insulators/semiconductors so copper is distinguished from aluminum for the bank comparison and carbon is taught as conductive but much poorer than metals, not a good conductor or an insulator. Also replaced the weak prefix mnemonic and added the required voltage-analogy limit. Quick quiz fixes: QZ-L-005-01 C2/C3 now use plausible distractors instead of giveaways.
- L-005-02 Medium undefined term/reference wording: changed reference-sheet wording to “may use,” defined the final RF stage where the Basic DC-input limit is mentioned, and changed QZ-L-005-02 C2 away from the Try-it numbers.
- L-005-03 Medium B-005-006-004/-005/-010: added the explicit N equal resistors power-sharing rule for series or parallel when sharing is even, relabelled the 72 ohm example as a generic bench test load, and added the power-sharing official IDs plus a transfer concept check.
- L-005-04 High B-005-008-004/-005/-009/-011: defined S-meter, taught dB values add when ratios multiply, added/rewrote dB-chain and S-meter examples using non-bank numbers, and changed Try-it #3 to ask for dB. High/Medium B-005-010-005/-009: taught impedance as E / I for AC, added inductor-change intuition, and explicitly stated the bypass capacitor has high reactance at audio while passing unwanted RF. High B-005-012-008: added dielectric material as a capacitance factor. Also fixed the 9.5 W rounding. QZ-L-005-04 now includes S-meter/bypass official IDs and avoids the copied 33 µF example/giveaway distractors.
- L-005-05 High B-005-011-002: added the transformer impedance explanation (different voltages/currents on windings mean different E/I impedance). High B-005-012-008: added more-L/more-C lowers resonant frequency and kept resistor addition as not changing the ideal L/C frequency. High B-005-011-010: replaced the misleading permanent-magnet wording with hardened-steel/ferromagnetic wording and the copper/aluminum/brass contrast. Medium B-005-012 resonance: explained series cancellation and parallel energy exchange. Medium B-005-013-010 and meter items: added accuracy/precision/resolution contrast and made RF wattmeter/final-amplifier-current table entries specific. QZ-L-005-05 now includes B-005-011-002, B-005-012-008, and meter-resistance/accuracy IDs, and uses new transformer numbers and plausible concept-check distractors.
- L-004-01 Medium B-004-002-010: defined forward biased as anode more positive than cathode enough for conduction. Defined preselector, mixer, speech processor, and modulator in the Try-it text. QZ-L-004-01 C2 no longer depends on undefined SSB/splatter language.
- L-004-02 Medium undefined terms: defined holes, bias, and active region near first use.
- L-004-03 Low/quick reference-sheet claim: extracted the ISED Basic exam reference PDF and verified there is no colour-code table; changed the lesson to state that plainly. QZ-L-004-03 now uses “kilohm” and “±” consistently.
Sources verified (accessed 2026-10-12): active generated bank content/generated/basic-2025-07-15/questions.json against ISED source https://apc-cap.ic.gc.ca/datafiles/amat_basic_quest.zip#amat_basic_quest_delim.txt (manifest retrieved 2026-09-29); ISED Basic exam/training reference material from https://www.ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/sites/default/files/documents/Reference%20Material%20for%20Amateur%20Radio%20Basic%20EN%202025%20.zip extracted locally with Swift PDFKit; RBR-4 page https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service returned 200 and was used only to corroborate the existing final-RF-stage regulatory context. Reference PDF check: exam PDF page 1 gives E/I/R/P and R/C/L formulas; pages 2-5 are diagrams only; no resistor colour-code table.
Skipped as separate structural/workflow tasks per scope: Try-it answer hiding (TASK-46.5); faded practice, stronger broad concept-check feedback, and full concept-check redesign beyond quick replacements (TASK-46.6); interleaving (TASK-46.7); M1 restructure (TASK-46.8); M2 format change (TASK-46.9); lesson splits/coverage moves including L-005-04 (TASK-46.10); cross-module prerequisite front matter changes for L-004-01/L-004-03 (TASK-46.11); rendered figure production/artist-brief hiding (task-38 lane).
Taught-facts self-check: reviewed the flagged covered/answer-key-only IDs listed above plus the changed lesson coverage ranges (B-005-001/002, 003/004, 005/006, 007/008/009/010, 011/012/013, B-004-001/002/003/004/005/006) against questions.json correct answers after edits. No previously taught covered fact was removed; new prose preserves all answers while avoiding ISED question/answer restatement.
Validation passed: node packages/content-tools/src/check-lesson-coverage.ts; pnpm --dir packages/content-tools check:quizzes; pnpm --dir packages/content-tools check:lesson-originality:all; pnpm --dir packages/content-tools check:explanations; pnpm check:links; cd apps/web && npx vitest run (160 tests); DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift (18 XCTest tests).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed all High M5/M4 lesson findings and quick Medium wording/quiz issues in L-005-01 through L-005-05 and L-004-01 through L-004-03 without coverage moves or structural rewrites. Added task notes mapping findings to question IDs, source/reference-PDF checks, skipped structural items, and taught-facts self-check. Verification passed: coverage, quizzes, lesson originality all, explanations, links, web vitest, and Swift content package tests.
<!-- SECTION:FINAL_SUMMARY:END -->
