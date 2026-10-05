---
id: TASK-12.14
title: Use shared Morse audio controller in course flows
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-04 05:20'
updated_date: '2026-10-05 04:30'
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
- [x] #1 Web course playback uses the same shared one-player-at-a-time controller as copy practice and the simulated receiving exam.
- [x] #2 Apple course playback uses the same shared Morse playback coordinator as the other Morse modes.
- [x] #3 Tests or targeted manual checks cover starting course audio while another Morse mode is active and confirm only one playback remains active.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Fix the web course-vs-copy regression test so it observes the course player's own stop signal/state instead of global oscillator stop counts.\n2. Inspect Apple view wiring and add an iOS UI test for starting another Morse mode while course playback is active if the existing accessibility identifiers make that feasible without product changes.\n3. Run targeted changed tests while iterating, then final web checks and one full iOS plus one full macOS CanadianHam xbuild suite.\n4. Record full-suite per-test names in task-12.14 notes and return task-12.14 to Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented shared course playback coordination. Web: MorseCoursePanel now registers as owner "course" with the existing MorsePlaybackCoordinator, claims before every course play, and App passes the same coordinator used by Quick listen/copy/exam. Apple: MorseCourseView now accepts the MorsePlaybackCoordinator, registers owner "course", claims before course play, and unregisters/stops on disappear. Tests added/updated: apps/web/src/App.test.tsx "coordinates course audio with the shared one-player-at-a-time Morse controller"; apps/apple/CanadianHamTests/MorseTrainerTests/testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime; apps/apple/CanadianHamUITests/CanadianHamPracticeUITests/testMorseStartingCourseAudioStopsCopyPlayback. Validation passed: pnpm test -- --run apps/web/src/App.test.tsx -t "coordinates course audio|stops any active Morse playback" (also ran package prechecks; web Vitest reported 13 files/123 tests passed). Validation passed: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination "platform=iOS Simulator,name=iPhone 17 Pro" -only-testing:CanadianHamTests/MorseTrainerTests/testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testMorseStartingCourseAudioStopsCopyPlayback -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testMorseStartingQuickListenStopsCopyPlayback test CODE_SIGNING_ALLOWED=NO; per-test passed: MorseTrainerTests/testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime, CanadianHamPracticeUITests/testMorseStartingCourseAudioStopsCopyPlayback, CanadianHamPracticeUITests/testMorseStartingQuickListenStopsCopyPlayback.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Course playback on web and Apple now uses the shared one-player-at-a-time Morse controller. Verified with web integration coverage for course vs Quick listen/copy, Apple coordinator unit coverage, and targeted iOS UI tests for course/Quick listen/copy ownership.
<!-- SECTION:FINAL_SUMMARY:END -->
