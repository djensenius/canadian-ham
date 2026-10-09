---
id: TASK-11.11
title: Negative tests for Advanced SHA256SUMS checks and Apple bundle exclusion
status: Done
assignee:
  - '@worker'
created_date: '2026-10-03 03:15'
updated_date: '2026-10-09 10:25'
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

Review round 1 reopened task-11.11: Apple tvOS/visionOS bundle guard must inspect app bundle, copy-script duplication must be removed, and guard-bites evidence must be recorded for bundle guards and SHA256SUMS negatives.

Review fixes: tvOS/visionOS bundle guards now inspect the built app bundles via Bundle(url:) next to the .xctest bundle (apps/apple/CanadianHamTVTests/CanadianHamTVTests.swift:4, apps/apple/CanadianHamVisionTests/CanadianHamVisionTests.swift:4). Removed the duplicate generated-copy scripts from tvOS/visionOS app/test targets; XcodeGen was run twice and apps/apple/CanadianHam.xcodeproj stayed stable. Guard-bites evidence: disabling validateSha256Sums made all five Advanced SHA256SUMS negative tests fail with Missing expected rejection in /tmp/advanced-sha-guard-fail.log. Adding a stale generated/stale-bank directory made iOS and macOS QuestionBankTests/testAppBundleContainsOnlyExpectedGeneratedBankDirectories fail with the extra stale-bank in /tmp/advanced-guard-ios-fail.log and /tmp/advanced-guard-macos-fail.log. Adding Advanced generated resources to tvOS/visionOS app targets made CanadianHamTVTests/testAppBundleContainsOnlyBasicQuestionBankResources and CanadianHamVisionTests/testAppBundleContainsOnlyBasicQuestionBankResources fail in /tmp/advanced-guard-tvos-fail.log and /tmp/advanced-guard-visionos-fail.log. A first full iOS run in review work previously hit a transient SpringBoard crash in testAccessibilityAuditPracticeSessionDark; targeted rerun passed, and final full iOS on code commit 8044afbf33ae76222dec781f32b8b0867bd242df passed.

Final validation on code commit 8044afbf33ae76222dec781f32b8b0867bd242df: targeted iOS bundle/course-switch run passed; full iOS passed CanadianHamTests 66 tests and CanadianHamUITests 74 tests; full macOS passed 68 CanadianHamTests; full tvOS clean rerun passed CanadianHamTVTests 4 tests and CanadianHamTVUITests 12 tests; full visionOS clean rerun passed CanadianHamVisionTests 4 tests and CanadianHamVisionUITests 9 tests. The first tvOS full after deliberate guard-bites failed because stale DerivedData still contained the deliberately injected generated/basic directory; clean xbuild rerun on the same code commit passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed review findings by moving tvOS/visionOS bundle guards to the app bundles, removing duplicate generated-copy scripts, proving SHA256SUMS and all Apple bundle guards fail under deliberate local breaks, and rerunning final Apple platform validation on commit 8044afbf33ae76222dec781f32b8b0867bd242df.
<!-- SECTION:FINAL_SUMMARY:END -->
