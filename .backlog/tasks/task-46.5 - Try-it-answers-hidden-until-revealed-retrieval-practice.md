---
id: TASK-46.5
title: Try it answers hidden until revealed (retrieval practice)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:57'
updated_date: '2026-10-21 23:09'
labels:
  - content
  - web
  - apple
dependencies: []
parent_task_id: TASK-46
priority: medium
ordinal: 103000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Today every Try it shows its answer on the same line, so there is no retrieval practice. Add a lesson-format convention for Try it answers and render them hidden behind an accessible Show answer control on web and Apple (iOS, iPadOS, macOS, visionOS; tvOS reveals on focus/select). Convert all existing Try it items.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Answers are hidden by default and revealed by an accessible control (keyboard, VoiceOver, screen readers; the state is announced)
- [ ] #2 All lessons converted; the content checker validates the format
- [ ] #3 Full default accessibility audits pass in light and dark on every platform that renders lessons
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Document paired numbered Try-it prompts and :::answer blocks; migrate all M2–M8 Try-its verbatim, with owner-approved minimal M4 prompt/answer repairs and anchor verification.
2. Validate the convention in the content checker with regressions; parse hidden answer blocks in web and content-swift.
3. Add EN/FR accessible reveal controls on web and all Apple platforms (tvOS focus/select), with unit, axe, and targeted reader tests.
4. Run content/web/package checks; commit before serialized nohup xbuild targeted iPhone/iPad, macOS, tvOS, visionOS checks. Record per-test evidence and changed figure lessons for coordinator, finalize, commit and push without opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
TASK-46.6 re-review follow-up (owner explicitly permits scoped README plus follow-up instead of converting legacy material now): content/lessons/README.md now applies separate feedback headings to new or restructured Try-its. Convert the remaining M3/M4 inline answers as part of this existing task, including l-003-08-access-grounding-lightning-rf-safety.md and l-004-01-amplifiers-and-diodes.md; inspect all eight M3 and three M4 lessons. Preserve prompts and identities while separating answers for the accessible reveal convention. This is already covered by AC #2 (all lessons converted), so no duplicate task was created.

Implemented paired numbered prompt + :::answer / one-line original answer / ::: convention; converted 141 Try-its across all 31 M2–M8 lessons. M1 remains reference-only (no Try-its). Faded-practice Check your work headings and solutions are unchanged. Byte-for-byte comparison to base 78f6f995 verified all 126 non-M4 answers; existing M4 answer prose is retained verbatim with approved prompt/answer repairs. No heading anchor targeted by a hint changed (984 hints checked).
Owner/coordinator approval via intercom: minimally split/reword M4 prompts and add an original answer only where no answer existed; remove redundant standalone feedback-list headings. M4 item review list: L-004-01 #1 asks what the next block does, #2 asks what audio stage helps, #3 asks the diode trade-off, #4 asks what clipped peaks suggest, #5 asks to name rectification; all original answer clauses retained. L-004-02 #1 moves both original sentences into the answer and asks what the emitter arrow identifies; #2 asks which stage/terminal, #3 asks the relay role, #5 asks what to check before substitution; original answers retained. L-004-02 #4 retains the original prompt and adds the only new answer: grid controls tube current; high voltage and stored charge require caution. L-004-03 #1–3 ask to decode the original colours; #4 asks which tolerance has less spread; #5 asks which band to compare; original answer clauses retained.
Removed headings per lesson: Check your thinking in L-002-01, L-002-02, L-002-03, L-002-04; Try-it feedback in L-005-01, L-005-02, L-005-03, L-005-04, L-005-05, L-005-06, L-006-01, L-006-02, L-006-03, L-006-04, L-006-05, L-007-01, L-007-02, L-007-03, L-008-01, L-008-02. Searched web/Apple/content-tools tests and updated the faded-practice test to inspect prompts after removing paired answer blocks. No hint anchors referenced these headings.
Changed figure-directive lessons (coordinator must run CanadianHamLessonFigures; worker will not): L-002-01–04; L-003-01–08; L-004-01–03; L-005-01–06; L-006-01–05; L-007-01–03; L-008-01–02 (all 31 changed lessons). Figure check passes: 39 SVGs, 39 references, assets in sync.
Initial checks: content-tools 244/244; content-swift 26/26 with DEVELOPER_DIR (plain swift test first failed due CLI tools missing XCTest, then corrected a test anchor API call); web focused parser/reveal/EN-FR light-dark axe 38/38, App+Markdown rerun 151/151. A full web run initially had an unrelated French-screen timing failure plus status-role collisions from the first implementation; switched the new announcement to a stable aria-live region, then all affected App tests passed. Typecheck, schema 58/58, import integrity, coverage 100/100, quizzes, all 984 hint anchors, originality all 37 lessons (0 issues/0 stale allowlist entries), figure checks and Apple text-source checker pass. Apple targeted tests and localization export queued next; no full suites.

First iPhone attempt exposed test positioning overhead at largest Dynamic Type: whole-lesson upward scrolling overshot the Try-it, then the existing generic middle-band positioning helper slowly scanned the full lesson accessibility tree. Coordinator approved a DEBUG-only -CanadianHamInitialLessonSectionAnchor beside the existing InitialLessonID seam, mapping to the existing lessonSection route. Release navigation is unchanged. Only the new Try-it reveal tests use the seam; they open the short resistor-colour prompt in L-004-03, explicitly assert the Try-it heading and Show answer control are fully visible before the collapsed audit/tap, and position only the control for the expanded audit. No shared positioning/audit helper was modified or weakened. tvOS buttons now reuse the existing custom secondary focus-ring style; other Apple buttons use large native controls with unrestricted vertical sizing.

Anchor attempt 2: iPhone French labels/state passed (58.323 s); default-light and largest-text-dark audits failed on a fully offscreen preceding faded-practice paragraph, not the reveal controls (black element screenshots saved under /tmp/task-46.5-iphone-attachments). The unchanged lesson exception helper requires scrollFrame.intersects(frame), so it cannot ignore fully offscreen contrast findings. Coordinator declined helper changes without an explicit owner decision. Approved next test positioning: start at check-your-work-compare-matching-digits in L-004-03, audit that preceding solution as well, then scroll down to the fully visible Try-it heading/prompt/control and run collapsed/revealed audits. This adds audit coverage and changes no issue filters. If the next run still fails only on fully offscreen elements, stop and hand the evidence to the coordinator for the owner.
<!-- SECTION:NOTES:END -->
