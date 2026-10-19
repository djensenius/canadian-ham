---
id: TASK-60
title: Replace point-width layout thresholds with adaptive SwiftUI layouts
status: Done
assignee:
  - '@worker'
created_date: '2026-10-18 23:49'
updated_date: '2026-10-19 20:53'
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
- [x] #1 The Duo unfolded layout is driven by system size classes and native inspector/NavigationSplitView adaptivity, with no app-defined point-width thresholds or hysteresis; the window-size measurement plumbing is removed if no longer needed
- [x] #2 The sidebar collapse for the exam tools uses NavigationSplitView or other adaptive behaviour instead of estimated column widths
- [x] #3 The calculator layout chooses fitting vs scrolling and help-text visibility via ViewThatFits or another adaptive mechanism instead of point-height thresholds, keeping keys at least 44 pt
- [x] #4 Behaviour on ordinary iPhones, iPad and Mac is unchanged or improved, verified by targeted UI tests and accessibility audits on iPhone 17 Pro, iPhone Duo, iPad Pro 13-inch and macOS unit tests; no tests are weakened
- [x] #5 TASK-54 real-device checks are updated for the size-class-based Duo behaviour
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Replace the Duo unfolded policy with size-class-driven decisions: remove window-size thresholds/hysteresis, root geometry measurement, custom environment plumbing, and DEBUG window-size launch hooks; keep the existing forced-regular iPhone landscape sheet behaviour by preserving compact navigation on compact-vertical phones.\n2. Update RootView sidebar collapse to rely on NavigationSplitView column visibility/style plus size class/exam-tool presentation instead of estimated column widths, preserving the iPad narrow regular-width collapse-and-restore tests.\n3. Refactor CalculatorToolView/CalculatorToolLayout so ViewThatFits selects calculator-with-help, calculator-without-help, then scrollable content, while layout metrics keep 44 pt key targets and accessibility-size scrolling.\n4. Replace threshold/window-size unit and UI tests with size-class policy and DEBUG size-class-change coverage, keep state-preservation and hinge-peek coverage, and update TASK-54 notes for size-class-based real-Duo checks.\n5. Run targeted unit/UI tests and backlog finalization commands with per-test evidence before committing/pushing/opening the PR.

Regression follow-up: reproduce 2–3 iPad exam-tool presentation failures; replace runtime split-style changes with stable native column visibility and restore the user sidebar state; run full iPad ExamTools, targeted iPhone inspector/transitions, and macOS units; record results and update PR #301.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Coordinator completion 2026-10-19 (head 6fb5d9cc): no point-width thresholds remain (grep for unfoldedIPhoneMinimum*/ExitWidth/estimatedSidebarWidth/minimumExamColumnWidth/compactHelpVisibilityHeight/SimulatedWindowSize/isPortrait in app code returns nothing). Duo policy = phone + regular horizontal + non-compact vertical size class; iPad sidebar uses NavigationSplitView .automatic while a tool is open (orientation helper removed); calculator uses ViewThatFits fitting/without-help/scroll, with explicit scroll on compact sheets and phone inspectors, keys at the 46 pt floor (56 pt reverted). Final validation (/tmp/task-60-final3.out HANDOFF4, all exit 0):
- iPhone 17 Pro targeted ExamTools regression set (large-detent calculator audit, both size-class transitions, landscape medium-sheet keys) passed.
- iPhone Duo landscape medium-sheet calculator passed.
- iPad Pro 13 sidebar/inspector passed.
- macOS calculator-layout units passed; text-source check passed.
Earlier full-class runs: iPhone 17 Pro matrix + practice audits + Learn passed; iPad full class only the TASK-61 hinge flake; Duo full class only the known TASK-54 items + TASK-61 flake; Pro Max landscape calculator = TASK-58 (pre-existing on main). TASK-54 updated with size-class real-device checks.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced app-defined point-width thresholds with adaptive SwiftUI: Duo/iPhone split decided by system size classes; iPad exam-tool sidebar collapse handled by NavigationSplitView; calculator picks fitting vs scrolling via ViewThatFits with an explicit scroll path for compact sheets; keys stay at least 44 pt (46 pt floor); window-size plumbing and DEBUG window-size hooks replaced by size-class hooks; threshold tests replaced by size-class policy tests.
<!-- SECTION:FINAL_SUMMARY:END -->
