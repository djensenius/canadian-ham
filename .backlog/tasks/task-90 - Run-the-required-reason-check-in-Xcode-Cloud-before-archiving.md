---
id: TASK-90
title: Run the required-reason check in Xcode Cloud before archiving
status: Done
assignee:
  - '@copilot'
created_date: '2026-11-03T04:10:00Z'
updated_date: '2026-11-03T09:19:00Z'
labels:
  - apple
  - ci
  - release
milestone: m-0
dependencies:
  - TASK-85
priority: medium
type: chore
ordinal: 173000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-85 adds scripts/check-apple-required-reasons.mjs (pnpm check:apple-required-reasons, self-test pnpm test:apple-required-reasons) and runs it in GitHub CI. TASK-86's Xcode Cloud ci_pre_xcodebuild.sh runs only the Apple network and iCloud guards (CH_GUARD_SCRIPTS in apps/apple/ci_scripts/canadian-ham-ci.sh), so an Xcode Cloud archive could be built from a tree whose privacy manifests no longer match the sources. Add the required-reason check and its self-test to the Xcode Cloud guards.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Xcode Cloud ci_pre_xcodebuild.sh runs check:apple-required-reasons and test:apple-required-reasons with the other guards and fails the archive when either fails
- [x] #2 scripts/test-xcode-cloud-ci-scripts.sh covers the new guards (pass and fail cases) and passes locally
- [x] #3 docs/release/distribution.md lists the required-reason check among the Xcode Cloud guards
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add check:apple-required-reasons and test:apple-required-reasons to CH_GUARD_SCRIPTS in apps/apple/ci_scripts/canadian-ham-ci.sh and update the guard log/comment wording.
2. Mirror the new guards in scripts/test-xcode-cloud-ci-scripts.sh (fixture package.json stubs, all_guards pattern) and add pre-xcodebuild archive fail cases for a failing required-reason check and a failing self-test.
3. Confirm both new scripts use only Node built-ins and run with node --run from a tree without node_modules.
4. Update docs/release/distribution.md Xcode Cloud script table, dry-run notes and release-tooling table (self-test ~25 s).
5. Run requested checks.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Commit 4f3e27ecc7cfd8094f6bad5026b2c79783453a35. CH_GUARD_SCRIPTS in apps/apple/ci_scripts/canadian-ham-ci.sh now also lists check:apple-required-reasons and test:apple-required-reasons; ch_run_guards fails the action with 'Apple guard <script> failed; refusing to build'. Post-clone also runs them (shared list). Both scripts import only node: built-ins and passed via node --run in this worktree, which has no node_modules (check 0.6 s, self-test 25.3 s). Harness: fixture stubs and all_guards pattern updated; real-guard archive case now asserts the real required-reason check and self-test output; new fail cases 'failing required-reason check stops an archive' (self-test not run) and 'failing required-reason self-test stops an archive' both exit 1. Checks: pnpm test:xcode-cloud-scripts 129 passed, 0 failed (~93 s); pnpm check:shell passed (12 files); pnpm check:apple-required-reasons passed; pnpm test:apple-required-reasons passed; pnpm check:links verified; pnpm typecheck Done; git diff --check clean; check-test-guard passed (no guarded changes).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Xcode Cloud now runs the privacy-manifest required-reason check and its self-test with the network and iCloud guards in ci_post_clone.sh and ci_pre_xcodebuild.sh, failing the archive if either fails. The dry-run harness covers pass and both fail cases (129 passed), and docs/release/distribution.md lists the new guards and the ~25 s self-test time.
<!-- SECTION:FINAL_SUMMARY:END -->
