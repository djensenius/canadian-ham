---
id: TASK-28
title: Limit tvOS test launch arguments to Debug builds
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-02 03:45'
updated_date: '2026-10-02 04:24'
labels:
  - apple
  - tvos
milestone: m-0
dependencies: []
priority: low
ordinal: 52000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: TVLaunchOptions parses test-only launch arguments (-CanadianHamReduceMotion, -CanadianHamTVEvidenceFocus and the existing ones) in Release builds. They're harmless, but task-25 set the precedent that test-only paths are compiled only into Debug builds.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test-only tvOS launch arguments are parsed only under #if DEBUG, and the UI tests that use them still pass
- [ ] #2 A Release tvOS build plus a string scan shows the argument names are absent from the binary
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Wrap tvOS TVLaunchOptions launch-argument parsing in #if DEBUG and keep Release defaults free of test flag strings.\n2. Run the tvOS UI test path that depends on launch arguments to confirm Debug tests still work.\n3. Build the tvOS app for Release and scan the built binary to prove the test launch-argument names are absent.\n4. Record objective evidence, check accepted criteria, summarize, and mark task-28 Done before starting task-27.
<!-- SECTION:PLAN:END -->
