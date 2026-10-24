---
id: TASK-46.8.1
title: Section-sized M1 lesson quiz rounds on web and Apple
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-21 14:58'
updated_date: '2026-10-24 18:48'
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
- [ ] #1 M1 lesson quizzes run in teaching-section-sized rounds on web and iOS/iPadOS/macOS/tvOS/visionOS, with every existing official quiz item retained and mapped to its teaching section.
- [ ] #2 Round navigation, scoring, completion, saved attempts, help flags, and lesson-link round trips preserve the TASK-50.14.2 behavior; no question is dropped or counted twice.
- [ ] #3 Targeted web and Apple tests cover round boundaries and persistence; accessible focus, VoiceOver, Dynamic Type, light/dark audits and localization checks pass on affected platforms without weakening audit coverage.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the existing quiz content/readers/sessions and derive explicit M1 round metadata from precise hint anchors in heading order; validate complete unique coverage.
2. Add section-grouped presentation/navigation/checkpoints to web and Apple while retaining one attempt/session, seeded ordering, hints and existing non-M1 behavior.
3. Add content, web and macOS model tests plus targeted iPhone/iPad round navigation, EN/FR and full light/dark audit coverage; keep existing helpers/tests unchanged.
4. Commit before nohup targeted validation, poll logs, run required schema/workspace/localization/guard checks, then record AC evidence, finalize, commit and push (no PR). tvOS/visionOS lesson quizzes N/A per coordinator/TASK-50.14.2.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented explicit bilingual M1 rounds derived from hint section anchors, with schema + checker validation for unique complete coverage, heading order, titles/translations and hint agreement. There are 24 rounds across six quizzes, retaining all 199 official items. Both readers group the original seeded order without changing choice permutations; non-M1 quizzes remain ungrouped. One cached session and one final attempt remain in use. Coordinator confirmed checkpoints only between rounds, correct/total and answered count, unrestricted unanswered navigation, and no reopening a dismissed checkpoint on resume. New web round/help/persistence/resume and EN/FR light/dark axe tests pass. pnpm test PASS: content-tools 249, Morse 21, calculator 127, web 267; schemas 59/59, typecheck and content-swift 27/27 PASS. First macOS targeted run waiting on shared xbuild lock. tvOS/visionOS quiz UI N/A by approved scope; shared content decoding will be build-checked by localization validation.

Targeted macOS initial run PASS 4/4 (two new full-M1/order/boundary/session methods plus existing cache/help payload regressions); the normal documented macOS command built the entire UI-test target successfully. Host app logged the pre-existing local persistent-store unknown-model migration diagnostic; all regression stores are in-memory and passed, and no persistent data was reset/deleted. Intentional French xbuild export round trip PASS with catalogue byte-unchanged. Final-source macOS nine-test run and pnpm check:apple-l10n (including generic tvOS/visionOS builds) queued through nohup. New iPhone/iPad M1 tests and unchanged 12 quiz/feedback regression methods queued; no full suites. Additional partial-score web test PASS; import checks, web build/dist URL+CSP audit and links PASS. Pre-existing ExamTools tests/helpers are byte-identical to main. Guard self-test and approved diff PASS with Test-guard-approved: owner decision 2026-10-22.
<!-- SECTION:NOTES:END -->
