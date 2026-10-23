---
id: TASK-70
title: >-
  Align occluded-contrast audit exception with owner wording (offscreen
  elements)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-23 03:00'
updated_date: '2026-10-23 03:00'
labels: []
dependencies: []
priority: high
type: task
ordinal: 149000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner-delegated decision 2026-10-22 (owner: make the best decisions you can; coordinator direction): align the shared occluded-contrast exception with the owner decision of 2026-10-12. Ignore only contrast audit findings whose non-zero element frame is not fully contained in the visible scroll area below an opaque navigation bar, including fully offscreen scroll-content descendants because the audit renders offscreen content as black. Remove only the scroll-frame intersection prerequisite in every helper copy, preserving nil-element, navigation-bar, ancestry, visible-containment checks and logging. Fully visible contrast and all non-contrast findings must still fail. Lone bullet and Question N of M false positives are conditional follow-up work, not granted by this task.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every occluded-contrast helper copy removes only the scrollFrame.intersects(frame) prerequisite and retains contrast-only, non-nil/non-zero frame, navigation exclusion, scroll ancestry, visible containment, and logging; lesson copies remain byte-identical.
- [ ] #2 AGENTS.md records the dated 2026-10-22 clarification including fully offscreen content and explicitly states that fully visible bullet and Question N of M exceptions are not yet granted.
- [ ] #3 Document or unit-test frame classification for fully offscreen, partially visible, fully visible, non-contrast, and nil-element cases without a significant helper refactor.
- [ ] #4 Discover all direct and transitive helper-calling UI tests and record per-test targeted iPhone 17 Pro results plus iPad reference-sheet helper caller results; failures remain visible and are escalated rather than widening exceptions.
- [ ] #5 Run the test-guard self-test and diff check using Test-guard-approved: owner decision 2026-10-22; record commands and skipped-platform rationale.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect all helper copies and discover direct/transitive test callers, including reference-sheet iPad paths.
2. Remove only the four intersection guards; document the dated scope in AGENTS.md. Keep inline classification if extraction significantly rewrites the four audit bodies; document the classification truth table.
3. Run all helper caller tests with targeted -only-testing selections through xbuild in two nohup batches (iPhone default/figure plans, iPad reference sheet), recording per-test outcomes. Run the guard self-test and approved diff guard.
4. Record evidence, finalize the verified task, commit and push the branch without opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
ID reconciliation: CLI allocated TASK-70 because the parallel Study-title lane reserved TASK-69. Coordinator approved keeping TASK-70 and renaming this branch to task-70-occluded-helper-align.
Classification kept inline: extracting audit type, optional XCUIElement/frame, nav-frame matching, and ancestry into a shared pure predicate would significantly rewrite all four existing audit closures for a one-line-per-copy change. The permitted documentation fallback is used: contrast + non-nil positive frame + non-nav + scroll descendant is ignored iff visibleScrollArea does not contain its frame. Fully offscreen -> ignored; partially visible -> ignored; fully visible -> not ignored; non-contrast -> not ignored (first guard); nil element -> not ignored (second guard); zero-size/nav/non-descendant -> not ignored. No bullet/header exception added.
<!-- SECTION:NOTES:END -->
