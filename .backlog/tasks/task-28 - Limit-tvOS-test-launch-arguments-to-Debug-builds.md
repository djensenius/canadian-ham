---
id: TASK-28
title: Limit tvOS test launch arguments to Debug builds
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-02 03:45'
updated_date: '2026-10-02 04:48'
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
- [x] #1 Test-only tvOS launch arguments are parsed only under #if DEBUG, and the UI tests that use them still pass
- [x] #2 A Release tvOS build plus a string scan shows the argument names are absent from the binary
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Wrap tvOS TVLaunchOptions launch-argument parsing in #if DEBUG and keep Release defaults free of test flag strings.
2. Run the tvOS UI test path that depends on launch arguments to confirm Debug tests still work.
3. Build the tvOS app for Release and scan the built binary to prove the test launch-argument names are absent.
4. Record objective evidence, check accepted criteria, summarize, and mark task-28 Done before starting task-27.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented #if DEBUG launch-argument parsing in TVLaunchOptions; Release builds now use fixed defaults. Validation: xbuild tvOS UI test CanadianHamTVUITests/testFocusRingEvidenceScreenshots passed, exercising -CanadianHamTVEvidenceFocus, -CanadianHamReduceMotion, -CanadianHamLanguage, answered state, appearance, screen, category and question launch arguments. Release validation: xbuild Release tvOS Simulator build passed at /tmp/canadian-ham-task-28-release, and strings scan of CanadianHamTV binary reported all launch-argument names absent.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Wrapped tvOS test-only launch-argument parsing in #if DEBUG while keeping Debug UI tests working. Verified with the focused tvOS UI test and a Release tvOS Simulator build plus binary strings scan showing the argument names absent.
<!-- SECTION:FINAL_SUMMARY:END -->
