---
id: TASK-46.6.1
title: Apple lesson-quiz per-option concept-check feedback
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-20 14:35'
updated_date: '2026-10-23 12:45'
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

5. Resume per coordinator authorization 2026-10-23: merge/push origin/main (TASK-70 aligned occluded contrast helper); rerun only new AX-XXXL method on iPhone/iPad unchanged. Only if the sole remaining issue is the fully visible Question N of M header, add a test-local contrast-only exact-label exception, logged with frame/screenshot and capped at one per audit, under owner-delegated decision 2026-10-22. Keep shared helpers unchanged. Then run all 12 targeted lesson-quiz methods on each device, verify AC3, finalize and push without a PR; stop on any other failure.

6. Supervisor-directed final-run failure handling: if final normal-size correct light/dark audits fail, let the already-started xbuild finish and extract element labels/frames, app/element screenshots, and visibility evidence. Rerun only those two methods once unchanged; if both pass, record both runs and continue the iPad selection. If either fails again, stop and report with evidence.

7. Updated supervisor direction after all five failures were identified: retry each of the other three failed methods once unchanged after the correct dark/light retry. If any retry fails, run the closest existing light/dark lesson-quiz audit controls on the same simulator in a detached /tmp worktree at current origin/main, then report evidence and stop. If all five retries pass, continue the requested iPad selection. No source edits or exceptions.
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

