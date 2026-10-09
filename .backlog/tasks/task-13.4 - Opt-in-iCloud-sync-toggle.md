---
id: TASK-13.4
title: Opt-in iCloud sync toggle
status: Done
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-09 07:29'
labels:
  - apple
  - privacy
milestone: m-1
dependencies:
  - TASK-13.3
parent_task_id: TASK-13
priority: medium
ordinal: 48000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner chose strictly opt-in sync of learning progress only (OFF by default) with an explicit container. See docs/proposals/icloud-sync.md (owner decisions in task-13 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 project.yml adds iCloud (CloudKit), Push and Background Modes (remote notifications); the project is regenerated with XcodeGen
- [x] #2 Settings has an iCloud Sync toggle that defaults OFF, using explicit cloudKitDatabase .none when off and .private("iCloud.com.djensenius.CanadianHam") (or the confirmed ID) when on; preferences stay in a separate local configuration
- [x] #3 Account change, sign-out and iCloud-disable are tested for local data loss; test configurations build without restricted entitlements (macOS ad hoc, simulators unsigned)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a non-default iCloud-gated Apple build configuration/xcconfig with ICLOUD_SYNC, gated entitlements, and a cheap CI guard that default configs have no iCloud/Push/remote-notification capabilities.\n2. Add a local-only iCloud sync preference and ProgressStore configuration selection so default/off builds use .none and gated/on builds use the private container for learning progress only.\n3. Expose the Settings toggle only under ICLOUD_SYNC on iOS/iPadOS and macOS, with tests for config selection and local-data-preserving toggle/account-change behavior.\n4. Regenerate the Xcode project, update the minimal privacy/agent docs and task notes, then run default iOS/macOS tests plus gated iOS/macOS builds per policy.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented gated iCloud sync: apps/apple/project.yml:12-15 defines non-default DebugCloudKit and apps/apple/project.yml:38-40 adds ICLOUD_SYNC; apps/apple/project.yml:131-135 attaches CloudKit/Push entitlements and remote-notification background mode only to DebugCloudKit. Generated apps/apple/CanadianHam.xcodeproj twice with XcodeGen and gate check passed.\nRuntime/UI: apps/apple/CanadianHam/Services/ProgressStore.swift:56-85 stores the local opt-in and chooses .none unless the build gate and opt-in are both active; apps/apple/CanadianHam/Services/ProgressStore.swift:517-565 keeps default builds local-only and gated builds split learning progress from LocalPreferences .none; apps/apple/CanadianHam/Views/StudyViews.swift:1478-1480,1555-1573 and apps/apple/CanadianHam/Views/NativeSettingsView.swift:91-100 expose the toggle only under ICLOUD_SYNC.\nTests: apps/apple/CanadianHamTests/ProgressStoreTests.swift:106-154 verifies OFF -> .none, ON+gate -> private iCloud.com.djensenius.CanadianHam, preferences .none, and ON/OFF/accountChanged/signedOut/iCloudDisabled do not delete local progress.\nValidation evidence: pnpm check:apple-icloud-gate passed; pnpm check:apple-network and pnpm test:apple-network passed; node scripts/check-apple-text-sources.ts passed; targeted iOS iCloud tests passed (2 tests); targeted reruns passed for iOS flakes testAccessibilityAuditCoreScreensLight and testAccessibilityAuditMockExamFlowDark. Full iOS default was attempted twice after the code commit: run 1 executed all tests with only testAccessibilityAuditCoreScreensLight failing from CanadianHam crash; targeted rerun passed and DiagnosticReports/CanadianHam-2026-10-09-004603.ips shows AXCodeLoader/CFLocaleCreateLocaleIdentifierFromComponents accessibility-loader crash, with no ProgressStore/ModelContainer/iCloud frames. Run 2 executed all tests with only testAccessibilityAuditMockExamFlowDark failing from com.apple.springboard crashed in SBSystemAppMain; DiagnosticReports/SpringBoard-2026-10-09-021211.ips shows SpringBoard PosterBoard/RBSAssertion snapshot crash, not app code. Supervisor approved not looping full iOS after targeted reruns. macOS default full suite passed (69 tests). iOS DebugCloudKit build passed with CODE_SIGNING_ALLOWED=NO. macOS DebugCloudKit ad-hoc build failed because restricted entitlements require a development certificate; macOS DebugCloudKit build passed with CODE_SIGNING_ALLOWED=NO.\nManual follow-up for owner: account-change/sign-out/iCloud-disable behavior still needs signed-device verification with the registered iCloud capability/container because unit tests can only verify local-data-preserving handlers without an iCloud account.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented the opt-in iCloud sync toggle behind the non-default DebugCloudKit/ICLOUD_SYNC gate. Default Debug/Release stay local-only with CI gate checks; gated builds add CloudKit/Push/remote-notification entitlements and Settings toggle, with OFF -> .none and ON -> .private(iCloud.com.djensenius.CanadianHam) for learning progress while preferences remain local-only. Verified with node/shell gate checks, targeted iCloud unit tests, default macOS full tests, gated iOS/macOS builds where possible, and documented iOS simulator flake diagnostics plus owner manual signed-device checks.
<!-- SECTION:FINAL_SUMMARY:END -->
