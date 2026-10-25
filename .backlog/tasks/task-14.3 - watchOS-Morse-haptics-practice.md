---
id: TASK-14.3
title: watchOS Morse haptics practice
status: To Do
assignee: []
created_date: '2026-10-25T17:01:00Z'
labels:
  - apple
  - watchos
milestone: m-1
dependencies:
  - TASK-14.2
documentation:
  - docs/proposals/watchos-companion.md
parent_task_id: TASK-14
type: feature
ordinal: 157000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
One-character listening/feeling drills make Morse useful on the wrist without bringing over the full Koch course or exam. Reuse morse-swift timing, not the existing iOS-only Core Haptics driver. WatchKit WKHapticType plays fixed presets, so pulse duration/cadence and dot/dash recognisability must be demonstrated on physical hardware; simulator success alone is not evidence of tactile fidelity. Escalate if that gate fails instead of silently changing the approved use case.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A Morse drill plays one A-Z character through a WatchKit WKHapticType adapter driven by morse-swift TimedMorseSequence, then offers four distinct pick-the-letter answers with immediate textual feedback, Replay and Next; no course/progress or exam claims are added.
- [ ] #2 The fixed-preset dot/dash mapping, supported cadence/speed and actual hardware observations are documented; a physical watch distinguishes representative short, long and mixed characters without overlapping/collapsed patterns. Unreliable output blocks completion and is escalated.
- [ ] #3 Optional locally generated tones can be enabled independently of haptics; audio-off/haptics-off states have a non-flashing dot/dash text alternative and an accessible unavailable-output message where appropriate, without recording audio or accessing a network.
- [ ] #4 Replay does not overlap output or reveal/speak the answer prematurely; leaving the screen, inactivity, interruption and advancing cancel pending playback. No workout/location/extended background session is used.
- [ ] #5 Unit tests verify sequence-to-output mapping, correct/wrong pick grading, replay and cancellation using existing timing fixtures; targeted watch UI tests verify play/replay/answer/Next and output settings via xbuild, with per-test results recorded.
<!-- AC:END -->
