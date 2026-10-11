---
id: TASK-40
title: Web test 'automatically includes M4 and M6 lessons' times out under load
status: To Do
assignee: []
created_date: '2026-10-10 23:50'
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
