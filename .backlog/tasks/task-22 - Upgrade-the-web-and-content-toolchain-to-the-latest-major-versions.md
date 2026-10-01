---
id: TASK-22
title: Upgrade the web and content toolchain to the latest major versions
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 18:11'
updated_date: '2026-10-01 18:17'
labels:
  - ci
  - web
  - tooling
milestone: m-0
dependencies: []
ordinal: 31000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The owner wants every dependency on its latest major version. Dependabot's first grouped PR (#55) bumped five development tools across majors at once and failed CI (TypeScript 7 rejects a test file with TS7022), so the upgrade needs deliberate work rather than a blind merge. Staying current also keeps the toolchain aligned with the Node 26 runtime we already use. Dependabot's grouping should change so future major bumps arrive one per PR instead of failing together.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 TypeScript 7, Vite 8, Vitest 5, jsdom 30 and @types/node 26 are the versions in every workspace package that uses them, and pnpm is 12.8 (packageManager)
- [x] #2 pnpm typecheck, pnpm test, pnpm build:web, the web dist URL audit, pnpm check:links, the content checkers and node packages/schemas/validate.mjs all pass, with the axe accessibility tests still green
- [x] #3 The PWA/service-worker build and offline behaviour still work (the existing PWA tests pass and the built service worker precaches the app shell)
- [x] #4 No checks are weakened: no tests skipped, no type errors suppressed with any/ts-ignore without a documented reason
- [x] #5 .github/dependabot.yml keeps minor and patch updates grouped weekly but opens a separate PR for each major update, and Dependabot PR #55 is closed in favour of this task
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Update packageManager and workspace devDependency ranges for TypeScript 7, Vite 8, Vitest 5, jsdom 30, and @types/node 26, then refresh pnpm-lock.yaml with pnpm 12.8.2.\n2. Adjust source/tests/config for actual migration breakages without weakening checks, especially fixing the TypeScript 7 App.test.tsx TS7022 by adding a concrete type.\n3. Update .github/dependabot.yml grouping so only minor+patch npm updates are grouped weekly while major npm updates open individually.\n4. Run the required install, typecheck, web test twice, build, URL/PWA audits, content validators, schema validators, Apple network check, link check, and actionlint; inspect built sw.js for app-shell precache.\n5. Record evidence, check proven ACs, write the final summary, and move task-22 to Done only after all ACs pass.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Research: npm registry latest majors are TypeScript 7.0.2, Vite 8.3.2, Vitest 5.0.3, jsdom 30.1.1, @types/node 26.6.3, pnpm latest 12.8.x is 12.8.2. Reviewed official Vite 8 migration notes (Rolldown/Oxc defaults, esbuild optional/deprecated, CJS interop, removed/deprecated Rollup-related options), Vitest 5 migration notes (clearMocks default true, testNamePattern separator, hoisted mocks, project inheritance/shared server, benchmark API), and jsdom changelog source for v30. Noted TypeScript 7 requires fixing the App.test.tsx TS7022 inference issue with an explicit type, not suppression. Dependabot PR #55 was closed by the coordinator in favour of task-22.

Implemented toolchain upgrade: packageManager pnpm@12.8.2; TypeScript ^7.0.2 and @types/node ^26.6.3 in every TS workspace; Vite ^8.3.2/Vitest ^5.0.3/jsdom ^30.1.1 in the web workspace; lockfile refreshed with pnpm 12.8.2. Fixed TypeScript 7 TS7022 in App.test.tsx with an explicit Answer | undefined type. Added .ts extensions in vite.config.ts to satisfy Vite native config-loader guidance. Switched web manifest JSON import to named imports so Rolldown does not bundle unused source URL metadata and the dist URL audit remains strict. Dependabot npm and GitHub Actions groups now include only minor/patch update-types so majors are individual PRs. pnpm install added pnpm-workspace.yaml minimumReleaseAgeExclude for vite@8.3.2 to satisfy the repository's pnpm supply-chain policy for this latest Vite version. Validation passed: pnpm install --frozen-lockfile; pnpm typecheck; pnpm test plus a second web test run; pnpm build:web; web dist URL audit; built sw.js PRECACHE_URLS includes ./, ./index.html, manifest/icons, CSS/JS chunks, and questions JSON; pnpm check:links; check-explanations/check-quizzes/check-coverage/check-lesson-originality --all; schema validate plus negative test; pnpm check:apple-network; go-run actionlint.
<!-- SECTION:NOTES:END -->
