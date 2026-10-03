---
id: TASK-12.12
title: Make Morse a top-level section
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-03 12:03'
updated_date: '2026-10-03 15:21'
labels:
  - web
  - apple
  - morse
  - accessibility
milestone: m-1
dependencies:
  - TASK-12.3
parent_task_id: TASK-12
priority: high
ordinal: 58000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner tried the preview and doesn't want Morse buried behind a Settings toggle (2026-10-02 decision in task-12). Morse becomes its own always-visible section, with its settings inside the section (web, iOS/iPadOS) or in native Settings on macOS (task-30). A small 'Preview' label stays until the course (task-12.5) and copy practice/exam (task-12.6) land.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Morse is a top-level section on every platform: web top navigation (#/morse), iOS/iPadOS tab or sidebar, macOS sidebar, tvOS and visionOS menu entry; the preview toggle and its gating/redirect code are removed, and task-12.10 is closed as obsolete with a note
- [x] #2 Morse settings (tone, speeds, timing profile, volume, ISED exam preset) live inside the Morse section on web and iOS/iPadOS; existing stored Morse preferences migrate without loss
- [x] #3 The section has a Morse home that will host Learn (course), Practice (copy) and Exam entries; for now it hosts the existing player, labelled Preview
- [x] #4 Accessibility audits (axe on web; light and dark Apple audits on iOS, tvOS and visionOS), French UI, and the web and four Apple xbuild suites pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Remove Morse preview-toggle gating and migrate stored preferences without the enabled flag.\n2. Promote Morse to a top-level destination on web and all Apple platforms, with a preview-labelled Morse home, placeholders, and platform-appropriate settings placement.\n3. Update launch-argument handling and UI/unit tests, then validate web and Apple checks before finalizing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Morse as an always-visible top-level destination on web and Apple platforms; removed web/Apple preview-toggle UI and setting gates; moved web/iOS Morse settings into the Morse section; added Morse placeholders and Quick listen; updated tests and localization. Validation so far: web focused tests, pnpm test, web build, apple text-source check, apple l10n, macOS xbuild passed; iOS/tvOS/visionOS xbuild runs timed out before completion after many tests passed.

Validation gap: full iOS xbuild suite was rerun after fixing home-action clipping, but it timed out at 1200s while still executing UI tests; earlier failing clipping audits were fixed and the Morse UI test passed. tvOS and visionOS xbuild suites also timed out during UI tests after unit tests and several UI tests passed. AC4 remains unchecked pending full platform suite completion.

Final validation (2026-10-03): compact iPhone now exposes Morse from top-level navigation via the `compact-top-level-morse` toolbar button; `CanadianHamPracticeUITests.testCompactTopLevelNavigationExposesMorse` passed in the full iOS suite. Platform xbuild results: iOS `CanadianHam` on iPhone 17 Pro passed (`CanadianHamTests`: 30 tests, 0 failures; `CanadianHamUITests`: 30 tests, 0 failures; log `/tmp/task-12.12-ios-final.log`). tvOS `CanadianHamTV` on Apple TV 4K (3rd generation) passed (`CanadianHamTVTests`: 3 tests, 0 failures; `CanadianHamTVUITests`: 11 tests, 0 failures; log `/tmp/task-12.12-tvos.log`). visionOS `CanadianHamVision` on Apple Vision Pro passed (`CanadianHamVisionTests`: 3 tests, 0 failures; `CanadianHamVisionUITests`: 8 tests, 0 failures; log `/tmp/task-12.12-visionos.log`). Prior branch validation already recorded web focused tests, pnpm test, web build, text-source/l10n checks, and macOS xbuild passing.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Morse is now always visible as a top-level section across web and Apple platforms, preview gating/toggles are removed, Morse home/settings are in-section where required, macOS uses the native Settings work from task-30, and task-12.10 is closed obsolete. Verified by prior web/mac validation plus full iOS, tvOS, and visionOS xbuild suites passing on 2026-10-03.
<!-- SECTION:FINAL_SUMMARY:END -->
