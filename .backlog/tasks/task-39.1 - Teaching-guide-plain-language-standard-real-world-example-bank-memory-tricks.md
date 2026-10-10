---
id: TASK-39.1
title: >-
  Teaching guide: plain-language standard, real-world example bank, memory
  tricks
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 22:14'
updated_date: '2026-10-10 22:20'
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
- [ ] #1 docs/teaching-guide.md exists with the plain-language standard, an example bank covering all 8 modules (electronics deepest), a vetted memory-trick list with what each helps remember and its source, and a misconceptions list
- [ ] #2 Every technical example and trick is checked for accuracy (Canadian context: RBR-4, RIC-3, Canadian band plan where relevant) and the research sources are listed
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Verify renderer-supported Markdown and lesson conventions from existing docs, sample lessons, and parser code.\n2. Check regulatory and numeric claims from the research brief against docs/exam-facts.md and content/generated/basic-2025-07-15/questions.json; drop or mark unverified claims.\n3. Write docs/teaching-guide.md with concise writer guidance, supported templates, verified example bank, memory tricks, misconceptions, Canadian accuracy notes, originality rules, and revision checklist.\n4. Run docs/content checks, record evidence in task notes, check acceptance criteria, finalize task, and commit.
<!-- SECTION:PLAN:END -->
