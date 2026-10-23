---
id: TASK-46.6.1
title: Apple lesson-quiz per-option concept-check feedback
status: Done
assignee:
  - '@worker'
created_date: '2026-10-20 14:35'
updated_date: '2026-10-23 16:51'
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
- [x] #3 Targeted unit/UI tests include correct and incorrect choices, shuffled mapping, absent feedback, EN/FR and light/dark accessibility audits without weakening existing tests; Apple localization/text checks and affected platform checks pass.
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

8. Resume with PR #1007/TASK-71: merge/push origin/main, then add a local auditIgnoringOccludedOrMeasuredContrast helper used only by the five new feedback methods. Preserve the existing occlusion guards verbatim and compose with the unchanged exported measurement predicates (>=4.5, keepAlways label/frame/ratio logging on pass/fail); leave every existing test/shared helper unchanged. Run the 12 selected methods on iPhone and iPad and three mapping units on macOS via nohup xbuild, then localization/text/approved guard checks. Stop on failures other than unverified contrast; record per-test/ignored-finding ratios, verify AC3, finalize and push without a PR.
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

Main-control result: origin/main ba5eb4f5c0ee0ff7477b708b73696474a143a303 PASSED both closest existing lesson-quiz audit controls on the same iPhone 17 Pro: testLessonQuizHintsDarkAndFullAccessibilityAudits 166.384 s, testLessonQuizHintsLightAndFullAccessibilityAudits 143.205 s; /tmp/task-46.6.1-main-control.{log,xcresult}, xbuild exit 0. These controls do not reproduce a general main/environment regression and do not validate the new option-feedback status itself. STOPPED as directed after the three repeat failures outside the authorized header-only scope. No source edit, shared-helper edit, local exception or AGENTS change was made in this resume. AC3 deliberately remains unchecked and the task remains In Progress; no PR. Full iPad selection skipped because the requested iPhone gate failed. Previous macOS units/localization checks remain recorded above (untouched implementation); resumed text-source check, guard self-test, approved guard against origin/main, and git diff --check passed. All new Apple invocations used nohup xbuild, one destination, targeted methods, grep polling, and natural completion; no builds were killed and no full suites were run.

Merged/pushed origin/main including PR #1007/TASK-71 as f45a6aeb. Coordinator approved a bounded local composite audit helper because neither existing audit wrapper accepts an issue predicate. It will preserve the occlusion guards verbatim and reuse the exported measured visibility/contrast predicates; scope remains only the five new feedback tests.

Blocked on main regression found during TASK-71 resume: first macOS mapping-unit xbuild failed before executing tests (exit 65), because unchanged UITestContrastMeasurement.swift:306 passes NSImage.cgImage method rather than CGImage on macOS. Evidence: /tmp/task-46.6.1-macos-measured.{log,xcresult}; /tmp/task-46.6.1-measured-runner.log. Ordered set -e runner stopped before iPhone/iPad/l10n. Coordinator is landing TASK-72 shared cross-platform contrastMeasurementCGImage(from:) fix; wait for merge notification, then merge origin/main, update only local composite screenshot conversion to that helper, and restart requested checks. AC3 remains unchecked/In Progress; no builds killed.

TASK-72 merged on main 80ca2871; merged/pushed as 6e5ea282. Updated only the new local composite helper to use contrastMeasurementCGImage(from:) per coordinator direction. Shared helpers remain byte-identical to main. Restarting the entire ordered targeted runner at macOS mapping units; failed original artifacts retain -measured suffix and resumed artifacts use -measured-v2.

Final TASK-71/TASK-72 resumed validation (all selected tests passed in one run per platform; no skips):

| CanadianHamExamToolsUITests method | iPhone 17 Pro | iPad Pro 13-inch (M5) |
|---|---|---|
| testLessonQuizConceptCheckHasNoHintOrOtherTools | PASS 19.918 s | PASS 19.404 s |
| testLessonQuizConceptOptionCorrectDarkAndFullAccessibilityAudit | PASS 72.272 s | PASS 39.739 s |
| testLessonQuizConceptOptionCorrectLightAndFullAccessibilityAudit | PASS 62.113 s | PASS 48.174 s |
| testLessonQuizConceptOptionFeedbackLargestDynamicType | PASS 191.792 s | PASS 45.286 s |
| testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit | PASS 70.579 s | PASS 34.658 s |
| testLessonQuizConceptOptionIncorrectFrenchFallbackLightAndFullAccessibilityAudit | PASS 69.047 s | PASS 34.918 s |
| testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip | PASS 316.045 s | PASS 91.027 s |
| testLessonQuizHintsDarkAndFullAccessibilityAudits | PASS 164.973 s | PASS 60.303 s |
| testLessonQuizHintsFrenchAndCurrentLessonRoundTrip | PASS 189.316 s | PASS 57.521 s |
| testLessonQuizHintsLightAndFullAccessibilityAudits | PASS 179.749 s | PASS 60.227 s |
| testLessonQuizOneLevelHintAndHelpCountPersistsAfterRelaunch | PASS 115.703 s | PASS 41.479 s |
| testLessonQuizPostChoiceHintsDoNotChangeSavedHelpAndRelaunchKeepsHelpCount | PASS 126.239 s | PASS 50.714 s |

