---
id: TASK-44.5
title: Cover official reference sheet in Apple mock exams
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-22 02:16'
updated_date: '2026-10-24 22:42'
labels:
  - apple
  - testing
dependencies:
  - TASK-44.4
parent_task_id: TASK-44
priority: medium
ordinal: 146000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-44.4 internal review noted that the reference-sheet integration is exercised from practice but not mock exams. Cover the actual Basic mock-exam tool path without changing approved accessibility exceptions or exposing hints in mock exams. Official assets remain internal-only and Advanced has no Basic sheet.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An Apple UI test opens the official sheet from a Basic mock exam and verifies page, zoom, accessible text and Study sheet fallback.
- [ ] #2 Using and closing the sheet preserves the current mock question, selected answer and exam progress.
- [ ] #3 Targeted iPhone and iPad checks and full-default accessibility audits pass, with only already-approved exception scopes if required.
- [ ] #4 Advanced mock exams still do not offer the Basic reference sheet and no mock exam offers hints.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect TASK-44.4/TASK-67, existing reference/mock tests and approved scope-specific helpers; leave existing tests/helpers unchanged.
2. Add Basic mock light/dark official-sheet coverage for pages, zoom, accessible text, Study fallback, question/answer/progress preservation and running/paused timer continuity; add Advanced/no-hints negative coverage. Fix only app bugs demonstrated by these tests.
3. Run targeted new and existing reference tests on iPhone 17 Pro and iPad Pro 13-inch (M5), the documented macOS unit command, l10n/text-source/test-guard checks via nohup and grep polling; no full simulator suites.
4. Record per-test evidence, finalize all four criteria, commit and push the task branch without a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added three UI tests in CanadianHamExamToolsUITests: Basic mock light/running and dark/paused sheet flows plus Advanced/no-sheet/no-hints negative coverage. Basic fixtures answer two questions and remain on question 2/3, then exercise all five pages/back navigation, zoom in/out, accessible formula text and Study fallback before verifying question/answer/exam seed/answered count and timer continuity. Full-default audits use raw calls for official image/text and iPhone fallback, the unchanged TASK-44.4 reference-scroll helper only for iPad fallback, and the unchanged occluded mock-screen helper before/after. No existing tests, shared helpers or app source changed. Targeted iPhone/iPad, documented macOS units, l10n/text/guard checks are running via nohup (/tmp/task445-checks.log), one destination at a time; no full simulator suites or killed builds.

First targeted iPhone attempt reached Study fallback but failed a new over-strict heading assertion: LessonMarkdownView intentionally suppresses a level-1 heading matching its supplied title. Corrected the new test to assert the actual accessible Study introduction and Ohm\x27s law heading instead. Official transcript title/formula assertions passed. This is a test-fixture correction, not an app bug; existing tests/helpers remain unchanged. The ongoing runner is not interrupted; iPad will build the correction, and only the two affected iPhone mock methods will be rerun.
<!-- SECTION:NOTES:END -->
