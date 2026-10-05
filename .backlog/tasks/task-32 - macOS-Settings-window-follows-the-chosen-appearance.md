---
id: TASK-32
title: macOS Settings window follows the chosen appearance
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-03 23:33'
updated_date: '2026-10-05 00:01'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the macOS Settings scene, appearance preference storage, and existing tests.\n2. Apply the stored appearance preference to NativeSettingsView/Settings scene using the same mapping as main windows without changing shared platform behavior.\n3. Add a focused macOS unit check for live appearance preference propagation.\n4. Run targeted macOS testing while iterating, then one full macOS suite per apps/apple/project.yml; record per-test names/results in notes before finalizing.
<!-- SECTION:PLAN:END -->