macOS LocalizationCatalogTests:
- testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata: PASS 0.002 s
- testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection: PASS 0.001 s
- testConceptCheckAnswerStatusMapsShuffledSourceChoices: PASS 0.001 s

Every ignored finding (verbatim keepAlways text attachment payloads; occlusion-only findings have no measured ratio by design):

- iphone CanadianHamExamToolsUITests/testLessonQuizConceptOptionCorrectDarkAndFullAccessibilityAudit(): occluded rule.
  label=A parts list needs 0.82 A. A meter on the same accessory reads 820 mA. What should the learner conclude? frame=x: 40.0, y: 92.63623046874994, width: 313.33333333333326, height: 98.99999999999997 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true
  Attachment: /tmp/task-46.6.1-iphone-measured-v2-attachments/6B4FEAA2-D75C-48E6-A6E9-C6DA970E9C8C.txt

- iphone CanadianHamExamToolsUITests/testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit(): measured rule.
  label=A parts list needs 0.82 A. A meter on the same accessory reads 820 mA. What should the learner conclude? frame=(40.0, 130.60579427083337, 313.33333333333326, 99.0) ratio=12.628753100147408:1
  Attachment: /tmp/task-46.6.1-iphone-measured-v2-attachments/20EDC6B6-B2B7-43B4-99A4-59DF084EA2EC.txt

- iphone CanadianHamExamToolsUITests/testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit(): measured rule.
  label=The readings differ by a factor of one hundred. frame=(110.0, 257.60579427083337, 233.66666666666669, 42.33333333333337) ratio=12.204207186018708:1
  Attachment: /tmp/task-46.6.1-iphone-measured-v2-attachments/47DD313E-0088-4F1E-B79E-253FA5B4E6AC.txt

- iphone CanadianHamExamToolsUITests/testLessonQuizHintsDarkAndFullAccessibilityAudits(): occluded rule.
  label=QZ-L-005-01-A frame=x: 40.0, y: -7.666666666666785, width: 160.0, height: 26.33333333333333 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true
  Attachment: /tmp/task-46.6.1-iphone-measured-v2-attachments/9BA2FB92-B5F0-47AD-9033-A162E85CEB06.txt

- iphone CanadianHamExamToolsUITests/testLessonQuizHintsDarkAndFullAccessibilityAudits(): occluded rule.
  label=1 questions: official bank questions update practice progress; concept checks do not. frame=x: 40.0, y: 26.666666666666544, width: 201.66666666666666, height: 86.33333333333334 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true
  Attachment: /tmp/task-46.6.1-iphone-measured-v2-attachments/087E3D66-49D1-476B-8AAF-1435D5DF49D5.txt

- iphone CanadianHamExamToolsUITests/testLessonQuizHintsLightAndFullAccessibilityAudits(): occluded rule.
  label=1 questions: official bank questions update practice progress; concept checks do not. frame=x: 40.0, y: 26.666666666666544, width: 201.66666666666666, height: 86.33333333333334 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true
  Attachment: /tmp/task-46.6.1-iphone-measured-v2-attachments/7B665009-98C5-4284-B190-E1A8343729BA.txt

- ipad CanadianHamExamToolsUITests/testLessonQuizConceptOptionFeedbackLargestDynamicType(): measured rule.
  label=Correct answer frame=(150.0, 1232.898681640625, 362.0, 51.5) ratio=8.360825174840722:1
  Attachment: /tmp/task-46.6.1-ipad-measured-v2-attachments/49C6BCEB-F20F-44BC-8ECA-2868C0F337BE.txt

- ipad CanadianHamExamToolsUITests/testLessonQuizConceptOptionFeedbackLargestDynamicType(): occluded rule.
  label=C frame=x: 96.5, y: 1333.0, width: 33.0, height: 63.5 visibleScrollArea=x: 0.0, y: 86.0, width: 1032.0, height: 1290.0 scrollFrame=x: 0.0, y: 0.0, width: 1032.0, height: 1376.0 matchedScrollDescendant=true
  Attachment: /tmp/task-46.6.1-ipad-measured-v2-attachments/ACCD2F14-1CEA-41CE-B600-9B872DAED3C8.txt

