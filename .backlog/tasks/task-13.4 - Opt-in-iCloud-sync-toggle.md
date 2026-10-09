---
id: TASK-13.4
title: Opt-in iCloud sync toggle
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-09 07:36'
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
- [ ] #2 Settings has an iCloud Sync toggle that defaults OFF, using explicit cloudKitDatabase .none when off and .private("iCloud.com.djensenius.CanadianHam") (or the confirmed ID) when on; preferences stay in a separate local configuration
- [ ] #3 Account change, sign-out and iCloud-disable are tested for local data loss; test configurations build without restricted entitlements (macOS ad hoc, simulators unsigned)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Fix review findings: preserve old single-store PreferencesEntity data when opening the gated split layout, wire ICLOUD_SYNC account-change observation, tighten gate/no-network guards, localize toggle strings, and repair platform entitlements.\n2. Add tests/follow-ups: prove old on-disk single-store data survives split .none open without destructive recovery, test account observer routing where possible, add guard negative self-tests, add task-13.5 AC for lesson-data sync gap, and create signed-device follow-up.\n3. Regenerate Xcode project twice, inspect DebugCloudKit Info.plist, run targeted/default/gated validation per review, record per-test evidence, then check ACs and mark Done last.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented gated iCloud sync: apps/apple/project.yml:12-15 defines non-default DebugCloudKit and apps/apple/project.yml:38-40 adds ICLOUD_SYNC; apps/apple/project.yml:131-135 attaches CloudKit/Push entitlements and remote-notification background mode only to DebugCloudKit. Generated apps/apple/CanadianHam.xcodeproj twice with XcodeGen and gate check passed.\nRuntime/UI: apps/apple/CanadianHam/Services/ProgressStore.swift:56-85 stores the local opt-in and chooses .none unless the build gate and opt-in are both active; apps/apple/CanadianHam/Services/ProgressStore.swift:517-565 keeps default builds local-only and gated builds split learning progress from LocalPreferences .none; apps/apple/CanadianHam/Views/StudyViews.swift:1478-1480,1555-1573 and apps/apple/CanadianHam/Views/NativeSettingsView.swift:91-100 expose the toggle only under ICLOUD_SYNC.\nTests: apps/apple/CanadianHamTests/ProgressStoreTests.swift:106-154 verifies OFF -> .none, ON+gate -> private iCloud.com.djensenius.CanadianHam, preferences .none, and ON/OFF/accountChanged/signedOut/iCloudDisabled do not delete local progress.\nValidation evidence: pnpm check:apple-icloud-gate passed; pnpm check:apple-network and pnpm test:apple-network passed; node scripts/check-apple-text-sources.ts passed; targeted iOS iCloud tests passed (2 tests); targeted reruns passed for iOS flakes testAccessibilityAuditCoreScreensLight and testAccessibilityAuditMockExamFlowDark. Full iOS default was attempted twice after the code commit: run 1 executed all tests with only testAccessibilityAuditCoreScreensLight failing from CanadianHam crash; targeted rerun passed and DiagnosticReports/CanadianHam-2026-10-09-004603.ips shows AXCodeLoader/CFLocaleCreateLocaleIdentifierFromComponents accessibility-loader crash, with no ProgressStore/ModelContainer/iCloud frames. Run 2 executed all tests with only testAccessibilityAuditMockExamFlowDark failing from com.apple.springboard crashed in SBSystemAppMain; DiagnosticReports/SpringBoard-2026-10-09-021211.ips shows SpringBoard PosterBoard/RBSAssertion snapshot crash, not app code. Supervisor approved not looping full iOS after targeted reruns. macOS default full suite passed (69 tests). iOS DebugCloudKit build passed with CODE_SIGNING_ALLOWED=NO. macOS DebugCloudKit ad-hoc build failed because restricted entitlements require a development certificate; macOS DebugCloudKit build passed with CODE_SIGNING_ALLOWED=NO.\nManual follow-up for owner: account-change/sign-out/iCloud-disable behavior still needs signed-device verification with the registered iCloud capability/container because unit tests can only verify local-data-preserving handlers without an iCloud account.
<!-- SECTION:NOTES:END -->
