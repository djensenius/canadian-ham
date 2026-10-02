# Static web deployment runbook

This runbook prepares `apps/web` for a future static deployment. It does not approve a deployment.

## Host choice and release gate

- Host for v1 preparation: GitHub Pages. A Pages site built from a private repository is still publicly reachable on standard GitHub plans; repository privacy does not make the Pages site private. The owner may redirect or change the public hostname later.
- The repository-level rule in [`AGENTS.md`](../../AGENTS.md) still applies: nothing is deployed, distributed, or made public until the T-009/T-607 release gates and the ISED permission record allow it.
- Deployment is blocked until task-1.1 records written ISED permission in [`docs/content-licensing.md`](../content-licensing.md) with exactly one `granted: yes` or `granted: YYYY-MM-DD` status part (an optional bracketed note may not contain denial, pending or revocation words), an ISED reference number, a valid permission date, a permission scope that covers the question-bank text, the covered source artifacts, the evidence storage location, and a release review status that is no longer blocked. Each field must appear exactly once.
- The workflow is manual only: `.github/workflows/deploy-web.yml` uses `workflow_dispatch` and intentionally has no `push`, `pull_request`, or scheduled trigger.
- The first job runs `node scripts/check-release-permission.mjs`. In the current repository state this gate fails because the permission record is still pending.

Do not run the workflow to deploy until the permission record is complete and the release review confirms that public exposure is allowed.

## Running the workflow after permission is recorded

After task-1.1 is complete and the release owner approves a web release:

1. Keep the repository private until the public-release gate permits a change; do not make the repo public from this workflow.
2. In repository **Settings → Pages**, set **Build and deployment → Source** to **GitHub Actions**. Do not use **Deploy from a branch**, because that bypasses this workflow and its permission gate.
3. In repository **Settings → Environments → github-pages**, restrict deployments to `main` and/or owner-approved release tags and require a reviewer. Do not allow arbitrary branch deployments, because a branch could edit the permission record before running the workflow.
4. In GitHub Actions, open **Deploy web to GitHub Pages**.
5. Choose **Run workflow** for `main` or the release tag selected by the owner.
6. Confirm the `ISED permission gate` job passes before the `deploy` job starts.
7. Confirm the deploy job runs:
   - `pnpm install --frozen-lockfile`
   - `pnpm build:web`
   - `pnpm --filter @canadian-ham/web audit:urls`
   - GitHub Pages artifact upload from `apps/web/dist`
   - GitHub Pages deployment

The workflow uses only official setup/pages actions and pins them to full commit SHAs. Its deploy job grants only the permissions needed for Pages (`contents: read`, `pages: write`, `id-token: write`).

## GitHub Pages base path

GitHub Pages project sites are usually served below a repository-name path such as `/canadian-ham/`, while custom domains can be served from `/`. The deploy workflow gives `actions/configure-pages` the `pages` id, normalizes `steps.pages.outputs.base_path` to include a trailing slash, and sets:

```text
CANADIAN_HAM_WEB_BASE_PATH=${{ steps.pages-base.outputs.base_path }}
```

`apps/web/vite.config.ts` uses that environment variable as Vite's `base` value for the deployment build. Local development, tests, and local preview builds default to `./`, so local `vite dev`, `pnpm build:web`, and `vite preview` do not need a repository-name path.

PWA paths stay relative:

- `manifest.webmanifest` uses `start_url: "./"` and `scope: "./"`, so the installed PWA is scoped to the directory where the manifest is served.
- The app registers `./sw.js`, so on GitHub Pages the service worker scope is the project-site path.
- The service worker precaches relative `./...` entries and rejects cross-origin fetches.

If the owner later moves the site to an apex/custom domain where the app is served at `/`, confirm `actions/configure-pages` reports `/` for the base path and repeat the build, URL/CSP audit, link check, and offline smoke test.

## Content Security Policy

`apps/web/index.html` currently contains a static CSP meta tag with no third-party origins:

```text
default-src 'self'; base-uri 'self'; object-src 'none'; form-action 'none'; connect-src 'self'; img-src 'self' data:; font-src 'self'; script-src 'self' 'sha256-E77amc0CnFRHG8inr16ONddkqQaLnAfKqxm96My0KQs='; style-src 'self'
```

The built-dist audit (`pnpm --filter @canadian-ham/web audit:urls`) also checks `dist/index.html` and fails if the CSP meta tag omits `default-src 'self'` or `default-src 'none'`, or contains a source expression other than `'self'`, `'none'`, `data:`, or an inline-script hash.

Limits of a meta CSP on GitHub Pages:

- GitHub Pages does not let this project set custom HTTP response headers for the static site, so the CSP is delivered as a `<meta http-equiv="Content-Security-Policy">` fallback.
- Some CSP directives cannot be enforced from a meta tag. In particular, `frame-ancestors` and `report-uri`/reporting endpoints require HTTP headers and are not available here.
- Because response headers are unavailable, there is no CSP report-only mode or server-side CSP report collection for this host.

## Host logging and retention

The app itself has no accounts, analytics, ads, third-party tracking, or server-side progress storage; see [`docs/privacy.md`](../privacy.md). Static hosting can still expose ordinary HTTP request data to the host. The current privacy documentation says a static host may see client IP addresses and user-agent data in ordinary request logs for app assets.

For GitHub Pages release review, confirm GitHub's then-current privacy statement before deployment for visitor IP/security logging and the exact retention period. Retention is **to confirm against GitHub's current privacy statement before release**. GitHub Pages does not provide this repository with a project-level setting to disable or shorten Pages access logs; no project-managed access logs or analytics are enabled by this repository.

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
