---
id: TASK-89
title: Run shellcheck on repository shell scripts in CI
status: In Progress
assignee:
  - '@worker'
created_date: '2026-11-03T04:10:00Z'
updated_date: '2026-11-03T04:23:00Z'
labels:
  - ci
  - release
milestone: m-0
dependencies: []
priority: medium
type: chore
ordinal: 172000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-86 added Xcode Cloud ci_scripts (apps/apple/ci_scripts/*.sh) and a shell test harness, and scripts/ has other bash scripts. Shellcheck currently runs only locally: shellcheck -x scripts/*.sh reports existing findings in 3 files, and GitHub CI (ubuntu-latest) does not run shellcheck at all. The macOS-only harnesses (pnpm test:fastlane needs plutil; pnpm test:xcode-cloud-scripts needs codesign, xmllint and sandbox-exec) cannot run on the Ubuntu CI; adding a macOS runner is an owner cost/policy decision and is out of scope here.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 CI runs shellcheck -x (and bash -n) on every tracked *.sh under scripts/ and apps/apple/ci_scripts/ and fails on findings
- [x] #2 Existing shellcheck findings are fixed, or suppressed with a narrow inline directive and a reason, without changing script behaviour
- [x] #3 Docs that list release-tooling checks state which harnesses run in GitHub CI and which stay local because they need macOS, and that a macOS runner is an owner decision
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add scripts/check-shell-scripts.sh (pnpm check:shell): enumerate tracked *.sh under scripts/ and apps/apple/ci_scripts/ with git ls-files, run bash -n and shellcheck -x on each, fail closed if shellcheck is missing, no files are found, or any file fails.
2. Fix the existing SC1007 findings (CDPATH= -> CDPATH='') in scripts/check-apple-no-network.sh and scripts/test-check-apple-no-network.sh; same behaviour, matches test-xcode-cloud-ci-scripts.sh.
3. Verify the new check passes with ShellCheck 0.9.0 (ubuntu-24.04 image), 0.10.0 and 0.11.0 (local and ubuntu-26.04 image) so no version pin is required.
4. Update docs/release/distribution.md (and testflight.md where it lists test:fastlane) to say which release-tooling harnesses run in GitHub CI and which stay local on macOS, and that a macOS runner is an owner decision.
5. Hand the coordinator the ci.yml step for the Node and content checks job; do not edit workflows.
6. Run pnpm check:shell, test:apple-network, typecheck, test, check:links, git diff --check and the test guard.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented in 401fc450:
- scripts/check-shell-scripts.sh (pnpm check:shell) lists tracked *.sh under scripts/ and apps/apple/ci_scripts/ with git ls-files -z, runs bash -n and shellcheck -x on each from the repo root, prints the ShellCheck and bash versions, and fails closed (exit 2) when shellcheck or git is unavailable or no files are found, and exits 1 when any file fails. 12 files today, including the checker itself.
- Findings on origin/main (same under ShellCheck 0.9.0, 0.10.0 and 0.11.0): SC1007 x3 in 2 files, scripts/check-apple-no-network.sh lines 4-5 and scripts/test-check-apple-no-network.sh line 4 (CDPATH= cd). Fixed by writing CDPATH='' cd, the same empty per-command assignment test-xcode-cloud-ci-scripts.sh already uses; no inline suppressions. The description's '3 files' no longer matches main: only these 2 files report findings.
- ShellCheck on GitHub runners (actions/runner-images readmes, image 20261026): ubuntu-24.04 ships shellcheck 0.9.0-1, ubuntu-26.04 ships 0.11.0-2; ubuntu-latest moves to 26.04 between 2026-10-19 and 2026-11-19 (runner-images#14748). Both are preinstalled, so no install or pin step is needed.
- Verified check:shell passes with 0.11.0 (local), 0.10.0 (official darwin.aarch64 release binary) and 0.9.0 (apt in an ubuntu:24.04 container, bash 5.2.21, matching the runner). Fail-closed cases checked in a scratch repo: no shellcheck on PATH (exit 2), no tracked files (exit 2), not a git repo (exit 2), bash -n syntax error and SC2086 finding (exit 1, untracked and out-of-scope files ignored, nested scripts/sub/*.sh included).
- Docs: docs/release/distribution.md gains a 'Release-tooling checks: GitHub CI and local' table (check:shell and the four guards in GitHub CI; test:fastlane needs plutil and test:xcode-cloud-scripts needs codesign, xmllint, sandbox-exec, so both stay local on macOS; a macOS runner is an owner decision), and the old manual shellcheck instruction now points to pnpm check:shell. docs/release/testflight.md says test:fastlane needs plutil and is local-only.
- Checks: pnpm check:shell passed (12 files); pnpm test:apple-network and check:apple-network passed; pnpm test:xcode-cloud-scripts 127 passed, 0 failed; pnpm typecheck, pnpm test, pnpm check:links passed; git diff --check clean; test guard passed.
- AC #1 stays unchecked: the coordinator adds the pnpm check:shell step to the ci.yml 'Node and content checks' job, and CI must run it before AC #1 can be checked.
- Out of scope: apps/apple/scripts/export_a11y_evidence.sh is a tracked *.sh outside the two directories in AC #1, so check:shell does not cover it (it passes shellcheck -x 0.11.0 today).
<!-- SECTION:NOTES:END -->
