---
id: TASK-48.2
title: Dark app icon matches the owner's app family
status: Done
assignee: []
created_date: '2026-10-17 23:54'
updated_date: '2026-10-17 23:54'
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
- [x] #1 Dark appiconset export uses the flat #453316 field with a white mark, matching FluxHaus by pixel sampling
- [x] #2 AppIcon.icon has light/dark fill specializations so the iOS 27 system dark render shows the family brown and a white mark
- [x] #3 Light, tinted and clear renders are unchanged; exports regenerated and icon asset checks pass
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
FluxHaus AppIcon-1024-dark.png samples flat (69,51,22) = #453316 with a white mark. FluxTerm's icon_1024_dark.png is the same, from fluxterm #66. render_icon.py now uses DARK_FIELD #453316 (flat) and DARK_INK #FFFFFF. A separate ICON_COMPOSER_UNDERLAY keeps the cream halo in brushstroke.png, so the light, clear and tinted renders are unchanged. icon.json now uses fill-specializations (light #E8D5B7, dark #453316) and a layer fill specialization (dark = solid white). Results:
- ictool iOS dark render: about (69,54,30) with a white mark; light unchanged at about (232,217,191).
- Exports: dark (69,51,22)/(255,255,255), light (232,213,183).
- check_icon_assets passed; xbuild generic iOS Simulator build succeeded (actool accepts the .icon).
- build:web, audit:urls and web tests passed.
- The dark web favicon also uses the family brown.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
The dark app icon now matches FluxHaus and FluxTerm: a flat #453316 field with a white mark, in both the dark appiconset fallback and the Icon Composer dark specialization that iOS 27 renders.
<!-- SECTION:FINAL_SUMMARY:END -->
