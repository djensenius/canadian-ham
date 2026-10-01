---
id: TASK-1.6
title: Release candidate pass
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
labels:
  - release
  - 'legacy:T-607'
milestone: m-0
dependencies:
  - TASK-1.2
  - TASK-1.3
  - TASK-1.4
  - TASK-1.5
parent_task_id: TASK-1
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Run the full release candidate pass on a single commit: all web and content checks (CI), all four Apple suites via xbuild, link checks, privacy checks, accessibility checks (automated and manual), the offline smoke tests and the licensing checklist. Legacy: T-607.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 CI passes on the release candidate commit
- [ ] #2 The iOS, macOS, tvOS and visionOS suites pass via xbuild on that commit
- [ ] #3 The consolidated release checklist is completed and its results recorded
- [ ] #4 Any failures are fixed or explicitly accepted by the owner
<!-- AC:END -->
