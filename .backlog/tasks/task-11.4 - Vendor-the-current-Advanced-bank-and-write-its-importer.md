---
id: TASK-11.4
title: Vendor the current Advanced bank and write its importer
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-02 15:48'
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
- [ ] #1 The current Advanced ZIP and PDFs are vendored verbatim under content/sources/ised/advanced-<title-page-date>/ with SHA-256 recorded, and the title-page date is the bank ID
- [ ] #2 The importer decodes the legacy encoding explicitly, handles the header row, and validates 549 questions, 7 categories and 50 subsections against the live file
- [ ] #3 A fixture covers a 50-question exam and no-Honours scoring; pnpm import:check and pnpm check:schemas pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Re-read the Advanced proposal/licensing constraints and current Basic importer/schema wiring.\n2. Fetch the live ISED Advanced ZIP and EN/FR PDFs, determine the PDF title-page date from extracted text/strings, and vendor verbatim artifacts with checksums and manifest metadata.\n3. Add Advanced category metadata and an importer path that explicitly decodes the source encoding, skips the header row, validates 549 questions / 7 categories / 50 subsections, and emits content/generated/advanced-<date>/ without changing the active Basic bank.\n4. Wire import:advanced:check into pnpm import:check, update schemas/docs and add real-bank Advanced engine/scoring fixtures.\n5. Run requested validation, update Backlog notes/ACs/final summary, and commit logical changes without pushing.
<!-- SECTION:PLAN:END -->
