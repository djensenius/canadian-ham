---
id: TASK-10
title: Fix failing Dependabot updates
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 17:00'
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
- [x] #1 The cause of the failed Dependabot runs is documented in this task's notes
- [x] #2 .github/dependabot.yml exists for the npm/pnpm workspaces and GitHub Actions
- [ ] #3 The next Dependabot run succeeds or opens a PR that passes CI
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a root .github/dependabot.yml using package-ecosystem npm at / so Dependabot reads the pnpm workspace/lockfile, plus a github-actions entry.
2. Use weekly schedules and grouping to keep npm workspace and GitHub Actions update PR volume low.
3. Verify the config and current dependency state with pnpm install --frozen-lockfile, pnpm typecheck, pnpm test, pnpm build:web, and actionlint because the change is GitHub workflow-adjacent.
4. Record the Dependabot failure diagnosis and validation evidence in task notes, check only AC #1 and #2, and leave AC #3 unchecked/In Progress until the next post-merge Dependabot run succeeds or opens a PR that passes CI.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Dependabot diagnosis: gh run list --workflow 'Dependabot Updates' showed two failed 2026-09-29 vitest security-update jobs (36509071802 and 36510963092) for npm_and_yarn in /apps/web. gh run view --log-failed for both jobs reported security_update_not_possible: latest-resolvable-version 3.2.7, lowest-non-vulnerable-version 4.1.11, conflicting-dependencies [], so Dependabot's default manifest-scoped security update could not produce the patched vitest update. gh api repos/djensenius/canadian-ham/dependabot/alerts showed alert #1 for apps/web/package.json vitest >=2.1.0,<4.1.11 is now fixed. Current GitHub Docs (Dependabot supported ecosystems reusable, fetched from github/docs main) list pnpm under YAML value npm with version and security updates supported for pnpm v7-v10. Current branch already has apps/web vitest ^4.1.11 and pnpm-lock.yaml resolves vitest 4.1.11, so no additional vitest pnpm update was needed here. Added .github/dependabot.yml with npm at / for the pnpm workspace/lockfile and github-actions at /.

Validation passed: pnpm install --frozen-lockfile; pnpm typecheck; pnpm test (content-tools 93 passed, web 10 files/78 tests passed); pnpm build:web; go run github.com/rhysd/actionlint/cmd/actionlint@latest; ruby YAML parse for .github/dependabot.yml. AC #3 remains unchecked because the next Dependabot run can only be verified after this branch is merged and Dependabot runs on main.

Residual risk for AC #3: GitHub Docs currently list Dependabot pnpm support for pnpm v7-v10 under package-ecosystem npm, while this repository declares packageManager pnpm@12.6.0 and uses pnpm-lock.yaml lockfileVersion 9.0. I did not downgrade or otherwise change the repository package manager because that would widen this task's configuration scope; the next Dependabot run must confirm whether GitHub's updater accepts the current pnpm 12 workspace.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added explicit Dependabot configuration for the root pnpm workspace lockfile and GitHub Actions, grouped on a weekly schedule to reduce PR volume. Documented the failed vitest security-update cause from the GitHub Dependabot run logs and confirmed the existing branch already uses fixed vitest 4.1.11. Verified locally with install, typecheck, tests, web build, actionlint, and YAML parsing. Task remains In Progress because AC #3 requires a post-merge Dependabot run; note the current GitHub Docs list pnpm v7-v10 while this repo declares pnpm@12.6.0, so that compatibility must be confirmed by the next run.
<!-- SECTION:FINAL_SUMMARY:END -->
