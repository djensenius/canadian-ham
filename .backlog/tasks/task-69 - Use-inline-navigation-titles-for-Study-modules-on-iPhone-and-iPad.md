---
id: TASK-69
title: Use inline navigation titles for Study modules on iPhone and iPad
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-23 02:59'
labels:
  - apple
dependencies: []
references:
  - TASK-55
  - TASK-52
documentation:
  - docs/evidence/task-52/README.md
priority: medium
ordinal: 149000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner-delegated decision 2026-10-22: Study module screens on iOS/iPadOS use inline native navigation titles, like practice sessions (TASK-55). TASK-52 evidence found seven of eight large module titles cut at default size. Keep navigation title text and the full wrapped content header; preserve non-iOS behaviour. This replaces the earlier TASK-52 decision to retain automatic/large Study titles, without removing the native-title accessibility-label/content-header requirements.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Study module navigation titles are inline on iOS/iPadOS with unchanged title text and full wrapped content headers; macOS/tvOS/visionOS behaviour is unchanged.
- [ ] #2 TASK-52 title sweeps still require full native accessibility labels and full wrapped module headers, and refreshed evidence documents inline module frames at EN/FR default and AX-XXXL sizes.
- [ ] #3 All four CanadianHamTitleSweeps cases pass on iPhone 17 Pro; targeted existing Study/module navigation tests and light/dark Learn audits pass on iPhone and iPad, with per-test results recorded and no full suites.
- [ ] #4 Apple text-source/localization checks and test guard pass; changes are committed and pushed without a PR.
<!-- AC:END -->
