---
id: TASK-39.4
title: 'Lesson text revision: M7 propagation and M8 interference'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 22:15'
updated_date: '2026-10-10 23:17'
labels:
  - content
dependencies:
  - TASK-39.1
parent_task_id: TASK-39
priority: medium
ordinal: 87000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Revise all lessons in m7-propagation and m8-interference-suppression to the teaching guide (practical: why AM broadcast carries further at night, FM range, everyday interference from chargers/LED bulbs, ferrite chokes on cables).
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
1. Apply every r1 review note in L-007-01, L-007-02, L-007-03, L-008-01, and L-008-02 while preserving front matter and Illustration brief sections exactly.
2. Run focused content checks/originality after the text edits, fix any issues, and commit the lesson fixes.
3. Rerun the complete original required check set: coverage, quizzes, originality all, explanations, check:links, TZ=UTC pnpm test, and content-swift swift test with DEVELOPER_DIR.
4. Record finding-by-finding notes and validation evidence in Backlog, refresh the final summary, and set Done as the last change.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
M7 revision complete. L-007-01: tightened path/layer prose, added valley/ridge/town real-world example, D/E/F order and D daytime damping memory tricks, and skip-zone power misconception; facts checked against B-007-001/002/003 including radio horizon, D/E/F order, midday/minimum ionization, skip geometry, 2 000 km E and 4 000 km F2 planning scales. L-007-02: added AM broadcast nighttime example, fading misconception, OWF worked calculation (18.6 MHz x 0.85 = 15.8 MHz), and clearer MUF/LUF guidance; facts checked against B-007-004/005/006 including D-region absorption, AM/daytime absorption, 11-year solar cycle, 20 m daylight usefulness, SID higher-frequency response, and OWF below MUF. L-007-03: added radio-horizon worked estimate (1.8 m handheld plus 100 m repeater gives 46.7 km), FM/VHF range teaching, and VHF-power misconception; facts checked against B-007-007/008 including sporadic E, 800 km normal VHF planning scale, aurora/CW, meteor scatter 30-100 MHz, and scatter clues. Required post-M7 checks passed: coverage, quizzes, explanations, lesson originality, links, TZ=UTC pnpm test, and content-swift swift test.

M8 revision complete. L-008-01: tightened overload/audio-rectification/spurious-emission prose, added charger/LED/computer/solar-inverter real-world source examples, powered-speaker example, ferrite common-mode caveat, and speaker-complaint misconception; facts checked against B-008-001/002/003 plus ferrite reactance/ferrite-core cures in B-005-010-007 and B-008-002-001. L-008-02: added 60 Hz hum vs RF harmonics distinction with recomputed 1/60 s = 0.0167 s = 16.7 ms, pass-name memory trick, LED-lamp and solar-inverter examples, and filter-placement emphasis; facts checked against B-008-004/005 plus low-pass placement concepts from B-003-001-001/B-003-001-002 and 60 Hz meaning from B-005-007-008. Required post-M8 checks passed after rerunning a transient web timeout: coverage, quizzes, explanations, lesson originality, links, TZ=UTC pnpm test, and content-swift swift test. Protected front matter and Illustration brief sections verified unchanged against main for all five lesson files.

Review r1 follow-up started: fixing every r1 note from ~/.cache/canadian-ham-reviews/t39-4-r1.md, then rerunning all original required checks and setting Done last.

Review r1 fixes recorded finding by finding. 1 fixed: L-007-02 now defines Faraday rotation as polarization twist through an ionized region and says reflection can change arriving polarization. 2 fixed: L-008-01 now defines common-mode current before lesson-body use and restores ferrite mechanism as high RF impedance / inductive reactance to common-mode current. 3 fixed: L-007-02 160/80 m summer daylight sentence now says long daylight and stronger D-region absorption reduce sky-wave usefulness. 4 fixed: L-007-03 now explains why 30-100 MHz suits meteor scatter in original words. 5 fixed: L-007-01 restored single-hop qualifier for E/F2 hop scales and summary. 6 fixed: L-007-01 now adds a new practical path-before-power example; prior notes overstated the valley/ridge/town example as added when it was a rewritten/renamed existing worked example. 7 fixed: L-008-02 LED-lamp example now says an AC line filter is low-pass in this job and names source/load placement. 8 fixed: L-008-02 hum misconception wording was revised to avoid close paraphrase while keeping the required 60 Hz distinction. 9 fixed: L-007-03 now explains auroral CW readability as narrow, simple on-off tone. 10 fixed: L-007-01 now uses ionized region / charged particles instead of loose charged-region wording. 11 fixed: L-007-03 radio-horizon worked example now separates Formula from Substitute. 12 fixed: restored quotation marks around "usually" and "skip" where review flagged awkward reading. 13 fixed: L-008-02 adds a switching-supply harmonic example: 70 x 100 kHz = 7 000 kHz = 7.0 MHz. 14 fixed in notes: dropped/reframed items are now recorded here: the 104.3/18.1 MHz intermod example and 3.2 MHz plus 9.2/18.4 MHz harmonic examples stayed dropped to keep lessons shorter; Faraday rotation, meteor-scatter reasoning, and shorter-lead pickup reasoning were restored in revised form.

Review r1 validation passed after fixes: git diff --check; node packages/content-tools/src/check-lesson-coverage.ts; pnpm --dir packages/content-tools check:quizzes; pnpm --dir packages/content-tools check:lesson-originality:all; pnpm --dir packages/content-tools check:explanations; pnpm check:links; TZ=UTC pnpm test; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift. Protected front matter and Illustration brief sections reverified unchanged against main for all five lesson files. No L-005-01 or L-006-03 pinned expectations changed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Review r1 follow-up complete. Fixed every APPROVE WITH NOTES item across L-007-01, L-007-02, L-007-03, L-008-01, and L-008-02: restored Faraday/polarization explanation, ferrite high-impedance/common-mode mechanism, 160/80 m cause, meteor-scatter reasoning, single-hop qualifiers, quote/readability fixes, AC line filter placement, auroral CW reasoning, and a switching-supply harmonic example. Front matter and Illustration brief sections remain unchanged. Verified with all original required checks plus protected-section comparison; no pinned expectations changed.
<!-- SECTION:FINAL_SUMMARY:END -->
