---
id: TASK-62
title: Audit lesson-originality allowlist staleness
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-19 13:14'
updated_date: '2026-10-20 04:01'
labels: []
dependencies: []
ordinal: 137000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-47 review noted that some originality allowlist entries may now be unnecessary after the numeric-overlap heuristic learned to suppress common dB/ratio false positives. Allowlisted blocks are skipped before numeric and near-verbatim checks, so stale entries can hide future regressions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Checker reports or tests identify allowlist entries that no longer suppress any issue
- [ ] #2 Unneeded allowlist entries are removed or justified with current checker output
- [ ] #3 All lesson originality checks still pass after the allowlist audit
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Evaluate allowlisted heading blocks with the unchanged originality rules, report entries that suppress no issues, and fail stale entries (audit the full allowlist for --all; scope partial runs to checked lessons). Add source-named regression tests.
2. Run the full audit, record the before/after entry lists and suppressed-issue evidence, remove every stale entry, and verify specific reasons on all survivors without changing lesson content.
3. Run the requested TypeScript/content checks, record evidence, finalize the task, and commit the focused change for required review before opening the requested PR.
<!-- SECTION:PLAN:END -->
