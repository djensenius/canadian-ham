---
id: TASK-1.2
title: Prepare App Store privacy label evidence
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
labels:
  - release
  - apple
  - 'legacy:T-603'
milestone: m-0
dependencies:
  - TASK-1.1
parent_task_id: TASK-1
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Assemble the evidence for the App Store privacy label 'Data Not Collected' and the web privacy summary: PrivacyInfo.xcprivacy, pnpm check:apple-network output, the dist URL audit, and docs/privacy.md. Legacy: T-603.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An evidence document lists each App Store privacy question with the answer and the supporting file or check output
- [ ] #2 The web privacy summary matches docs/privacy.md
- [ ] #3 pnpm check:apple-network and the web dist URL audit pass on the release commit
<!-- AC:END -->
