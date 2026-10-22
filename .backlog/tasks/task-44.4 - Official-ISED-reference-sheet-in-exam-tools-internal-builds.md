---
id: TASK-44.4
title: Official ISED reference sheet in exam tools (internal builds)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 22:21'
updated_date: '2026-10-22 00:04'
labels:
  - content
  - web
  - apple
dependencies:
  - TASK-44.3
modified_files:
  - docs/content-licensing.md
  - docs/release/ised-reference-sheet-request.md
parent_task_id: TASK-44
priority: medium
ordinal: 111000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner decision 2026-10-12 (2A): use the official ISED Basic reference sheet (EN PDF in content/sources/ised/basic-2025-07-15/reference/) in the in-exam reference panel for internal TestFlight builds under the interim risk basis, while asking ISED to add the reference sheets (EN and FR) to the permission request. Public release stays blocked until ISED permission covers the sheet. Keep the original study sheet as the fallback (one config point).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 docs/content-licensing.md records the decision, the risk basis, and that public release is blocked until permission covers the sheet
- [x] #2 A ready-to-send follow-up request to ISED (EN, asking for the reference sheets in EN and FR) is drafted for the owner
- [ ] #3 Web and Apple exam tools show the official sheet (zoomable, accessible text equivalent) in internal builds; the original sheet remains available as fallback
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Merge origin/main (branch task file retained) and push.
2. Render the official five-page exam PDF offline with source checksums; maintain a faithful English text equivalent separately from the original study sheet.
3. Integrate zoomable official/study selector on web and iOS/iPadOS/macOS, gated by OFFICIAL_REFERENCE_SHEET (Debug/dev on; Release/production off; explicit internal beta opt-in only).
4. Add targeted reference-sheet unit, EN/FR light/dark accessibility, resource-gate and Apple UI coverage without changing audit helpers. Document public-release exclusion.
5. Run requested targeted web/Apple checks via nohup/polling, record per-test evidence, check AC3, finalize, commit and push (no PR).
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Docs-only slice complete: updated docs/content-licensing.md with owner decision 2026-10-12 (2A), original-request exclusion of reference sheets, interim internal-TestFlight risk basis matching the question-bank handling, task-1.7/T-009 public-release block until T-007/task-1.1 permission covers the sheet, English-only source status, and fallback content/reference-sheet/basic.md. Drafted docs/release/ised-reference-sheet-request.md for the owner to send to ISED. Validation: pnpm check:links passed.

PDF inspection for integration lane (no integration implemented; depends on task-44.3): inspected content/sources/ised/basic-2025-07-15/reference/*.pdf with file(1), mdls, raw PDF object counts, and a Swift/PDFKit text extraction script because poppler pdfinfo/pdftotext is not installed on this machine. Exam PDF (Reference Material for Amateur Radio Exam Basic EN 2025.pdf): PDF 1.7, 5 pages, PDFKit extracted 1,307 characters total; page 1 has formula text, pages 2-5 mostly headers/titles plus object placeholders for diagrams; raw scan found 12 /Subtype/Image XObjects, fonts, and ToUnicode maps. Training PDF: PDF 1.7, 7 pages, PDFKit extracted 2,610 characters total; page 1 has formula table text, pages 2-7 mostly headings plus diagram/image placeholders; raw scan found 12 image XObjects. Integration plan: use only the exam-version sheet for exam tools. Web should prefer pre-rendered page images for stable offline fidelity/zoom plus a maintained/extracted text equivalent/transcript instead of embedding the PDF directly. Apple can use PDFKit/PDFView for the official PDF fidelity and zoom if accessibility is verified, but still needs a separate accessible text equivalent because the diagram pages are image-based and the PDF text layer is incomplete; fall back to page images plus transcript if PDFKit accessibility is insufficient.

2026-10-12: Owner sent the ISED follow-up request (docs/release/ised-reference-sheet-request.md) asking to add the Basic reference sheets (EN and FR) to the permission. Awaiting reply; public release stays blocked until permission covers the sheet.

2026-10-21: Merged origin/main and pushed 3ba41fef; retained branch task version per instruction. Coordinator approved Debug/dev ON and default Release/production OFF gate with explicit internal beta opt-in, public permission gate unchanged.
<!-- SECTION:NOTES:END -->
