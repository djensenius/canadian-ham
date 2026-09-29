# packages/engine-ts

Purpose: TypeScript quiz, practice, mock-exam, scoring, readiness, and spaced-repetition engine.

Belongs here:

- Shared TypeScript engine source and tests.
- Fixture readers that validate behaviour against [`../../fixtures/engine/`](../../fixtures/engine/).

Must not go here:

- React components or web UI state.
- Verbatim ISED source artifacts or hand-edited generated data.
- Swift engine code.

Relevant docs: [`../../docs/architecture.md`](../../docs/architecture.md), [`../../docs/requirements.md`](../../docs/requirements.md), [`../../fixtures/engine/`](../../fixtures/engine/).

## Package shape

- Package name: `@canadian-ham/engine-ts`.
- Runtime dependencies: none.
- Module format: ESM (`"type": "module"`).
- Export: `./src/index.ts` so Vite can consume the TypeScript source directly.
- Node execution: source uses erasable TypeScript syntax and `.ts` import extensions, so Node 26 can run it through built-in type stripping.

## Deterministic RNG implementation

The engine uses UTF-8 seed bytes, FNV-1a 64-bit hashing, and PCG32 XSH RR as specified in `docs/architecture.md`. TypeScript implements the 64-bit arithmetic with `BigInt` and masks intermediate state with `0xffffffffffffffffn` after every wrapping operation. PCG output is converted to a JavaScript `number` only after the 32-bit value has been masked, so every emitted value is an unsigned uint32.

The bounded draw uses the architecture threshold rejection rule, and shuffles use Fisher-Yates with `i = n - 1` down to `1`.

## Local checks

```sh
node --test packages/engine-ts/test/
node packages/engine-ts/src/generate-fixtures.ts --check
```

The fixture generator rewrites only files under `fixtures/engine/`. Use `--check` to fail when committed fixture outputs drift from the implementation.
