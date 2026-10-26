---
id: TASK-74
title: iPad mock exam accessibility audits
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T00:56:00Z'
updated_date: '2026-10-26T13:37:00Z'
labels:
  - apple
  - accessibility
  - testing
dependencies: []
references:
  - apps/apple/CanadianHamUITests/CanadianHamExamToolsUITests.swift
  - apps/apple/CanadianHamUITests/CanadianHamPracticeUITests.swift
priority: medium
type: bug
ordinal: 153000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Coordinator-authorized follow-up from TASK-44.5 (2026-10-24 under owner delegation 2026-10-22), incorporating the earlier TASK-74 100% official-sheet investigation rather than creating a duplicate.

Unresolved iPad Pro 13-inch (M5), iOS 27.0 findings:
1. Fully visible thin monospaced mock-exam-seed contrast findings in light/dark. A .weight(.medium) experiment did not resolve the legacy seed ui-a11y-mock-exam-timer; it was reverted, preserving the app presentation. Original evidence: Test-CanadianHam-2026.10.24_19-02-02--0400.xcresult; /tmp/task445-ipad-light-attachments/B2933CAE-5FDC-4DA0-9FE6-AFF090645C02.png and /tmp/task445-ipad-dark-before/BDD80782-FBED-42E0-94BE-6596F7BB3132.png. Medium experiment: /tmp/task445-ipad-legacy-light/ECD64D0A-4E39-49F8-A543-5D3273666E85.png in Test-CanadianHam-2026.10.24_21-16-19--0400.xcresult.
2. Official sheet full-default audits report one nil-element .textClipped finding, with no element screenshot/identifier, at BOTH 100% and 150% zoom in mock exams. 100%: /tmp/task445-ipad-running-final.log, Test-CanadianHam-2026.10.24_20-50-46--0400.xcresult, /tmp/task445-ipad-light-after/BEA27278-CB27-4450-B8FE-EF25DE94E570.png and CD215185-0B83-42FD-84B2-9C5587360FEB.txt. 150%: /tmp/task445-ipad-final.log, Test-CanadianHam-2026.10.24_21-16-19--0400.xcresult, /tmp/task445-ipad-150-light/{3C5764C2-40A0-47C5-86D8-AAFFB53CDA58.png,6C64B812-0105-4693-8C9A-D3818AC5A6D1.txt} and /tmp/task445-ipad-150-dark/{D736305E-EA71-46CB-B867-6B1B5B095B0F.png,09C7FCF6-EC65-4076-B5AC-35C6CFFE8AFB.txt}. The practice matrix audits official images only at 150%; investigate 100% and 150% on BOTH practice and mock paths in light/dark.
3. Pre-existing CanadianHamPracticeUITests.testAccessibilityAuditMockExamFlowDark and testMockExamHeaderControlsSupportLargestAccessibilityTextSize assume a compact Questions button that does not exist in real iPad regular layout. The light flow can also fail on the caption. Existing tests/helpers were not changed by TASK-44.5. Evidence: /tmp/task445-ipad-final.log and the same 21-16-19 xcresult.

All xcresults are under /Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-dipnadmjyqgfukfpgamjtsdvyhpd/Logs/Test/.

Coordinator decision for TASK-44.5 only: its new iPad mock tests retain EVERY behaviour assertion (pages/zoom/text/fallback, question/answer/progress/timer continuity, Advanced/no-hints negatives) without their full audits; iPhone keeps every full-default audit. AGENTS.md records this temporary limitation. No generic iPad nil-element or measured-contrast exception is granted; do not extend the iPhone medium rule or TASK-71/73 scopes. Investigation/remediation and restoration of iPad audits remain this follow-up, with separate approval for any new exception.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The iPad exam-code contrast, official-sheet 100%/150% nil textClipped findings (practice and mock, light/dark), and legacy compact-Questions assumptions are investigated with reproducible screenshot/xcresult evidence.
- [ ] #2 Findings document affected elements/layouts or framework limitations and scoped remediation/restoration of iPad audits or required owner decisions; existing audit/exception scopes are preserved unless separately approved.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Reproduce the iPad caption, official-sheet clipping and legacy navigation findings with screenshot, hierarchy and xcresult evidence; measure caption pixels and bisect nil-element clipping with temporary scratch probes.
2. Apply only proven minimal semantic-colour/weight or layout fixes; make legacy Questions navigation layout-aware without reducing assertions/audits; preserve shared helpers and exception scopes.
3. Restore TASK-44.5 iPad audits where resolved; run targeted iPad/iPhone tests, macOS compilation, text/l10n/test-guard checks; document per-test outcomes and before/after evidence.
4. Commit and push milestones; record exact unresolved owner decisions and keep In Progress unless all findings are resolved.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-10-26 baseline investigation: fresh native iPad PNGs and full hierarchies persisted under docs/evidence/task-74; docs/testing/task-74-ipad-mock-audits.md records reproduction and exact ratios. Caption glyph-core contrast is 16.3364:1 light / 12.6297:1 dark, while current full audit reports contrast failed/nearly passed. No styling change or measured-contrast extension: needs an owner decision. Scratch page-4 clipping matrix: practice passes light/dark at 100%/150%; mock fails one nil-element textClipped in all four states (baseline xcresult /tmp/task74-baseline.xcresult, 2 diagnostic tests/6 expected issues). Omitting only inline mock navigator does NOT remove the two mock-light clipping failures, so next scratch bisection isolates the mock header. All scratch handlers return false; no audit exception is added. Legacy layout-aware test edits pending validation; shared helpers untouched.
<!-- SECTION:NOTES:END -->
