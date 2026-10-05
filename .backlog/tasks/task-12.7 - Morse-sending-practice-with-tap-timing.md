---
id: TASK-12.7
title: Morse sending practice with tap timing
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-05 20:31'
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Morse sending practice: shared TS/Swift helpers classify straight-key key-down durations, decode elements including 8-dot error signal, apply resend/delete behavior, and score sending with existing exam diff/pass rule. Added web Sending practice (keyboard/touch straight key plus iambic paddles, side-tone through shared WebMorsePlayer, feedback, exam timer/results) and Apple iPhone/iPad/Mac pushed Sending practice/results screens with DEBUG-only deterministic UI-test hook. tvOS and visionOS were intentionally left at their existing basic Morse screens; they only pick up shared engine/audio package changes through linking. Reverted the six out-of-scope Morse course stat commits with git revert as requested; no hard-coded Color.black/Color.white or accessibilityHidden course-stat workaround remains. Merged origin/main in commit 7d6bee577c2f7c8a11b8e8c68c2a1b1bc75d4b12 and resolved Localizable.xcstrings via JSON round-trip.
<!-- SECTION:NOTES:END -->
