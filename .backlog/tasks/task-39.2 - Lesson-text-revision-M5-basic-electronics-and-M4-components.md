---
id: TASK-39.2
title: 'Lesson text revision: M5 basic electronics and M4 components'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-10 22:14'
updated_date: '2026-10-10 23:19'
labels:
  - content
dependencies:
  - TASK-39.1
parent_task_id: TASK-39
priority: medium
ordinal: 85000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Revise all lessons in m5-basic-electronics and m4-circuit-components to the teaching guide. These need the richest practical examples (LED circuits with a series resistor, voltage dividers, batteries in series/parallel, fuses, power supplies, diodes/transistors in everyday devices, resistor colour code tricks). Coordinate with task-38.1, which edits l-005-02's figure reference.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every lesson in scope is revised to docs/teaching-guide.md: plain language (terms defined at first use, short sentences, active voice), with a technical-accuracy pass
- [x] #2 Each technical lesson gains at least one 'In the real world' example tied to everyday or station hardware, with worked numbers where useful (rule-reference lessons follow the reference-style rules in content/lessons/README.md)
- [x] #3 Memory tricks from the guide are added where they help, are accurate and inoffensive, and say what they help remember
- [x] #4 Coverage, quiz, explanation, originality and link checks pass; lesson IDs, front matter coverage and quiz references are unchanged; Illustration brief sections are left intact for task-38
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Address every r1 finding in the scoped lesson prose while preserving front matter, coverage, quiz IDs, and Illustration brief sections.
2. Run a real readability pass over all 8 existing lessons: split long sentences, define E12/Ah/Wh/bleeder resistors and unclear terms, remove premature or duplicate callouts, and keep examples original.
3. Rerun the full required content/test command set, compare front matter/Illustration briefs against merge-base, record finding-by-finding notes, then set Done last.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
M5 pass: revised L-005-01 through L-005-05. Added prefix, Ohm/power and meter memory aids; phone-charger, LED, fuse, battery series/parallel, loaded divider, capacitor filter, ferrite choke, wall-wart transformer, resonance and meter examples. Numeric facts checked against B-005-001 through B-005-013 and teaching-guide example bank; no regulatory facts added. Required checks after M5 all passed.

M4 pass: revised L-004-01 through L-004-03. Added diode symbol/protection memory aid, USB and 9 V LED resistor examples with E12/power checks, NPN/terminal memory aids, transistor relay switch with flyback diode, tube safety context, and resistor colour-code mnemonic/examples including 4.7 kilohm and 220 ohm tolerance ranges. Facts checked against B-004-001 through B-004-006 and teaching-guide example bank; no regulatory facts added. Required checks after M4 all passed.

Final validation: coverage, quiz, explanation, originality, link, TZ=UTC pnpm test, and Swift content package tests all passed after M5 and again after M4/final. Script comparison against merge-base confirmed all 8 scoped lesson front matter blocks and Illustration brief sections are unchanged. Pinned L-005-01 tests still pass without expected-value updates.

Reviving for review r1 fixes: set task back to In Progress before edits. Will fix all Must fix, Should fix, and Minor notes unless explicitly answered in notes.

Review r1 fixes:
- Must 1 fixed: L-005-02 fuse example now distinguishes whole-radio DC supply connector power (276 W) from the Basic regulatory DC input limit at the transmitter final RF stage; radio-connection wording now says DC supply power, not loose DC input power.
- Must 2 fixed: L-005-03 Try it now states the resistor count with a solvable originality-safe series example: three 18 ohm resistors across 8.1 V.
- Must 3 fixed: L-005-02 now introduces LED forward voltage drop and the need for a series resistor, then works a USB 5.0 V LED example before the 9 V battery example; E12 is defined.
- Should 4 fixed: real readability pass across all 8 lessons split long sentences and clarified existing prose; E12, Ah, Wh, and bleeder resistor are defined.
- Should 5 fixed: removed ELI the ICE man from L-005-04 because the lesson does not teach L/C phase relationships.
- Should 6 fixed: product-over-sum now shows Rt = (R1 x R2) / (R1 + R2) and includes an unequal 330/470 ohm worked example.
- Should 7 fixed: equal-pair parallel example now uses Formula: Rt = R / 2; I = E / Rt.
- Should 8 fixed: prefix memory trick now matches the table and omits nano.
- Minor notes fixed: conductance wording clarified; L-005-03 uses output E instead of Vout and explains battery series/parallel directly; L-005-05 turns-ratio direction and wall-wart VA/loss caveats revised; LED resistor power rounded consistently; repeated offensive-mnemonic warning reduced; duplicate misconception/common-mistake repeats removed or reworded; M4 and L-005-03 Try it sections are numbered.
- Validation: final full run passed coverage, quizzes, lesson originality all, explanations, check:links, TZ=UTC pnpm test, and Swift content package tests. An interim Swift run failed after splitting the L-005-01 intro into a new paragraph; I restored the asserted block structure without weakening tests, and the final Swift run passed. Front matter and Illustration brief sections were script-compared against merge-base and remained unchanged.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Addressed review r1 across all scoped M5 and M4 lessons: fixed the final-RF-stage caveat, restored solvable practice wording, added a standalone USB LED setup before the 9 V LED example, completed the requested readability/definition pass, removed premature ELI-the-ICE-man content, added product-over-sum formula and an unequal example, and resolved all minor notes. Verified with coverage, quizzes, lesson originality all, explanations, link check, TZ=UTC pnpm test, Swift content package tests, and front-matter/Illustration-brief comparison.
<!-- SECTION:FINAL_SUMMARY:END -->
