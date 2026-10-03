---
id: TASK-11.11
title: Negative tests for Advanced SHA256SUMS checks and Apple bundle exclusion
status: To Do
assignee: []
created_date: '2026-10-03 03:15'
labels:
  - content
  - apple
milestone: m-1
dependencies:
  - TASK-11.4
parent_task_id: TASK-11
priority: low
ordinal: 57000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the task-11.4 re-review found two checks without regression tests: the importer's per-line SHA256SUMS verification (format, duplicates, manifest membership, hash mismatch, missing lines) has only the passing real-bank import, and the exclusion of generated/advanced-* from the Apple app bundles is only verified by hand, so a future project.yml edit could bring the Advanced text back into the app.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 advanced-importer tests cover a malformed line, a duplicate path, a path not in the manifest, a hash mismatch and a missing manifest file, each failing with a clear error
- [ ] #2 An Apple unit test asserts generated/basic-2025-07-15 is in the bundle and generated/advanced-* is not, passing in the iOS and macOS xbuild suites
<!-- AC:END -->
