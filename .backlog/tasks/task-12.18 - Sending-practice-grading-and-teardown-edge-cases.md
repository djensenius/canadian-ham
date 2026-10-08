---
id: TASK-12.18
title: 'Sending practice: grading and teardown edge cases'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-06 11:55'
updated_date: '2026-10-08 13:26'
labels: []
dependencies:
  - TASK-12.7
parent_task_id: TASK-12
priority: low
ordinal: 68000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: Copilot's last PR #144 (task-12.7) review listed four smaller items in unchanged code. Apple doesn't cancel a pending character finalisation when leaving the sending screen. On both platforms, grading at the deadline or by hand doesn't first finish a key that is still held, so the held element is left out and a held paddle keeps sounding. The Apple diff summary's French plural follows only the total count ('1 erronées').
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Leaving the Apple sending screen cancels and clears the pending character finalisation
- [ ] #2 Web and Apple grading first releases all keys (finishing a held straight-key element) and stops playback, with tests
- [ ] #3 The Apple Morse diff summary agrees in French for each count (plural per component, or count-invariant labels), with a LocalizationCatalogTests assertion
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the sending teardown/grading and Morse diff-summary localization paths.\n2. Ensure pending finalization is cancelled/cleared when leaving sending, and grading releases held keys/stops playback before scoring on Apple and web.\n3. Fix French diff-summary agreement and add targeted tests for sending grading and localization evidence.\n4. Run focused tests, record file:line validation evidence, check ACs, summarize, and mark Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented sending teardown/grading changes: apps/apple/CanadianHam/Morse/Sending/MorseSendingPracticeView.swift:161 clears pending finalization on disappear; :380-383 releases held keys before scoring; :427-432 cancels/clears pending samples. Web grading now releases held keys before scoring at apps/web/src/morse/sending/MorseSendingPracticeSection.tsx:448-452 with coverage in apps/web/src/morse/sending/MorseSendingPracticeSection.test.tsx:215-228. French diff summary uses count-invariant labels in apps/apple/CanadianHam/Resources/Localizable.xcstrings:2150-2188 with assertion in apps/apple/CanadianHamTests/LocalizationCatalogTests.swift:55-59. Validation so far: pnpm --dir apps/web test src/morse/sending/MorseSendingPracticeSection.test.tsx passed (13 tests); prior targeted iOS xbuild passed LocalizationCatalogTests/testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries and CanadianHamPracticeUITests/testMorseSendingPracticeGradesHeldStraightKeyBeforeScoring. Added pending-finalization UI test at apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:370-383; rerun was queued behind the xbuild lock for >1h, so I cancelled only my queued wrapper and will rerun Apple checks after final code.
<!-- SECTION:NOTES:END -->
