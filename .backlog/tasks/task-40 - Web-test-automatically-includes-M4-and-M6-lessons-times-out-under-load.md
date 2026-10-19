---
id: TASK-40
title: Web test 'automatically includes M4 and M6 lessons' times out under load
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 23:50'
updated_date: '2026-10-19 13:05'
labels:
  - web
dependencies: []
priority: low
ordinal: 90000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
apps/web/src/App.test.tsx > 'automatically includes M4 and M6 lessons from content and renders them' intermittently exceeds the default timeout (seen at 2 038 ms) when the build host is heavily loaded; reruns pass. Seen 2026-10-10 in task-39.x lanes. Make it deterministic (for example, scope the render, await the specific element with findBy*, or set an explicit per-test timeout justified by measurement) without weakening its assertions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The test passes reliably under load (for example, 10 consecutive runs while the build host is busy) with unchanged assertion strength
- [ ] #2 Any timeout change is justified by a measured duration in the task notes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect App.test.tsx helpers and the lesson/Morse quiz rendering path to identify slow or nondeterministic waits, timers, axe usage, or isolation gaps.
2. Apply the smallest deterministic fix without weakening assertions; prefer scoped queries, targeted rendering, and timer/test isolation fixes over timeout increases.
3. Run focused web tests repeatedly, including under CPU load, then run required project checks.
4. Record measured evidence in task notes, check acceptance criteria, finalize the task, commit, push, and open the requested PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Root cause: App.test.tsx mixed large route renders, axe passes, and async IndexedDB/question-bank startup with Testing Library's 1s default async query timeout and Vitest's 5s per-test timeout. Under repeated runs/load, some App flows legitimately took about 5-6s and findByRole could time out while the app still showed the loading screen. The M4/M6 test also changed hash routes outside act and did not wait for the lesson quiz choices, leaving route updates/question-bank rendering less deterministic. MarkdownContent also reparsed lesson/reference Markdown on every rerender, increasing the cost of those large pages.

Fix: memoized MarkdownContent parsing/heading anchors; added act-wrapped setAppHash for in-test route changes; scoped the M4/M6 assertions to main, removed the unnecessary Learn rerender between M4 and M6, and now waits for the M4/M6 quiz answer-choice groups without dropping existing heading/module assertions; reset fake timers in afterEach. Added measured guards for App flows only: Testing Library async queries now wait up to 5s and the App flow suite has a 10s per-test timeout because a pre-guard repeated web run failed with App tests at 5.03-5.98s despite passing when isolated.

Validation: focused M4/M6 test passed at 330ms after the deterministic route/query changes. After final changes, pnpm --filter @canadian-ham/web test passed 5 explicit runs: run 1 84.88s, runs 2 and 3 under concurrent pnpm test load 81.37s and 73.51s, run 4 30.99s, run 5 21.42s. The concurrent heavy pnpm test exited 0 and its included web run passed in 87.39s. Required checks also passed: pnpm typecheck; pnpm test; pnpm build:web; pnpm --filter @canadian-ham/web audit:urls. Known jsdom/axe noise remained unchanged: repeated "Not implemented: HTMLCanvasElement's getContext()" messages.
<!-- SECTION:NOTES:END -->
