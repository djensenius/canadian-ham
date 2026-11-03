---
id: TASK-86
title: App Store distribution builds with Xcode Cloud
status: In Progress
assignee:
  - '@worker'
created_date: '2026-11-03T02:32:00Z'
updated_date: '2026-11-03T03:10:00Z'
labels:
  - apple
  - release
  - ci
milestone: m-0
dependencies: []
priority: high
type: feature
ordinal: 169000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Current Apple builds can only reach internal TestFlight: fastlane/ExportOptions.plist sets testFlightInternalTestingOnly and the lanes only upload internal betas. The owner wants builds that can go to external TestFlight and the App Store for every platform (iOS/iPadOS with the embedded watch app, macOS, tvOS, visionOS) and prefers Xcode Cloud to Fastlane. Make App Store distribution builds possible and documented without uploading or submitting anything. Uploads, external testing and App Store submission stay behind TASK-1.7 and the release checklist, and TASK-85 (required-reason API declarations) must land before any App Store Connect upload of a distribution build. Xcode Cloud assigns build numbers from CI_BUILD_NUMBER and its next-build-number setting, while builds already uploaded by Fastlane use 12-digit timestamps (fastlane/Fastfile build_number).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 An App Store distribution export (method app-store-connect without testFlightInternalTestingOnly) exists alongside the internal-only one, and an export-only run through xbuild produces signed artifacts for iOS with the embedded watch app, macOS, tvOS and visionOS without uploading
- [x] #2 Xcode Cloud ci_scripts (next to the Xcode project) run the Apple network and iCloud guards before archiving and never build DebugCloudKit, and the docs make Xcode Cloud build numbers higher than the latest uploaded timestamp build; shellcheck and a local dry run of the scripts pass
- [x] #3 docs/release documents the Xcode Cloud workflows (archive per platform, internal and external TestFlight, App Store submission), the owner-only App Store Connect setup steps, and the TASK-1.7 and TASK-85 gates; AGENTS.md and docs/release/testflight.md are updated to match
- [x] #4 Fastlane remains a working fallback until Xcode Cloud has archived all four platforms once, and the docs say when to retire it
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add fastlane/ExportOptions-AppStore.plist (app-store-connect, automatic signing, no testFlightInternalTestingOnly) and a fail-safe Fastfile beta option distribution:true that selects it, archives without the internal-only OFFICIAL_REFERENCE_SHEET opt-in, writes to separate appstore archive/export dirs and is export-only until TASK-1.7/TASK-85 clear; default stays internal. Extend scripts/test-fastlane-export-only.rb.
2. Add apps/apple/ci_scripts (ci_post_clone.sh, ci_pre_xcodebuild.sh, ci_post_xcodebuild.sh + shared helper): locate/install pinned Node via Homebrew, run the package.json Apple network and iCloud guards (fail closed), reject archives of non-allowlisted schemes or schemes whose ArchiveAction is not Release (DebugCloudKit), require CI_BUILD_NUMBER above a committed floor, inspect the archive for iCloud/push entitlements. Add a dry-run harness with simulated CI_* env (archive, non-archive, DebugCloudKit rejection, guard failure). Run shellcheck and the dry runs.
3. Export-only distribution runs for ios, mac, appletvos, xros one at a time via fastlane export_only:true distribution:true; verify codesign, entitlements (no iCloud/push/aps), watch embedded in iOS IPA, no internal-only flag, no official sheet.
4. Docs: docs/release/distribution.md (Xcode Cloud workflows per platform, owner-only ASC setup, build numbers, TASK-1.7/TASK-85 gates, Fastlane retirement); update AGENTS.md TestFlight section, docs/release/testflight.md and release-checklist.md links.
5. Validation: shellcheck, dry runs, pnpm typecheck, pnpm check:apple-network, pnpm check:apple-icloud-gate, pnpm test:fastlane, ruby -c, plutil -lint; record evidence in notes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation commit acdc3998 (worker, 2026-11-02).

