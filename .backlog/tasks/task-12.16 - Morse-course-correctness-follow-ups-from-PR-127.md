---
id: TASK-12.16
title: 'Morse course correctness follow-ups from PR #127'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-04 09:12'
updated_date: '2026-10-04 09:17'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.5
parent_task_id: TASK-12
priority: high
ordinal: 63000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: Copilot's final review of PR #127 found six issues in the new course code: the summary claims the next lesson unlocked after review sessions and after lesson 40; the daily streak resets to 0 at midnight until today's first lesson (TS and Swift); Apple builds progress dates with Calendar.current, so non-Gregorian calendars produce dates that don't match web; and the TypeScript course parser doesn't validate unit IDs while Swift does.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Summary copy depends on session mode and lesson position: reviews and lesson 40 never claim an unlock (web and Apple), with tests
- [x] #2 The daily streak counts back from today if there's activity today, otherwise from yesterday, so it only breaks after a missed day; identical in TS and Swift with a shared fixture
- [x] #3 Apple progress dates use a Gregorian calendar in the current time zone; the TS parser validates unit IDs unit-01..unit-08 like Swift; tests cover both
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Fix the shared Morse course engine behavior: daily streak starts from today or yesterday and TypeScript validates unit IDs unit-01..unit-08, then cover both with package tests/shared fixture.
2. Update web and Apple lesson summary copy so review sessions and final lesson completions do not claim a next unlock, and add tests.
3. Use a Gregorian current-time-zone date formatter for Apple local progress dates and cover it in Swift tests.
4. Run targeted package/web/Swift checks for the changed code before moving to task-12.15.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented shared Morse course correctness fixes. Targeted validation:
- packages/morse-engine Vitest: packages/morse-engine/test/course.test.ts and fixtures.test.ts passed (17 tests), including rejects course fixtures with unexpected unit IDs and shared course-streak fixture cases.
- packages/morse-swift: initial swift test without DEVELOPER_DIR failed because CommandLineTools could not resolve XCTest; reran with DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer and MorseFixtureTests/testEveryMorseFixtureMatchesSwiftEngine passed.
- web: pnpm --filter @canadian-ham/web test -- App.test.tsx passed (Vitest reported 13 files, 122 tests), including uses Morse course summary copy for review sessions and the final lesson.
- Apple targeted macOS xbuild unit tests passed: MorseTrainerTests/testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition and MorseTrainerTests/testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed Morse course summary copy for review/final-lesson sessions on web and Apple; changed TS/Swift daily streaks to count from today or yesterday using a shared fixture; made Apple local progress dates Gregorian in the current time zone; and added TS validation for unit IDs. Verified with package Vitest, DEVELOPER_DIR swift test, targeted web App tests, and targeted xbuild macOS unit tests named in notes.
<!-- SECTION:FINAL_SUMMARY:END -->
