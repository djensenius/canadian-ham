---
id: TASK-11.13
title: Warn before a course switch discards unfinished work
status: Done
assignee:
  - '@worker'
created_date: '2026-10-05 13:33'
updated_date: '2026-10-05 21:52'
labels: []
dependencies:
  - TASK-11.5
parent_task_id: TASK-11
priority: low
ordinal: 66000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: switching course (Basic/Advanced) silently discards an unfinished mock exam or review session on web and Apple. Found in the task-11.5 review.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Switching course while a mock exam or review session is unfinished asks for confirmation on web and Apple (or keeps the session per course)
- [x] #2 Tests on web and Apple; accessible, EN/FR
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Locate web and Apple course-switch paths and existing session state for mock exams and practice/review sessions.
2. Add localized, accessible confirmation before discarding unfinished sessions; Cancel leaves the current course and session intact.
3. Add web component coverage and iOS UI coverage including light/dark unfiltered accessibility audits.
4. Run targeted tests, localization checks, web checks, and one full Apple run for each affected platform.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Started implementation after reading task-execution/task-finalization guidance, AGENTS testing policy, task-11.5 review notes, and PR #141 discussion.

Implemented web and Apple course-switch confirmation before discarding unfinished practice/mock sessions, with EN/FR strings and web/iOS UI coverage. Web pnpm test, typecheck, build, dist URL/CSP audit, and Apple text-source check passed; iOS targeted UI/unit runs are queued behind the xbuild lock.

Validation passed:
- Web component coverage: App.test.tsx confirms course switching with an unfinished mock exam opens an accessible alertdialog, Cancel preserves Basic and the mock session, and Confirm switches to Advanced.
- Apple UI coverage: testCourseSwitchConfirmationKeepsMockExamWhenCancelledLight and testCourseSwitchConfirmationAuditsDark both passed with default unfiltered performAccessibilityAudit() on the confirmation in light/dark.
- pnpm test/typecheck/build:web and dist URL/CSP audit passed.
- node scripts/check-apple-text-sources.ts and pnpm check:apple-l10n passed.
- Apple final suite via /tmp/t1112-apple-final-2.log: iOS full suite 60 tests passed; macOS full suite 53 tests passed; tvOS full suite 12 tests passed; visionOS full suite 9 tests passed. tvOS/visionOS were run because Localizable.xcstrings is bundled there too.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented confirmation before course switches discard unfinished mock/practice work on web and Apple settings flows, with EN/FR strings and light/dark UI audit coverage. Cancel keeps the current course/session; confirmed switches clear course-scoped session state through existing bank-change handling. Verified with web checks, Apple l10n/text-source checks, targeted UI tests, and full iOS/macOS/tvOS/visionOS xbuild suites.
<!-- SECTION:FINAL_SUMMARY:END -->
