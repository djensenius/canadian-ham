---
id: TASK-12.12
title: Make Morse a top-level section
status: To Do
assignee: []
created_date: '2026-10-03 12:03'
labels:
  - web
  - apple
  - morse
  - accessibility
milestone: m-1
dependencies:
  - TASK-12.3
parent_task_id: TASK-12
priority: high
ordinal: 58000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner tried the preview and doesn't want Morse buried behind a Settings toggle (2026-10-02 decision in task-12). Morse becomes its own always-visible section, with its settings inside the section (web, iOS/iPadOS) or in native Settings on macOS (task-30). A small 'Preview' label stays until the course (task-12.5) and copy practice/exam (task-12.6) land.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Morse is a top-level section on every platform: web top navigation (#/morse), iOS/iPadOS tab or sidebar, macOS sidebar, tvOS and visionOS menu entry; the preview toggle and its gating/redirect code are removed, and task-12.10 is closed as obsolete with a note
- [ ] #2 Morse settings (tone, speeds, timing profile, volume, ISED exam preset) live inside the Morse section on web and iOS/iPadOS; existing stored Morse preferences migrate without loss
- [ ] #3 The section has a Morse home that will host Learn (course), Practice (copy) and Exam entries; for now it hosts the existing player, labelled Preview
- [ ] #4 Accessibility audits (axe on web; light and dark Apple audits on iOS, tvOS and visionOS), French UI, and the web and four Apple xbuild suites pass
<!-- AC:END -->