AC1 evidence: fastlane/ExportOptions-AppStore.plist (app-store-connect, automatic, team 9JALHNGRBQ, manageAppVersionAndBuildNumber false, no testFlightInternalTestingOnly) + Fastfile beta option distribution:true (requires export_only:true; appstore/ archive+build folders; no OFFICIAL_REFERENCE_SHEET opt-in; refuses upload of fastlane/builds/appstore artifacts). Export-only runs via xbuild, one at a time, no upload:
- iOS 202611022152: fastlane/builds/appstore/ios/202611022152/CanadianHam.ipa. App and Watch/CanadianHamWatch.app signed Apple Distribution: david jensenius (9JALHNGRBQ), codesign --verify --deep --strict OK, entitlements only application-identifier/team-identifier/beta-reports-active/get-task-allow=false, iOS Team Store profile without devices, CFBundleVersion 202611022152 on app and watch, PrivacyInfo.xcprivacy present, no official-basic-exam.
- macOS 202611022154: CanadianHam.pkg signed 3rd Party Mac Developer Installer (9JALHNGRBQ); app Apple Distribution, Mac Team Store profile, entitlements app-sandbox + files.user-selected.read-write + application-identifier/team-identifier only, verify OK, no watch, no official sheet.
- tvOS 202611022156: CanadianHamTV.ipa Apple Distribution, tvOS Team Store profile, entitlements as iOS, verify OK, privacy manifest present.
- visionOS 202611022159: CanadianHamVision.ipa Apple Distribution, Team Store profile, entitlements as iOS, verify OK, privacy manifest present.
All four exports' ExportOptions.plist show method app-store-connect, testFlightInternalTestingOnly => false; no iCloud/ubiquity/aps-environment entitlements anywhere.

AC2 evidence: apps/apple/ci_scripts/{ci_post_clone,ci_pre_xcodebuild,ci_post_xcodebuild}.sh + canadian-ham-ci.sh + build-number-floor (202610271757, newest Fastlane upload found in local worktrees). shellcheck 0.11.0 -x clean; /bin/bash 3.2 -n OK. pnpm test:xcode-cloud-scripts: 48 passed, 0 failed (real guards on repo; archive iOS/macOS/tvOS/visionOS/xrOS; DebugCloudKit scheme and CONFIGURATION rejection; watch scheme/platform mismatch; ICLOUD_SYNC/CloudKit entitlements/OFFICIAL_REFERENCE_SHEET env overrides; build numbers 1, floor, non-integer, missing; failing and missing guards; Node discovery via stub brew only; ad-hoc signed fake archives with push/iCloud/official sheet/unsigned). Mutation check: disabling the floor and Release checks made 3 cases fail. ci_post_xcodebuild.sh passes on all four real distribution archives (iOS checked 2 apps incl. watch). Build numbers: docs/release/distribution.md has the owner set Xcode Cloud Next Build Number to date +%Y%m%d%H%M or later, and raise it plus the floor after Fastlane uploads. Real Xcode Cloud run remains an owner gate.

Other checks: local xbuild Release build of CanadianHam for generic/platform=macOS without SDKROOT/SUPPORTED_PLATFORMS overrides (CODE_SIGNING_ALLOWED=NO, -derivedDataPath /tmp/ch-task86-dd) BUILD SUCCEEDED, product platform MACOS minos 27.0, no watch app; so Xcode Cloud macOS archives should not need project changes. pnpm typecheck OK; pnpm test OK; pnpm check:links OK; pnpm check:apple-network/test:apple-network/check:apple-icloud-gate/test:apple-icloud-gate OK; pnpm test:fastlane 9 runs, 179 assertions, 0 failures; ruby -c Fastfile Syntax OK; plutil -lint both plists OK; node scripts/check-test-guard.mjs --base 4067a86c passed.

Open: App Store Connect acceptance of a 12-digit Next Build Number is untested (Mac builds can't go below 202610271757); visionOS CI_PRODUCT_PLATFORM value is undocumented (scripts accept visionOS/xrOS and fail closed otherwise); Xcode Cloud internal builds never include the internal-only official sheet.

AC2 checked on local criteria only (scripts, shellcheck, dry run, docs). The first real Xcode Cloud run for all four platforms is an owner gate and is not verified. Task left In Progress for coordinator review.
<!-- SECTION:NOTES:END -->
