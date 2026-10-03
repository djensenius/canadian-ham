---
id: TASK-12.6
title: Morse copy practice and simulated Canadian 5 wpm exam
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
updated_date: '2026-10-03 12:03'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.12
parent_task_id: TASK-12
priority: medium
ordinal: 44000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: learners need to listen to whole passages and type what they hear, and candidates need practice in the real ISED format: 3 minutes of uninterrupted copy, a 2-minute review, and the RIC-1/RIC-3 pass rule (owner decision 2026-10-02 in task-12). See docs/proposals/morse-trainer.md.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The text generator follows RIC-1 section 8.2 (at least 75 weighted characters and 180 s for the chosen profile); the default profile is isedParis 12/5 with ric1Literal as a harder option
- [ ] #2 Playback is uninterrupted, followed by a 2-minute review; grading is 5 or fewer errors = pass (100%), otherwise fail, with a diff view
- [ ] #3 Web and Apple tests cover generation, timing and grading with the shared fixtures
- [ ] #4 Copy practice: listen to a full passage (plain-language sentences or QSO-style text) at the user's settings, type it, and see a character-level diff with wrong, missing and inserted characters highlighted, accessible to screen readers
<!-- AC:END -->
