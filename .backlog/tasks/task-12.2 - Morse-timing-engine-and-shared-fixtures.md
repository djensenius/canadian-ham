---
id: TASK-12.2
title: Morse timing engine and shared fixtures
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-02 11:56'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-1
parent_task_id: TASK-12
priority: medium
ordinal: 40000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: every Morse feature (audio, drills, exam, sending) depends on exact, testable timing that matches the ISED/RIC-1 rules, the same on web and Apple. See docs/proposals/morse-trainer.md (owner decisions in task-12 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 @canadian-ham/morse-engine (TS) and CanadianHamMorseEngine (SwiftPM) turn text into timed symbols with general Farnsworth timing and the isedParis (12/5, 1.405 s / 3.279 s) and ric1Literal (0.7 s / 1.7 s) profiles; effective speed is clamped to at most the character speed
- [x] #2 The character set is limited to RIC-1 section 8.2; figures and punctuation weigh 2 for word counts
- [x] #3 Shared fixtures in fixtures/morse/ (PARIS 12.0 s isedParis and 7.6 s ric1Literal, the RIC-1 section 8.3 sample = 78 weighted characters, error scoring with 5 errors = pass and 6 = fail, insertions) pass in both languages
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Mirror packages/engine-ts and packages/engine-swift conventions for new Morse packages without wiring them into apps.
2. Add shared fixtures under fixtures/morse/ for timing, word weighting, validation, and grading.
3. Implement TypeScript timing/validation/weighting/grading APIs and tests against the shared fixtures; wire the package into root pnpm test/typecheck.
4. Implement matching SwiftPM library and tests against the same shared fixtures.
5. Update CI only for the new TS package and document Swift local test status because existing CI has no macOS/Swift job.
6. Run requested checks, record evidence, check ACs, finalize task, and commit logical slices.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner override: task-12.2 formally depends on task-1 (v1 release), but the owner asked to start implementation now.

Implemented Morse TS and Swift packages plus shared fixtures. CI has no macOS/Swift job and engine-swift is local-only there, so packages/morse-swift/README.md documents DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test instead of adding a CI step.

Validation evidence:
- pnpm --filter @canadian-ham/morse-engine typecheck passed.
- pnpm --filter @canadian-ham/morse-engine test passed (5 fixture tests).
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test from packages/morse-swift passed (1 XCTest fixture runner, 0 failures).
- pnpm typecheck passed after installing workspace dependencies.
- pnpm test passed (content-tools 95 tests, morse-engine 5 tests, web 83 tests).
- pnpm check:links passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented shared Morse timing and grading engines in TypeScript and SwiftPM, backed by fixtures/morse for PARIS timing, RIC-1 character validation, word weighting, and edit-distance exam scoring. The TypeScript package is included in root pnpm test/typecheck; Swift remains local-only because CI has no macOS/Swift job and the package README documents the DEVELOPER_DIR swift test command. Verified with TS package tests/typecheck, SwiftPM tests, root pnpm typecheck/test, and link checks.
<!-- SECTION:FINAL_SUMMARY:END -->
