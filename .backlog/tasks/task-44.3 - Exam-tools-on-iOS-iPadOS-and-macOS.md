---
id: TASK-44.3
title: 'Exam tools on iOS, iPadOS and macOS'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:39'
updated_date: '2026-10-12 19:19'
labels:
  - apple
dependencies:
  - TASK-44.1
parent_task_id: TASK-44
priority: medium
ordinal: 96000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apple UI for the calculator and reference sheet in practice and mock exams: iPhone a bottom sheet with medium and large detents and background interaction up through medium, so answers stay tappable; iPad regular width and macOS an inspector side panel; compact width falls back to the sheet; hardware-keyboard input; VoiceOver labels and announced results; Dynamic Type; French. The reference sheet is a zoomable view with an accessible text equivalent. The sheet source is pluggable per the owner's licensing decision.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 With either tool open, the question and answer choices remain visible and operable on iPhone, iPad (portrait, landscape, Split View) and Mac (UI tests assert hittable answers)
- [ ] #2 Full default accessibility audits pass with the tools open in light and dark; the largest text size works
- [ ] #3 The mock exam timer is unaffected
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add an iOS/macOS-only exam-tools model and UI that links CanadianHamCalculatorEngine, handles calculator keys/hardware keyboard, result announcements, and pluggable bundled reference-sheet loading with unavailable fallback.\n2. Integrate non-modal tools into practice and mock exams using the approved compact sheet and regular/mac inspector layout while clearing calculator state when a new practice/mock exam starts.\n3. Add localization entries with the required Python string-catalog round trip and add unit/UI coverage in a new UI-test file for tools, audits, Dynamic Type, precise scrolling, protected areas, and mock timer continuity.\n4. Regenerate the Xcode project twice after project.yml target/package changes, run the Apple l10n/text checks plus targeted iOS/iPad/macOS test commands, update task notes/ACs/final summary, and commit.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Coordinator: renders the shared reference sheet from content/reference-sheet/ (created by 44.2); use a test fixture until 44.2 merges.

WIP handoff after first implementation slice: committed and pushed be37f05f on branch task-44.3-apple-exam-tools. Done: added CanadianHamCalculatorEngine to CanadianHam and CanadianHamTests only (not tvOS/visionOS), added ExamToolModels/ExamToolViews, wired practice/mock exam tool buttons, compact sheet/regular inspector presentation, calculator keyboard shortcuts/VoiceOver labels/result accessibility value, pluggable ReferenceSheetConfiguration loader with unavailable fallback, unit tests, a new CanadianHamExamToolsUITests file, Localizable.xcstrings keys via Python JSON round trip, and regenerated XcodeGen twice with project.pbxproj checksum stable on the second run. Verified: git diff --check passed; node scripts/check-apple-text-sources.ts passed; XcodeGen second run kept project.pbxproj unchanged; iOS targeted unit command DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamTests/ExamCalculatorViewModelTests test CODE_SIGNING_ALLOWED=NO passed 4 tests. Failing/partial: pnpm check:apple-l10n passed text-source checks but timed out after 20 min waiting on xbuild lock; full task UI suite is not passing yet. Latest targeted UI run for testPracticeCalculatorSheetKeepsAnswersHittableAtMediumDetent failed because answer-A-button exists at y=154 but is not hittable while the sheet is open; earlier full new UI file run had 8 failures including text-clipped accessibility audits, largest Dynamic Type reciprocal key reachability, mock timer/tool answer hittability, reference unavailable lookup (later improved to static text), preciseScroll, and regular-width inspector hittability. Subsequent fixes improved Dynamic Type key reachability and reference unavailable text lookup, but answer hittability with sheet remains unresolved. Next steps: merge origin/main so content/reference-sheet/basic.md from 44.2 is available, replace/remove the temporary unit-test fixture as appropriate, fix compact sheet answer operability (likely sheet detent/initial detent/background scroll positioning and XCTest gesture strategy), then rerun targeted iOS UI methods, iPad inspector targeted run, macOS unit command, pnpm check:apple-l10n, and node scripts/check-apple-text-sources.ts before finalization.

WIP update after main merge and follow-up commits: branch now includes origin/main with content/reference-sheet/basic.md and uses that real file in the unit-test bundle instead of the temporary fixture. Added medium detent selection for compact sheets, delayed answer-anchor scrolling when a tool opens, and adjusted UI tests to expect the real bundled reference sheet. Pushed commits 6cc05748, cfd4fc96, and 00619b8c. Verified after these changes: git diff --check passed; node scripts/check-apple-text-sources.ts passed; targeted iOS unit command for CanadianHamTests/ExamCalculatorViewModelTests passed 4 tests after fixing the straight-apostrophe reference-sheet assertion. Still not complete: targeted iOS UI rerun for the practice calculator/reference sheet methods could not start before timeout because another full iOS xbuild (pid 97258/97259, xcodebuild 97261) holds the serialized build lock; do not kill it. Previous UI failure before the latest delayed-scroll adjustment was answer-A-button existing but not hittable with the compact sheet open. Next steps: once the xbuild lock clears, rerun the targeted iOS UI methods in CanadianHamExamToolsUITests, then the new UI class/light-dark audits, an iPad inspector targeted run, macOS unit command, pnpm check:apple-l10n, and resolve any remaining UI/audit failures before checking ACs or marking Done.
<!-- SECTION:NOTES:END -->
