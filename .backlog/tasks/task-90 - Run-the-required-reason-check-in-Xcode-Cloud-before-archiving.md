---
id: TASK-90
title: Run the required-reason check in Xcode Cloud before archiving
status: To Do
assignee: []
created_date: '2026-11-03T04:10:00Z'
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
- [ ] #1 Xcode Cloud ci_pre_xcodebuild.sh runs check:apple-required-reasons and test:apple-required-reasons with the other guards and fails the archive when either fails
- [ ] #2 scripts/test-xcode-cloud-ci-scripts.sh covers the new guards (pass and fail cases) and passes locally
- [ ] #3 docs/release/distribution.md lists the required-reason check among the Xcode Cloud guards
<!-- AC:END -->
