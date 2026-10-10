---
id: TASK-39.4
title: 'Lesson text revision: M7 propagation and M8 interference'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 22:15'
updated_date: '2026-10-10 23:03'
labels:
  - content
dependencies:
  - TASK-39.1
parent_task_id: TASK-39
priority: medium
ordinal: 87000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Revise all lessons in m7-propagation and m8-interference-suppression to the teaching guide (practical: why AM broadcast carries further at night, FM range, everyday interference from chargers/LED bulbs, ferrite chokes on cables).
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
1. Revise M7 lesson bodies first, preserving all front matter, covers, quizIds, and Illustration brief sections exactly.
2. Run the required content, link, web, and Swift package checks after the M7 module slice, fix any lesson-originality or parser issues, then commit that slice.
3. Revise M8 lesson bodies with practical interference examples, ferrite/common-mode caveats, filter placement, 60 Hz hum distinction, and preserve protected metadata/briefs exactly.
4. Run the same full check set after M8 and final verification, update pinned expectations only if touched (not needed for L-007/L-008), then record evidence, check ACs, summarize, and mark Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
M7 revision complete. L-007-01: tightened path/layer prose, added valley/ridge/town real-world example, D/E/F order and D daytime damping memory tricks, and skip-zone power misconception; facts checked against B-007-001/002/003 including radio horizon, D/E/F order, midday/minimum ionization, skip geometry, 2 000 km E and 4 000 km F2 planning scales. L-007-02: added AM broadcast nighttime example, fading misconception, OWF worked calculation (18.6 MHz x 0.85 = 15.8 MHz), and clearer MUF/LUF guidance; facts checked against B-007-004/005/006 including D-region absorption, AM/daytime absorption, 11-year solar cycle, 20 m daylight usefulness, SID higher-frequency response, and OWF below MUF. L-007-03: added radio-horizon worked estimate (1.8 m handheld plus 100 m repeater gives 46.7 km), FM/VHF range teaching, and VHF-power misconception; facts checked against B-007-007/008 including sporadic E, 800 km normal VHF planning scale, aurora/CW, meteor scatter 30-100 MHz, and scatter clues. Required post-M7 checks passed: coverage, quizzes, explanations, lesson originality, links, TZ=UTC pnpm test, and content-swift swift test.

M8 revision complete. L-008-01: tightened overload/audio-rectification/spurious-emission prose, added charger/LED/computer/solar-inverter real-world source examples, powered-speaker example, ferrite common-mode caveat, and speaker-complaint misconception; facts checked against B-008-001/002/003 plus ferrite reactance/ferrite-core cures in B-005-010-007 and B-008-002-001. L-008-02: added 60 Hz hum vs RF harmonics distinction with recomputed 1/60 s = 0.0167 s = 16.7 ms, pass-name memory trick, LED-lamp and solar-inverter examples, and filter-placement emphasis; facts checked against B-008-004/005 plus low-pass placement concepts from B-003-001-001/B-003-001-002 and 60 Hz meaning from B-005-007-008. Required post-M8 checks passed after rerunning a transient web timeout: coverage, quizzes, explanations, lesson originality, links, TZ=UTC pnpm test, and content-swift swift test. Protected front matter and Illustration brief sections verified unchanged against main for all five lesson files.
<!-- SECTION:NOTES:END -->
