# Agent instructions

## Coordinator rules (the Pi session in the root pane)
- You are the coordinator. Plan and delegate; do not edit source files yourself.
- Break work into small, independent tasks with clear acceptance criteria.
- Track all work in Backlog.md (see "Backlog.md task workflow" below); `tasks/PLAN.md` is only a
  pointer and legacy ID map. The GitHub Project is the live board, mirrored from Backlog.md by
  [`djensenius/backlog-sync`](https://github.com/djensenius/backlog-sync).
- At the start of each coordinator session, triage open GitHub issues labelled `inbox`: search first,
  create or update Backlog tasks from the task branch workflow below, and then remove the `inbox`
  label manually because this repository uses backlog-sync `inbox.mode: manual`.
- Use a `scout` subagent to investigate before assigning implementation.
- Use a `worker` subagent for implementation, one at a time. Before each worker, create a persistent
  task branch and worktree (`git worktree add ../<repo>-<task> -b <branch>`) and launch the worker
  with `cwd` set to that worktree. Do not use managed `worktree: true` runs here: they return a patch
  and delete their branch, which breaks branch review. Task status changes ride on the task branch,
  not on `main`. Each worker commits to its branch and reports the branch, full 40-character commit
  SHA, files, and checks run.
- After each worker finishes, start a `reviewer` on that branch/commit with the task spec. Require it
  to fetch every `review_git` output page. Only open a pull request on APPROVE or APPROVE WITH NOTES.
- Push the approved branch and open a pull request titled `task-N: Title` that names the Backlog task,
  lists checks run, and includes Apple `xbuild` per-test results in the PR body when Apple tests were
  run. Automatic Copilot code review and CI must pass before merge.
- Review-loop stopping rule: fix high-severity findings and re-request review. Medium or low findings,
  or ones that don't fit the project, are fixed or answered with reasoning and resolved. Findings about
  code the PR didn't change become follow-up Backlog tasks. Merge when the latest Copilot review has no
  unresolved high-severity findings and CI is green.
- Either the owner or the coordinator merges the pull request. After merging: update the main checkout,
  run the quick checks there (`pnpm typecheck`, `pnpm test`, and the checks for what merged; full Apple
  suites only if the merge combined Apple changes from more than one branch) before starting any
  dependent worker, then remove the task worktree with `git worktree remove`.

## Internal TestFlight builds
- After a feature merges to main, the coordinator uploads internal TestFlight builds from the main checkout for all four platforms (`fastlane ios beta`, `mac beta`, `appletvos beta`, `xros beta`). Run the post-merge iOS/macOS checks first. Build numbers are timestamps.
- Signing uses the dedicated build keychain described in `docs/release/testflight.md`; never ask for or handle the login keychain password.
- Internal testers only until task-1.7: no external groups, public links or App Store submission.

## Build and test rules (all agents)
- Never call `xcodebuild` directly. Always use `xbuild` with the same arguments;
  it serializes builds across all agents and cleans up simulators.
- Prefer one simulator destination per run; do not boot extra simulators.
- If a build is waiting on the lock, wait. Do not kill other builds.

## Testing policy (all agents)
Test what changed, once, at the right level. Full Apple suites are slow (20-40 min per
platform) and share one build lock, so don't run them by reflex.
- **While iterating:** run only what you touched: the relevant web/package tests, Apple unit
  tests, and the specific UI test classes or methods with `-only-testing:` (one platform).
- **During review (internal reviewer and Copilot):** keep running only the relevant tests: the
  affected web/package tests and the specific Apple test classes or methods with
  `-only-testing:` for what each fix touches. No full suites during review rounds.
- **Once per merge batch, just before merge (owner decision 2026-10-14):** Apple PRs that are
  approved (internal review approved, all Copilot feedback addressed, targeted tests green) wait
  in a merge batch. The coordinator merges them, in order, onto a short-lived `train-<date>`
  branch from main and runs the full suite once for each platform any of them changed. If it
  passes, the PRs merge to main in the same order with no further suite runs. If it fails, the
  coordinator finds the responsible PR with targeted tests, takes it out of the batch, and reruns
  only the failed platform's full suite. Web-only and content-only PRs don't wait for a batch.
  Which platforms count as changed:
  - web or TS package changes: `pnpm typecheck`, `pnpm test`, plus the checks for what changed
    (`pnpm build:web` and the URL/CSP audit for web; `pnpm check:schemas` and `pnpm import:check`
    for content and schemas).
  - Apple code: decide by target membership in `apps/apple/project.yml`, not by folder. Run
    the suite of every platform whose target compiles a changed file or links a changed Swift
    package. iOS and macOS share the `CanadianHam` target; tvOS and visionOS also compile some
    files from `apps/apple/CanadianHam/` and link `packages/engine-swift` and
    `packages/morse-swift`, so changes there usually need their suites too. Code only under
    `apps/apple/Platforms/<platform>/` or a platform's test target needs only that platform.
  - Swift package: `swift test` in the package (or its `xbuild` scheme), plus the suites of
    every app target that links it.
  - String catalogue or SwiftUI text: `pnpm check:apple-l10n` and
    `node scripts/check-apple-text-sources.ts`, plus the affected platforms.
- **No Apple suites** for web-only, docs-only or Backlog-only changes, and never rerun suites
  after a commit that only changes `.backlog/` or docs.
- **Fix rounds:** rerun only the failing or changed tests with `-only-testing:`; the single full
  run happens in the merge batch (above).
- **Lesson figure audits:** the per-lesson figure audits (`CanadianHamLessonFiguresUITests`) run
  in their own test plan, only when figures, `content/figures/`, lesson Markdown with figure
  directives, or the lesson reader change (owner decision 2026-10-14; task-33 moves them out of
  the default plan).
- **Release candidate (task-1.6):** the full four-platform run with every accessibility audit,
  plus the manual checks in `docs/release/release-checklist.md`.
- Record per-test results for the full runs you did in the task notes and PR body, and say
  which platforms you skipped and why.

### Approved accessibility audit exceptions
- Task-42 Morse settings description: a narrow contrast exception is approved for the known Morse
  settings description false positive; task-42 should generalize it onto the shared occluded-content
  helper rather than adding a separate filter.
- Lesson and Morse screens: owner decision 2026-10-12 approves ignoring only contrast audit issues
  whose element frame is not fully contained in the visible scroll area below an opaque navigation
  bar. Fully visible contrast issues and every non-contrast issue must still fail.
- Task-44.3 exam tool: owner decision 2026-10-12 approves the medium-detent rule that text inside
  the exam tool panel's scroll content may be clipped at larger Dynamic Type sizes; task-44.3
  implements that exception.

## CI test guard
- The separate `Test guard` pull-request workflow runs the base branch copy of
  `scripts/check-test-guard.mjs` when it exists (falling back to the PR copy only while bootstrapping
  the checker), first with `--self-test` and then against the PR merge-base...head diff. The
  `Test guard` status check should be required in branch protection (coordinator configures this on
  GitHub).
- The guard fails when Apple diffs add, remove or narrow `performAccessibilityAudit` calls or handler
  code, change the named shared audit/positioning helpers listed in `SHARED_HELPERS`, call the approved
  exception helpers, add `.accessibilityHidden(true)`, add `.accessibilityElement(children: .ignore)` or
  `.accessibilityElement()`, add `XCTSkip`/`XCTSkipIf`/`XCTSkipUnless`, add `.minimumScaleFactor(` in app
  views, delete Swift `func test...` methods, or change the guard checker/workflow itself.
- A PR body line exactly matching `Test-guard-approved: task-<number>` or
  `Test-guard-approved: owner decision YYYY-MM-DD` approves intentional findings. The marker must start
  at the beginning of its own line with no bullet or indentation; markers inside fenced code blocks or
  HTML comments are ignored. Reviewers verify that the referenced task or owner decision actually
  approves the guarded change before accepting the marker.
- The workflow listens for PR body edits, so adding or fixing an approval marker starts a new
  `Test guard` run without pushing another commit. If GitHub does not start that edited-event run,
  re-trigger the separate `Test guard` workflow/check after saving the PR body rather than re-running
  an older failed run with its stale event payload or re-running all CI.
- The guard is a heuristic backstop, not a substitute for review; reviewers remain responsible for
  spotting test or audit weakening that does not match its patterns.

## Project notes
- Monorepo layout planned as `content/`, `apps/web/`, `apps/apple/`, `packages/`, `fixtures/`, `docs/`, and `tasks/`.
- Active app question bank remains ISED Basic 2025-07-15; delimited TXT SHA-256 `34c7cd7967addfde648c566d0ecf25bf3d1e071c603b5101cfecc7bd0cbc284f`.
- Advanced exception: verbatim Advanced question-bank source files may be vendored under `content/sources/ised/advanced-<title-page-date>/` only under the interim private-development policy in `docs/content-licensing.md`; no Advanced bank is active in the apps yet.
- Preserve ISED EN/FR question text verbatim; original lessons/explanations stay separate from official data.
- The repo stays private until T-009, which requires T-007 permission records and T-607 release checks; never make it public, deploy, or distribute builds before then, except internal TestFlight builds to App Store Connect team members (task-1.10; no external testers, public links, or App Store submission until task-1.7); see `docs/content-licensing.md` and `docs/release/testflight.md`.
- Apple app targets iOS/iPadOS 27.0, macOS 27.0, tvOS 27.0, and visionOS 27.0 minimums.
- Apple app release builds for v1 must work fully offline and collect no data; no networking code, third-party SDKs, analytics, or iCloud sync in v1.
- Optional CloudKit sync work may land on main only behind an off-by-default build gate for after v1: CloudKit, Push Notifications, and the remote-notification background mode are allowed only in the non-default `DebugCloudKit` Apple build configuration, which defines `ICLOUD_SYNC`. The gated container ID is `iCloud.org.davidjensenius.CanadianHam`. Default `Debug`/`Release`, CI, and the test commands below must have no iCloud or push capability, no remote-notification background mode, and no Settings iCloud toggle. v1 release builds must have no iCloud or push capability.
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
Backlog.md (`.backlog/`) is the single source of truth for work. The GitHub Project is the live board,
mirrored from every worktree by [`djensenius/backlog-sync`](https://github.com/djensenius/backlog-sync);
never track work directly on GitHub except for owner-created issues with the `inbox` label.

- At the start of a session, run `backlog instructions overview`, then read the detailed guide for the
  action you are about to take. Coordinators also check for open GitHub issues labelled `inbox`, triage
  them into Backlog tasks (search first), and remove the label manually after triage because this
  repository uses backlog-sync `inbox.mode: manual`.
- Always use the `backlog` CLI to read and change tasks, with `--plain` for output meant for agents
  (`backlog task list --plain`, `backlog task view task-12 --plain`, `backlog board`). Never create or
  edit files in `.backlog/` directly.
- Task changes are auto-committed (`autoCommit: true`) on the branch you run the CLI on. Start and
  update a task from its own branch/worktree: set it In Progress and assign it there, then make every
  later change (plan, notes, checked criteria, final summary, Done) from the task's worktree so it
  reaches main through the PR. The GitHub Project is kept current from worktrees; `backlog board` on
  main catches up when PRs merge. If a merge conflicts only in a task file under `.backlog/`, keep the
  branch's version.
- Before creating a task, search first (`backlog search "<words>" --plain`) and don't duplicate an
  existing task; extend it or ask instead. Create new tasks (including inbox triage) on a branch and
  land them through a PR because `main` is PR-only. New tasks need a clear description and acceptance
  criteria (`--ac`), and use `--dep` for dependencies and `-p` for subtasks.
- Before writing code, add a short implementation plan: `backlog task edit task-12 --plan "1. ..."`.
- Put the task ID in the branch name and PR title, e.g. branch `task-12-short-slug`, worktree
  `../canadian-ham-task-12`, PR "task-12: Short title".
- While working, record progress with `--append-notes`. Scope outside the acceptance criteria needs a
  follow-up task or the owner's OK; don't silently expand a task.
- When finished: verify each acceptance criterion with real evidence, then check it
  (`--check-ac <n>`), add implementation notes, write `--final-summary`, and move the task to `Done`.
- If you're blocked: say so in the task notes (`--append-notes "Blocked: ..."`), leave the task
  `In Progress`, and tell the owner (subagents tell the coordinator).

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
