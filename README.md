# canadian-ham

`canadian-ham` is a Canadian Amateur Radio Operator Certificate, Basic Qualification learning system. The planned product is a static web app plus an offline Apple app for iPhone, iPad, and Mac. Both apps use the same platform-neutral lessons, question data, explanations, schemas, and fixtures.

## Private repository notice

This repository is private because it will contain ISED question-bank and reference material for private development. Do not redistribute the repository, publish the web app, or distribute app builds until the public-release gate is satisfied and permission is recorded in [docs/content-licensing.md](docs/content-licensing.md).

## Layout

```text
canadian-ham/
  apps/
    web/                  Static Vite + React + TypeScript web app (future)
    apple/                SwiftUI multiplatform Apple app (future)
  content/
    sources/ised/         Verbatim ISED source artifacts only
    generated/            Importer-generated normalized JSON only
    lessons/              Original platform-neutral lessons
    explanations/         Original explanations by question ID
    reference/            Reference metadata and permitted bundled assets
  fixtures/
    engine/               Language-neutral engine fixtures
    importer/             Importer validation fixtures
  packages/
    content-tools/        TypeScript importer and validation tooling
    engine-ts/            TypeScript quiz/exam engine package
    engine-swift/         SwiftPM quiz/exam engine package
    schemas/              Schema definitions
  docs/                   Requirements, architecture, privacy, and licensing docs
  tasks/                  Running implementation plan
```

## Key docs

- [Product requirements](docs/requirements.md)
- [Architecture plan](docs/architecture.md)
- [Exam facts](docs/exam-facts.md)
- [Privacy plan](docs/privacy.md)
- [Content licensing and attribution plan](docs/content-licensing.md)
- [Running plan](tasks/PLAN.md)

## Build rule

Use `xbuild` for all Apple builds and tests. Never call `xcodebuild` directly.

## Continuous integration

GitHub Actions CI for the private `djensenius/canadian-ham` repository runs on Ubuntu for pushes to `main` and pull requests. It installs the pinned pnpm workspace on Node 26, then runs TypeScript, Node/content, web build, URL-audit, and Apple no-network grep checks. Apple platform build and test suites stay local via `xbuild` and are not run on GitHub-hosted macOS runners.

## Commands

Install the workspace dependencies with the pinned pnpm version from `package.json`:

```sh
pnpm install
```

Common checks:

```sh
pnpm test
pnpm import:check
pnpm check:links
pnpm -r typecheck
pnpm build:web
```

Web app during development:

```sh
pnpm --filter @canadian-ham/web dev
```
