---
id: TASK-46.6.1
title: Apple lesson-quiz per-option concept-check feedback
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-20 14:35'
updated_date: '2026-10-23 17:04'
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
1. Gate concept feedback focus with a one-shot request from the choose action, cleared on navigation, and unit-test initial/restored answers and Previous/Next consumption.
2. Reuse Correct. and add missing Incorrect. with French translations using an exact Python JSON round-trip; update the feedback assertions.
3. Run the unchanged Practice LearnFlow light/dark audits on iPhone 17 Pro and iPad Pro 13-inch (M5) first via nohup xbuild; stop and report screenshots/labels if new feedback status fails.
4. Rerun the 12 lesson-quiz methods per device, documented macOS unit command, localization without catalogue rewrite, text sources and approved guard. Record per-test evidence, finalize, commit and push; no PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Review follow-up 2026-10-23: prior blocked/unchecked-AC3 investigation paragraphs are superseded by the green TASK-71/TASK-72 results below and have been trimmed. Historical artifacts remain in /tmp/task-46.6.1-* and in branch history. Review now requests choice-only focus, sentence correctness labels, unchanged LearnFlow light/dark audits on iPhone/iPad, the 12-method regression selections, and the documented full macOS unit command. AC3 is temporarily reopened pending this follow-up validation.

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

Review fixes committed a83d15fa: one-shot check-ID focus request is armed only by choosing, consumed once, cleared on check navigation/disappearance, and cancellation checked before assigning accessibility focus. Added a unit test for initial/restored, Previous/Next, one-shot and mismatched requests; UI automation does not expose VoiceOver focus, so manual VoiceOver is not claimed. Status now uses existing Correct. (existing French translation preserved) and new Incorrect. (fr/fr-CA Mauvaise réponse.); Python JSON round-trip equality was verified before editing, existing key order preserved. Updated only task-added status assertions. Trimmed superseded blocked investigation notes via CLI replacement. Unchanged CanadianHamPracticeUITests LearnFlow full audits PASS on iPhone (dark 58.268 s, light 42.903 s) and iPad (dark 40.890 s, light 36.041 s), no retries or exceptions. Bundles/logs /tmp/task-46.6.1-{iphone,ipad}-review-audits.{xcresult,log}; literal nohup runner /tmp/task-46.6.1-review-audits.sh. The 12-method iPhone/iPad selections, full documented macOS units and ancillary checks now run in the ordered nohup /tmp/task-46.6.1-review-checks.sh; no PR.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented source-indexed per-option concept-check feedback with localized correctness, EN/FR fallback metadata, post-answer accessibility focus and the existing explanation retained. Merged/pushed main with TASK-71 and TASK-72; only the five new feedback audits use a bounded local composite full-audit helper, preserving the existing occlusion guards and adding unchanged measured-contrast predicates at >=4.5:1 with keepAlways label/frame/ratio logging. All pre-existing test/helper methods remain unchanged. Final validation passed in one run per platform: iPhone 12/12, iPad 12/12, macOS mapping units 3/3, localization/text checks, approved guard and diff checks. Four measured findings were verified (12.628753100147408:1; 12.204207186018708:1; 8.360825174840722:1 twice); seven approved occlusion-only findings are logged separately. Per-test timings and every attachment payload/path are in the notes. AC1-3 checked, no PR opened. Full suites remain for the coordinator merge batch; manual VoiceOver speech was not exercised.
<!-- SECTION:FINAL_SUMMARY:END -->
