---
id: TASK-63
title: Keep the open exam tool presented across size-class changes
status: To Do
assignee: []
created_date: '2026-10-20 01:34'
labels:
  - apple
dependencies:
  - TASK-54
priority: low
ordinal: 138000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Follow-up to TASK-56, deferred by coordinator decision 2026-10-19 until TASK-54 real-device Duo results. The current stable app dismisses an open calculator or hint during compact/split root changes but preserves its value/revealed levels for reopening.

The TASK-56 experiment retained selected tools in root-owned session models and immediately restored them on the new host. Compact-to-split on iPhone 17 Pro reproduced a native SwiftUI inspector/AttributeGraph render loop (100% app CPU). Waiting until the replacement host appeared, with a cancellation-checked Task.yield readiness gate, did not resolve it. Experiment commits 29d7c729599a4f1ea687579328157cf2493aaaf8 and c828827eb21100df4b5478889e9ba9c72215726d; local logs /tmp/task-56-iphone-r2.log and /tmp/task-56-tool-retry.log, sample /tmp/task-56-hang.sample. Tool changes were reverted before shipping TASK-56.

Approaches to assess after real hardware evidence: (1) a two-phase native presentation handoff that dismisses the old tool, retains desired selection/value, and switches roots/re-presents only after actual panel disappearance; (2) lifting the presenter and its calculator/hint context above RootView’s adaptive branch. Neither approach is approved for implementation yet. Avoid fixed delays, width thresholds, or weakening navigation/tool/audit tests.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Use TASK-54 real-device findings to document the actual fold/unfold presentation behavior and approve a restoration approach before implementation
- [ ] #2 An open calculator or hint continues across compact-to-split and split-to-compact changes without a native render loop, preserving calculator value and revealed hint levels
- [ ] #3 Strict transition coverage does not reopen a missing tool and leaves existing navigation, accessibility and exception helpers unchanged
<!-- AC:END -->
