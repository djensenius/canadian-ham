# fixtures

Purpose: shared JSON fixtures that define cross-platform behaviour.

Belongs here:

- Engine fixtures under [`engine/`](engine/) that both TypeScript and Swift implementations must pass.
- Importer fixtures under [`importer/`](importer/) for source parsing and validation edge cases.

Must not go here:

- Runtime app code.
- Verbatim ISED source artifacts.
- Fixtures that depend on localized UI strings instead of stable IDs and invariants.

Relevant docs: [`../docs/architecture.md`](../docs/architecture.md), [`../docs/requirements.md`](../docs/requirements.md).
