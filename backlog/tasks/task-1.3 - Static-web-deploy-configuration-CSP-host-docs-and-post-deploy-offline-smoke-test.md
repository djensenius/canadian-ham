---
id: TASK-1.3
title: >-
  Static web deploy configuration, CSP/host docs and post-deploy offline smoke
  test
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
labels:
  - release
  - web
  - 'legacy:T-604'
  - 'legacy:T-313'
milestone: m-0
dependencies:
  - TASK-1.1
parent_task_id: TASK-1
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add the static hosting configuration for apps/web, document host logging and the Content-Security-Policy (allowing no third-party origins), and write a post-deploy offline smoke-test checklist (load, install PWA, go offline, practise, mock exam, export/import). Includes the remaining part of the web privacy audit (legacy T-313: the dist URL audit is already done). Legacy: T-604, T-313.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The deployment configuration is committed and documented
- [ ] #2 The CSP blocks all third-party origins and the host log retention is documented
- [ ] #3 The post-deploy offline smoke test checklist exists and has been run once against a deployment
- [ ] #4 No deployment happens before the ISED permission is recorded
<!-- AC:END -->
