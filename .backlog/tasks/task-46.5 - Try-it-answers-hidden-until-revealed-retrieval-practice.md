---
id: TASK-46.5
title: Try it answers hidden until revealed (retrieval practice)
status: Done
assignee:
  - '@worker'
created_date: '2026-10-12 14:57'
updated_date: '2026-10-23 23:50'
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
- [x] #3 Full default accessibility audits pass in light and dark on every platform that renders lessons
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

8. Resume with merged TASK-71: coordinator-approved local auditIgnoringOccludedOrMeasuredContrast helper composes verbatim approved occlusion guards/logging with shared measured-contrast predicates (>=4.5, keepAlways success/failure logging). Only new Try-it audits change. Preserve shortest L-005-04 direct anchor and visibility assertions; run only Try-it light/dark/French on iPhone and iPad using serial nohup xbuild, then l10n/text/test guard (owner decision 2026-10-22). Stop/report any other failure. Record ratios/per-test evidence; finalize AC3/Done only on green, push without PR; coordinator owns 31-lesson figure plan.

9. Coordinator-approved after iPhone dark failed the unchanged prompt visibility assertion before auditing (111.527s): add only a new Try-it-local bounded positioning pass (max10 precise small scrolls in either direction), then keep identical visibility assertions and log frames on exhaustion. Wait for TASK-72 merge; merge main and use contrastMeasurementCGImage(from:) in local composed helper; rerun dark first then iPhone light/French, all iPad tests and l10n.

10. Coordinator-approved after the bounded10-pass dark retry left Show answer2pt below visible area: retain union-based overshoot targeting with8pt margin and <=80pt precise scrolls; allow12 passes; explicitly log/return if prompt/control union is taller than visible area. Keep unchanged containment assertions and exhaustion logging; rerun dark-first then rest.

11. Coordinator-approved after12-pass dark positioning stalled with identical2pt residual clipping: only the new Try-it positioning helper now requests at least24pt whenever vertical overshoot remains, still clamped by unchanged preciseScroll to80pt and bounded to12 passes. Keep all containment assertions, union-height stop and exhaustion logs. Rerun dark then remaining iPhone/iPad and l10n checks.

12. Coordinator-approved after iPad light failed only an unmeasurable fully visible high-contrast paragraph: leave shared/local measurement logic unchanged and AC3 unchecked; run independent iPad dark/French plus l10n/text/guard. Record all findings/screenshots and push paused handoff. Coordinator owns separate TASK-71 measurement follow-up; await explicit merge-main/iPad-only rerun instruction after it lands.

13. Coordinator-approved TASK-73 rounded-button resume: merge/push origin/main, preserve both AGENTS exceptions, and update only the local composite measured branch to the shared measuredControlTextContrast path with element-type gate and full-image/crop/inset logging; preserve verbatim occlusion branch. Serial nohup xbuild: iPhone light twice, dark/French once; iPad light/dark/French once (approved light no-audit path); documented macOS units, l10n, text sources, dated-marker guard. Stop on any failure; only if all green, record per-test ratios, check AC3/Done, push; no PR; coordinator owns 31-lesson figure plan.

Review-fix round (2026-10-23): restore TASK-65 cross-lane notes via CLI; correct audit exception record/date; make tvOS Try-it prompt/answer independently focusable and assert reachability; recast three M4 checks as transfer prompts and capitalize answer starts; add real-lesson web parsing regression; run requested targeted checks serially through xbuild (nohup/poll), record evidence and push without PR.
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

PAUSED by coordinator 2026-10-23 after shortest-lesson retarget: iPhone testLessonTryItRevealAndAccessibilityLight on L-005-04 FAIL 156.348 s, full collapsed-state audit on fully visible nonbullet 'Try these before reading the feedback below.' Initial Try-it heading, prompt and Show answer visibility assertions all passed. Element screenshot shows high-contrast dark ink on paper; app screenshot confirms paragraph/prompt/buttons fully visible. Log /tmp/task-46.5-short-iphone-light.log; xcresult path /tmp/task-46.5-short-iphone-light-xcresult-path.txt; exported element /tmp/task-46.5-short-iphone-light-attachments/BBEAFF9A-A75C-44FD-AFEF-AF3DF818B0E0.png; app /tmp/task-46.5-short-iphone-light-attachments/2D4A4655-2EE1-466D-B30D-D958EFFABA12.png; manifest/results JSON retained. Nohup script stopped before dark, long-French rerun, and iPad. No background validation remains; no build/process was signalled. AC3 remains unchecked and task In Progress. Coordinator suspects simulator/environment or main because both lanes report fully visible high-contrast false positives; TASK-46.6.1 lane is running the main control. Wait for coordinator before resuming. No exception, AGENTS amendment, shared helper change, audit narrowing, skip, or production change added in this resume.

Resume checks/evidence: origin/main merged/pushed (merge1bbdab61); coordinator-approved direct-anchor change55ad569a and shortest-lesson retarget aabd495256d4f6ed16ba2199a10a83c17e33a9b9 committed/pushed. Shared aligned auditIgnoringOccludedLessonTextContrast verified byte-identical to origin/main. Merged pnpm typecheck PASS; pnpm test: content-tools244/244, Morse21/21, calculator127/127; web257/259 initially passed, two known unrelated timeout failures both passed unchanged targeted retry (2/2, 152 unselected tests) after Apple run. Coordinator explicitly approved that one retry. pnpm build:web, production URL/CSP audit, schemas58/58, imports including reference sheet, and Apple text-source checks PASS. Logs /tmp/task-46.5-merged-*.log and /tmp/task-46.5-merged-web-targeted-retry.log. Apple localization export was not refreshed after merge because native audit blocker paused the lane; prior export/mac/tvOS/visionOS and long French reveal results remain in earlier notes. No full suites or figure plan run. All31 changed figure-directive lesson paths reconfirmed in /tmp/task-46.5-changed-figure-lessons.txt; coordinator owns figure plan. Updated handoff is /tmp/task-46.5-handoff.md. No PR opened.

TASK-71 resume: merged/pushed main d05ff6e8; local approved composed audit helper committed0911ea50; all198 pre-branch tests/helpers and shared measurement source byte-identical to origin/main. Text-source and guard self-test/diff with Test-guard-approved: owner decision2026-10-22 PASS. iPhone light full collapsed/expanded audit PASS173.535s; one measured finding label=The report is about S9 plus16dB... ratio16.336427704401043:1 (keepAlways attachment A1CF397D-DB56-41E3-B363-DA735007AEDC.txt under /tmp/task-46.5-measured-iphone-light-attachments). iPhone dark FAIL111.527s before audit: unchanged prompt-fully-visible assertion line2414. Script STOPPED as requested; French/iPad/l10n not run; no processes signalled. Coordinator authorized bounded local positioning fix and TASK-72 platform-image bridge merge before resuming dark-first. AC3 remains unchecked.

TASK-72 merged/pushed (d71b76b0); local composite uses contrastMeasurementCGImage(from:). Dark retry FAIL201.431s before audit: prompt y195.259 height497.333 fully visible, control y704.667 height155.333 ends860 vs visible maxY858. Bounded10-pass positioning exhausted; unchanged control visibility assertion correctly failed. No contrast findings suppressed or tests skipped; script stopped before all remaining tests/l10n. Evidence /tmp/task-46.5-measured-v2-iphone-dark.log, -results.json, -xcresult-path.txt, -attachments/8B11344A-FF0D-438F-941B-FD75A1B520D4.txt (geometry). Coordinator approved union-targeted12-pass refinement with unchanged assertions.

v3 dark FAIL253.514s before audit after roughly69min waiting on shared xbuild lock (never interrupted):12 union-targeted passes ended at exactly the same2pt-clipped control geometry as v2. Repeated residual10pt drags (2pt overshoot+8pt margin) did not move content, consistent with pan-recognition threshold. Evidence /tmp/task-46.5-measured-v3-iphone-dark.log, -results.json, -xcresult-path.txt and -attachments (geometry + video). Script stopped; remaining tests/l10n not started. Coordinator explicitly approved a new-test-local minimum24pt drag when overshoot remains; shared preciseScroll and all assertions unchanged. AC3 remains unchecked pending actual audits.

