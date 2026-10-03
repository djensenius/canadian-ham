---
id: TASK-30
title: Native Settings window on macOS
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-03 12:03'
updated_date: '2026-10-03 13:30'
labels:
  - apple
  - macos
  - accessibility
milestone: m-0
dependencies:
  - TASK-12.3
priority: medium
ordinal: 59000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner wants the Mac app to feel native: app settings belong in the standard Settings window (app menu → Settings…, Command-comma), not an in-app page. iPhone and iPad keep their in-app Settings.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 macOS uses a SwiftUI Settings scene (Command-comma) with tabs for General (language, appearance), Data (export, import, reset) and Morse (all Morse settings); the in-app Settings page/sidebar entry is removed on macOS only
- [ ] #2 All settings behave identically to iOS (same storage, live updates to open windows), with keyboard navigation and VoiceOver labels; Full Keyboard Access works
- [ ] #3 macOS unit tests cover the shared settings model; iOS/iPadOS in-app Settings is unchanged and its UI tests pass; the macOS and iOS xbuild suites pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a macOS SwiftUI Settings scene wired to shared progress and Morse settings models.\n2. Move macOS settings out of the in-app sidebar while keeping iPhone/iPad in-app settings.\n3. Add model coverage and run macOS/iOS validation.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented a native macOS Settings scene with General, Data, and Morse tabs backed by the shared ProgressStoreService and MorseTrainerSettings state; removed the macOS in-app Settings sidebar entry.
<!-- SECTION:NOTES:END -->
