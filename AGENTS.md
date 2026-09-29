# Agent instructions

## Coordinator rules (the Pi session in the root pane)
- You are the coordinator. Plan and delegate; do not edit source files yourself.
- Break work into small, independent tasks with clear acceptance criteria.
- Keep the running plan in `tasks/PLAN.md`; update it as tasks complete.
- Use a `scout` subagent to investigate before assigning implementation.
- Use a `worker` subagent for implementation, one at a time. Before each
  worker, create a persistent branch and worktree
  (`git worktree add ../<repo>-<task> -b <branch>`) and launch the worker with
  `cwd` set to that worktree. Do not use managed `worktree: true` runs here:
  they return a patch and delete their branch, which breaks branch review.
  Each worker commits to its branch and reports the branch, full 40-character
  commit SHA, files, and checks run.
- After each worker finishes, start a `reviewer` on that branch/commit with the
  task spec. Require it to fetch every `review_git` output page. Only integrate
  on APPROVE or APPROVE WITH NOTES.
- After integrating: build and run tests on the main checkout before starting
  any dependent worker, then remove the task worktree with
  `git worktree remove`.
- Push finished branches to the `origin` remote so work is not only in worktrees.

## Build and test rules (all agents)
- Never call `xcodebuild` directly. Always use `xbuild` with the same arguments;
  it serializes builds across all agents and cleans up simulators.
- Prefer one simulator destination per run; do not boot extra simulators.
- If a build is waiting on the lock, wait. Do not kill other builds.

## Project notes
- Monorepo layout planned as `content/`, `apps/web/`, `apps/apple/`, `packages/`, `fixtures/`, `docs/`, and `tasks/`.
- Active question bank is only ISED Basic 2025-07-15; delimited TXT SHA-256 `34c7cd7967addfde648c566d0ecf25bf3d1e071c603b5101cfecc7bd0cbc284f`.
- Preserve ISED EN/FR question text verbatim; original lessons/explanations stay separate from official data.
- The repo is private until ISED permission is recorded (T-007). Never make it public, deploy, or distribute builds before then; see `docs/content-licensing.md`.
- Apple app must work fully offline and collect no data; no networking code, third-party SDKs, analytics, or iCloud sync in v1.
- Use `xbuild` for Apple builds/tests; never call `xcodebuild` directly.
