---
id: TASK-11.4
title: Vendor the current Advanced bank and write its importer
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-02 15:56'
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
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Advanced bank ingestion for bank advanced-2025-02-04. Fetched fresh from HTTPS ISED URLs for ZIP and EN/FR PDFs, extracted title-page date 04 February/février 2025 from PDF streams, recorded SHA-256 checksums, and generated 549-question / 7-category / 50-subsection output. Validation passed: pnpm typecheck; pnpm test; pnpm import:check; pnpm check:schemas; pnpm check:links; content/sources/ised/advanced-2025-02-04 shasum -a 256 -c SHA256SUMS; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test in packages/engine-swift. Confirmed git status shows no apps/apple or apps/web changes.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Vendored the current ISED Advanced bank as advanced-2025-02-04, added an explicit-encoding Advanced importer and import:advanced:check, generated Advanced JSON, schema/docs wiring, and real-bank Advanced engine fixtures covering 50-question exams and no-Honours scoring. Verified with pnpm typecheck, pnpm test, pnpm import:check, pnpm check:schemas, pnpm check:links, source checksum verification, and Swift package tests.
<!-- SECTION:FINAL_SUMMARY:END -->
