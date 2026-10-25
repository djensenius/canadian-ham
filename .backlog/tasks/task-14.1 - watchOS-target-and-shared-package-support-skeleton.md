---
id: TASK-14.1
title: watchOS target and shared-package support skeleton
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T17:01:00Z'
updated_date: '2026-10-25T17:20:00Z'
labels:
  - apple
  - watchos
milestone: m-1
dependencies: []
documentation:
  - docs/proposals/watchos-companion.md
parent_task_id: TASK-14
type: feature
ordinal: 155000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner approved the watch companion on 2026-10-25. Before feature work, prove the three existing local Swift packages and a minimal independently usable SwiftUI app can run on watchOS 27. Current package manifests omit watchOS; no watch target exists. The proposal recommends a watch app embedded in the existing iOS distribution container, without app-level pairing or WatchConnectivity. This task establishes compatibility and distribution structure only, not practice features.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 CanadianHamWatch is a watchOS 27 XcodeGen app target and shared scheme with watch-specific source/resource membership, CanadianHamWatchTests and CanadianHamWatchUITests; project.yml and the generated project are committed and regeneration is deterministic.
- [ ] #2 engine-swift, content-swift and morse-swift explicitly support watchOS 27, compile for the watch simulator, and have relevant package tests passing; existing platform support is preserved and affected-platform merge-batch checks are identified.
- [ ] #3 The minimal app launches and passes a unit smoke test and a UI launch/navigation smoke test via DEVELOPER_DIR-prefixed xbuild using one installed watchOS 27 simulator; exact destination and per-test results are recorded.
- [ ] #4 The watch bundle identifier org.davidjensenius.CanadianHam.watchkitapp and independent-operation embedding are validated in an iOS-container build; no phone-app setup, application pairing or WatchConnectivity is needed for watch launch.
- [ ] #5 Default Debug/Release and the watch target in DebugCloudKit contain no cloud/push capability, network code, third-party SDKs or background networking; the watch privacy manifest declares no tracking/collected data, and network/iCloud guards pass with watch membership covered.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect package platform boundaries, XcodeGen target patterns and privacy guards.
2. Add explicit watchOS package support, an independent embedded SwiftUI placeholder app, localized watch resources and unit/UI smoke targets. Extend guard coverage and regenerate the project twice.
3. Commit the implementation, then run targeted watch smoke, package tests, iOS container build-for-testing, full macOS unit target, tvOS/visionOS builds and localization/privacy/test-guard checks with logged destinations/results.
4. Record acceptance evidence, mark Done, commit and push the task branch without opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation committed as 541b0b64. XcodeGen generated an iOS-filtered PBXTargetDependency and Embed Watch Content build phase automatically; macOS membership is filtered out. All three shared packages contain only Foundation/os code, so no source platform guards were necessary; the iOS Core Haptics driver is not in watch target membership. Shared Localizable.xcstrings reuses EN/FR translations, adding only Alphabet. Watch privacy is explicit in its own manifest. Initial guard checks and regression fixtures pass; XcodeGen second-run PBX/scheme SHA-1 hashes are identical.
Validation runner: /tmp/task-14.1-checks.sh, summary /tmp/task-14.1-checks.log and per-command /tmp/task-14.1-<name>.log. Watch targeted smoke is queued behind the shared xbuild lock (TASK-29 lane); no competing build was interrupted. Full suites are not requested/run, except the explicitly required full macOS unit target. Affected merge-batch platforms: iOS/macOS/tvOS/visionOS (shared package support) and new watchOS.

Watch smoke (3 unit + 2 EN/FR UI) and all 53 package tests passed; iOS container build-for-testing validated the embedded watch bundle with ValidateEmbeddedBinary; full macOS unit target passed 223 tests, zero failures. Localization export and all generic tvOS/visionOS/watch builds compiled, but the final XLIFF check found two new untranslated generated watch bundle metadata keys. Added French/fr-CA metadata resources following existing platform patterns, regenerated twice with identical hashes, and committed the fix. Re-running only localization and watch smoke for this resource-membership fix; no unchanged full suite repeats.
<!-- SECTION:NOTES:END -->
