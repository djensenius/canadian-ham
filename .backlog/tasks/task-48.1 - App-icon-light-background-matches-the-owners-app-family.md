---
id: TASK-48.1
title: App icon light background matches the owner's app family
status: In Progress
assignee:
  - '@coordinator'
created_date: '2026-10-17 22:49'
updated_date: '2026-10-17 22:50'
labels: []
dependencies: []
parent_task_id: TASK-48
ordinal: 131000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The light-mode app icon used a pale cream gradient (#FFF7E8 to #F6EEDC) that looks lighter and yellower than the owner's other ink-brush apps on the Home Screen (owner screenshot 2026-10-17). FluxHaus and FluxKlang both use a flat #E8D5B7 field.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The icon renderer uses the family cream #E8D5B7 for the light icon field, the Icon Composer fill, and the other exports that share it
- [ ] #2 All exports are regenerated with design/app-icon/render_icon.py and the icon asset checks pass
- [ ] #3 The rendered light icon matches the other family icons when compared side by side
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Set CREAM_INNER/CREAM_OUTER to the family #E8D5B7 in render_icon.py. 2. Re-render all exports. 3. Run check_icon_assets.py and compare against the family icons. 4. Open a PR.
<!-- SECTION:PLAN:END -->
