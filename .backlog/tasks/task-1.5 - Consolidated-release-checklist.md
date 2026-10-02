---
id: TASK-1.5
title: Consolidated release checklist
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 11:52'
labels:
  - release
  - docs
  - 'legacy:T-006'
milestone: m-0
dependencies: []
parent_task_id: TASK-1
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Consolidate the release procedures currently spread across docs/content-licensing.md (release checklist, public-release gate), docs/accessibility.md (manual release checklist), docs/privacy.md (verification checklist) and docs/apple-offline-smoke-test.md into one release checklist. Legacy: T-006.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 One release checklist links or includes every licensing, privacy, accessibility, offline and source-verification check
- [ ] #2 Each existing doc checklist points to the consolidated checklist
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inventory the referenced release, privacy, accessibility, offline, source-verification, and related task-gate checks.
2. Add docs/release/release-checklist.md as a release-day checklist organized by gates, content, privacy, accessibility, offline Apple, offline web, store submission, and public repo.
3. Add short pointers near existing checklist sections without deleting existing content.
4. Run pnpm check:links, adjust task-1.3 references if needed, then finalize Backlog with evidence.
<!-- SECTION:PLAN:END -->
