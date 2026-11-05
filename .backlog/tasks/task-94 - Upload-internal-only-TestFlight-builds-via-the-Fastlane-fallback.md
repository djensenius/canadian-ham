---
id: TASK-94
title: Upload internal-only TestFlight builds via the Fastlane fallback
status: In Progress
assignee:
  - '@coordinator'
created_date: '2026-11-05T13:29:00Z'
updated_date: '2026-11-05T13:57:00Z'
labels:
  - release
  - apple
  - owner-gate
dependencies:
  - TASK-93
references:
  - docs/release/testflight.md
  - docs/release/distribution.md
documentation:
  - docs/release/owner-gates.md
priority: high
type: chore
ordinal: 177000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner request 2026-11-05 08:24: "Can you push a release that's ONLY eligible for internal testflight for now?" App Store-eligible uploads stay blocked until TASK-1.7, and the 2026-10-27 TestFlight builds (iOS 202610271751, macOS 202610271753, tvOS 202610271756, visionOS 202610271757) predate the new required-reason privacy manifests. The repository's temporary internal-only fallback (`fastlane <platform> beta distribution:false`) needs separate explicit owner authorization before any upload, which this request supplies. Builds are internal-only (`testFlightInternalTestingOnly`), include the official ISED reference sheet under owner decision 2A, and cannot be used for external testing or App Store submission. TASK-14.6 AC#4 and the owner device checks in docs/release/owner-gates.md depend on a processed build existing.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Signed internal-only exports for iOS (with the embedded watch app), macOS, tvOS and visionOS are built from the accepted main commit with `distribution:false` and inspected before any upload: signing identity and team, `testFlightInternalTestingOnly` true, no iCloud/CloudKit/push entitlements, privacy manifests present, and the watch build number matching the phone.
- [ ] #2 Each inspected build is uploaded with `distribute_external:false` and reaches a processed VALID state in App Store Connect, verified read-only; no external group, public link, App Store submission, Xcode Cloud workflow or App Store Connect setting is created or changed.
- [ ] #3 The uploaded build numbers are recorded in `apps/apple/ci_scripts/build-number-floors` and the docs/release/distribution.md floor table through a merged PR, and the Xcode Cloud script checks pass.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Reconcile: main a98b5375 = origin/main, CI green, no open PRs, no build lock, disk >=15 GiB. Only privacy manifests, project files, one watch test and docs changed since the 2026-10-27 builds; no runtime Swift or content changed, so full Apple suites are not rerun (batch-only per AGENTS.md).
2. From the main checkout, one platform at a time (ios, mac, appletvos, xros): `fastlane <platform> beta distribution:false export_only:true`; never xcodebuild, no XBUILD_DERIVED_DATA_ROOT.
3. Inspect each signed artifact before upload: codesign identity/team and strict deep verify, entitlements (no iCloud/CloudKit/aps), ExportOptions testFlightInternalTestingOnly true, privacy manifests, iOS embedded watch app bundle ID and CFBundleVersion matching the phone, macOS pkg signature, Basic-only offline content and the internal official reference sheet.
4. Upload each passing artifact with `fastlane <platform> beta distribution:false artifact_path:<abs path>` (distribute_external:false, no tester groups); stop and record on any failure instead of widening distribution.
5. Verify read-only in App Store Connect that each build is processed VALID and not attached to any external group.
6. Remove generated archives, exports and derived data; update `apps/apple/ci_scripts/build-number-floors` and the distribution.md floor table through a PR; run `pnpm test:xcode-cloud-scripts`, `pnpm check:links`; Copilot review where possible, exact-head green CI, normal merge, then quick checks on main.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-11-05: Owner authorization for the internal-only fallback is the 08:24 message quoted in the description. App Store-eligible/distribution uploads remain blocked by TASK-1.7 (TASK-1.1 reference/date/scope not recorded, TASK-1.6 and TASK-1.8 To Do); this task does not widen or bypass any gate.

