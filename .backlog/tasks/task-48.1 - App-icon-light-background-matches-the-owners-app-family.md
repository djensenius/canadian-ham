---
id: TASK-48.1
title: App icon light background matches the owner's app family
status: Done
assignee:
  - '@coordinator'
created_date: '2026-10-17 22:49'
updated_date: '2026-10-17 22:57'
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
- [x] #1 The icon renderer uses the family cream #E8D5B7 for the light icon field, the Icon Composer fill, and the other exports that share it
- [x] #2 All exports are regenerated with design/app-icon/render_icon.py and the icon asset checks pass
- [x] #3 The rendered light icon matches the other family icons when compared side by side
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Set CREAM_INNER/CREAM_OUTER to the family #E8D5B7 in render_icon.py. 2. Re-render all exports. 3. Run check_icon_assets.py and compare against the family icons. 4. Open a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner screenshot 2026-10-17 showed the icon lighter and yellower than the family. FluxHaus AppIcon-1024 and the FluxKlang AppIcon.icon fill are both flat #E8D5B7 (232,213,183). Set CREAM_INNER/OUTER to that value, re-rendered with render_icon.py (ImageMagick + ictool), and check_icon_assets.py passed. The flat exports are exactly (232,213,183), matching FluxHaus. The ictool iOS light render shows about (230-244, 215-229, 188-202), matching the family icons on the Home Screen screenshot (about 228-235, 212-220, 185-193). The web favicon and PWA icons share the same field. pnpm test passed on rerun (App.test.tsx timing flake, task-40), build:web and audit:urls passed. Dark and tinted variants are unchanged.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
The light app icon field now uses the family cream #E8D5B7 (flat), matching FluxHaus and FluxKlang. All Apple, web, tvOS and visionOS icon exports were regenerated from render_icon.py.
<!-- SECTION:FINAL_SUMMARY:END -->