Final v4 iPhone17Pro PASS: light174.198s; dark235.735s (largest Dynamic Type); French183.936s. Dark accepted3 findings by existing occluded-content rule only (S-meter learning outcome twice at negative y; frequency paragraph extends below visible scroll area); no measured findings. Light verified one finding at16.336427704401043:1 (The report is about S9 plus16dB...); keepAlways note3DB439B1-F27E-406F-BD74-216E7D32EF10.txt. iPad13-inchM5 light FAIL137.543s in expanded full audit: fully visible Given: initial report = S9 plus19dB; transmitter power falls from48W to24W. frame(92,259.09444444444443,597.5,20.5), ratio=unmeasurable; correctly NOT ignored. Five other iPad findings verified16.336427704401043:1 (four bullets plus Sanity check: Is the report lower while still above S9?). Full bundle /tmp/task-46.5-measured-v4-ipad-light.xcresult; all exported attachments/measurement notes under corresponding-attachments directory; summary /tmp/task-46.5-measured-results-summary.json. Serial script stopped; coordinator now authorizes independent dark/French/l10n checks only, with no measurement edits and AC3 unchecked pending separate follow-up. Later builds pruned original dark DerivedData bundle; its already-exported keepAlways attachments, console per-test result and summary remain; remaining bundles now preserved under/tmp immediately.

Final measured-contrast resume handoff2026-10-23 (coordinator explicitly directs keeping AC3 unchecked/In Progress pending separate measurement follow-up):
Merged/pushed main through80ca2871 (TASK-71 and TASK-72). Only new Try-it audit calls use local auditIgnoringOccludedOrMeasuredContrast; exact approved occlusion guards/logging OR shared measuredTextContrast/isFullyVisibleForContrastMeasurement with >=4.5 and keepAlways success/failure logging. Uses contrastMeasurementCGImage(from:). All198 pre-branch test/helper functions and shared measurement file are byte-identical to origin/main80ca2871. Preserved shortest L-005-04 direct anchor, long L-004-03 French test, all existing visibility/state assertions and full collapsed/expanded audits. Coordinator-approved new-test-only positioning uses prompt/control union, <=80pt corrections with24pt minimum, <=12 passes, union-too-tall stop and exhaustion geometry; shared preciseScroll unchanged.
Latest per-test results (only-testing; no full suites):
- measured-v4-iphone-dark: -[CanadianHamUITests.CanadianHamPracticeUITests testLessonTryItRevealAndAccessibilityDark] PASSED 235.735s.
- measured-v4-iphone-light: -[CanadianHamUITests.CanadianHamPracticeUITests testLessonTryItRevealAndAccessibilityLight] PASSED 174.198s.
- measured-v4-iphone-french: -[CanadianHamUITests.CanadianHamPracticeUITests testLessonTryItRevealFrenchLabelsAndState] PASSED 183.936s.
- measured-v4-ipad-light: -[CanadianHamUITests.CanadianHamPracticeUITests testLessonTryItRevealAndAccessibilityLight] FAILED 137.543s.
- measured-v5-ipad-dark: -[CanadianHamUITests.CanadianHamPracticeUITests testLessonTryItRevealAndAccessibilityDark] PASSED 100.477s.
- measured-v5-ipad-french: -[CanadianHamUITests.CanadianHamPracticeUITests testLessonTryItRevealFrenchLabelsAndState] PASSED 69.815s.
Logged measured findings (all notes are keepAlways; no label exception):
- measured-v4-iphone-light: label=The report is about S9 plus 16 dB. This compares received levels; it is not a change in the report's readability part. frame=(40.0, 241.59259259259306, 299.0, 64.33333333333303) ratio=16.336427704401043:1 attachment=/tmp/task-46.5-measured-v4-iphone-light-attachments/3DB439B1-F27E-406F-BD74-216E7D32EF10.txt
- measured-v4-ipad-light: label=• frame=(76.0, 259.09444444444443, 8.0, 20.5) ratio=16.336427704401043:1 attachment=/tmp/task-46.5-measured-v4-ipad-light-attachments/06CD6317-3C65-4085-B004-F5328E4598F1.txt
- measured-v4-ipad-light: label=• frame=(76.0, 402.09444444444443, 8.0, 20.5) ratio=16.336427704401043:1 attachment=/tmp/task-46.5-measured-v4-ipad-light-attachments/32FB062D-16E9-416F-9934-F60ABA9A12FC.txt
- measured-v4-ipad-light: label=• frame=(76.0, 373.59444444444443, 8.0, 20.5) ratio=16.336427704401043:1 attachment=/tmp/task-46.5-measured-v4-ipad-light-attachments/435CDCE4-80A2-4EA0-A314-CC56E0C086B3.txt
- measured-v4-ipad-light: label=• frame=(76.0, 345.09444444444443, 8.0, 20.5) ratio=16.336427704401043:1 attachment=/tmp/task-46.5-measured-v4-ipad-light-attachments/D4F10A9A-FEF0-4AB2-B7BF-B2B063F1D994.txt
- measured-v4-ipad-light: label=Given: initial report = S9 plus 19 dB; transmitter power falls from 48 W to 24 W. frame=(92.0, 259.09444444444443, 597.5, 20.5) ratio=unmeasurable attachment=/tmp/task-46.5-measured-v4-ipad-light-attachments/E3F8D148-A06D-4579-AA22-C7977A84BFB3.txt
- measured-v4-ipad-light: label=Sanity check: Is the report lower while still above S9? frame=(92.0, 402.09444444444443, 401.5, 20.5) ratio=16.336427704401043:1 attachment=/tmp/task-46.5-measured-v4-ipad-light-attachments/FC3470CB-E2B9-462C-A4DC-790EAB96F29D.txt
Logged approved occlusion findings (ratio N/A: accepted by verbatim original occluded-content rule, not the measurement rule):
- measured-v4-iphone-dark: label=adjust an S-meter reading that is stated in decibels above S9. frame=x: 71.66666666666666, y: -88.25925925926458, width: 279.0, height: 373.33333333333303 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true attachment=/tmp/task-46.5-measured-v4-iphone-dark-attachments/240020CC-9300-4D8D-9096-FB72E37E3472.txt
- measured-v4-iphone-dark: label=adjust an S-meter reading that is stated in decibels above S9. frame=x: 71.66666666666666, y: -136.25925925926458, width: 279.0, height: 373.33333333333303 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true attachment=/tmp/task-46.5-measured-v4-iphone-dark-attachments/FAE60F5B-3BD0-41B2-AF4C-D6F5CE65065F.txt
- measured-v4-iphone-dark: label=Frequency is the number of complete cycles per second. The unit is hertz. A 400 Hz tone completes 400 cycles each second. frame=x: 40.0, y: 376.07407407406936, width: 322.33333333333326, height: 621.333333333333 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true attachment=/tmp/task-46.5-measured-v4-iphone-dark-attachments/FCCF9840-209C-4E47-B11F-C6F8722FA6EB.txt
- measured-v5-ipad-dark: label=The report is about S9 plus 16 dB. This compares received levels; it is not a change in the report's readability part. frame=x: 76.0, y: 11498.094444444443, width: 871.5, height: 187.5 visibleScrollArea=x: 0.0, y: 86.0, width: 1032.0, height: 1290.0 scrollFrame=x: 0.0, y: 0.0, width: 1032.0, height: 1376.0 matchedScrollDescendant=true attachment=/tmp/task-46.5-measured-v5-ipad-dark-attachments/6813DA27-1E75-48DA-8911-67A114F9D062.txt
BLOCKER: only iPad light failed: expanded full audit could not measure fully visible Given paragraph; correctly failed closed, not ignored. Element screenshot /tmp/task-46.5-measured-v4-ipad-light-attachments/F46D182E-2E71-4C4E-B108-103DFEA2C2E3.png (inspected: dark ink on light paper); app screenshot FC1DB962-2B0E-4AB7-8835-2FAA62B40437.png in same directory. Full bundle /tmp/task-46.5-measured-v4-ipad-light.xcresult. Coordinator owns separate TASK-71 follow-up; do not change helper, check AC3, set Done, or rerun green iPhone tests without direction. Once follow-up merges, coordinator will authorize merge-main and iPad-only rerun.
Independent checks PASS: pnpm check:apple-l10n (French export + generic tvOS/visionOS builds; catalogue byte-unchanged), node scripts/check-apple-text-sources.ts, node scripts/check-test-guard.mjs --self-test, TEST_GUARD_PR_BODY="Test-guard-approved: owner decision 2026-10-22" node scripts/check-test-guard.mjs --base origin/main --head HEAD; git diff --check; source scope proof above. Logs /tmp/task-46.5-measured-v5-{l10n,text-sources,test-guard-self,test-guard}.log. Existing unrelated plural-substitution warnings remain warnings; exit0. No source fix, test narrowing, skip, or hidden accessibility element added.
Evidence: per-test console logs /tmp/task-46.5-measured-v4-{iphone-dark,iphone-light,iphone-french,ipad-light}.log and /tmp/task-46.5-measured-v5-ipad-{dark,french}.log. Exact nohup commands in /tmp/task-46.5-measured-v4-audits.sh, /tmp/task-46.5-measured-v5-ipad-dark.sh, /tmp/task-46.5-measured-v5-remaining.sh. Summary /tmp/task-46.5-measured-results-summary.json and /tmp/task-46.5-measured-final-evidence.txt; all keepAlways attachments exported to corresponding -attachments directories. Later builds pruned the original dark DerivedData xcresult, but its already-exported attachments, console per-test result and summary remain. All other final bundles are preserved under /tmp/task-46.5-measured-v4-{iphone-light,iphone-french,ipad-light}.xcresult and /tmp/task-46.5-measured-v5-ipad-{dark,french}.xcresult. Earlier failed positioning attempts and approvals remain in prior notes. No background validation job remains; no build/process was signalled; xbuild lock waits included roughly69min for one attempt.
No PR. Prior macOS localization, tvOS/visionOS light/dark audits and web/content/package results remain as recorded; not rerun for this iOS-test-only resume. Coordinator still owns CanadianHamLessonFigures and merge-batch full-platform suites; worker did not run either. All31 changed figure-directive lesson paths (README example excluded):
- content/lessons/m2-operating-procedures/l-002-01-voice-repeater-and-simplex-procedure.md
- content/lessons/m2-operating-procedures/l-002-02-morse-rst-and-q-signals.md
- content/lessons/m2-operating-procedures/l-002-03-distress-urgency-and-safety-traffic.md
- content/lessons/m2-operating-procedures/l-002-04-records-maps-and-locators.md
- content/lessons/m3-station-practice-safety/l-003-01-station-filtering-and-radio-blocks.md
- content/lessons/m3-station-practice-safety/l-003-02-cw-ssb-blocks-and-receivers.md
- content/lessons/m3-station-practice-safety/l-003-03-digital-interfaces-and-power-supplies.md
- content/lessons/m3-station-practice-safety/l-003-04-antennas-and-receiver-specs.md
- content/lessons/m3-station-practice-safety/l-003-05-signal-quality-cw-ssb-fm.md
- content/lessons/m3-station-practice-safety/l-003-06-controls-digital-voice-and-packet.md
- content/lessons/m3-station-practice-safety/l-003-07-batteries-dc-supplies-and-ripple.md
- content/lessons/m3-station-practice-safety/l-003-08-access-grounding-lightning-rf-safety.md
- content/lessons/m4-circuit-components/l-004-01-amplifiers-and-diodes.md
- content/lessons/m4-circuit-components/l-004-02-transistors-fets-and-tubes.md
- content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md
- content/lessons/m5-basic-electronics/l-005-01-units-conductors-current.md
- content/lessons/m5-basic-electronics/l-005-02-power-ohms-law.md
- content/lessons/m5-basic-electronics/l-005-03-parallel-circuits-and-ratings.md
- content/lessons/m5-basic-electronics/l-005-04-ac-and-decibels.md
- content/lessons/m5-basic-electronics/l-005-05-reactance-and-resonance.md
- content/lessons/m5-basic-electronics/l-005-06-transformers-and-meters.md
- content/lessons/m6-feedlines-antennas/l-006-01-feedline-basics-and-types.md
- content/lessons/m6-feedlines-antennas/l-006-02-loss-swr-and-matching.md
- content/lessons/m6-feedlines-antennas/l-006-03-polarization-dipoles-wavelength.md
- content/lessons/m6-feedlines-antennas/l-006-04-directivity-yagis-and-lengths.md
- content/lessons/m6-feedlines-antennas/l-006-05-loops-quads-and-patterns.md
- content/lessons/m7-propagation/l-007-01-paths-ionosphere-and-skip.md
- content/lessons/m7-propagation/l-007-02-absorption-solar-cycle-and-muf.md
- content/lessons/m7-propagation/l-007-03-vhf-uhf-and-unusual-modes.md
- content/lessons/m8-interference-suppression/l-008-01-receiver-device-interference-and-filters.md
- content/lessons/m8-interference-suppression/l-008-02-transmitter-emissions-and-harmonics.md

