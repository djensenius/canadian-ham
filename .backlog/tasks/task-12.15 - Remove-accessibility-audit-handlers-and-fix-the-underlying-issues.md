---
id: TASK-12.15
title: Remove accessibility audit handlers and fix the underlying issues
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-04 07:02'
updated_date: '2026-10-04 09:57'
labels:
  - apple
  - accessibility
  - morse
milestone: m-1
dependencies:
  - TASK-12.5
parent_task_id: TASK-12
priority: high
ordinal: 62000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the project rule is full default accessibility audits with no handlers or exclusions. Two Morse audits now filter issues: the graded copy/exam diff audit ignores contrast issues on morse-diff tokens (from task-12.6), which can hide real contrast failures in the error highlights, and the course-path audit ignores Dynamic Type issues on lesson labels (from task-12.5). Both need the underlying issues fixed so the audits can run unfiltered.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 No performAccessibilityAudit call in any UI test target uses an issue handler or a restricted audit-type set; all audits run the full default audit
- [ ] #2 The graded Morse diff tokens meet contrast in light and dark (colours from adaptive design tokens, not colour alone) and the course path passes Dynamic Type without filtering
- [ ] #3 The iOS light and dark audits for the Morse course path, lesson, summary and graded diff pass; the iOS and macOS suites pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Remove all issue handlers and restricted audit-type arguments from performAccessibilityAudit calls in the UI tests so every audit uses the default full audit.
2. Fix the underlying Morse diff contrast using adaptive Apple DesignTokens while keeping non-colour cues.
3. Fix the Morse course path Dynamic Type layout by allowing lesson content to wrap/scale without clipping.
4. Run targeted iOS audits/tests while iterating, then required web/package/check scripts and one final full iOS and macOS run; document per-test results.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Progress/blocked: removed all performAccessibilityAudit handlers/restricted audit-type sets; course path Dynamic Type light audit passed after replacing LazyVStack with VStack and using wrapping lesson button text. Graded diff full default audit still fails Xcode Contrast in light mode after opaque DesignTokens.Colors.paper background + DesignTokens.Colors.ink foreground on diff heading/summary and semantic DesignTokens backgrounds on tokens; xbuild reports failing element as visible high-contrast static text such as “Character diff” / diff summary. No filter added. Last failing command: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination platform=iOS Simulator,name=iPhone 17 Pro -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseExamGradedDiffLight test CODE_SIGNING_ALLOWED=NO. Need owner/coordinator decision per task instruction before continuing or accepting a system false-positive exception.
<!-- SECTION:NOTES:END -->
