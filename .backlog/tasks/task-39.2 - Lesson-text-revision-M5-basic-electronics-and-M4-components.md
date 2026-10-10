---
id: TASK-39.2
title: 'Lesson text revision: M5 basic electronics and M4 components'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 22:14'
updated_date: '2026-10-10 23:05'
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
1. Revise M5 lesson bodies first, preserving front matter, quiz IDs, and each Illustration brief while adding practical examples, worked numbers, vetted memory tricks, and misconception notes.
2. Run the required content checks after M5 and record per-lesson notes with checked question IDs.
3. Revise M4 lesson bodies with component-focused examples: diodes, transistor switching, wall-wart context, capacitors/inductors, and resistor colour mnemonic.
4. Run the required checks after M4 and at final, update pinned expectations only if text changes require it, then finalize Backlog acceptance criteria.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
M5 pass: revised L-005-01 through L-005-05. Added prefix, Ohm/power and meter memory aids; phone-charger, LED, fuse, battery series/parallel, loaded divider, capacitor filter, ferrite choke, wall-wart transformer, resonance and meter examples. Numeric facts checked against B-005-001 through B-005-013 and teaching-guide example bank; no regulatory facts added. Required checks after M5 all passed.

M4 pass: revised L-004-01 through L-004-03. Added diode symbol/protection memory aid, USB and 9 V LED resistor examples with E12/power checks, NPN/terminal memory aids, transistor relay switch with flyback diode, tube safety context, and resistor colour-code mnemonic/examples including 4.7 kilohm and 220 ohm tolerance ranges. Facts checked against B-004-001 through B-004-006 and teaching-guide example bank; no regulatory facts added. Required checks after M4 all passed.

Final validation: coverage, quiz, explanation, originality, link, TZ=UTC pnpm test, and Swift content package tests all passed after M5 and again after M4/final. Script comparison against merge-base confirmed all 8 scoped lesson front matter blocks and Illustration brief sections are unchanged. Pinned L-005-01 tests still pass without expected-value updates.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Revised all M5 and M4 lesson prose to the teaching guide with plain-language pass, practical station/everyday examples, worked calculations, memory tricks, and misconception callouts. Preserved lesson IDs, front matter coverage/quiz references, and Illustration brief sections. Verified with coverage, quiz, explanation, originality, link, full pnpm test, and Swift content package tests; no pinned test expectations needed changes.
<!-- SECTION:FINAL_SUMMARY:END -->
