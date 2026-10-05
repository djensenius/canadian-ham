---
id: TASK-12.7
title: Morse sending practice with tap timing
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-05 04:35'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.6
parent_task_id: TASK-12
priority: medium
ordinal: 45000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the Morse qualification includes sending; the owner chose tap timing on keyboard or touch so no microphone permission is needed. See docs/proposals/morse-trainer.md (owner decisions in task-12 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Straight-key and paddle emulation on keyboard and touch, with dot/dash ratio feedback
- [ ] #2 An exam-style check: whole text within 3:00, the 8-dot error signal and resend accepted, 5 or fewer errors to pass
- [ ] #3 No microphone permission or new entitlements; tests pass on web and Apple
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect existing Morse engine/audio/copy exam flows and platform routing to identify narrow seams for sending practice.\n2. Add shared TS/Swift timing decode/scoring helpers plus JSON fixtures for tap classification and 8-dot error signal behavior.\n3. Add web sending practice and exam-style sending screens using the existing Morse audio controller and copy/exam corpus generator, with keyboard/touch controls and tests.\n4. Add iPhone/iPad/Mac sending practice/results screens using the Swift Morse engine/audio controller, DEBUG-only deterministic UI-test hook, localization strings, unit/UI tests, and leave tvOS/visionOS unchanged.\n5. Run targeted checks while iterating, then required web/package/Apple validations and record evidence before finalizing.
<!-- SECTION:PLAN:END -->
