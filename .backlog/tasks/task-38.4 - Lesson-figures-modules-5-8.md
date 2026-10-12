---
id: TASK-38.4
title: 'Lesson figures: modules 5-8'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 20:55'
updated_date: '2026-10-12 16:11'
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
Figures added in first slice: L-005-05 transformer-resonance-meters shows primary/secondary transformer flux coupling, parallel LC high impedance at resonance, voltmeter across load and ammeter in series; verified against B-005-011-001..011, B-005-012-001..011, B-005-013-001..010 and lesson values 240 V/360 W/1.5 A, 240 V x 0.3 A = 72 W, 36 V secondary, 300 mA step-up example. L-006-01 feedline-types-balun shows coax shield/centre conductor as unbalanced, window/open-wire balanced lines, and balun at dipole feed point; verified against B-006-001-001..011, B-006-002-001..011, B-006-003-001..011 including 50-ohm amateur coax and 75-ohm TV coax lesson contrast. L-006-02 swr-loss-matching shows forward/reflected waves, line loss reducing returned reflection, and feed-point matching; verified against B-006-004-001..010, B-006-005-001..011, B-006-006-001..011 including SWR estimates 1.5:1=4%, 2:1≈11%, 3:1=25% and 240/60=4:1 lesson example.

Figures added in second slice: L-006-04 yagi-vertical-length shows reflector longer, driven feed element, director shorter, main-lobe direction, quarter-wave vertical with radials and 71.3 / f(MHz); verified against B-006-009-001..011, B-006-010-001..011, B-006-011-001..011 including 143/f driven-element lesson examples, 71.3/f quarter-wave convention, 150/f VHF half-wave convention, and dBi-dBd 2.1 dB reference. L-006-05 loop-antenna-patterns shows dipole torus/broadside pattern, quad square loop, delta loop feed points, and 306 / f(MHz); verified against B-006-012-001..009 and B-006-013-001..011 including 73-ohm free-space dipole feed point and 306/f loop examples. L-007-01 propagation-paths-skip-zone shows VHF line of sight, ground wave, NVIS, low-angle sky wave, D/E/F1/F2 order, and skip zone; verified against B-007-001-001..010, B-007-002-001..011, B-007-003-001..011 including D lowest, F2 highest, E-region ~2000 km and F2 ~4000 km single-hop planning scales.

Figures added in third slice: L-007-02 daytime-absorption-frequency-window shows Sunlit D-region absorption, F-region return, and frequency window with LUF/OWF/MUF; verified against B-007-004-001..011, B-007-005-001..011, B-007-006-001..011 including 11-year solar cycle, OWF slightly below MUF, and lesson example LUF 5.8 MHz, MUF 18.6 MHz, OWF 15.8 MHz (0.85 x MUF). L-007-03 vhf-unusual-propagation-modes shows sporadic E, tropospheric ducting, auroral scatter, and meteor scatter; verified against B-007-007-001..011 and B-007-008-001..011 including six metres for sporadic E/meteor scatter, auroral E-region/north/CW clues, 800 km normal VHF planning scale, temperature-inversion ducting, and meteor scatter 30-100 MHz.

Figures added in fourth slice: L-008-01 interference-troubleshooting-map separates receiver overload, audio rectification, and transmitter spurious outputs; verified against B-008-001-001..011, B-008-002-001..011, B-008-003-001..011 including high-pass at TV receiver, ferrite coils/lead shortening/common-mode choke cures, key clicks, spurious emissions, and parasitic oscillation. L-008-02 filter-response-sketches shows low-pass, high-pass, band-pass, band-reject, and notch frequency responses with pass/attenuate labels; verified against B-008-004-001..011 and B-008-005-001..011 including harmonics as integer multiples, second harmonic example at 56 MHz from 10 m, overdrive/flat topping, filter placement, and impedance matching.

Validation/render evidence: ran pnpm check:figures:fix, pnpm check:figures, node scripts/check-figures.mjs --self-test, content coverage/quizzes/originality:all/explanations/links, web vitest, and content-swift swift test. Rendered all 13 figure SVGs with qlmanage -t -s 800 and inspected the PNGs; final renders are saved under docs/evidence/task-38.4/. AC #2 remains unchecked because Apple in-app/xbuild validation is intentionally deferred in this lane per task instructions.

