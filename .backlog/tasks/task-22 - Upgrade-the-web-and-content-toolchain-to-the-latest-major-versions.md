---
id: TASK-22
title: Upgrade the web and content toolchain to the latest major versions
status: To Do
assignee: []
created_date: '2026-10-01 18:11'
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
- [ ] #1 TypeScript 7, Vite 8, Vitest 5, jsdom 30 and @types/node 26 are the versions in every workspace package that uses them, and pnpm is 12.8 (packageManager)
- [ ] #2 pnpm typecheck, pnpm test, pnpm build:web, the web dist URL audit, pnpm check:links, the content checkers and node packages/schemas/validate.mjs all pass, with the axe accessibility tests still green
- [ ] #3 The PWA/service-worker build and offline behaviour still work (the existing PWA tests pass and the built service worker precaches the app shell)
- [ ] #4 No checks are weakened: no tests skipped, no type errors suppressed with any/ts-ignore without a documented reason
- [ ] #5 .github/dependabot.yml keeps minor and patch updates grouped weekly but opens a separate PR for each major update, and Dependabot PR #55 is closed in favour of this task
<!-- AC:END -->
