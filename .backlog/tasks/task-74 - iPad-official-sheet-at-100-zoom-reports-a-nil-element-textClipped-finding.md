---
id: TASK-74
title: iPad official sheet at 100 % zoom reports a nil-element textClipped finding
status: To Do
assignee: []
created_date: '2026-10-25T00:56:00Z'
labels:
  - apple
  - accessibility
  - testing
dependencies: []
references:
  - apps/apple/CanadianHamUITests/CanadianHamExamToolsUITests.swift
priority: medium
type: bug
ordinal: 153000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Follow-up authorized by the coordinator on 2026-10-24 during TASK-44.5. On iPad Pro 13-inch (M5), iOS 27.0, the Basic mock official reference sheet at page 4 / 100% zoom reports one nil-element .textClipped finding from the full-default audit: "Text of this element may be clipped at larger Dynamic Type sizes." No identifier or element screenshot is supplied. The earlier fully visible mock-exam-seed contrast finding is resolved by the separately approved medium-weight caption; this is a different, non-contrast issue.

Evidence: /tmp/task445-ipad-running-final.log; /Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-dipnadmjyqgfukfpgamjtsdvyhpd/Logs/Test/Test-CanadianHam-2026.10.24_20-50-46--0400.xcresult; exported failure app screenshot /tmp/task445-ipad-light-after/BEA27278-CB27-4450-B8FE-EF25DE94E570.png and description /tmp/task445-ipad-light-after/CD215185-0B83-42FD-84B2-9C5587360FEB.txt. In CanadianHamExamToolsUITests the existing practice matrix audits the official image only at 150%, with Zoom out enabled; it does not audit the 100% state. TASK-44.5 is explicitly approved to align its new mock audit to that same 150% state while retaining real 100% zoom-out assertions, not to ignore this finding.

Investigate the 100% state on BOTH practice and mock paths, in light and dark. There is no approved iPad nil-element textClipped exception; do not extend the iPhone medium-detent rule or TASK-71/73 measured-contrast scope. Any new exception needs separate owner/coordinator approval.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The iPad 100% official-sheet state is investigated on both practice and Basic mock paths in light and dark with full-default audits, recording reproducibility and screenshot/xcresult evidence.
- [ ] #2 Findings document the affected element/layout or framework limitation and a scoped remediation or required owner decision, explicitly preserving existing audit/exception scopes unless separately approved.
<!-- AC:END -->
