---
id: TASK-10
title: Fix failing Dependabot updates
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 16:57'
labels:
  - ci
milestone: m-0
dependencies: []
ordinal: 17000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
GitHub's default Dependabot security updates for vitest in apps/web failed twice (2026-09-29), and there is no .github/dependabot.yml. Diagnose the failures and add an explicit pnpm-aware Dependabot configuration.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The cause of the failed Dependabot runs is documented in this task's notes
- [ ] #2 .github/dependabot.yml exists for the npm/pnpm workspaces and GitHub Actions
- [ ] #3 The next Dependabot run succeeds or opens a PR that passes CI
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a root .github/dependabot.yml using package-ecosystem npm at / so Dependabot reads the pnpm workspace/lockfile, plus a github-actions entry.\n2. Use weekly schedules and grouping to keep npm workspace and GitHub Actions update PR volume low.\n3. Verify the config and current dependency state with pnpm install --frozen-lockfile, pnpm typecheck, pnpm test, pnpm build:web, and actionlint because the change is GitHub workflow-adjacent.\n4. Record the Dependabot failure diagnosis and validation evidence in task notes, check only AC #1 and #2, and leave AC #3 unchecked/In Progress until the next post-merge Dependabot run succeeds or opens a PR that passes CI.
<!-- SECTION:PLAN:END -->
