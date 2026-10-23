---
id: TASK-46.5
title: Try it answers hidden until revealed (retrieval practice)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:57'
updated_date: '2026-10-23 12:01'
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
- [x] #1 Answers are hidden by default and revealed by an accessible control (keyboard, VoiceOver, screen readers; the state is announced)
- [x] #2 All lessons converted; the content checker validates the format
- [ ] #3 Full default accessibility audits pass in light and dark on every platform that renders lessons
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Document paired numbered Try-it prompts and :::answer blocks; migrate all M2–M8 Try-its verbatim, with owner-approved minimal M4 prompt/answer repairs and anchor verification.
2. Validate the convention in the content checker with regressions; parse hidden answer blocks in web and content-swift.
3. Add EN/FR accessible reveal controls on web and all Apple platforms (tvOS focus/select), with unit, axe, and targeted reader tests.
4. Run content/web/package checks; commit before serialized nohup xbuild targeted iPhone/iPad, macOS, tvOS, visionOS checks. Record per-test evidence and changed figure lessons for coordinator, finalize, commit and push without opening a PR.

5. Resume 2026-10-23: merge and push origin/main (TASK-70 aligned helper), rerun only unchanged failing iPhone/iPad Try-it light/dark audits via nohup. If a fully visible lone bullet remains, export and inspect its screenshot before applying only the authorized local contrast label-exact/cap-1 exception and dated AGENTS entry. Stop for any other failure. Refresh only stale figure-free checks; record per-test evidence, finish AC3 and task, push without a PR; coordinator runs figure plan.

6. Coordinator-approved 2026-10-23 after the unchanged post-TASK-70 dark test passed its preceding-section audit but failed recovery positioning: open the new Try-it tests directly at the Try-it anchor again; remove only the preceding-section workaround audit; explicitly require prompt plus Show answer fully visible below the navigation bar. Preserve remaining assertions, full audits and aligned shared helpers. Rerun iPhone then iPad light/dark.

7. Coordinator-approved 2026-10-23 after direct L-004-03 full audit flagged fully visible nonbullet worked-example text: retarget only the new Try-it full-audit tests to shortest authored Try-it lesson by Markdown-body character count, preserving direct anchor, full audits, prompt/control visibility assertions and unchanged aligned helper; retain existing long L-004-03 French reveal/state test without audit. Record both L-004-03 false positives in TASK-65 and stop on fully visible nonbullet findings in shortest-lesson audits.
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

AC #2 verified: all 141 Try-its in all 31 M2–M8 lessons use paired hidden-answer blocks; M1 has none by policy. Coverage checker now rejects legacy inline/missing/empty/malformed/unpaired answers; content-tools 244 tests, 100/100 coverage, schema 58 tests, all 984 hint anchors and originality-all checks pass. Remaining ACs await targeted Apple audit evidence.

Remaining independent checks: localization export/generic tvOS+visionOS builds passed without changing the xcstrings catalogue; text-source gate passed. macOS LocalizationCatalogTests: 6/6 passed, including testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench (0.001 s). tvOS testLessonTryItRevealsOnRemoteFocusAndSelectWithAccessibilityLightAndDark passed (77.169 s; full audits both appearances). visionOS testLessonTryItDisclosureAndAccessibilityLightAndDark passed (86.354 s; full collapsed/expanded audits both appearances). MAIN inspected in a detached /tmp worktree at 78f6f995 and removed: no existing targeted test reaches the L-004-03 faded-practice/Try-it position; only its figure at line53 has an existing audit. No main reproduction claim and no figure audit run. Inspection report: /tmp/task-46.5-main-baseline-inspection.txt.
First iPad run: dark preceding-solution audit passed, but the audit itself scrolled the lesson away; bounded 80-point-only positioning could not recover Try-it within 24 steps (test failed at 176.358 s). Fixed only the new local test helper to use direction-aware coarse swipes when far from the target, then precise alignment; all visibility assertions and shared helpers unchanged. Light failed its preceding-solution full contrast audit (92.524 s). Queueing only the failed dark navigation test plus the existing pure French reveal/state test on iPad, while the final iPhone French test runs.

