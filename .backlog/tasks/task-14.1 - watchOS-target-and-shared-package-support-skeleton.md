---
id: TASK-14.1
title: watchOS target and shared-package support skeleton
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T17:01:00Z'
updated_date: '2026-10-25T17:40:00Z'
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
- [x] #1 CanadianHamWatch is a watchOS 27 XcodeGen app target and shared scheme with watch-specific source/resource membership, CanadianHamWatchTests and CanadianHamWatchUITests; project.yml and the generated project are committed and regeneration is deterministic.
- [x] #2 engine-swift, content-swift and morse-swift explicitly support watchOS 27, compile for the watch simulator, and have relevant package tests passing; existing platform support is preserved and affected-platform merge-batch checks are identified.
- [x] #3 The minimal app launches and passes a unit smoke test and a UI launch/navigation smoke test via DEVELOPER_DIR-prefixed xbuild using one installed watchOS 27 simulator; exact destination and per-test results are recorded.
- [x] #4 The watch bundle identifier org.davidjensenius.CanadianHam.watchkitapp and independent-operation embedding are validated in an iOS-container build; no phone-app setup, application pairing or WatchConnectivity is needed for watch launch.
- [x] #5 Default Debug/Release and the watch target in DebugCloudKit contain no cloud/push capability, network code, third-party SDKs or background networking; the watch privacy manifest declares no tracking/collected data, and network/iCloud guards pass with watch membership covered.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect package platform boundaries, XcodeGen target patterns and privacy guards.
2. Add explicit watchOS package support, an independent embedded SwiftUI placeholder app, localized watch resources and unit/UI smoke targets. Extend guard coverage and regenerate the project twice.
3. Commit the implementation, then run targeted watch smoke, package tests, iOS container build-for-testing, full macOS unit target, tvOS/visionOS builds and localization/privacy/test-guard checks with logged destinations/results.
4. Record acceptance evidence, mark Done, commit and push the task branch without opening a PR.

5. Address approved review notes: add existing-family opaque watch AppIcon, export-only beta safety path, watch background-mode/count regression checks, UI wait ordering and concise build policy. Regenerate twice; commit fixes before running watch smoke, full macOS unit, iOS build-for-testing, l10n/platform builds and guards. Archive/export iOS and macOS without upload using the dedicated keychain; inspect artifact payloads/signatures and record run-specific commit evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation committed as 541b0b64. XcodeGen generated an iOS-filtered PBXTargetDependency and Embed Watch Content build phase automatically; macOS membership is filtered out. All three shared packages contain only Foundation/os code, so no source platform guards were necessary; the iOS Core Haptics driver is not in watch target membership. Shared Localizable.xcstrings reuses EN/FR translations, adding only Alphabet. Watch privacy is explicit in its own manifest. Initial guard checks and regression fixtures pass; XcodeGen second-run PBX/scheme SHA-1 hashes are identical.
Validation runner: /tmp/task-14.1-checks.sh, summary /tmp/task-14.1-checks.log and per-command /tmp/task-14.1-<name>.log. Watch targeted smoke is queued behind the shared xbuild lock (TASK-29 lane); no competing build was interrupted. Full suites are not requested/run, except the explicitly required full macOS unit target. Affected merge-batch platforms: iOS/macOS/tvOS/visionOS (shared package support) and new watchOS.

Watch smoke (3 unit + 2 EN/FR UI) and all 53 package tests passed; iOS container build-for-testing validated the embedded watch bundle with ValidateEmbeddedBinary; full macOS unit target passed 223 tests, zero failures. Localization export and all generic tvOS/visionOS/watch builds compiled, but the final XLIFF check found two new untranslated generated watch bundle metadata keys. Added French/fr-CA metadata resources following existing platform patterns, regenerated twice with identical hashes, and committed the fix. Re-running only localization and watch smoke for this resource-membership fix; no unchanged full suite repeats.

Localization refinement: legacy per-product InfoPlist.strings were bundled correctly but Xcode exported synthetic watch metadata at en.lproj without matching the watch French files. Replaced only watch metadata with a dedicated InfoPlist.xcstrings (EN/fr/fr-CA); an isolated xbuild localization export confirmed every metadata key now has a French target. UI continues to share Localizable.xcstrings. A final full localization check plus targeted watch smoke and iOS container rebuild are queued. Resolved DebugCloudKit watch build settings show SDK WatchSimulator27.0, supported watchos/watchsimulator, only DEBUG in compilation conditions, no OTHER_SWIFT_FLAGS/cloud capabilities.

FINAL ACCEPTANCE EVIDENCE: docs/testing/task-14.1-watchos-skeleton.md records exact commands/destinations and all 281 individual passing test results (watch 3 unit + 2 UI; macOS unit 223; engine/content/Morse package tests 22/27/4), plus result-bundle paths, log names, decoded final embedded-bundle metadata/privacy, iteration failures and remaining release/hardware gates.
AC1: final project.yml, PBX project and shared scheme committed; final two XcodeGen runs followed by git diff --exit-code -- apps/apple/CanadianHam.xcodeproj passed empty. AC2: all three manifests explicitly support watchOS27; watch simulator compiles all packages and package tests pass; unchanged iOS/macOS/tvOS/visionOS compatibility validated; affected merge-batch platforms listed. AC3: final watch run on platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0 passed testIndependentOfflineBundle, testPlannedSections, testSharedPackagesOnWatch, testLaunchAndNavigateEnglish and testLaunchAndNavigateFrench. AC4: final iPhone17Pro build-for-testing passed including Copy and ValidateEmbeddedBinary for the watch payload; plist confirms org.davidjensenius.CanadianHam.watchkitapp, WKApplication and WKRunsIndependentlyOfCompanionApp true. AC5: final network/iCloud guards and regression fixtures pass; resolved watch DebugCloudKit has only DEBUG, no cloud/push flags/entitlements, no background modes; own privacy manifest has no tracking/collected data.
Final pnpm check:apple-l10n passed at 17:32:59 UTC, including generic tvOS/visionOS/watch builds, text-source self-test, complete French export and unchanged shared UI/watch metadata catalogues. Final test guard passed with no guarded changes. One intermediate l10n run exited127 because its shell script was edited during export; the final unchanged-script run fully passed. Full iOS/tvOS/visionOS suites were intentionally skipped (targeted builds only); only the requested full macOS unit target ran. All nohup runners exited, no other build was killed. No archive/signing upload, TestFlight distribution, phone pairing/sync or practice functionality added.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented the watchOS27 skeleton: independent SwiftUI watch app with EN/FR Practice/Morse/Alphabet placeholder navigation, watch unit/UI targets and shared scheme, iOS-only embedding, explicit watch privacy manifest, package platform support and watch-aware privacy/localization guards. Final validation: 5 watch smoke + 53 package + 223 macOS unit tests passed; iOS container, tvOS/visionOS/watch builds, localization/text/privacy/test guards and deterministic regeneration passed. Full per-test evidence: docs/testing/task-14.1-watchos-skeleton.md. Signing/icon/hardware/features remain their approved later subtasks; all five acceptance criteria proven.
<!-- SECTION:FINAL_SUMMARY:END -->
