---
id: TASK-39.4
title: 'Lesson text revision: M7 propagation and M8 interference'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 22:15'
updated_date: '2026-10-10 22:52'
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
1. Revise M7 lesson bodies first, preserving all front matter, covers, quizIds, and Illustration brief sections exactly.\n2. Run the required content, link, web, and Swift package checks after the M7 module slice, fix any lesson-originality or parser issues, then commit that slice.\n3. Revise M8 lesson bodies with practical interference examples, ferrite/common-mode caveats, filter placement, 60 Hz hum distinction, and preserve protected metadata/briefs exactly.\n4. Run the same full check set after M8 and again as final verification if fixes are needed, update pinned expectations only if touched (not expected for L-007/L-008), then record evidence, check ACs, summarize, and mark Done.
<!-- SECTION:PLAN:END -->