Final targeted Apple results (no full suites): iPhone testLessonTryItRevealFrenchLabelsAndState PASS 120.485 s on current test positioning; iPad same pure reveal/FR label/state test PASS 62.234 s. Both verify default hidden state, reveal, and native accessibility values. macOS LocalizationCatalogTests 6/6 PASS (new Try-it localization test 0.001 s). tvOS testLessonTryItRevealsOnRemoteFocusAndSelectWithAccessibilityLightAndDark PASS 77.169 s; visionOS testLessonTryItDisclosureAndAccessibilityLightAndDark PASS 86.354 s; both include full default audits in light and dark. pnpm check:apple-l10n and text sources PASS, xcstrings unchanged after export (Python round-trip preserved the original catalogue formatting; 7 new EN/FR/fr-CA entries).
AC #3 BLOCKED: iPhone light audit FAIL 189.631 s (standalone bullet in unchanged faded-practice list), dark FAIL 129.939 s (fully offscreen Fill the gaps before checking below; black element screenshot). These are the approved preceding-solution-start attempts; first Try-it-anchor attempts also failed on fully offscreen preceding solution text. iPad light FAIL 92.524 s (standalone bullet); final dark retry FAIL 78.247 s (offscreen lesson-heading-memory-trick-colour-order). An earlier iPad dark attempt first passed its preceding-solution audit but then lost position after audit-driven scrolling; the new local positioning helper was fixed with direction-aware coarse swipes plus precise alignment. No shared audit/positioning helper or issue filter was edited, and no audit was narrowed/skipped.
Evidence: /tmp/task-46.5-iphone.log and /tmp/task-46.5-preceding-solution-attachments (latest iPhone full-audit failures); /tmp/task-46.5-ipad.log and /tmp/task-46.5-ipad-attachments (first iPad/light failure); /tmp/task-46.5-ipad-retry.log and /tmp/task-46.5-ipad-retry-attachments (final dark failure plus French pass); /tmp/task-46.5-apple-remaining.log (all independent check outcomes); /tmp/task-46.5-iphone-french.log, /tmp/task-46.5-mac.log, /tmp/task-46.5-tv.log, /tmp/task-46.5-vision.log, /tmp/task-46.5-l10n.log. Per-test xcresult paths are recorded in those logs and /tmp/task-46.5-*-xcresult-path.txt. MAIN reproduction is NOT established: no existing test reaches this same lesson position; read-only detached-worktree inspection report retained.
Coordinator explicitly directs leaving this task In Progress for owner review of the fully offscreen-helper/contrast issue. ACs #1 and #2 are verified; #3 remains unchecked. Coordinator must still run the figure plan for all 31 changed figure lessons, as listed above. The existing helper is unchanged and still fails nil-element, fully-visible contrast, navigation-bar and all non-contrast findings. No PR was opened. No background validation job remains. Final web production build and URL/CSP audit rechecked successfully.

Resume 2026-10-23: merged origin/main (TASK-70 helper alignment, merge 1bbdab61) and pushed. Unchanged iPhone dark preceding-section full audit passed its offscreen finding through the aligned helper, then failed Try-it heading positioning at y=24119.94 after 533.000 s; stopped for coordinator decision. Coordinator explicitly authorized returning to the direct Try-it anchor and removing only the preceding-section audit detour added for the pre-TASK-70 helper. No shared helper/filter changes authorized. Merged typecheck passes; web run had 257/259 passing with known unrelated loading-state/v6 migration timeouts; coordinator permits one unchanged targeted retry after Apple run finishes.

Direct L-004-03 iPhone light collapsed audit failed on fully visible 'Answer: value = 4 700 ohms.' (332.957 s) after initial Try-it prompt/control visibility passed. No exception added; script stopped before dark/iPad. Both direct and preceding-detour false positives exported and recorded in TASK-65. Coordinator authorized shortest-lesson retargeting with identical audit/visibility requirements, not an issue filter change. Measured all 31 Try-it lessons by Markdown body character count (front matter excluded): L-005-04 AC and decibels shortest at 8,985 characters, Try-it starts at 6,951 (L-004-03:13,735/10,731); full table /tmp/task-46.5-try-it-lesson-lengths.tsv. Existing testLessonTryItRevealFrenchLabelsAndState stays on long L-004-03, with no audit. No shared helpers changed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented 141 paired hidden Try-it answers across all 31 M2–M8 lessons, with content validation and accessible localized web/Apple reveal controls; M1 remains reference-only. Web, content tools, Swift content, schema/import/hint/originality checks pass. Native reveal/state tests pass on iPhone/iPad, tvOS and visionOS full light/dark audits pass, macOS localization units and localization export pass. Completion is blocked only on AC #3: iPhone/iPad full lesson audits fail on unrelated preceding lesson text/bullet findings; shared helpers and filters remain unchanged. Task remains In Progress pending owner decision and reviewer follow-up; coordinator figure plan is still required.
<!-- SECTION:FINAL_SUMMARY:END -->
