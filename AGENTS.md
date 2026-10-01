# Agent instructions

## Coordinator rules (the Pi session in the root pane)
- You are the coordinator. Plan and delegate; do not edit source files yourself.
- Break work into small, independent tasks with clear acceptance criteria.
- Track all work in Backlog.md (see "Backlog.md task workflow" below); `tasks/PLAN.md` is only a
  pointer and legacy ID map. The coordinator creates tasks and keeps their status current.
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
- The repo stays private until T-009, which requires T-007 permission records and T-607 release checks; never make it public, deploy, or distribute builds before then; see `docs/content-licensing.md`.
- Apple app must work fully offline and collect no data; no networking code, third-party SDKs, analytics, or iCloud sync in v1.
- Use `xbuild` for Apple builds/tests; never call `xcodebuild` directly.

## Apple builds
- Scheme: `CanadianHam`.
- Always run Apple builds/tests through `xbuild`, never direct `xcodebuild`.
- `xcode-select` points at CommandLineTools on this machine, so prefix Apple build/test commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- iOS simulator test command, using the single requested simulator destination and running both unit and UI tests:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test CODE_SIGNING_ALLOWED=NO`
- macOS test command (unit tests only; UI tests are iOS-only, and SDK/platform overrides keep the auto platform target on macOS while signing locally):
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES`
- tvOS simulator test command:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamTV -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' test CODE_SIGNING_ALLOWED=NO`
- visionOS simulator test command:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamVision -destination 'platform=visionOS Simulator,name=Apple Vision Pro' test CODE_SIGNING_ALLOWED=NO`
- visionOS generic simulator build fallback if the named simulator runtime is unavailable:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamVision -destination 'generic/platform=visionOS Simulator' build CODE_SIGNING_ALLOWED=NO`
- Regenerate the Apple project after editing `apps/apple/project.yml` or target membership:
  `cd apps/apple && /opt/homebrew/bin/xcodegen generate --spec project.yml`
- Check regeneration determinism by running the XcodeGen command twice and confirming `git diff -- apps/apple/CanadianHam.xcodeproj` is empty.
- Commit both `apps/apple/project.yml` and the generated `apps/apple/CanadianHam.xcodeproj` so Xcode can open the project without XcodeGen.

## Backlog.md task workflow (all agents)
Backlog.md (`backlog/`) is the single source of truth for work. The GitHub Project and issues are a
read-only mirror produced by `tools/backlog-sync`; never track work there (except the `inbox` label, below).

- Always use the `backlog` CLI to read and change tasks, with `--plain` for output meant for agents
  (`backlog task list --plain`, `backlog task view task-12 --plain`, `backlog board`).
  Never create or edit files in `backlog/` directly.
- Task changes are auto-committed (`autoCommit: true`) on the branch you run the CLI on, and the board
  reads every active branch (`checkActiveBranches: true`). Run task updates for branch work from that
  task's worktree so the status travels with the branch.
- Before creating a task, search first (`backlog search "<words>" --plain`) and don't duplicate an
  existing task; extend it or ask instead. New tasks need a clear description and acceptance criteria
  (`--ac`), and use `--dep` for dependencies and `-p` for subtasks.
- Before starting work: pick a `To Do` task whose dependencies are all `Done`, then
  `backlog task edit task-12 -s "In Progress" -a @<your-name>`.
- Before writing code, add a short implementation plan: `backlog task edit task-12 --plan "1. ..."`.
- Put the task ID in the branch name and PR title, e.g. branch `task-12-short-slug`, worktree
  `../canadian-ham-task-12`, PR "task-12: Short title".
- While working, record progress with `--append-notes`. Scope outside the acceptance criteria needs a
  follow-up task or the owner's OK; don't silently expand a task.
- When finished: verify each acceptance criterion with real evidence, then check it
  (`--check-ac <n>`), add implementation notes, write `--final-summary`, and move the task to `Done`.
- If you're blocked: say so in the task notes (`--append-notes "Blocked: ..."`), leave the task
  `In Progress`, and tell the owner (subagents tell the coordinator).
- Issues the owner opens on GitHub with the label `inbox` are imported as new `To Do` tasks by the sync;
  triage them like any other task.

<!-- BACKLOG.MD GUIDELINES START -->
<!-- backlog.md-instructions-version: 1.53.0 -->
<CRITICAL_INSTRUCTION>

## Backlog.md Workflow

This project uses Backlog.md for task and project management.

**At the beginning of each conversation in this project, run `backlog instructions overview` before answering or taking action. Re-read it only if you have not read it yet in the current conversation.**

Use the overview to decide whether to search, read, create, or update Backlog tasks.

Before task lifecycle actions, read the matching detailed guide:
- `backlog instructions task-creation` before creating or splitting tasks
- `backlog instructions task-execution` before planning, changing status or assignee, adding a plan or implementation notes, or implementing task work
- `backlog instructions task-finalization` before checking acceptance criteria, writing final summaries, or moving tasks to terminal statuses

Use `backlog <command> --help` before running unfamiliar commands. Help shows options, fields, and examples.

Do not edit Backlog task, draft, document, decision, or milestone markdown files directly. Use the `backlog` CLI so metadata, relationships, and history stay consistent.

</CRITICAL_INSTRUCTION>
<!-- BACKLOG.MD GUIDELINES END -->
