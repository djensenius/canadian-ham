---
id: TASK-78
title: Run the Swift package tests in GitHub CI
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-27T13:24:00Z'
updated_date: '2026-10-27T13:29:00Z'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect Linux portability and fixture/content inputs for all four Swift packages; verify an official Swift image and Docker availability.
2. Add minimal conditional imports/logging and a path-classified Linux Swift CI job covering all portable packages and engine fixture parity; update local-only documentation.
3. Run Linux and macOS package tests, macOS app unit tests, iOS build-for-testing, pnpm test, and focused workflow/test-guard checks.
4. Commit/push a temporary failing test to a draft verification PR, capture the failing job, revert the assertion and capture the passing run; record evidence, finalize task, commit and push.

5. Approved coordinator refinement: keep content-swift in Linux CI by conditionally compiling its Apple-Foundation Markdown renderer and heading anchors; move only the 10 renderer-dependent tests into one Darwin-only file. Keep all 17 loader/model/validation/front-matter/explanation tests in Linux CI and preserve all 27 tests on macOS.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Docker available via OrbStack. Official swift:6.4 and swift:6.4.1 manifests exist; swift:6.4 currently supplies Swift 6.4.1. Initial Linux run: morse-swift and calculator-swift pass unchanged; engine fixture comparator needs explicit CoreFoundation import. content-swift needs both os logging guards and an Apple-only renderer split because Linux Foundation has no AttributedString(markdown:options:) or MarkdownParsingOptions. Coordinator approved preserving Linux content coverage via a minimal Darwin-only source/test split; no fake Markdown renderer, skips or new dependencies. Before split: macOS content-swift 27/27 tests pass. No package is excluded; only the 10 renderer/heading-anchor tests stay Darwin-only.
<!-- SECTION:NOTES:END -->