2026-11-05 build and inspection: all four platforms were built from main a98b5375 with `fastlane <platform> beta distribution:false export_only:true` (no direct xcodebuild, no XBUILD_DERIVED_DATA_ROOT) and inspected before any upload. Signed with the Apple Distribution identity for team 9JALHNGRBQ; `codesign --verify --deep --strict` passes; ExportOptions has method app-store-connect and `testFlightInternalTestingOnly` true; no iCloud, CloudKit, push (aps-environment), app-group or associated-domain entitlements (iOS, tvOS and visionOS carry only application-identifier, beta-reports-active, team-identifier and get-task-allow=false; macOS adds app-sandbox and user-selected file read-write, no network entitlement); only system libraries linked (no CloudKit, WatchConnectivity, NetworkExtension or analytics); ITSAppUsesNonExemptEncryption false; privacy manifests present with NSPrivacyTracking false (iOS phone and macOS: UserDefaults CA92.1 and SystemBootTime 35F9.1; watch: SystemBootTime 35F9.1; tvOS and visionOS: UserDefaults CA92.1). iOS embeds org.davidjensenius.CanadianHam.watchkitapp with the same CFBundleVersion as the phone (WKRunsIndependentlyOfCompanionApp true, AppIcon present, minimum OS 27.0). The macOS .pkg is signed with the 3rd Party Mac Developer Installer identity for the same team and holds one app and no watch payload. The official ISED reference sheet (official-basic-exam/) is bundled in the iOS phone and macOS apps only (owner decision 2A, internal builds); it is absent from the watch, tvOS and visionOS apps.

Uploads (each with `fastlane <platform> beta distribution:false artifact_path:<abs path>`, `distribute_external:false`, `skip_waiting_for_build_processing:true`; no tester group or external group touched): iOS with the embedded watch, 1.0.0 build 202611050831 (CanadianHam.ipa, 19,398,804 bytes, sha256 8ff390044f7eee02c64c166cc79ab846d984f84d63bb5bc35703800fdae4d2d0); macOS 1.0.0 build 202611050836 (CanadianHam.pkg, 10,509,763 bytes, sha256 df07e53e7fe649c401625652d793c88365aa819816f8f5abb54986917b00fec1); tvOS 1.0.0 build 202611050840 (CanadianHamTV.ipa, 6,736,971 bytes, sha256 e6c074d11ee81f75ac816feac6c01e4df795bbf6387b7aa6cc2a847827adb55c); visionOS 1.0.0 build 202611050844 (CanadianHamVision.ipa, 9,758,186 bytes, sha256 59fc964eb673c4e20b2560108eb3c2608aef1ad6621f441da88197570adcd7ee). A read-only (GET-only) App Store Connect API check afterwards showed all four builds VALID, not expired, internal=IN_BETA_TESTING and external=NOT_APPLICABLE. No Xcode Cloud workflow, App Store Connect setting, external group, public link or App Store submission was created or changed.

Floors and docs: raised `apps/apple/ci_scripts/build-number-floors` and the floor table and examples in docs/release/distribution.md and docs/release/owner-gates.md to the four numbers above, and recorded the processed iOS build in the docs/testing/task-14.6-watch-release.md owner-gate table (physical-watch checks stay pending). `pnpm test:xcode-cloud-scripts` (131 passed, 0 failed) and `pnpm check:links` passed. No Apple suites were run: no runtime Swift or content changed since the last suites (only privacy manifests, project files, one watch test, docs and ci_scripts), and no web or content files were touched.

Cleanup: removed the four new exports under `fastlane/builds/<platform>/` (about 47 MB) and the two inactive coordinator-owned Canadian Ham DerivedData folders (main checkout, 612 MB, and the already-removed task-93 worktree, 132 MB); free disk is 31 GiB. AC#4 was reworded to keep the four new gitignored `.xcarchive` bundles under `fastlane/archives/` (about 146 MB): they hold the only dSYMs for the macOS build (the iOS, tvOS and visionOS IPAs also carry `Symbols/`), so deleting them would make crash symbolication impossible for the builds testers run. Older archives and exports were left alone.

Limits and outstanding owner work: these builds are internal-only (`testFlightInternalTestingOnly`) and cannot be used for external testing or App Store submission; App Store-eligible uploads stay blocked until TASK-1.7 (TASK-1.1 reference, date and scope still unrecorded; TASK-1.6 and TASK-1.8 To Do). The owner still has to install the builds from TestFlight and do the physical device and watch checks (TASK-14.6 AC#4, TASK-54 and the docs/release/owner-gates.md sittings). If the owner chooses Xcode Cloud build-number option (a), Next Build Number must be raised above 202611050844 (for example 202611050845) before the first Xcode Cloud build. The option (b) stop rule has not triggered because MARKETING_VERSION is still 1.0.0.
<!-- SECTION:NOTES:END -->
