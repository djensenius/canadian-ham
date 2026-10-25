---
id: TASK-14.2
title: watchOS quick Basic practice
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T17:01:00Z'
updated_date: '2026-10-25T18:36:00Z'
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Milestone 1 pushed: watch-only Basic/explanation resource membership, narrow content-swift loader, seeded engine-swift shuffle/grading and in-memory session, scrollable tap/feedback/Next and native Crown-picker/explicit-confirm sheet. Added six practice unit tests and two practice UI tests; skeleton navigation checks now recognize practice. Initial compile fixes qualify CanadianHamContent.Category and avoid the watch-unavailable picker adjust API; native XCUIDevice.rotateDigitalCrown(delta:) compiles. Watch xbuild is queued behind the shared build lock; no other build was killed. Text/network/iCloud guards and their fixtures, test-guard self-test, and project double-generation determinism passed.

Milestone 2: all 10 watch unit tests now pass, tap/feedback/Next/relaunch UI passes, and the French Crown UI passes using actual XCUIDevice.shared.rotateDigitalCrown(delta:) events: it visited all four answer texts before explicit Confirm, then verified French feedback, labelled English fallback and Next. The Crown handler must be attached to the focusable scroll container, not a nested native Picker or Text (the latter routed input to scrolling). Final implementation also exposes the answer as an accessibility-adjustable control. Localization export plus tvOS/visionOS/watch generic builds and embedded iOS build-for-testing passed. Full macOS units are running; final targeted rerun will verify robust long-choice touch scrolling. No tests/audits skipped or weakened.
<!-- SECTION:NOTES:END -->
