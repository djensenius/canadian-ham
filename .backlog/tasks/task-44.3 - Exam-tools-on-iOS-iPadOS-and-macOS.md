---
id: TASK-44.3
title: 'Exam tools on iOS, iPadOS and macOS'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:39'
updated_date: '2026-10-12 15:51'
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
<!-- SECTION:NOTES:END -->
