# packages/content-tools

Purpose: TypeScript importer, validation, lint, and coverage tooling.

Belongs here:

- TypeScript scripts run directly by Node's type stripping support.
- `node:test` suites for importer and content validation.
- Tooling that emits reviewed output under [`../../content/generated/`](../../content/generated/).

Must not go here:

- Runtime app code or app-specific UI.
- Runtime dependencies for the importer; the importer has zero runtime dependencies.
- Hand-edited generated JSON.

## Commands

Run commands from the repository root with Node 26 or newer:

```sh
node packages/content-tools/src/import-basic.ts
node packages/content-tools/src/import-basic.ts --check
node --test packages/content-tools/test/
```

The import command verifies the committed source TXT SHA-256 against both
`content/sources/ised/basic-2025-07-15/manifest.json` and `SHA256SUMS`, parses
strict UTF-8/CRLF semicolon-delimited rows, validates bank counts and category
metadata, runs answer-position lint, and writes deterministic JSON to
`content/generated/basic-2025-07-15/`.

The `--check` mode regenerates the output in memory and fails if the committed
JSON differs. It is intended for CI and reproducibility checks.

Note on quote characters: the current official TXT contains literal quote
characters at the start or end of some answer fields (for example quoted labels
such as `"A"`). The importer preserves those characters as data and rejects
wrapper-shaped CSV fields and doubled-quote CSV escapes; it does not unescape or
trim field values.

Relevant docs: [`../../docs/architecture.md`](../../docs/architecture.md), [`../../docs/exam-facts.md`](../../docs/exam-facts.md), [`../../docs/requirements.md`](../../docs/requirements.md).
