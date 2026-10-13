---
id: TASK-46.2
title: 'Lesson accuracy and coverage fixes: M6 and M3'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-12 14:57'
updated_date: '2026-10-12 15:26'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
priority: high
ordinal: 100000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apply the High findings (and Medium ones that are a sentence or two) from docs/lesson-review/m6-m3.md. Follow docs/teaching-guide.md and content/lessons/README.md. Verify every new fact against the bank and primary sources (RBR-4, RIC-1, NRC and so on), and check the reference-sheet claims the reviewer could not verify against the ISED reference PDF. Never restate ISED question or answer text. Fix matching explanation files where the review flags them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every High finding in docs/lesson-review/m6-m3.md is fixed (or declined with a recorded reason), with question IDs listed in the notes
- [x] #2 Every covered question flagged as untaught or answer-key only is now taught with a reason
- [x] #3 Coverage, quizzes, originality, explanations and links checks pass; the taught-facts check finds no regressions
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Verify M6/M3 findings against the bank, extracted ISED reference material, and primary sources before changing prose.
2. Patch only local lesson paragraphs, quizzes, and flagged explanations for High findings plus quick Medium fixes; skip structural follow-up tasks with recorded reasons.
3. Run content/web/Swift checks, record finding-to-fix notes with sources and question IDs, then finalize task-46.2.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation notes for task-46.2:

High findings fixed:
- L-006-01: corrected balun placement rule for balanced/unbalanced transitions (B-006-002-010, B-006-002-008).
- L-006-01: added inside-the-coax teaching for dielectric/velocity factor, foam vs solid dielectric choke risk, and shielding construction ranking (B-006-001-007, B-006-003-002, B-006-003-009, B-006-003-011).
- L-006-01: taught Z0 as conductor-ratio based, matched load behaviour, and mismatched-line input impedance varying with length (B-006-001-004, B-006-001-006, B-006-001-009, B-006-001-011, B-006-006-009).
- L-006-02: added a physical standing-wave explanation, current peaks/loss, and why low-loss open-wire line tolerates high SWR better (B-006-004-002, B-006-005-005, B-006-005-007, B-006-005-008).
- L-006-02: named RG-58/RG-213 loss implications and added wide-band transformer matching (B-006-004-001, B-006-004-006, B-006-006-007).
- L-006-03: derived 300/f from 300 000 km/s, defined ground wave and vertical polarization retention, and added the series-inductance/resonance statement (B-006-008-004, B-006-007-010, B-006-008-005).
- L-006-04: taught Yagi spacing near a fifth wavelength, wider spacing/gain, quarter-wave vertical horizontal omnidirectionality, and stacking as pattern concentration rather than created power (B-006-011-010, B-006-011-006, B-006-010-005, B-006-011-011).
- L-003-08: added antenna-repair power/feedline isolation and contrasted it with grounding, plus strengthened station grounding, RF-burn, and high-gain antenna placement wording (B-003-020-010, B-003-019-001, B-003-020-008, B-003-021-010).

Quick Medium fixes included:
- L-006-05: replaced the quad support/distractor framing with weather vulnerability, added trap harmonic risk, delta loops with parasitic elements, square-quad feed-point polarization, and a loop-length misconception callout (B-006-013-006, B-006-012-007, B-006-013-002, B-006-013-008, B-006-013-009).
- L-003-03 and QZ-L-003-03-A: removed bleeder-as-sufficient safety wording, made bleeders a non-substitute backup, revised the concept-check option, defined fixed pads, and separated 18 V AC secondary from roughly 23-24 V filtered DC (B-003-019-009).
- L-003-02: stated that the oscillator keeps running and keying controls carrier amplitude in a driver/amplifier stage; clarified balanced modulator vs mixer roles (B-003-004-004, B-003-006-009).
- L-003-05 and QZ-L-003-05-A: prioritized steady supply voltage for chirp, defined full quieting, and changed the FM bandwidth concept check from band-plan framing to Canadian regulation framing (B-003-011-002, B-003-013-009).
- L-003-07 and EXP-B-003-017-009: taught wire-gauge numbering/minimum-gauge meaning and reworded the No. 8 distractor explanation (B-003-017-009).
- L-003-04: taught amplitude for waterfall strength, explained 750-850 Hz from a 100 Hz filter centred on 800 Hz, and defined filter skirts (B-003-010-003, B-003-010-011).
- L-003-06: changed RTTY spacing to 250-500 Hz, linked packet reliability to emergency use, and defined grid (B-003-015-007, B-003-015-009).
- L-003-01: clarified tuner use with an antenna outside its designed band (B-003-001-006).
- M6 quizzes: replaced quick giveaway/duplicate concept checks in QZ-L-006-01-A, QZ-L-006-02-A, QZ-L-006-04-A, and QZ-L-006-05-A without adding interleaving.

