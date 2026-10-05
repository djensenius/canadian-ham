---
id: TASK-12.14
title: Use shared Morse audio controller in course flows
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-04 05:20'
updated_date: '2026-10-05 00:01'
labels: []
milestone: m-1
dependencies: []
parent_task_id: TASK-12
ordinal: 61000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: task-12.5 introduced web and Apple Morse course playback after task-12.6 added shared one-player-at-a-time Morse audio coordination. The course currently uses its own web player and Apple driver, so course playback can overlap copy practice or simulated exam audio instead of respecting the shared Morse audio policy.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Web course playback uses the same shared one-player-at-a-time controller as copy practice and the simulated receiving exam.
- [ ] #2 Apple course playback uses the same shared Morse playback coordinator as the other Morse modes.
- [ ] #3 Tests or targeted manual checks cover starting course audio while another Morse mode is active and confirm only one playback remains active.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Wire web MorseCoursePanel into the existing MorsePlaybackCoordinator used by Quick listen, copy practice, and exam, including course stop registration and claim-on-play.
2. Wire Apple MorseCourseView into the shared MorsePlaybackCoordinator and stop course playback when other Morse modes claim audio.
3. Add web and iOS UI coverage that starts course audio while another Morse mode is active and starts another Morse mode while course audio is active.
4. Run targeted web and Apple tests, then finalize task-12.14 with evidence before starting task-12.17.
<!-- SECTION:PLAN:END -->
