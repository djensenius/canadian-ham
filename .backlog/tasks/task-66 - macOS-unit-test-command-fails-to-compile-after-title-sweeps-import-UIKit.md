---
id: TASK-66
title: macOS unit-test command fails to compile after title sweeps import UIKit
status: Done
assignee: []
created_date: '2026-10-21 22:03'
updated_date: '2026-10-21 22:03'
labels:
  - bug
  - tests
dependencies: []
priority: high
ordinal: 145000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
#325 (TASK-52) added an unconditional import UIKit and UIKit font measurement to CanadianHamPracticeUITests.swift. The documented macOS unit-test command still builds the UI test target for macOS, so it failed to compile before any unit test ran.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The documented macOS unit-test command builds and passes; the iOS UI test target still builds and the four title-sweep tests are unchanged on iOS
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Wrapped import UIKit and the TASK-52 title-sweep tests and helpers (UIFont/UITraitCollection measurement) in #if os(iOS). UI tests only run on iOS. Checks: macOS documented unit command 192/192 pass; iOS build-for-testing on iPhone 17 Pro succeeds; the test guard passes. The sweep tests are byte-identical inside the iOS block.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Restored the macOS unit-test command by compiling the UIKit title sweeps for iOS only.
<!-- SECTION:FINAL_SUMMARY:END -->
