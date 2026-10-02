---
id: TASK-12.4
title: 'Morse visual, haptic and screen-reader alternatives'
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
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