Skipped/deferred because they are separate structural tasks or out of this task's quick-fix scope:
- Try-it answer hiding/retrieval formatting: task-46.5.
- Faded practice and richer concept-check feedback: task-46.6.
- Interleaved quiz items: task-46.7.
- Lesson splits/coverage moves for long lessons and mixed topics: task-46.10.
- Cross-module prerequisite front matter: task-46.11.
- New figure directives/visual production for M6/M3: left to the active figure lanes/task-38 to avoid merge conflicts; this branch only adjusted prose adjacent to fixed findings.
- Low-polish items such as estimatedMinutes, broad story-to-worked-example renames, and M3 index status were not changed.

Source verification (accessed 2026-10-12 unless local path noted):
- Active bank: content/generated/basic-2025-07-15/questions.json for every question ID listed above.
- ISED reference PDFs extracted locally with Swift PDFKit from content/sources/ised/basic-2025-07-15/reference/. The exam sheet extraction shows λ=300/F, L=306/F, L=142/F, L=71/F and E/I/R/P formulas; the training sheet adds formula descriptions. No new unverified 'reference sheet gives...' prose was added.
- ISED RBR-4: https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service (checked bandwidth section and Schedule I for the below-28-MHz occupied-bandwidth framing).
- Health Canada Safety Code 6: https://www.canada.ca/en/health-canada/services/publications/health-risks-safety/limits-human-exposure-radiofrequency-electromagnetic-energy-range-3-300.html (checked RF exposure framework for existing L-003-08 Safety Code 6 framing).
- ISED RIC-1: https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-1-guide-examiners-accredited-conduct-examinations-amateur-radio-operator-certificates and RIC-3: https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-3-information-amateur-radio-service were reachable for current amateur-service/exam context; no new lesson claim depended on an unverified RIC-only fact.

Validation results:
- node packages/content-tools/src/check-lesson-coverage.ts: passed (100/100 subsections, no duplicates).
- pnpm --dir packages/content-tools check:quizzes: passed (36 quiz files, 504 official refs, 78 concept checks).
- pnpm --dir packages/content-tools check:lesson-originality:all: initial run found originality collisions; after wording fixes it passed (36 lessons, 984 official questions, 0 issues).
- pnpm --dir packages/content-tools check:explanations: passed (984 explanations, 2952 per-choice notes).
- pnpm check:links: passed (Markdown relative links verified).
- cd apps/web && npx vitest run: first full run failed 2 existing/flaky course-switch tests, rerun passed (15 files, 160 tests). Canvas getContext jsdom warnings only.
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift: passed (18 ContentLibraryTests).
- Apple app suites were not run; this was content-only work per task instructions.

Review round for 8ee77cf: merged origin/main into task-46.2-lesson-fixes-m6-m3 and kept this branch's task-46.2 file on the expected task-file conflict. Applying requested accuracy, reason-depth, quiz, low-item, taught-facts-note, and validation fixes.

