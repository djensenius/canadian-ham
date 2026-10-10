---
id: TASK-39.1
title: >-
  Teaching guide: plain-language standard, real-world example bank, memory
  tricks
status: Done
assignee:
  - '@worker'
created_date: '2026-10-10 22:14'
updated_date: '2026-10-10 22:37'
labels:
  - content
  - docs
dependencies: []
parent_task_id: TASK-39
priority: medium
ordinal: 84000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Research and write docs/teaching-guide.md: a plain-language standard (target reading level, sentence/paragraph length, define terms at first use, units and number style with SI space grouping per owner decision A), a per-module bank of practical real-world examples (e.g. LED with a series resistor from a 9 V battery or USB 5 V, car 12 V fuse sizing, phone charger power, flashlight, microwave oven 2.4 GHz, FM broadcast ~3 m wavelength, TV coax, speaker impedance), common accurate memory tricks used in amateur radio teaching (with sources; reject offensive or inaccurate ones), and common misconceptions to address. Sources cited; nothing copied from third-party study guides.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 docs/teaching-guide.md exists with the plain-language standard, an example bank covering all 8 modules (electronics deepest), a vetted memory-trick list with what each helps remember and its source, and a misconceptions list
- [x] #2 Every technical example and trick is checked for accuracy (Canadian context: RBR-4, RIC-3, Canadian band plan where relevant) and the research sources are listed
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Verify renderer-supported Markdown and lesson conventions from existing docs, sample lessons, and parser code.
2. Check regulatory and numeric claims from the research brief against docs/exam-facts.md and content/generated/basic-2025-07-15/questions.json; drop or mark unverified claims.
3. Write docs/teaching-guide.md with concise writer guidance, supported templates, verified example bank, memory tricks, misconceptions, Canadian accuracy notes, originality rules, and revision checklist.
4. Run docs/content checks, record evidence in task notes, check acceptance criteria, finalize task, and commit.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented docs/teaching-guide.md. Verification evidence:
- Confirmed all 63 cited Basic question IDs in the guide exist in content/generated/basic-2025-07-15/questions.json with a script.
- Checked identification interval against B-001-013-006 and B-001-013-009.
- Checked certificate lifetime/address facts against B-001-002-002, B-001-002-001, and B-001-002-003.
- Checked below-30-MHz access against B-001-015-003 and Basic/Advanced power against B-001-017-009, B-001-017-010, B-001-017-005, B-001-017-007, and B-001-017-002.
- Checked Safety Code 6 notes against B-001-024-001, B-001-024-002, B-001-024-005, B-001-024-006, and B-001-024-009.
- Checked band-plan voluntary status against B-002-004-010; marked specific calling frequencies and 70 cm offsets as needing current RAC/local verification before use.
- Checked repeater/simplex/RST/Q-signal/phonetic operating claims against B-002-001-009, B-002-001-011, B-002-003-003, B-002-003-004, B-002-006-001, B-002-006-002, B-002-006-003, B-002-006-009, B-002-007-002, B-002-007-004, B-002-007-007, B-002-007-008, B-002-007-010, and B-002-008-005.
- Checked diode, resistor colour-code, Ohm/power, series/parallel battery, reactance/ferrite, wavelength, SWR, tuner, low-pass-filter, and propagation claims against the question IDs cited inline in the guide.
- Corrected research-brief errors: Honours does not raise power to Advanced limits; 2.45 GHz has 12.2 cm wavelength but is in the 13 cm amateur region; invented mnemonic/source attributions were replaced with common/traditional source status; Break Break is not taught as casual entry; 146.520 MHz and 70 cm offsets were not treated as exam-bank facts; universal fuse-margin claims were dropped.
- Validation passed: pnpm check:links; pnpm typecheck; cited-QID existence script. No docs/Markdown lint script exists in package.json scripts.

Review r1 fixes started: addressing all 18 findings from ~/.cache/canadian-ham-reviews/t39-1-r1.md.

Review r1 fixes completed for all 18 findings:
1. Fixed 60 Hz citation to B-005-007-008 and removed harmonic-example guidance; added that 60 Hz hum is not a harmonic emission.
2. Changed parallel-battery example to two 6 V, 10 Ah packs so it no longer copies B-003-016-009.
3. Completed Basic power summary: 250 W DC input, 560 W PEP SSB, 190 W carrier; cited B-001-017-004 and stated Honours/Morse add below-30-MHz access, not power.
4. Added caveat that regulatory DC-input power applies to the final RF stage, not whole-radio supply draw.
5. Updated callout templates to use list items and added renderer caveats from MarkdownContent.tsx and MarkdownLessonContent.swift.
6. Added pnpm test, DEVELOPER_DIR swift test in packages/content-swift, and pinned L-005-01/L-006-03 test warnings to the revision checklist.
7. Stated M2 is reference-style for this revision pass and rewrote M1/M2 misconception rows as positive rules.
8. Updated dipole guidance to cite B-006-012-001, B-006-012-009, and B-006-010-003 and to match each bank-item convention.
9. Corrected radio horizon total to 46.7 km.
10. Changed wavelength memory anchor to 100 MHz -> 3 m.
11. Added originality warning for the 6 dB/S-unit answer.
12. Applied SI grouping to 1 000 W / 2 250 W and specified normal space U+0020.
13. Added table, blockquote, and one-line-per-list-item Markdown rules.
14. Added caveat that reflected power is not simply lost.
15. Clarified E in the LED resistor formula is resistor voltage.
16. Added flyback-diode caution for relay driver examples.
17. Added speaker impedance, flashlight, and labelled FM broadcast 3 m examples; added primary reference URLs for RBR-4, RIC-3, Safety Code 6, and RAC 2 m band plan.
18. Chose x as the single multiply sign standard and told writers to normalize older × uses.
Validation: pnpm check:links passed; qid existence script passed (62 cited IDs); cd packages/content-swift && swift test failed under CommandLineTools due missing XCTest, then DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift passed; pnpm test passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Addressed all 18 review r1 findings in docs/teaching-guide.md and verified with pnpm check:links, cited-question-ID validation, DEVELOPER_DIR swift test --package-path packages/content-swift, and pnpm test. The task remains Done for review.
<!-- SECTION:FINAL_SUMMARY:END -->
