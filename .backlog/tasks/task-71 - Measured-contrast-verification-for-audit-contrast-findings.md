---
id: TASK-71
title: Measured-contrast verification for audit contrast findings
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-23 12:50'
updated_date: '2026-10-23 12:51'
labels:
  - accessibility
  - tests
dependencies: []
priority: high
ordinal: 150000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner-delegated decision 2026-10-22 (owner: make the best decisions you can). XCTest's performAccessibilityAudit reports contrast findings on fully visible, visibly high-contrast lesson and lesson-quiz text in the new TASK-46.5 and TASK-46.6.1 tests (e.g. 'Correct 820 / 1 000 = 0.82 A…' on the success panel, a Try-it intro paragraph, 'Question 1 of 1'), while main's existing tests pass. Evidence is in TASK-65 and /tmp/task-46.6.1-iphone-final-failure-evidence.json. Add a shared UI-test helper that runs the full default audit and, for contrast findings only on a non-nil element, measures the WCAG contrast ratio from the element screenshot pixels and ignores the finding only when the measured ratio is at least 4.5:1, logging the label, frame and ratio. Measurement failure or a ratio below 4.5:1 still fails; all non-contrast issues still fail. Used only by the new TASK-46.5 and TASK-46.6.1 audits unless a later decision widens it.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A shared helper measures text/background contrast from the element screenshot (WCAG relative luminance), ignores contrast findings only when the measured ratio >= 4.5:1, and logs label, frame and ratio; non-contrast, nil-element, unmeasurable and < 4.5:1 findings fail
- [ ] #2 Unit-style tests prove the measurement on synthetic images: dark-on-cream passes, mid-grey-on-cream (< 4.5:1) fails, two-colour panels and anti-aliased text are handled, and a uniform image is unmeasurable
- [ ] #3 AGENTS.md records the dated owner-delegated decision and its scope; existing helpers and existing tests are unchanged
- [ ] #4 Targeted proof: the helper passes on the known false-positive screens and fails on a deliberately low-contrast DEBUG-only fixture or an equivalent synthetic proof
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect failure screenshots and existing UI-test audit/target conventions.
2. Add a pure quantized WCAG contrast measurement helper, strict default-audit wrapper, synthetic proofs and three exported element-image resources; document the narrow approved scope.
3. Regenerate XcodeGen twice and verify no second-run changes; run only the new pure UI-test class on iPhone 17 Pro through nohup/xbuild, polling its log. Verify the test guard flags the handler.
4. Record evidence per AC, finalize TASK-71, commit and push the task branch (no PR).
<!-- SECTION:PLAN:END -->
