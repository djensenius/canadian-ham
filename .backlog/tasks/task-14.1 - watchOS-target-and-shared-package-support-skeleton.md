---
id: TASK-14.1
title: watchOS target and shared-package support skeleton
status: Done
assignee:
  - '@worker'
created_date: '2026-10-25T17:01:00Z'
updated_date: '2026-10-25T17:50:00Z'
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

APPROVED REVIEW NOTES FIXED: implementation commit 126fce65fa264e1423c45324871ee93d758a123d adds an opaque 1024px existing-art watch AppIcon (circular preview checked), export_only:true for upload_beta with 3 Ruby safety tests/27 assertions, WKBackgroundModes smoke/guard coverage, exact 9-block watch configuration assertion with failure fixtures, UI existence-before-hittability ordering, run-specific commit provenance and watch build/test policy. TASK-14.6 notes preserve icon refinement/hardware/internal upload gates. All reruns used this exact unchanged commit: 5 watch smoke + full 223 macOS unit tests passed; iOS build-for-testing passed; pnpm check:apple-l10n passed including tvOS, visionOS and watchOS simulator builds; privacy/iCloud guards and fixtures, test guard/self-test, Ruby tests/syntax passed. XcodeGen twice before commit had identical hashes; twice after all checks gave empty generated-project diff. Updated evidence doc includes all 228 review-round individual passing test results and destinations/result bundles.

SIGNED EXPORT PROOF, NO UPLOAD: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer FASTLANE_SKIP_UPDATE_CHECK=1 fastlane ios beta export_only:true and fastlane mac beta export_only:true both archived/exported successfully on 126fce65 using the existing dedicated build keychain/API key. No other keychain/password handled. IPA: /Users/david/Developer/canadian-ham-task-14.1/fastlane/builds/ios/202610251346/CanadianHam.ipa; archive: fastlane/archives/ios/CanadianHam-202610251346.xcarchive. IPA contains Payload/CanadianHam.app/Watch/CanadianHamWatch.app, ID org.davidjensenius.CanadianHam.watchkitapp, WKApplication/independent operation true, matching phone/watch 1.0.0/202610251346, Assets.car (154392 bytes) with 1024px AppIcon rendition and embedded.mobileprovision with matching application identifier. codesign -dv: Apple Distribution: david jensenius (9JALHNGRBQ), chain WWDR/Apple Root CA, TeamIdentifier 9JALHNGRBQ; deep/strict verification exit0 for watch and phone. Both background-mode keys absent; signed entitlements have no iCloud/push; privacy manifest no tracking/data. PKG: /Users/david/Developer/canadian-ham-task-14.1/fastlane/builds/mac/202610251347/CanadianHam.pkg; archive: fastlane/archives/mac/CanadianHam-202610251347.xcarchive. pkgutil signature check passed (Mac Installer Distribution team 9JALHNGRBQ); full expansion contains one MacOSX CanadianHam.app and zero watch directories/apps/watchkit files, app signature verifies. Both fastlane logs explicitly skip upload; no upload_to_testflight step. No PR or TestFlight upload created. Full evidence: docs/testing/task-14.1-watchos-skeleton.md; runner /tmp/task-14.1-review-checks.log; inspection /tmp/task-14.1-review-ipa-inspection.log and /tmp/task-14.1-review-mac-inspection.log. Physical watch/ASC processing and full affected-platform merge-batch suites remain coordinator/later-task gates.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented the watchOS27 independent embedded skeleton and all approved internal-review notes: explicit shared-package support, localized placeholder navigation, privacy/test targets, a real opaque watch icon, stricter watch background/configuration guards and export-only beta validation without uploads. Immutable review-run commit 126fce65fa264e1423c45324871ee93d758a123d passed 5 watch smoke + 223 full macOS unit tests, iOS build-for-testing, tvOS/visionOS/watch builds, l10n and all guard/self-tests plus 3 fastlane tests. Both iOS/macOS signed archive/exports passed; IPA contains a correctly signed/provisioned/icon-bearing watch app, macOS pkg has none. Per-test/signature/artifact evidence: docs/testing/task-14.1-watchos-skeleton.md. No PR or upload; TASK-14.6 retains final icon refinement, ASC processing and physical-watch install.
<!-- SECTION:FINAL_SUMMARY:END -->
