---
id: TASK-13.2
title: Privacy review for opt-in iCloud sync
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
labels:
  - apple
  - privacy
  - docs
milestone: m-1
dependencies:
  - TASK-1
parent_task_id: TASK-13
priority: medium
ordinal: 46000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: v1 forbids iCloud and push capabilities; the owner approved a scoped, opt-in exception after v1, which must be documented and justified before any code. See docs/proposals/icloud-sync.md (owner decisions in task-13 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 docs/privacy.md, REQ-APPLE-003/004, DEC-APPLE-003 and the AGENTS.md iCloud rule are updated for opt-in CloudKit, Push Notifications and the remote-notification background mode only
- [ ] #2 The 'Data Not Collected' reasoning is recorded with Apple sources (App Privacy 'collect' definition, private database access)
- [ ] #3 A CloudKit Console log no-export/no-retention policy is documented
<!-- AC:END -->
