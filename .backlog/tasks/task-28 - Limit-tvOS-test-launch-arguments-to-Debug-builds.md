---
id: TASK-28
title: Limit tvOS test launch arguments to Debug builds
status: To Do
assignee: []
created_date: '2026-10-02 03:45'
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
