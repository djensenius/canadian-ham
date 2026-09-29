# packages/engine-swift

Purpose: SwiftPM quiz, practice, mock-exam, scoring, readiness, and spaced-repetition engine.

Belongs here:

- Swift engine source and tests.
- Fixture readers that validate behaviour against [`../../fixtures/engine/`](../../fixtures/engine/).

Must not go here:

- SwiftUI app code; use [`../../apps/apple/`](../../apps/apple/).
- Networking, analytics, iCloud sync, or third-party SDK code.
- Verbatim ISED source artifacts.

Relevant docs: [`../../docs/architecture.md`](../../docs/architecture.md), [`../../docs/requirements.md`](../../docs/requirements.md), [`../../fixtures/engine/`](../../fixtures/engine/). Use `xbuild`, never `xcodebuild`, for Apple-related builds and tests.