- ipad CanadianHamExamToolsUITests/testLessonQuizConceptOptionFeedbackLargestDynamicType(): occluded rule.
  label=The readings differ by a factor of ten. frame=x: 146.0, y: 1329.0, width: 674.0, height: 125.5 visibleScrollArea=x: 0.0, y: 86.0, width: 1032.0, height: 1290.0 scrollFrame=x: 0.0, y: 0.0, width: 1032.0, height: 1376.0 matchedScrollDescendant=true
  Attachment: /tmp/task-46.6.1-ipad-measured-v2-attachments/56E60735-E5CE-4E04-B8C5-29CB19ACA258.txt

- ipad CanadianHamExamToolsUITests/testLessonQuizConceptOptionFeedbackLargestDynamicType(): measured rule.
  label=Correct answer frame=(150.0, 1232.898681640625, 362.0, 51.5) ratio=8.360825174840722:1
  Attachment: /tmp/task-46.6.1-ipad-measured-v2-attachments/23FC8B4B-A18B-4C3B-96B3-9E3BD5F6961C.txt

- ipad CanadianHamExamToolsUITests/testLessonQuizConceptOptionFeedbackLargestDynamicType(): occluded rule.
  label=The readings differ by a factor of ten. frame=x: 146.0, y: 1329.0, width: 674.0, height: 125.5 visibleScrollArea=x: 0.0, y: 86.0, width: 1032.0, height: 1290.0 scrollFrame=x: 0.0, y: 0.0, width: 1032.0, height: 1376.0 matchedScrollDescendant=true
  Attachment: /tmp/task-46.6.1-ipad-measured-v2-attachments/355E8371-00A3-40F8-A370-31268CD6BE5B.txt

Raw tests and evidence: /tmp/task-46.6.1-{macos,iphone,ipad}-measured-v2.{log,xcresult}, matching -tests.json, and iPhone/iPad -attachments/manifest.json with every keepAlways text payload. Literal ordered commands are retained in /tmp/task-46.6.1-measured-v2-checks.sh; runner log /tmp/task-46.6.1-measured-v2-runner.log.

Source preservation verification: a balanced-method-body comparison against origin/main confirms all 117 pre-existing methods/shared helpers in CanadianHamExamToolsUITests.swift are unchanged. The local composite occlusion branch is verbatim to the existing helper (ignoring indentation); its measured branch is verbatim to TASK-71/TASK-72 (ignoring indentation). Shared UITestContrastMeasurement.swift has no branch diff. Both UI selections and the 3 macOS mapping units passed without retry; only localization/text/guard checks remain running. All xbuild calls used nohup, one requested simulator destination at a time, grep polling, and natural completion; shared-lock waits were respected.

Final ancillary validation after green targeted selections: pnpm check:apple-l10n PASS (French localization export plus generic tvOS/visionOS localization builds; catalogue unchanged), node scripts/check-apple-text-sources.ts PASS, node scripts/check-test-guard.mjs --self-test PASS, TEST_GUARD_PR_BODY="Test-guard-approved: owner decision 2026-10-22" node scripts/check-test-guard.mjs --base origin/main --head HEAD PASS with approved audit-composition findings, and git diff --check PASS. Logs: /tmp/task-46.6.1-{l10n,text,guard-self,guard}-measured-v2.log; ordered nohup runner exited 0. The guard also reports context/line-shift findings in unchanged existing methods; the independent balanced-method comparison confirms all 117 origin/main methods/shared helpers in this class are unchanged. Earlier compilation failure was a main TASK-71 macOS screenshot bridge regression and is resolved by merged TASK-72, not a skipped test. No retry was needed after that fix. No full Apple suites were run: merge-batch suites remain coordinator-owned; targeted iPhone/iPad UI and macOS mapping tests cover the affected iOS/macOS CanadianHam target. tvOS/visionOS suites skipped because LearnViews.swift is not in those app targets; only their localization builds run within the required check. Manual VoiceOver speech/focus was not exercised; existing AccessibilityFocusState behavior and attributed language metadata are covered by units/UI assertions and the full audits. AC3 is now verified; task complete without a PR.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented source-indexed per-option concept-check feedback with localized correctness, EN/FR fallback metadata, post-answer accessibility focus and the existing explanation retained. Merged/pushed main with TASK-71 and TASK-72; only the five new feedback audits use a bounded local composite full-audit helper, preserving the existing occlusion guards and adding unchanged measured-contrast predicates at >=4.5:1 with keepAlways label/frame/ratio logging. All pre-existing test/helper methods remain unchanged. Final validation passed in one run per platform: iPhone 12/12, iPad 12/12, macOS mapping units 3/3, localization/text checks, approved guard and diff checks. Four measured findings were verified (12.628753100147408:1; 12.204207186018708:1; 8.360825174840722:1 twice); seven approved occlusion-only findings are logged separately. Per-test timings and every attachment payload/path are in the notes. AC1-3 checked, no PR opened. Full suites remain for the coordinator merge batch; manual VoiceOver speech was not exercised.
<!-- SECTION:FINAL_SUMMARY:END -->
