---
id: TASK-56
title: >-
  Sync arbitrary compact/split navigation routes across iPhone Duo layout
  changes
status: To Do
assignee: []
created_date: '2026-10-18 03:22'
updated_date: '2026-10-19 23:20'
labels:
  - apple
dependencies:
  - TASK-15
priority: high
ordinal: 135000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
PR #286 preserves practice and mock exam session state across simulated Duo fold/unfold and syncs the root selection for routes controlled by RootView. Arbitrary NavigationStack pushes created inside compact Learn still cannot be introspected from SwiftUI NavigationPath, so folding or unfolding from a deep Learn route can still lose the exact lesson/quiz stack.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Starting from a compact Learn lesson or quiz route and unfolding to split keeps the same lesson or quiz visible
- [ ] #2 Starting from a split Learn lesson or quiz route and folding to compact keeps the same lesson or quiz visible
- [ ] #3 UI or unit coverage exercises at least one compact-to-split and one split-to-compact deep Learn route without weakening existing navigation tests
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Also keep the open exam tool (calculator/hint) presented across size-class transitions; currently it dismisses and must be reopened (value is preserved).
<!-- SECTION:NOTES:END -->
