---
id: TASK-68
title: Harden the web official-sheet exclusion check with asset hashes
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-22 03:34'
updated_date: '2026-10-24 18:35'
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
- [ ] #1 The default web build check fails when any output file matches an official page SHA-256, including renamed files
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read official asset SHA-256 values from the reference README and scan every default web output file by hash, retaining existing filename/transcript checks.
2. Decode inline base64 image data URLs and compare their hashes; add self-tests for renamed/hashed/extensionless official assets, inline JS/CSS images, transcript content, and clean output with the original study sheet.
3. Update licensing/release-checklist documentation, run both build modes plus gate self-tests, pnpm test, pnpm typecheck, and the URL/CSP audit; record evidence, finalize TASK-68, commit and push the task branch.
<!-- SECTION:PLAN:END -->
