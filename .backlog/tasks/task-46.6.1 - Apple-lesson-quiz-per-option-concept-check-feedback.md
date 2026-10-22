---
id: TASK-46.6.1
title: Apple lesson-quiz per-option concept-check feedback
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-20 14:35'
updated_date: '2026-10-22 00:01'
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
- [x] #1 After answering a concept check, iOS/iPadOS/macOS lesson quizzes show the chosen option feedback plus the existing explanation; shuffled options map to the correct source feedback and legacy choices without feedback still work.
- [x] #2 Feedback uses EN/FR fallback with correct language metadata, accessible focus/VoiceOver and Dynamic Type, and colour-independent correctness; no feedback is disclosed before answering.
- [ ] #3 Targeted unit/UI tests include correct and incorrect choices, shuffled mapping, absent feedback, EN/FR and light/dark accessibility audits without weakening existing tests; Apple localization/text checks and affected platform checks pass.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Resolve chosen concept-check feedback from the stored source index with existing localized fallback metadata, and render it only in post-answer feedback while preserving the quiz layout.
2. Add focused mapping/fallback unit coverage and seeded concept-check UI coverage for correct/incorrect/legacy choices, EN/FR, Dynamic Type and light/dark audits.
3. Commit implementation, run localization/text and test-guard checks plus targeted macOS unit and iPhone/iPad quiz tests through nohup xbuild; record per-test evidence, finalize and push without a PR.

4. Supervisor-directed bounded audit investigation: preserve full audits; when the settled targeted run still fails on the unchanged header, record TASK-65 evidence, leave AC3 unchecked/In Progress, write the handoff and push without opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented post-answer source-indexed option feedback in the existing concept feedback card. Correctness remains explicit localized text; option feedback is a language-tagged attributed run within the focused status, with the general explanation retained. No official/mock code, catalogue, content or shared audit helper changes. Supervisor direction: use test-target-only bilingual/legacy quiz fixtures (no app DEBUG fixture). Real authored feedback currently has neither French translations nor absent-feedback choices, so UI tests use EN content plus French interface/EN fallback; model mapping and attributed language metadata, actual FR and legacy/no-answer behavior are covered by units.

Validation progress: macOS new units PASS (3/3). Initial iPhone run: 6/7 untouched existing lesson-quiz methods PASS; AX-XXXL hint/layout round-trip failed reaching restored Hint 2 (y844 below panel maxY828) and is queued for a targeted retry. The five new UI methods initially failed querying their IDs: xcresult accessibility hierarchy confirms the existing lesson-quiz-feedback container ID was propagated onto both new status and existing explanation Text children (feedback itself and shuffled text were correct). Fixed by adding children: .contain, matching PracticeFeedback, in ac85def5. A single-method smoke, then only remaining new/failed methods, all 12 methods on iPad, and l10n checks are queued via nohup and waiting normally for the shared xbuild lock. No existing tests/audits or shared helper were weakened.

Current AC3 evidence: passes except reproducible audit false positive on unchanged header. The single new AX-XXXL concept method reaches/asserts both localized status and existing explanation with full visibility, but its second full audit reproducibly flags unchanged Question 1 of 1 (near-black on paper) after audit auto-scroll. Supervisor approved exactly one unchanged retry; both failures retained (184.329 s and 196.875 s) and reported to TASK-65. No audit/helper weakening or unrelated visual fix. Four new iPhone default-size light/dark correct/incorrect/French-fallback methods PASS; all seven existing quiz tests PASS (existing hint AX-XXXL method needed one unchanged retry). iPad 12-method run and localization/guard checks continue.

Bounded investigation per supervisor: the existing passing testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip does NOT call any accessibility audit; it tests hint reachability and vertical layout at AX-XXXL, so it never audits Question N of M at that size. The new method audits both feedback status and explanation. The failure screenshots contain no focus ring, and VoiceOver is not enabled by these UI launches. Both failures name unchanged Question 1 of 1; second audit auto-scrolls the screen to that header, away from the pre-audit feedback target. Trying the same 0.8-second settle used by existing hint tests after positioning each target and before asserting full visibility/auditing, without filtering or relaxing anything. AC3 remains unchecked/In Progress.

Final targeted per-test evidence (latest result per method across runs, NOT a single green suite):

