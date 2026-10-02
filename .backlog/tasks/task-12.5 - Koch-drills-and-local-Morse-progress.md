---
id: TASK-12.5
title: Koch drills and local Morse progress
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.3
parent_task_id: TASK-12
priority: medium
ordinal: 43000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the Koch method with Farnsworth spacing is the proven way to learn copy by ear; progress must stay on-device. See docs/proposals/morse-trainer.md (owner decisions in task-12 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A 40-lesson Koch curriculum (G4FON order adapted to the ISED character set) unlocks lessons at 90% accuracy
- [ ] #2 Drill views on web and Apple give instant keyboard feedback
- [ ] #3 Character mastery is stored locally (IndexedDB on web, the Apple progress store) and included in progress export/import with schema updates
<!-- AC:END -->
