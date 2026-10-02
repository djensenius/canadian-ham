---
id: TASK-26
title: Harden category French-name status checks
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:52'
updated_date: '2026-10-02 04:27'
labels:
  - content
  - web
milestone: m-0
dependencies: []
priority: low
ordinal: 50000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the task-6 review found gaps around the new category frenchNameStatus field. They don't affect the Basic bank (all 8 names are verified) but would bite a future bank with pending names, such as Advanced: (1) the importer's status rules have no negative tests; (2) common.schema.json accepts status 'verified' with fr: null; (3) the web falls back to the English name when fr is null but still tags it lang=fr-CA.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Importer tests cover pending-with-name, verified-with-null, empty string and unknown status, each failing with a clear error
- [x] #2 The JSON Schema rejects verified with a null or empty French name (oneOf/if-then), with valid and invalid fixtures
- [x] #3 When the web falls back to the English category name, the element is tagged lang=en, with a unit test
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect existing category import/schema/web handling and tests.
2. Add importer negative tests for frenchNameStatus edge cases and adjust messages only if needed.
3. Tighten common JSON Schema and add schema fixtures/tests for verified French names.
4. Update web category-name fallback language tagging and unit tests.
5. Run required validation commands, then finalize task with evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented importer negative coverage for category frenchNameStatus/name.fr combinations, tightened generatedCategory JSON Schema with oneOf status/name rules plus fixtures, and updated web category-name rendering to carry the actual fallback language.

Validation passed: pnpm typecheck; pnpm test (content-tools 95 tests, web 82 tests); pnpm build:web; pnpm import:check; pnpm check:schemas (34 schema tests, 1042 validation targets); pnpm check:links. Targeted schema/content/web tests also passed before the full run.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Hardened category French-name status handling: importer tests now reject pending names, verified null names, empty French names, and unknown statuses; generatedCategory schema now couples frenchNameStatus with name.fr using oneOf and fixture coverage; web category name rendering now tags English fallbacks as lang=en. Verified with the required pnpm commands.
<!-- SECTION:FINAL_SUMMARY:END -->
