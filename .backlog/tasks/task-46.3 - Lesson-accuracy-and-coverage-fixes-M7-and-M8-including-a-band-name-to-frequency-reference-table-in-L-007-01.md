---
id: TASK-46.3
title: >-
  Lesson accuracy and coverage fixes: M7 and M8 (including a band-name to
  frequency reference table in L-007-01)
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
ordinal: 101000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apply the High findings (and Medium ones that are a sentence or two) from docs/lesson-review/m7-m8.md. Follow docs/teaching-guide.md and content/lessons/README.md. Verify every new fact against the bank and primary sources (RBR-4, RIC-1, NRC and so on), and check the reference-sheet claims the reviewer could not verify against the ISED reference PDF. Never restate ISED question or answer text. Fix matching explanation files where the review flags them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every High finding in docs/lesson-review/m7-m8.md is fixed (or declined with a recorded reason), with question IDs listed in the notes
- [x] #2 Every covered question flagged as untaught or answer-key only is now taught with a reason
- [x] #3 Coverage, quizzes, originality, explanations and links checks pass; the taught-facts check finds no regressions
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read M7/M8 lessons, quizzes, explanations, generated bank, and primary/source references.\n2. Apply narrow prose fixes for each High finding plus approved quick Medium fixes, including compact band-name/frequency reference in L-007-01 and pointer from L-008-02.\n3. Update flagged explanation text and any quick concept-check replacements without restating official bank text.\n4. Run requested content/web/Swift checks, record findings-to-fixes and verified sources in task notes, check ACs, finalize Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation notes (task-46.3): fixed High findings and quick Medium fixes in M7/M8. Findings -> fixes:
- H1 B-007-006-004: L-007-02 now explains oblique paths as needing less bending at shallow angle, replacing the wrong path-length mechanism.
- H2 B-007-005-004: L-007-02 now teaches solar flux as a fixed 10.7 cm / 2 800 MHz measurement and adds the Canadian NRC/DRAO Penticton hook.
- H3 B-007-005-006: L-007-02 now names both electromagnetic and particle radiation, with CMEs as occasional disturbances.
- H4 B-007-004-011: L-007-02 fading section now teaches phase distortion from delayed copies.
- H5 B-007-007-004: L-007-03 now defines tropospheric wave and contrasts it with ground wave.
- H6 B-008-003-003 and B-008-004-004: L-008-01/L-008-02 now distinguish out-of-band emissions near necessary bandwidth from farther-away spurious emissions; harmonics are identified as spurious. EXP-B-008-003-003 was aligned.
- H7 B-008-001-004/-010: L-008-01 now names high-pass at FM/TV receiver input and band-pass for desired VHF range, pointing forward to L-008-02 filter vocabulary.
- H8 B-008-001-011: L-008-01 worked example and Try-it now make receiver input filtering the first cure and explain attenuator fallback cost.
- H9 B-007-001-008, B-007-002-009, B-007-006-005/-009/-011, B-007-007-006, B-007-008-009/-011, B-008-004-001/-007/-010, B-008-005-009: L-007-01 now has a compact band-name/frequency table tied to 300 / f; L-007-03 covers six metres as about 50 MHz; L-008-02 points to the table and shows harmonic use.
Quick Medium fixes included: L-007-01 ionospheric-wave synonym, lower-frequency ground-wave reach around 200 km, NVIS below critical frequency and low horizontal antenna, reflection/refraction/diffraction/scattering table, F1/F2 merge at night wording, hop-count worked example, quiz C1/C3 replacements; L-007-02 SID cause, 40 MHz solar maximum ceiling, 20 m daylight reason, same-band beacon guidance, LUF caveat, quiz C3 replacement; L-007-03 800 km versus 46.7 km context, scatter-near-MUF reason, quiz C1/C3 replacements; L-008-01 headroom/front-end/common-mode/differential/circuit-common/neutralization definitions, external intermod junctions and outside-gain-antenna path, telephone RFI filter, overmodulation clarification, symptom triage table, all three concept checks replaced with technical discrimination items; L-008-02 overmodulation definition, out-of-band/spurious contrast, ambiguous meter wording, low-pass harmonic wording.
Taught-facts self-check: reviewed the flagged not-taught/answer-key-only/partial IDs from docs/lesson-review/m7-m8.md against the revised lessons and questions.json; all flagged covered facts are now taught in lesson prose or tables. Also checked changed paragraphs for preserving existing covered facts around D/E/F order, skip scales, MUF/LUF/OWF, radio horizon, sporadic E, aurora/meteor scatter, receiver overload, audio rectification, ferrites, key clicks, parasitics, harmonics and filters; no taught fact was intentionally dropped.
Sources verified/accessed 2026-10-12: content/generated/basic-2025-07-15/questions.json for all question IDs; ISED RBR-4 Schedule I amateur bands at https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service for amateur band frequency ranges; ISED Basic reference PDFs in content/sources/ised/basic-2025-07-15/reference/ extracted with Swift PDFKit, confirming F = 300 / lambda and lambda = 300 / F; Space Weather Canada/NRC solar flux pages https://www.spaceweather.gc.ca/forecast-prevision/solar-solaire/solarflux/sx-2-en.php, sx-3-en.php, and sx-4-en.php for 10.7 cm, 2 800 MHz, daily flux data, and DRAO/Penticton/NRC context. No new RIC-1/RIC-3 operating-procedure facts were added.
Skipped as separate-task scope: Try-it answer hiding -> task-46.5; faded practice and full concept-check/interleaving redesign -> task-46.6/task-46.7 (only quick replacements done here); lesson splits/coverage moves and L-008-01 length reduction/section reshuffle -> task-46.10; cross-module prerequisite front matter -> task-46.11; figure/directive work and visual production -> existing figure lane/task-38; M1/M2 changes -> task-46.4/task-46.8/task-46.9.
Validation passed: node packages/content-tools/src/check-lesson-coverage.ts; pnpm --dir packages/content-tools check:quizzes; pnpm --dir packages/content-tools check:lesson-originality:all; pnpm --dir packages/content-tools check:explanations; pnpm check:links; cd apps/web && npx vitest run (15 files, 160 tests; jsdom canvas getContext warnings only); DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift (18 XCTest tests passed plus Swift Testing 0-test suite passed).

