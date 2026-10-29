---
id: TASK-81
title: Refresh release audit coverage and current privacy inventory
status: In Progress
assignee:
  - '@copilot-worker'
created_date: '2026-10-29T00:01:00Z'
updated_date: '2026-10-29T00:02:00Z'
labels:
  - release
  - docs
dependencies: []
references:
  - docs/release/release-checklist.md
  - docs/release/privacy-label-evidence.md
type: docs
ordinal: 165000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Fleet reconnaissance found that the consolidated release checklist does not explicitly schedule the audit plans excluded from the default Apple plan, and the historical privacy snapshot predates current Morse settings UserDefaults persistence. Refresh documentation without treating a rehearsal as release approval or making unsupported required-reason compliance claims. Related existing work: TASK-1.5 and TASK-1.2; preserve their statuses and release gates.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Release checklist explicitly requires the separate figure and title-sweep plans, exclusive quiet-host figure scheduling, and per-test evidence.
- [ ] #2 A dated source-revision-identified privacy addendum preserves historical evidence, inventories current preference persistence and manifest declarations, and explicitly records unresolved required-reason review without invented reasons or compliance clearance.
- [ ] #3 Links and focused source/configuration cross-checks pass; only the two release documents and CLI-managed task records change; parent statuses, release gates, and owner status.md remain untouched.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Compare release checklist with current Apple default/figure/title test plans and quiet-host runner; preserve all release/device/ISED gates.
2. Inventory current Apple preference persistence, manifest declarations and target membership at source SHA a69c27400b88302c9f8ce393ea98ae01b73cfd25; append dated historical-preserving evidence with required-reason review OPEN.
3. Run pnpm check:links and focused source/configuration comparisons; no Apple suites for docs-only edits. Verify scoped diff and unchanged parent statuses; record evidence, finalize TASK-81 and commit documentation.
<!-- SECTION:PLAN:END -->
