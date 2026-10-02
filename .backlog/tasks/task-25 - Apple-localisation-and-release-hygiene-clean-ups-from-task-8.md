---
id: TASK-25
title: Apple localisation and release-hygiene clean-ups from task-8
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:10'
updated_date: '2026-10-02 01:44'
labels:
  - apple
  - l10n
milestone: m-0
dependencies: []
priority: low
ordinal: 33000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: two small gaps from the task-8 review. (1) The French error tests only look up the catalogue; they never run QuestionBankLoadError.errorDescription under a French locale, so a regression in the real code path would pass. (2) RootView.swift keeps a test-only 'Forced store open failure' message in release builds, so test scaffolding ships to users.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A unit test runs QuestionBankLoadError.missingResource(...).errorDescription under a French locale (fr and fr-CA) and asserts the exact French text
- [x] #2 The forced store-failure test string and its code path compile only in DEBUG or UI-testing builds and are absent from the Release build, verified by a Release build plus a check that the string is not in the built app's strings
- [x] #3 pnpm check:apple-l10n and the iOS and macOS xbuild suites pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a unit test that evaluates QuestionBankLoadError.missingResource("manifest").errorDescription with French language settings for fr and fr-CA and asserts the exact French text. 2. Gate the forced store-open failure launch argument and localized helper so they are only compiled for Debug/UI-test-capable builds and do not emit the forced-failure string into Release. 3. Validate with pnpm check:apple-l10n, iOS and macOS xbuild test suites, and a Release xbuild plus built-app string scan for the forced-failure text before checking acceptance criteria.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented a bundle-based QuestionBankLoadError.localizedMessage(bundle:) seam; errorDescription delegates to the same function with .main, and the French unit test verifies fr and fr-CA lproj bundles through that same code path with bundle as the only parameter. Gated the forced store-open UI-test failure helper and launch-argument path with #if DEBUG, removed its catalogue entry, and verified a Release macOS build contains neither the English nor French forced-failure string in the binary or localized resources. Validation passed: pnpm check:apple-l10n; iOS xbuild CanadianHam test suite (21 unit + 26 UI); macOS xbuild CanadianHam unit suite (21 tests, UI skipped per project instructions); Release macOS xbuild build and forced-string scan.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added the French QuestionBankLoadError localization coverage through the bundle seam used by errorDescription, removed the forced store-failure string from shipped localization resources, and restricted the forced store-failure launch path/helper to DEBUG builds. Verified with pnpm check:apple-l10n, iOS and macOS xbuild test suites, and a Release macOS build plus binary/localized-resource string scan.
<!-- SECTION:FINAL_SUMMARY:END -->
