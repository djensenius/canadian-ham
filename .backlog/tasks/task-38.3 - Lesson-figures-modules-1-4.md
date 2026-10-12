---
id: TASK-38.3
title: 'Lesson figures: modules 1-4'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 20:55'
updated_date: '2026-10-12 16:08'
labels:
  - content
  - apple
  - web
dependencies:
  - TASK-38.1
parent_task_id: TASK-38
priority: low
ordinal: 81000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Draw the remaining Illustration brief figures for lessons in m1-regulations-policies, m2-operating-procedures, m3-station-practice-safety and m4-circuit-components (except those covered by task-38.2), following each brief's alt text and description.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every brief in modules 1-4 not covered by task-38.2 has a drawn figure referenced from its lesson
- [ ] #2 Same accessibility and originality bar as task-38.1; audits pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inventory module 1-4 illustration briefs and choose one stable figure id per lesson, excluding L-004-03.\n2. Draw simple original currentColor SVGs with generous text clearance, add matching ::figure directives and text equivalents where dense.\n3. Regenerate figure assets/metadata with pnpm check:figures:fix, render every figure with qlmanage into docs/evidence/task-38.3/, inspect previews, and iterate.\n4. Run figure/content/web/Swift content checks; record per-figure evidence and leave Apple app xbuild validation unchecked for the later integration lane.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Figure notes batch m4: L-004-01 amplifiers-diodes shows weak input/larger output, amplifier supply energy, and diode anode/cathode with conventional-current and electron-flow directions; verified against lesson text and B-004-001/B-004-002 quiz questions B-004-001-001..010 and B-004-002-001..009, especially B-004-002-005 and B-004-002-007. L-004-02 control-terminals shows NPN, N-channel FET, and triode terminals with base/gate/grid circled as controls; verified against lesson text and B-004-003/B-004-004/B-004-005 quiz questions B-004-003-001..011, B-004-004-001..011, and B-004-005-001..009.

Figure notes batch m2a: L-002-01 voice-repeater-simplex shows repeater input/output, pause/listen, CTCSS/offset, and direct simplex after copy is confirmed; verified against lesson text and quiz questions B-002-001-001..004, B-002-002-001..010, B-002-003-001..005, and B-002-004-001..005. L-002-02 morse-rst-contact-flow shows QRL?/listen, CQ, DE, call signs, RST, 73, and separate R/S/T gauges; verified against lesson text and quiz questions B-002-005-001..010, B-002-006-001..010, and B-002-007-001..005, including B-002-006-009 for RST separation.

Figure notes batch m2b: L-002-03 distress-urgency-safety-board shows distress as life-threatening with MAYDAY/SOS, urgent as serious help, safety as hazard information, plus spare battery and portable dipole go-kit; verified against lesson text and B-002-008-001..010. L-002-04 records-maps-locators shows UTC/call/band/mode/grid logging, centred azimuthal map, opposite short/long paths, UTC clock, and 4- or 6-character grid note; verified against lesson text and B-002-009-001..010, especially B-002-009-002, B-002-009-003, B-002-009-004, and B-002-009-006 for 180 degrees.

Figure notes batch m1a: L-001-01 authority-records-exams shows Act, Regulations, ISED standards, certificate/call sign, address reminder, and ISED/accredited-examiner exam paths; verified against lesson reference facts and quiz questions B-001-001-001..004, B-001-002-001..009, B-001-003-001..008, B-001-004-001..007, and B-001-022-001..005. L-001-02 station-control-decision-tree shows authorization, radio service, message purpose, control operator, own-licence side branch, non-commercial/open messages, and qualified supervision; verified against lesson text and B-001-005-001..010, B-001-006-001..011, B-001-007-001..011, B-001-008-001..010, and B-001-009-001..011.

Figure notes batch m1b: L-001-03 communications-flowchart shows interference listen/change/stop, distress exception/stand-by, third-party personal/supervised handling, and start/end/30-minute identification; verified against lesson text and B-001-010-001..011, B-001-011-001..010, B-001-012-001..006, B-001-013-001..009, and B-001-014-001..009, especially B-001-013-006 and B-001-013-009. L-001-04 privileges-station-checklist shows certificate-radio-amplifier-antenna chain, qualification/band/bandwidth/output-power/repeater/modulation checks, and band-edge width inset; verified against lesson text and B-001-015-001..010, B-001-016-001..011, B-001-017-001..010, B-001-018-001..010, and B-001-019-001..007.

