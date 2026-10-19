---
id: TASK-46.12
title: Realign lesson figures after the TASK-46.10 coverage split
status: To Do
assignee: []
created_date: '2026-10-19 23:09'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
ordinal: 138000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
PR #302 review identified two figure/lesson mismatches after the lesson split: transformer-resonance-meters in L-005-06 still contains a resonance panel and high-impedance-at-resonance brief although resonance is now taught in L-005-05; communications-flowchart in L-001-03 retains a third-party lane although B-001-014 is now taught in L-001-05. Keep the diagrams, text equivalents and briefs aligned with the material taught in each lesson without changing official question-bank text.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The transformer/resonance/meters figure and its brief/text equivalent match their host lesson; resonance is explained with the L-005-05 material rather than presented as already taught in L-005-06.
- [ ] #2 The communications flowchart, brief and text equivalent in L-001-03 no longer assume the third-party rules taught later in L-001-05.
- [ ] #3 Figure, content-link and targeted lesson-figure accessibility checks pass for the changed figures/lessons.
<!-- AC:END -->