| CanadianHamExamToolsUITests method | iPhone 17 Pro | iPad Pro 13-inch (M5) |
|---|---|---|
| testLessonQuizConceptCheckHasNoHintOrOtherTools | PASSED 25.855 s (iphone) | PASSED 15.332 s |
| testLessonQuizConceptOptionCorrectDarkAndFullAccessibilityAudit | PASSED 78.286 s (iphone-fix) | PASSED 40.391 s |
| testLessonQuizConceptOptionCorrectLightAndFullAccessibilityAudit | PASSED 82.452 s (iphone-smoke) | PASSED 34.351 s |
| testLessonQuizConceptOptionFeedbackLargestDynamicType | FAILED 203.610 s (iphone-largest-settle) | FAILED 40.552 s |
| testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit | PASSED 85.663 s (iphone-fix) | PASSED 34.857 s |
| testLessonQuizConceptOptionIncorrectFrenchFallbackLightAndFullAccessibilityAudit | PASSED 74.123 s (iphone-fix) | PASSED 34.507 s |
| testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip | PASSED 269.356 s (iphone-fix) | PASSED 88.385 s |
| testLessonQuizHintsDarkAndFullAccessibilityAudits | PASSED 150.124 s (iphone) | PASSED 60.993 s |
| testLessonQuizHintsFrenchAndCurrentLessonRoundTrip | PASSED 165.720 s (iphone) | PASSED 58.621 s |
| testLessonQuizHintsLightAndFullAccessibilityAudits | PASSED 163.908 s (iphone) | PASSED 59.912 s |
| testLessonQuizOneLevelHintAndHelpCountPersistsAfterRelaunch | PASSED 108.400 s (iphone) | PASSED 38.102 s |
| testLessonQuizPostChoiceHintsDoNotChangeSavedHelpAndRelaunchKeepsHelpCount | PASSED 112.954 s (iphone) | PASSED 47.026 s |

macOS LocalizationCatalogTests: testConceptCheckAnswerStatusMapsShuffledSourceChoices PASS 0.001 s; testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata PASS 0.002 s; testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection PASS 0.001 s.

Ancillary checks: pnpm check:apple-l10n PASS (French export plus its tvOS/visionOS generic localization builds; catalogue unchanged); node scripts/check-apple-text-sources.ts PASS; node scripts/check-test-guard.mjs --self-test PASS; TEST_GUARD_PR_BODY="Test-guard-approved: owner decision 2026-10-12" node scripts/check-test-guard.mjs --base 78f6f995 --head HEAD PASS (only new calls to unchanged approved lesson audit helper). Unapproved guard run correctly reports the new audit call-site. git diff --check PASS.

Raw evidence: /tmp/task-46.6.1-{macos,iphone,iphone-smoke,iphone-fix,iphone-largest-fix,iphone-largest-retry,iphone-largest-settle,ipad}.log; same basenames with .xcresult. Ancillary logs: /tmp/task-46.6.1-{l10n,text,guard-self,guard}.log. Literal commands/ordered runners: /tmp/task-46.6.1-checks.sh, -checks-fix.sh, -checks-final.sh, -checks-remaining.sh and -settle-check.sh. All Apple runs used nohup xbuild; no full suites. tvOS/visionOS suites skipped because LearnViews.swift belongs only to the iOS/macOS CanadianHam target; their localization builds ran only because the requested localization script includes them.

Blocked: passes except reproducible audit false positive on unchanged header. The settled iPhone run still reports Contrast on Question 1 of 1 (203.610 s) after all feedback text/full-visibility assertions pass. iPad AX-XXXL also fails Contrast (40.552 s). Per supervisor, stop investigation; do not merge a newly failing test, leave AC3 unchecked/task In Progress, push for owner review. Existing AX-XXXL hint/layout test has no audit; its passing result cannot validate this header contrast at that size. No filter, skip, helper change, narrowed audit or unrelated visual fix was added. The added settle is only 0.8 s before each full audit; it did not resolve the finding. Manual VoiceOver speech/focus was not exercised; implementation uses AccessibilityFocusState and language-tagged Text, covered by attributed-run unit checks and normal-size full audits.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented source-indexed per-option concept-check feedback in the Apple lesson quiz, combined with localized explicit correctness in the focused status and retaining the existing explanation. EN/FR fallback and language metadata, legacy choices and no pre-answer disclosure are covered by three passing macOS unit methods; four new default-size light/dark UI methods and all seven existing quiz methods pass on both iPhone and iPad. Localization/text and approved test-guard checks pass. NOT complete: the new AX-XXXL full-audit method reproducibly reports contrast on unchanged Question 1 of 1 despite visibly high-contrast screenshots; 0.8-second settling does not resolve it. Per supervisor, AC3 remains unchecked and the task stays In Progress; evidence appended to TASK-65. No audits were weakened and no PR was opened.
<!-- SECTION:FINAL_SUMMARY:END -->
