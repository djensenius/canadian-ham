---
id: TASK-38.4
title: 'Lesson figures: modules 5-8'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 20:55'
updated_date: '2026-10-12 14:38'
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
- [ ] #1 Every brief in modules 5-8 not covered by task-38.1/38.2 has a drawn figure referenced from its lesson
- [ ] #2 Same accessibility and originality bar as task-38.1; audits pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add one original SVG and ::figure reference for each in-scope module 5-8 illustration brief, leaving excluded task-38.1/38.2 lessons untouched.\n2. Verify figure labels, clearances, and technical values against lesson text and content/generated/basic-2025-07-15/questions.json.\n3. Regenerate Apple figure assets/metadata with pnpm check:figures:fix, render every SVG with qlmanage into docs/evidence/task-38.4/, inspect thumbnails, then run figure, content, web, and content-swift checks.\n4. Record per-figure notes and leave Apple xbuild validation acceptance unchecked per lane instructions.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Figures added in first slice: L-005-05 transformer-resonance-meters shows primary/secondary transformer flux coupling, parallel LC high impedance at resonance, voltmeter across load and ammeter in series; verified against B-005-011-001..011, B-005-012-001..011, B-005-013-001..010 and lesson values 240 V/360 W/1.5 A, 240 V x 0.3 A = 72 W, 36 V secondary, 300 mA step-up example. L-006-01 feedline-types-balun shows coax shield/centre conductor as unbalanced, window/open-wire balanced lines, and balun at dipole feed point; verified against B-006-001-001..011, B-006-002-001..011, B-006-003-001..011 including 50-ohm amateur coax and 75-ohm TV coax lesson contrast. L-006-02 swr-loss-matching shows forward/reflected waves, line loss reducing returned reflection, and feed-point matching; verified against B-006-004-001..010, B-006-005-001..011, B-006-006-001..011 including SWR estimates 1.5:1=4%, 2:1≈11%, 3:1=25% and 240/60=4:1 lesson example.

Figures added in second slice: L-006-04 yagi-vertical-length shows reflector longer, driven feed element, director shorter, main-lobe direction, quarter-wave vertical with radials and 71.3 / f(MHz); verified against B-006-009-001..011, B-006-010-001..011, B-006-011-001..011 including 143/f driven-element lesson examples, 71.3/f quarter-wave convention, 150/f VHF half-wave convention, and dBi-dBd 2.1 dB reference. L-006-05 loop-antenna-patterns shows dipole torus/broadside pattern, quad square loop, delta loop feed points, and 306 / f(MHz); verified against B-006-012-001..009 and B-006-013-001..011 including 73-ohm free-space dipole feed point and 306/f loop examples. L-007-01 propagation-paths-skip-zone shows VHF line of sight, ground wave, NVIS, low-angle sky wave, D/E/F1/F2 order, and skip zone; verified against B-007-001-001..010, B-007-002-001..011, B-007-003-001..011 including D lowest, F2 highest, E-region ~2000 km and F2 ~4000 km single-hop planning scales.

Figures added in third slice: L-007-02 daytime-absorption-frequency-window shows Sunlit D-region absorption, F-region return, and frequency window with LUF/OWF/MUF; verified against B-007-004-001..011, B-007-005-001..011, B-007-006-001..011 including 11-year solar cycle, OWF slightly below MUF, and lesson example LUF 5.8 MHz, MUF 18.6 MHz, OWF 15.8 MHz (0.85 x MUF). L-007-03 vhf-unusual-propagation-modes shows sporadic E, tropospheric ducting, auroral scatter, and meteor scatter; verified against B-007-007-001..011 and B-007-008-001..011 including six metres for sporadic E/meteor scatter, auroral E-region/north/CW clues, 800 km normal VHF planning scale, temperature-inversion ducting, and meteor scatter 30-100 MHz.
<!-- SECTION:NOTES:END -->
