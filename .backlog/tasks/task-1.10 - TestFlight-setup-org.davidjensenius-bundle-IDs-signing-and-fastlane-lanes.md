---
id: TASK-1.10
title: 'TestFlight setup: org.davidjensenius bundle IDs, signing and fastlane lanes'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 12:40'
updated_date: '2026-10-10 14:39'
labels: []
dependencies: []
parent_task_id: TASK-1
priority: high
ordinal: 75000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner wants internal TestFlight builds now, following the Telephone Booth apps' conventions (../art/Telephone-Booth/Telephone-Booth-Operator-Mobile: universal purchase, team 9JALHNGRBQ, fastlane with the App Store Connect API key at ~/.appstoreconnect/AuthKey_XP65R4N5A2.p8). Internal testing only until task-1.7 (no external or public TestFlight).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All app targets (iOS/macOS, tvOS, visionOS) use bundle ID org.davidjensenius.CanadianHam (universal purchase), test targets use org.davidjensenius.CanadianHam.* sub-IDs, DEVELOPMENT_TEAM is 9JALHNGRBQ, ITSAppUsesNonExemptEncryption is false, and the version and build come from MARKETING_VERSION/CURRENT_PROJECT_VERSION; the project is regenerated deterministically
- [ ] #2 The gated iCloud container becomes iCloud.org.davidjensenius.CanadianHam everywhere (entitlements, code, gate check plus self-tests, docs, task notes); default builds stay iCloud-free
- [ ] #3 fastlane/ (Appfile, Fastfile) mirrors Telephone Booth's lanes (register_bundle_ids, create_app_record, asc_status, iOS and Mac beta, tvOS/visionOS beta) but archives and exports through xbuild rather than calling xcodebuild directly, and reads the API key only by path; no secrets are committed
- [ ] #4 docs/release/testflight.md runbook (setup, lanes, versioning, internal-testers-only rule); the four platform suites pass on the final code; bundle IDs are registered on the Developer Portal via the API-key lane
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Update Apple project settings for org.davidjensenius universal bundle IDs, team/signing, marketing version and encryption keys, then regenerate the Xcode project twice and verify deterministic output.
2. Replace the gated iCloud container ID everywhere in entitlements/code/docs/gate checks/self-tests and update stale com.djensenius bundle references in docs/tests/scripts.
3. Add fastlane Appfile/Fastfile plus ExportOptions plists and gitignore coverage for xbuild archive/export beta lanes and Developer Portal registration.
4. Add the TestFlight runbook, run the required guard checks, project suites, register_bundle_ids, and an iOS Release archive/export proof, then record objective evidence in Backlog and commit.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
TestFlight upload attempts: fastlane ios beta used Release, xbuild, bundle org.davidjensenius.CanadianHam, build number 202610101034 and resolved signing identity Apple Development: david jensenius (MZU6SNXU5J) plus iOS Team Provisioning Profile: *, but archive failed at CodeSign with errSecInternalComponent (xbuild exit 65). fastlane mac beta used build number 202610101036 and likewise resolved signing identity before failing at CodeSign with errSecInternalComponent. Coordinator confirmed this is environmental keychain/private-key access; uploads stopped and owner will rerun interactively. docs/release/testflight.md now has Troubleshooting guidance for unlocking keychain / Always Allow / key partition list. iOS full test suite passed: CanadianHamTests 69 tests and CanadianHamUITests 74 tests, 0 failures, log /tmp/tf-ios.log.
<!-- SECTION:NOTES:END -->
