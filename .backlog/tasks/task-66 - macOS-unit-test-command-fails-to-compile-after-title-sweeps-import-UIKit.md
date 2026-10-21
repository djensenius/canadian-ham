---
id: TASK-66
title: macOS unit-test command fails to compile after title sweeps import UIKit
status: To Do
assignee: []
created_date: '2026-10-21 22:03'
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
- [ ] #1 The documented macOS unit-test command builds and passes; the iOS UI test target still builds and the four title-sweep tests are unchanged on iOS
<!-- AC:END -->
