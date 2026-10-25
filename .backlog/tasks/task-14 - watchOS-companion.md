---
id: TASK-14
title: watchOS companion
status: Done
assignee:
  - '@worker'
created_date: 2026-10-01 02:27
updated_date: '2026-10-25T17:03:00Z'
labels:
  - apple
  - legacy:T-703
milestone: m-1
dependencies: []
documentation:
  - docs/proposals/watchos-companion.md
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Investigate a watchOS companion only after the Apple v1 privacy posture is stable. Legacy: T-703.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A short proposal covers the use cases, the data model and how the companion stays offline and data-free
- [x] #2 The owner has decided whether to build it
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect current Apple targets, practice/Morse code, package manifests, content sizes, release configuration, and installed watchOS simulator runtime.
2. Write the scoped offline watchOS proposal and create six dependent implementation subtasks through Backlog.
3. Validate the proposal and task graph, record the owner decision and AC evidence, complete TASK-14, commit and push this branch without opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision 2026-10-25: yes, build the watchOS companion ("go ahead and get started on watch"). This lane completes the proposal and implementation-task breakdown only; the app itself will be built in the subtasks.

AC1 evidence: docs/proposals/watchos-companion.md (1,105 words; indexed in docs/proposals/README.md) covers all four wrist-sized use cases, full Basic bank/data reuse, explicit exclusions, offline/Data Not Collected guarantees, accessibility, testing, distribution and risks. Proposal committed in 8fbb0e32. AC2 evidence: owner decision 2026-10-25 recorded above and in the proposal: yes, build the watch companion.
Created TASK-14.1 through TASK-14.6 through the CLI, all To Do and unassigned, with specific ACs, proposal links and a sequential dependency chain: target/packages -> quick practice -> Morse haptics -> alphabet reference -> EN/FR/accessibility -> TestFlight/icon. This parent is intentionally proposal-complete; the unbuilt app is carried by those subtasks.
Validation: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list runtimes confirmed watchOS 27.0 installed, builds 24R5355a and 24R362; simctl list devices available confirmed Apple Watch Series 12 (42mm). Local WatchSimulator XCUIAutomation header declares performAccessibilityAudit from watchOS 10. No simulator was booted.
Python inline validation passed: proposal/index local links resolve; 984 bilingual Basic questions map to 984 EN-only explanations; measured raw bytes match the proposal (bank 1,308,618 + explanations 1,052,351 = 2,360,969, 2.25 MiB); all three package manifests currently omit watchOS; all six children have unchecked ACs, the expected parent, explicit dependencies and no speculative execution plans. git diff --check df921d06 passed.
No app/package/build/fastlane code changed and no tests added; iOS/macOS/tvOS/visionOS/watchOS suites deliberately not run for this docs/Backlog-only lane. Risks delegated to subtasks: watch package compilation, installed memory/startup cost, tiny-screen EN/FR layouts, fixed-preset haptic fidelity on hardware, and iOS-container signing/TestFlight packaging. No PR or TestFlight upload in this lane.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Completed the owner-approved offline watchOS companion proposal and created TASK-14.1–14.6 with acceptance criteria and ordered dependencies. Runtime, resource-size, local-link and task-graph checks passed. TASK-14 completes proposal/decision scope only; app implementation, hardware haptic validation and internal TestFlight remain in the six To Do subtasks.
<!-- SECTION:FINAL_SUMMARY:END -->
