---
id: TASK-11.11
title: Negative tests for Advanced SHA256SUMS checks and Apple bundle exclusion
status: Done
assignee:
  - '@worker'
created_date: '2026-10-03 03:15'
updated_date: '2026-10-09 06:00'
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
- [x] #1 advanced-importer tests cover a malformed line, a duplicate path, a path not in the manifest, a hash mismatch and a missing manifest file, each failing with a clear error
- [x] #2 Apple bundle guard tests assert the post-task-11.5 per-platform contract: iOS/macOS app bundles contain exactly generated/basic-2025-07-15 and generated/advanced-2025-02-04, while tvOS/visionOS app bundles contain generated/basic-2025-07-15 and no generated/advanced-* directories
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add negative Advanced SHA256SUMS importer tests for malformed lines, duplicates, non-manifest paths, hash mismatches, and missing manifest entries.\n2. Add Apple bundle tests proving Basic generated content is bundled and Advanced generated content is excluded.\n3. Run targeted content-tools and Apple tests, then final affected checks.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Decision: task-11.11 AC #2 predates task-11.5. Supervisor clarified that iOS/macOS deliberately bundle Advanced for the course switcher; tvOS/visionOS remain Basic-only. Interpret and update the AC to the per-platform bundle contract rather than removing Advanced from iOS/macOS.

Implemented SHA256SUMS negatives in packages/content-tools/test/advanced-importer.test.ts:73 covering malformed line, duplicate path, non-manifest path, manifest hash mismatch, and missing manifest line. Added exact Apple generated-bank bundle guards: iOS/macOS app allow-list test in apps/apple/CanadianHamTests/QuestionBankTests.swift:6; tvOS test-bundle Basic-only guard in apps/apple/CanadianHamTVTests/CanadianHamTVTests.swift:4; visionOS test-bundle Basic-only guard in apps/apple/CanadianHamVisionTests/CanadianHamVisionTests.swift:4. Added Basic generated-copy scripts for tvOS/visionOS targets in apps/apple/project.yml:262 and apps/apple/project.yml:388. Validation passed: pnpm --filter @canadian-ham/content-tools test; XcodeGen deterministic; targeted iOS tests CanadianHamTests.QuestionBankTests/testAppBundleContainsOnlyExpectedGeneratedBankDirectories passed; full iOS passed 74 UI tests plus unit tests; full macOS unit suite passed; tvOS tests passed including CanadianHamTVTests/testBundleContainsOnlyBasicGeneratedBankDirectory; visionOS tests passed including CanadianHamVisionTests/testBundleContainsOnlyBasicGeneratedBankDirectory. Note: the exact allow-list assertions are the bundle guard; introducing an unexpected generated bank directory would make the set comparison fail.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added importer regression tests for every SHA256SUMS failure mode and Apple generated-bank bundle allow-list tests for iOS/macOS, tvOS, and visionOS under the post-task-11.5 per-platform contract. Verified with content-tools tests, deterministic XcodeGen, and full Apple platform runs.
<!-- SECTION:FINAL_SUMMARY:END -->