Figure notes batch m1c: L-001-05 international-location-checklist shows travel desk, message/location/ID-format checklist, ITU Regions 1/2/3, and US/CEPT visit branches; verified against lesson text and B-001-020-001..010 plus B-001-021-001..005, including Region 2 for Canada, Region 3 for Australia/Japan/Southeast Asia, and Region 1 for Europe/Africa. L-001-06 antenna-rf-emc-checklists shows antenna consultation, RF keep-clear factors (power, gain, distance, frequency), field-strength meter, home entertainment gear, and affected control device; verified against lesson text and B-001-023-001..010, B-001-024-001..010, and B-001-025-001..010.

Figure notes batch m3a: L-003-01 station-filtering-radio-blocks shows HF chain (TX/amp, LPF close to output, SWR, tuner, switch, antenna/dummy) and FM superhet receiver chain (antenna, RF, mixer plus LO, IF filter/amp, limiter, discriminator/AF); verified against lesson text and B-003-001-001..010, B-003-002-001..008, and B-003-003-001..011. L-003-02 cw-ssb-signal-paths shows CW transmitter oscillator-buffer-PA with key, SSB/CW receiver path with LO/BFO, and SSB transmitter path mic-speech-balanced modulator-filter-mixer-final; verified against lesson text and B-003-004-001..008, B-003-005-001..010, and B-003-006-001..008.

Figure notes batch m3b: L-003-03 digital-interface-linear-supply shows laptop/interface/radio RX audio, TX tones, PTT line, and AC-to-DC supply chain with transformer, rectifier, filter capacitor, regulator, output terminals, and output sensing; verified against lesson text and B-003-007-001..007 plus B-003-008-001..010. L-003-04 yagi-receiver-specs shows Yagi reflector/driven/director/boom/feedline, receiver display/filter choices, and desired/LO/image IF spacing markers; verified against lesson text and B-003-009-001..011 plus B-003-010-001..010.

Figure notes batch m3c: L-003-05 signal-quality-cw-ssb-fm shows clean CW carrier/click-risk jagged edge, SSB ALC limit and clipped/splatter cue, and FM centre/deviation/over-deviation; verified against lesson text and B-003-011-001..006, B-003-012-001..010, and B-003-013-001..010. L-003-06 controls-digital-voice-packet shows paddle-to-keyer timing, microphone gain/VOX/speech processing, transceiver receiver noise tools, and packet station-digipeater-station path; verified against lesson text and B-003-014-001..010 plus B-003-015-001..005.

Figure notes batch m3d: L-003-07 batteries-dc-supplies-ripple shows DC source, fuse close to source, heavy leads to transceiver, regulated and ripple waveforms, and series/parallel battery mini-icons; verified against lesson text and B-003-016-001..010 plus B-003-017-001..010, especially B-003-017-005, B-003-017-007, and B-003-017-010. L-003-08 grounding-lightning-rf-safety shows locked power, unplugged mic, station equipment bonded to a single ground bar, surge panel/building bond, storm disconnect cue, antenna RF keep-clear area, and people outside; verified against lesson text and B-003-018-001..011, B-003-019-001..010, B-003-020-001..010, and B-003-021-001..005.

Validation passed: qlmanage rendered all 23 SVGs to docs/evidence/task-38.3/ and previews were inspected for text clearance/legibility; no Apple xbuild app validation was run in this lane per instruction, so real Apple app screenshot validation remains deferred until task-38.1/main integration. Automated checks passed: pnpm check:figures:fix; pnpm check:figures; node scripts/check-figures.mjs --self-test; content coverage/quizzes/originality:all/explanations/links; web Vitest; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift.

Review follow-up: unchecking AC #2 because Apple app validation/light-dark screenshot audits are deferred until after task-38.1 merges; this round addresses review findings and reruns non-xbuild checks.

