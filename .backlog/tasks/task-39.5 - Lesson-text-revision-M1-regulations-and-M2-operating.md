---
id: TASK-39.5
title: 'Lesson text revision: M1 regulations and M2 operating'
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
ordinal: 88000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Revise all lessons in m1-regulations-policies and m2-operating-procedures to the teaching guide. M1 follows the reference-style rules in content/lessons/README.md (no Try-its, worked Q&A, practice items or Common mistakes); improve readability and add context and memory tricks within those rules. M2: practical on-air examples (a repeater contact, a simplex contact, giving a signal report).
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
1. Preserve front matter, covers, quiz IDs, and Illustration brief blocks while revising only lesson prose/tables in M1 and M2 reference-style lessons.
2. For M1, tighten rule prose, add approved memory aids for certificate/address, identification, and power qualification limits, and add practical context without Try-its or Common mistakes.
3. For M2, add practical procedure descriptions and short on-air examples inside allowed reference-style sections, plus approved memory aids for phonetics, RST, Q signals, and UTC/logging where useful.
4. Verify facts against questions.json and docs/exam-facts.md, run required content checks after M1, after M2, and final full checks, then record notes, AC evidence, and final summary through Backlog CLI.
<!-- SECTION:PLAN:END -->
