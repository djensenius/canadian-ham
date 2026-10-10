---
id: TASK-1.10
title: 'TestFlight setup: org.davidjensenius bundle IDs, signing and fastlane lanes'
status: To Do
assignee: []
created_date: '2026-10-10 12:40'
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
