---
id: TASK-77
title: >-
  Mock exam header: replace the inner ViewThatFits and let the default navigator
  sheet scroll
status: To Do
assignee: []
created_date: '2026-10-26T16:14:00Z'
labels:
  - accessibility
  - layout
dependencies: []
priority: low
ordinal: 162000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found in the TASK-74 review. The mock header still has two inner ViewThatFits (flagAndNavigatorControls, quickJumpControls). Under the owner's 2026-10-18 single-tree layout rule, they should become measured-fit single-tree layouts like MockExamHeaderControlLayout, because rejected candidates can leak accessibility nodes the way TASK-74's outer header did. Also, the default-size iPhone question navigator sheet doesn't scroll (TASK-74 fixed only accessibility sizes); with a 100-question exam in iPhone landscape, the grid probably doesn't fit.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Both inner ViewThatFits in the mock header are replaced by single-tree measured-fit layouts, with pixel-identical before/after screenshots in every layout they choose
- [ ] #2 The question navigator sheet scrolls at every text size; a 100-question mock exam's full grid is reachable in iPhone portrait and landscape
- [ ] #3 The targeted iPhone and iPad mock exam tests and audits pass via xbuild
<!-- AC:END -->
