---
id: TASK-87
title: Owner device-check guide for the remaining hardware gates
status: Done
assignee:
  - '@worker'
created_date: '2026-11-03T02:33:00Z'
updated_date: '2026-11-03T02:55:00Z'
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
Several tasks wait only on the owner, real hardware or an owner decision: TASK-29 (Apple TV VoiceOver on About cards), TASK-14.3 and TASK-14.5 (watch Morse haptics and accessibility), TASK-14.6 (watch install from TestFlight), TASK-54 (iPhone Duo), TASK-34 (signed-device iCloud checks, DebugCloudKit builds only), and the owner decisions in TASK-65, TASK-1.1, TASK-1.7 and TASK-1.8. Step-by-step checklists already exist for the watch (docs/testing/task-14.3-watch-morse.md, task-14.5-watch-a11y.md, task-14.6-watch-release.md, docs/release/testflight.md) and Apple TV (docs/accessibility.md, Owner listening check (tvOS VoiceOver)); iPhone Duo has none. Write one guide that indexes every owner gate in order, so the owner can finish each device in one sitting, and add the missing iPhone Duo steps. TASK-63 is follow-on product work that depends on TASK-54 results, not an owner check.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A single owner-gate guide lists every open owner-gate task (TASK-1.1, 1.7, 1.8, 14.3, 14.5, 14.6, 29, 34, 54, 65) by task and acceptance criterion, says what the owner must do or decide, and orders the device checks so one session covers each device
- [x] #2 The guide links the existing watch and Apple TV checklists instead of copying them, and adds step-by-step iPhone Duo steps with expected results taken from TASK-54 acceptance criteria without adding scope; TASK-63 is listed only as follow-on work
- [x] #3 Each listed task's notes link the guide, and the guide states the evidence format the coordinator needs to check off the criteria
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read every owner-gate task (TASK-1.1, 1.7, 1.8, 14.3, 14.5, 14.6, 29, 34, 54, 65; TASK-63/15 for context) and note unchecked ACs and required owner evidence.
2. Read the existing watch, Apple TV, flake, licensing, release and iCloud checklists to link (not copy).
3. Write docs/release/owner-gates.md: per-task/per-AC index, one sitting per device (Apple Watch, Apple TV, iPhone Duo, signed-device iCloud DebugCloudKit, owner decisions), iPhone Duo steps from TASK-54 ACs only, TASK-63 as follow-on, evidence format.
4. Link the guide from docs/release/release-checklist.md near the manual gates.
5. Append a note linking the guide to each listed task.
6. Validate relative links/anchors; run pnpm check:links if it covers docs.
7. Finalize TASK-87 (notes, ACs, summary, Done) and commit.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Evidence 2026-11-03: docs commit b83f7aa4 adds docs/release/owner-gates.md (at-a-glance table for all 10 owner-gate tasks from 'backlog task list -l owner-gate' with open ACs; reporting template; Sitting 1 decisions (TASK-1.7 repo already public, 1.1, 1.8, 65, TASK-34 AC6-8); Sitting 2 Apple Watch, which links the testflight.md owner checklist and the TASK-14.3/14.5/14.6 docs; Sitting 3 Apple TV, which links accessibility.md#owner-listening-check-tvos-voiceover; Sitting 4 iPhone Duo steps restating TASK-54 AC1-7, with implementation-note observations marked as not criteria; Sitting 5 DebugCloudKit-only iCloud steps for TASK-34; follow-on section listing TASK-63 only) and one link line under Gates in docs/release/release-checklist.md. Guide-link notes appended to TASK-1.1, 1.7, 1.8, 14.3, 14.5, 14.6, 29, 34, 54 and 65 (statuses unchanged). Checks: a throwaway node link/anchor check over both files reported 'checked 86 relative links, 0 problems' (not committed); pnpm check:links reported 'Markdown relative links verified.' (exit 0) and covers every repo .md file including anchors; git diff --check was clean. No code, builds or Apple tests. Open: the coordinator must supply the processed TestFlight build numbers; which result screen TASK-54 AC2 means is unclear, so the guide keeps it generic.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added docs/release/owner-gates.md, one guide to the remaining owner-only gates. It lists every open owner-gate task and unchecked criterion with the owner's action or decision, and groups the work into one sitting each for decisions (no device), Apple Watch, Apple TV, iPhone Duo and signed-device iCloud (DebugCloudKit only), with the build each sitting needs. It links the existing watch and tvOS checklists instead of copying them. It adds iPhone Duo steps whose expected results restate TASK-54 AC1-7, lists TASK-63 only as follow-on work, notes the already-public repository as a TASK-1.7 owner decision, and sets out the per-criterion evidence format and where to report it. Linked from the release checklist gates; each owner-gate task's notes link the guide. Verified with pnpm check:links and a throwaway anchor check (86 links, 0 problems). Risks: build numbers must come from the coordinator; device steps describe expected results only from existing criteria and design notes, and the owner's observations decide each criterion.
<!-- SECTION:FINAL_SUMMARY:END -->
