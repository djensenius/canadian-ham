---
id: TASK-38.4
title: 'Lesson figures: modules 5-8'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 20:55'
updated_date: '2026-10-12 16:25'
labels:
  - content
  - apple
  - web
dependencies:
  - TASK-38.1
parent_task_id: TASK-38
priority: low
ordinal: 82000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Draw the remaining Illustration brief figures for lessons in m5-basic-electronics, m6-feedlines-antennas, m7-propagation and m8-interference-suppression (except those covered by task-38.1/38.2).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every brief in modules 5-8 not covered by task-38.1/38.2 has a drawn figure referenced from its lesson
- [ ] #2 Same accessibility and originality bar as task-38.1; audits pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add one original SVG and ::figure reference for each in-scope module 5-8 illustration brief, leaving excluded task-38.1/38.2 lessons untouched.
2. Verify figure labels, clearances, and technical values against lesson text and content/generated/basic-2025-07-15/questions.json.
3. Regenerate Apple figure assets/metadata with pnpm check:figures:fix, render every SVG with qlmanage into docs/evidence/task-38.4/, inspect thumbnails, then run figure, content, web, and content-swift checks.
4. Record per-figure notes and leave Apple xbuild validation acceptance unchecked per lane instructions.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Task-38.4 current implementation adds ten original SVG lesson figures for modules 5-8 and references them inline beside the relevant teaching text: transformer-resonance-meters, feedline-types-balun, swr-loss-matching, yagi-vertical-length, loop-antenna-patterns, propagation-paths-skip-zone, daytime-absorption-frequency-window, vhf-unusual-propagation-modes, interference-troubleshooting-map, and filter-response-sketches. Apple vector assets were synced from the SVG sources and qlmanage evidence PNGs are stored under docs/evidence/task-38.4/. AC #2 remains unchecked because Apple xbuild/in-app validation is deferred in this lane.

Final figure notes after review fixes: transformer-resonance-meters uses separate same-side coil humps for P and S windings on a shared two-bar core, a same-side-hump L branch and C branch between LC rails, battery plates with touching leads, an A meter in series, a straight-segment zigzag load, and a V meter across the load. feedline-types-balun shows radio feed to a balun at the centre dipole feed gap plus labelled coax, window-line, and open-wire examples. swr-loss-matching shows rig, SWR meter, station-end ATU, lossy feedline section, antenna, forward/reflected waves, and a separate tuner-at-feed-point sketch. yagi-vertical-length shows longer reflector, driven feed element, shorter director, main lobe toward the director, and 71.3/f beside the vertical. loop-antenna-patterns shows weak labels clear of the dipole ellipse near the wire ends, paired quad loops on a boom with feed point, a delta loop with H/V feed dots, and the 306/f formula. propagation-paths-skip-zone shows VHF direct, ground wave ending on the Earth line, NVIS starting/landing on the ground line, and a lower-angle longer sky-wave path with a skip-zone bracket from beyond ground-wave reach to the far return. daytime-absorption-frequency-window shows a lower HF ray stopped at the D band with an X marker, an F-return ray starting on the ground line, a usable-window bracket, LUF/OWF/MUF ticks, and an axis arrow beyond the MUF tick. vhf-unusual-propagation-modes shows sporadic E, ducting, aurora, and meteor panels with the meteor path touching the trail and station humps. interference-troubleshooting-map separates receiver overload, audio rectification, and wanted/unwanted transmitter outputs with labels next to their paths. filter-response-sketches shows low-pass, high-pass, band-pass, wide band-reject, and narrow notch responses with clear pass/attenuate labels.

Validation for the latest fix: pnpm check:figures:fix; pnpm check:figures; node scripts/check-figures.mjs --self-test. Rendered transformer-resonance-meters, propagation-paths-skip-zone, daytime-absorption-frequency-window, and loop-antenna-patterns with qlmanage -t -s 1200, read each PNG, and refreshed the matching docs/evidence/task-38.4 PNGs.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added ten original SVG lesson figures for the in-scope modules 5-8 briefs, referenced them from lessons with alt text and text equivalents, regenerated Apple figure assets/metadata, and saved qlmanage render evidence under docs/evidence/task-38.4/. Automated figure, content, web, and content-swift checks pass; Apple xbuild validation was not run per lane instructions.
<!-- SECTION:FINAL_SUMMARY:END -->
