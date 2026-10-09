---
id: TASK-13.4
title: Opt-in iCloud sync toggle
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-09 14:08'
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
- [ ] #1 project.yml adds iCloud (CloudKit), Push and Background Modes (remote notifications) only behind the non-default ICLOUD_SYNC gate; the project is regenerated with XcodeGen
- [ ] #2 Settings has an iCloud Sync toggle that defaults OFF, existing local data survives first gated split-layout launch, OFF uses explicit cloudKitDatabase .none, ON uses .private("iCloud.com.djensenius.CanadianHam") (or the confirmed ID), and preferences stay in a separate local configuration
- [ ] #3 Account-change/sign-out/iCloud-disable handler wiring is tested for no local data deletion by app code; default test configurations build without restricted entitlements, and signed-device CloudKit/account behaviours are tracked separately
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Fix review findings: preserve old single-store PreferencesEntity data when opening the gated split layout, wire ICLOUD_SYNC account-change observation, tighten gate/no-network guards, localize toggle strings, and repair platform entitlements.\n2. Add tests/follow-ups: prove old on-disk single-store data survives split .none open without destructive recovery, test account observer routing where possible, add guard negative self-tests, add task-13.5 AC for lesson-data sync gap, and create signed-device follow-up.\n3. Regenerate Xcode project twice, inspect DebugCloudKit Info.plist, run targeted/default/gated validation per review, record per-test evidence, then check ACs and mark Done last.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented gated iCloud sync: apps/apple/project.yml:12-15 defines non-default DebugCloudKit and apps/apple/project.yml:38-40 adds ICLOUD_SYNC; apps/apple/project.yml:131-135 attaches CloudKit/Push entitlements and remote-notification background mode only to DebugCloudKit. Generated apps/apple/CanadianHam.xcodeproj twice with XcodeGen and gate check passed.\nRuntime/UI: apps/apple/CanadianHam/Services/ProgressStore.swift:56-85 stores the local opt-in and chooses .none unless the build gate and opt-in are both active; apps/apple/CanadianHam/Services/ProgressStore.swift:517-565 keeps default builds local-only and gated builds split learning progress from LocalPreferences .none; apps/apple/CanadianHam/Views/StudyViews.swift:1478-1480,1555-1573 and apps/apple/CanadianHam/Views/NativeSettingsView.swift:91-100 expose the toggle only under ICLOUD_SYNC.\nTests: apps/apple/CanadianHamTests/ProgressStoreTests.swift:106-154 verifies OFF -> .none, ON+gate -> private iCloud.com.djensenius.CanadianHam, preferences .none, and ON/OFF/accountChanged/signedOut/iCloudDisabled do not delete local progress.\nValidation evidence: pnpm check:apple-icloud-gate passed; pnpm check:apple-network and pnpm test:apple-network passed; node scripts/check-apple-text-sources.ts passed; targeted iOS iCloud tests passed (2 tests); targeted reruns passed for iOS flakes testAccessibilityAuditCoreScreensLight and testAccessibilityAuditMockExamFlowDark. Full iOS default was attempted twice after the code commit: run 1 executed all tests with only testAccessibilityAuditCoreScreensLight failing from CanadianHam crash; targeted rerun passed and DiagnosticReports/CanadianHam-2026-10-09-004603.ips shows AXCodeLoader/CFLocaleCreateLocaleIdentifierFromComponents accessibility-loader crash, with no ProgressStore/ModelContainer/iCloud frames. Run 2 executed all tests with only testAccessibilityAuditMockExamFlowDark failing from com.apple.springboard crashed in SBSystemAppMain; DiagnosticReports/SpringBoard-2026-10-09-021211.ips shows SpringBoard PosterBoard/RBSAssertion snapshot crash, not app code. Supervisor approved not looping full iOS after targeted reruns. macOS default full suite passed (69 tests). iOS DebugCloudKit build passed with CODE_SIGNING_ALLOWED=NO. macOS DebugCloudKit ad-hoc build failed because restricted entitlements require a development certificate; macOS DebugCloudKit build passed with CODE_SIGNING_ALLOWED=NO.\nManual follow-up for owner: account-change/sign-out/iCloud-disable behavior still needs signed-device verification with the registered iCloud capability/container because unit tests can only verify local-data-preserving handlers without an iCloud account.

