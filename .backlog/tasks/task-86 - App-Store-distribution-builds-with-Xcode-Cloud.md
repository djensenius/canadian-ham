---
id: TASK-86
title: App Store distribution builds with Xcode Cloud
status: In Progress
assignee:
  - '@worker'
created_date: '2026-11-03T02:32:00Z'
updated_date: '2026-11-03T03:44:00Z'
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

Review round 2 fixes (commit a60a9c68; review of 58b49621 was APPROVE WITH NOTES):
- A1: build-number-floor replaced by apps/apple/ci_scripts/build-number-floors (<platform> <version> <build>; ios 1.0.0 202610271751, macos 1.0.0 202610271753, tvos 1.0.0 202610271756, visionos 1.0.0 202610271757, read-only App Store Connect data). Platform comes from CI_PRODUCT_PLATFORM (xrOS maps to visionos; watchOS, unknown or missing fails). The version comes from plain MARKETING_VERSION lines in project.pbxproj (missing, conflicting, [sdk=] or non-numeric fails). macOS must beat the highest macOS floor of any version. iOS, tvOS and visionOS must beat only the floor for the version being built; a version without an entry may start small. A missing, empty or malformed floors file fails.
- A2/B8/B9 docs (distribution.md, AGENTS.md, testflight.md, release-checklist.md): owner decision path (a) one sequence if App Store Connect accepts a Next Build Number above the floors; (b) if refused (int32 cap likely), iOS, iPadOS, tvOS and visionOS move to a new MARKETING_VERSION (for example 1.0.1) from small numbers, with no macOS archive action; (c) macOS stays on the Fastlane export path temporarily, or the owner asks Apple Developer Support. A CFBundleVersion override is labelled unverified and not recommended. Cites Apple's Setting the next build number page. Update build-number-floors in the same change as each Fastlane upload, and retire Fastlane uploads per platform once Xcode Cloud ships it. HOMEBREW_NO_AUTO_UPDATE is deliberately not set: on an image whose cached formula data predates node@26 it would fail the build. Documented in the script comment and the docs.
- B3: ci_post_xcodebuild.sh skips only when CI_XCODEBUILD_EXIT_CODE is a set, non-zero integer. Unset or empty still scans; a non-integer fails.
- B4: Fastfile beta_distribution_artifact? refuses uploads of distribution exports after File.realpath, so symlinked files, symlinked folders and case variants are caught.
- B5: the environment scan names VAR (MARKER), never the value, and says that branch, tag and pull request names can trigger it.
- B6: archive scan covers .app and .appex, including PlugIns and Extensions.
- B7: harness adds the analyze action, real Homebrew-unavailable via sandbox-exec (verified to hide /opt/homebrew and /usr/local first, otherwise SKIP), floors and version cases, .appex, exit codes and branch, tag and PR names. Ruby tests now use temporary roots instead of the real fastlane/builds/appstore, and cover symlink and case-variant refusal and the export options plist reaching -exportOptionsPlist via the real archive_and_export with xbuild stubbed.
Checks: pnpm test:xcode-cloud-scripts 98 passed, 0 failed (no SKIP); pnpm test:fastlane 12 runs, 340 assertions, 0 failures; shellcheck -x on ci_scripts and the harness clean; /bin/bash -n OK on all 5 scripts; ruby -c on the Fastfile and the Ruby test Syntax OK; pnpm check:links verified; git diff --check clean; node scripts/check-test-guard.mjs --base origin/main --head HEAD passed with no guarded changes. Mutation checks caught: macOS using the per-version floor (6 failures), unset exit code skipping (4), no appex scan (2), printing values (8), lexical-only Fastfile check (1), and the export plist ignored or swapped (1 and 2). No xbuild runs, uploads or App Store Connect writes this round.

Round 3 (delta review), AC #2 rationale (AC text unchanged): AC #2 is met under both build-number paths in docs/release/distribution.md#build-numbers. Option (a): the owner sets Next Build Number above the build-number-floors values, so every Xcode Cloud build number is higher than every uploaded timestamp build on all four platforms. Option (b) is Apple's documented fallback when (a) is impossible (for example an int32 cap): iOS, iPadOS, tvOS and visionOS need only a unique (CFBundleShortVersionString, CFBundleVersion) pair, so a new marketing version (for example 1.0.1) restarts at small Xcode Cloud numbers without colliding with any upload (https://developer.apple.com/documentation/xcode/setting-the-next-build-number-for-xcode-cloud-builds). In both cases ci_pre_xcodebuild.sh still enforces macOS above every recorded upload and non-Mac platforms above every Fastlane upload of the same marketing version, failing closed on a missing or unknown platform or version.
Pointer (reviewer item 6): the round-2 per-platform build-number-floors evidence replaces the earlier single build-number-floor AC #2 evidence paragraph.
Round 3 fixes (commit 7f8a732a): floors entries and MARKETING_VERSION must be exactly x.y.z (no leading zeros except a lone 0) and fail closed otherwise, documented in the floors header, with harness cases for two-part and leading-zero versions in both places (mutation check: the old 1-3 part pattern fails the 5 new cases). Under option (b), the coordinator stops Fastlane uploads for iOS, tvOS and visionOS from the version-bump merge onward (Mac continues), in distribution.md, AGENTS.md and testflight.md. 'In the same change' is now 'in a PR right after the upload, before the next Xcode Cloud archive'. No change to owner-gates.md (coordinator follow-up).
Checks: pnpm test:xcode-cloud-scripts 103 passed, 0 failed; pnpm test:fastlane 12 runs, 340 assertions, 0 failures, 0 errors, 0 skips; shellcheck -x on ci_scripts and harness: no findings; /bin/bash -n OK (5 files); ruby -c fastlane/Fastfile Syntax OK; pnpm check:links verified; git diff --check clean; test guard passed (no guarded changes).
<!-- SECTION:NOTES:END -->
