---
id: TASK-21
title: Tell Copilot code review to skip Backlog.md task files
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 13:51'
updated_date: '2026-10-01 13:52'
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
- [ ] #1 `.github/instructions/backlog.instructions.md` has `applyTo` frontmatter covering both `backlog/**` and `.backlog/**` and tells Copilot code review not to review or comment on those files
- [ ] #2 `.github/copilot-instructions.md` states the same rule repository-wide (and briefly that task files are managed with the backlog CLI)
- [ ] #3 The owner's plan support for repository content exclusion (Settings → Copilot → Content exclusion) is checked and recorded in the task notes, with the path to add if it is available
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Verify GitHub custom-instructions and content-exclusion docs.\n2. Add Copilot instruction files scoped to Backlog task paths and repository-wide review context.\n3. Run link checks, record validation and content-exclusion finding, then finalize task.
<!-- SECTION:PLAN:END -->
