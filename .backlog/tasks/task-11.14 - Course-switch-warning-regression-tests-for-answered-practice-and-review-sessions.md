---
id: TASK-11.14
title: >-
  Course-switch warning: regression tests for answered practice and review
  sessions
status: Done
assignee:
  - '@worker'
created_date: '2026-10-06 03:22'
updated_date: '2026-10-09 10:25'
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
- [x] #2 Apple UI tests cover the same cases on iOS (targeted runs plus the policy's full runs)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add web course-switch regression tests for answered immediate practice, unsubmitted review-later practice, confirm discard, cancel preserve, and submitted-review no prompt.\n2. Add matching iOS UI coverage for Apple course switching.\n3. Run targeted web and Apple UI tests, then final affected platform suites.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added web course-switch regressions in apps/web/src/App.test.tsx:1065 for partially answered immediate practice, apps/web/src/App.test.tsx:1092 for fully answered unsubmitted review-later practice, and apps/web/src/App.test.tsx:1120 for submitted review-later no-prompt. Added iOS UI coverage in apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:1010, :1040, and :1065. Targeted iOS per-test results: CanadianHamTests.QuestionBankTests/testAppBundleContainsOnlyExpectedGeneratedBankDirectories passed; CanadianHamPracticeUITests/testCourseSwitchConfirmationCoversAnsweredImmediatePractice passed; CanadianHamPracticeUITests/testCourseSwitchConfirmationCoversReviewLaterPracticeBeforeAndAfterSubmit passed; CanadianHamPracticeUITests/testSubmittedReviewLaterPracticeDoesNotWarnBeforeCourseSwitch passed. A first full iOS run hit a transient SpringBoard crash in testAccessibilityAuditPracticeSessionDark; targeted rerun of that unchanged full-default audit passed, then a second full iOS suite passed 74 tests/0 failures. Full macOS, tvOS, and visionOS xbuild suites also passed.

Review round 1 reopened task-11.14 AC #2: iOS UI coverage must restore real Cancel/Confirm assertions without starting a new session, rename tests to match behavior, and final Apple evidence must include per-test names/counts tied to the final commit.

Review fixes: restored iOS UI assertions in apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift. testCourseSwitchCancelKeepsImmediatePracticeFeedbackAndConfirmOpensAdvancedPractice verifies Cancel preserves answer feedback and Confirm opens Advanced A-001 practice. testCourseSwitchCancelKeepsUnsubmittedReviewLaterAnswersAndConfirmOpensAdvancedPractice verifies Cancel preserves Answered 1 of 1 plus Submit for review and Confirm opens Advanced A-001 practice. testSubmittedReviewLaterPracticeDoesNotWarnBeforeCourseSwitch verifies a submitted review-later session switches without warning. Added category button identifiers in apps/apple/CanadianHam/Views/StudyViews.swift so tests return to the existing/correct category flow rather than starting an unrelated new session. Kept the Advanced 70+68 below-threshold tests in packages/engine-ts/test/validation.test.ts and packages/engine-swift/Tests/CanadianHamEngineTests/ValidationTests.swift alongside the 70+70 inclusive case.

Final validation on code commit 8044afbf33ae76222dec781f32b8b0867bd242df: targeted iOS passed QuestionBankTests/testAppBundleContainsOnlyExpectedGeneratedBankDirectories, CanadianHamPracticeUITests/testCourseSwitchCancelKeepsImmediatePracticeFeedbackAndConfirmOpensAdvancedPractice, /testCourseSwitchCancelKeepsUnsubmittedReviewLaterAnswersAndConfirmOpensAdvancedPractice, and /testSubmittedReviewLaterPracticeDoesNotWarnBeforeCourseSwitch. Full iOS passed 66 CanadianHamTests and 74 CanadianHamUITests. Full macOS passed 68 CanadianHamTests. Full tvOS clean rerun passed 4 unit and 12 UI tests. Full visionOS clean rerun passed 4 unit and 9 UI tests. Earlier review-work full iOS hit a transient SpringBoard crash in testAccessibilityAuditPracticeSessionDark; targeted rerun and final full iOS passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Restored iOS course-switch assertions for Cancel-preserves and Confirm-discards/opens-Advanced behavior, kept submitted-review no-prompt coverage, and verified with targeted iOS plus final full Apple platform suites on code commit 8044afbf33ae76222dec781f32b8b0867bd242df.
<!-- SECTION:FINAL_SUMMARY:END -->
