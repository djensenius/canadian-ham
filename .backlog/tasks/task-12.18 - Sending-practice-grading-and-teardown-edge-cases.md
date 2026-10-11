---
id: TASK-12.18
title: 'Sending practice: grading and teardown edge cases'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-06 11:55'
updated_date: '2026-10-11 10:23'
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
- [x] #1 Leaving the Apple sending screen cancels and clears the pending character finalisation
- [x] #2 Web and Apple grading first releases all keys (finishing a held straight-key element) and stops playback, with tests
- [x] #3 The Apple Morse diff summary agrees in French for each count (plural per component, or count-invariant labels), with a LocalizationCatalogTests assertion
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the sending teardown/grading and Morse diff-summary localization paths.\n2. Ensure pending finalization is cancelled/cleared when leaving sending, and grading releases held keys/stops playback before scoring on Apple and web.\n3. Fix French diff-summary agreement and add targeted tests for sending grading and localization evidence.\n4. Run focused tests, record file:line validation evidence, check ACs, summarize, and mark Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented sending teardown/grading changes: apps/apple/CanadianHam/Morse/Sending/MorseSendingPracticeView.swift:161 clears pending finalization on disappear; :380-383 releases held keys before scoring; :427-432 cancels/clears pending samples. Web grading now releases held keys before scoring at apps/web/src/morse/sending/MorseSendingPracticeSection.tsx:448-452 with coverage in apps/web/src/morse/sending/MorseSendingPracticeSection.test.tsx:215-228. French diff summary uses count-invariant labels in apps/apple/CanadianHam/Resources/Localizable.xcstrings:2150-2188 with assertion in apps/apple/CanadianHamTests/LocalizationCatalogTests.swift:55-59. Validation so far: pnpm --dir apps/web test src/morse/sending/MorseSendingPracticeSection.test.tsx passed (13 tests); prior targeted iOS xbuild passed LocalizationCatalogTests/testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries and CanadianHamPracticeUITests/testMorseSendingPracticeGradesHeldStraightKeyBeforeScoring. Added pending-finalization UI test at apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:370-383; rerun was queued behind the xbuild lock for >1h, so I cancelled only my queued wrapper and will rerun Apple checks after final code.

Final validation passed on tip 6b892eaafeae1c5a29da15f01cdb7da6d860e962: visibility targeted iOS pass repeated twice (3/3 tests each); full iOS pass 139/139 test cases including CanadianHamPracticeUITests/testMorseSendingPracticeClearsPendingCharacterWhenLeaving, /testMorseSendingPracticeGradesHeldStraightKeyBeforeScoring, /testMorseSendingPracticeGradesImmediatelyAtDeadline, and LocalizationCatalogTests/testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries. Web sending validation passed earlier with pnpm --dir apps/web test src/morse/sending/MorseSendingPracticeSection.test.tsx (13/13). Additional final checks passed: pnpm typecheck; pnpm test (web/package suite 269 total tests across content-tools/morse-engine/web); pnpm build:web; node scripts/check-apple-text-sources.ts; pnpm check:apple-l10n after final string changes. Full Apple suites passed: macOS 67/67, tvOS 15/15, visionOS 12/12. Note: an earlier full iOS run failed because task-12.20 post-settle assertions required full visibility; fixed to partial visibility and reran the requested targeted tests twice before final full suites.

Review r2 follow-up on tip 6eeda354c240e6c3661ec2a13b9adcb3e29298af: removed the unused DEBUG "Hold straight key for sending test" button and beginHeldStraightKeyForUITest helper; the remaining held-key coverage uses the real grading hook in CanadianHamPracticeUITests/testMorseSendingPracticeGradesHeldStraightKeyBeforeScoring and still asserts 0 errors. Added Back-from-running-exam cancellation: MorseSendingPracticeView now clears a running/stale exam when the pushed Exam-style check is popped and opens the exam screen from a fresh sending state. Verified by DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testMorseSendingPracticeBackFromRunningExamStopsDeadlineGrading -resultBundlePath /tmp/morse-polish-r2-back2.xcresult test CODE_SIGNING_ALLOWED=NO (1/1 passed). Related targeted sending tests passed in /tmp/morse-polish-r2-other2.xcresult: testMorseSendingPracticeClearsPendingCharacterWhenLeaving, testMorseSendingPracticeGradesHeldStraightKeyBeforeScoring, testMorseSendingPracticeGradesImmediatelyAtDeadline, and testMorseSendingPracticeUsesDebugHookAndPushesResultsScreen (part of 7/7 run). Per coordinator policy update, full four-platform suites were not rerun in this review round.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Addressed r2 sending-practice follow-ups: removed the unused held-key DEBUG button/helper and added Back-from-running-exam cancellation for the pushed Exam-style check. Verified with targeted iOS UI tests: Back cancellation 1/1 passed and related sending tests passed in the 7/7 targeted run.
<!-- SECTION:FINAL_SUMMARY:END -->
