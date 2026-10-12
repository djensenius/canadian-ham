---
id: TASK-38.3
title: 'Lesson figures: modules 1-4'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 20:55'
updated_date: '2026-10-12 14:37'
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
- [ ] #1 Every brief in modules 1-4 not covered by task-38.2 has a drawn figure referenced from its lesson
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
<!-- SECTION:NOTES:END -->
