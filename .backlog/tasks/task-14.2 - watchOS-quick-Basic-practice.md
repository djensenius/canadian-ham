---
id: TASK-14.2
title: watchOS quick Basic practice
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T17:01:00Z'
updated_date: '2026-10-25T18:02:00Z'
labels:
  - apple
  - watchos
milestone: m-1
dependencies:
  - TASK-14.1
documentation:
  - docs/proposals/watchos-companion.md
parent_task_id: TASK-14
type: feature
ordinal: 156000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Short wrist-sized practice should work without a phone, history or study setup. Follow the tvOS in-memory model while omitting its lessons and hints. The full 984-question bilingual Basic bank plus existing explanations measures 2,360,969 raw bytes in the proposal; prefer it over a divergent subset. ContentLibrary.load currently requires lesson/module validation, so reuse content-swift models/parser without pulling lessons into the watch bundle.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The watch bundles all 984 Basic questions with original EN/FR stems and four answers, bank metadata and existing explanations; bundle tests verify IDs/counts and exclude Advanced, hints, lessons, quizzes and figures, and installed size/decode-time/memory measurements are recorded.
- [ ] #2 Quick practice presents a random Basic question and four shuffled choices using engine-swift while retaining sourceIndex for grading; seeded unit tests cover correct and wrong choices after shuffling and empty/load-error handling.
- [ ] #3 Tap submits an answer; the Digital Crown can select any of four choices followed by explicit confirmation, without scrolling accidentally submitting; targeted watch UI tests cover both input paths.
- [ ] #4 Submitting immediately locks the selection and shows textual correct/incorrect feedback, the correct answer and the existing explanation; Next resets feedback for a fresh question. Explanations remain scrollable and hint-free, with no dead lesson links.
- [ ] #5 Session/answers/scores and settings are in memory only: no progress store, files, UserDefaults, App Groups or transfer. A relaunch test proves that answers are not restored, and offline operation is verified without a phone counterpart.
- [ ] #6 Relevant watch unit and UI tests pass via xbuild with per-test evidence. Official EN/FR text remains verbatim; missing French explanation bodies use a clearly labelled English fallback with the correct accessibility language rather than a new translation.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a watch-only Basic/explanations loader and in-memory seeded practice model, with bundle and grading/error tests.
2. Implement semantic, scrollable tap/Crown-confirm practice and labelled English explanation fallback; add EN/FR watch UI coverage including relaunch.
3. Regenerate XcodeGen twice; run watch tests, localization/text/privacy/test guards, embedded iOS build and macOS units; record size/decode/memory and per-test evidence.
4. Commit/push milestones, verify acceptance evidence and finalize the task without opening a PR.
<!-- SECTION:PLAN:END -->
