---
id: TASK-38.2
title: Core memory-aid figures
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 20:55'
updated_date: '2026-10-12 14:30'
labels:
  - content
  - apple
  - web
dependencies:
  - TASK-38.1
parent_task_id: TASK-38
priority: medium
ordinal: 80000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Using the task-38.1 pipeline, draw: metric prefix ladder (giga to pico, x/÷ 1 000), resistor colour code (band names labelled, not colour-only), series vs parallel circuits with current paths, dB ratio table (3/6/10/20 dB), and wavelength = 300 / f(MHz) with a half-wave dipole example. Replace the matching lesson briefs (l-005-01, l-004-03, l-005-03, l-005-04, l-006-03) where they fit.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Each listed figure exists, is referenced from its lesson, and has alt text plus a text equivalent where dense
- [ ] #2 Same accessibility and originality bar as task-38.1; audits pass in light and dark; numbers use space grouping (owner decision A)
- [ ] #3 The L-005-01 metric-prefix ladder figure shows the micro-to-pico step as x/÷ 1 000 000 (the lesson table skips nano) or adds a nano rung; the brief's 'x 1 000 at every step' arrows are corrected when the figure is drawn
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add five original currentColor SVG sources for metric prefixes, resistor colour-code bands, series/parallel paths, dB ratio shortcuts, and wavelength/dipole estimate.\n2. Reference each SVG from its matching lesson with alt text and text equivalents for dense ladder/table/colour-code content while leaving illustration briefs as authoring notes.\n3. Regenerate figure assets/metadata, render and inspect qlmanage previews, run figure, content, web, and content-swift checks, then record per-figure evidence without running Apple xbuild.
<!-- SECTION:PLAN:END -->
