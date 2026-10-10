---
id: TASK-39.1
title: >-
  Teaching guide: plain-language standard, real-world example bank, memory
  tricks
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 22:14'
updated_date: '2026-10-10 22:32'
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
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Wrote docs/teaching-guide.md for lesson writers with plain-language rules, renderer-safe Markdown templates, self-study teaching patterns, all-module example bank, vetted memory tricks, misconceptions, Canadian accuracy notes, originality rules, and a revision checklist. Verified all cited question IDs exist, checked regulatory/numeric claims against the active Basic bank and docs/exam-facts.md, corrected or dropped erroneous research-brief claims, and ran pnpm check:links plus pnpm typecheck.
<!-- SECTION:FINAL_SUMMARY:END -->
