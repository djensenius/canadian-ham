---
id: TASK-46.8.1
title: Section-sized M1 lesson quiz rounds on web and Apple
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-21 14:58'
updated_date: '2026-10-24 21:53'
labels:
  - web
  - apple
dependencies:
  - TASK-50.14.2
parent_task_id: TASK-46.8
ordinal: 144000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner approved section-sized quiz rounds as part of TASK-46.8 on 2026-10-12. The principles-led M1 content rewrite is separate so quiz UI work does not conflict with the Apple lesson-quiz hints branch. Exhaustive M1 quizzes currently create long uninterrupted sessions; section-sized rounds should provide retrieval between teaching sections without losing official question coverage, progress, or hints.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 M1 lesson quizzes run in teaching-section-sized rounds on web and iOS/iPadOS/macOS/tvOS/visionOS, with every existing official quiz item retained and mapped to its teaching section.
- [x] #2 Round navigation, scoring, completion, saved attempts, help flags, and lesson-link round trips preserve the TASK-50.14.2 behavior; no question is dropped or counted twice.
- [x] #3 Targeted web and Apple tests cover round boundaries and persistence; accessible focus, VoiceOver, Dynamic Type, light/dark audits and localization checks pass on affected platforms without weakening audit coverage.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the existing quiz content/readers/sessions and derive explicit M1 round metadata from precise hint anchors in heading order; validate complete unique coverage.
2. Add section-grouped presentation/navigation/checkpoints to web and Apple while retaining one attempt/session, seeded ordering, hints and existing non-M1 behavior.
3. Add content, web and macOS model tests plus targeted iPhone/iPad round navigation, EN/FR and full light/dark audit coverage; keep existing helpers/tests unchanged.
4. Commit before nohup targeted validation, poll logs, run required schema/workspace/localization/guard checks, then record AC evidence, finalize, commit and push (no PR). tvOS/visionOS lesson quizzes N/A per coordinator/TASK-50.14.2.

5. Apply coordinator-approved review notes 1–8: record audit scope, align round title/interface language, limit focus to round transitions, harden concept fallback/anchor checking and tests; run complete requested targeted checks with nohup/grep polling, record per-test evidence, commit and push without PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented explicit bilingual M1 rounds derived from hint section anchors, with schema + checker validation for unique complete coverage, heading order, titles/translations and hint agreement. There are 24 rounds across six quizzes, retaining all 199 official items. Both readers group the original seeded order without changing choice permutations; non-M1 quizzes remain ungrouped. One cached session and one final attempt remain in use. Coordinator confirmed checkpoints only between rounds, correct/total and answered count, unrestricted unanswered navigation, and no reopening a dismissed checkpoint on resume. New web round/help/persistence/resume and EN/FR light/dark axe tests pass. pnpm test PASS: content-tools 249, Morse 21, calculator 127, web 267; schemas 59/59, typecheck and content-swift 27/27 PASS. First macOS targeted run waiting on shared xbuild lock. tvOS/visionOS quiz UI N/A by approved scope; shared content decoding will be build-checked by localization validation.

Targeted macOS initial run PASS 4/4 (two new full-M1/order/boundary/session methods plus existing cache/help payload regressions); the normal documented macOS command built the entire UI-test target successfully. Host app logged the pre-existing local persistent-store unknown-model migration diagnostic; all regression stores are in-memory and passed, and no persistent data was reset/deleted. Intentional French xbuild export round trip PASS with catalogue byte-unchanged. Final-source macOS nine-test run and pnpm check:apple-l10n (including generic tvOS/visionOS builds) queued through nohup. New iPhone/iPad M1 tests and unchanged 12 quiz/feedback regression methods queued; no full suites. Additional partial-score web test PASS; import checks, web build/dist URL+CSP audit and links PASS. Pre-existing ExamTools tests/helpers are byte-identical to main. Guard self-test and approved diff PASS with Test-guard-approved: owner decision 2026-10-22.

iPhone initial M1 UI run: English light/dark full audits PASS (206.048s / 221.520s). French AX light/dark header audits passed but the new test used web’s French Next label; fixed to native catalogue Suivant. The new persistence method reached Round 2, current-lesson return and Previous with its original question/feedback intact; it failed only an incorrect isEnabled assertion because the existing AnswerChoiceButton freezes through allowsHitTesting/accessibilityRespondsToUserInteraction, not .disabled. Replaced this new-test assumption with selected-answer and Correct-feedback assertions. No app/audit/old helper/test changes. The three failed new methods are queued alone on iPhone, then all five new methods on iPad plus the unchanged 12 regressions/device. Final-source macOS results correct prior estimate: 14/14 PASS, including all 10 LocalizationCatalogTests and 4 quiz/model methods.

iPhone 17 Pro: all five distinct new M1 methods PASS across initial/failing-only recheck, on unchanged final production source.
- testM1QuizRoundsLightAndFullAccessibilityAudits: PASS 206.048s (phone-new.log)
- testM1QuizRoundsDarkAndFullAccessibilityAudits: PASS 221.520s (phone-new.log)
- testM1QuizRoundsFrenchLargestTypeLightAndFullAccessibilityAudits: PASS 387.343s (phone-new-r2.log)
- testM1QuizRoundsFrenchLargestTypeDarkAndFullAccessibilityAudits: PASS 402.486s (phone-new-r2.log)
- testM1QuizRoundsKeepHelpAnswersResumeAndOneSavedAttempt: PASS 399.061s (phone-new-r2.log).
The latter uses the existing DEBUG six-item prefix to cross a real five-item section, check checkpoint score, Previous and frozen selection, current-lesson hint return without reopening a dismissed checkpoint, final 6/6 scoring, one saved attempt and two help flags after relaunch. Full 199-item uniqueness/order/coverage is verified by model/content tests and full 33-item web scoring/persistence. iPad five new tests and twelve unchanged regressions on each device remain queued. Logs, commands and xcresults: /tmp/task-46.8.1-runs.

