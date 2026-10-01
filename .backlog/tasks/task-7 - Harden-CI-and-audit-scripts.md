---
id: TASK-7
title: Harden CI and audit scripts
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 21:59'
labels:
  - ci
milestone: m-0
dependencies: []
ordinal: 14000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Reviews of the no-network audit and CI lanes left non-blocking gaps where a check can pass without checking anything: a grep error read as 'no matches', untested skip branches, a zero-file originality run, a case-sensitive URL scan, and a rule whose sample also matches another rule. Each is a silent false-pass risk in a gate we rely on for the privacy promise.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The Swift URL-literal scan treats grep exit 2 as an error, not as no matches
- [ ] #2 The self-test covers the grep-error branch and the plutil-missing skip branch
- [ ] #3 check-lesson-originality --all fails when it checks zero files
- [ ] #4 The lesson URL scan is case-insensitive (HTTPS://, WWW.)
- [ ] #5 The import-kind rule has a sample that only that rule can match (e.g. import enum WebKit.WKNavigationType)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Harden scripts/check-apple-no-network.sh so Swift URL grep failures report as audit issues and lesson content URL detection catches uppercase HTTPS/WWW references without changing allowed citation rules.\n2. Extend scripts/test-check-apple-no-network.sh with fixtures for URL-grep failure, plutil-unavailable skip output, uppercase lesson links, and a single import-kind sample that only the import-kind rule can match.\n3. Update packages/content-tools/src/check-lesson-originality.ts and tests so --all/required full-bank runs fail when zero lesson files are checked.\n4. Run required bash, pnpm, and originality validation, then record evidence before finalizing task-7.
<!-- SECTION:PLAN:END -->
