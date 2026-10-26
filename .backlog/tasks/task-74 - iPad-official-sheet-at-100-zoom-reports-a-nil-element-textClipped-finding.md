---
id: TASK-74
title: iPad mock exam accessibility audits
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T00:56:00Z'
updated_date: '2026-10-26T14:09:00Z'
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

5. Coordinator-approved caption follow-up (2026-10-26): unchanged composite failed the oversized whole-element crop (4.104 light / 3.554 dark). Investigate a structural accessibility-frame correction preserving text selection and pixel-identical card appearance on iPad/iPhone light/dark; prefer plain audits, or use the approved unchanged composite only if it measures successfully. No non-button crop/algorithm/threshold changes.

6. Coordinator direction 2026-10-26 under owner 2026-10-18 single-tree adaptive-layout rule: replace only the outer mock-header ViewThatFits with a small fitting Layout following LessonQuizControlLayout. Choose horizontal from measured ideal width vs proposed width, else identical leading VStack; force vertical at accessibility sizes. No point thresholds, no new handlers. Prove narrow/wide/portrait/AX rendering parity, restore all TASK-44.5 iPad full audits, and rerun targeted coverage.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-10-26 baseline investigation: fresh native iPad PNGs and full hierarchies persisted under docs/evidence/task-74; docs/testing/task-74-ipad-mock-audits.md records reproduction and exact ratios. Caption glyph-core contrast is 16.3364:1 light / 12.6297:1 dark, while current full audit reports contrast failed/nearly passed. No styling change or measured-contrast extension: needs an owner decision. Scratch page-4 clipping matrix: practice passes light/dark at 100%/150%; mock fails one nil-element textClipped in all four states (baseline xcresult /tmp/task74-baseline.xcresult, 2 diagnostic tests/6 expected issues). Omitting only inline mock navigator does NOT remove the two mock-light clipping failures, so next scratch bisection isolates the mock header. All scratch handlers return false; no audit exception is added. Legacy layout-aware test edits pending validation; shared helpers untouched.

Coordinator decision received 2026-10-26 under owner delegation 2026-10-22 (record requested as coordinator 2026-10-25 in AGENTS): caption appearance must stay unchanged. Existing local auditIgnoringOccludedOrMeasuredContrast composite is now approved for TASK-44.5 iPad mock tests and iPad legacy mock tests hitting the same caption. Keep all non-contrast issues, unmeasurable/below-4.5 contrast failing; keep existing button-crop rules, algorithms, thresholds and shared helpers byte-identical; no new handler or nil-element rule. Eventual PR marker: Test-guard-approved: owner decision 2026-10-22. Clipping bisection continues independently; omit-header scratch cleared both 100%/150%, while omitting caption alone did not. Header-controls bisection queued on shared lock.

Caption milestone: a structural .contentShape(.accessibility, Rectangle()) on the still-selectable caption tightens its AX frame from (60,110,284.5,46.5) to (76,126,252.5,14.5) points on iPad. Element PNG shrinks 568x92 -> 504x28; unchanged whole-image measurement now yields 16.3364:1 light / 12.6286:1 dark. Plain contrast probes pass both appearances (iPad 33.361 s, iPhone after 52.534 s; before iPhone 60.752 s). Before/after iPad full-card crops and iPhone app-content regions are pixel-identical (zero differing RGB pixels) in light/dark; screenshots persisted under docs/evidence/task-74. Per superseding coordinator direction no measured composite or new AGENTS scope is used. Full-default regression and restored pre/post mock-screen audits are prepared. Clipping bisection: omitting timer controls clears both inspector zooms; fixed-ideal-width HStack does not. Testing the already-selected vertical candidate next; no scratch layout changes will ship.
<!-- SECTION:NOTES:END -->
