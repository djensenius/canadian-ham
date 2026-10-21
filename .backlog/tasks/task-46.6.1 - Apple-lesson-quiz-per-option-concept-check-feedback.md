---
id: TASK-46.6.1
title: Apple lesson-quiz per-option concept-check feedback
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-20 14:35'
updated_date: '2026-10-21 23:43'
labels:
  - apple
dependencies:
  - TASK-50.14.2
parent_task_id: TASK-46.6
ordinal: 143000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-46.6 adds optional localized feedback to each concept-check choice and displays the chosen option feedback on web. Apple lesson quizzes currently show only the generic concept explanation. Follow the shared content contract after the Apple quiz-hints work, without changing official bank questions or mock exams.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 After answering a concept check, iOS/iPadOS/macOS lesson quizzes show the chosen option feedback plus the existing explanation; shuffled options map to the correct source feedback and legacy choices without feedback still work.
- [ ] #2 Feedback uses EN/FR fallback with correct language metadata, accessible focus/VoiceOver and Dynamic Type, and colour-independent correctness; no feedback is disclosed before answering.
- [ ] #3 Targeted unit/UI tests include correct and incorrect choices, shuffled mapping, absent feedback, EN/FR and light/dark accessibility audits without weakening existing tests; Apple localization/text checks and affected platform checks pass.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Resolve chosen concept-check feedback from the stored source index with existing localized fallback metadata, and render it only in post-answer feedback while preserving the quiz layout.
2. Add focused mapping/fallback unit coverage and seeded concept-check UI coverage for correct/incorrect/legacy choices, EN/FR, Dynamic Type and light/dark audits.
3. Commit implementation, run localization/text and test-guard checks plus targeted macOS unit and iPhone/iPad quiz tests through nohup xbuild; record per-test evidence, finalize and push without a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented post-answer source-indexed option feedback in the existing concept feedback card. Correctness remains explicit localized text; option feedback is a language-tagged attributed run within the focused status, with the general explanation retained. No official/mock code, catalogue, content or shared audit helper changes. Supervisor direction: use test-target-only bilingual/legacy quiz fixtures (no app DEBUG fixture). Real authored feedback currently has neither French translations nor absent-feedback choices, so UI tests use EN content plus French interface/EN fallback; model mapping and attributed language metadata, actual FR and legacy/no-answer behavior are covered by units.

Validation progress: macOS new units PASS (3/3). Initial iPhone run: 6/7 untouched existing lesson-quiz methods PASS; AX-XXXL hint/layout round-trip failed reaching restored Hint 2 (y844 below panel maxY828) and is queued for a targeted retry. The five new UI methods initially failed querying their IDs: xcresult accessibility hierarchy confirms the existing lesson-quiz-feedback container ID was propagated onto both new status and existing explanation Text children (feedback itself and shuffled text were correct). Fixed by adding children: .contain, matching PracticeFeedback, in ac85def5. A single-method smoke, then only remaining new/failed methods, all 12 methods on iPad, and l10n checks are queued via nohup and waiting normally for the shared xbuild lock. No existing tests/audits or shared helper were weakened.

Current AC3 evidence: passes except reproducible audit false positive on unchanged header. The single new AX-XXXL concept method reaches/asserts both localized status and existing explanation with full visibility, but its second full audit reproducibly flags unchanged Question 1 of 1 (near-black on paper) after audit auto-scroll. Supervisor approved exactly one unchanged retry; both failures retained (184.329 s and 196.875 s) and reported to TASK-65. No audit/helper weakening or unrelated visual fix. Four new iPhone default-size light/dark correct/incorrect/French-fallback methods PASS; all seven existing quiz tests PASS (existing hint AX-XXXL method needed one unchanged retry). iPad 12-method run and localization/guard checks continue.

Bounded investigation per supervisor: the existing passing testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip does NOT call any accessibility audit; it tests hint reachability and vertical layout at AX-XXXL, so it never audits Question N of M at that size. The new method audits both feedback status and explanation. The failure screenshots contain no focus ring, and VoiceOver is not enabled by these UI launches. Both failures name unchanged Question 1 of 1; second audit auto-scrolls the screen to that header, away from the pre-audit feedback target. Trying the same 0.8-second settle used by existing hint tests after positioning each target and before asserting full visibility/auditing, without filtering or relaxing anything. AC3 remains unchecked/In Progress.
<!-- SECTION:NOTES:END -->
