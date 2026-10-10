---
id: TASK-39.3
title: 'Lesson text revision: M6 feedlines/antennas and M3 station/safety'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 22:15'
updated_date: '2026-10-10 22:53'
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
