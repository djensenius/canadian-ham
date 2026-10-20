---
id: TASK-56
title: >-
  Sync arbitrary compact/split navigation routes across iPhone Duo layout
  changes
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-18 03:22'
updated_date: '2026-10-20 00:05'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect RootView navigation and exam-tool ownership, then introduce a pure typed compact/split route mapping with exhaustive unit coverage.
2. Synchronize deep routes in both directions and lift active exam-tool presentation above the adaptive root switch without changing tool/session reset behavior.
3. Add strict DEBUG size-class transition UI tests for lessons, quizzes and open tools; leave existing transition tests and shared/exception helpers unchanged.
4. Run targeted xbuild checks using nohup scripts on iPhone 17 Pro, iPad Pro 13-inch (M5), iPhone Duo (27.1), and macOS units; record per-test evidence and finalize TASK-56.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Also keep the open exam tool (calculator/hint) presented across size-class transitions; currently it dismisses and must be reopened (value is preserved).

Implementation: compact navigation now uses a typed route array shared with Learn NavigationLinks, with a pure RootNavigationMapping compact/split conversion that preserves module/lesson/section/quiz stacks and practice/mock destinations. Selected calculator/hint is retained in the root-owned session models. Added six mapping/session-state unit tests and eight strict UI tests (both directions for lesson, quiz, calculator and hint). Existing ExamTools tests and shared/exception helpers are byte-identical, verified by reconstructing the pre-insertion source. XcodeGen output was deterministic over two runs. Targeted xbuild validation is queued in /tmp/task-56-initial.sh and /tmp/task-56-macos.sh; waiting on the shared build lock without interruption. No app strings changed.
<!-- SECTION:NOTES:END -->
