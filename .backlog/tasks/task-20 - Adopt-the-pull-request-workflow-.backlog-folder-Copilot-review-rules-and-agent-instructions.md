---
id: TASK-20
title: >-
  Adopt the pull-request workflow: .backlog folder, Copilot review rules and
  agent instructions
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 13:51'
updated_date: '2026-10-01 16:02'
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
- [x] #1 The Backlog folder is moved from backlog/ to .backlog/ using a method the Backlog.md CLI supports (documented in the task notes), and backlog board, task list and doctor all work afterwards
- [x] #2 Copilot code review is told not to review .backlog/ files via .github/instructions/backlog.instructions.md (applyTo '.backlog/**') and .github/copilot-instructions.md; whether repository content exclusion is available on the owner's plan is recorded
- [x] #3 CI reports success quickly for PRs that only change .backlog/ (a job-level changes check, not paths-ignore, so a required status check never stays pending), and runs the full checks otherwise
- [x] #4 AGENTS.md describes the PR workflow (task branch, task status changes in the branch, PR titled '<task-id>: Title', Copilot review and CI before merge, either the owner or the coordinator merges, Apple xbuild per-test results posted in the PR) and the GitHub Project as the live board, and the 'In Progress on main before branching' rule is removed
- [x] #5 README, docs and tasks/PLAN.md references to backlog/ point to .backlog/
- [ ] #6 After merge, a main branch ruleset requires a pull request, the CI status check and automatic Copilot review (recorded in the task notes)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Move the Backlog.md data folder from backlog/ to .backlog/ with git mv and verify backlog board, task list, and doctor.
2. Update AGENTS.md for the PR workflow, live GitHub Project board, Copilot review-loop stopping rule, inbox triage, and .backlog task-file conflict guidance while removing the main-before-branching rule.
3. Update CI to detect .backlog-only pull requests with a job-level changes check and run only a quick success path for those PRs while preserving full checks for all other changes.
4. Update README/docs/tasks references from backlog/ to .backlog/ and point backlog-sync references at djensenius/backlog-sync where appropriate; verify Copilot skip instructions already include .backlog/** and record that evidence.
5. Close task-18 as Done with notes/final summary that all AC follow-ups moved to djensenius/backlog-sync task-8, leaving ACs unchecked unless the CLI refuses Done.
6. Run the requested validation, check task-20 ACs 1-5 with evidence, leave AC 6 unchecked and task-20 In Progress, then commit logical changes without pushing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Research: backlog init --help supports --backlog-dir with backlog, .backlog, or custom project-relative path; Backlog.md 1.53.0 README says project data may live in backlog/, .backlog/, or a custom path, and config discovery checks backlog.config.yml then backlog/config.yml or .backlog/config.yml. Therefore git mv backlog .backlog with the existing config.yml inside the folder is CLI-supported and requires no .backlog-sync.json change because task-19 made the syncer discover the active Backlog directory.

Implementation/validation evidence: moved Backlog.md data with git mv backlog .backlog. CLI support evidence: backlog init --help documents --backlog-dir accepting backlog, .backlog, or custom project-relative paths; Backlog.md 1.53.0 README says settings resolve from backlog.config.yml, then backlog/config.yml or .backlog/config.yml. Post-move commands passed: backlog task list --plain, backlog doctor, and backlog board. Copilot skip verification: task-21 completed .github/instructions/backlog.instructions.md with applyTo covering backlog/**,.backlog/** plus .github/copilot-instructions.md; task-21 notes record no personal/user-owned Copilot Pro/Pro+ repository content-exclusion support found, with /.backlog/** and /backlog/** fallback paths if it becomes available. CI now has a Change classification job and keeps the Node/content status green quickly for .backlog-only PRs while running full checks otherwise. AGENTS.md now documents task-branch PR workflow, branch-local task status changes, PR title format, automatic Copilot review and CI, owner/coordinator merge, Apple xbuild per-test PR-body expectation, inbox manual triage, the GitHub Project live board, and the copied Copilot review-loop stopping rule. README/docs/tasks references now point to .backlog/ and the syncer docs point to djensenius/backlog-sync. Validation passed: pnpm typecheck; pnpm test; pnpm check:links; pnpm check:apple-network; backlog task list --plain; backlog doctor; backlog board. actionlint was not available on PATH. AC #6 is intentionally left unchecked for coordinator follow-up after merge.

Fix round: addressed reviewer medium/low notes by making Node and content checks run when not cancelled and fail first if change classification is not success; changed classification to git diff --name-only --no-renames BASE...HEAD; clarified that new tasks, including inbox triage, are created on a branch and land through a PR because main is PR-only; aligned inbox wording with backlog-sync inbox.mode: manual. Validation passed: pnpm check:links; go run github.com/rhysd/actionlint/cmd/actionlint@latest.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Moved Backlog.md data to .backlog/ with CLI-supported discovery evidence, updated PR/workflow instructions and docs, added .backlog-only CI change classification, verified Copilot skip coverage from task-21, and closed task-18 as moved to djensenius/backlog-sync task-8. Verified with pnpm typecheck, pnpm test, pnpm check:links, pnpm check:apple-network, backlog task list --plain, backlog doctor, and backlog board. Leaving task-20 In Progress because AC #6 (main branch ruleset after merge) remains coordinator-owned.
<!-- SECTION:FINAL_SUMMARY:END -->
