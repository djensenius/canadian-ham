---
id: TASK-12.7
title: Morse sending practice with tap timing
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
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
