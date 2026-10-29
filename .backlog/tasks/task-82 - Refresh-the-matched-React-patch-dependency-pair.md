---
id: TASK-82
title: Refresh the matched React patch dependency pair
status: To Do
assignee: []
created_date: '2026-10-29T00:21:00Z'
labels:
  - dependencies
  - web
dependencies: []
references:
  - https://github.com/djensenius/canadian-ham/pull/318
type: chore
ordinal: 165000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Fleet dependency assessment found React and React DOM 19.3.1 available and existing Dependabot PR #318 based on an older main. Pre-review approved refreshing only the matched patch pair onto current main, preserving current CI and root scripts. Defer the broader seven-package development-tooling update in #319. Validate the refreshed head rather than relying on stale CI.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Only the matched React and React DOM 19.3.1 direct dependency declarations and resulting pnpm lockfile changes are included, besides this CLI-managed task record; current CI/root scripts and release/privacy gates remain unchanged.
- [ ] #2 Frozen installation with existing strict peers, typecheck, web/package tests, web build and built URL/CSP audit pass on the refreshed branch.
- [ ] #3 Internal review, Copilot PR review and required CI pass before merge; record exact checks and no Apple suites for this web-only update.
<!-- AC:END -->
