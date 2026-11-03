---
id: TASK-92
title: Align release instructions with owner-triggered Xcode Cloud
status: In Progress
assignee:
  - '@worker'
created_date: '2026-11-03T09:46:00Z'
updated_date: '2026-11-03T09:46:00Z'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read the six active policy documents and preserve existing release gates, historical evidence and fallback safeguards.
2. Align owner-triggered Xcode Cloud preference and separately authorized Fastlane fallback wording; keep local inspection exports explicitly export-only.
3. Run available documentation link checks, diff whitespace checks and a focused policy/anchor scan, then commit documentation with required trailers and finalize TASK-92 through the CLI.
<!-- SECTION:PLAN:END -->
