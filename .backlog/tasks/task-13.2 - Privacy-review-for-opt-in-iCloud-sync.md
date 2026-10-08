---
id: TASK-13.2
title: Privacy review for opt-in iCloud sync
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-08 12:07'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Update privacy, requirements, decision, and AGENTS policy docs to preserve v1 offline/no-iCloud release builds while documenting the off-by-default post-v1 CloudKit/Push/remote-notification build-gated exception.\n2. Record Data Not Collected reasoning using Apple App Privacy collect definition and private CloudKit database access, plus a no-export/no-retention policy for CloudKit Console logs.\n3. Verify docs-only scope for task-13.2 and keep schema/code changes in task-13.3.
<!-- SECTION:PLAN:END -->
