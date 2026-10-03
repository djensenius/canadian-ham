---
id: TASK-12.12
title: Make Morse a top-level section
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-03 12:03'
updated_date: '2026-10-03 13:30'
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
- [ ] #1 Morse is a top-level section on every platform: web top navigation (#/morse), iOS/iPadOS tab or sidebar, macOS sidebar, tvOS and visionOS menu entry; the preview toggle and its gating/redirect code are removed, and task-12.10 is closed as obsolete with a note
- [ ] #2 Morse settings (tone, speeds, timing profile, volume, ISED exam preset) live inside the Morse section on web and iOS/iPadOS; existing stored Morse preferences migrate without loss
- [ ] #3 The section has a Morse home that will host Learn (course), Practice (copy) and Exam entries; for now it hosts the existing player, labelled Preview
- [ ] #4 Accessibility audits (axe on web; light and dark Apple audits on iOS, tvOS and visionOS), French UI, and the web and four Apple xbuild suites pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Remove Morse preview-toggle gating and migrate stored preferences without the enabled flag.\n2. Promote Morse to a top-level destination on web and all Apple platforms, with a preview-labelled Morse home, placeholders, and platform-appropriate settings placement.\n3. Update launch-argument handling and UI/unit tests, then validate web and Apple checks before finalizing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Morse as an always-visible top-level destination on web and Apple platforms; removed web/Apple preview-toggle UI and setting gates; moved web/iOS Morse settings into the Morse section; added Morse placeholders and Quick listen; updated tests and localization. Validation so far: web focused tests, pnpm test, web build, apple text-source check, apple l10n, macOS xbuild passed; iOS/tvOS/visionOS xbuild runs timed out before completion after many tests passed.
<!-- SECTION:NOTES:END -->
