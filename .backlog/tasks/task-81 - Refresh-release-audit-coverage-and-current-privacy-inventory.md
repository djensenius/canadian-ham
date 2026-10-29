---
id: TASK-81
title: Refresh release audit coverage and current privacy inventory
status: To Do
assignee: []
created_date: '2026-10-29T00:01:00Z'
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