pnpm check:apple-l10n PASS (apple-l10n.log, exit 0): complete French export, catalogue byte-unchanged, generic CanadianHamTV and CanadianHamVision BUILD SUCCEEDED. tvOS/visionOS have no quiz screens and their quiz AC/UI-test coverage is N/A per approved scope; shared metadata/catalogue compiled successfully. No full Apple suites. iPhone unchanged 12-method quiz/feedback regression run PASS 12/12, exit 0 (phone-regression.log); combined with five new M1 methods, all 17 distinct iPhone UI methods are green. iPad new M1 run PASS 5/5: dark 91.620s, French AX dark 106.300s, French AX light 104.079s, help/resume/saved attempt 178.333s, light 86.736s (pad-new.log). iPad unchanged 12-method run is the last remaining check and is running. Final typecheck, web build/URL+CSP audit, Apple text-source check, approved test guard and diff checks PASS; original ExamTools suffix still byte-identical to main.

# Final validation evidence: TASK-46.8.1

All final validation commands exited 0. Production source last changed in 75d263a85c02e3618a4d7947857565e5357ee600; later commits only add/refine tests and record evidence. No existing UI tests/helpers were changed.

## macOS
- CanadianHamTests.LocalizationCatalogTests/testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata: PASS (0.002s; mac-final.log)
- CanadianHamTests.LocalizationCatalogTests/testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection: PASS (0.001s; mac-final.log)
- CanadianHamTests.LocalizationCatalogTests/testConceptCheckAnswerStatusMapsShuffledSourceChoices: PASS (0.001s; mac-final.log)
- CanadianHamTests.LocalizationCatalogTests/testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext: PASS (0.001s; mac-final.log)
- CanadianHamTests.LocalizationCatalogTests/testEveryCatalogKeyHasFrenchTranslations: PASS (0.007s; mac-final.log)
- CanadianHamTests.LocalizationCatalogTests/testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries: PASS (0.005s; mac-final.log)
- CanadianHamTests.LocalizationCatalogTests/testLanguagePreferenceResolvesSystemAndOverrides: PASS (0.001s; mac-final.log)
- CanadianHamTests.ProgressStoreTests/testLessonQuizHelpFixtureValidationAndPayloadRoundTrips: PASS (0.143s; mac-final.log)
- CanadianHamTests.ProgressStoreTests/testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation: PASS (0.001s; mac-final.log)
- CanadianHamTests.LocalizationCatalogTests/testLocalizedNullableTextAndLanguageFallsBackToEnglish: PASS (0.001s; mac-final.log)
- CanadianHamTests.ProgressStoreTests/testM1QuizRoundBoundariesPreserveOneSessionAnswersHelpAndDismissedCheckpoint: PASS (0.560s; mac-final.log)
- CanadianHamTests.ProgressStoreTests/testM1QuizRoundsRetainEveryItemAndSeededOrderWithinTeachingSections: PASS (0.555s; mac-final.log)
- CanadianHamTests.LocalizationCatalogTests/testQuestionBankLoadErrorDescriptionUsesFrenchLocale: PASS (0.004s; mac-final.log)
- CanadianHamTests.LocalizationCatalogTests/testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench: PASS (0.001s; mac-final.log)

