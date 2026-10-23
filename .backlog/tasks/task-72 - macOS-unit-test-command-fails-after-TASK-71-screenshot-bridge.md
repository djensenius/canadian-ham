---
id: TASK-72
title: macOS unit-test command fails after TASK-71 screenshot bridge
status: Done
assignee: []
created_date: '2026-10-23 14:32'
updated_date: '2026-10-23 14:32'
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
- [x] #1 A cross-platform contrastMeasurementCGImage(from:) bridges NSImage/UIImage; the macOS unit command and the iOS UITestContrastMeasurementTests both pass
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added contrastMeasurementCGImage(from:) (#if os(macOS) NSImage.cgImage(forProposedRect:context:hints:) else UIImage.cgImage) and used it in auditVerifyingMeasuredContrast. macOS documented unit command: 210/210 passed. iOS UITestContrastMeasurementTests on iPhone 17 Pro: 31/31 passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Restored the macOS unit-test command by bridging XCUIScreenshot images on both platforms.
<!-- SECTION:FINAL_SUMMARY:END -->
