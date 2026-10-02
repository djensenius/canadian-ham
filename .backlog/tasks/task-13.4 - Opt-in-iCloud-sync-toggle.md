---
id: TASK-13.4
title: Opt-in iCloud sync toggle
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
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
