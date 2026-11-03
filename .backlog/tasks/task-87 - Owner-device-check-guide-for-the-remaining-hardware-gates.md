---
id: TASK-87
title: Owner device-check guide for the remaining hardware gates
status: To Do
assignee: []
created_date: '2026-11-03T02:33:00Z'
labels:
  - docs
  - testing
dependencies: []
priority: medium
type: docs
ordinal: 170000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Several tasks wait only on checks that need the owner and real hardware: TASK-29 (Apple TV VoiceOver on About cards), TASK-14.3 and TASK-14.5 (watch Morse haptics and accessibility), TASK-14.6 (watch install from TestFlight), and TASK-54 with TASK-63 (iPhone Duo). The watch checks already have checklists in docs/testing and docs/release/testflight.md; Apple TV and iPhone Duo do not. Write one guide that lists every owner gate in order with exact steps, expected results and where to record evidence, so the owner can finish them in one sitting.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A single owner-gate guide lists every open hardware or owner check by task and acceptance criterion, links the existing watch checklists, and orders the checks so one device session covers each device
- [ ] #2 It adds step-by-step checklists with expected results for TASK-29 (Apple TV VoiceOver) and TASK-54/TASK-63 (iPhone Duo), copied from their acceptance criteria without adding scope
- [ ] #3 Each listed task's notes link the guide, and the guide states the evidence format the coordinator needs to check off the criteria
<!-- AC:END -->