Review r463 requested changes after 778a9d8. Merged origin/main first (kept branch task-46.3 conflict version as instructed). Fixing answer-pair/near-copy issues, band table completeness, emission definitions, affected explanation, and concept checks; then rerunning required checks.

Review r463 fixes completed after merging origin/main (kept branch task-46.3 file on conflict):
- Removed bank-answer pairs from new prose: changed L-007-01 worked hop example from 5 000 km/multi-hop to a 9 000 km/several-hop planning example; removed L-008-02 15 m third harmonic -> 63 MHz and 28 MHz doubled -> 56 MHz examples, replacing with 17 m near 18.1 MHz -> 36.2 MHz; removed the 100 MHz distractor sentence from L-007-02; replaced the explicit 28 MHz beacon example with a same-band beacon principle.
- Fixed harmonic band-name guidance: L-008-02 now points only to L-007-01's real band-frequency table, not 300 / f; L-007-01 now says band names are approximate and gives the 20 m/14 MHz caveat.
- Completed the L-007-01 compact reference with RBR-4 Canadian allocation values for 17 m (18.068 MHz to 18.168 MHz), 12 m (24.890 MHz to 24.990 MHz), 6 m (50 MHz to 54 MHz), 2 m (144 MHz to 148 MHz), and 70 cm (430 MHz to 450 MHz), and clarified the 31 m broadcast row as receive-only shortwave context between 40 m and 30 m.
- Reworked out-of-band/spurious wording by cause in L-008-01, L-008-02, and the triage table: out-of-band is modulation-process energy just outside necessary bandwidth; spurious is other unwanted output outside necessary bandwidth, near or far. Aligned EXP-B-008-003-002 and tightened EXP-B-008-003-003.
- Paraphrased near-copies in L-008-01 telephone RFI wording, L-007-03 tropospheric-wave wording, and L-008-01 receiver-intermod antenna wording.
- Rewrote QZ-L-007-03-A C1/C3 and QZ-L-008-01-A C1 to test applied reasoning without restating the bank stems/answers.
Validation rerun after r463 fixes passed: node packages/content-tools/src/check-lesson-coverage.ts; pnpm --dir packages/content-tools check:quizzes; pnpm --dir packages/content-tools check:lesson-originality:all; pnpm --dir packages/content-tools check:explanations; pnpm check:links; cd apps/web && npx vitest run (15 files, 160 tests; jsdom canvas getContext warnings only); DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift (18 XCTest tests passed plus Swift Testing 0-test suite passed).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Addressed review r463 after merging origin/main: removed added bank-answer pairs and near-copy wording, completed and clarified the L-007-01 band table with Canadian allocation values, corrected harmonic guidance to use real band frequencies, defined out-of-band versus spurious by cause, aligned B-008-003 explanations, and rewrote the flagged concept checks. Revalidated with coverage, quizzes, lesson originality :all, explanations, links, web vitest, and Swift content package tests.
<!-- SECTION:FINAL_SUMMARY:END -->
