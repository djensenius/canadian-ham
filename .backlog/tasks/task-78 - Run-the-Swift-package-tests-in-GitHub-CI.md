---
id: TASK-78
title: Run the Swift package tests in GitHub CI
status: To Do
assignee: []
created_date: '2026-10-27T13:24:00Z'
labels:
  - ci
dependencies: []
priority: medium
ordinal: 163000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The Swift packages (content-swift, engine-swift, morse-swift, calculator-swift) and the Swift half of scripts/check-engine-parity.sh only run locally. TASK-64 showed a content-swift test can fall out of date on main without CI noticing. Run them in CI on Linux (the official Swift Docker image; macOS runners cost about 10x for a private repo). Apple-only imports such as os get minimal canImport guards, with no behaviour change on Apple platforms. Apple app suites stay local (xbuild/simulators).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A CI job runs swift test for every Swift package that can build on Linux, plus the Swift half of the engine-parity check if feasible, triggered when those packages, their fixtures or the content they read change
- [ ] #2 Any package that can't run on Linux is documented with the reason, and the ci.yml local-only comment is updated
- [ ] #3 Source guards are minimal (canImport), the Apple-platform behaviour is unchanged, and local swift test plus the macOS app unit command still pass
- [ ] #4 The job passes on the PR, and a deliberately broken test was shown to fail it (recorded in the notes, then reverted)
<!-- AC:END -->
