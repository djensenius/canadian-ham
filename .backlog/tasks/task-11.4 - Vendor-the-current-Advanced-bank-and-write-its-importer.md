---
id: TASK-11.4
title: Vendor the current Advanced bank and write its importer
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-02 17:42'
labels:
  - content
milestone: m-1
dependencies:
  - TASK-11.2
  - TASK-11.3
parent_task_id: TASK-11
priority: medium
ordinal: 36000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: multi-course practice needs the official Advanced bank as generated data, imported with the same verbatim guarantees as Basic. See docs/proposals/advanced-course.md (owner decisions in task-11 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The current Advanced ZIP and PDFs are vendored verbatim under content/sources/ised/advanced-<title-page-date>/ with SHA-256 recorded, and the title-page date is the bank ID
- [x] #2 The importer decodes the legacy encoding explicitly, handles the header row, and validates 549 questions, 7 categories and 50 subsections against the live file
- [x] #3 A fixture covers a 50-question exam and no-Honours scoring; pnpm import:check and pnpm check:schemas pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Re-read the Advanced proposal/licensing constraints and current Basic importer/schema wiring.
2. Fetch the live ISED Advanced ZIP and EN/FR PDFs, determine the PDF title-page date from extracted text/strings, and vendor verbatim artifacts with checksums and manifest metadata.
3. Add Advanced category metadata and an importer path that explicitly decodes the source encoding, skips the header row, validates 549 questions / 7 categories / 50 subsections, and emits content/generated/advanced-<date>/ without changing the active Basic bank.
4. Wire import:advanced:check into pnpm import:check, update schemas/docs and add real-bank Advanced engine/scoring fixtures.
5. Run requested validation, update Backlog notes/ACs/final summary, and commit logical changes without pushing.

6. Fix review-round findings: restore schema negative-test specificity, keep Advanced generated content out of Apple bundles, cover Advanced engine fixtures in fixture generation, tighten checksum/docs/licensing coverage, create the requested French category-name follow-up, and rerun the requested validation.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Advanced bank ingestion for bank advanced-2025-02-04. Fetched fresh from HTTPS ISED URLs for ZIP and EN/FR PDFs, extracted title-page date 04 February/février 2025 from PDF streams, recorded SHA-256 checksums, and generated 549-question / 7-category / 50-subsection output. Validation passed: pnpm typecheck; pnpm test; pnpm import:check; pnpm check:schemas; pnpm check:links; content/sources/ised/advanced-2025-02-04 shasum -a 256 -c SHA256SUMS; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test in packages/engine-swift. Confirmed git status shows no apps/apple or apps/web changes.

2026-10-02 review round: owner asked to start before v1; keeping task Done while fixing review findings because acceptance criteria remain intended to hold after the fixes.

2026-10-02 review round complete: fixed schema bank selection and Advanced category negative tests; validated all Advanced SHA256SUMS entries; wired Advanced real-bank engine fixtures into generate-fixtures; documented live UTF-8 status; excluded Advanced generated data from iOS/macOS app and unit-test bundles while preserving the generated/basic-2025-07-15 resource layout. Created follow-up TASK-11.10 for official French Advanced category names. Verified no literal \n remains in the task plan. Validation passed: pnpm typecheck; pnpm test; pnpm import:check; pnpm check:schemas; pnpm check:links; pnpm --filter @canadian-ham/engine-ts test; pnpm --filter @canadian-ham/engine-ts generate-fixtures:check; cd packages/engine-swift && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test; XcodeGen run twice with stable pbxproj diff; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild iOS CanadianHam test on iPhone 17 Pro; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild macOS CanadianHam test with UI tests skipped. The first iOS xbuild attempt failed after the initial Apple resource change because the generated/ resource layout was missing; fixed by copying only Basic generated content into generated/basic-2025-07-15 and reran successfully.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Completed review-round fixes for task-11.4: restored bank-specific category schema diagnostics and negative tests including Advanced cases; verified every Advanced SHA256SUMS line in the importer; documented the live UTF-8 Advanced TXT; added content/categories-advanced.json to licensing docs; wired the real Advanced engine fixtures into generate-fixtures; kept generated Advanced data out of Apple app/test bundles; and created TASK-11.10 for official French category-name verification. Verified with pnpm typecheck, pnpm test, pnpm import:check, pnpm check:schemas, pnpm check:links, engine-ts tests, generate-fixtures:check, Swift package tests, stable double XcodeGen generation, and passing iOS/macOS xbuild suites.
<!-- SECTION:FINAL_SUMMARY:END -->
