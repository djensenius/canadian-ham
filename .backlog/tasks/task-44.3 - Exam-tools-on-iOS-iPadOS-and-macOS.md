---
id: TASK-44.3
title: 'Exam tools on iOS, iPadOS and macOS'
status: To Do
assignee: []
created_date: '2026-10-12 14:39'
labels:
  - apple
dependencies:
  - TASK-44.1
parent_task_id: TASK-44
priority: medium
ordinal: 96000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apple UI for the calculator and reference sheet in practice and mock exams: iPhone a bottom sheet with medium and large detents and background interaction up through medium, so answers stay tappable; iPad regular width and macOS an inspector side panel; compact width falls back to the sheet; hardware-keyboard input; VoiceOver labels and announced results; Dynamic Type; French. The reference sheet is a zoomable view with an accessible text equivalent. The sheet source is pluggable per the owner's licensing decision.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 With either tool open, the question and answer choices remain visible and operable on iPhone, iPad (portrait, landscape, Split View) and Mac (UI tests assert hittable answers)
- [ ] #2 Full default accessibility audits pass with the tools open in light and dark; the largest text size works
- [ ] #3 The mock exam timer is unaffected
<!-- AC:END -->
