---
id: TASK-13.5
title: 'iCloud merge rules, cloud deletion and privacy verification'
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
labels:
  - apple
  - privacy
milestone: m-1
dependencies:
  - TASK-13.4
parent_task_id: TASK-13
priority: medium
ordinal: 49000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: progress from several devices must converge without losing or double-counting attempts, users must be able to delete their cloud data for real, and the privacy answers must be re-checked. See docs/proposals/icloud-sync.md (owner decisions in task-13 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A convergent merge meets the proposal's section 6 requirements (cumulative attempts/correctAttempts, stable tie-breakers, unique submittedAt) with shared TS/Swift fixtures; JSON import stays replace-all
- [ ] #2 Delete iCloud Progress stops sync (local-only) before deleting the zone, honours the user's keep-or-delete-local choice, and a test shows no re-upload after restart
- [ ] #3 Reset all data covers cloud data; airplane-mode, no-account and account-switch smoke tests pass; App Store privacy answers are re-checked
<!-- AC:END -->
