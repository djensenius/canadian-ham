---
id: TASK-12.3
title: Morse audio drivers and settings
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
parent_task_id: TASK-12
priority: medium
ordinal: 41000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: learners must hear clean, click-free Morse offline on every platform, with no third-party audio code. See docs/proposals/morse-trainer.md (owner decisions in task-12 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Web Audio driver (oscillator with about 5 ms gain ramps, started by a user gesture) and an AVAudioEngine/AVAudioSourceNode driver on iOS, iPadOS, macOS, tvOS and visionOS
- [ ] #2 Settings for tone (400-900 Hz, default 650), character speed (12-25, default 15), effective speed (5 up to the character speed, default 5), timing profile and trainer volume, plus a one-tap ISED exam preset (12/5)
- [ ] #3 The Morse feature stays off by default until v1 Basic ships; no network or new permissions; tests pass on web and all four Apple platforms
<!-- AC:END -->
