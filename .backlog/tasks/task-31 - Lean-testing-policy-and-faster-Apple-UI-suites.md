---
id: TASK-31
title: Lean testing policy and faster Apple UI suites
status: To Do
assignee: []
created_date: '2026-10-03 13:42'
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
- [ ] #1 AGENTS.md documents the tiered policy: targeted -only-testing runs while iterating; each changed platform's full suite once per PR; no Apple suites for web/docs/Backlog-only changes; full four-platform run with every audit at the release-candidate pass (task-1.6)
- [ ] #2 The iOS UI suite is consolidated (e.g. light and dark audits per flow combined into one launch where possible, fewer repeated app launches) with the same screens, flows and accessibility audits still covered; a before/after table of test count and wall-clock time is recorded in the task notes
- [ ] #3 tvOS and visionOS UI suites get the same treatment where it helps; all four suites pass after consolidation
<!-- AC:END -->
