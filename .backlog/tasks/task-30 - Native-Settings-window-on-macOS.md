---
id: TASK-30
title: Native Settings window on macOS
status: To Do
assignee: []
created_date: '2026-10-03 12:03'
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
