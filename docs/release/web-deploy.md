# Static web deployment runbook

This runbook prepares `apps/web` for a future static deployment. It does not approve a deployment.

## Host choice and release gate

- Host for v1 preparation: GitHub Pages for the private repository project site. The owner may redirect or change the public hostname later.
- Deployment is blocked until task-1.1 records written ISED permission in [`docs/content-licensing.md`](../content-licensing.md) with granted status, an ISED reference number, and a permission date.
- The workflow is manual only: `.github/workflows/deploy-web.yml` uses `workflow_dispatch` and intentionally has no `push`, `pull_request`, or scheduled trigger.
- The first job runs `node scripts/check-release-permission.mjs`. In the current repository state this gate fails because the permission record is still pending.

Do not run the workflow to deploy until the permission record is complete and the release review confirms that public exposure is allowed.

## Running the workflow after permission is recorded

After task-1.1 is complete and the release owner approves a web release:

1. Keep the repository private until the public-release gate permits a change; do not make the repo public from this workflow.
2. In GitHub Actions, open **Deploy web to GitHub Pages**.
3. Choose **Run workflow** for the release branch or tag selected by the owner.
4. Confirm the `ISED permission gate` job passes before the `deploy` job starts.
5. Confirm the deploy job runs:
   - `pnpm install --frozen-lockfile`
   - `pnpm build:web`
   - `pnpm --filter @canadian-ham/web audit:urls`
   - GitHub Pages artifact upload from `apps/web/dist`
   - GitHub Pages deployment

The workflow uses only official setup/pages actions and pins them to full commit SHAs. Its deploy job grants only the permissions needed for Pages (`contents: read`, `pages: write`, `id-token: write`).

## GitHub Pages base path

GitHub Pages project sites are served below a repository-name path such as `/canadian-ham/`. The deploy workflow sets:

```text
CANADIAN_HAM_WEB_BASE_PATH=/${{ github.event.repository.name }}/
```

`apps/web/vite.config.ts` uses that environment variable as Vite's `base` value for the deployment build. Local development, tests, and local preview builds default to `./`, so local `vite dev`, `pnpm build:web`, and `vite preview` do not need a repository-name path.

PWA paths stay relative:

- `manifest.webmanifest` uses `start_url: "./"` and `scope: "./"`, so the installed PWA is scoped to the directory where the manifest is served.
- The app registers `./sw.js`, so on GitHub Pages the service worker scope is the project-site path.
- The service worker precaches relative `./...` entries and rejects cross-origin fetches.

If the owner later moves the site to an apex/custom domain where the app is served at `/`, update the workflow base path to `/` and repeat the build, URL/CSP audit, link check, and offline smoke test.

## Content Security Policy

`apps/web/index.html` currently contains a static CSP meta tag with no third-party origins:

```text
default-src 'self'; base-uri 'self'; object-src 'none'; form-action 'none'; connect-src 'self'; img-src 'self' data:; font-src 'self'; script-src 'self' 'sha256-E77amc0CnFRHG8inr16ONddkqQaLnAfKqxm96My0KQs='; style-src 'self'
```

The built-dist audit (`pnpm --filter @canadian-ham/web audit:urls`) also checks `dist/index.html` and fails if the CSP meta tag contains a source expression other than `'self'`, `'none'`, `data:`, or an inline-script hash.

Limits of a meta CSP on GitHub Pages:

- GitHub Pages does not let this project set custom HTTP response headers for the static site, so the CSP is delivered as a `<meta http-equiv="Content-Security-Policy">` fallback.
- Some CSP directives cannot be enforced from a meta tag. In particular, `frame-ancestors` and `report-uri`/reporting endpoints require HTTP headers and are not available here.
- Because response headers are unavailable, there is no CSP report-only mode or server-side CSP report collection for this host.

## Host logging and retention

The app itself has no accounts, analytics, ads, third-party tracking, or server-side progress storage; see [`docs/privacy.md`](../privacy.md). Static hosting can still expose ordinary HTTP request data to the host. The current privacy documentation says a static host may see client IP addresses and user-agent data in ordinary request logs for app assets.

For GitHub Pages release review, confirm GitHub's then-current privacy statement before deployment for visitor IP/security logging and the exact retention period. Retention is **to confirm against GitHub's current privacy statement before release**. No project-managed access logs or analytics are enabled by this repository.

## Required release checks

Before any public deployment:

1. `node scripts/check-release-permission.mjs` must pass.
2. `pnpm typecheck` must pass.
3. `pnpm test` must pass.
4. `pnpm build:web` must pass with the deployment base path.
5. `pnpm --filter @canadian-ham/web audit:urls` must pass.
6. `pnpm check:links` must pass.
7. `go run github.com/rhysd/actionlint/cmd/actionlint@latest` must pass.
8. The [post-deploy offline smoke-test checklist](web-offline-smoke-test.md) must pass against the deployed URL before task-1.3 AC #3 is checked.
