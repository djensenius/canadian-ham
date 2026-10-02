---
id: TASK-25
title: Apple localisation and release-hygiene clean-ups from task-8
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:10'
updated_date: '2026-10-02 01:13'
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
- [ ] #1 A unit test runs QuestionBankLoadError.missingResource(...).errorDescription under a French locale (fr and fr-CA) and asserts the exact French text
- [ ] #2 The forced store-failure test string and its code path compile only in DEBUG or UI-testing builds and are absent from the Release build, verified by a Release build plus a check that the string is not in the built app's strings
- [ ] #3 pnpm check:apple-l10n and the iOS and macOS xbuild suites pass
<!-- AC:END -->
