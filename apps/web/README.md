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
pnpm --filter @canadian-ham/web audit:urls
```

The Vite build uses a relative base (`./`) so the static output can be hosted from any path. Runtime assets must remain self-hosted; do not add analytics, telemetry, remote fonts, CDNs, third-party API calls, or other network-dependent app features.

## Content Security Policy

`index.html` is the production CSP source. Production keeps a strict `style-src 'self'` directive and does not allow `'unsafe-inline'`; the pre-paint theme script is allowed only by its `sha256-...` hash. Tests verify that the hash matches the inline script.

Vite's development server injects imported CSS with inline `<style>` elements. `vite.config.ts` uses a `transformIndexHtml` hook with `apply: "serve"` to add `'unsafe-inline'` to `style-src` only while running `pnpm --filter @canadian-ham/web dev`. This dev-only CSP is not written to production builds.

For web build checks, run `pnpm build:web` and then `pnpm --filter @canadian-ham/web audit:urls`. The URL audit scans `apps/web/dist` and allows only XML namespace URLs, React production error-message strings under `https://react.dev/errors/`, and exact official-source citation URLs listed in `apps/web/scripts/audit-dist-urls.ts`. The current citation allowlist covers the ISED RBR-4 source page used by B-001 explanations. Citation URLs are allowed only because the `@canadian-ham/web` app renders them as user-activated external links; the app must not fetch, preload, or cache them automatically. Any other `http://` or `https://` URL in `dist` fails the audit.
