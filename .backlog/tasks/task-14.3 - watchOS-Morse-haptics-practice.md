---
id: TASK-14.3
title: watchOS Morse haptics practice
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T17:01:00Z'
updated_date: '2026-10-25T19:34:00Z'
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
- [x] #1 A Morse drill plays one A-Z character through a WatchKit WKHapticType adapter driven by morse-swift TimedMorseSequence, then offers four distinct pick-the-letter answers with immediate textual feedback, Replay and Next; no course/progress or exam claims are added.
- [ ] #2 The fixed-preset dot/dash mapping, supported cadence/speed and actual hardware observations are documented; a physical watch distinguishes representative short, long and mixed characters without overlapping/collapsed patterns. Unreliable output blocks completion and is escalated.
- [x] #3 Optional locally generated tones can be enabled independently of haptics; audio-off/haptics-off states have a non-flashing dot/dash text alternative and an accessible unavailable-output message where appropriate, without recording audio or accessing a network.
- [x] #4 Replay does not overlap output or reveal/speak the answer prematurely; leaving the screen, inactivity, interruption and advancing cancel pending playback. No workout/location/extended background session is used.
- [x] #5 Unit tests verify sequence-to-output mapping, correct/wrong pick grading, replay and cancellation using existing timing fixtures; targeted watch UI tests verify play/replay/answer/Next and output settings via xbuild, with per-test results recorded.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the watch practice patterns, Morse timing and local tone drivers. 2. Implement session-only Morse settings, deterministic drill and cancellable WatchKit/tone playback with injectable scheduling. 3. Add focused unit/UI tests, localized strings and hardware-check documentation. 4. Run watch tests, localization/text/guard checks and iOS build-for-testing; record evidence, leave AC2 blocked for owner hardware check, commit and push.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation milestone: A–Z drill, session-only output settings, fixed click/directionUp mapping, clamped 1–2 WPM cadence and cancellable WatchKit/local synthesized tones implemented. Eight WatchMorseTests passed on Series 12 (42mm), watchOS 27.0; fixture-to-event/tone mapping, grading, replay, stale callback cancellation and spacing covered. Blocked: owner hardware check; AC2 remains unchecked. See docs/testing/task-14.3-watch-morse.md. Targeted watch UI tests and broader requested checks next.

Watch scheme run: 24/26 tests initially passed. Corrected practice-bundle validation to exclude the injected unit-test fixture bundle, native watch switch/picker/lazy Form automation, and a real Swift 6 audio-render callback isolation crash. Added a real tone-render/restart regression test. Targeted reruns now pass the failed practice-content test, all 9 Morse unit tests and the complete output-settings/text/tone UI test. Other five watch UI tests passed in the scheme run. Apple tool diagnostics report simctl collection noise after runs, but targeted final run is TEST SUCCEEDED. No hardware fidelity claim.

Acceptance evidence: AC1 seeded watch play/replay/answer/Next UI and 100 seeded grading/choice unit cases passed. AC3 independent haptic/tone matrix, real AVAudioSourceNode render/restart regression, tone-only UI and static requested text/no-output message UI passed. AC4 overlap guard, stale callback invalidation, cancellation before/mid-sequence, Next cooldown, delayed-scheduler safety and pre-answer UI non-reveal assertions passed; exit/scene/interruption/media-reset hooks all call the same tested cancel path. AC5 21 watch unit + 6 UI tests have passing evidence across the scheme run and targeted fix reruns; per-test rows are in docs/testing/task-14.3-watch-morse.md. pnpm check:apple-l10n (final export unchanged), text-source gate/self-test, network/iCloud guards/self-tests, test guard/self-test, deterministic XcodeGen, iOS build-for-testing and macOS 223/223 unit tests passed. macOS per-test rows: docs/testing/task-14.3-macos-unit-results.md. No shared Swift/package changes, so morse-swift swift test was not required. No full iOS/tvOS/visionOS suites: only additive watch strings outside watch targets; localization builds cover them, merge-batch suites remain coordinator-owned. Blocked: owner hardware check. AC2 stays unchecked and TASK-14.3 stays In Progress. No physical haptic fidelity, VoiceOver listening, TestFlight upload or PR claimed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented offline A–Z watch Morse practice with four choices, feedback, Replay/Next, cancellable WatchKit presets and independent local tones, session-only settings and accessible static text fallback. Candidate mapping click/directionUp and conservative 1–2 WPM/1.2-second onset floor are documented for owner hardware validation. Automated evidence passes (27 distinct watch tests across scheme/targeted runs, 223 macOS units, iOS test build, localization and guards). AC1/3/4/5 checked; AC2 remains blocked for the physical-watch observations documented in docs/testing/task-14.3-watch-morse.md. Task intentionally remains In Progress.
<!-- SECTION:FINAL_SUMMARY:END -->
