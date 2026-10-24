---
id: TASK-68
title: Harden the web official-sheet exclusion check with asset hashes
status: Done
assignee:
  - '@worker'
created_date: '2026-10-22 03:34'
updated_date: '2026-10-24 18:37'
labels:
  - release
  - tests
dependencies: []
ordinal: 148000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-44.4 review note: the default web build check finds official pages by file name only; a renamed or inlined PNG would pass. Compare against the SHA-256 list in the reference README.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The default web build check fails when any output file matches an official page SHA-256, including renamed files
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read official asset SHA-256 values from the reference README and scan every default web output file by hash, retaining existing filename/transcript checks.
2. Decode inline base64 image data URLs and compare their hashes; add self-tests for renamed/hashed/extensionless official assets, inline JS/CSS images, transcript content, and clean output with the original study sheet.
3. Update licensing/release-checklist documentation, run both build modes plus gate self-tests, pnpm test, pnpm typecheck, and the URL/CSP audit; record evidence, finalize TASK-68, commit and push the task branch.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented SHA-256 exclusion for every regular dist file regardless of filename/extension, using the six asset hashes in content/reference/official-basic-exam/README.md as the single source of truth. Retained filename/transcript markers and now scan transcript text across every extension. Decoded base64 image data URLs are also hashed; the OFFICIAL_REFERENCE_SHEET=YES output-check exemption is unchanged. Updated asset provenance, licensing verification instructions and release checklist.

AC #1 evidence: pnpm test:official-reference-sheet passes self-tests that reject each of five official pages and the transcript under renamed .png, hashed .webp, .bin and extensionless names (24 fixtures). All five pages are also rejected when inlined as image data URLs in JS, CSS and an arbitrary-extension fixture with uppercase MIME/charset metadata (15 fixtures). Existing filename/marker rejection tests remain, with CSS and JSON-embedded transcript coverage added. Clean fixtures containing the original study sheet as text and a JS module, plus unrelated inline bytes, pass. Self-tests additionally verify that source asset bytes match the recorded hashes.

Validation passed: OFFICIAL_REFERENCE_SHEET=YES pnpm build:web (official assets present; output exclusion explicitly skipped), then env -u OFFICIAL_REFERENCE_SHEET pnpm build:web (default exclusion passed; clean default dist left in worktree); pnpm --filter @canadian-ham/web audit:urls passed against both builds (URL and CSP checks); pnpm test:official-reference-sheet; pnpm test (content-tools 244/244, Morse 21/21, calculator 127/127, web 260/260 across 18 files, plus official-sheet and release-permission gate self-tests); pnpm typecheck; git diff --check. Apple platform suites skipped because only a Node web-output check and docs changed; no Apple implementation changes.

Known limits, documented: exact-byte hashing cannot identify re-encoded images or obfuscated/assembled data URLs. Builds still report the existing >500 kB chunk warning; web tests report jsdom canvas getContext notices but all pass. No public deployment or distribution performed; no PR opened.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Default web builds now reject official reference page/transcript bytes under any filename or extension and reject decoded base64 image data URLs matching the README hashes. Existing name/transcript checks and internal opt-in behavior remain. Regression fixtures cover renamed files, inline JS/CSS images, transcript leaks and clean original-study-sheet output. Both build modes, gate self-tests, all 652 package/web tests, typechecking and URL/CSP audits passed; limitations are documented.
<!-- SECTION:FINAL_SUMMARY:END -->
