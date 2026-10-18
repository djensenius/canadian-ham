---
id: TASK-59
title: Generalize the Dynamic Type accessibility label to all secondary buttons
status: To Do
assignee: []
created_date: '2026-10-18 08:37'
labels:
  - apple
  - accessibility
dependencies:
  - TASK-57
ordinal: 134000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Follow-up from the PR #290 review (TASK-57). The Hint button's visible label already scaled; SwiftUI's synthesized accessibility node lacked font metadata, so the Dynamic Type audit flagged it. Other short-titled AccessibleSecondaryButtonLabel buttons (Next, Done, Play, Previous in StudyViews, MorseCourseView, LearnViews) could hit the same finding in some layouts.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 AccessibleSecondaryButtonLabel (or its style) carries an explicit localized Text accessibility label so every secondary button exposes a scalable label, and the per-call-site label added in TASK-57 is removed if redundant
- [ ] #2 testLargestDynamicTypeKeepsHintToolButtonReachable additionally proves the visible Hint text grows (frame height at AX-XXXL greater than at the default size, or a targeted .dynamicType audit)
- [ ] #3 Targeted audits on iPhone 17 Pro, iPad and macOS unit tests pass
<!-- AC:END -->
