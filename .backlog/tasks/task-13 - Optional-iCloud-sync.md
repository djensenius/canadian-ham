---
id: TASK-13
title: Optional iCloud sync
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
labels:
  - apple
  - privacy
  - needs-decision
  - 'legacy:T-705'
milestone: m-1
dependencies: []
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Privacy-review item: optional, opt-in iCloud sync of learning progress via SwiftData and the CloudKit private database. The research recommends post-v1, because CloudKit requires removing unique constraints from the progress models. v1 stays offline with no iCloud. Legacy: T-705.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The research is source-checked and committed under docs/proposals/
- [ ] #2 The owner's decisions (timing, sync scope, opt-in default off) are recorded
- [ ] #3 If approved, implementation subtasks are created and the AGENTS.md v1 iCloud rule is revisited
<!-- AC:END -->
