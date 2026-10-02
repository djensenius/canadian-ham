---
id: TASK-1.2
title: Prepare App Store privacy label evidence
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 04:28'
labels:
  - release
  - apple
  - 'legacy:T-603'
milestone: m-0
dependencies:
  - TASK-1.1
documentation:
  - docs/release/privacy-label-evidence.md
  - docs/privacy.md
modified_files:
  - docs/release/privacy-label-evidence.md
  - docs/privacy.md
  - apps/web/src/lib/i18n.ts
parent_task_id: TASK-1
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Assemble the evidence for the App Store privacy label 'Data Not Collected' and the web privacy summary: PrivacyInfo.xcprivacy, pnpm check:apple-network output, the dist URL audit, and docs/privacy.md. Legacy: T-603.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 An evidence document lists each App Store privacy question with the answer and the supporting file or check output
- [x] #2 The web privacy summary matches docs/privacy.md
- [ ] #3 pnpm check:apple-network and the web dist URL audit pass on the release commit
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inventory current privacy sources: docs/privacy.md, existing Apple wording references in docs, apps/apple PrivacyInfo.xcprivacy target membership, Apple network checks, and web app privacy copy.
2. Run required validation commands and capture commit SHA/output summaries: pnpm check:apple-network, pnpm test:apple-network, pnpm build:web, and pnpm --filter @canadian-ham/web audit:urls.
3. Add docs/release/privacy-label-evidence.md documenting the current App Store privacy label/privacy manifest questions in scope with answers and evidence, marking wording that must be confirmed in App Store Connect; link it from docs/privacy.md.
4. Align web Settings privacy summary copy with docs/privacy.md, including EN/FR per docs/french-style.md.
5. Update task notes/final summary, check only AC #1 and #2 with evidence, and leave AC #3 unchecked/In Progress because the release commit does not exist yet.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Prepared docs/release/privacy-label-evidence.md and linked it from docs/privacy.md. Updated apps/web Settings privacy copy in English and French to match docs/privacy.md, including no accounts/analytics/third-party requests/server-side progress storage and static-host log caveat. Validation snapshot on commit 788b49f95f8387525da42bacb4b7c81d2cbb4331: plutil parsed PrivacyInfo.xcprivacy with no collected data/tracking/required-reason APIs; pnpm check:apple-network passed; pnpm test:apple-network passed; pnpm --filter @canadian-ham/web test passed (10 files, 81 tests); pnpm build:web passed with a non-fatal chunk-size warning; pnpm --filter @canadian-ham/web audit:urls passed. AC #3 remains unchecked because the release commit does not exist yet; rerun required commands on the release commit before checking it.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Pre-release privacy-label evidence is prepared for task-1.2: added docs/release/privacy-label-evidence.md, linked it from docs/privacy.md, and aligned the web Settings privacy summary (EN/FR) with docs/privacy.md. AC #1 and #2 are verified by the evidence document and validation outputs; AC #3 is intentionally left unchecked and the task remains In Progress until the same checks pass on the future release commit.
<!-- SECTION:FINAL_SUMMARY:END -->
