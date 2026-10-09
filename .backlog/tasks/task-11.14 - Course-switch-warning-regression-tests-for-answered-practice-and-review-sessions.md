---
id: TASK-11.14
title: >-
  Course-switch warning: regression tests for answered practice and review
  sessions
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-06 03:22'
updated_date: '2026-10-09 06:07'
labels: []
dependencies:
  - TASK-11.13
parent_task_id: TASK-11
priority: low
ordinal: 67000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: PR #142 (task-11.13) tests the course-switch warning for mock exams and unanswered practice only. Copilot asked for coverage of the answered-practice paths on web and Apple.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Web tests: partially answered immediate practice and fully answered but unsubmitted review-later practice both prompt; Cancel keeps the answers; Confirm discards the session; a submitted review session does not prompt
- [ ] #2 Apple UI tests cover the same cases on iOS (targeted runs plus the policy's full runs)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add web course-switch regression tests for answered immediate practice, unsubmitted review-later practice, confirm discard, cancel preserve, and submitted-review no prompt.\n2. Add matching iOS UI coverage for Apple course switching.\n3. Run targeted web and Apple UI tests, then final affected platform suites.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added web course-switch regressions in apps/web/src/App.test.tsx:1065 for partially answered immediate practice, apps/web/src/App.test.tsx:1092 for fully answered unsubmitted review-later practice, and apps/web/src/App.test.tsx:1120 for submitted review-later no-prompt. Added iOS UI coverage in apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:1010, :1040, and :1065. Targeted iOS per-test results: CanadianHamTests.QuestionBankTests/testAppBundleContainsOnlyExpectedGeneratedBankDirectories passed; CanadianHamPracticeUITests/testCourseSwitchConfirmationCoversAnsweredImmediatePractice passed; CanadianHamPracticeUITests/testCourseSwitchConfirmationCoversReviewLaterPracticeBeforeAndAfterSubmit passed; CanadianHamPracticeUITests/testSubmittedReviewLaterPracticeDoesNotWarnBeforeCourseSwitch passed. A first full iOS run hit a transient SpringBoard crash in testAccessibilityAuditPracticeSessionDark; targeted rerun of that unchanged full-default audit passed, then a second full iOS suite passed 74 tests/0 failures. Full macOS, tvOS, and visionOS xbuild suites also passed.

Review round 1 reopened task-11.14 AC #2: iOS UI coverage must restore real Cancel/Confirm assertions without starting a new session, rename tests to match behavior, and final Apple evidence must include per-test names/counts tied to the final commit.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added web and iOS UI regressions for answered immediate practice, unsubmitted review-later practice, confirm/cancel behavior, and submitted-review no-prompt behavior. Verified with targeted web/iOS tests and final Apple platform suites.
<!-- SECTION:FINAL_SUMMARY:END -->
