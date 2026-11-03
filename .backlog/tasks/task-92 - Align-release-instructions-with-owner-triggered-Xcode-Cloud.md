---
id: TASK-92
title: Align release instructions with owner-triggered Xcode Cloud
status: To Do
assignee: []
created_date: '2026-11-03T09:46:00Z'
labels:
  - documentation
  - release
dependencies:
  - TASK-86
  - TASK-91
priority: medium
type: docs
ordinal: 175000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The approved agentic delivery uses Xcode Cloud and does not authorize uploads. Active instructions still direct agents to upload with Fastlane after merges, contradicting that policy. Align the governing instructions and linked release runbooks without changing tooling, licensing gates, or historical evidence.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Active instructions prefer owner-triggered Xcode Cloud and explicitly state that merge or review approval does not authorize uploads or release-workflow triggers; no automatic post-merge upload direction remains.
- [ ] #2 Fastlane export-only distribution checks and conditional explicitly authorized internal fallback instructions remain usable; build-number floors, option (b) platform restrictions, signing safeguards and all existing release gates are preserved.
- [ ] #3 Linked TestFlight, distribution, owner-gates, release checklist and pending watch-delivery instructions agree; no upload, workflow trigger, Apple source/project or tool behavior changes are performed.
<!-- AC:END -->
