---
id: TASK-26
title: Harden category French-name status checks
status: To Do
assignee: []
created_date: '2026-10-02 01:52'
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
- [ ] #1 Importer tests cover pending-with-name, verified-with-null, empty string and unknown status, each failing with a clear error
- [ ] #2 The JSON Schema rejects verified with a null or empty French name (oneOf/if-then), with valid and invalid fixtures
- [ ] #3 When the web falls back to the English category name, the element is tagged lang=en, with a unit test
<!-- AC:END -->
