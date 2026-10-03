---
id: TASK-32
title: macOS Settings window follows the chosen appearance
status: To Do
assignee: []
created_date: '2026-10-03 23:33'
labels:
  - apple
  - macos
milestone: m-0
dependencies:
  - TASK-30
priority: low
ordinal: 60000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: Copilot's final PR #121 review noted the native macOS Settings window doesn't apply the app's selected appearance (light/dark/system) the way the main windows do, so it can look mismatched.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The Settings scene applies the stored appearance preference live, matching the main windows
- [ ] #2 A macOS unit or UI check covers it; the macOS suite passes
<!-- AC:END -->
