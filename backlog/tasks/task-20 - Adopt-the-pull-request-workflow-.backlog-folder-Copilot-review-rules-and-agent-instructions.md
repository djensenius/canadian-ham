---
id: TASK-20
title: >-
  Adopt the pull-request workflow: .backlog folder, Copilot review rules and
  agent instructions
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 13:51'
updated_date: '2026-10-01 15:53'
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
