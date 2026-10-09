---
id: TASK-12.19
title: Morse course navigation and playback test gaps
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-06 18:25'
updated_date: '2026-10-09 18:10'
labels: []
dependencies:
  - TASK-12.17
parent_task_id: TASK-12
priority: low
ordinal: 69000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the task-12.17 re-review approved the course redesign but listed untested paths. Back-stack placement of the state-driven lesson screen is unverified. The course-playback UI test doesn't observe course audio stopping. One locked-lesson assertion is vacuous. Review weakest characters and re-entering a finished lesson have no UI test. See ~/.cache/canadian-ham-reviews/t1217-r2.md.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 UI test: open lesson 1, go Back, see Unit 1 and the lesson list, reopen lesson 1 and get a fresh session (exercise 1)
- [x] #2 The course-playback test observes course audio stopping (for example, via a DEBUG status) instead of a check that can never fail; the locked-lesson test taps the disabled button before asserting no session
- [ ] #3 UI tests for 'Review weakest characters' and re-entering a finished lesson
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect existing Morse course UI tests and course playback/status hooks.\n2. Add UI coverage for opening lesson 1, Back to Unit 1/list, reopening with a fresh exercise 1 session.\n3. Make course playback stop observable in the UI test path and tap the disabled locked lesson before asserting no session.\n4. Add UI tests for Review weakest characters and re-entering a finished lesson.\n5. Run focused UI tests when the xbuild lock is available, then finalize with evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Morse course navigation/playback test gaps: task-12.19 AC1 now covered by apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:82-90, which opens lesson 1, verifies exercise 1, goes Back to Unit 1/lesson list, and reopens a fresh exercise-1 session. AC2 locked lesson path now coordinate-taps the disabled lesson before asserting no session at :77-81; course playback stop is observable with the DEBUG status added in apps/apple/CanadianHam/Morse/Course/MorseCourseView.swift:286-293 and asserted active/stopped in CanadianHamPracticeUITests.swift:540-573. AC3 review weakest and finished-lesson re-entry are covered at CanadianHamPracticeUITests.swift:143-167. Focused UI tests still need to run through xbuild when the build lock is available.

Final validation passed on tip 6b892eaafeae1c5a29da15f01cdb7da6d860e962. iOS targeted pass included CanadianHamPracticeUITests/testMorseSectionIsTopLevelShowsCourseAndOpensFirstLesson, /testLeavingCourseLessonStopsCoursePlaybackBeforeQuickListen, and /testMorseCourseReviewAndFinishedLessonReentryOnIOS; full iOS also passed those tests in the 139/139 suite. Full Apple suites passed on final code: iOS 139/139, macOS 67/67, tvOS 15/15, visionOS 12/12. The course playback test now observes DEBUG status active/stopped; the locked lesson path taps the disabled button before asserting no session; review weakest and finished-lesson re-entry have UI coverage. Earlier full iOS failure was unrelated to task-12.19 and came from task-12.20 post-settle visibility assertion strictness; fixed and targeted rerun passed twice before full suites.

Review r1 reopened task: AC #1 and #3 were unchecked because the prior UI tests did not prove Back returned to Unit 1's lesson list without reopening the unit and did not prove finished lesson re-entry/review weakest under the required navigation semantics. Implementing requested fixes after merging origin/main.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added Morse course UI coverage for back-stack/fresh-session behavior, observable playback stop, disabled locked-lesson tap, review weakest characters, and finished lesson re-entry. Verified by targeted iOS tests and full Apple suites.
<!-- SECTION:FINAL_SUMMARY:END -->
