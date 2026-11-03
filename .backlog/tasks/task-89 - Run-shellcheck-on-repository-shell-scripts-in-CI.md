---
id: TASK-89
title: Run shellcheck on repository shell scripts in CI
status: To Do
assignee: []
created_date: '2026-11-03T04:10:00Z'
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
- [ ] #2 Existing shellcheck findings are fixed, or suppressed with a narrow inline directive and a reason, without changing script behaviour
- [ ] #3 Docs that list release-tooling checks state which harnesses run in GitHub CI and which stay local because they need macOS, and that a macOS runner is an owner decision
<!-- AC:END -->
