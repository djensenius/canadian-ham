---
id: TASK-21
title: Tell Copilot code review to skip Backlog.md task files
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 13:51'
updated_date: '2026-10-01 13:53'
labels:
  - ci
  - docs
milestone: m-0
dependencies: []
ordinal: 29000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Every change now goes through a pull request with Copilot code review, and task status changes ride inside those PRs. Backlog.md's task files are generated and maintained by its CLI, so Copilot comments on them are noise that the owner would have to dismiss on every PR. This lands first, so the following PRs (including the move to .backlog/) are already covered.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `.github/instructions/backlog.instructions.md` has `applyTo` frontmatter covering both `backlog/**` and `.backlog/**` and tells Copilot code review not to review or comment on those files
- [x] #2 `.github/copilot-instructions.md` states the same rule repository-wide (and briefly that task files are managed with the backlog CLI)
- [x] #3 The owner's plan support for repository content exclusion (Settings → Copilot → Content exclusion) is checked and recorded in the task notes, with the path to add if it is available
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Verify GitHub custom-instructions and content-exclusion docs.\n2. Add Copilot instruction files scoped to Backlog task paths and repository-wide review context.\n3. Run link checks, record validation and content-exclusion finding, then finalize task.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Docs/validation: GitHub's repository custom instructions doc (https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions) says path-specific instructions live in .github/instructions/NAME.instructions.md and use applyTo glob frontmatter; its reusable source says multiple patterns are comma-separated (example applyTo: "**/*.ts,**/*.tsx"). GitHub's 2025-09-03 code-review changelog (https://github.blog/changelog/2025-09-03-copilot-code-review-path-scoped-custom-instruction-file-support/) says Copilot code review recognizes *.instructions.md files with applyTo path globs. Content exclusion: GitHub's content-exclusion doc (https://docs.github.com/en/copilot/how-tos/configure-content-exclusion/exclude-content-from-copilot) is marked for Copilot Business/Enterprise, so I found no repository-level content exclusion support for a personal/user-owned Copilot Pro or Pro+ repository. If the owner later has the setting available, the repository-level paths to enter are - "/.backlog/**" and - "/backlog/**". Validation passed: pnpm check:links; Python assertions verified both instruction files' required rules/context.
<!-- SECTION:NOTES:END -->
