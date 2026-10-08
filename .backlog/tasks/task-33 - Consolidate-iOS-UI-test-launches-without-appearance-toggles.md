---
id: TASK-33
title: Consolidate iOS UI test launches without appearance toggles
status: To Do
assignee: []
created_date: '2026-10-08 04:35'
labels:
  - apple
  - testing
  - ci
dependencies:
  - TASK-31
ordinal: 71000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Task-31 attempted to combine iOS light/dark accessibility audits into one launch, but the iOS simulator SpringBoard crashed while snapshotting after in-test appearance changes. The safe remaining work is to find launch-sharing opportunities that stay within a single appearance per test.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 iOS UI audits share launches within one appearance where safe; no test switches XCUIDevice.shared.appearance after launch.
- [ ] #2 Before/after iOS UI test count and wall-clock timing are recorded in task notes.
- [ ] #3 Before/after audit inventory diff shows no loss of screen/state/appearance/region coverage.
- [ ] #4 Full iOS suite passes after consolidation.
<!-- AC:END -->
