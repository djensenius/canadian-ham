---
id: TASK-50.14.1
title: 'Web lesson-quiz hints, attempt models and schemas'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-20 13:03'
updated_date: '2026-10-20 13:23'
labels:
  - web
  - engine
dependencies: []
parent_task_id: TASK-50.14
ordinal: 141000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apply the owner-approved 2026-10-20 lesson-quiz hint decision recorded verbatim in TASK-50.14 to web, and establish compatible attempt data for the dependent Apple work. Reuse existing bundled Basic hints rather than authoring new hint content; do not change Apple app files.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Official bank items expose the existing accessible EN/FR practice hint ladder (including one-level cases), generic lesson link and reference-sheet gating; concept checks have no Hint control; mock exams and timed modes remain unchanged.
- [x] #2 A hint visible at least 0.5 s before item scoring records answeredWithHelp; post-score hints do not mutate it; lesson-link round trips (including the current lesson) preserve quiz answers and hint state.
- [x] #3 Hinted correct answers still count as correct; summary counts helped answers and per-question feedback/review marks with help in plain translated EN/FR; passing and lesson completion stay unchanged.
- [x] #4 Existing question-progress updates use TASK-50.15 semantics (hinted correct keeps box and due now, incorrect stays incorrect, weak attempts get no proficiency credit); attempt records preserve optional answeredWithHelp across persistence/export/import and sync with backwards compatibility and TS/Swift parity/shared fixtures wherever model behavior changes.
- [x] #5 Unit/integration tests cover timing boundaries, scoring, progress, persistence compatibility, EN/FR and lesson navigation; keyboard/VoiceOver-readable semantics and light/dark axe audits pass without weakening tests. Required typecheck, test, build, URL audit, schema, import and engine parity checks pass; engine-swift swift test runs if changed.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add optional sorted unique answeredWithHelpIds to quiz attempt/schema/import/sync validation; preserve compatible legacy records and filter IDs to destination membership during split migration. Existing engines already implement progress semantics, so no engine API change is needed.
2. Lift quiz session state to App for lesson navigation survival; reuse ExamTools/HintTool for official items only and freeze help at immediate choice scoring, passing flags to progress at final submit.
3. Add EN/FR help feedback and summary, persistence/migration/schema tests plus timing/navigation/progress/light-dark axe integration tests.
4. Run required checks and engine parity, record evidence, commit/push and finalize.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Coordinator approved optional answeredWithHelpIds (readonly string[]) matching existing attempt ID-array shape: sorted, unique subset of officialQuestionIds; missing means none. Help freezes on choice because feedback scores immediately; final submit passes the flag to existing applyAnswer. Apple app model/persistence is deferred to .2. No engine parity change is needed: engines do not own quiz attempts and applyAnswer already supports help.

Model step committed/pushed: optional sorted unique official answeredWithHelpIds, shared compatibility fixture, schema (including sortedSubset assertion), import/sync validation and split-migration filtering. New focused compatibility tests: 3 passed; schema tests: 56 passed. Whole progressStore test file initially hit existing v6-device migration 5 s timeout under load; no tests or timeouts were weakened. UI work is in progress.

Completed web implementation (66ff2ed9) and model/schema implementation (cc23863a).
- Coordinator clarification: lesson quizzes are hint-only, adding neither calculator nor reference sheet. Sheet pointer labels are hidden with referenceSheetAvailable=false; Apple ACs record the same contract.
- AC1: existing HintTool/ExamTools ladder, generic link, one-level case, EN/FR, pointer suppression and concept/mock exclusions covered in App.test.tsx plus existing practice/mock coverage.
- AC2: 499 ms vs 500 ms, post-score immutability, early-close and same-lesson-link timer cancellation, current/other lesson round trips and preserved scored feedback covered by focused integration tests. Same-lesson links hide the hint panel to stop offscreen qualification.
- AC3: helped correct/incorrect count normally (10/11 test), localized summary and per-question With help/Avec aide markers, unchanged completion, retry state and submitted-item review verified.
- AC4: existing applyPracticeAnswer forwards answeredWithHelp; hinted correct keeps box 3/due now, incorrect resets box 0/due now, accuracy/recent-help arrays preserved. Engines unchanged and existing shared engine fixtures still pass. Optional answeredWithHelpIds uses shared fixtures/lesson-quiz-help.json; persistence/export/import/sync compatibility, invalid IDs/order/duplicates and split migration covered. Common-schema references automatically apply to progress exports and device rows.
- AC5: focused lesson flows 12 passed. Full pnpm test passed at final code: content-tools 153, morse 21, calculator 127, web 235; release-permission self-test passed. pnpm typecheck, pnpm build:web, pnpm --filter @canadian-ham/web audit:urls, pnpm check:schemas (56 tests), pnpm import:check and bash scripts/check-engine-parity.sh passed. Engine parity: TS 23 / Swift xbuild macOS package 21, all zero failures. EN/FR light/dark axe audits cover hint-open, helped feedback and submitted results; keyboard reveal/Escape/focus and live-status semantics verified through DOM tests. No manual VoiceOver session performed.
- Initial runs hit existing loaded-machine timeouts in v6-device migration and lesson quiz initial-render waits; focused reruns and final full pnpm test passed unchanged, without increasing timeouts or weakening assertions. Tightened answer-choice test helper to exact localized text matching so numeric answer substrings cannot choose a distractor.
- Non-failing existing tooling warnings: jsdom canvas getContext unavailable for axe; Vite large-chunk warning; git credential-store warning (-25308), while each push succeeded.
- No Apple app files or Swift sources changed. iOS/iPadOS/macOS/tvOS/visionOS app suites skipped (Apple work belongs to TASK-50.14.2; unchanged Swift engine behavior validated by parity). Separate swift test not needed because engine-swift did not change.
- Internal reviewer gate remains for coordinator before any PR. No PR opened.