Review fix a1b5730: redrew the technically incorrect feedline/balun, SWR/loss/matching, transformer/parallel-LC/meter, propagation-path, and daytime-absorption figures; corrected interference, Yagi, loop, VHF modes, and filter response details; moved all task-38.4 figure directives inline beside the relevant lesson sections; rewrote text equivalents to match the final drawings; added the task-38.4 originality note; removed task-38.1 render PNGs from docs/evidence/task-38.4; regenerated Apple assets and qlmanage evidence. Validation rerun: pnpm check:figures:fix; pnpm check:figures; node scripts/check-figures.mjs --self-test; pnpm --dir packages/content-tools check:coverage/check:quizzes/check:lesson-originality:all/check:explanations; pnpm check:links. Re-rendered and inspected all 10 changed SVGs with qlmanage.

Review-fix checker output summary from /tmp/task384_svg_probe.py (0.7*font-size*chars text boxes; paths sampled at 100 points):
- propagation-paths-skip-zone: TEXT CLEAR. Layer path y-ranges: D 424.0-448.0, E 324.5-350.0, F1 227.0-254.0, F2 126.5-158.0. NVIS ray y=196.0-574.0, x=220.0-400.0; low-angle ray y=161.5-574.0, x=220.0-820.0; both apexes are in the F region, with low-angle higher/longer. VHF direct x=116.0-736.0 y=499.5-522.0. Ground wave x=120.0-342.0 y=570.3-592.0. Skip bracket x=342.0-820.0 y=650.0.
- daytime-absorption-frequency-window: F line y=172.0-196.0; D band y=332.5-352.0; absorbed low-HF ray y=350.0-488.0 and ends at (190.0,350.0) on D band; F-return ray y=170.0-488.0 and reaches the F line; LUF/OWF/MUF markers x=600.0/830.0/880.0, with OWF close to MUF. Conservative text script reported only stacked-label gaps/overlaps; qlmanage render inspected clean after moving title and labels.
- transformer-resonance-meters: two separate transformer winding groups: primary paths x=76.0-152.0, secondary paths x=206.0-282.0, shared core bars x=152.0 and x=206.0. LC rails y=210.0 and y=410.0; coil branch x=400.5-439.5 y=250.0-410.0; capacitor plates x=498.0-566.0 at y=266.0-272.0 and y=348.0-354.0 with split leads to rails. Meter circuit: source plates y=260.0-332.0, A meter circle on top series path at y=180.0, load branch y=300.0-410.0, V meter leads connect to load endpoints. Render inspected clean.
- swr-loss-matching: TEXT CLEAR. Forward arrow x=94.0-674.0 y=85.5-116.0. Main feedline x=464.0-806.0 y=190.0 plus antenna branch. Thick reflected arrow x=580.0-790.0 y=274.0-310.0; thin reflected arrow x=184.0-552.0 y=278.0-306.0; lossy squiggle x=560.0-752.0 y=234.0-258.0. Feed-point tuner sketch main line x=174.0-688.0 to tuner, then x=806.0-876.0 to antenna branch.
- interference-troubleshooting-map: wanted TX output x=822.0-930.0 y=315.0; unwanted spurs x=812.0-914.0 y=120.0-200.0 and y=430.0-516.0; RX overload arrows enter the RX at y=278.0 and y=324.0. Speaker lead loop y=196.0-414.0, RF pickup arrow y=220.0-256.0, detector triangle y=324.0-368.0. Conservative text script reported a 5-unit speaker-lead/unwanted gap; qlmanage render inspected with no visual text collision.
- yagi-vertical-length: element y-ranges: reflector 152.0-490.0, driven 186.0-456.0, director 224.0-416.0; main lobe arrow x=530.0-748.0 y=286.0-350.0 points toward director; vertical/radials y=400.0-612.0 with formula beside the vertical. Conservative script reports only stacked label line gaps; render inspected with labels separated.
- feedline-types-balun: radio-to-balun line x=174.0-646.0 y=120.0; balun-to-feed-gap leads end at dipole feed gap x=686.0-710.0 and x=746.0-772.0, y=96.0. Coax cross-section y=388.0, window-line conductors y=372.0-410.0, open-wire conductors y=345.5-440.5. Conservative script reports stacked label line overlaps; render inspected clean.
- vhf-unusual-propagation-modes: sporadic-E ray touches patch at y=154.0 and ground at y=304.0; ducting ray x=570.0-876.0 y=195.0-228.0 between layers; aurora beam x=110.0-238.0 y=526.0-640.0 toward curtain paths y=444.0-600.0; meteor burst path y=506.0-596.0 touches meteor trail y=468.0-494.0 at (770.0,506.0) and starts/ends on station humps y=614.5-640.0. Conservative script reports stacked title/label gaps; render inspected clean.
- loop-antenna-patterns: dipole wire x=24.0-296.0 y=326.0 with vertical broadside ellipse; paired quad loops on boom x=316.0-624.0 y=295.5-300.0 and feed dot at driven loop; delta side-feed lead x=620.0-704.0 y=264.0-324.0 and bottom H-feed lead x=760.0 y=430.0-510.0. Conservative script reports stacked title/label gaps; render inspected clean.
- filter-response-sketches: low-pass response y=128.0-226.0, high-pass response y=128.0-226.0, band-pass response y=133.5-226.0, band-reject response y=486.0-544.0 with a wide dip, notch response y=486.0-532.5 with a narrow dip. Conservative script reports stacked label line gaps; render inspected clean.

