# packages/content-tools

Purpose: TypeScript importer, validation, lint, and coverage tooling.

Belongs here:

- TypeScript scripts run directly by Node's type stripping support.
- `node:test` suites for importer and content validation.
- Tooling that emits reviewed output under [`../../content/generated/`](../../content/generated/).

Must not go here:

- Runtime app code or app-specific UI.
- Runtime dependencies for the importer; the importer is planned with zero runtime dependencies.
- Hand-edited generated JSON.

Relevant docs: [`../../docs/architecture.md`](../../docs/architecture.md), [`../../docs/exam-facts.md`](../../docs/exam-facts.md), [`../../docs/requirements.md`](../../docs/requirements.md).
