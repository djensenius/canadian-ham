---
id: TASK-13
title: Optional iCloud sync
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
updated_date: '2026-10-09 00:22'
labels:
  - apple
  - privacy
  - 'legacy:T-705'
milestone: m-1
dependencies: []
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Privacy-review item: optional, opt-in iCloud sync of learning progress via SwiftData and the CloudKit private database. The research recommends post-v1, because CloudKit requires removing unique constraints from the progress models. v1 stays offline with no iCloud. Legacy: T-705.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The research is source-checked and committed under docs/proposals/
- [x] #2 The owner's decisions (timing, sync scope, opt-in default off) are recorded
- [x] #3 If approved, implementation subtasks are created and the AGENTS.md v1 iCloud rule is revisited
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decisions (2026-10-02, owner accepted all recommendations in docs/proposals/icloud-sync.md):
1. Timing and schema: no iCloud in v1. Keep the v1 SwiftData schema and migrate after v1 via SchemaMigrationPlan (remove .unique, add declaration-level defaults, dedup in ProgressStore).
2. Scope: sync learning progress only; PreferencesEntity stays local in a separate cloudKitDatabase: .none configuration.
3. Default: strictly opt-in, OFF until the user turns it on.
4. Container and platforms: explicit container iCloud.com.djensenius.CanadianHam (confirm the exact ID when the capability is added); tvOS and visionOS sync only after those targets get progress storage.
5. Privacy docs: approved in principle, after v1, a scoped exception in docs/privacy.md for CloudKit, Push Notifications and the remote-notification background mode (opt-in only), plus a CloudKit Console log no-retention policy. The AGENTS.md rule 'no iCloud sync in v1' stays unchanged; the privacy-review subtask revisits AGENTS.md, privacy.md and REQ-APPLE-003/004 when post-v1 work starts.

2026-10-02: implementation subtasks task-13.2 to task-13.5 created. AGENTS.md v1 iCloud rule revisited: it stays as is for v1 (owner decision); task-13.2 updates it together with docs/privacy.md when post-v1 work starts.

2026-10-08 owner and coordinator update: the owner asked for iCloud sync now. v1 hasn't shipped (waiting on ISED permission), so decision 1 changes: the local-only SwiftData schema V2 (no .unique, declaration defaults, V1→V2 lightweight migration, query-before-insert dedup) lands BEFORE v1 ships (task-13.3), so only one schema is in the field. Decision 5 is refined: AGENTS.md now says v1 RELEASE builds stay offline with no iCloud or push capability, and CloudKit, Push and the remote-notification background mode are allowed only behind an off-by-default build gate after v1 (task-13.2). The gate and toggle are task-13.4.
<!-- SECTION:NOTES:END -->
