---
id: TASK-14.1
title: watchOS target and shared-package support skeleton
status: To Do
assignee: []
created_date: '2026-10-25T17:01:00Z'
labels:
  - apple
  - watchos
milestone: m-1
dependencies: []
documentation:
  - docs/proposals/watchos-companion.md
parent_task_id: TASK-14
type: feature
ordinal: 155000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner approved the watch companion on 2026-10-25. Before feature work, prove the three existing local Swift packages and a minimal independently usable SwiftUI app can run on watchOS 27. Current package manifests omit watchOS; no watch target exists. The proposal recommends a watch app embedded in the existing iOS distribution container, without app-level pairing or WatchConnectivity. This task establishes compatibility and distribution structure only, not practice features.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 CanadianHamWatch is a watchOS 27 XcodeGen app target and shared scheme with watch-specific source/resource membership, CanadianHamWatchTests and CanadianHamWatchUITests; project.yml and the generated project are committed and regeneration is deterministic.
- [ ] #2 engine-swift, content-swift and morse-swift explicitly support watchOS 27, compile for the watch simulator, and have relevant package tests passing; existing platform support is preserved and affected-platform merge-batch checks are identified.
- [ ] #3 The minimal app launches and passes a unit smoke test and a UI launch/navigation smoke test via DEVELOPER_DIR-prefixed xbuild using one installed watchOS 27 simulator; exact destination and per-test results are recorded.
- [ ] #4 The watch bundle identifier org.davidjensenius.CanadianHam.watchkitapp and independent-operation embedding are validated in an iOS-container build; no phone-app setup, application pairing or WatchConnectivity is needed for watch launch.
- [ ] #5 Default Debug/Release and the watch target in DebugCloudKit contain no cloud/push capability, network code, third-party SDKs or background networking; the watch privacy manifest declares no tracking/collected data, and network/iCloud guards pass with watch membership covered.
<!-- AC:END -->
