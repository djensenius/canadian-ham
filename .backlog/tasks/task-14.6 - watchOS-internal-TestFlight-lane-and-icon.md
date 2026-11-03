---
id: TASK-14.6
title: watchOS internal TestFlight lane and icon
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T17:02:00Z'
updated_date: '2026-10-25T22:53:00Z'
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
- [x] #1 The watch app has a valid watch AppIcon derived from the existing icon family, safe under circular masking at small sizes, with visual review evidence; bundle ID/signing and any icon variants required by the current watch SDK validate without warnings or missing assets.
- [x] #2 A documented fastlane beta entry path archives/exports the iOS container containing CanadianHamWatch through xbuild only, using the dedicated build keychain and matching timestamp build numbers. The existing ios beta includes the watch payload, other platform lanes still work, and no separate unsupported ASC watchOS platform is invented.
- [x] #3 Release artifacts are inspected to verify the watch payload, correct bundle IDs/icon/privacy manifest, Basic-only offline content, and absence of cloud/push, WatchConnectivity, networking/telemetry SDKs and unused lesson/hint/Advanced resources; network/iCloud guards pass.
- [ ] #4 After review/merge approval, an internal-team-only TestFlight upload is processed and installation on a physical watch verifies quick practice, Morse, reference and EN/FR without the phone app or network. Results and build IDs are recorded; no external group, public link or App Store submission is created before TASK-1.7/licensing approval.
- [x] #5 docs/release/testflight.md, privacy-label evidence and the release checklist cover the watch payload, Data Not Collected, signing/install steps and manual hardware checks; the simulator build/test command and targeted per-test results are recorded before upload.
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

2026-10-25: retained existing opaque 1024px cream/hex watch icon after circular native-size review at 1024/196/88/48 px; before/after evidence committed with release docs. Signed iOS export-only build 202610251833 and macOS export-only build 202610251835 succeeded; upload explicitly skipped. IPA inspection verifies matching phone/watch timestamps, IDs/independent flag, compiled icon, empty collection manifest, distribution signatures, no cloud/push/App Groups/WatchConnectivity/network/third-party direct links, and all 988 Basic/explanation JSON files byte-identical to source, with an exact full-bundle file allowlist. macOS pkg has no watch payload. Network/iCloud guards + fixtures and fastlane safety tests (4/53) pass. Full Series 12 42mm watch scheme is running; no upload/PR. AC4 reserved for post-merge processed internal upload and owner physical install/offline/haptics/listening checks; task stays In Progress.

2026-10-25 final automated evidence: one complete CanadianHamWatch scheme run on Series 12 (42mm), watchOS 27.0 (24R362), 22:36:30–22:52:01 UTC passed 56/56 (29 unit, 27 UI), zero failures/skips, including all 16 full default EN/FR accessibility audits. Per-test names/durations and immutable-runtime provenance are in docs/testing/task-14.6-watch-release.md; raw result summary is in docs/evidence/task-14.6/watch-test-summary.json, xcresult/logs retained at ~/.cache/canadian-ham-task-14.6/. Result metadata misnames device iPhone Air; simctl confirms the same UUID is the requested Watch Series 12 42mm. Final asset diagnostic grep across both signed exports and watch simulator build found zero actool/icon/asset warnings/errors. Existing catalogue/audio deprecations, synchronous audio-session runtime warning and simulator metadata/diagnostics messages are recorded, not hidden. Links, preview byte-for-byte regeneration, fastlane syntax/safety tests, network/iCloud guards+fixtures, test guard and diff checks pass. No runtime/project/Fastfile or icon edits were needed; all changes are docs/evidence and task metadata. No upload, invitation or PR. AC1/2/3/5 checked with signed artifact and test evidence. AC4 remains blocked pending approved post-merge internal iOS upload/ASC processing and owner physical-watch install, offline practice/Morse/reference/EN-FR, three-style haptic comparison, VoiceOver, memory and launch checks; task intentionally stays In Progress. iOS/macOS/tvOS/visionOS full suites and tvOS/visionOS exports skipped because unchanged and outside this requested docs/evidence validation; coordinator retains merge/release gates.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Pre-merge release validation is ready for review: retained the circular-safe existing icon with 1024/196/88/48px before/after evidence, documented the embedded-watch iOS beta entry path and internal-only signing/install/privacy/hardware gates, produced and inspected signed export-only iOS/macOS artifacts, and recorded 56/56 full-watch tests plus passing guards. AC1/2/3/5 are proven; AC4 and task stay In Progress for the post-merge processed internal upload and owner physical installation/offline/haptic/listening/memory pass. No upload or PR was performed.
<!-- SECTION:FINAL_SUMMARY:END -->
