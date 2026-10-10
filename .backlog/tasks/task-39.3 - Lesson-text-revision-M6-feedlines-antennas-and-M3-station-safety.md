---
id: TASK-39.3
title: 'Lesson text revision: M6 feedlines/antennas and M3 station/safety'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-10 22:15'
updated_date: '2026-10-10 23:04'
labels:
  - content
dependencies:
  - TASK-39.1
parent_task_id: TASK-39
priority: medium
ordinal: 86000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Revise all lessons in m6-feedlines-antennas and m3-station-practice-safety to the teaching guide (practical: coax in homes, wavelength and antenna length worked examples, SWR in plain terms, station grounding/power supply examples).
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
1. Revise M6 lessons first, preserving front matter and Illustration brief blocks while adding practical feedline, SWR, wavelength, antenna-length, tuner, and memory-trick teaching from docs/teaching-guide.md.\n2. Run the required content checks after the M6 slice, fix originality or coverage issues, record per-lesson fact/source notes, and commit the slice.\n3. Revise M3 lessons, preserving metadata and Illustration brief blocks while strengthening station block, power-supply, fusing, battery, grounding/bonding, electrical-code, and Safety Code 6 explanations with practical examples.\n4. Run the full required validation set, update pinned test expectations only if asserted text changed, finalize Backlog acceptance criteria with evidence, and commit the completed task.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
M6 slice revised: L-006-01 adds practical seventy-five-ohm home coax versus fifty-ohm amateur-radio coax and balun/feedpoint clarity (checked B-006-001-006, B-006-002-005, B-006-010-008); L-006-02 adds plain SWR/reflected-power caveat and tuner misconception without unsupported reflected-power fate claims (checked B-006-005-001, B-006-005-009, B-006-006-010); L-006-03 adds VHF wavelength worked example, 100 MHz wavelength memory trick, and practical dipole length example (checked B-006-008-003, B-006-008-011 and guide conventions); L-006-04 adds beam aiming example, Yagi element length and vertical length worked examples, and VHF half-wave convention note (checked B-006-010-001, B-006-010-003, B-006-011); L-006-05 adds support-direction example plus dipole/quad/loop worked examples (checked B-006-012 and B-006-013). M6 checks passed after originality fixes: coverage, quizzes, explanations, lesson originality, links, TZ=UTC pnpm test on rerun, and Swift package tests; first pnpm test attempt had transient web timing failures, rerun passed.

M3 slice revised: L-003-01 adds real-world filter/dummy-load placement; L-003-02 adds chirp-from-power explanation; L-003-03 adds USB/data-interface level example and stored-charge LED caveat; L-003-04 adds waterfall/filter practical example; L-003-05 adds single-change signal-quality troubleshooting; L-003-06 adds headset/fan VOX example; L-003-07 adds 13.8 V x 19 A = 262.2 W station-supply example, P-over-I-E memory trick, source-fuse and fuse-not-shock-protection guidance; L-003-08 adds CSA C22.1 provincial/territorial code wording, fuse-shock misconception, and Safety Code 6 controlled/uncontrolled/no-exempt-transmitter scope. Facts checked against B-003-016, B-003-017, B-003-018, B-003-019, B-003-020, B-003-021 plus Safety Code 6 bank facts B-001-024-002, B-001-024-006, B-001-024-009 and docs/teaching-guide.md electrical-code note.

Final validation: node packages/content-tools/src/check-lesson-coverage.ts passed (100/100 subsections); pnpm --dir packages/content-tools check:quizzes passed (36 quizzes, 504 official references, 78 concept checks); pnpm --dir packages/content-tools check:explanations passed (984 explanations); pnpm --dir packages/content-tools check:lesson-originality:all passed (0 issues); pnpm check:links passed; TZ=UTC pnpm test passed on final rerun (content-tools 108 tests, morse-engine 21 tests, web 152 tests; earlier web runs had transient loading timeouts and were rerun); DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift passed (18 tests). A script confirmed front matter and Illustration brief blocks unchanged for all 13 scoped lesson files relative to merge base. No pinned test expectations were changed because the L-006-03 code-block assertion text remains present.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Revised all M6 feedline/antenna and M3 station/safety lessons for plain-language teaching with practical examples, worked antenna/power calculations, vetted memory tricks, SWR/tuner caveats, station power/fusing/battery guidance, grounding/bonding, Safety Code 6, and provincial/territorial electrical-code wording. Preserved all lesson IDs, front matter coverage/quiz references, and Illustration brief sections; validation passed with coverage, quiz, explanation, originality, links, full pnpm tests, and Swift content package tests.
<!-- SECTION:FINAL_SUMMARY:END -->