Review fix round for 8ee77cf:
- Merged origin/main into task-46.2-lesson-fixes-m6-m3 first; expected conflict was only task-46.2 and I kept this branch's version.
- Fixed L-003-03 transformer/rectifier voltage wording: 18 V AC gives about 25.5 V peak, roughly 23-24 V after the bridge diodes before ripple/load.
- Rewrote QZ-L-003-05-A-C3 so the 80 m/below-28-MHz case and 10 m case are both introduced, and the explanation uses regulatory occupied-bandwidth reasoning.
- Added reasons, not just answer statements: ground-wave vertical polarization (horizontal E-field weakened by ground currents), vertical horizontal-pattern symmetry, transformer broadband matching from turns ratio rather than LC resonance, quad feed-point polarization from current peaks, and RTTY spacing from shift plus keying sidebands.
- Replaced QZ-L-006-01-A-C1 with the window-line/unbalanced-tuner balun-placement concept check. Rewrote QZ-L-006-04-A-C2/C3 with real misconceptions about vertical directionality and stacked antenna gain.
- Applied Low review items: separated conductor vs dielectric loss peaks, restored stacking doubling => +3 dB and identical-pair wording in the body, strengthened matched-load absorption wording, removed quad support-complexity wording, restored the trap-harmonic reason, explained foam dielectric as mostly air, used about 0.2 λ wording, and revised QZ-L-003-03-A-C3 to plant the bleeder-resistor misconception.

Per-lesson taught-facts check for this review round:
- L-006-01: all covered B-006-001/002/003 facts retained; added body coverage for window-line balun placement and kept coax route/buried-route teaching intact.
- L-006-02: all covered B-006-004/005/006 facts retained; transformer bandwidth, high-SWR loss, and matched-line-length facts now include reasons.
- L-006-03: all covered B-006-007/008 facts retained; ground-wave vertical-polarization and 300/f facts now include reasons.
- L-006-04: all covered B-006-009/010/011 facts retained; vertical pattern, Yagi spacing, and stacking facts now include reasons and non-giveaway checks.
- L-006-05: all covered B-006-012/013 facts retained; trap-harmonic, quad weather, parasitic-loop, loop-length, and feed-point-polarization facts now include reasons.
- L-003-03: all covered B-003-007/008 facts retained; linear-supply voltage/discharge wording corrected.
- L-003-05: all covered B-003-011/012/013 facts retained; FM bandwidth/regulatory concept check is coherent.
- L-003-06: all covered B-003-014/015 facts retained; RTTY spacing and packet reliability facts remain taught with reasons.

Deferred non-High P/T items explicitly not expanded in this follow-up:
- B-006-006-006 (tuner adds reactance) remains sufficient in current matching/tuner prose; no structural tuner expansion was added.
- B-006-001-005 (buried/near-soil coax route) remains taught in L-006-01 Try it/routing context but was not expanded into a new body section.
- B-006-010-008 and B-006-009-003/-004 remain supported by the existing vertical/Yagi directivity prose; no additional coverage move was made.
- B-003-018-003 remains taught in L-003-07; no cross-lesson coverage move was made.

Validation for review round:
- node packages/content-tools/src/check-lesson-coverage.ts: passed (100/100 subsections; no duplicates).
- pnpm --dir packages/content-tools check:quizzes: passed (36 quiz files, 504 official refs, 78 concept checks).
- pnpm --dir packages/content-tools check:lesson-originality:all: passed after local wording fixes (36 lessons, 984 official questions, 0 issues).
- pnpm --dir packages/content-tools check:explanations: passed (984 explanations, 2952 per-choice notes).
- pnpm check:links: passed (Markdown relative links verified).
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift: passed (18 ContentLibraryTests).
- cd apps/web && npx vitest run: first run failed one unrelated/loading timing test; immediate rerun passed (15 files, 160 tests). Canvas getContext jsdom warnings only.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Addressed REQUEST CHANGES on 8ee77cf after merging main: corrected L-003-03 rectifier voltage, made QZ-L-003-05-A-C3 coherent, added physical/regulatory reasons for answer-only coverage items, replaced weak M6 concept checks, applied requested Low wording fixes, recorded per-lesson taught-facts/deferred notes, and reran content, web, and Swift content checks.
<!-- SECTION:FINAL_SUMMARY:END -->
