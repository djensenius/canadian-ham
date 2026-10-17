---
id: TASK-50.12
title: 'Apple hint tool on iOS, iPadOS and macOS'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 07:58'
updated_date: '2026-10-17 20:04'
labels:
  - apple
dependencies:
  - TASK-44.3
  - TASK-50.11
  - TASK-50.15
  - TASK-53
parent_task_id: TASK-50
priority: high
type: task
ordinal: 126000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add the Hint tool to iOS/iPadOS/macOS practice and review sessions after task-44.3 supplies the Apple exam-tools surface and after the web behaviour is established. Hints must be hidden in mock exams and share the same progress semantics as web.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 iOS, iPadOS, and macOS practice/review sessions expose localized hints in the exam-tools UI created by task-44.3; mock exams do not.
- [x] #2 Opening a hint and answering records answered with help and applies the same mastery, weak-area, and spaced-review semantics as web.
- [x] #3 Apple accessibility tests cover the tool open state and hinted-answer flow on the affected platforms without widening to tvOS/visionOS.
- [x] #4 Reference-sheet pointer labels from referenceSheetSection are shown only on Apple surfaces where the reference sheet is available and hidden otherwise.
- [x] #5 Hint data is bundled into the Apple content package for iOS, iPadOS, and macOS offline use with the active Basic bank.
- [x] #6 A localized "Review in lesson" link from lessonLink appears with the last available hint level (Hint 2 for two-level files, Hint 1 for one-level files), notes in French UI that current lesson bodies are English-only, opens the linked lesson at sectionAnchor without discarding the in-progress practice/review session, and the Apple lesson reader renders the computed id on the target heading element using the shared fixtures/lesson-heading-anchors.json algorithm and Swift fixture test, keeps heading IDs unique per page, and moves focus to the target heading after navigation.
- [x] #7 The hint tool handles one-level hint files by presenting only Hint 1, with no empty or broken Hint 2 affordance.
- [x] #8 The lesson link uses a generic localized label ("Review in lesson" / « Revoir dans la leçon ») and never shows the linked section heading or lesson title before the question is answered, because some headings contain answer words (e.g. "Sporadic E and six metres")
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Trace the web hint implementation and Apple practice/review/exam-tools surfaces, including progress submission, bundled content generation, lesson navigation, localization, and existing tests.
2. Add bundled Apple Basic hint data and Swift models/loaders gated to iOS/iPadOS/macOS practice and review sessions, leaving mock exams, lesson quizzes, tvOS, and visionOS unchanged.
3. Add the Hint tool to the existing exam-tools UI with the approved ladder, stable 0.5 s shown qualification, reference-sheet availability gating, session-level help state, lesson-link navigation, and answeredWithHelp progress recording.
4. Port the shared lesson heading-anchor algorithm to Swift, render unique heading IDs, and focus linked lesson headings after hint navigation.
5. Add targeted unit/UI/accessibility tests and run the requested content, web/package, and xbuild checks before finalizing the Backlog task.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Validation and AC audit after continuing at 01451d4e/882ac42f:
- iPhone 17 Pro targeted xbuild: CanadianHamExamToolsUITests + CanadianHamPracticeUITests/testLearnUserNavigationOpensLessonQuiz + HintSessionStateTests passed (23 UI tests executed, 3 skipped; HintSessionStateTests 5 at 01451d4e, then 6 after adding progress-recording coverage).
- iPad Pro 13-inch (M5) targeted xbuild: CanadianHamExamToolsUITests passed (22 executed, 6 skipped), including hint and inspector audits.
- macOS xbuild unit tests passed at final code (150 executed, 0 failures).
- pnpm check:apple-l10n passed with no catalog rewrite (git status clean afterward), node scripts/check-apple-text-sources.ts passed, pnpm typecheck/test/check:hints -- --require-complete/check:schemas passed.
- AC audit: practice UI exposes Hint and mock UI does not; advanced/tvOS/visionOS are not targeted. Hint ladder shows Hint 1 then Hint 2 only when present, hides reference-sheet pointer until Apple reference sheets are available, keeps session-level state across the lesson link via RootView navigation, and records answeredWithHelp through AppleStudyEngine. Lesson links use the generic localized label and shared LessonHeadingAnchors fixture algorithm; UI test opens the target section anchor and the lesson reader applies accessibility focus to the heading.

Reopened after internal review request-changes; implementing findings 1-15 in focused fix groups with targeted validation.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented Apple question hints for iOS/iPadOS/macOS practice and review sessions: bundled Basic hints, Swift content models/loader validation, the localized Hint exam tool, stable 0.5 s answered-with-help qualification, lesson-link navigation to anchored headings with focus, and Apple tests for ladder, lesson link, mock-exam absence, reference-sheet gating, one-level hints, audits, fixtures, and progress recording. Validation passed on targeted iPhone/iPad UI runs, macOS unit tests, Apple localization/text-source checks, and pnpm type/content/schema/hint checks. tvOS/visionOS remain intentionally untouched for TASK-50.13.
<!-- SECTION:FINAL_SUMMARY:END -->
