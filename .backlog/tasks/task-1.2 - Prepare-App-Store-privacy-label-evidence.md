---
id: TASK-1.2
title: Prepare App Store privacy label evidence
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 04:24'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inventory current privacy sources: docs/privacy.md, any App Store wording references in docs, apps/apple PrivacyInfo.xcprivacy files/target membership, Apple network checks, and web app privacy copy.\n2. Run required validation commands and capture commit SHA/output summaries: pnpm check:apple-network, pnpm test:apple-network, pnpm build:web, and pnpm --filter @canadian-ham/web audit:urls.\n3. Add docs/release/privacy-label-evidence.md documenting every current App Store privacy label/privacy manifest question in scope with answers and evidence, marking wording that must be confirmed in App Store Connect; link it from docs/privacy.md.\n4. Align web About/Settings privacy summary copy with docs/privacy.md if needed, including EN/FR per docs/french-style.md.\n5. Re-run relevant checks, update task notes/final summary, check only AC #1 and #2 with evidence, and leave AC #3 unchecked/In Progress because the release commit does not exist yet.
<!-- SECTION:PLAN:END -->
