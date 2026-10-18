---
id: TASK-60
title: Replace point-width layout thresholds with adaptive SwiftUI layouts
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-18 23:49'
updated_date: '2026-10-18 23:50'
labels:
  - apple
  - layout
dependencies: []
priority: high
ordinal: 137000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner decision 2026-10-18: use modern SwiftUI adaptive layouts instead of hard-coded point widths whenever possible. Targets: the iPhone Duo unfolded layout policy (800/780/600 pt thresholds, hysteresis and the window-size measurement plumbing from #286), the iPad/unfolded sidebar collapse width estimates (320/380/420 pt in RootView), and the calculator help-text height threshold (440 pt in CalculatorToolLayout). Prefer system size classes, native .inspector and NavigationSplitView adaptivity, ViewThatFits, containerRelativeFrame and the Layout protocol. API parameters like inspectorColumnWidth, the macOS window minimum and readable-width caps may stay.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The Duo unfolded layout is driven by system size classes and native inspector/NavigationSplitView adaptivity, with no app-defined point-width thresholds or hysteresis; the window-size measurement plumbing is removed if no longer needed
- [ ] #2 The sidebar collapse for the exam tools uses NavigationSplitView or other adaptive behaviour instead of estimated column widths
- [ ] #3 The calculator layout chooses fitting vs scrolling and help-text visibility via ViewThatFits or another adaptive mechanism instead of point-height thresholds, keeping keys at least 44 pt
- [ ] #4 Behaviour on ordinary iPhones, iPad and Mac is unchanged or improved, verified by targeted UI tests and accessibility audits on iPhone 17 Pro, iPhone Duo, iPad Pro 13-inch and macOS unit tests; no tests are weakened
- [ ] #5 TASK-54 real-device checks are updated for the size-class-based Duo behaviour
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Replace the Duo unfolded policy with size-class-driven decisions: remove window-size thresholds/hysteresis, root geometry measurement, custom environment plumbing, and DEBUG window-size launch hooks; keep the existing forced-regular iPhone landscape sheet behaviour by preserving compact navigation on compact-vertical phones.\n2. Update RootView sidebar collapse to rely on NavigationSplitView column visibility/style plus size class/exam-tool presentation instead of estimated column widths, preserving the iPad narrow regular-width collapse-and-restore tests.\n3. Refactor CalculatorToolView/CalculatorToolLayout so ViewThatFits selects calculator-with-help, calculator-without-help, then scrollable content, while layout metrics keep 44 pt key targets and accessibility-size scrolling.\n4. Replace threshold/window-size unit and UI tests with size-class policy and DEBUG size-class-change coverage, keep state-preservation and hinge-peek coverage, and update TASK-54 notes for size-class-based real-Duo checks.\n5. Run targeted unit/UI tests and backlog finalization commands with per-test evidence before committing/pushing/opening the PR.
<!-- SECTION:PLAN:END -->
