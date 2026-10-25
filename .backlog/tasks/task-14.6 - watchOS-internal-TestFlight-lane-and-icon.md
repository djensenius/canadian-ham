---
id: TASK-14.6
title: watchOS internal TestFlight lane and icon
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T17:02:00Z'
updated_date: '2026-10-25T22:32:00Z'
labels:
  - apple
  - watchos
  - release
milestone: m-1
dependencies:
  - TASK-14.5
references:
  - docs/release/testflight.md
documentation:
  - docs/proposals/watchos-companion.md
parent_task_id: TASK-14
type: feature
ordinal: 160000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The watch app needs a release-quality icon and a reproducible internal delivery path, not a separate unverified watchOS App Store Connect upload assumption. The proposal recommends independent watch operation with the payload embedded in the existing iOS container. Extend the current xbuild-only fastlane/keychain workflow while preserving all four existing beta platforms and the private/internal-only licensing gate. No external release or distribution broadening is approved.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The watch app has a valid watch AppIcon derived from the existing icon family, safe under circular masking at small sizes, with visual review evidence; bundle ID/signing and any icon variants required by the current watch SDK validate without warnings or missing assets.
- [ ] #2 A documented fastlane beta entry path archives/exports the iOS container containing CanadianHamWatch through xbuild only, using the dedicated build keychain and matching timestamp build numbers. The existing ios beta includes the watch payload, other platform lanes still work, and no separate unsupported ASC watchOS platform is invented.
- [ ] #3 Release artifacts are inspected to verify the watch payload, correct bundle IDs/icon/privacy manifest, Basic-only offline content, and absence of cloud/push, WatchConnectivity, networking/telemetry SDKs and unused lesson/hint/Advanced resources; network/iCloud guards pass.
- [ ] #4 After review/merge approval, an internal-team-only TestFlight upload is processed and installation on a physical watch verifies quick practice, Morse, reference and EN/FR without the phone app or network. Results and build IDs are recorded; no external group, public link or App Store submission is created before TASK-1.7/licensing approval.
- [ ] #5 docs/release/testflight.md, privacy-label evidence and the release checklist cover the watch payload, Data Not Collected, signing/install steps and manual hardware checks; the simulator build/test command and targeted per-test results are recorded before upload.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review existing watch icon under circular masks at 1024/196/88/48 px; refine only if needed and retain before/after evidence.
2. Document the existing iOS-container beta path, signing/install/physical-watch gates and Data Not Collected evidence.
3. Run immutable-source signed iOS/macOS export-only lanes through xbuild and the full Series 12 42mm watch scheme; inspect the exported watch bundle, assets, privacy, entitlements, frameworks and exact offline resources; run network/iCloud guards and fastlane safety tests.
4. Record commands, per-test results and limitations; check AC1/2/3/5 only when proven, leave AC4 and task In Progress for post-merge owner upload/install, commit and push without uploading or opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Coordinator decision 2026-10-25 after TASK-14.1 internal review: TASK-14.1 now adds a real opaque 1024px watch AppIcon derived from existing app art and proves iOS-container/macOS archive+export without uploading. TASK-14.6 may refine the circular/small-size icon and retains physical-watch, final feature payload, release documentation and internal-only TestFlight processing/install gates.

From the TASK-14.2 review: the decoded Basic bank stays resident for the app's lifetime (about 7.9 MiB retained on the simulator; first-touch load 0.365 s) and a failed load is cached until relaunch. Include both in the physical-watch memory and launch budget check.
<!-- SECTION:NOTES:END -->
