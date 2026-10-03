---
id: TASK-12.5
title: Duolingo-style Morse course (Koch method) with local progress
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
updated_date: '2026-10-03 12:04'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.12
parent_task_id: TASK-12
priority: medium
ordinal: 43000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner wants formal, Duolingo-like training where you really learn Morse by ear (2026-10-02 decision in task-12), not just a player. The Koch method with Farnsworth spacing is the proven approach (docs/proposals/morse-trainer.md); progress must stay on-device.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A course path of 40 Koch lessons (G4FON order adapted to the ISED character set) grouped into units, shown as a visual path with locked, current and completed lessons; each lesson introduces 1-2 new characters and unlocks the next at 90% accuracy
- [ ] #2 Lessons are short sessions mixing exercise types: meet the character (hear it, see its dits and dahs), listen and choose from options, listen and type single characters, and listen and type 5-character groups at Farnsworth speed, with instant feedback and a lesson summary
- [ ] #3 A review session practises the weakest characters (by recent accuracy) and a local daily streak and lesson count encourage regular practice, with no accounts, notifications or network
- [ ] #4 Per-character mastery and course progress are stored locally (IndexedDB on web, the Apple progress store) and included in progress export/import with schema and shared TS/Swift fixture updates
- [ ] #5 Fully accessible: keyboard and VoiceOver/screen-reader operable, announcements don't talk over audio, Reduce Motion respected, French UI; web axe and Apple light/dark audits pass on web, iOS/iPadOS, macOS (unit) , tvOS and visionOS (tvOS/visionOS may offer a simplified lesson flow)
<!-- AC:END -->
