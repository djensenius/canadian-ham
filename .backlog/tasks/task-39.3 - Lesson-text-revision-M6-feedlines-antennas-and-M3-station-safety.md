---
id: TASK-39.3
title: 'Lesson text revision: M6 feedlines/antennas and M3 station/safety'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 22:15'
updated_date: '2026-10-10 22:59'
labels:
  - content
dependencies:
  - TASK-39.1
parent_task_id: TASK-39
priority: medium
ordinal: 86000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Revise all lessons in m6-feedlines-antennas and m3-station-practice-safety to the teaching guide (practical: coax in homes, wavelength and antenna length worked examples, SWR in plain terms, station grounding/power supply examples).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every lesson in scope is revised to docs/teaching-guide.md: plain language (terms defined at first use, short sentences, active voice), with a technical-accuracy pass
- [ ] #2 Each technical lesson gains at least one 'In the real world' example tied to everyday or station hardware, with worked numbers where useful (rule-reference lessons follow the reference-style rules in content/lessons/README.md)
- [ ] #3 Memory tricks from the guide are added where they help, are accurate and inoffensive, and say what they help remember
- [ ] #4 Coverage, quiz, explanation, originality and link checks pass; lesson IDs, front matter coverage and quiz references are unchanged; Illustration brief sections are left intact for task-38
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Revise M6 lessons first, preserving front matter and Illustration brief blocks while adding practical feedline, SWR, wavelength, antenna-length, tuner, and memory-trick teaching from docs/teaching-guide.md.\n2. Run the required content checks after the M6 slice, fix originality or coverage issues, record per-lesson fact/source notes, and commit the slice.\n3. Revise M3 lessons, preserving metadata and Illustration brief blocks while strengthening station block, power-supply, fusing, battery, grounding/bonding, electrical-code, and Safety Code 6 explanations with practical examples.\n4. Run the full required validation set, update pinned test expectations only if asserted text changed, finalize Backlog acceptance criteria with evidence, and commit the completed task.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
M6 slice revised: L-006-01 adds practical seventy-five-ohm home coax versus fifty-ohm amateur-radio coax and balun/feedpoint clarity (checked B-006-001-006, B-006-002-005, B-006-010-008); L-006-02 adds plain SWR/reflected-power caveat and tuner misconception without unsupported reflected-power fate claims (checked B-006-005-001, B-006-005-009, B-006-006-010); L-006-03 adds VHF wavelength worked example, 100 MHz wavelength memory trick, and practical dipole length example (checked B-006-008-003, B-006-008-011 and guide conventions); L-006-04 adds beam aiming example, Yagi element length and vertical length worked examples, and VHF half-wave convention note (checked B-006-010-001, B-006-010-003, B-006-011); L-006-05 adds support-direction example plus dipole/quad/loop worked examples (checked B-006-012 and B-006-013). M6 checks passed after originality fixes: coverage, quizzes, explanations, lesson originality, links, TZ=UTC pnpm test on rerun, and Swift package tests; first pnpm test attempt had transient web timing failures, rerun passed.
<!-- SECTION:NOTES:END -->
