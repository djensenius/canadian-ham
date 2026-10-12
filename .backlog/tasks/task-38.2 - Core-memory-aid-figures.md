---
id: TASK-38.2
title: Core memory-aid figures
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 20:55'
updated_date: '2026-10-12 14:39'
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
- [x] #1 Each listed figure exists, is referenced from its lesson, and has alt text plus a text equivalent where dense
- [ ] #2 Same accessibility and originality bar as task-38.1; audits pass in light and dark; numbers use space grouping (owner decision A)
- [x] #3 The L-005-01 metric-prefix ladder figure shows the micro-to-pico step as x/÷ 1 000 000 (the lesson table skips nano) or adds a nano rung; the brief's 'x 1 000 at every step' arrows are corrected when the figure is drawn
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add five original currentColor SVG sources for metric prefixes, resistor colour-code bands, series/parallel paths, dB ratio shortcuts, and wavelength/dipole estimate.\n2. Reference each SVG from its matching lesson with alt text and text equivalents for dense ladder/table/colour-code content while leaving illustration briefs as authoring notes.\n3. Regenerate figure assets/metadata, render and inspect qlmanage previews, run figure, content, web, and content-swift checks, then record per-figure evidence without running Apple xbuild.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Per-figure notes: metric-prefix-ladder for L-005-01 shows G/M/k/base/m/µ/p, x or ÷ 1 000 for adjacent steps through micro, the skipped-nano µ↔p jump as x or ÷ 1 000 000, and 14.230 MHz = 14 230 kHz; verified against the lesson table/worked examples and Basic B-005-001-001 through B-005-001-011. resistor-colour-code for L-004-03 labels every band by position and colour name (yellow=4, violet=7, red=x 100, gold=±5%) and shows 4 700 Ω with a ±5% range of 4 465 Ω to 4 935 Ω; verified against the lesson examples/table and Basic B-004-006-001 through B-004-006-011. series-parallel-current-paths for L-005-03 shows a single series current path and separate parallel branch currents rejoining as I total = I1 + I2; verified against Basic B-005-005-001, B-005-005-003, B-005-005-005, and B-005-005-011. db-power-ratio-table for L-005-04 shows 3/6/10/20 dB power shortcuts (x or ÷ 2, 4, 10, 100); verified against Basic B-005-008-001, -002, -003, -007, -008, -010, -011 and the lesson dB shortcuts. wavelength-dipole-example for L-006-03 shows λ(m)=300/f(MHz), 14.2 MHz → λ≈21.1 m, half-wave≈10.6 m total and ≈5.3 m each side with practical wire shorter; verified against the lesson wavelength/dipole text and Basic B-006-008-003, -004, -007, and -011. No figure restates an official question or answer.

Validation notes: ran pnpm check:figures:fix, pnpm check:figures, node scripts/check-figures.mjs --self-test, node packages/content-tools/src/check-lesson-coverage.ts, pnpm --dir packages/content-tools check:quizzes, pnpm --dir packages/content-tools check:lesson-originality:all, pnpm --dir packages/content-tools check:explanations, pnpm check:links, pnpm --filter @canadian-ham/web test, and DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift. Rendered each new SVG with qlmanage -t -s 800 and visually inspected the PNGs; saved evidence under docs/evidence/task-38.2/. Apple xbuild app audits were intentionally not run in this lane, so the light/dark Apple validation portion remains unchecked/pending.
<!-- SECTION:NOTES:END -->
