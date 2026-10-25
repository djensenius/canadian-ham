---
id: TASK-14.2
title: watchOS quick Basic practice
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T17:01:00Z'
updated_date: '2026-10-25T18:54:00Z'
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
- [x] #1 The watch bundles all 984 Basic questions with original EN/FR stems and four answers, bank metadata and existing explanations; bundle tests verify IDs/counts and exclude Advanced, hints, lessons, quizzes and figures, and installed size/decode-time/memory measurements are recorded.
- [x] #2 Quick practice presents a random Basic question and four shuffled choices using engine-swift while retaining sourceIndex for grading; seeded unit tests cover correct and wrong choices after shuffling and empty/load-error handling.
- [x] #3 Tap submits an answer; the Digital Crown can select any of four choices followed by explicit confirmation, without scrolling accidentally submitting; targeted watch UI tests cover both input paths.
- [x] #4 Submitting immediately locks the selection and shows textual correct/incorrect feedback, the correct answer and the existing explanation; Next resets feedback for a fresh question. Explanations remain scrollable and hint-free, with no dead lesson links.
- [x] #5 Session/answers/scores and settings are in memory only: no progress store, files, UserDefaults, App Groups or transfer. A relaunch test proves that answers are not restored, and offline operation is verified without a phone counterpart.
- [x] #6 Relevant watch unit and UI tests pass via xbuild with per-test evidence. Official EN/FR text remains verbatim; missing French explanation bodies use a clearly labelled English fallback with the correct accessibility language rather than a new translation.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a watch-only Basic/explanations loader and in-memory seeded practice model, with bundle and grading/error tests.
2. Implement semantic, scrollable tap/Crown-confirm practice and labelled English explanation fallback; add EN/FR watch UI coverage including relaunch.
3. Regenerate XcodeGen twice; run watch tests, localization/text/privacy/test guards, embedded iOS build and macOS units; record size/decode/memory and per-test evidence.
4. Commit/push milestones, verify acceptance evidence and finalize the task without opening a PR.

5. Review fixes: lazy off-main cached bank with loading UI; parsed choice-labelled explanations; deterministic UI seeds and meaningful bundle/session checks; headers and submit announcement. Re-measure a first-touch load, rerun watch/localization/guards/iOS and shared-catalogue macOS checks, update evidence, commit and push without a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Milestone 1 pushed: watch-only Basic/explanation resource membership, narrow content-swift loader, seeded engine-swift shuffle/grading and in-memory session, scrollable tap/feedback/Next and native Crown-picker/explicit-confirm sheet. Added six practice unit tests and two practice UI tests; skeleton navigation checks now recognize practice. Initial compile fixes qualify CanadianHamContent.Category and avoid the watch-unavailable picker adjust API; native XCUIDevice.rotateDigitalCrown(delta:) compiles. Watch xbuild is queued behind the shared build lock; no other build was killed. Text/network/iCloud guards and their fixtures, test-guard self-test, and project double-generation determinism passed.

Milestone 2: all 10 watch unit tests now pass, tap/feedback/Next/relaunch UI passes, and the French Crown UI passes using actual XCUIDevice.shared.rotateDigitalCrown(delta:) events: it visited all four answer texts before explicit Confirm, then verified French feedback, labelled English fallback and Next. The Crown handler must be attached to the focusable scroll container, not a nested native Picker or Text (the latter routed input to scrolling). Final implementation also exposes the answer as an accessibility-adjustable control. Localization export plus tvOS/visionOS/watch generic builds and embedded iOS build-for-testing passed. Full macOS units are running; final targeted rerun will verify robust long-choice touch scrolling. No tests/audits skipped or weakened.

All 6 ACs verified; evidence: docs/testing/task-14.2-watch-practice.md. Installed watch bundle has exactly 988 original JSON resources (byte-for-byte source matches), 2,360,969 raw bytes, no excluded content; Debug installed logical/allocated bytes 16,773,998/19,832,832 including injected test PlugIns (app excluding them: 10,025,821/13,062,144). Final cold load 0.218668292 s, retained-bank resident delta 8,159,232 bytes. The paired iPhone simulator had no CanadianHam counterpart installed. 10 unit and 4 UI tests passed across targeted watch runs; final unchanged-source 640ddb3e run passed cold load plus both practice UI methods. Full macOS unit target 223/223; iOS embedded build-for-testing; localization/export/generic builds; text, network/iCloud + fixtures, test guard/self-test and XcodeGen twice with empty determinism diff all passed. Initial UI failures were fixed and rerun only at affected class/method scope. No accessibility exceptions or audit weakening. Hardware/VoiceOver listening/full audits remain existing TASK-14.5/14.6 gates. No PR or TestFlight upload opened.

Reopened for internal review fixes: eager main-thread loads and raw authoring explanation text are blockers; addressing test determinism and low accessibility/catalogue notes in the same narrow review round.

Review-fix implementation committed at d8790e996a55aa497e84d77fc733b0210957fb05 (catalogue cleanup abdf6079). Practice has optional session + labelled loading ProgressView, navigation-value destinations and a shared actor caching a detached off-main load. All 984 EN/FR rendered explanation paths now parse authoring text, quote distractor choices and tag English fallback runs en-CA. DEBUG/UI-test seed 3121 fixes the first two draws; no hard-coded answer-state assertion. Headers and localized submit announcements added. Full watch run: 14/15 passed, with one overly strict new assertion rejecting the existing AppIcon Assets.car; fixed to real SVG/PNG resource checks and independent assetutil metadata (only AppIcon). Targeted cold/bundle/tap rerun passed 3/3. Initial localization export correctly exposed newly-unused Not selected, now removed via ordered Python round-trip; retry and final catalogue-based measurement are queued. iOS/macOS gates still running/queued.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented standalone offline watch Basic quick practice: full original 984-question bilingual bank and explanations, narrow lesson-free loader, seeded engine shuffle/sourceIndex grading, tap or focus-owned Crown selection with explicit confirmation, textual feedback/correct answer/explanation/Next, and clearly labelled en-CA English fallback in French. All state is in memory; relaunch and no-phone-counterpart behaviour verified. Added bundle/grading/error/fallback/measurement tests and EN/FR practice UI tests. Validation and all per-test results recorded in docs/testing/task-14.2-watch-practice.md; 14 distinct watch tests and all 223 macOS units pass across focused runs; embedded iOS build and all requested guards/checks pass. Physical-watch performance/VoiceOver and full accessibility audits remain planned follow-up gates, not claimed here.
<!-- SECTION:FINAL_SUMMARY:END -->
