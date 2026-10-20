---
id: TASK-50.14.1
title: 'Web lesson-quiz hints, attempt models and schemas'
status: To Do
assignee: []
created_date: '2026-10-20 13:03'
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
