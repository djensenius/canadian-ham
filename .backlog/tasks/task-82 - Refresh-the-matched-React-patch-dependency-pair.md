---
id: TASK-82
title: Refresh the matched React patch dependency pair
status: In Progress
assignee:
  - '@copilot-worker'
created_date: '2026-10-29T00:21:00Z'
updated_date: '2026-10-29T00:24:00Z'
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
- [x] #1 Only the matched React and React DOM 19.3.1 direct dependency declarations and resulting pnpm lockfile changes are included, besides this CLI-managed task record; current CI/root scripts and release/privacy gates remain unchanged.
- [x] #2 Frozen installation with existing strict peers, typecheck, web/package tests, web build and built URL/CSP audit pass on the refreshed branch.
- [ ] #3 Internal review, Copilot PR review and required CI pass before merge; record exact checks and no Apple suites for this web-only update.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Use pnpm 12.8.2 to update only the web React/react-dom matched pair to ^19.3.1, preserving all other resolved package versions and both lockfile documents.
2. Verify the scoped diff and run frozen install, typecheck, root tests, engine-ts tests, web build, URL/CSP audit, and diff whitespace check. No Apple suites for this web-only patch.
3. Record exact evidence, check AC1/AC2 only if proven, and leave AC3 unchecked/In Progress for future reviews and CI; commit with requested trailers.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Ready for review on task-82-react-patch, based on a69c27400b88302c9f8ce393ea98ae01b73cfd25 plus the CLI-created TASK-82 record. Used Node v26.12.1 / pnpm 12.8.2 and pnpm --filter @canadian-ham/web update react@^19.3.1 react-dom@^19.3.1. Manifest previously allowed ^19.1.1 and locked 19.3.0; now both declare ^19.3.1 and resolve 19.3.1. Only the matched pair, integrity/peer references, and CLI-managed TASK-82 record changed. Both YAML documents retained; first document byte-identical; no other package versions changed. Root scripts/CI, strictPeerDependencies:true, autoInstallPeers:false, official content, release/privacy gates, and owner root status.md untouched.
Validation (requested commands all exit 0, first attempts):
- pnpm install --frozen-lockfile: Lockfile is up to date, resolution step is skipped; Already up to date; Done in 56ms using pnpm v12.8.2.
- pnpm typecheck: all workspace typechecks Done, including apps/web typecheck: Done.
- pnpm test: Quiet figure runner: 6 integration scenarios passed (no Xcode dependency); Watch alphabet reference self-test passed; official reference sheet and release permission gate self-tests passed; content-tools tests 250 / pass 250 / fail 0; morse-engine Test Files 2 passed (2), Tests 23 passed (23); calculator-engine tests 127 / pass 127 / fail 0; web Test Files 18 passed (18), Tests 283 passed (283), Duration 30.54s. No Scope:Due failure or targeted rerun.
- pnpm --filter @canadian-ham/engine-ts test (root test does not cover it): tests 32 / pass 32 / fail 0.
- pnpm build:web: 2155 modules transformed; built in 356ms; official reference sheet gate passed; Default web output contains no official asset hashes (standalone or inline) or transcript text. Non-failing warning: Some chunks are larger than 500 kB after minification; left unchanged/out of scope.
- pnpm --filter @canadian-ham/web audit:urls: dist URL and CSP audit passed.
- git diff --check: no output, exit 0.
- Extra ad-hoc Node scope assertion initially failed because its normalization incorrectly matched @types/react substrings, not because dependencies changed; corrected token boundary and reran successfully: Scope check passed: only TASK-82, web manifest and lockfile changed; first lockfile document and all non-pair package versions preserved. No repository check or test changed.
No Apple suites (iOS/macOS/tvOS/visionOS/watchOS) run: web-only patch. Internal dependency pre-review APPROVE WITH NOTES supplied by coordinator; implementation review, Copilot PR review and required CI remain future gates. AC3 deliberately unchecked and task remains In Progress. No GitHub interactions, push, PR, merge, amend or rebase performed.
<!-- SECTION:NOTES:END -->
