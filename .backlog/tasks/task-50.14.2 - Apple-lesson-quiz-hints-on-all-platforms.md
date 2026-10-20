---
id: TASK-50.14.2
title: Apple lesson-quiz hints on all platforms
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-20 13:03'
updated_date: '2026-10-20 13:57'
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
<!-- SECTION:NOTES:END -->
