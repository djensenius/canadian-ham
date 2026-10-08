---
id: TASK-11.11
title: Negative tests for Advanced SHA256SUMS checks and Apple bundle exclusion
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-03 03:15'
updated_date: '2026-10-08 12:08'
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
- [ ] #2 Apple bundle guard tests assert the post-task-11.5 per-platform contract: iOS/macOS app bundles contain exactly generated/basic-2025-07-15 and generated/advanced-2025-02-04, while tvOS/visionOS app bundles contain generated/basic-2025-07-15 and no generated/advanced-* directories
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add negative Advanced SHA256SUMS importer tests for malformed lines, duplicates, non-manifest paths, hash mismatches, and missing manifest entries.\n2. Add Apple bundle tests proving Basic generated content is bundled and Advanced generated content is excluded.\n3. Run targeted content-tools and Apple tests, then final affected checks.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Decision: task-11.11 AC #2 predates task-11.5. Supervisor clarified that iOS/macOS deliberately bundle Advanced for the course switcher; tvOS/visionOS remain Basic-only. Interpret and update the AC to the per-platform bundle contract rather than removing Advanced from iOS/macOS.
<!-- SECTION:NOTES:END -->
