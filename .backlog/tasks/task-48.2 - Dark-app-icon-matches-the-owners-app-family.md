---
id: TASK-48.2
title: Dark app icon matches the owner's app family
status: To Do
assignee: []
created_date: '2026-10-17 23:54'
labels: []
dependencies: []
parent_task_id: TASK-48
ordinal: 132000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner 2026-10-17: the dark-mode app icon should match ../FluxHaus (AppIcon-1024-dark.png: flat #453316 field, white mark). FluxTerm already matches (fluxterm PR #66). Canadian Ham used a near-black #201B16 field with a cream mark, and the Icon Composer .icon had no dark specialization.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Dark appiconset export uses the flat #453316 field with a white mark, matching FluxHaus by pixel sampling
- [ ] #2 AppIcon.icon has light/dark fill specializations so the iOS 27 system dark render shows the family brown and a white mark
- [ ] #3 Light, tinted and clear renders are unchanged; exports regenerated and icon asset checks pass
<!-- AC:END -->
