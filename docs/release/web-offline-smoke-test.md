# Web post-deploy offline smoke-test checklist

Use this checklist after a permitted deployment of `apps/web`. It verifies that the static site, PWA cache, offline study flows, local progress controls, bilingual UI, About page, and no-third-party-request policy still match the release privacy design.

This checklist is not complete for task-1.3 until it has been run against the deployed GitHub Pages URL after the ISED permission gate allows deployment.

## Setup

- Deployment URL: _pending permitted deployment_
- Browser and version: _record during release smoke test_
- Platform/device: _record during release smoke test_
- Build or commit SHA: _record during release smoke test_
- Tester: _record during release smoke test_
- Date/time: _record during release smoke test_

Before starting:

1. Open browser DevTools.
2. Open the Network panel and enable request preservation if available.
3. Clear storage for the deployment origin, including service workers, IndexedDB, localStorage, and Cache Storage.
4. Disable browser extensions that could add network noise, or use a clean profile.

## Post-deploy checklist

- [ ] Load the deployed URL over HTTPS and confirm the app shell renders without console errors.
- [ ] Confirm the PWA/offline status reaches ready state after the service worker installs.
- [ ] Install the PWA using the browser install prompt or install menu.
- [ ] Switch the browser/device offline.
- [ ] Reload the installed PWA or browser tab while offline and confirm the app shell still loads.
- [ ] Complete a practise/practice session while offline and confirm question navigation works.
- [ ] Open and read a lesson while offline.
- [ ] Start and finish a mock exam while offline.
- [ ] Export progress JSON while offline or after returning online only if the browser blocks downloads offline; note which behaviour occurred.
- [ ] Import the exported progress JSON and confirm progress is restored.
- [ ] Switch the UI to French and confirm French interface text renders.
- [ ] Open the About page and confirm the privacy/no-analytics/local-progress summary and ISED disclaimer/attribution state match the release documents.
- [ ] In DevTools Network, verify there were no third-party requests during load, install, offline reload, practice, lesson, mock exam, export/import, French UI, or About-page checks. User-clicked external citation links are out of scope for this no-automatic-request check.
- [ ] Return online and confirm no queued telemetry, analytics, crash-reporting, or progress-sync requests are sent.

## Evidence to record

- Deployment URL and commit SHA.
- Screenshot or notes showing PWA ready/installed state.
- Screenshot or notes showing offline reload succeeded.
- Export/import file name used for the round trip.
- DevTools Network summary showing same-origin requests only.
- Any browser limitations or skipped steps.

## Local preview dry run

This section records local, non-deployment rehearsals. These runs do not satisfy the post-deploy requirement above.

- 2026-10-02 local preview dry run from the task-1.3 worktree, not a deployment: ran `pnpm build:web`, then `pnpm --filter @canadian-ham/web preview --host 127.0.0.1 --port 4173 --strictPort`, then fetched `http://127.0.0.1:4173/`, `/manifest.webmanifest`, and `/sw.js`. Confirmed the app shell root, CSP meta tag, relative manifest `start_url`/`scope`, and service worker cross-origin rejection logic were present. Full browser installation, offline UI flows, and DevTools third-party-request review remain pending for the permitted post-deploy run.
