---
id: TASK-12.2
title: Morse timing engine and shared fixtures
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-1
parent_task_id: TASK-12
priority: medium
ordinal: 40000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: every Morse feature (audio, drills, exam, sending) depends on exact, testable timing that matches the ISED/RIC-1 rules, the same on web and Apple. See docs/proposals/morse-trainer.md (owner decisions in task-12 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 @canadian-ham/morse-engine (TS) and CanadianHamMorseEngine (SwiftPM) turn text into timed symbols with general Farnsworth timing and the isedParis (12/5, 1.405 s / 3.279 s) and ric1Literal (0.7 s / 1.7 s) profiles; effective speed is clamped to at most the character speed
- [ ] #2 The character set is limited to RIC-1 section 8.2; figures and punctuation weigh 2 for word counts
- [ ] #3 Shared fixtures in fixtures/morse/ (PARIS 12.0 s isedParis and 7.6 s ric1Literal, the RIC-1 section 8.3 sample = 78 weighted characters, error scoring with 5 errors = pass and 6 = fail, insertions) pass in both languages
<!-- AC:END -->
