---
id: TASK-56
title: >-
  Sync arbitrary compact/split navigation routes across iPhone Duo layout
  changes
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-18 03:22'
updated_date: '2026-10-20 01:34'
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
1. Keep the typed compact/split navigation mapping and exhaustive route unit tests.
2. Preserve arbitrary Learn stacks in both directions with explicit sidebar-only stack resets.
3. Add strict DEBUG size-class transition UI tests for Learn lessons and quizzes in both directions; leave all pre-existing tests and shared/exception helpers byte-identical.
4. Per coordinator decision 2026-10-19, revert selected-tool restoration and native-host gating, retaining stable dismiss/reopen/value behavior; track open-tool continuity as low-priority TASK-63 dependent on TASK-54 real-device results.
5. Validate navigation on iPhone 17 Pro, iPad Pro 13-inch (M5), iPhone Duo (27.1), and macOS units, then record evidence and open the PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Also keep the open exam tool (calculator/hint) presented across size-class transitions; currently it dismisses and must be reopened (value is preserved).

Implementation: compact navigation now uses a typed route array shared with Learn NavigationLinks, with a pure RootNavigationMapping compact/split conversion that preserves module/lesson/section/quiz stacks and practice/mock destinations. Selected calculator/hint is retained in the root-owned session models. Added six mapping/session-state unit tests and eight strict UI tests (both directions for lesson, quiz, calculator and hint). Existing ExamTools tests and shared/exception helpers are byte-identical, verified by reconstructing the pre-insertion source. XcodeGen output was deterministic over two runs. Targeted xbuild validation is queued in /tmp/task-56-initial.sh and /tmp/task-56-macos.sh; waiting on the shared build lock without interruption. No app strings changed.

Validation iteration: initial iPhone build exposed two remaining DEBUG category/subsection references to the removed compact enum; fixed. Retry compiled and all six RootNavigationMappingTests passed. The first strict calculator compact-to-split UI test then reproduced a real native inspector/AttributeGraph render loop (app 100% CPU, sample /tmp/task-56-hang.sample). Interrupted only this task-owned xbuild child after confirming its parent script/PID; no other builds interrupted. Added a presentation-host lifecycle gate so a retained tool is presented after the new native host attaches, and disappearing hosts cannot clear its selected state. Strict test assertions are unchanged. Targeted two-direction calculator retry is queued in /tmp/task-56-tool-retry.sh; macOS units and remaining platforms are queued. pnpm typecheck and pnpm test passed (144 content, 21 Morse, 127 calculator, 209 web tests). Test guard self-test and merge-base diff check passed without an approval marker; no guarded changes.

Coordinator decision 2026-10-19: open-tool persistence was an add-on note, not AC1–AC3, and is explicitly descoped from TASK-56 after both immediate restoration and host-readiness gating reproduced a native inspector render loop. Reverted all ExamToolViews/StudyViews changes to the stable main baseline; tools dismiss across root switches but calculator values and hint levels remain preserved for reopening. Removed only the newly added out-of-scope tool-continuation tests; every pre-existing test and helper is unchanged. Created low-priority TASK-63, dependent on TASK-54 real-device results, recording the render-loop evidence and the two unapproved alternatives (two-phase native handoff vs lifting the presenter above RootView). TASK-56 continues with pure navigation mapping, five mapping units, and four strict lesson/quiz transition UI tests.
<!-- SECTION:NOTES:END -->