Fresh review fix on branch task-38.4-figures: merged origin/task-38.5-figure-checker (fetch emitted credential-store warning 'fatal: failed to store: -25308' but merge reported already up to date on a1805a9ccaef6150858720a426e267ffbac00b06), fixed the latest r384-3 review findings, regenerated Apple assets, and refreshed docs/evidence/task-38.4 PNGs at qlmanage size 1200. Visual qlmanage reads: transformer-resonance-meters shows separate transformer windings on a two-bar core, connected LC tank rails with L and C labels, and a battery source, A meter, zigzag load and V meter wired across the load; feedline-types-balun shows radio feed to a balun at the centre feed gap of a dipole, plus labelled coax/window-line/open-wire sketches; swr-loss-matching shows rig-SWR-ATU-lossy-line-antenna chain with forward and reflected arrows and a separate tuner-at-feed-point sketch; yagi-vertical-length shows longer reflector, fed driven element, shorter director, main lobe toward director, and 71.3/f beside the vertical; loop-antenna-patterns shows weak labels at the dipole wire ends, paired quad loops on a boom with feed point, a delta loop with H and V feed dots, and the 306/f formula below; propagation-paths-skip-zone shows labelled D/E/F1/F2 layers, VHF direct path, ground wave, NVIS turning in the F-region area and landing before the low-angle skip-zone bracket, and low-angle sky wave returning far away; daytime-absorption-frequency-window shows sunlit D absorption, F return reaching the F line, separated LUF/OWF/MUF labels with OWF close to MUF, and too-low/too-high side labels; vhf-unusual-propagation-modes shows sporadic-E, ducting, aurora and meteor panels, with the meteor burst touching the trail and station humps; interference-troubleshooting-map shows overload arrows entering RX, a speaker lead into a diode-like detector/speaker input, and TX wanted plus two unwanted outputs with labels next to their paths; filter-response-sketches shows low-pass, high-pass, band-pass, wider band-reject and narrower notch responses with clear pass/attenuate labels. Verification rerun: pnpm check:figures:fix; pnpm check:figures; node scripts/check-figures.mjs --self-test; pnpm --dir packages/content-tools check:coverage/check:quizzes/check:lesson-originality:all/check:explanations; pnpm check:links; pnpm --filter @canadian-ham/web test. AC #2 intentionally remains unchecked pending Apple validation after task-38.1 merges.

Follow-up checker revision 9827527: merged origin/task-38.5-figure-checker and fixed all stricter label findings without loosening the checker. Re-rendered changed figures with qlmanage -t -s 1200 and read the PNGs. Visual reads: daytime-absorption-frequency-window has separated daytime HF and F return labels, D absorbs on the D band, and clear LUF/OWF/MUF window labels; interference-troubleshooting-map has the wanted TX label pulled inside the viewBox next to the wanted output and both unwanted labels beside their spur paths; loop-antenna-patterns has the left weak label pulled inside the edge near the dipole wire end and the right weak label remains clear; propagation-paths-skip-zone has low/angle as an aligned two-line stack beside the low-angle path with no collision; transformer-resonance-meters has the load label pulled inside and next to the zigzag load branch; vhf-unusual-propagation-modes has the sporadic E title and patchy label separated while patchy stays above the E patch. Verification: pnpm check:figures:fix, pnpm check:figures, and node scripts/check-figures.mjs --self-test all pass with zero failures.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added ten original SVG lesson figures for the in-scope modules 5-8 briefs, referenced them from lessons with alt text and text equivalents, regenerated Apple figure assets/metadata, and saved qlmanage render evidence under docs/evidence/task-38.4/. Automated figure, content, web, and content-swift checks pass; Apple xbuild validation was not run per lane instructions.
<!-- SECTION:FINAL_SUMMARY:END -->
