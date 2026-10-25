---
id: TASK-14.3
title: watchOS Morse haptics practice
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T17:01:00Z'
updated_date: '2026-10-25T19:27:00Z'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the watch practice patterns, Morse timing and local tone drivers. 2. Implement session-only Morse settings, deterministic drill and cancellable WatchKit/tone playback with injectable scheduling. 3. Add focused unit/UI tests, localized strings and hardware-check documentation. 4. Run watch tests, localization/text/guard checks and iOS build-for-testing; record evidence, leave AC2 blocked for owner hardware check, commit and push.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation milestone: A–Z drill, session-only output settings, fixed click/directionUp mapping, clamped 1–2 WPM cadence and cancellable WatchKit/local synthesized tones implemented. Eight WatchMorseTests passed on Series 12 (42mm), watchOS 27.0; fixture-to-event/tone mapping, grading, replay, stale callback cancellation and spacing covered. Blocked: owner hardware check; AC2 remains unchecked. See docs/testing/task-14.3-watch-morse.md. Targeted watch UI tests and broader requested checks next.

Watch scheme run: 24/26 tests initially passed. Corrected practice-bundle validation to exclude the injected unit-test fixture bundle, native watch switch/picker/lazy Form automation, and a real Swift 6 audio-render callback isolation crash. Added a real tone-render/restart regression test. Targeted reruns now pass the failed practice-content test, all 9 Morse unit tests and the complete output-settings/text/tone UI test. Other five watch UI tests passed in the scheme run. Apple tool diagnostics report simctl collection noise after runs, but targeted final run is TEST SUCCEEDED. No hardware fidelity claim.
<!-- SECTION:NOTES:END -->
