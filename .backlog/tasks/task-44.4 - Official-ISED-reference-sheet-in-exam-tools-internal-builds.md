---
id: TASK-44.4
title: Official ISED reference sheet in exam tools (internal builds)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 22:21'
updated_date: '2026-10-22 01:54'
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

AC3 implementation: official exam PDF reproduced as five unannotated offline pages (144 dpi, deterministic render/checksums recorded); English printed text/formulas transcribed, with explicitly project-authored symbol/connection descriptions for otherwise unlabelled diagrams. Web and iOS/iPadOS/macOS have page selection, zoom, accessible text, and Study sheet fallback. tvOS/visionOS have no reference-sheet tool and are unchanged. OFFICIAL_REFERENCE_SHEET excludes imports/resources in default production/Release, removes stale Apple resources, and is enabled only in dev/Debug or explicit internal beta opt-in. Gate script plus web gate/fallback tests added; licensing, release checklist and internal TestFlight instructions updated.\nValidation so far: typecheck passed; pnpm test passed (content-tools 226, Morse 21, calculator 127, web 253); default and opted-in web builds + both URL/CSP audits passed, default official-asset/transcript absence verified; Markdown links and text-source gate passed; XcodeGen second generation identical; 12 iPhone exam-tool unit tests passed, Basic-only availability and hint ladder UI regressions passed. First new UI run found a too-small caption zoom percentage and an over-flinging generic scroll setup at AX-XXXL; fixed app typography and added reference-specific precise positioning without changing shared/audit helpers. Rerunning only failed UI tests; macOS unit checks and l10n queued via nohup.

Targeted audit fix rounds: the new positioning helper wrongly inset its visible rectangle by 2pt, excluding leading-edge controls; corrected to the full visible scroll frame below navigation. Coordinator approved viewport positioning plus real tap/state checks in this new helper only. Once-per-test diagnostics show Next isHittable=true, no blocking transparent overlay, and actual page/sheet/zoom state changes succeed. Shared/audit/exception helpers remain unchanged. Reused the existing accessible secondary-button style and explicit Dynamic Type layouts for zoom after the full-default audit flagged the native button style. AX-XXXL audit setup aligns a whole control boundary so an offscreen Page label is not sampled through the opaque tool header; no audit types or findings are ignored.
Latest iPhone official-sheet EN/FR light/dark method passed (253.426s), including all 12 full-default image/text/fallback audits. AX-XXXL and iPad checks still running. macOS units 38/38 passed; the completed l10n check passed, including tvOS and visionOS build checks. The catalogue exporter reordered keys; semantic comparison against the merge baseline confirms no existing translation was changed or removed.
Test guard: self-test passed. Use exactly Test-guard-approved: owner decision 2026-10-12 in the eventual PR body (coordinator approval). The only guarded changes are replacing testReferenceSheetToolHiddenUntilTask44Dot4 with testReferenceSheetToolAvailableOnlyForBasic (the obsolete hidden assertion is superseded by the requested feature; Advanced still explicitly rejects the sheet), and adding testOfficialReferenceSheetLightAndDarkEnglishAndFrench plus testReferenceSheetLargestDynamicTypeKeepsControlsReachable with full-default audits.

Coordinator clarification/approval 2026-10-21: the existing approved exception (a), using unchanged auditIgnoringOccludedLessonTextContrast(app:), covers exam tools as part of practice/mock screens (owner 2026-10-14). Use it ONLY for the new AX-XXXL reference-sheet audit, where the Page label is partly clipped by the tool scroll area; nonnil-element, scroll ancestry/intersection and not-fully-visible constraints remain exactly as implemented, and fully visible contrast/non-contrast issues still fail. The 12 EN/FR light/dark official-image/text-equivalent/study audits remain raw performAccessibilityAudit() default calls. Removed brittle exact top-alignment setup rather than adding or widening any exception/helper. 44pt assertions and actual sheet/page/zoom state checks remain intact.

Latest: iPhone AX-XXXL passed (139.160s) after returning the reference scroll view to its top before its approved full-default audit; iPad AX-XXXL passed (46.312s). iPad normal matrix image/text audits passed, then its Study fallback audit sampled a clipped -3 dB table row at the bottom edge (blank-paper element screenshot). Coordinator approved the unchanged occluded-scroll contrast helper for the iPad Study fallback only as the same existing exception (a); image/official-text audits and every iPhone normal audit remain raw/default. Rerunning only that iPad matrix method; no shared/audit helper changes.

Coordinator approval 2026-10-21 for the iPad fallback only: add NEW auditIgnoringOccludedReferenceSheetTextContrast. The unchanged generic helper picks the main/background scroll view in the inspector layout, so it cannot classify the reference panel clip. The new helper selects only reference-sheet-scroll and fails if absent (no fallback). Its performAccessibilityAudit handler is byte-for-byte identical to the approved exception (a) rule: contrast-only, nonnil element, non-navigation frame, explicit reference scroll ancestry/intersection, not fully contained in visible reference area. All 67 pre-existing helpers remain byte-for-byte unchanged. The internal reviewer should diff the new handler line by line against the original; the eventual PR must explain the second-scroll-view reason under Test-guard-approved: owner decision 2026-10-12.
<!-- SECTION:NOTES:END -->
