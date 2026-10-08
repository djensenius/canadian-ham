---
id: TASK-12.20
title: 'Morse visual output: follow-ups from the task-12.4 review'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-07 12:14'
updated_date: '2026-10-08 13:34'
labels: []
dependencies:
  - TASK-12.4
parent_task_id: TASK-12
priority: low
ordinal: 70000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: task-12.4's final review (~/.cache/canadian-ham-reviews/t124-r3.md) approved with notes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 After the UI-test scroll-settling helper runs, each lower-half audit asserts its target (sending feedback, Morse settings, last course unit) is still visible below the bar
- [ ] #2 Remove the unreachable luminance-too-high reason (TS and Swift) or document it; add a Swift test at exactly the area cap
- [ ] #3 Safety-note areas say square points / px² with grouped digits; the web unlit lamp sits on paper (not paper-inset) like Apple
- [ ] #4 Apple: turning on Reduce Motion or Dim Flashing Lights during beacon playback stops the beacon (or switches to tape) in all four playback owners
- [ ] #5 The UI-test scroll-settling helper fails (XCTFail) if the scroll view is missing instead of returning silently
- [ ] #6 Apple export/import includes the Morse settings (including outputMode) with a round-trip test, matching web
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the shared UI-test scroll-settling helpers, Morse visual playback planning, settings export/import, and playback-owner reduce-motion hooks.\n2. Keep the scroll-settling helper strict, add post-settle visibility assertions and missing-scroll-view XCTFail behaviour.\n3. Remove/document the unreachable luminance reason with an exact area-cap Swift test; update safety-note wording and web unlit lamp styling.\n4. Stop or switch running visual beacons when Reduce Motion/Dim Flashing Lights changes in all four playback owners.\n5. Include Morse settings in Apple export/import matching web replace-all semantics, with a round-trip test.\n6. Run focused tests and record file:line evidence before finalization.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented visual-output follow-ups: post-settle UI audit assertions now cover sending feedback, Morse settings, and final course unit at apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift:1337-1338,:1543-1546,:1551-1554, and scrollUntilPartiallyVisible now XCTFails when no scroll view exists at :2063-2068. Safety-note formatting now uses grouped square points at apps/apple/CanadianHam/Morse/MorseTrainerView.swift:86-104 and web uses px² with the unlit lamp on paper at apps/web/src/lib/i18n.ts:421,:864 and apps/web/src/styles.css:1018-1025. Removed unreachable luminance-too-high from packages/morse-engine/src/morse.ts:72-75 and packages/morse-swift/Sources/CanadianHamMorseEngine/Morse.swift:137-144; exact area-cap Swift coverage is packages/morse-swift/Tests/CanadianHamMorseEngineTests/MorseFixtureTests.swift:178-184. Reduce Motion/Dim Flashing Lights beacon stops route through apps/apple/CanadianHam/Morse/MorseTrainerView.swift:367-402, CopyExam/MorseCopyExamView.swift:234-330 and :491-596, and Course/MorseCourseView.swift:41-45,:498-504. Apple export/import now carries preferences.morse in apps/apple/CanadianHam/Services/ProgressStore.swift:119-138,:619-640 and UI import/export applies it in StudyViews.swift:1621-1655 plus NativeSettingsView.swift:263-305, with round-trip coverage in apps/apple/CanadianHamTests/ProgressStoreTests.swift. Validation passed: pnpm --dir apps/web test src/App.test.tsx src/lib/morseSettings.test.ts (76 tests); pnpm --dir packages/morse-engine test (21 tests); DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test in packages/morse-swift (4 XCTest tests). A plain swift test without DEVELOPER_DIR failed because xcode-select points at CommandLineTools and XCTest was unavailable.
<!-- SECTION:NOTES:END -->