Resumed 2026-10-23 under coordinator direction. Merged origin/main through ba5eb4f5 (PR #1005/TASK-70) without conflicts and pushed merge 8ca78a41. The new AX-XXXL method PASSED unchanged on iPhone 17 Pro using the aligned auditIgnoringOccludedLessonTextContrast: 210.917 s, /tmp/task-46.6.1-iphone-aligned.{log,xcresult}. No local header exception, audit narrowing, shared helper edit, or AGENTS exception entry has been added. iPad unchanged rerun is queued via the same nohup runner, waiting normally on the shared xbuild lock.

The unchanged aligned-helper AX-XXXL rerun also PASSED on iPad Pro 13-inch (M5): 54.424 s, /tmp/task-46.6.1-ipad-aligned.{log,xcresult}. Both result bundles report one pass, zero failures/skips. Conditional authorization for a fully visible Question N of M header exception was NOT used; shared helpers match origin/main, and AGENTS.md is unchanged by this task. Started the requested final 12-method lesson-quiz selection (seven existing plus five feedback methods), iPhone then iPad, via nohup /tmp/task-46.6.1-final-targeted.sh. Resumed Apple text-source and test-guard self-test checks pass; the diff against origin/main passes with the coordinator-provided Test-guard-approved: owner decision 2026-10-22 marker (only the existing task-added calls to the approved occluded helper are flagged without approval).

Final iPhone 12-method run finished 7 PASS / 5 FAIL / 0 skipped (xbuild exit 65), /tmp/task-46.6.1-iphone-final.{log,xcresult}; set -e correctly prevented the iPad run. All seven existing methods passed. All five new methods reported Contrast at the unchanged shared helper. Correct dark/light issue screenshots identify the fully visible new lesson-quiz-feedback-status text, Correct 820 / 1 000 = 0.82 A, so only the display unit differs.; screenshot-derived approximate frame x56 y583.667 w286.667 h42 points (Scale=3; the original audit does not log XCUIElement.frame). Both assert full visibility before auditing, and app/element images show pale green on dark green (dark) / dark green on pale green (light), not a header/occlusion. French dark/light issue screenshots identify the fully visible unchanged English prompt (A parts list needs 0.82 A. A meter on the same accessory reads 820 mA. What should the learner conclude?), approximate screenshot-derived x40 y130.667 w312.667 h98.667 points. AX-XXXL again identifies Question 1 of 1, near-black on paper and fully visible at the bottom of the auto-scrolled app screenshot. Failure app/element exports and manifest: /tmp/task-46.6.1-iphone-final-attachments/; mapping and frame derivation: /tmp/task-46.6.1-iphone-final-failure-evidence.json. No exception has been added. Supervisor approved one unchanged retry of just correct dark/light after extracting evidence; launched via nohup /tmp/task-46.6.1-correct-retry.sh. AC3 remains unchecked/In Progress.

2026-10-23 resumed validation (unchanged tests/shared helper; current task branch includes TASK-70):

| Method | iPhone final selection | iPhone unchanged retry |
|---|---|---|
| testLessonQuizConceptCheckHasNoHintOrOtherTools | PASSED 23.327 s | not rerun; passed selection |
| testLessonQuizConceptOptionCorrectDarkAndFullAccessibilityAudit | FAILED 66.157 s | FAILED 86.195 s |
| testLessonQuizConceptOptionCorrectLightAndFullAccessibilityAudit | FAILED 71.965 s | FAILED 70.330 s |
| testLessonQuizConceptOptionFeedbackLargestDynamicType | FAILED 189.848 s | PASSED 208.938 s |
| testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit | FAILED 66.015 s | FAILED 68.058 s |
| testLessonQuizConceptOptionIncorrectFrenchFallbackLightAndFullAccessibilityAudit | FAILED 65.409 s | PASSED 61.431 s |
| testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip | PASSED 282.410 s | not rerun; passed selection |
| testLessonQuizHintsDarkAndFullAccessibilityAudits | PASSED 162.586 s | not rerun; passed selection |
| testLessonQuizHintsFrenchAndCurrentLessonRoundTrip | PASSED 169.698 s | not rerun; passed selection |
| testLessonQuizHintsLightAndFullAccessibilityAudits | PASSED 156.592 s | not rerun; passed selection |
| testLessonQuizOneLevelHintAndHelpCountPersistsAfterRelaunch | PASSED 107.478 s | not rerun; passed selection |
| testLessonQuizPostChoiceHintsDoNotChangeSavedHelpAndRelaunchKeepsHelpCount | PASSED 115.981 s | not rerun; passed selection |

Standalone unchanged AX-XXXL reruns before this final selection: iPhone PASS 210.917 s; iPad PASS 54.424 s. In the final selection, seven existing methods passed and all five new methods failed Contrast. The one approved unchanged retry per failed method reproduces correct dark/light (86.195 s / 70.330 s) and French dark prompt (68.058 s); AX-XXXL and French light pass on retry. No new source edits/exception; AC3 remains unchecked and task In Progress. Full iPad selection was not launched because iPhone did not pass.

Reproducible issue evidence: correct dark/light both flag the fully visible new feedback status (approx screenshot-derived x56 y583.667 w286.667 h42 pt); French dark flags the fully visible existing English prompt (approx x40 y130.667 w312.667 h98.667 pt). Runtime XCUIElement.frame is not captured by the unchanged helper for unfiltered issues, so these are explicitly approximate frames located by text-mask matching inside the app screenshot, not claimed runtime frames. The element screenshots are byte-identical across original/retry (SHA-256 correct-dark 46f116ed81e0a348a66bc3f39bd65b3b1938779de5004937d25eb1057024bb5d; correct-light b8fc4a925a34004e5b5b0deb9016774c7e90dfe18be023d3097dc759cfff2d65; French-dark 34b38eaed0832a5cf2679d8fb2298a5192716c27b8f6d2cbcf04fe7f20dffe7c). Dominant foreground/background screenshot pixel WCAG calculations are respectively 11.41:1, 8.36:1, and 12.63:1; these document screenshot appearance only and are not a replacement for the full audit.

Evidence: /tmp/task-46.6.1-iphone-{final,correct-retry,remaining-retry}.{log,xcresult}; failure app/element screenshots, descriptions and manifests in matching -attachments directories. Readable copies: /tmp/task-46.6.1-final-{correct-dark,correct-light,french-dark,french-light,largest}-{app,element}.png. Frame/mapping derivation /tmp/task-46.6.1-iphone-final-failure-evidence.json.

Per supervisor, controls are now running on the same iPhone 17 Pro simulator in detached /tmp/canadian-ham-task-46.6.1-main-control at origin/main ba5eb4f5c0ee0ff7477b708b73696474a143a303: existing testLessonQuizHintsLightAndFullAccessibilityAudits and testLessonQuizHintsDarkAndFullAccessibilityAudits. Ordered nohup runner /tmp/task-46.6.1-remaining-retry-and-control.sh; control log/bundle /tmp/task-46.6.1-main-control.{log,xcresult}.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented source-indexed per-option concept-check feedback in the Apple lesson quiz, combined with localized explicit correctness in the focused status and retaining the existing explanation. EN/FR fallback and language metadata, legacy choices and no pre-answer disclosure are covered by three passing macOS unit methods; four new default-size light/dark UI methods and all seven existing quiz methods pass on both iPhone and iPad. Localization/text and approved test-guard checks pass. NOT complete: the new AX-XXXL full-audit method reproducibly reports contrast on unchanged Question 1 of 1 despite visibly high-contrast screenshots; 0.8-second settling does not resolve it. Per supervisor, AC3 remains unchecked and the task stays In Progress; evidence appended to TASK-65. No audits were weakened and no PR was opened.
<!-- SECTION:FINAL_SUMMARY:END -->
