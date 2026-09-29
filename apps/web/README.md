# apps/web

Static Vite + React + TypeScript app for the Canadian Amateur Radio Basic study flow.

The app imports generated question-bank JSON from `../../content/generated/basic-2025-07-15/` at build time. Do not copy generated or source ISED files into this app directory.

## Commands

From the repository root:

```sh
pnpm --filter @canadian-ham/web dev
pnpm --filter @canadian-ham/web test
pnpm --filter @canadian-ham/web typecheck
pnpm build:web
```

The Vite build uses a relative base (`./`) so the static output can be hosted from any path. Runtime assets must remain self-hosted; do not add analytics, telemetry, remote fonts, CDNs, third-party API calls, or other network-dependent app features.
