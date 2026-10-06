---
id: TASK-12.4
title: 'Morse visual, haptic and screen-reader alternatives'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-06 18:46'
labels:
  - web
  - apple
  - morse
  - accessibility
milestone: m-1
dependencies:
  - TASK-12.3
parent_task_id: TASK-12
priority: medium
ordinal: 42000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: Deaf and hard-of-hearing learners need non-audio ways to learn, and a flashing beacon must not risk seizures. See docs/proposals/morse-trainer.md (owner decisions in task-12 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A visual beacon meets WCAG 2.2 SC 2.3.1 (flash area under 25% of a 341x256 CSS px region, red-flash handling, cadence limits), plus a non-flashing tape display
- [ ] #2 Core Haptics is used only where supportsHaptics is true (in practice iPhone), with no haptic UI on tvOS or visionOS
- [ ] #3 VoiceOver/ARIA announcements don't talk over playback; accessibility audits pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add shared Morse output-mode primitives in TypeScript and Swift: output-mode persistence, schedule-to-beacon/tape/haptic events, and WCAG flash-safety calculations with tests.
2. Wire web Morse playback consumers (Quick listen, course, copy practice, exam) through the existing one-player coordinator for audio, visual beacon, and non-flashing tape; add settings, reduced-motion fallback, ARIA behavior, styles, and component tests.
3. Wire Apple iOS/iPadOS/macOS Morse playback consumers through the same settings for audio, visual beacon, non-flashing tape, and capability-gated Core Haptics on iPhone only; keep tvOS/visionOS basic with no new UI and localize EN/FR strings through the catalogue JSON round trip.
4. Run targeted TS/Swift tests and required web/Apple checks, record file:line evidence and per-test names in task notes, then finalize only with verified acceptance criteria.
<!-- SECTION:PLAN:END -->
