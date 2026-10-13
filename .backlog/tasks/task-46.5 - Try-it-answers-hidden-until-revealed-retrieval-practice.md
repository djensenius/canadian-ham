---
id: TASK-46.5
title: Try it answers hidden until revealed (retrieval practice)
status: To Do
assignee: []
created_date: '2026-10-12 14:57'
labels:
  - content
  - web
  - apple
dependencies: []
parent_task_id: TASK-46
priority: medium
ordinal: 103000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Today every Try it shows its answer on the same line, so there is no retrieval practice. Add a lesson-format convention for Try it answers and render them hidden behind an accessible Show answer control on web and Apple (iOS, iPadOS, macOS, visionOS; tvOS reveals on focus/select). Convert all existing Try it items.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Answers are hidden by default and revealed by an accessible control (keyboard, VoiceOver, screen readers; the state is announced)
- [ ] #2 All lessons converted; the content checker validates the format
- [ ] #3 Full default accessibility audits pass in light and dark on every platform that renders lessons
<!-- AC:END -->
