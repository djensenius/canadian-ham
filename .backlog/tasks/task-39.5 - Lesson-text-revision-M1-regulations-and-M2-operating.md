---
id: TASK-39.5
title: 'Lesson text revision: M1 regulations and M2 operating'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-10 22:15'
updated_date: '2026-10-10 23:28'
labels:
  - content
dependencies:
  - TASK-39.1
parent_task_id: TASK-39
priority: medium
ordinal: 88000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Revise all lessons in m1-regulations-policies and m2-operating-procedures to the teaching guide. M1 follows the reference-style rules in content/lessons/README.md (no Try-its, worked Q&A, practice items or Common mistakes); improve readability and add context and memory tricks within those rules. M2: practical on-air examples (a repeater contact, a simplex contact, giving a signal report).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every lesson in scope is revised to docs/teaching-guide.md: plain language (terms defined at first use, short sentences, active voice), with a technical-accuracy pass
- [x] #2 Each technical lesson gains at least one 'In the real world' example tied to everyday or station hardware, with worked numbers where useful (rule-reference lessons follow the reference-style rules in content/lessons/README.md)
- [x] #3 Memory tricks from the guide are added where they help, are accurate and inoffensive, and say what they help remember
- [x] #4 Coverage, quiz, explanation, originality and link checks pass; lesson IDs, front matter coverage and quiz references are unchanged; Illustration brief sections are left intact for task-38
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Preserve front matter, covers, quiz IDs, and Illustration brief blocks while revising only lesson prose/tables in M1 and M2 reference-style lessons.
2. For M1, tighten rule prose, add approved memory aids for certificate/address, identification, and power qualification limits, and add practical context without Try-its or Common mistakes.
3. For M2, add practical procedure descriptions and short on-air examples inside allowed reference-style sections, plus approved memory aids for phonetics, RST, Q signals, and UTC/logging where useful.
4. Verify facts against questions.json and docs/exam-facts.md, run required content checks after M1, after M2, and final full checks, then record notes, AC evidence, and final summary through Backlog CLI.

5. Address review r1 requested changes: replace the S-unit example numbers and definition, relocate M1 memory tricks, define ERP/EIRP and restore L-001-04 explanatory prose, remove learner-facing writer notes, add required worked/on-air examples, fix minor wording/originality concerns, rerun the full content validation suite, then record finding-by-finding notes and move Done last.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
M1 pass: revised L-001-01 through L-001-06 in reference style without changing front matter, covers, quiz IDs, or Illustration brief blocks. L-001-01 added station-binder real-world context and certificate/address memory aid; facts checked against B-001-001 through B-001-004, B-001-022, and docs/exam-facts.md. L-001-02 added club work-day station-control context; facts checked against B-001-005 through B-001-009. L-001-03 added public-service net context and start/stop/half-hour identification memory aid; facts checked against B-001-010 through B-001-014. L-001-04 added power-display context and Basic-power memory aid; power and below-30-MHz facts checked against B-001-015 through B-001-019 and docs/exam-facts.md. L-001-05 added travel note-card context and place-first memory aid; facts checked against B-001-020 and B-001-021. L-001-06 added installation-file context; Safety Code 6 and EMCAB facts checked against B-001-023 through B-001-025. M1 check tranche passed after rerunning a transient web timeout: coverage, quizzes, originality, explanations, links, TZ=UTC pnpm test, and swift test.

M2 pass: revised L-002-01 through L-002-04 in existing reference-style operating format without changing front matter, covers, quiz IDs, or Illustration brief blocks. L-002-01 added repeater-entry and simplex procedure examples, a 146.940 MHz minus 600 kHz offset calculation, and ITU phonetic memory aid; facts checked against B-002-001 through B-002-004. L-002-02 added RST and Q-signal memory aids plus real-world report and S-unit power examples; facts checked against B-002-005 through B-002-007. Adjusted the S-unit wording to avoid originality overlap while preserving the 6 dB/S-unit and quadrupling relationship. L-002-03 added distress-role memory aid and break-in/readiness examples; facts checked against B-002-008. L-002-04 added log-investigation and UTC conversion examples plus long-path memory aid; facts checked against B-002-009. M2 check tranche passed: coverage, quizzes, originality, explanations, links, TZ=UTC pnpm test, and swift test.

Final validation passed after all lesson edits and Backlog notes: node packages/content-tools/src/check-lesson-coverage.ts; pnpm --dir packages/content-tools check:quizzes; pnpm --dir packages/content-tools check:lesson-originality:all; pnpm --dir packages/content-tools check:explanations; pnpm check:links; TZ=UTC pnpm test; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift. Pinned L-005-01 and L-006-03 expectations were not touched because this task did not change those lessons.

Review r1 fixes, finding by finding: 1 fixed by changing the S-unit example from 25 W -> 100 W to 10 W -> 40 W. 2 fixed by defining an S-unit as a marked step on a receiver signal-strength meter and restoring clear 6 dB per S-unit wording. 3 fixed by moving all four M1 memory tricks to the ends of their How these rules fit together sections. 4 fixed by defining PEP, ERP, and EIRP before the tables and restoring explanatory prose for the repeater/carrier/stability/modulation table. 5 fixed by removing learner-facing writer notes, rewriting the ITU phonetics Limit bullet, and keeping the Q-signal caveat as a learner-facing table-limit note. 6 fixed by adding the L-001-04 20 A x 13.8 V = 276 W whole-radio draw example versus the 250 W final-stage DC-input rule, correcting the power-supply-label wording, and adding a simple L-002-03 battery-runtime calculation. 7 fixed by adding illustrative procedure exchanges for repeater entry, simplex operation, and signal reports. 8 fixed by changing the UTC example to UTC minus 5 with recomputed 2100 -> 1600 and 0300 -> 2200 previous local date. 9 fixed by tightening address-change, interval-identification, and QTH/QRM/QRN memory wording. 10 fixed by rewriting the L-001-06 concern sentence, the public-service-net script sentence, and the distress break-in order wording. 11 fixed by tying L-001-06 to hardware details and strengthening L-001-02/L-001-05 real-world hardware context. No review finding was intentionally declined.

Review r1 validation passed: node packages/content-tools/src/check-lesson-coverage.ts; pnpm --dir packages/content-tools check:quizzes; pnpm --dir packages/content-tools check:lesson-originality:all; pnpm --dir packages/content-tools check:explanations; pnpm check:links; TZ=UTC pnpm test; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift. Pinned L-005-01 and L-006-03 expectations were not updated because those lessons/tests were not touched.

Review r2 (APPROVE WITH NOTES): coordinator applied the notes: EIRP spelled as in the bank (equivalent isotropically radiated power, B-001-017-008); full ITU alphabet restored in the l-002-01 memory trick; MAYDAY named in the l-002-03 break-in; unmodulated carrier 'only for brief tests below 30 MHz'; M1 tricks cue 30 (30-day address notice B-001-002-001/-003; 30-minute ID); l-001-04 intro split. Coverage, quizzes, originality :all, explanations and links pass.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Revised task-39.5 after review r1. Fixed every requested-change, note, and minor item: S-unit originality/readability, M1 memory-trick placement, ERP/EIRP definitions and repeater/stability prose, learner-facing writer notes, L-001-04 final-stage power example, M2 sample on-air exchanges, UTC originality, wording slips, and light real-world hardware context. Verified with coverage, quizzes, lesson originality :all, explanations, links, TZ=UTC pnpm test, and content-swift swift test.
<!-- SECTION:FINAL_SUMMARY:END -->
