---
id: TASK-31
title: Lean testing policy and faster Apple UI suites
status: In Progress
assignee:
  - '@coordinator'
created_date: '2026-10-03 13:42'
updated_date: '2026-10-03 13:44'
labels:
  - apple
  - testing
  - ci
milestone: m-0
dependencies: []
priority: medium
ordinal: 58000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner noted we are overtesting (2026-10-03). Every task ran the full UI suite on all four Apple platforms (20-40 min each, serialized by the shared xbuild lock), often several times per task, even for changes that touched one screen or no Apple code. The policy goes in AGENTS.md now; this task also slims the Apple UI suites themselves, without losing coverage.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 AGENTS.md documents the tiered policy: targeted -only-testing runs while iterating; each changed platform's full suite once per PR; no Apple suites for web/docs/Backlog-only changes; full four-platform run with every audit at the release-candidate pass (task-1.6)
- [ ] #2 The iOS UI suite is consolidated (e.g. light and dark audits per flow combined into one launch where possible, fewer repeated app launches) with the same screens, flows and accessibility audits still covered; a before/after table of test count and wall-clock time is recorded in the task notes
- [ ] #3 tvOS and visionOS UI suites get the same treatment where it helps; all four suites pass after consolidation
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Document the tiered testing policy in AGENTS.md (this PR).
2. Later worker: consolidate the iOS UI suite (combine light/dark audits per flow, fewer launches) with a before/after time table.
3. Same for tvOS and visionOS where it helps; run all four suites once.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
AC #1: AGENTS.md now has a 'Testing policy (all agents)' section and the post-merge rule runs quick checks instead of full Apple suites. AC #2/#3 (suite consolidation) are for a later worker.
<!-- SECTION:NOTES:END -->
