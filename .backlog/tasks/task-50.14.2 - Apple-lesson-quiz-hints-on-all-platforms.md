---
id: TASK-50.14.2
title: Apple lesson-quiz hints on all platforms
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-20 13:03'
updated_date: '2026-10-20 16:47'
labels:
  - apple
dependencies:
  - TASK-50.14.1
parent_task_id: TASK-50.14
ordinal: 142000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apply the owner-approved 2026-10-20 rules in TASK-50.14 after the web/model contract lands. Cover iOS/iPadOS/macOS/tvOS/visionOS, reusing bundled hints and the answeredWithHelp attempt model from TASK-50.14.1; lesson quizzes are now approved, not mock exams.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Official bank quiz items on iOS/iPadOS/macOS/tvOS/visionOS reuse practice hint ladder, one-level handling, generic lesson link (including current lesson), reference-sheet availability gating and offline content; concept checks expose no Hint control; mock exams and timed modes stay unchanged.
- [ ] #2 At least 0.5 s hint visibility before scoring qualifies help; post-score hints never mutate records; quiz/hint/answer state survives lesson-link round trips and layout/navigation changes.
- [ ] #3 Hinted correct answers count as correct, results summary counts helped answers, each per-question result marks with help, and passing/completion are unchanged; UI strings are plain translated EN/FR with French English-only-lesson notice.
- [ ] #4 Existing question-progress paths apply TASK-50.15 scheduling/weak-area/recent-answer semantics; persist answeredWithHelp in quiz attempts using the shared model and preserve old attempts without flags, including import/export/sync round trips.
- [ ] #5 Targeted unit/UI tests cover timing, score, progress, persistence, EN/FR, current/other lesson links and hint exclusions; VoiceOver/focus/Dynamic Type and light/dark accessibility audits cover affected screens without weakening tests; Apple localization/text checks and relevant platform checks pass. Web axe evidence remains covered by dependency TASK-50.14.1.
- [ ] #6 Match the web attempt contract: optional answeredWithHelpIds array, sorted unique subset of officialQuestionIds, missing means none; reject unknown/concept IDs in import/sync, preserve the field through persistence/export/import/sync and lesson-ID migrations (filter to destination official membership if an attempt splits).
- [ ] #7 Lesson quizzes have a hint-only toolbar/panel: no calculator or reference sheet is added. Use referenceSheetAvailable=false and hide existing reference-sheet pointer labels, including when the hint metadata has a pointer.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Extend Apple quiz attempt payload, validation, sync and lesson migration to preserve the shared helped-ID contract; add fixture and round-trip tests.
2. Reuse practice hint presentation and timing in every rendered lesson quiz, freeze help at choice, retain session on lesson-link visits, and add localized score/feedback markers.
3. Add focused unit and UI coverage (EN/FR, timing, exclusions, navigation and full light/dark audits); run localization checks and targeted macOS/iPhone/iPad/tvOS/visionOS xbuild tests using nohup scripts.
4. Commit/push before build waits, record per-test evidence, and finalize only verified acceptance criteria.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Review note (TASK-50.14.1 review 2026-10-20): current Apple builds, including TestFlight, accept and then DROP answeredWithHelpIds on lesson-quiz attempts. LessonQuizAttempt (ProgressStore.swift ~206) and DeviceLessonQuizAttemptRecord (ProgressSyncMerge.swift 43-59) use default Decodable, which ignores unknown keys, and upsertLessonQuizAttempt (~2019) re-encodes without the field, so web → Apple import/sync → export loses the flag (scores unaffected). Storage: Apple keeps attempts as a JSON payload blob (payloadData), so adding the optional field needs no SwiftData model migration, but old blobs and archived JSON must decode as none. Validation must reject unknown, concept-check, unsorted and duplicate IDs, matching web.

Coordinator confirmed tvOS/visionOS have no lesson quizzes: no new quiz surface; iOS/iPadOS/macOS UI and shared attempt payload are in scope. tvOS/visionOS build-only validation required if their compiled shared files change. Implemented optional payload field, strict help-ID validation, migration filtering, root-owned quiz session cache, practice hint-only panel and markers. Added fixture/persistence/import/sync tests and focused UI/audit tests; validation starting.

Validation so far (all through nohup xbuild scripts, logs /tmp/task-50.14.2-runs): macOS targeted run PASS, 32/32 tests (HintSessionStateTests 26/26; ProgressStoreTests: help fixture/payload/import/export/sync parity, session cache, split migration, concept-inclusive migration fixture, atomic archived multi-device migration and save rollback all PASS). Separate real 0.5-second/freeze-at-choice test PASS, 1/1. pnpm check:schemas PASS (2,034 targets); node scripts/check-apple-text-sources.ts PASS; test-guard self-test PASS. Guard reports only the three added full-default audit calls, intentional under the owner 2026-10-20 lesson-quiz decision; current checker does not accept dotted task IDs in approval markers, so PR should use Test-guard-approved: owner decision 2026-10-20. iPhone/iPad focused UI tests and full localization/tvOS/visionOS builds pending shared lock. No full test suites run.

Initial iPhone UI run: concept exclusions, French/current-lesson round trip, one-level-help persistence and post-choice immutability/persistence PASS. AX/layout was blocked by the existing debug overlay covering Hint; new-test positioning now scrolls Hint below that overlay and explicitly asserts it is not overlapped. Light/dark feedback audits exposed only opaque-navigation-bar occluded text false positives (xcresult screenshots in /tmp/task-50.14.2-runs/phone-failures). R2 confirmed moving one header merely exposed the next occluded element. Coordinator explicitly authorized calling existing auditIgnoringOccludedLessonTextContrast for quiz feedback in light/dark under owner decision 2026-10-12. The helper is byte-identical; fully visible contrast and all non-contrast issues still fail. Removed the attempt to position-shuffle the occluded header. Hint-panel and top-visible saved-results audits remain unfiltered defaults. PR marker now required: Test-guard-approved: owner decision 2026-10-12. All affected tests queued for targeted rerun; no full suite.

Localization validation completed PASS: pnpm check:apple-l10n (complete French XLIFF export, catalogue unchanged, generic CanadianHamTV and CanadianHamVision builds both BUILD SUCCEEDED). R2 iPhone: French/current-lesson round trip PASS (238.844s), one-level hinted-help persistence PASS (135.128s), post-choice immutability/persistence PASS (139.328s), light full-default panel/feedback/result audits PASS (182.198s); AX failed because the existing test-only layout overlay intercepted the tap, and dark failed on the next occluded header text. Those two causes are addressed in current source. R3 is queued for AX plus light/dark audit tests, followed by the 7-test iPad Pro 13-inch (M5) run. Programmatic suffix comparison against e04991d8 confirms every pre-existing ExamTools UI test and every audit/positioning helper remains byte-identical. No full suites.

R3 dark panel/approved-feedback/default-result audits PASS (201.045s). AX still failed before reopening because content would not scroll, revealing the actual integration error: examToolPresentation had been attached inside the outer quiz ScrollView, producing a fixed inspector container around tall card content at regular width. Moved the presenter outside the quiz ScrollView exactly as practice does; retained all load-error handling. Current source ce146da5 is pushed. R4 nohup script queued: targeted macOS cache+timing tests to compile the revised screen, then all 7 affected new quiz UI methods on iPhone 17 Pro and iPad Pro 13-inch (M5), stop on first failed command. Shared/approved helpers remain byte-identical; no suite or test/audit removal.
<!-- SECTION:NOTES:END -->
