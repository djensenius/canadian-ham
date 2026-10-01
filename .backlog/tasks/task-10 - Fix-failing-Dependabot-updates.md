---
id: TASK-10
title: Fix failing Dependabot updates
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 17:27'
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
- [x] #3 The next Dependabot run succeeds or opens a PR that passes CI
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

Coordinator diagnosis (2026-10-01): both failed Dependabot runs (2026-09-29 01:41Z and 02:05Z) ran while apps/web/package.json pinned "vitest": "^3.2.0" (since 66bd785). The fix (lowest patched 4.1.11) needed a major bump outside that range, so the security update reported security_update_not_possible (latest resolvable 3.2.7). The manual bump to ^4.1.11 landed later in 3566fee (2026-09-29 02:21Z) and resolved alert #1. Second risk for AC #3: the repo uses packageManager pnpm@12.6.0, whose pnpm-lock.yaml is a two-document YAML file (two lockfileVersion '9.0' documents); Dependabot documents pnpm support only up to v10, so the next run may fail to parse it. If it does, open a follow-up task (e.g. pin the lockfile format or document the limitation) rather than widening this one. Security updates are not covered by the version-update groups (applies-to: version-updates); acceptable for now.

Coordinator, 2026-10-01: after PR #52 merged (with versioning-strategy: increase), the next Dependabot runs succeeded: Dependabot Updates runs at 2026-10-01T17:20:54Z and 17:20:55Z both completed with conclusion success (see gh run list --workflow 'Dependabot Updates'). The pnpm 12 lockfile risk did not materialise.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Diagnosed the failed vitest security updates (the fix needed a major bump outside ^3.2.0; resolved by the manual bump in 3566fee), added .github/dependabot.yml for the pnpm workspace and GitHub Actions with weekly grouped updates and versioning-strategy: increase so future fixes can raise version ranges, and confirmed with two successful Dependabot runs after merge.
<!-- SECTION:FINAL_SUMMARY:END -->
