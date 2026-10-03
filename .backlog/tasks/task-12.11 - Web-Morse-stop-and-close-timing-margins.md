---
id: TASK-12.11
title: Web Morse stop and close timing margins
status: To Do
assignee: []
created_date: '2026-10-03 03:18'
labels:
  - web
  - morse
milestone: m-1
dependencies:
  - TASK-12.3
parent_task_id: TASK-12
priority: low
ordinal: 57000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the task-12.3 final review found web edge cases: (1) close() waits exactly the 5 ms ramp by wall clock before context.close(), but browsers render whole device buffers, so leaving the page mid-tone can still click; (2) the stop fade is anchored at context.currentTime, which can lag (Firefox reduces timer precision), shortening or skipping the ramp; (3) out-of-range number input reverts silently.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 close() waits at least ramp + baseLatency + outputLatency + a margin (about 100 ms total), with a test
- [ ] #2 The stop fade is robust to a stale currentTime (e.g. setTargetAtTime from currentTime, or a ramp started slightly ahead), with a test
- [ ] #3 Out-of-range Morse number input explains the revert or clamps, announced politely; web tests and axe pass
<!-- AC:END -->