Review follow-up fixed: redrew the requested technical figures (CW keying now controls PA, RX/TX audio arrows corrected, FM receiver includes discriminator, station grounds are bonded, triode grid is between cathode and plate), moved all 20 directives inline beside teaching sections, rewrote text equivalents to match drawn labels, added the task-38.3 originality note, removed 38.1 evidence from docs/evidence/task-38.3, regenerated Apple assets, rendered 20 task-38.3 qlmanage PNGs, and inspected each PNG for label collisions/clearance.

Review follow-up visual verification after hardened checker merge: qlmanage rendered all 20 task-38.3 SVGs at 1200 px into /tmp/task-38.3-visual and docs/evidence/task-38.3; I opened every PNG with the read tool. Visual notes: authority-records-exams: authority stack, address 30 days card, and ISED/examiner exam branches are clear with no clipping. station-control-decision-tree: auth/service/purpose/control-op flow connects to own licence, non-commercial open messages, and qualified supervision boxes. communications-flowchart: three lanes show interference, distress, and 3rd party flows; labels are separated from arrows and ID 30 min is near the clock. privileges-station-checklist: station chain, checklist boxes, band-edge inside/spills insets, and checkmarks are legible. international-location-checklist: travel desk, checklist, divided ITU map, and US/CEPT branches are visible without label collisions. antenna-rf-emc-checklists: consult/RF exposure/EMC panels show nearby person, folder, clear zone, meter, home, and ctrl labels clearly. voice-repeater-simplex: repeater box sits above the hill curve, input/output arrows do not cut labels, and simplex arrow is clear. morse-rst-contact-flow: Morse timeline and R/S/T meter panel are legible and separated. distress-urgency-safety-board: priority board text is readable and go-kit battery/dipole labels are separate. records-maps-locators: log columns, UTC clock, azimuthal short/long paths, and grid label are clear. station-filtering-radio-blocks: HF chain, switch-to-dummy branch, and FM receiver row including LO and discriminator are readable. cw-ssb-signal-paths: CW key is at PA, LO/BFO/VFO labels sit by their injected oscillators, and RX/SSB rows are clear. digital-interface-linear-supply: RX/TX/PTT directions, shunt capacitor, regulator, DC, and sense output are clear. yagi-receiver-specs: reflector/driven/director/boom/feedline labels, W/M/N filter markers, and desired/LO/image IF markers are separated. signal-quality-cw-ssb-fm: CW smooth/click risk, SSB ALC/flat clips, and FM centre/deviation/overdev labels are readable. controls-digital-voice-packet: paddle/keyer/TX key, mic/gain/VOX/spch, radio noise tools, and packet path are clear. batteries-dc-supplies-ripple: DC source, + fuse, heavy leads, radio, regulation/ripple, and series/parallel icons are legible. grounding-lightning-rf-safety: lock, mic off, bonded ground path, grounded surge box, storm-off arrow, antenna, and outside people are clear. amplifiers-diodes: amplifier input/output are same-frequency with larger output, supply connects to the amplifier, and diode current/e-flow directions are clear. control-terminals: NPN, N-FET, and triode terminal labels have leader/nearby placement; grid is between cathode and plate and circled.
Validation passed after fetching/merging origin/task-38.5-figure-checker (already up to date): pnpm check:figures; node scripts/check-figures.mjs --self-test; pnpm check:figures:fix; qlmanage/read-tool visual inspection of all 20 figures; content coverage, quizzes, originality:all, explanations, links; pnpm test; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift. AC #2 remains unchecked because Apple app xbuild/light-dark screenshot validation is deferred.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Review follow-up addressed for task-38.3: 20 module 1-4 figures redrawn/simplified for technical accuracy and legibility, directives moved inline, text equivalents synced to visible labels, Apple figure assets regenerated, task-38.3 originality note added, and evidence refreshed with only the 20 task-38.3 qlmanage PNGs. AC #2 remains unchecked because Apple app validation/light-dark screenshots are deferred until after task-38.1 merges.
<!-- SECTION:FINAL_SUMMARY:END -->
