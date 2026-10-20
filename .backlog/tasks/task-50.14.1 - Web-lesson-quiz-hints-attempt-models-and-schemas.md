---
id: TASK-50.14.1
title: 'Web lesson-quiz hints, attempt models and schemas'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-20 13:03'
updated_date: '2026-10-20 13:10'
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
- [ ] #1 Official bank items expose the existing accessible EN/FR practice hint ladder (including one-level cases), generic lesson link and reference-sheet gating; concept checks have no Hint control; mock exams and timed modes remain unchanged.
- [ ] #2 A hint visible at least 0.5 s before item scoring records answeredWithHelp; post-score hints do not mutate it; lesson-link round trips (including the current lesson) preserve quiz answers and hint state.
- [ ] #3 Hinted correct answers still count as correct; summary counts helped answers and per-question feedback/review marks with help in plain translated EN/FR; passing and lesson completion stay unchanged.
- [ ] #4 Existing question-progress updates use TASK-50.15 semantics (hinted correct keeps box and due now, incorrect stays incorrect, weak attempts get no proficiency credit); attempt records preserve optional answeredWithHelp across persistence/export/import and sync with backwards compatibility and TS/Swift parity/shared fixtures wherever model behavior changes.
- [ ] #5 Unit/integration tests cover timing boundaries, scoring, progress, persistence compatibility, EN/FR and lesson navigation; keyboard/VoiceOver-readable semantics and light/dark axe audits pass without weakening tests. Required typecheck, test, build, URL audit, schema, import and engine parity checks pass; engine-swift swift test runs if changed.
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
<!-- SECTION:NOTES:END -->
