---
id: TASK-20
title: >-
  Adopt the pull-request workflow: .backlog folder, Copilot review rules and
  agent instructions
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 13:51'
updated_date: '2026-10-01 15:54'
labels:
  - ci
  - docs
  - tooling
milestone: m-0
dependencies:
  - TASK-19
ordinal: 30000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The owner wants every change to reach main through a pull request with Copilot code review and CI, merged by either the owner or the coordinator. Backlog task changes now ride inside each task's PR instead of being committed to main, the GitHub Project (kept current by backlog-sync from all worktrees) is the live board, and the earlier 'move tasks to In Progress on main before branching' rule is retired. Copilot shouldn't spend reviews on Backlog.md's generated task files, and the owner wants the Backlog folder hidden as .backlog/ to keep the repository tidy.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The Backlog folder is moved from backlog/ to .backlog/ using a method the Backlog.md CLI supports (documented in the task notes), and backlog board, task list and doctor all work afterwards
- [ ] #2 Copilot code review is told not to review .backlog/ files via .github/instructions/backlog.instructions.md (applyTo '.backlog/**') and .github/copilot-instructions.md; whether repository content exclusion is available on the owner's plan is recorded
- [ ] #3 CI reports success quickly for PRs that only change .backlog/ (a job-level changes check, not paths-ignore, so a required status check never stays pending), and runs the full checks otherwise
- [ ] #4 AGENTS.md describes the PR workflow (task branch, task status changes in the branch, PR titled '<task-id>: Title', Copilot review and CI before merge, either the owner or the coordinator merges, Apple xbuild per-test results posted in the PR) and the GitHub Project as the live board, and the 'In Progress on main before branching' rule is removed
- [ ] #5 README, docs and tasks/PLAN.md references to backlog/ point to .backlog/
- [ ] #6 After merge, a main branch ruleset requires a pull request, the CI status check and automatic Copilot review (recorded in the task notes)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Move the Backlog.md data folder from backlog/ to .backlog/ with git mv and verify backlog board, task list, and doctor.\n2. Update AGENTS.md for the PR workflow, live GitHub Project board, Copilot review-loop stopping rule, inbox triage, and .backlog task-file conflict guidance while removing the main-before-branching rule.\n3. Update CI to detect .backlog-only pull requests with a job-level changes check and run only a quick success path for those PRs while preserving full checks for all other changes.\n4. Update README/docs/tasks references from backlog/ to .backlog/ and point backlog-sync references at djensenius/backlog-sync where appropriate; verify Copilot skip instructions already include .backlog/** and record that evidence.\n5. Close task-18 as Done with notes/final summary that all AC follow-ups moved to djensenius/backlog-sync task-8, leaving ACs unchecked unless the CLI refuses Done.\n6. Run the requested validation, check task-20 ACs 1-5 with evidence, leave AC 6 unchecked and task-20 In Progress, then commit logical changes without pushing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Research: backlog init --help supports --backlog-dir with backlog, .backlog, or custom project-relative path; Backlog.md 1.53.0 README says project data may live in backlog/, .backlog/, or a custom path, and config discovery checks backlog.config.yml then backlog/config.yml or .backlog/config.yml. Therefore git mv backlog .backlog with the existing config.yml inside the folder is CLI-supported and requires no .backlog-sync.json change because task-19 made the syncer discover the active Backlog directory.
<!-- SECTION:NOTES:END -->
