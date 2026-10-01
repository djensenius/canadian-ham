## Backlog.md task files

Files under `backlog/**` and `.backlog/**` are Backlog.md task-tracking records written and maintained by the `backlog` CLI, not source code. Copilot code review must not review or comment on them, and must not suggest changes to their formatting or content.

## Review context

- Preserve official ISED EN/FR question text verbatim; do not "fix" it.
- The Apple app is offline-only and collects no data: no networking, third-party SDKs, analytics, or iCloud sync for v1.
- For Apple builds/tests, use `xbuild`; never call `xcodebuild` directly.
