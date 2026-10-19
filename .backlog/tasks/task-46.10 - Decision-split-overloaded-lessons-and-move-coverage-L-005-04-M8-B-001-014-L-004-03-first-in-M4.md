---
id: TASK-46.10
title: >-
  Split overloaded lessons and move coverage (L-005-04, M8, B-001-014, L-004-03
  first in M4)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:58'
updated_date: '2026-10-19 20:56'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
priority: medium
ordinal: 108000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Needs an owner decision; see docs/lesson-review/README.md. Once decided, add the implementation plan and acceptance criteria, or close as declined.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Owner decision recorded
- [ ] #2 Splits and moves done with coverage, quizzes, explanations, figures and links updated; saved lesson progress migrates on web and Apple
- [ ] #3 L-005-04 and M8 are split into smaller lessons, B-001-014 moves to L-001-05, and L-004-03 comes first in M4
- [ ] #4 Lesson coverage shows every question still covered exactly as intended, and all content checks pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the current lesson/review files, existing lesson IDs, quizzes, explanations, hints, figures, links, and progress-storage code paths.\n2. Restructure the affected lessons mechanically: split L-005-04 into AC/dB and reactance/resonance lessons, split M8 receiver/transmitter lessons, move B-001-014 coverage into L-001-05, and reorder M4 so L-004-03 is taught first.\n3. Update dependent content metadata and references: quizzes, explanations lesson links, hint lessonLink anchors, figure directives, cross-links, schemas, and tests that name changed lesson IDs/titles.\n4. Add explicit old-to-new lesson ID migration for web and Apple progress/quiz references, including import/load tests and documented split behavior.\n5. Run the requested content, web, and targeted Apple checks; record evidence, finalize the Backlog task, commit, push, and open the PR with migration notes.

6. Finish the inherited test decoder helper and add only the two version-validation localizations, verifying the catalogue preserves origin/main entries and key order. Run full macOS units, the eight affected iOS Learn/figure tests, and requested web/content checks; record per-test evidence before finalization and PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision 2026-10-12: YES. Split L-005-04 (AC and dB vs reactance and resonance), split M8 (receiver-side vs transmitter-side), move B-001-014 to L-001-05, teach L-004-03 first in M4. Lesson IDs may change; migrate saved progress and quiz references. Start after the 38.x figure branches merge.

Owner decision 2026-10-12: yes, do it, including migrating saved lesson progress for moved or split lessons.

Resumed finalization: committed test-local archived-array decoder helper (8d31d867; assertions unchanged) and exactly two sorted version-validation localizations (b67bfb39). Python verified origin/main catalogue entries and order unchanged and exact OrderedDict round-trip formatting. Final macOS full units, eight affected iPhone Learn/figure tests, localization no-rewrite gate, and all requested web/content checks queued via nohup in /tmp/task-46.10-{apple3,web-content3}.sh. The initial foreground localization attempt timed out while waiting for the shared lock, with catalogue hash unchanged; queued retry uses nohup.

Coordinator-approved parity fix: web split-quiz migration now matches Apple by skipping a destination with no answered official questions unless it is the original quiz. Added regression covering top-level and legacy sync-row migration; it failed before the one-line fix and all 29 ProgressStore tests passed afterward (pnpm --dir apps/web exec vitest run src/lib/progressStore.test.ts). Existing assertions were not weakened.

Full macOS run: 180 tests executed; 179 passed and existing testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates failed nine assertions because migration merged/sorted invalid raw rows before validation. Coordinator approved fixing both import paths: raw rows now validate before any migration, including exact historical quiz membership from source commit 350a3b53658c64f12e89c0b48d6b97c7c3040e88; migrated rows then validate against current membership. Imports reject invalid data before writing. Existing validation assertions are unchanged and now also assert import rejection. New Apple/web tests cover invalid scores and historical top-level/sync quiz membership, including removed legacy concept C3. Corrected only the legacy L-005-05 mixed-row fixture from B-005-009-003 to historically correct B-005-012-001; v2 fixture and all migration assertions preserved. Historical membership tables were independently checked against source via Python; web ProgressStore 31 tests pass. macOS ProgressStore class rerun queued via nohup; initial typecheck caught missing test DB names, fixed, and retry passes.

macOS fix validation passed via xbuild: entire ProgressStoreTests class, 93 tests / zero failures, including unchanged testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates and the two new raw-validation regressions. Initial full run covered the other 89 unit tests successfully (180 total before adding two tests); combined final evidence covers 182 distinct passing tests. Full-run/fix-rerun per-test table prepared at /tmp/task-46.10-macos-per-test.md for the PR and task notes. Latest pnpm test passes 217 web + 21 Morse Vitest tests; typecheck, build and URL/CSP audit pass. iOS and localization checks remain queued.

Tightened historical validation tables from subsection prefixes to the exact sampled officialQuestionIds: the old quizzes selected questions, not whole subsections. Both tables now match all source official-question and concept IDs exactly (Python set comparison against commit 350a3b53658c64f12e89c0b48d6b97c7c3040e88). Verified every old official ID occurs in a current destination. Strengthened the historical-membership regression on Apple/web to reject same-subsection B-005-009-001, which was never in the old quiz, for both top-level and sync rows. Web ProgressStore 31 tests pass; latest targeted Apple historical-membership method is queued via nohup. No assertions removed.
<!-- SECTION:NOTES:END -->
