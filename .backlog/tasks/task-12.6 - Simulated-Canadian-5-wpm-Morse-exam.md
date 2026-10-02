---
id: TASK-12.6
title: Simulated Canadian 5 wpm Morse exam
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.2
  - TASK-12.3
parent_task_id: TASK-12
priority: medium
ordinal: 44000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: candidates need practice in the real ISED format: 3 minutes of uninterrupted copy, a 2-minute review, and the RIC-1/RIC-3 pass rule. See docs/proposals/morse-trainer.md (owner decisions in task-12 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The text generator follows RIC-1 section 8.2 (at least 75 weighted characters and 180 s for the chosen profile); the default profile is isedParis 12/5 with ric1Literal as a harder option
- [ ] #2 Playback is uninterrupted, followed by a 2-minute review; grading is 5 or fewer errors = pass (100%), otherwise fail, with a diff view
- [ ] #3 Web and Apple tests cover generation, timing and grading with the shared fixtures
<!-- AC:END -->
