---
id: TASK-86
title: App Store distribution builds with Xcode Cloud
status: To Do
assignee: []
created_date: '2026-11-03T02:32:00Z'
updated_date: '2026-11-03T02:39:00Z'
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
- [ ] #1 An App Store distribution export (method app-store-connect without testFlightInternalTestingOnly) exists alongside the internal-only one, and an export-only run through xbuild produces signed artifacts for iOS with the embedded watch app, macOS, tvOS and visionOS without uploading
- [ ] #2 Xcode Cloud ci_scripts (next to the Xcode project) run the Apple network and iCloud guards before archiving and never build DebugCloudKit, and the docs make Xcode Cloud build numbers higher than the latest uploaded timestamp build; shellcheck and a local dry run of the scripts pass
- [ ] #3 docs/release documents the Xcode Cloud workflows (archive per platform, internal and external TestFlight, App Store submission), the owner-only App Store Connect setup steps, and the TASK-1.7 and TASK-85 gates; AGENTS.md and docs/release/testflight.md are updated to match
- [ ] #4 Fastlane remains a working fallback until Xcode Cloud has archived all four platforms once, and the docs say when to retire it
<!-- AC:END -->
