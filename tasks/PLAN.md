# Moved to Backlog.md

Work is tracked in [`.backlog/`](../.backlog/) with the [Backlog.md](https://github.com/MrLesk/Backlog.md) CLI.
Use `backlog board`, `backlog task list --plain` and `backlog search <query>`; never edit files in `.backlog/` by hand.
See the Backlog.md workflow in [`AGENTS.md`](../AGENTS.md).

The previous running plan (tasks T-000 to T-706, 73 of them done before the migration) is preserved in git history:
`git show 7f50809da11e186902222b5c2bae8e65ea57bf2b:tasks/PLAN.md`.

## Legacy ID map

Docs and commit messages still refer to legacy `T-xxx` IDs. Open items were migrated as follows; each task also carries a `legacy:T-xxx` label.

| Legacy ID | Backlog task |
|---|---|
| T-007 | task-1.1 Record ISED permission |
| T-603 | task-1.2 App Store privacy label evidence |
| T-604, T-313 (remaining part) | task-1.3 Static web deploy, CSP/host docs, post-deploy smoke test |
| T-606 | task-1.4 Release About pages |
| T-006 | task-1.5 Consolidated release checklist |
| T-607 | task-1.6 Release candidate pass |
| T-009 | task-1.7 Make the repository public |
| T-003 | task-2 JSON Schemas |
| T-004 | task-3 Schema validation tests in CI |
| T-011b | task-4 Final app icon artwork approval |
| T-407 | task-5 Reference-sheet teaching links decision |
| Open planning questions | task-6 Resolve open planning questions |
| T-701 | task-11 Advanced qualification course |
| T-702 | task-12 Morse code 5 wpm trainer |
| T-705 | task-13 Optional iCloud sync |
| T-703 | task-14 watchOS companion |
| T-706 | task-15 iPhone Duo readiness |

All other legacy IDs were done, merged into another task, or dropped (T-507) before the migration.
