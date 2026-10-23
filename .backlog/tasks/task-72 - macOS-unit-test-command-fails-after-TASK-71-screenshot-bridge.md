---
id: TASK-72
title: macOS unit-test command fails after TASK-71 screenshot bridge
status: To Do
assignee: []
created_date: '2026-10-23 14:32'
labels:
  - bug
  - tests
dependencies: []
priority: high
ordinal: 151000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-71 added element.screenshot().image.cgImage in UITestContrastMeasurement.swift. On macOS XCUIScreenshot.image is NSImage, so the documented macOS unit-test command (which still builds the UI test target) fails to compile.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A cross-platform contrastMeasurementCGImage(from:) bridges NSImage/UIImage; the macOS unit command and the iOS UITestContrastMeasurementTests both pass
<!-- AC:END -->
