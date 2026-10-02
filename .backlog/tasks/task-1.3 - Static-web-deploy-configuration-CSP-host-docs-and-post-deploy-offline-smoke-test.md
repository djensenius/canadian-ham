---
id: TASK-1.3
title: >-
  Static web deploy configuration, CSP/host docs and post-deploy offline smoke
  test
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 12:00'
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
- [x] #2 The CSP blocks all third-party origins and the host log retention is documented
- [ ] #3 The post-deploy offline smoke test checklist exists and has been run once against a deployment
- [ ] #4 No deployment happens before the ISED permission is recorded
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a permission-gate script with tests/self-test that reads docs/content-licensing.md and fails until ISED permission is recorded with granted status, reference number, and date.
2. Configure Vite/GitHub Pages project-site base handling without breaking local dev, manifest scope/start_url, or service worker registration; add/audit build output checks including CSP third-party-origin validation.
3. Add a workflow_dispatch-only GitHub Pages deployment workflow using official pinned actions, minimal permissions, the permission gate, pnpm build:web, and the dist URL audit before artifact upload.
4. Document GitHub Pages host choice, gate, workflow usage, base path, CSP/meta limitations, host logs/retention caveat, and the post-deploy offline smoke checklist; run local preview smoke once and record it as non-deployment.
5. Validate with pnpm typecheck, pnpm test, pnpm build:web, dist URL audit, pnpm check:links, actionlint, and the permission gate expected failure; check only AC #1, #2, and #4 with evidence and leave AC #3 unchecked/In Progress.

6. Fix review findings: tighten the ISED permission gate to accept only explicit granted yes/date statuses with self-test coverage, use pinned pnpm/action-setup in deploy workflow, require default-src in the CSP audit, use configure-pages base_path output, clarify deploy/privacy/smoke docs, merge origin/main if PR #100 has landed, then rerun validation and re-check AC #1 and #4 only.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented GitHub Pages prep without deploying: workflow_dispatch-only `.github/workflows/deploy-web.yml` uses pinned official actions, minimal Pages permissions, first permission-gate job, `pnpm build:web`, and `pnpm --filter @canadian-ham/web audit:urls` before artifact upload. Added `scripts/check-release-permission.mjs` self-test and root `pnpm test` coverage. Added Vite `CANADIAN_HAM_WEB_BASE_PATH` support and tests; verified `/canadian-ham/` build keeps manifest scope/start_url and service worker paths relative. Extended dist audit to fail CSP third-party source expressions. Documented GitHub Pages host/gate/base/CSP/meta limits/log-retention caveat in `docs/release/web-deploy.md` and linked from `docs/privacy.md`. Added `docs/release/web-offline-smoke-test.md`; recorded only a local preview dry run, not a deployment, so AC #3 remains unchecked.

Validation evidence: `pnpm typecheck` passed; `pnpm test` passed (including release-permission self-test, content-tools 95 tests, web 89 tests); `pnpm build:web` passed; `pnpm --filter @canadian-ham/web audit:urls` passed; `pnpm check:links` passed; `go run github.com/rhysd/actionlint/cmd/actionlint@latest` passed; `node scripts/check-release-permission.mjs` failed today with exit status 1 because request status/reference/date are pending; local preview smoke fetched app shell, manifest and sw.js from `127.0.0.1:4173`.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Prepared static web deployment configuration and documentation while leaving task-1.3 In Progress pending a real deployment smoke test. Evidence for checked ACs: the manual-only GitHub Pages workflow, gate script, Vite base handling, CSP/dist audit, deployment docs, privacy link, and offline smoke checklist are committed; validation passed for typecheck, tests, web build, dist URL/CSP audit, link check and actionlint; the permission gate fails on the current pending ISED permission record, and the workflow has no push/schedule trigger. AC #3 remains unchecked because no deployment was performed.
<!-- SECTION:FINAL_SUMMARY:END -->
