---
id: TASK-13.4
title: Opt-in iCloud sync toggle
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-09 00:32'
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
- [ ] #1 project.yml adds iCloud (CloudKit), Push and Background Modes (remote notifications); the project is regenerated with XcodeGen
- [ ] #2 Settings has an iCloud Sync toggle that defaults OFF, using explicit cloudKitDatabase .none when off and .private("iCloud.com.djensenius.CanadianHam") (or the confirmed ID) when on; preferences stay in a separate local configuration
- [ ] #3 Account change, sign-out and iCloud-disable are tested for local data loss; test configurations build without restricted entitlements (macOS ad hoc, simulators unsigned)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a non-default iCloud-gated Apple build configuration/xcconfig with ICLOUD_SYNC, gated entitlements, and a cheap CI guard that default configs have no iCloud/Push/remote-notification capabilities.\n2. Add a local-only iCloud sync preference and ProgressStore configuration selection so default/off builds use .none and gated/on builds use the private container for learning progress only.\n3. Expose the Settings toggle only under ICLOUD_SYNC on iOS/iPadOS and macOS, with tests for config selection and local-data-preserving toggle/account-change behavior.\n4. Regenerate the Xcode project, update the minimal privacy/agent docs and task notes, then run default iOS/macOS tests plus gated iOS/macOS builds per policy.
<!-- SECTION:PLAN:END -->