Engine parity xbuild per-test results (all PASS):
- CanadianHamEngineTests.FixtureTests testEveryEngineFixtureMatchesSwiftEngine: PASS
- CanadianHamEngineTests.FixtureTests testJSONComparatorRejectsExtraExpectedOutputKey: PASS
- CanadianHamEngineTests.PCG32Tests testPCG32SrandomDemoMatchesPublishedCOutputs: PASS
- CanadianHamEngineTests.ValidationTests testAdvancedReadinessDoesNotCountExamsBelowSeventyPercent: PASS
- CanadianHamEngineTests.ValidationTests testAdvancedReadinessTreatsSeventyPercentPassThresholdAsInclusive: PASS
- CanadianHamEngineTests.ValidationTests testApplyAnswerRejectsOutOfRangeLeitnerBoxes: PASS
- CanadianHamEngineTests.ValidationTests testBankRulesAcceptFutureSchemaValidBasicIds: PASS
- CanadianHamEngineTests.ValidationTests testBankRulesAcceptOnlySchemaValidBasicAndAdvancedIds: PASS
- CanadianHamEngineTests.ValidationTests testEngineTimestampInputsRequireCanonicalMillisecondUTCFormat: PASS
- CanadianHamEngineTests.ValidationTests testExamGenerationRequiresCanonicalAnswerSourceIndexes: PASS
- CanadianHamEngineTests.ValidationTests testFullMockExamGenerationUsesActiveBankSubsectionCount: PASS
- CanadianHamEngineTests.ValidationTests testHintedCorrectPreservesAccuracyWithoutMasteryCredit: PASS
- CanadianHamEngineTests.ValidationTests testOlderProgressJsonDecodesHelpFieldsAsFalse: PASS
- CanadianHamEngineTests.ValidationTests testPracticeExamGenerationDoesNotRequireKnownBankRulesUnlessFullMockIsRequested: PASS
- CanadianHamEngineTests.ValidationTests testReadinessRejectsDuplicateSubmittedAtTimestamps: PASS
- CanadianHamEngineTests.ValidationTests testScoreExamRejectsUnsupportedBankIds: PASS
- CanadianHamEngineTests.ValidationTests testSharedBankRulesFixtureAgreesWithSwiftEngine: PASS
- CanadianHamEngineTests.ValidationTests testTimestampAdditionCrossesMonthAndYearBoundaries: PASS
- CanadianHamEngineTests.ValidationTests testTimestampFormattingRejectsYearsOutsideCanonicalRange: PASS
- CanadianHamEngineTests.ValidationTests testTimestampParserAcceptsLeapDayInLeapYears: PASS
- CanadianHamEngineTests.ValidationTests testTimestampParserRejectsImpossibleDatesAndNonAsciiDigits: PASS
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented hint-only web lesson quizzes for official questions, preserving scores/completion and freezing help at choice after 0.5 s visibility. Added localized feedback and results counts, session-preserving lesson navigation, optional validated answeredWithHelpIds in attempts/import/export/sync, split-migration compatibility and shared fixtures. All requested checks passed, including 235 web tests, 56 schema tests and TS/Swift engine parity. Apple implementation remains in TASK-50.14.2; no Apple app/Swift source edits. Ready for internal review, not a PR.
<!-- SECTION:FINAL_SUMMARY:END -->
