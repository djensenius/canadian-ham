# apps/apple

Purpose: future SwiftUI multiplatform Apple app for iPhone, iPad, and Mac.

Belongs here:

- Apple app project files, SwiftUI views, app resources, entitlements, and app tests once scaffolded.
- Local-only progress storage integration and offline reference viewer app code.

Must not go here:

- Networking code, third-party SDKs, analytics, iCloud sync, or push notification support in v1.
- Verbatim ISED source artifacts; source files belong under [`../../content/sources/ised/`](../../content/sources/ised/).
- Shared Swift engine package code; use [`../../packages/engine-swift/`](../../packages/engine-swift/).

Relevant docs: [`../../docs/architecture.md`](../../docs/architecture.md), [`../../docs/privacy.md`](../../docs/privacy.md), [`../../docs/content-licensing.md`](../../docs/content-licensing.md). Use `xbuild`, never `xcodebuild`, for Apple builds and tests.