TASK-73 rounded-control resume FINAL GREEN (2026-10-23; supersedes prior paused/blocked handoffs):
Merged/pushed origin/main1a183cfa (#1012) via ddb4030c; preserved both TASK-71/TASK-73 rounded-control guidance and the approved TASK-46.5 iPad light limitation in AGENTS. Preserved both independently added localization test methods; Backlog-only TASK-65 conflict kept branch version under repository merge policy. Local composite helper change5910491d uses exactly the same controlTextContrastMeasurement, native scale, elementType==.button gate and measurement.logDescription as auditVerifyingMeasuredContrast. Local occlusion branch is a verbatim shared-helper copy; all198 pre-branch Practice test/helper functions and shared measurement source are byte-identical to origin/main1a183cfa (scope proof /tmp/task-46.5-rounded-v1-source-scope.log). No production or shared-helper edits in this resume.
All requested serial nohup xbuild commands passed, including two independent iPhone light runs. Exact commands: /tmp/task-46.5-rounded-v1-validation.sh; status /tmp/task-46.5-rounded-v1-status.log ends FINAL_EXIT=0. All UI result bundles preserved in /tmp and attachments exported to matching -attachments directories. No build/process was killed; ordinary lock waits respected. Per-test results:
- iphone-light-1: CanadianHamUITests.CanadianHamPracticeUITests testLessonTryItRevealAndAccessibilityLight PASS 260.205s; log /tmp/task-46.5-rounded-v1-iphone-light-1.log; bundle /tmp/task-46.5-rounded-v1-iphone-light-1.xcresult
- iphone-light-2: CanadianHamUITests.CanadianHamPracticeUITests testLessonTryItRevealAndAccessibilityLight PASS 260.877s; log /tmp/task-46.5-rounded-v1-iphone-light-2.log; bundle /tmp/task-46.5-rounded-v1-iphone-light-2.xcresult
- iphone-dark: CanadianHamUITests.CanadianHamPracticeUITests testLessonTryItRevealAndAccessibilityDark PASS 239.976s; log /tmp/task-46.5-rounded-v1-iphone-dark.log; bundle /tmp/task-46.5-rounded-v1-iphone-dark.xcresult
- iphone-french: CanadianHamUITests.CanadianHamPracticeUITests testLessonTryItRevealFrenchLabelsAndState PASS 170.975s; log /tmp/task-46.5-rounded-v1-iphone-french.log; bundle /tmp/task-46.5-rounded-v1-iphone-french.xcresult
- ipad-light: CanadianHamUITests.CanadianHamPracticeUITests testLessonTryItRevealAndAccessibilityLight PASS 67.203s; log /tmp/task-46.5-rounded-v1-ipad-light.log; bundle /tmp/task-46.5-rounded-v1-ipad-light.xcresult
- ipad-dark: CanadianHamUITests.CanadianHamPracticeUITests testLessonTryItRevealAndAccessibilityDark PASS 124.472s; log /tmp/task-46.5-rounded-v1-ipad-dark.log; bundle /tmp/task-46.5-rounded-v1-ipad-dark.xcresult
- ipad-french: CanadianHamUITests.CanadianHamPracticeUITests testLessonTryItRevealFrenchLabelsAndState PASS 71.480s; log /tmp/task-46.5-rounded-v1-ipad-french.log; bundle /tmp/task-46.5-rounded-v1-ipad-french.xcresult
English light on iPad keeps the already-approved TASK-73 no-audit path with every reveal/visibility/state assertion. English light twice on iPhone and largest-Dynamic-Type dark on both devices retain full default collapsed/expanded audits. The existing French method is reveal/labels/state coverage, not an audit; it is unchanged. No new skip, assertion change, positioning change, exception, or audit narrowing in this resume.
Logged measured findings below include original full-image ratios, final measured ratios, crop-used flags and pixel insets. All keepAlways attachments; threshold remains >=4.5:1. iPhone Hide answer1:1.1993729121750754:1 ->13.620392055674973:1 with18px horizontal/6px vertical crop in both light runs. Show answer2:1.1993750921574988:1 ->13.620392186551232:1 with the same crop. Other iPhone light text16.336427557064553–16.336427704401043:1 without crop; iPad dark12.628944545731066–12.629133347776998:1 without crop. No failed/unmeasurable finding was ignored.
- iphone-light-1: label=The second is 28.2 MHz, in HF; the third is 42.3 MHz, in VHF. frame=(24.166666666666657, 511.33333333333303, 354.3333435058594, 74.33333587646484) ratio=16.336427557064553:1 fullImageRatio=16.336427557064553:1 cropUsed=false cropInsetsPixels=none; attachment=/tmp/task-46.5-rounded-v1-iphone-light-1-attachments/1EC0EDED-38B4-490C-9792-6DF4B860B150.txt
- iphone-light-1: label=Hide answer 1 frame=(40.16666666666666, 465.0, 150.66666666666669, 50.33333333333303) ratio=13.620392055674973:1 fullImageRatio=1.1993729121750754:1 cropUsed=true cropInsetsPixels=horizontal=18.0 vertical=6.0; attachment=/tmp/task-46.5-rounded-v1-iphone-light-1-attachments/2190F952-47E0-4DB7-BA4C-76156A01D95A.txt
- iphone-light-1: label=What rough power ratio matches a rise of about 7 dB? frame=(63.333333333333336, 581.5925925925922, 298.33333333333337, 42.33333333333303) ratio=16.336427704401043:1 fullImageRatio=16.336427704401043:1 cropUsed=false cropInsetsPixels=none; attachment=/tmp/task-46.5-rounded-v1-iphone-light-1-attachments/5909ACC0-8CCB-41CD-9EA8-F81671EAD238.txt
- iphone-light-1: label=Show answer 2 frame=(40.16666666666666, 636.0, 160.0, 50.33333333333303) ratio=13.620392186551232:1 fullImageRatio=1.1993750921574988:1 cropUsed=true cropInsetsPixels=horizontal=18.0 vertical=6.0; attachment=/tmp/task-46.5-rounded-v1-iphone-light-1-attachments/7C1FF33B-AF89-4DDD-953E-8BF56509CBC1.txt
- iphone-light-1: label=Try these before reading the feedback below. frame=(40.0, 404.2592592592591, 219.33333333333326, 42.33333333333303) ratio=16.336427704401043:1 fullImageRatio=16.336427704401043:1 cropUsed=false cropInsetsPixels=none; attachment=/tmp/task-46.5-rounded-v1-iphone-light-1-attachments/F04477EB-8B68-4805-B7C1-1F788CE24EAD.txt
- iphone-light-2: label=What rough power ratio matches a rise of about 7 dB? frame=(63.333333333333336, 581.5925925925922, 298.33333333333337, 42.33333333333303) ratio=16.336427704401043:1 fullImageRatio=16.336427704401043:1 cropUsed=false cropInsetsPixels=none; attachment=/tmp/task-46.5-rounded-v1-iphone-light-2-attachments/052350B3-039E-4431-AF92-05666FB93404.txt
- iphone-light-2: label=Show answer 2 frame=(40.16666666666666, 636.0, 160.0, 50.33333333333303) ratio=13.620392186551232:1 fullImageRatio=1.1993750921574988:1 cropUsed=true cropInsetsPixels=horizontal=18.0 vertical=6.0; attachment=/tmp/task-46.5-rounded-v1-iphone-light-2-attachments/0EF149ED-832E-47D0-9CCC-15FB6915612F.txt
- iphone-light-2: label=The second is 28.2 MHz, in HF; the third is 42.3 MHz, in VHF. frame=(24.166666666666657, 511.33333333333303, 354.3333435058594, 74.33333587646484) ratio=16.336427557064553:1 fullImageRatio=16.336427557064553:1 cropUsed=false cropInsetsPixels=none; attachment=/tmp/task-46.5-rounded-v1-iphone-light-2-attachments/A93EF97C-60EF-418F-9D7A-41F48A25C2A8.txt
- iphone-light-2: label=Try these before reading the feedback below. frame=(40.0, 404.2592592592591, 219.33333333333326, 42.33333333333303) ratio=16.336427704401043:1 fullImageRatio=16.336427704401043:1 cropUsed=false cropInsetsPixels=none; attachment=/tmp/task-46.5-rounded-v1-iphone-light-2-attachments/C45C92E3-BCCF-4945-BEC2-C1C74FC7EB44.txt
- iphone-light-2: label=Hide answer 1 frame=(40.16666666666666, 465.0, 150.66666666666669, 50.33333333333303) ratio=13.620392055674973:1 fullImageRatio=1.1993729121750754:1 cropUsed=true cropInsetsPixels=horizontal=18.0 vertical=6.0; attachment=/tmp/task-46.5-rounded-v1-iphone-light-2-attachments/FA6D8BD0-6FC8-4A9A-8F7F-967118BB8B5C.txt
- ipad-dark: label=• frame=(76.0, 949.9055555555551, 23.5, 63.5) ratio=12.629111764231077:1 fullImageRatio=12.629111764231077:1 cropUsed=false cropInsetsPixels=none; attachment=/tmp/task-46.5-rounded-v1-ipad-dark-attachments/0BCF148E-D220-4DDA-9FDA-9D76AC92B771.txt
- ipad-dark: label=Mistaken idea: phase and polarity are two names for the same thing. frame=(107.5, 816.4055555555551, 836.5, 125.5) ratio=12.629133347776998:1 fullImageRatio=12.629133347776998:1 cropUsed=false cropInsetsPixels=none; attachment=/tmp/task-46.5-rounded-v1-ipad-dark-attachments/3A850573-3FC0-4DE2-B32F-073FB50A6F06.txt
- ipad-dark: label=Correction: phase is timing between AC waveforms. DC polarity is positive and negative direction. frame=(107.5, 949.9055555555551, 839.0, 187.5) ratio=12.629100476877243:1 fullImageRatio=12.629100476877243:1 cropUsed=false cropInsetsPixels=none; attachment=/tmp/task-46.5-rounded-v1-ipad-dark-attachments/464CB02E-6DC4-4B71-8065-5088CB38BC49.txt
- ipad-dark: label=• frame=(76.0, 816.4055555555551, 23.5, 63.5) ratio=12.629111764231077:1 fullImageRatio=12.629111764231077:1 cropUsed=false cropInsetsPixels=none; attachment=/tmp/task-46.5-rounded-v1-ipad-dark-attachments/48054C27-34E3-4BAF-B0ED-2EDE216C8ED6.txt
- ipad-dark: label=Decibels as power ratios frame=(76.0, 1120.405555555555, 645.0, 67.0) ratio=12.628944545731066:1 fullImageRatio=12.628944545731066:1 cropUsed=false cropInsetsPixels=none; attachment=/tmp/task-46.5-rounded-v1-ipad-dark-attachments/6362E6EE-E90C-4901-A707-6805E56E66E1.txt
- ipad-dark: label=Mistaken idea: phase and polarity are two names for the same thing. frame=(107.5, 787.4055555555551, 836.5, 125.5) ratio=12.629133347776998:1 fullImageRatio=12.629133347776998:1 cropUsed=false cropInsetsPixels=none; attachment=/tmp/task-46.5-rounded-v1-ipad-dark-attachments/75620AE3-665E-47C6-9284-A4D6394571D8.txt
- ipad-dark: label=• frame=(76.0, 787.4055555555551, 23.5, 63.5) ratio=12.629111764231077:1 fullImageRatio=12.629111764231077:1 cropUsed=false cropInsetsPixels=none; attachment=/tmp/task-46.5-rounded-v1-ipad-dark-attachments/AA0F48FE-8AD1-4A34-8708-F7468EBDA79A.txt
Approved original occlusion-rule findings (not measurement exceptions; ratio N/A), all keepAlways:
- iphone-light-1: label=• frame=x: 40.0, y: 91.59259259259215, width: 8.0, height: 20.33333333333303 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true; attachment=/tmp/task-46.5-rounded-v1-iphone-light-1-attachments/36EC1046-7F15-498E-B147-6D5D12660EC1.txt
- iphone-light-1: label=• frame=x: 40.0, y: 93.92592592592518, width: 8.0, height: 20.33333333333303 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true; attachment=/tmp/task-46.5-rounded-v1-iphone-light-1-attachments/710DA1F7-AEED-4731-8718-3C6AC71797B5.txt
- iphone-light-1: label=Complete: new report = S9 plus (19 - ___) dB = S9 plus ___ dB. frame=x: 56.0, y: 91.59259259259215, width: 285.6666666666667, height: 42.33333333333303 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true; attachment=/tmp/task-46.5-rounded-v1-iphone-light-1-attachments/80545887-06C6-4A32-9B84-32AB4FE57F46.txt
- iphone-light-1: label=Sanity check: Is the report lower while still above S9? frame=x: 56.0, y: 93.92592592592518, width: 292.0, height: 42.33333333333303 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true; attachment=/tmp/task-46.5-rounded-v1-iphone-light-1-attachments/ED19DBEC-FAF6-4AD6-B66C-FE2868CD83F4.txt
- iphone-light-2: label=• frame=x: 40.0, y: 91.59259259259215, width: 8.0, height: 20.33333333333303 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true; attachment=/tmp/task-46.5-rounded-v1-iphone-light-2-attachments/76ABB59C-D9F3-45BF-9CE5-533252878452.txt
- iphone-light-2: label=• frame=x: 40.0, y: 93.92592592592518, width: 8.0, height: 20.33333333333303 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true; attachment=/tmp/task-46.5-rounded-v1-iphone-light-2-attachments/8F484B59-B6C3-48C1-8F1D-161019A268F2.txt
- iphone-light-2: label=Complete: new report = S9 plus (19 - ___) dB = S9 plus ___ dB. frame=x: 56.0, y: 91.59259259259215, width: 285.6666666666667, height: 42.33333333333303 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true; attachment=/tmp/task-46.5-rounded-v1-iphone-light-2-attachments/C6D7F64F-6498-4029-AA7C-A9ACD4ACA9C9.txt
- iphone-light-2: label=Sanity check: Is the report lower while still above S9? frame=x: 56.0, y: 93.92592592592518, width: 292.0, height: 42.33333333333303 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true; attachment=/tmp/task-46.5-rounded-v1-iphone-light-2-attachments/CD6A7334-F824-4A2B-BA6D-8F7E91EBAD34.txt
- iphone-dark: label=Try these before reading the feedback below. frame=x: 40.0, y: 32747.925925925916, width: 322.33333333333326, height: 249.3333333333394 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true; attachment=/tmp/task-46.5-rounded-v1-iphone-dark-attachments/995333F8-DEF2-43BD-89C7-DF37027C0846.txt
- iphone-dark: label=Which ranges contain the second and third harmonics of 14.1 MHz? frame=x: 85.0, y: 32961.259259259255, width: 273.0, height: 497.33333333333576 visibleScrollArea=x: 0.0, y: 116.0, width: 402.0, height: 758.0 scrollFrame=x: 0.0, y: 0.0, width: 402.0, height: 874.0 matchedScrollDescendant=true; attachment=/tmp/task-46.5-rounded-v1-iphone-dark-attachments/E1609EE7-4BFB-469E-9E0B-05C025B823BC.txt
- ipad-dark: label=Phase describes timing between waveforms. A pair of AC signals may have the same frequency but not start their cycles at the same instant; that timing difference is phase. frame=x: 76.0, y: -159.5944444444449, width: 856.0, height: 311.5 visibleScrollArea=x: 0.0, y: 86.0, width: 1032.0, height: 1290.0 scrollFrame=x: 0.0, y: 0.0, width: 1032.0, height: 1376.0 matchedScrollDescendant=true; attachment=/tmp/task-46.5-rounded-v1-ipad-dark-attachments/A969C161-DF64-4737-86A8-BDC7630147D6.txt
- ipad-dark: label=Phase describes timing between waveforms. A pair of AC signals may have the same frequency but not start their cycles at the same instant; that timing difference is phase. frame=x: 76.0, y: -188.5944444444449, width: 856.0, height: 311.5 visibleScrollArea=x: 0.0, y: 86.0, width: 1032.0, height: 1290.0 scrollFrame=x: 0.0, y: 0.0, width: 1032.0, height: 1376.0 matchedScrollDescendant=true; attachment=/tmp/task-46.5-rounded-v1-ipad-dark-attachments/AD6C740A-BEA7-4EB0-95DB-532E1208749F.txt
Documented macOS unit command PASS215/215,0 failures16.497s (16.573s outer test-suite duration); builds the UI-test target successfully. Log /tmp/task-46.5-rounded-v1-mac.log; bundle /tmp/task-46.5-rounded-v1-mac.xcresult. Full per-test results below.
Independent checks PASS: pnpm check:apple-l10n (French export + generic tvOS/visionOS builds; catalogue unchanged); node scripts/check-apple-text-sources.ts; node scripts/check-test-guard.mjs --self-test; TEST_GUARD_PR_BODY="Test-guard-approved: owner decision 2026-10-22" node scripts/check-test-guard.mjs --base origin/main --head HEAD; git diff --check. Logs /tmp/task-46.5-rounded-v1-{l10n,text-sources,test-guard-self,test-guard,diff-check}.log. Known Node module-type and Xcode catalogue warnings remain nonfatal. PR will also cite task-73; no PR opened.
AC3 now verified under the expressly approved TASK-73 iPad-light limitation and existing platform evidence: prior tvOS Try-it focus/select full light/dark audits PASS77.169s and visionOS collapsed/expanded full light/dark audits PASS86.354s; not rerun because only iOS UI-test-local logic changed this resume (l10n generic builds for both passed). Web/content/package results remain those recorded earlier; no changes in this resume. No full iOS suites, title sweeps or figure plan run; coordinator owns merge-batch suites and CanadianHamLessonFigures for all31 changed figure-directive lessons. Reconfirmed31 paths in /tmp/task-46.5-rounded-v1-figure-lessons.txt; copied below. Remove the English light iPad audit limitation once TASK-73 supports safe2x thin-stroke measurement. Independent review still required.
Full macOS unit per-test results (PASS):
- CanadianHamTests.DuoLayoutPolicyTests testCompactWidthIPhoneKeepsSheetPolicy: PASS 0.001s
- CanadianHamTests.DuoLayoutPolicyTests testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact: PASS 0.001s
- CanadianHamTests.DuoLayoutPolicyTests testIPadInspectorRuleRemainsSizeClassDriven: PASS 0.000s
- CanadianHamTests.DuoLayoutPolicyTests testMacAndOtherIdiomsNeverUseIPhonePolicy: PASS 0.000s
- CanadianHamTests.DuoLayoutPolicyTests testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy: PASS 0.000s
- CanadianHamTests.DuoLayoutPolicyTests testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact: PASS 0.004s
- CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp: PASS 0.001s
- CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys: PASS 0.002s
- CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere: PASS 0.001s
- CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds: PASS 0.000s
- CanadianHamTests.ExamCalculatorViewModelTests testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes: PASS 0.001s
- CanadianHamTests.ExamCalculatorViewModelTests testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale: PASS 0.002s
- CanadianHamTests.ExamCalculatorViewModelTests testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString: PASS 0.001s
- CanadianHamTests.ExamCalculatorViewModelTests testKeyHandlingProducesEngineDisplayAndSpokenResult: PASS 0.001s
- CanadianHamTests.ExamCalculatorViewModelTests testOfficialReferenceSheetGateAndBundledPages: PASS 0.001s
- CanadianHamTests.ExamCalculatorViewModelTests testQuestionCardFocusResetKeepsTextSelectionEnabled: PASS 0.004s
- CanadianHamTests.ExamCalculatorViewModelTests testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet: PASS 0.001s
- CanadianHamTests.ExamCalculatorViewModelTests testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekEndsWhenPhoneFullyOpensOrCloses: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekFastUnfoldThroughBandNeverPeeks: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekLeavingToleranceDoesNotResetDismissalSuppression: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekPresentationDismissalSuppressesReopenUntilReset: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekPresentationImmediateAnswerEndsEligibility: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekPresentationStartsOnlyOnceUntilPostureReset: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekRecheckPeeksWithoutNewSamples: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekRequiresStableDwellInSlightOpenBand: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekSlowCloseThroughBandNeverPeeks: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekToleratesSmallJitterOnlyAfterPeekStarts: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHingePeekUnavailableSampleDoesNotResetDismissalSuppression: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHintQualificationMarksUnansweredQuestionAsQualifiedOnly: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp: PASS 0.390s
- CanadianHamTests.HintSessionStateTests testHintVisibilityTimerDoesNotQualifyShortPeekRoute: PASS 0.292s
- CanadianHamTests.HintSessionStateTests testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp: PASS 0.003s
- CanadianHamTests.HintSessionStateTests testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable: PASS 0.003s
- CanadianHamTests.HintSessionStateTests testReviewLaterHintAfterSelectionRecordsHelp: PASS 0.003s
- CanadianHamTests.HintSessionStateTests testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission: PASS 0.001s
- CanadianHamTests.HintSessionStateTests testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange: PASS 2.657s
- CanadianHamTests.LocalizationCatalogTests testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata: PASS 0.004s
- CanadianHamTests.LocalizationCatalogTests testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection: PASS 0.002s
- CanadianHamTests.LocalizationCatalogTests testConceptCheckAnswerStatusMapsShuffledSourceChoices: PASS 0.002s
- CanadianHamTests.LocalizationCatalogTests testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext: PASS 0.002s
- CanadianHamTests.LocalizationCatalogTests testEveryCatalogKeyHasFrenchTranslations: PASS 0.014s
- CanadianHamTests.LocalizationCatalogTests testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries: PASS 0.005s
- CanadianHamTests.LocalizationCatalogTests testLanguagePreferenceResolvesSystemAndOverrides: PASS 0.001s
- CanadianHamTests.LocalizationCatalogTests testLocalizedNullableTextAndLanguageFallsBackToEnglish: PASS 0.001s
- CanadianHamTests.LocalizationCatalogTests testQuestionBankLoadErrorDescriptionUsesFrenchLocale: PASS 0.004s
- CanadianHamTests.LocalizationCatalogTests testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testCompletedMorseCourseSessionIgnoresResubmittedAnswer: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testFixedTimingProfilesUseEngineValues: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testLessonBodyAndBulletContrastTokensMeetMinimumRatio: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession: PASS 1.654s
- CanadianHamTests.MorseTrainerTests testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testMorseAudioSessionStaysActiveUntilLastPlayerReleases: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone: PASS 0.002s
- CanadianHamTests.MorseTrainerTests testMorseCourseProgressIgnoresStoredProgressForAnotherCourse: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testMorseExamGeneratorMeetsReceivingExamConstraints: PASS 0.003s
- CanadianHamTests.MorseTrainerTests testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying: PASS 0.003s
- CanadianHamTests.MorseTrainerTests testMorseSendingClassifiesTimingAndErrorSignal: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testMorseSendingKeyerClassifiesPressWhenAudioFails: PASS 0.004s
- CanadianHamTests.MorseTrainerTests testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended: PASS 0.002s
- CanadianHamTests.MorseTrainerTests testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError: PASS 0.105s
- CanadianHamTests.MorseTrainerTests testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone: PASS 0.005s
- CanadianHamTests.MorseTrainerTests testMorseSendingKeyerReleaseCannotBeSupersededBySilence: PASS 0.004s
- CanadianHamTests.MorseTrainerTests testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress: PASS 0.004s
- CanadianHamTests.MorseTrainerTests testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError: PASS 0.109s
- CanadianHamTests.MorseTrainerTests testMorseSendingPendingFinalizationHelperCancelsAndClears: PASS 0.002s
- CanadianHamTests.MorseTrainerTests testMorseSendingRemainingExamSecondsUsesFixedDeadline: PASS 0.003s
- CanadianHamTests.MorseTrainerTests testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters: PASS 0.003s
- CanadianHamTests.MorseTrainerTests testMorseSettingsClampAndPreset: PASS 0.002s
- CanadianHamTests.MorseTrainerTests testMorseSettingsCodableRoundTripPreservesOutputMode: PASS 0.002s
- CanadianHamTests.MorseTrainerTests testMorseSettingsDecodesLegacyPayloadWithIsEnabled: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast: PASS 0.008s
- CanadianHamTests.MorseTrainerTests testMorseSettingsRoundTripThroughUserDefaults: PASS 0.004s
- CanadianHamTests.MorseTrainerTests testMorseStopDelayDrainsFadeBeforeStoppingEngine: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess: PASS 0.056s
- CanadianHamTests.MorseTrainerTests testReduceFlashingDecisionUsesInjectedFlags: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testReduceFlashingStopsOnlyRunningVisualBeacon: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testScheduleMorseVisualPlaybackInitialStateAndFallback: PASS 0.001s
- CanadianHamTests.MorseTrainerTests testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess: PASS 0.037s
- CanadianHamTests.ProgressStoreTests testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress: PASS 0.072s
- CanadianHamTests.ProgressStoreTests testAdvancedImportRejectsHonoursAttempts: PASS 0.022s
- CanadianHamTests.ProgressStoreTests testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch: PASS 0.003s
- CanadianHamTests.ProgressStoreTests testAppSettingsModelPublishesMorseSettingsForRootViewSync: PASS 0.001s
- CanadianHamTests.ProgressStoreTests testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement: PASS 0.001s
- CanadianHamTests.ProgressStoreTests testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows: PASS 0.001s
- CanadianHamTests.ProgressStoreTests testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore: PASS 0.027s
- CanadianHamTests.ProgressStoreTests testDecodesLegacyBasicExportWithoutBankIdFields: PASS 0.029s
- CanadianHamTests.ProgressStoreTests testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme: PASS 0.029s
- CanadianHamTests.ProgressStoreTests testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker: PASS 0.017s
- CanadianHamTests.ProgressStoreTests testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt: PASS 0.055s
- CanadianHamTests.ProgressStoreTests testFreshInstallDefaultsLanguageToSystem: PASS 0.010s
- CanadianHamTests.ProgressStoreTests testICloudAccountSignalsUseInitInjectedFactory: PASS 0.064s
- CanadianHamTests.ProgressStoreTests testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot: PASS 0.026s
- CanadianHamTests.ProgressStoreTests testICloudDeleteCanDeleteLocalDataAfterZoneDelete: PASS 0.026s
- CanadianHamTests.ProgressStoreTests testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload: PASS 0.135s
- CanadianHamTests.ProgressStoreTests testICloudMergeFixtureIsPermutationIndependentAndIdempotent: PASS 0.004s
- CanadianHamTests.ProgressStoreTests testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal: PASS 0.001s
- CanadianHamTests.ProgressStoreTests testICloudSyncToggleAndAccountSignalsPreserveLocalProgress: PASS 0.053s
- CanadianHamTests.ProgressStoreTests testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing: PASS 0.032s
- CanadianHamTests.ProgressStoreTests testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields: PASS 0.033s
- CanadianHamTests.ProgressStoreTests testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount: PASS 0.044s
- CanadianHamTests.ProgressStoreTests testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons: PASS 0.066s
- CanadianHamTests.ProgressStoreTests testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange: PASS 0.032s
- CanadianHamTests.ProgressStoreTests testImportLeavesTask4610Version2LessonSplitRowsUnchanged: PASS 0.033s
- CanadianHamTests.ProgressStoreTests testImportMigratesMixedTask4610SyncRowsByRowVersion: PASS 0.039s
- CanadianHamTests.ProgressStoreTests testImportMigratesTask4610LessonSplitProgressAndQuizAttempts: PASS 0.037s
- CanadianHamTests.ProgressStoreTests testImportOfOlderExportDoesNotRemoveExistingMorseProgress: PASS 0.030s
- CanadianHamTests.ProgressStoreTests testImportRejectsInvalidSyncDeviceRows: PASS 0.037s
- CanadianHamTests.ProgressStoreTests testImportRejectsUnsupportedLanguagePreferenceValues: PASS 0.037s
- CanadianHamTests.ProgressStoreTests testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses: PASS 0.067s
- CanadianHamTests.ProgressStoreTests testImportRollbackKeepsExistingDataWhenReplacementFails: PASS 0.042s
- CanadianHamTests.ProgressStoreTests testImportRollbackPropagatesMorseProgressRemovalFailure: PASS 0.031s
- CanadianHamTests.ProgressStoreTests testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress: PASS 0.030s
- CanadianHamTests.ProgressStoreTests testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt: PASS 0.034s
- CanadianHamTests.ProgressStoreTests testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues: PASS 0.001s
- CanadianHamTests.ProgressStoreTests testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates: PASS 0.037s
- CanadianHamTests.ProgressStoreTests testImportValidationRejectsDuplicateMorseDailyActivityDates: PASS 0.037s
- CanadianHamTests.ProgressStoreTests testImportValidationRejectsInvalidMorseCourseProgress: PASS 0.038s
- CanadianHamTests.ProgressStoreTests testImportValidationRejectsMismatchedScoreBankId: PASS 0.039s
- CanadianHamTests.ProgressStoreTests testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt: PASS 0.033s
- CanadianHamTests.ProgressStoreTests testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges: PASS 0.032s
- CanadianHamTests.ProgressStoreTests testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults: PASS 0.039s
- CanadianHamTests.ProgressStoreTests testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference: PASS 0.010s
- CanadianHamTests.ProgressStoreTests testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault: PASS 0.014s
- CanadianHamTests.ProgressStoreTests testLaunchIgnoresRegisteredAppleLanguagesValue: PASS 0.010s
- CanadianHamTests.ProgressStoreTests testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue: PASS 0.009s
- CanadianHamTests.ProgressStoreTests testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries: PASS 0.012s
- CanadianHamTests.ProgressStoreTests testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun: PASS 0.013s
- CanadianHamTests.ProgressStoreTests testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting: PASS 0.010s
- CanadianHamTests.ProgressStoreTests testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce: PASS 0.009s
- CanadianHamTests.ProgressStoreTests testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure: PASS 0.029s
- CanadianHamTests.ProgressStoreTests testLessonQuizHelpFixtureValidationAndPayloadRoundTrips: PASS 0.134s
- CanadianHamTests.ProgressStoreTests testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix: PASS 0.031s
- CanadianHamTests.ProgressStoreTests testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice: PASS 2.638s
- CanadianHamTests.ProgressStoreTests testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation: PASS 0.003s
- CanadianHamTests.ProgressStoreTests testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead: PASS 0.060s
- CanadianHamTests.ProgressStoreTests testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution: PASS 0.053s
- CanadianHamTests.ProgressStoreTests testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution: PASS 0.032s
- CanadianHamTests.ProgressStoreTests testMigratesArchivedLessonProgressKeepsMaxOwnReadCount: PASS 0.010s
- CanadianHamTests.ProgressStoreTests testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist: PASS 0.032s
- CanadianHamTests.ProgressStoreTests testMigratesCommittedPreV2StoreFixtureWithAllDataIntact: PASS 0.381s
- CanadianHamTests.ProgressStoreTests testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity: PASS 0.016s
- CanadianHamTests.ProgressStoreTests testMigratesProgressStoreV1ToV2WithoutUniqueConstraints: PASS 0.066s
- CanadianHamTests.ProgressStoreTests testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields: PASS 0.072s
- CanadianHamTests.ProgressStoreTests testMockExamTimerRefreshPreservesFractionalRemainder: PASS 0.001s
- CanadianHamTests.ProgressStoreTests testMorseCourseProgressRoundTripsTwentyRecentCharacterResults: PASS 0.032s
- CanadianHamTests.ProgressStoreTests testMorseExportMapsHapticsToWebCompatibleAudio: PASS 0.001s
- CanadianHamTests.ProgressStoreTests testMorseImportDecodesMissingAndPartialMorsePreferences: PASS 0.052s
- CanadianHamTests.ProgressStoreTests testMorseImportRejectsExplicitNullMorseValues: PASS 0.001s
- CanadianHamTests.ProgressStoreTests testMorseImportRejectsUnsupportedMorsePreferenceEnums: PASS 0.041s
- CanadianHamTests.ProgressStoreTests testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender: PASS 0.932s
- CanadianHamTests.ProgressStoreTests testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference: PASS 0.012s
- CanadianHamTests.ProgressStoreTests testNativeSettingsGeneralBindingsUpdatePracticePreferences: PASS 0.011s
- CanadianHamTests.ProgressStoreTests testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows: PASS 0.037s
- CanadianHamTests.ProgressStoreTests testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt: PASS 0.011s
- CanadianHamTests.ProgressStoreTests testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences: PASS 0.040s
- CanadianHamTests.ProgressStoreTests testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse: PASS 0.033s
- CanadianHamTests.ProgressStoreTests testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints: PASS 0.037s
- CanadianHamTests.ProgressStoreTests testProgressStoreRoundTripExportImportReset: PASS 0.055s
- CanadianHamTests.ProgressStoreTests testResetAllDataTurnsICloudSyncOptInOff: PASS 0.013s
- CanadianHamTests.ProgressStoreTests testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData: PASS 0.029s
- CanadianHamTests.ProgressStoreTests testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure: PASS 0.046s
- CanadianHamTests.ProgressStoreTests testResetClearsAppleLanguagesAndLanguagePreference: PASS 0.012s
- CanadianHamTests.ProgressStoreTests testResetFailureKeepsPreviousAppleLanguagesAndPreference: PASS 0.014s
- CanadianHamTests.ProgressStoreTests testResetRollsBackWhenMorseProgressRemovalFails: PASS 0.014s
- CanadianHamTests.ProgressStoreTests testSavingLargeQuestionProgressBatchBuildsOneWriteContext: PASS 1.737s
- CanadianHamTests.ProgressStoreTests testSharedAppleSettingsModelAppliesLivePreferenceUpdates: PASS 0.012s
- CanadianHamTests.ProgressStoreTests testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules: PASS 0.001s
- CanadianHamTests.ProgressStoreTests testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries: PASS 0.010s
- CanadianHamTests.ProgressStoreTests testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress: PASS 0.102s
- CanadianHamTests.ProgressStoreTests testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists: PASS 0.064s
- CanadianHamTests.ProgressStoreTests testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite: PASS 0.031s
- CanadianHamTests.ProgressStoreTests testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration: PASS 0.009s
- CanadianHamTests.ProgressStoreTests testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices: PASS 0.042s
- CanadianHamTests.ProgressStoreTests testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports: PASS 0.038s
- CanadianHamTests.ProgressStoreTests testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration: PASS 0.028s
- CanadianHamTests.ProgressStoreTests testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds: PASS 0.029s
- CanadianHamTests.ProgressStoreTests testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating: PASS 0.097s
- CanadianHamTests.ProgressStoreTests testTask4610SharedConceptMappingAndConceptInclusiveScores: PASS 0.228s
- CanadianHamTests.ProgressStoreTests testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows: PASS 0.039s
- CanadianHamTests.ProgressStoreTests testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync: PASS 0.054s
- CanadianHamTests.QuestionBankTests testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames: PASS 0.012s
- CanadianHamTests.QuestionBankTests testAdvancedMockExamUsesFiftyQuestionsAndNoHonours: PASS 0.013s
- CanadianHamTests.QuestionBankTests testAppBundleContainsNoReadmeFiles: PASS 0.013s
- CanadianHamTests.QuestionBankTests testAppBundleContainsOnlyExpectedGeneratedBankDirectories: PASS 0.001s
- CanadianHamTests.QuestionBankTests testBundledJSONDecodesExpectedCounts: PASS 0.018s
- CanadianHamTests.QuestionBankTests testBundledLessonModelExposesPrerequisites: PASS 0.545s
- CanadianHamTests.QuestionBankTests testBundledLessonsAndExplanationsLoadThroughContentLibrary: PASS 0.716s
- CanadianHamTests.QuestionBankTests testEngineQuestionDrawKeepsQuestionInsideRequestedCategory: PASS 0.019s
- CanadianHamTests.QuestionBankTests testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion: PASS 0.078s
- CanadianHamTests.QuestionBankTests testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes: PASS 0.001s
- CanadianHamTests.QuestionBankTests testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons: PASS 0.553s
- CanadianHamTests.ReadinessAndScoringTests testAdvancedScoringAndReadinessSuppressHonours: PASS 0.001s
- CanadianHamTests.ReadinessAndScoringTests testExamScoringBoundaries: PASS 0.001s
- CanadianHamTests.ReadinessAndScoringTests testReadinessStates: PASS 0.001s
- CanadianHamTests.ReadinessAndScoringTests testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate: PASS 0.036s
- CanadianHamTests.RootNavigationMappingTests testCompactHomeSessionAndSectionPushesUseVisibleDestination: PASS 0.001s
- CanadianHamTests.RootNavigationMappingTests testEmptyCompactPathMapsToHome: PASS 0.001s
- CanadianHamTests.RootNavigationMappingTests testEveryLearnRouteRoundTripsWithItsWholeStack: PASS 0.001s
- CanadianHamTests.RootNavigationMappingTests testEveryRootSelectionRoundTrips: PASS 0.001s
- CanadianHamTests.RootNavigationMappingTests testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts: PASS 0.001s
- CanadianHamTests.RootNavigationMappingTests testPracticeHintLessonStackKeepsSessionAsSplitSelection: PASS 0.001s
All31 changed figure-directive lesson paths (README example excluded):
- content/lessons/m2-operating-procedures/l-002-01-voice-repeater-and-simplex-procedure.md
- content/lessons/m2-operating-procedures/l-002-02-morse-rst-and-q-signals.md
- content/lessons/m2-operating-procedures/l-002-03-distress-urgency-and-safety-traffic.md
- content/lessons/m2-operating-procedures/l-002-04-records-maps-and-locators.md
- content/lessons/m3-station-practice-safety/l-003-01-station-filtering-and-radio-blocks.md
- content/lessons/m3-station-practice-safety/l-003-02-cw-ssb-blocks-and-receivers.md
- content/lessons/m3-station-practice-safety/l-003-03-digital-interfaces-and-power-supplies.md
- content/lessons/m3-station-practice-safety/l-003-04-antennas-and-receiver-specs.md
- content/lessons/m3-station-practice-safety/l-003-05-signal-quality-cw-ssb-fm.md
- content/lessons/m3-station-practice-safety/l-003-06-controls-digital-voice-and-packet.md
- content/lessons/m3-station-practice-safety/l-003-07-batteries-dc-supplies-and-ripple.md
- content/lessons/m3-station-practice-safety/l-003-08-access-grounding-lightning-rf-safety.md
- content/lessons/m4-circuit-components/l-004-01-amplifiers-and-diodes.md
- content/lessons/m4-circuit-components/l-004-02-transistors-fets-and-tubes.md
- content/lessons/m4-circuit-components/l-004-03-resistor-colour-codes.md
- content/lessons/m5-basic-electronics/l-005-01-units-conductors-current.md
- content/lessons/m5-basic-electronics/l-005-02-power-ohms-law.md
- content/lessons/m5-basic-electronics/l-005-03-parallel-circuits-and-ratings.md
- content/lessons/m5-basic-electronics/l-005-04-ac-and-decibels.md
- content/lessons/m5-basic-electronics/l-005-05-reactance-and-resonance.md
- content/lessons/m5-basic-electronics/l-005-06-transformers-and-meters.md
- content/lessons/m6-feedlines-antennas/l-006-01-feedline-basics-and-types.md
- content/lessons/m6-feedlines-antennas/l-006-02-loss-swr-and-matching.md
- content/lessons/m6-feedlines-antennas/l-006-03-polarization-dipoles-wavelength.md
- content/lessons/m6-feedlines-antennas/l-006-04-directivity-yagis-and-lengths.md
- content/lessons/m6-feedlines-antennas/l-006-05-loops-quads-and-patterns.md
- content/lessons/m7-propagation/l-007-01-paths-ionosphere-and-skip.md
- content/lessons/m7-propagation/l-007-02-absorption-solar-cycle-and-muf.md
- content/lessons/m7-propagation/l-007-03-vhf-uhf-and-unusual-modes.md
- content/lessons/m8-interference-suppression/l-008-01-receiver-device-interference-and-filters.md
- content/lessons/m8-interference-suppression/l-008-02-transmitter-emissions-and-harmonics.md

Internal review fix round 2026-10-23: restored both TASK-46.6.1 TASK-65 paragraphs byte-for-byte from origin/main via CLI, retaining all three TASK-46.5 paragraphs (supersedes earlier branch-version conflict note). Corrected AGENTS/test-comment audit coverage and dated iPad-light limitation coordinator decision 2026-10-23 under owner delegation 2026-10-22: iPhone light default/dark largest audits, French reveal/state only, iPad dark audit. tvOS prompt (including item number) and revealed answer now independently combined/focusable; toggle remains focusable, and UI regression asserts prompt/answer staticTexts acquire actual remote focus. Recast M4 L-004-01 #5 as filtering after rectification, L-004-02 #3 as changing relay switching to linear microphone operation, L-004-03 #4 as wider-tolerance replacement effects on timing; original teaching facts/body unchanged. Capitalized five other lowercase answer starts; full 141-answer scan found none remaining. Web regression parses all37 real lessons, verifies31/141 prompt-answer pairs, numbering/nonempty content, no delimiter paragraphs. Initial run caught stale36 lesson assertion and implicit readdir Buffer typing, both fixed; final pnpm test PASS (web260/260; first run also had unrelated existing IndexedDB v6 migration5s timeout, unchanged full retry passes). Typecheck PASS after explicit UTF-8; coverage100/100, originality0 issues/stale0, links, hints984/984 complete, content-swift26/26, guard self/diff and diff-check PASS. Apple queue and l10n are running under nohup with grep polling, waiting behind coordinator figure-plan run; no other build killed. Targeted results pending.

Internal review fix round COMPLETE 2026-10-23: all requested final checks pass. tvOS testLessonTryItRevealsOnRemoteFocusAndSelectWithAccessibilityLightAndDark PASS93.632s with prompt and answer staticTexts acquiring actual remote focus in both appearances; existing testPracticeHintLadderLessonLinkAndAudit PASS56.296s. visionOS testLessonTryItDisclosureAndAccessibilityLightAndDark PASS86.469s (collapsed/expanded full audits in light/dark). Requested single iPhone17 Pro testLessonTryItRevealAndAccessibilityLight PASS179.308s (both full audits); macOS documented unit command builds UITests and PASS215/215,0 failures,16.713s summed test time. l10n French export plus tvOS/visionOS builds, text sources, guard self/diff (owner decision2026-10-22 plus task-73 markers), typecheck and diff-check all PASS. Durable commands, failures fixed/retried, xcresult paths, scoped skip rationale, and complete per-test macOS215/tvOS2/visionOS1/iPhone1 results are in docs/testing/task-46.5-review-results.md. Raw logs /tmp/task-46.5-review-{tvos,visionos,iphone,macos,l10n,guard-diff-final}.log. Waited politely through coordinator figure-plan and other shared-lock builds; no process killed. Only targeted Apple tests plus full macOS units; no new full platform suite. No audit calls/handlers/shared helpers changed in this fix round. All six requested review fixes addressed; independent rereview still required; no PR opened.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented141 hidden paired Try-it answers across31 M2–M8 lessons with accessible localized web/Apple controls and strict format validation. Internal-review fixes restore TASK-65 cross-lane evidence, accurately date/document the iPad-light exception and French reveal-only scope, make tvOS prompt/answer independently focusable (remote-focus regression green), replace three M4 bank-like prompts with original transfer checks, capitalize answer starts, and test all37 real lessons/141 pairs on web. Final checks PASS: pnpm test (244 content-tools/21 Morse/127 calculator/260 web), typecheck,100/100 coverage,0 originality issues, links,984 complete hints,26 content-swift, tvOS2/2, visionOS1/1, one requested iPhone light179.308s, macOS215/215, l10n/text/guard/diff. Complete per-test results and commands: docs/testing/task-46.5-review-results.md. Approved TASK-73 iPad-light limitation remains. No PR; independent rereview required.
<!-- SECTION:FINAL_SUMMARY:END -->
