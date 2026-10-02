---
id: TASK-12.1
title: Source-check the Morse trainer brief and record decisions
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 01:11'
labels:
  - docs
milestone: m-1
dependencies: []
parent_task_id: TASK-12
ordinal: 21000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Verify the claims in the Morse trainer research brief against the current ISED RBR-4, RIC-1 and RIC-3, including the receive/send test format and the pass criteria (the brief contradicts itself on '100%' vs '<= 5 errors'). Commit it to docs/proposals/morse-trainer.md and record the owner's decisions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The test format and pass criteria are confirmed from ISED documents
- [x] #2 The brief is committed under docs/proposals/
- [x] #3 The owner's decisions are recorded in the parent task notes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Copy the source-checked Morse brief into docs/proposals/ with only formatting/link/project-scope cleanup.
2. Preserve verified facts while adding the proposals index and relative project links.
3. Run pnpm check:links, check only the supported acceptance criteria, record open owner decisions, and commit.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Committed draft prepared in docs/proposals/morse-trainer.md with docs/proposals/README.md index. Validation passed: pnpm check:links. Verification summary claim counts: Corrected 3; Corrected (narrower than stated) 1; Corrected (project rule) 1; ISED wording verified/arithmetic does not support 5 wpm 1; Partly corrected 1; Partly verified 1; Unclear 1; Unverified 2; Verified family 23; total 34.

Open owner decisions (AC #3 remains unchecked): scope integrated module vs separate app; default character speed 12 wpm vs 15–18 wpm; sending evaluation microphone pitch detection vs tap timing; exam timing profile PARIS-calibrated 12/5 vs RIC-1 literal/harder option; haptics scope on supportsHaptics-capable devices only.

Addressed Copilot comment 4161264976 by correcting the WCAG 2.3.1 flash-area threshold (21,824 CSS px), adding red-flash/general-flash threshold guidance, merging origin/main's advanced-course proposal index entry, and rerunning pnpm check:links (passed).

2026-10-02: the owner accepted all recommendations; the decisions are recorded in the parent task notes.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Source-checked the brief and committed it as docs/proposals/morse-trainer.md (PRs #64, after Copilot review rounds; pnpm check:links passed). The owner's decisions (all recommendations accepted on 2026-10-02) are recorded in the parent task notes.
<!-- SECTION:FINAL_SUMMARY:END -->