## iPhone 17 Pro
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizConceptCheckHasNoHintOrOtherTools: PASS (23.854s; phone-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizConceptOptionCorrectDarkAndFullAccessibilityAudit: PASS (70.032s; phone-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizConceptOptionCorrectLightAndFullAccessibilityAudit: PASS (72.981s; phone-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizConceptOptionFeedbackLargestDynamicType: PASS (208.288s; phone-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit: PASS (69.822s; phone-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizConceptOptionIncorrectFrenchFallbackLightAndFullAccessibilityAudit: PASS (75.674s; phone-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip: PASS (304.691s; phone-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizHintsDarkAndFullAccessibilityAudits: PASS (169.995s; phone-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizHintsFrenchAndCurrentLessonRoundTrip: PASS (177.311s; phone-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizHintsLightAndFullAccessibilityAudits: PASS (170.430s; phone-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizOneLevelHintAndHelpCountPersistsAfterRelaunch: PASS (112.232s; phone-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizPostChoiceHintsDoNotChangeSavedHelpAndRelaunchKeepsHelpCount: PASS (128.251s; phone-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testM1QuizRoundsDarkAndFullAccessibilityAudits: PASS (221.520s; phone-new.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testM1QuizRoundsFrenchLargestTypeDarkAndFullAccessibilityAudits: PASS (402.486s; phone-new-r2.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testM1QuizRoundsFrenchLargestTypeLightAndFullAccessibilityAudits: PASS (387.343s; phone-new-r2.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testM1QuizRoundsKeepHelpAnswersResumeAndOneSavedAttempt: PASS (399.061s; phone-new-r2.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testM1QuizRoundsLightAndFullAccessibilityAudits: PASS (206.048s; phone-new.log)

## iPad Pro 13-inch (M5)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizConceptCheckHasNoHintOrOtherTools: PASS (14.726s; pad-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizConceptOptionCorrectDarkAndFullAccessibilityAudit: PASS (33.605s; pad-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizConceptOptionCorrectLightAndFullAccessibilityAudit: PASS (37.915s; pad-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizConceptOptionFeedbackLargestDynamicType: PASS (42.616s; pad-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit: PASS (43.100s; pad-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizConceptOptionIncorrectFrenchFallbackLightAndFullAccessibilityAudit: PASS (33.009s; pad-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip: PASS (88.722s; pad-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizHintsDarkAndFullAccessibilityAudits: PASS (60.382s; pad-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizHintsFrenchAndCurrentLessonRoundTrip: PASS (60.722s; pad-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizHintsLightAndFullAccessibilityAudits: PASS (58.653s; pad-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizOneLevelHintAndHelpCountPersistsAfterRelaunch: PASS (38.260s; pad-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testLessonQuizPostChoiceHintsDoNotChangeSavedHelpAndRelaunchKeepsHelpCount: PASS (45.721s; pad-regression.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testM1QuizRoundsDarkAndFullAccessibilityAudits: PASS (91.620s; pad-new.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testM1QuizRoundsFrenchLargestTypeDarkAndFullAccessibilityAudits: PASS (106.300s; pad-new.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testM1QuizRoundsFrenchLargestTypeLightAndFullAccessibilityAudits: PASS (104.079s; pad-new.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testM1QuizRoundsKeepHelpAnswersResumeAndOneSavedAttempt: PASS (178.333s; pad-new.log)
- CanadianHamUITests.CanadianHamExamToolsUITests/testM1QuizRoundsLightAndFullAccessibilityAudits: PASS (86.736s; pad-new.log)

## Commands and result bundles

All Apple commands ran through nohup scripts with grep polling and one simulator destination per test command. No builds were killed. No full suites were run.
- `/tmp/task-46.8.1-runs/mac.sh`: initial documented macOS command with four selectors, PASS 4/4.
- `/tmp/task-46.8.1-runs/localization.sh`: documented macOS command with those four selectors plus LocalizationCatalogTests, PASS 14/14; then pnpm check:apple-l10n, PASS.
- `/tmp/task-46.8.1-runs/apple.sh`: intentional localization export (catalogue unchanged) and initial iPhone five-method run (two PASS; three test-only assumptions corrected as recorded above).
- `/tmp/task-46.8.1-runs/apple-r2.sh`: failing-only iPhone three-method recheck PASS; iPad five-method new coverage PASS; unchanged twelve-method iPhone and iPad regressions PASS. Complete xbuild commands and selectors are retained in these scripts.

- mac-final.log: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-brprdowgzbmuxzcvfklrciudznua/Logs/Test/Test-CanadianHam-2026.10.24_14-49-47--0400.xcresult`
- phone-new.log: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-brprdowgzbmuxzcvfklrciudznua/Logs/Test/Test-CanadianHam-2026.10.24_14-50-03--0400.xcresult`
- phone-new-r2.log: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-brprdowgzbmuxzcvfklrciudznua/Logs/Test/Test-CanadianHam-2026.10.24_15-07-47--0400.xcresult`
- pad-new.log: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-brprdowgzbmuxzcvfklrciudznua/Logs/Test/Test-CanadianHam-2026.10.24_15-30-00--0400.xcresult`
- phone-regression.log: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-brprdowgzbmuxzcvfklrciudznua/Logs/Test/Test-CanadianHam-2026.10.24_15-42-36--0400.xcresult`
- pad-regression.log: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-brprdowgzbmuxzcvfklrciudznua/Logs/Test/Test-CanadianHam-2026.10.24_16-10-40--0400.xcresult`

## Other validation and AC evidence

- AC1: Explicit EN/FR metadata partitions all 199 unchanged M1 official IDs into 24 teaching-section rounds in lesson heading order, with checker assertions against every hint teaching anchor. Content/schema and TS/Swift model coverage pass. Web/iPhone/iPad exercise real sections; macOS compiles and its model units pass. tvOS/visionOS quiz UI is N/A by coordinator-approved TASK-50.14.2 scope; generic builds pass.
- AC2: One session and final attempt are retained. Full 33-item web run saves 33/33 with one helped item, all IDs once and 33 progress records; relaunch retains the result/help count. Partial and unanswered checkpoint scores pass. Native six-item DEBUG prefix verifies a real round boundary, Previous/frozen selection, hint-section return/resume, one 6/6 attempt and two helped items after relaunch. Full 199-item uniqueness/seeded ordering is covered by both model suites. Existing twelve quiz/feedback tests pass unchanged on each device.
- AC3: Web focus assertions and EN/FR light/dark axe pass. Native headers/checkpoints use header traits and AccessibilityFocusState; EN light/dark and French AX-XXXL light/dark full audits pass on both iPhone/iPad. New local composite applies only approved occluded/measured contrast rules (TASK-70/71/73); nil, unmeasurable, low-contrast and non-contrast findings still fail. Every original ExamTools test/helper suffix is byte-identical to main.
- pnpm test PASS: content-tools 249, Morse 21, calculator 127, web 267 at the workspace run; the later added partial-round-score test passes separately (268 distinct web tests covered across runs). Final M1 flow/axe recheck PASS 5/5; model round tests PASS 2/2.
- pnpm check:schemas PASS 59/59; quiz checker PASS 37 files / 521 official refs / 92 concepts, including all six official-only M1 quizzes. content-swift swift test PASS 27/27.
- Final typecheck, web build, dist URL/CSP audit, import checks, links, Apple text-source checker, test-guard self-test and approved diff, and git diff --check PASS.
- pnpm check:apple-l10n PASS: complete French export; catalogue unchanged; CanadianHamTV and CanadianHamVision generic simulator builds both BUILD SUCCEEDED.
- Required PR marker: Test-guard-approved: owner decision 2026-10-22. Reviewer must verify the explicitly approved new lesson-quiz composite; old tests/helpers were not widened.
- No shared engine modules changed, so engine parity reruns/fixtures are N/A. No figure/title/card-layout change; separate figure/title sweeps N/A. Full Apple suites intentionally skipped by targeted-only direction.
- No manual VoiceOver or native macOS window session was performed; native accessibility semantics/focus bindings, automated full audits, localization and macOS compile/model tests are the evidence. The macOS host logged its existing local persistent-store unknown-model diagnostic; all regression stores are in-memory and passed, and no persistent data was deleted/reset by the worker.
- No PR opened. Independent reviewer approval is still required before the coordinator opens one.

Review follow-up direction (coordinator 2026-10-24): local occluded-or-measured composite also covers new TASK-46.8.1 M1-round lesson-quiz audits under owner delegation 2026-10-22. Round chrome/title follows interface language with English fallback; focus moves only on crossing round boundaries, never initial entry or within-round navigation. Full Apple suites remain deferred per owner decision 2026-10-17 to the eventual merge batch (iOS, macOS, tvOS, visionOS due shared content package).

Review follow-up implementation: recorded the dated 2026-10-24 audit widening in AGENTS.md and cited it in the new composite comment; Apple round/checkpoint titles now resolve interface language with existing EN fallback. Round focus is only requested at round changes/checkpoint entry, not initial loading, retry, or within-round Next/Previous. Web DOM focus and native production focus-routing regression assertions cover both directions and non-movement within rounds. Both readers retain the full legacy seeded order and suppress rounds if concept checks coexist; new TS/Swift tests verify no dropped checks. Unknown anchors/reversed sections cannot reset the checker high-water mark; regression added. New web group has appFlowTestTimeoutMs, seeded-ID comment corrected. Full Apple suites remain deferred per owner decision 2026-10-17 to the eventual four-platform merge batch. Production-source commit 791e41c5; test-fixture correction 7ec2f938. Requested full documented macOS unit command PASS 218/218 (mac-full.log). pnpm test final PASS: content-tools 250, Morse 21, calculator 127, web 270. Schemas 59/59, typecheck, Apple text-source self-test/check, web build/URL-CSP audit and guard self-test/approved diff PASS. Earlier full pnpm runs exposed unchanged practice hint-help timer and v6 IndexedDB-upgrade timeout flakes; final full pnpm run is green without editing those tests. New test-only fixture errors were corrected: web currently shares UI/bank preference; native checkpoint exact title includes Reference facts prefix. Apple 17-method/device runs and l10n remain queued under nohup in /tmp/task-46.8.1-review. Future PR guard approval must cite the dated widening (Test-guard-approved: owner decision 2026-10-24; retain 2026-10-22 marker where relevant). No old audit/helper or twelve existing quiz test bodies changed.

## Review-follow-up Apple per-test results (2026-10-24)
All requested Apple test runs exit 0 on final source commits 791e41c5 / 7ec2f938. The macOS command had no -only-testing filter: full CanadianHamTests target 218/218. iPhone and iPad each ran five M1 and twelve unchanged lesson-quiz methods: 17/17 each. Native EN/FR audits deliberately mismatch question-bank and interface languages and verify both round heading and checkpoint title. The production AccessibilityFocusState routing helper is asserted by the boundary unit test (initial/load: none; within-round Next/Previous: none; checkpoint: checkpoint; Continue and cross-round Previous: round heading). This is automated focus-routing evidence, not a manual VoiceOver session.

### macOS full CanadianHamTests
Log: /tmp/task-46.8.1-review/mac-full.log
Result: /Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-brprdowgzbmuxzcvfklrciudznua/Logs/Test/Test-CanadianHam-2026.10.24_16-34-00--0400.xcresult
- DuoLayoutPolicyTests/testCompactWidthIPhoneKeepsSheetPolicy: PASS (0.001s)
- DuoLayoutPolicyTests/testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact: PASS (0.001s)
- DuoLayoutPolicyTests/testIPadInspectorRuleRemainsSizeClassDriven: PASS (0.000s)
- DuoLayoutPolicyTests/testMacAndOtherIdiomsNeverUseIPhonePolicy: PASS (0.000s)
- DuoLayoutPolicyTests/testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy: PASS (0.000s)
- DuoLayoutPolicyTests/testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact: PASS (0.000s)
- ExamCalculatorViewModelTests/testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp: PASS (0.001s)
- ExamCalculatorViewModelTests/testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys: PASS (0.001s)
- ExamCalculatorViewModelTests/testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere: PASS (0.001s)
- ExamCalculatorViewModelTests/testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds: PASS (0.000s)
- ExamCalculatorViewModelTests/testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes: PASS (0.000s)
- ExamCalculatorViewModelTests/testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale: PASS (0.001s)
- ExamCalculatorViewModelTests/testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString: PASS (0.001s)
- ExamCalculatorViewModelTests/testKeyHandlingProducesEngineDisplayAndSpokenResult: PASS (0.001s)
- ExamCalculatorViewModelTests/testOfficialReferenceSheetGateAndBundledPages: PASS (0.001s)
- ExamCalculatorViewModelTests/testQuestionCardFocusResetKeepsTextSelectionEnabled: PASS (0.004s)
- ExamCalculatorViewModelTests/testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet: PASS (0.001s)
- ExamCalculatorViewModelTests/testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately: PASS (0.001s)
- HintSessionStateTests/testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine: PASS (0.001s)
- HintSessionStateTests/testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer: PASS (0.001s)
- HintSessionStateTests/testHingePeekEndsWhenPhoneFullyOpensOrCloses: PASS (0.001s)
- HintSessionStateTests/testHingePeekFastUnfoldThroughBandNeverPeeks: PASS (0.000s)
- HintSessionStateTests/testHingePeekLeavingToleranceDoesNotResetDismissalSuppression: PASS (0.000s)
- HintSessionStateTests/testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression: PASS (0.001s)
- HintSessionStateTests/testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell: PASS (0.001s)
- HintSessionStateTests/testHingePeekPresentationDismissalSuppressesReopenUntilReset: PASS (0.001s)
- HintSessionStateTests/testHingePeekPresentationImmediateAnswerEndsEligibility: PASS (0.001s)
- HintSessionStateTests/testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset: PASS (0.000s)
- HintSessionStateTests/testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear: PASS (0.001s)
- HintSessionStateTests/testHingePeekPresentationStartsOnlyOnceUntilPostureReset: PASS (0.001s)
- HintSessionStateTests/testHingePeekRecheckPeeksWithoutNewSamples: PASS (0.001s)
- HintSessionStateTests/testHingePeekRequiresStableDwellInSlightOpenBand: PASS (0.001s)
- HintSessionStateTests/testHingePeekSlowCloseThroughBandNeverPeeks: PASS (0.001s)
- HintSessionStateTests/testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek: PASS (0.001s)
- HintSessionStateTests/testHingePeekToleratesSmallJitterOnlyAfterPeekStarts: PASS (0.001s)
- HintSessionStateTests/testHingePeekUnavailableSampleDoesNotResetDismissalSuppression: PASS (0.001s)
- HintSessionStateTests/testHintQualificationMarksUnansweredQuestionAsQualifiedOnly: PASS (0.001s)
- HintSessionStateTests/testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp: PASS (0.403s)
- HintSessionStateTests/testHintVisibilityTimerDoesNotQualifyShortPeekRoute: PASS (0.294s)
- HintSessionStateTests/testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp: PASS (0.002s)
- HintSessionStateTests/testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable: PASS (0.001s)
- HintSessionStateTests/testReviewLaterHintAfterSelectionRecordsHelp: PASS (0.002s)
- HintSessionStateTests/testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission: PASS (0.001s)
- HintSessionStateTests/testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange: PASS (2.570s)
- LocalizationCatalogTests/testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata: PASS (0.003s)
- LocalizationCatalogTests/testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection: PASS (0.002s)
- LocalizationCatalogTests/testConceptCheckAnswerStatusMapsShuffledSourceChoices: PASS (0.003s)
- LocalizationCatalogTests/testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext: PASS (0.001s)
- LocalizationCatalogTests/testEveryCatalogKeyHasFrenchTranslations: PASS (0.014s)
- LocalizationCatalogTests/testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries: PASS (0.004s)
- LocalizationCatalogTests/testLanguagePreferenceResolvesSystemAndOverrides: PASS (0.001s)
- LocalizationCatalogTests/testLocalizedNullableTextAndLanguageFallsBackToEnglish: PASS (0.001s)
- LocalizationCatalogTests/testQuestionBankLoadErrorDescriptionUsesFrenchLocale: PASS (0.004s)
- LocalizationCatalogTests/testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench: PASS (0.001s)
- MorseTrainerTests/testCompletedMorseCourseSessionIgnoresResubmittedAnswer: PASS (0.001s)
- MorseTrainerTests/testFixedTimingProfilesUseEngineValues: PASS (0.001s)
- MorseTrainerTests/testLessonBodyAndBulletContrastTokensMeetMinimumRatio: PASS (0.001s)
- MorseTrainerTests/testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession: PASS (1.648s)
- MorseTrainerTests/testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp: PASS (0.001s)
- MorseTrainerTests/testMorseAudioSessionStaysActiveUntilLastPlayerReleases: PASS (0.001s)
- MorseTrainerTests/testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins: PASS (0.001s)
- MorseTrainerTests/testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas: PASS (0.001s)
- MorseTrainerTests/testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters: PASS (0.001s)
- MorseTrainerTests/testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone: PASS (0.002s)
- MorseTrainerTests/testMorseCourseProgressIgnoresStoredProgressForAnotherCourse: PASS (0.001s)
- MorseTrainerTests/testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition: PASS (0.001s)
- MorseTrainerTests/testMorseExamGeneratorMeetsReceivingExamConstraints: PASS (0.002s)
- MorseTrainerTests/testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime: PASS (0.001s)
- MorseTrainerTests/testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying: PASS (0.106s)
- MorseTrainerTests/testMorseSendingClassifiesTimingAndErrorSignal: PASS (0.002s)
- MorseTrainerTests/testMorseSendingKeyerClassifiesPressWhenAudioFails: PASS (0.005s)
- MorseTrainerTests/testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended: PASS (0.001s)
- MorseTrainerTests/testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError: PASS (0.103s)
- MorseTrainerTests/testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone: PASS (0.004s)
- MorseTrainerTests/testMorseSendingKeyerReleaseCannotBeSupersededBySilence: PASS (0.003s)
- MorseTrainerTests/testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress: PASS (0.104s)
- MorseTrainerTests/testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError: PASS (0.110s)
- MorseTrainerTests/testMorseSendingPendingFinalizationHelperCancelsAndClears: PASS (0.002s)
- MorseTrainerTests/testMorseSendingRemainingExamSecondsUsesFixedDeadline: PASS (0.002s)
- MorseTrainerTests/testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters: PASS (0.001s)
- MorseTrainerTests/testMorseSettingsClampAndPreset: PASS (0.001s)
- MorseTrainerTests/testMorseSettingsCodableRoundTripPreservesOutputMode: PASS (0.002s)
- MorseTrainerTests/testMorseSettingsDecodesLegacyPayloadWithIsEnabled: PASS (0.002s)
- MorseTrainerTests/testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast: PASS (0.011s)
- MorseTrainerTests/testMorseSettingsRoundTripThroughUserDefaults: PASS (0.004s)
- MorseTrainerTests/testMorseStopDelayDrainsFadeBeforeStoppingEngine: PASS (0.001s)
- MorseTrainerTests/testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced: PASS (0.001s)
- MorseTrainerTests/testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess: PASS (0.046s)
- MorseTrainerTests/testReduceFlashingDecisionUsesInjectedFlags: PASS (0.001s)
- MorseTrainerTests/testReduceFlashingStopsOnlyRunningVisualBeacon: PASS (0.001s)
- MorseTrainerTests/testScheduleMorseVisualPlaybackInitialStateAndFallback: PASS (0.001s)
- MorseTrainerTests/testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess: PASS (0.037s)
- ProgressStoreTests/testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress: PASS (0.078s)
- ProgressStoreTests/testAdvancedImportRejectsHonoursAttempts: PASS (0.024s)
- ProgressStoreTests/testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch: PASS (0.004s)
- ProgressStoreTests/testAppSettingsModelPublishesMorseSettingsForRootViewSync: PASS (0.001s)
- ProgressStoreTests/testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement: PASS (0.001s)
- ProgressStoreTests/testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows: PASS (0.001s)
- ProgressStoreTests/testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore: PASS (0.026s)
- ProgressStoreTests/testDecodesLegacyBasicExportWithoutBankIdFields: PASS (0.030s)
- ProgressStoreTests/testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme: PASS (0.031s)
- ProgressStoreTests/testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker: PASS (0.023s)
- ProgressStoreTests/testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt: PASS (0.059s)
- ProgressStoreTests/testFreshInstallDefaultsLanguageToSystem: PASS (0.011s)
- ProgressStoreTests/testICloudAccountSignalsUseInitInjectedFactory: PASS (0.069s)
- ProgressStoreTests/testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot: PASS (0.028s)
- ProgressStoreTests/testICloudDeleteCanDeleteLocalDataAfterZoneDelete: PASS (0.027s)
- ProgressStoreTests/testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload: PASS (0.035s)
- ProgressStoreTests/testICloudMergeFixtureIsPermutationIndependentAndIdempotent: PASS (0.002s)
- ProgressStoreTests/testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal: PASS (0.000s)
- ProgressStoreTests/testICloudSyncToggleAndAccountSignalsPreserveLocalProgress: PASS (0.049s)
- ProgressStoreTests/testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing: PASS (0.038s)
- ProgressStoreTests/testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields: PASS (0.036s)
- ProgressStoreTests/testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount: PASS (0.047s)
- ProgressStoreTests/testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons: PASS (0.062s)
- ProgressStoreTests/testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange: PASS (0.034s)
- ProgressStoreTests/testImportLeavesTask4610Version2LessonSplitRowsUnchanged: PASS (0.035s)
- ProgressStoreTests/testImportMigratesMixedTask4610SyncRowsByRowVersion: PASS (0.040s)
- ProgressStoreTests/testImportMigratesTask4610LessonSplitProgressAndQuizAttempts: PASS (0.039s)
- ProgressStoreTests/testImportOfOlderExportDoesNotRemoveExistingMorseProgress: PASS (0.034s)
- ProgressStoreTests/testImportRejectsInvalidSyncDeviceRows: PASS (0.039s)
- ProgressStoreTests/testImportRejectsUnsupportedLanguagePreferenceValues: PASS (0.038s)
- ProgressStoreTests/testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses: PASS (0.070s)
- ProgressStoreTests/testImportRollbackKeepsExistingDataWhenReplacementFails: PASS (0.044s)
- ProgressStoreTests/testImportRollbackPropagatesMorseProgressRemovalFailure: PASS (0.033s)
- ProgressStoreTests/testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress: PASS (0.032s)
- ProgressStoreTests/testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt: PASS (0.035s)
- ProgressStoreTests/testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues: PASS (0.001s)
- ProgressStoreTests/testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates: PASS (0.038s)
- ProgressStoreTests/testImportValidationRejectsDuplicateMorseDailyActivityDates: PASS (0.037s)
- ProgressStoreTests/testImportValidationRejectsInvalidMorseCourseProgress: PASS (0.038s)
- ProgressStoreTests/testImportValidationRejectsMismatchedScoreBankId: PASS (0.037s)
- ProgressStoreTests/testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt: PASS (0.034s)
- ProgressStoreTests/testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges: PASS (0.032s)
- ProgressStoreTests/testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults: PASS (0.037s)
- ProgressStoreTests/testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference: PASS (0.010s)
- ProgressStoreTests/testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault: PASS (0.014s)
- ProgressStoreTests/testLaunchIgnoresRegisteredAppleLanguagesValue: PASS (0.010s)
- ProgressStoreTests/testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue: PASS (0.009s)
- ProgressStoreTests/testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries: PASS (0.012s)
- ProgressStoreTests/testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun: PASS (0.013s)
- ProgressStoreTests/testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting: PASS (0.010s)
- ProgressStoreTests/testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce: PASS (0.010s)
- ProgressStoreTests/testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure: PASS (0.032s)
- ProgressStoreTests/testLessonQuizHelpFixtureValidationAndPayloadRoundTrips: PASS (0.139s)
- ProgressStoreTests/testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix: PASS (0.030s)
- ProgressStoreTests/testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice: PASS (2.624s)
- ProgressStoreTests/testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation: PASS (0.002s)
- ProgressStoreTests/testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead: PASS (0.056s)
- ProgressStoreTests/testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution: PASS (0.049s)
- ProgressStoreTests/testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution: PASS (0.033s)
- ProgressStoreTests/testM1QuizRoundBoundariesPreserveOneSessionAnswersHelpAndDismissedCheckpoint: PASS (0.558s)
- ProgressStoreTests/testM1QuizRoundsRetainEveryItemAndSeededOrderWithinTeachingSections: PASS (0.549s)
- ProgressStoreTests/testMigratesArchivedLessonProgressKeepsMaxOwnReadCount: PASS (0.012s)
- ProgressStoreTests/testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist: PASS (0.034s)
- ProgressStoreTests/testMigratesCommittedPreV2StoreFixtureWithAllDataIntact: PASS (0.404s)
- ProgressStoreTests/testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity: PASS (0.019s)
- ProgressStoreTests/testMigratesProgressStoreV1ToV2WithoutUniqueConstraints: PASS (0.070s)
- ProgressStoreTests/testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields: PASS (0.071s)
- ProgressStoreTests/testMockExamTimerRefreshPreservesFractionalRemainder: PASS (0.001s)
- ProgressStoreTests/testMorseCourseProgressRoundTripsTwentyRecentCharacterResults: PASS (0.029s)
- ProgressStoreTests/testMorseExportMapsHapticsToWebCompatibleAudio: PASS (0.001s)
- ProgressStoreTests/testMorseImportDecodesMissingAndPartialMorsePreferences: PASS (0.053s)
- ProgressStoreTests/testMorseImportRejectsExplicitNullMorseValues: PASS (0.001s)
- ProgressStoreTests/testMorseImportRejectsUnsupportedMorsePreferenceEnums: PASS (0.037s)
- ProgressStoreTests/testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender: PASS (0.944s)
- ProgressStoreTests/testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference: PASS (0.011s)
- ProgressStoreTests/testNativeSettingsGeneralBindingsUpdatePracticePreferences: PASS (0.011s)
- ProgressStoreTests/testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows: PASS (0.037s)
- ProgressStoreTests/testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt: PASS (0.011s)
- ProgressStoreTests/testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences: PASS (0.039s)
- ProgressStoreTests/testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse: PASS (0.034s)
- ProgressStoreTests/testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints: PASS (0.038s)
- ProgressStoreTests/testProgressStoreRoundTripExportImportReset: PASS (0.054s)
- ProgressStoreTests/testQuizRoundsWithConceptChecksKeepTheCompleteUngroupedOrder: PASS (0.551s)
- ProgressStoreTests/testResetAllDataTurnsICloudSyncOptInOff: PASS (0.013s)
- ProgressStoreTests/testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData: PASS (0.028s)
- ProgressStoreTests/testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure: PASS (0.044s)
- ProgressStoreTests/testResetClearsAppleLanguagesAndLanguagePreference: PASS (0.012s)
- ProgressStoreTests/testResetFailureKeepsPreviousAppleLanguagesAndPreference: PASS (0.013s)
- ProgressStoreTests/testResetRollsBackWhenMorseProgressRemovalFails: PASS (0.014s)
- ProgressStoreTests/testSavingLargeQuestionProgressBatchBuildsOneWriteContext: PASS (1.758s)
- ProgressStoreTests/testSharedAppleSettingsModelAppliesLivePreferenceUpdates: PASS (0.114s)
- ProgressStoreTests/testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules: PASS (0.001s)
- ProgressStoreTests/testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries: PASS (0.010s)
- ProgressStoreTests/testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress: PASS (0.102s)
- ProgressStoreTests/testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists: PASS (0.058s)
- ProgressStoreTests/testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite: PASS (0.030s)
- ProgressStoreTests/testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration: PASS (0.010s)
- ProgressStoreTests/testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices: PASS (0.042s)
- ProgressStoreTests/testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports: PASS (0.038s)
- ProgressStoreTests/testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration: PASS (0.028s)
- ProgressStoreTests/testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds: PASS (0.028s)
- ProgressStoreTests/testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating: PASS (0.097s)
- ProgressStoreTests/testTask4610SharedConceptMappingAndConceptInclusiveScores: PASS (0.230s)
- ProgressStoreTests/testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows: PASS (0.041s)
- ProgressStoreTests/testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync: PASS (0.055s)
- QuestionBankTests/testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames: PASS (0.013s)
- QuestionBankTests/testAdvancedMockExamUsesFiftyQuestionsAndNoHonours: PASS (0.013s)
- QuestionBankTests/testAppBundleContainsNoReadmeFiles: PASS (0.013s)
- QuestionBankTests/testAppBundleContainsOnlyExpectedGeneratedBankDirectories: PASS (0.001s)
- QuestionBankTests/testBundledJSONDecodesExpectedCounts: PASS (0.019s)
- QuestionBankTests/testBundledLessonModelExposesPrerequisites: PASS (0.557s)
- QuestionBankTests/testBundledLessonsAndExplanationsLoadThroughContentLibrary: PASS (0.745s)
- QuestionBankTests/testEngineQuestionDrawKeepsQuestionInsideRequestedCategory: PASS (0.019s)
- QuestionBankTests/testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion: PASS (0.080s)
- QuestionBankTests/testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes: PASS (0.001s)
- QuestionBankTests/testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons: PASS (0.561s)
- ReadinessAndScoringTests/testAdvancedScoringAndReadinessSuppressHonours: PASS (0.001s)
- ReadinessAndScoringTests/testExamScoringBoundaries: PASS (0.001s)
- ReadinessAndScoringTests/testReadinessStates: PASS (0.001s)
- ReadinessAndScoringTests/testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate: PASS (0.035s)
- RootNavigationMappingTests/testCompactHomeSessionAndSectionPushesUseVisibleDestination: PASS (0.001s)
- RootNavigationMappingTests/testEmptyCompactPathMapsToHome: PASS (0.001s)
- RootNavigationMappingTests/testEveryLearnRouteRoundTripsWithItsWholeStack: PASS (0.001s)
- RootNavigationMappingTests/testEveryRootSelectionRoundTrips: PASS (0.001s)
- RootNavigationMappingTests/testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts: PASS (0.001s)
- RootNavigationMappingTests/testPracticeHintLessonStackKeepsSessionAsSplitSelection: PASS (0.001s)

### iPhone 17 Pro targeted UI tests
Log: /tmp/task-46.8.1-review/phone.log
Result: /Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-brprdowgzbmuxzcvfklrciudznua/Logs/Test/Test-CanadianHam-2026.10.24_16-39-12--0400.xcresult
- CanadianHamExamToolsUITests/testLessonQuizConceptCheckHasNoHintOrOtherTools: PASS (23.207s)
- CanadianHamExamToolsUITests/testLessonQuizConceptOptionCorrectDarkAndFullAccessibilityAudit: PASS (72.561s)
- CanadianHamExamToolsUITests/testLessonQuizConceptOptionCorrectLightAndFullAccessibilityAudit: PASS (70.509s)
- CanadianHamExamToolsUITests/testLessonQuizConceptOptionFeedbackLargestDynamicType: PASS (203.289s)
- CanadianHamExamToolsUITests/testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit: PASS (77.596s)
- CanadianHamExamToolsUITests/testLessonQuizConceptOptionIncorrectFrenchFallbackLightAndFullAccessibilityAudit: PASS (74.290s)
- CanadianHamExamToolsUITests/testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip: PASS (303.883s)
- CanadianHamExamToolsUITests/testLessonQuizHintsDarkAndFullAccessibilityAudits: PASS (165.711s)
- CanadianHamExamToolsUITests/testLessonQuizHintsFrenchAndCurrentLessonRoundTrip: PASS (174.771s)
- CanadianHamExamToolsUITests/testLessonQuizHintsLightAndFullAccessibilityAudits: PASS (179.847s)
- CanadianHamExamToolsUITests/testLessonQuizOneLevelHintAndHelpCountPersistsAfterRelaunch: PASS (114.366s)
- CanadianHamExamToolsUITests/testLessonQuizPostChoiceHintsDoNotChangeSavedHelpAndRelaunchKeepsHelpCount: PASS (134.738s)
- CanadianHamExamToolsUITests/testM1QuizRoundsDarkAndFullAccessibilityAudits: PASS (190.570s)
- CanadianHamExamToolsUITests/testM1QuizRoundsFrenchLargestTypeDarkAndFullAccessibilityAudits: PASS (274.286s)
- CanadianHamExamToolsUITests/testM1QuizRoundsFrenchLargestTypeLightAndFullAccessibilityAudits: PASS (271.911s)
- CanadianHamExamToolsUITests/testM1QuizRoundsKeepHelpAnswersResumeAndOneSavedAttempt: PASS (408.394s)
- CanadianHamExamToolsUITests/testM1QuizRoundsLightAndFullAccessibilityAudits: PASS (198.225s)

### iPad Pro 13-inch (M5) targeted UI tests
Log: /tmp/task-46.8.1-review/pad.log
Result: /Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-brprdowgzbmuxzcvfklrciudznua/Logs/Test/Test-CanadianHam-2026.10.24_17-32-27--0400.xcresult
- CanadianHamExamToolsUITests/testLessonQuizConceptCheckHasNoHintOrOtherTools: PASS (18.896s)
- CanadianHamExamToolsUITests/testLessonQuizConceptOptionCorrectDarkAndFullAccessibilityAudit: PASS (32.885s)
- CanadianHamExamToolsUITests/testLessonQuizConceptOptionCorrectLightAndFullAccessibilityAudit: PASS (32.245s)
- CanadianHamExamToolsUITests/testLessonQuizConceptOptionFeedbackLargestDynamicType: PASS (42.392s)
- CanadianHamExamToolsUITests/testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit: PASS (33.598s)
- CanadianHamExamToolsUITests/testLessonQuizConceptOptionIncorrectFrenchFallbackLightAndFullAccessibilityAudit: PASS (36.070s)
- CanadianHamExamToolsUITests/testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip: PASS (94.101s)
- CanadianHamExamToolsUITests/testLessonQuizHintsDarkAndFullAccessibilityAudits: PASS (107.989s)
- CanadianHamExamToolsUITests/testLessonQuizHintsFrenchAndCurrentLessonRoundTrip: PASS (61.230s)
- CanadianHamExamToolsUITests/testLessonQuizHintsLightAndFullAccessibilityAudits: PASS (61.724s)
- CanadianHamExamToolsUITests/testLessonQuizOneLevelHintAndHelpCountPersistsAfterRelaunch: PASS (40.975s)
- CanadianHamExamToolsUITests/testLessonQuizPostChoiceHintsDoNotChangeSavedHelpAndRelaunchKeepsHelpCount: PASS (49.516s)
- CanadianHamExamToolsUITests/testM1QuizRoundsDarkAndFullAccessibilityAudits: PASS (86.631s)
- CanadianHamExamToolsUITests/testM1QuizRoundsFrenchLargestTypeDarkAndFullAccessibilityAudits: PASS (104.939s)
- CanadianHamExamToolsUITests/testM1QuizRoundsFrenchLargestTypeLightAndFullAccessibilityAudits: PASS (99.884s)
- CanadianHamExamToolsUITests/testM1QuizRoundsKeepHelpAnswersResumeAndOneSavedAttempt: PASS (166.292s)
- CanadianHamExamToolsUITests/testM1QuizRoundsLightAndFullAccessibilityAudits: PASS (86.329s)

Commands and selectors are retained verbatim in /tmp/task-46.8.1-review/apple.sh (nohup driver, one destination per command; grep polling; no builds killed). Per-test machine-readable evidence: /tmp/task-46.8.1-review/per-test-results.json. No full iOS/tvOS/visionOS suites were run. Full four-platform suites remain deferred per owner decision 2026-10-17 for the eventual merge batch because Models.swift is shared by all targets. macOS full units were explicitly requested and completed here. Final localization validation is still running/queued; it will be recorded separately.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented 24 bilingual, teaching-section-sized rounds across all six M1 quizzes, preserving all 199 official items, one session/attempt and existing seeded relative order/choice permutations. Explicit round metadata is schema-checked and validated against lesson heading order, exact titles and hint teaching anchors. Web and iOS/iPadOS/macOS now show round/question progress, accessible between-round score checkpoints and Continue, cross-round Previous/Next, native/web focus, and unchanged final submit/scoring/help/persistence/lesson-link resume. Non-M1 quizzes remain unchanged; tvOS/visionOS quiz UI is N/A by approved scope, with both shared-content builds passing. Validation: pnpm test and targeted partial-score/focus/EN-FR light/dark axe tests; schemas 59; content-swift 27; macOS 14 targeted units; iPhone 17/17 and iPad 17/17 distinct UI methods, including all 12 unchanged quiz/feedback regressions per device and new full light/dark/AX audits. Localization export is complete and catalogue unchanged; web build/URL+CSP, imports, links, text-source and approved test-guard checks pass. Per-test results/xcresult paths and original test-only fixes are recorded above. No old audit/helper/test weakening, no full Apple suites, no PR. No manual VoiceOver/macOS window session; automated native focus/AX and model/build coverage used. Done and ready for independent branch review; PR marker owner decision 2026-10-22 required.
<!-- SECTION:FINAL_SUMMARY:END -->
