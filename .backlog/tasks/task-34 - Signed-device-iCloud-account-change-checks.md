---
id: TASK-34
title: Signed-device iCloud account-change checks
status: To Do
assignee: []
created_date: '2026-10-09 07:36'
labels:
  - apple
  - privacy
dependencies:
  - TASK-13.4
ordinal: 72000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The opt-in iCloud gate can unit-test local handlers and default-build entitlements, but real CloudKit behavior when the user signs out, switches accounts, disables iCloud, or CloudKit purges mirrored data requires an owner-run signed device with the registered container/capability.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 On a signed iOS or macOS device with the registered iCloud container, sign out while sync is on and verify local learning progress remains available and sync is disabled
- [ ] #2 On a signed iOS or macOS device with the registered iCloud container, switch iCloud accounts while sync is on and verify the app does not continue mirroring into the prior or new account until the user opts in again
- [ ] #3 On a signed iOS or macOS device with the registered iCloud container, disable iCloud/CloudKit access for the app and verify local learning progress remains available and sync is disabled
- [ ] #4 Document whether SwiftData/CloudKit purges any mirrored local data in these scenarios and feed findings back into task-13.5 merge/deletion work
<!-- AC:END -->