Review round 1 fixes implemented at commit 5c142ced3e0c6ab2b3aad18aa6bcd946d1cb40c3. Store split: apps/apple/CanadianHam/Services/ProgressStore.swift:549-570 opens through an injectable layout, apps/apple/CanadianHam/Services/ProgressStore.swift:706-764 snapshots legacy PreferencesEntity rows from Progress.store and copies them into Preferences.store only when the split local preferences store is empty, preserving old rows until copy succeeds. Test apps/apple/CanadianHamTests/ProgressStoreTests.swift:167-227 creates an old on-disk single-store layout and verifies split .none open preserves question progress, exam attempts, preferences, lesson progress and quiz attempts. Account wiring: apps/apple/CanadianHam/Services/ProgressStore.swift:98-114 maps account availability/signals to opt-out, and apps/apple/CanadianHam/Services/ProgressStore.swift:529-542,819-852 observes CKAccountChanged and checks CK account status at launch under ICLOUD_SYNC; test apps/apple/CanadianHamTests/ProgressStoreTests.swift:120-164 verifies account/sign-out/iCloud-disabled routing does not delete local progress.\nGuard/localization fixes: scripts/check-apple-icloud-gate.mjs:23-124 now scans all generated Debug/Release build settings and platform-specific push keys; scripts/test-check-apple-icloud-gate.mjs covers negative leaks. scripts/check-apple-no-network.sh filters only exact #if ICLOUD_SYNC branches and scans default project configs; scripts/test-check-apple-no-network.sh has negative fixtures for #else/#if ICLOUD_SYNC || DEBUG and default CloudKit config leaks. apps/apple/CanadianHam/Resources/CanadianHam.macOS.CloudKit.entitlements uses com.apple.developer.aps-environment. apps/apple/CanadianHam/Support/ICloudSyncCopy.swift:3-31 and Localizable.xcstrings carry the gated toggle/privacy strings; apps/apple/CanadianHam/Views/StudyViews.swift:1506-1514 avoids the default-build privacy contradiction. apps/apple/project.yml:132-137 uses the gated entitlements and iOS DebugCloudKit Info.plist; plutil inspection of the built DebugCloudKit iOS app showed UIBackgroundModes[0] = remote-notification.\nFollow-ups: added task-13.5 AC for moving lesson progress/quiz attempts out of PreferencesEntity into syncable learning-progress storage; created task-34 for owner signed-device checks (sign-out, account switch, iCloud disabled, CloudKit purging mirrored data) with dependency on task-13.4.\nFinal validation on commit 5c142ced3e0c6ab2b3aad18aa6bcd946d1cb40c3: pnpm check:apple-icloud-gate, pnpm test:apple-icloud-gate, pnpm check:apple-network, pnpm test:apple-network and node scripts/check-apple-text-sources.ts passed. Targeted iOS tests passed: testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal, testICloudSyncToggleAndAccountSignalsPreserveLocalProgress, testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress (3 tests, 0 failures). pnpm check:apple-l10n passed. Full default iOS passed: CanadianHamTests 68 tests + CanadianHamUITests 71 tests, 0 failures. Full default macOS passed: 70 tests, 0 failures. DebugCloudKit iOS build passed with CODE_SIGNING_ALLOWED=NO; DebugCloudKit macOS build passed with CODE_SIGNING_ALLOWED=NO; DebugCloudKit Info.plist inspection passed for remote-notification. tvOS/visionOS suites skipped because task changed only iOS/macOS CanadianHam target/project gate and no tvOS/visionOS-compiled sources.
<!-- SECTION:NOTES:END -->
