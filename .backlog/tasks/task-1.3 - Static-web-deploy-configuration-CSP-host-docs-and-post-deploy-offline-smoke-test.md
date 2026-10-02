---
id: TASK-1.3
title: >-
  Static web deploy configuration, CSP/host docs and post-deploy offline smoke
  test
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 11:49'
labels:
  - release
  - web
  - 'legacy:T-604'
  - 'legacy:T-313'
milestone: m-0
dependencies:
  - TASK-1.1
parent_task_id: TASK-1
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add the static hosting configuration for apps/web, document host logging and the Content-Security-Policy (allowing no third-party origins), and write a post-deploy offline smoke-test checklist (load, install PWA, go offline, practise, mock exam, export/import). Includes the remaining part of the web privacy audit (legacy T-313: the dist URL audit is already done). Legacy: T-604, T-313.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The deployment configuration is committed and documented
- [ ] #2 The CSP blocks all third-party origins and the host log retention is documented
- [ ] #3 The post-deploy offline smoke test checklist exists and has been run once against a deployment
- [ ] #4 No deployment happens before the ISED permission is recorded
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a permission-gate script with tests/self-test that reads docs/content-licensing.md and fails until ISED permission is recorded with granted status, reference number, and date.\n2. Configure Vite/GitHub Pages project-site base handling without breaking local dev, manifest scope/start_url, or service worker registration; add/audit build output checks including CSP third-party-origin validation.\n3. Add a workflow_dispatch-only GitHub Pages deployment workflow using official pinned actions, minimal permissions, the permission gate, pnpm build:web, and the dist URL audit before artifact upload.\n4. Document GitHub Pages host choice, gate, workflow usage, base path, CSP/meta limitations, host logs/retention caveat, and the post-deploy offline smoke checklist; run local preview smoke once and record it as non-deployment.\n5. Validate with pnpm typecheck, pnpm test, pnpm build:web, dist URL audit, pnpm check:links, actionlint, and the permission gate expected failure; check only AC #1, #2, and #4 with evidence and leave AC #3 unchecked/In Progress.
<!-- SECTION:PLAN:END -->
