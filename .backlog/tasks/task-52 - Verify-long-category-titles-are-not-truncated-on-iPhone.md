---
id: TASK-52
title: Verify long category titles are not truncated on iPhone
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 08:06'
updated_date: '2026-10-21 16:20'
labels:
  - apple
dependencies: []
priority: low
ordinal: 115000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Seen during task-44.3 work: long category titles such as 'Regulations and Policies' appeared truncated ('Regulations and Polici…') in some iPhone layouts. Check every category list, card and header on iPhone at default and large Dynamic Type sizes, and fix any truncation without minimumScaleFactor or layout changes made just to pass tests.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every category title on iPhone wraps or fits at default and accessibility text sizes, with screenshots or a test as evidence
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Verify the TASK-55 default-size baseline and inventory Home, Practice, Study, weak areas, mock category IDs and the regular-width sidebar.
2. Add EN/FR default and AX-XXXL UI coverage for every Basic/Advanced category list/card/session header plus Study/weak-area headers; retain all existing tests and shared helpers unchanged.
3. Apply the coordinator-approved native navigation exception: keep original titles, require complete accessibility labels and wrapped same-screen content headers, document measured ellipses, and check Large Content Viewer behaviour. No app layout changes remain.
4. Run only the added tests through nohup xbuild on iPhone 17 Pro, save screenshots/results in docs/evidence/task-52, verify deterministic project generation, then finalize, commit and push without a PR.

5. Continuation: short sidebar hierarchy probe confirmed virtualized rows are skipped by full swipes. Preserve the exact full-title StaticText query, use bounded slow scrolling in only the new evidence helper, confirm default B-001/B-003 visibility, remove the temporary diagnostic, and commit before the all-four final xbuild run. Refresh evidence, rerun test guard against origin/main and XcodeGen determinism, then finalize and push without a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Baseline targeted UI test confirms TASK-55 removed the original default-size English Regulations and Policies truncation; the longer Basic Station Assembly, Practice and Safety navigation title and wrapped content header also fit on iPhone 17 Pro. Continuing largest-accessibility French coverage and all shared category surfaces (including Advanced). Test header identifiers resolve to the existing combined accessibility header; tests preserve that hierarchy and all shared helpers.

Reproduced remaining native inline-navigation truncation in French B-003 at Accessibility XXXL. Regression test detects a 314-pt one-line navigation frame where even 17-pt text requires 342.7 pt; screenshot retained from baseline-fr-ax-3.xcresult. Testing a wrapping principal toolbar Text while retaining the system navigation title, with no font shrinking or point-width rules.

Coordinator decision 2026-10-20 (owner may revisit): retain TASK-55 native inline category navigation titles; the owner previously rejected generic Practice titles. Native inline truncation at accessibility sizes is accepted platform behaviour provided VoiceOver receives the full title and the prominent scrollable header visibly wraps the complete category name. Reverted the multiline principal-toolbar experiment: UIKit constrained the bar and the unscaled AX-XXXL title overflowed (y=-201.7, height=571.3). Tests will assert complete native navigation accessibility labels plus full wrapped content headers and investigate native Large Content Viewer support. No font capping/shrinking, custom navigation bar, or generic title changes approved.

Coordinator clarification 2026-10-20: the native navigation-bar visual-ellipsis exception also applies at default text size wherever long native practice or Study module titles cannot fit. Each case must retain the complete accessibility label and the full wrapped title in the content header on that screen. Cards, lists and content headers retain strict no-truncation checks. Evidence will list the specific titles/sizes so the owner can revisit this decision; French B-003 requires 342.7 pt at 17-pt text versus 314 pt available.

Large Content Viewer confirmed on iPhone 17 Pro at AX-XXXL: a ten-second hold on the native French B-003 title displays its complete name in a wrapped/hyphenated system overlay without an ellipsis. Timed host captures at 3 s and 7 s both show it; a repeat capture from the final coverage run is retained in docs/evidence/task-52/native-large-content-viewer-fr-accessibility-xxxl-B-003.png. No app implementation was needed. Strict card measurements now preserve the text language and native hyphenation (the original unhyphenated metric falsely required an extra line for the visibly complete Compo-sants des circuits). All pre-existing tests/audits/helpers remain unchanged.

Coordinator clarification 2026-10-20: the approved native-title exception also covers the existing automatic/large navigation style on Study module screens, with no style/title changes. Observed B-003 at AX-XXXL: native bar displays Station Ass… with a 346.3 × 71.7 pt accessibility frame; the complete Station Assembly, Practice and Safety label and the full wrapped same-screen content header both pass. Evidence retained as native-study-fr-accessibility-xxxl-B-003.png. French AX-XXXL coverage passed in 1278.551 seconds; the other three targeted cases are queued by the conditional driver.

Coordinator-approved measurement correction: SwiftUI text frames omit outer font leading, so the new metric helper now measures glyph/line fragments without usesFontLeading. A complete default-size one-line title was 20.333 pt high versus the old 22-pt leading-inclusive estimate. The unchanged 1-pt pixel-rounding tolerance is far smaller than a full line (~20 pt or more); the new helper also asserts that subtracting a line from a measured multi-line title fails its height predicate. All four TASK-52 cases will be rerun using the final helper, per coordinator instruction; no pre-existing test/audit/helper changed.

Final-helper default EN passed all Home, Practice, Study/module and weak-area checks, then the sidebar selector could not find a standalone Regulations and Policies StaticText at default size. AX sidebar coverage had passed. Coordinator approved stopping only the already-failed TASK-52 run for a short native hierarchy/screenshot diagnostic; verified xcodebuild PID 26932 by all four TASK-52 selectors, result path and exact task-worktree cwd before SIGINT. No other build was touched. This is not yet an app truncation finding; the actual visible row/title must be inspected before adapting the selector.

Blocked: a full CanadianHamLessonFigures plan (no only-testing selectors) occupies the shared xbuild lock; the short default-sidebar diagnostic could not start. Coordinator directed an In Progress handoff. Cancelled only the verified TASK-52 queued probe lockf waiter (PID 92875 under probe xbuild parent 92872, cwd verified); probe log ends XBUILD_EXIT=1 and all its xbuild parents exited. No other build was touched. Evidence docs explicitly distinguish historical observations from final acceptance. Continuation instructions, exact probe/all-four commands, query rules and evidence are in /tmp/task-52-handoff.md. Temporary diagnostic method is intentionally uncommitted for the next worker; remove it after inspection. AC remains unchecked; no final success summary or Done status is claimed.

Continuation 2026-10-21: sidebar hierarchy probe passed in 37.018 s. The initial sidebar contains only upper virtualized rows; a single full swipe skips B-001/B-002 and leaves B-003 at y=-32. Exact full-title StaticText descendants are present when rows enter the hierarchy, including Station Assembly, Practice and Safety (216.7 x 42.3 pt). Visible default-size rows wrap fully in the host screenshot. Replacing only the new positioning helper's not-found swipe with a bounded slow drag; a second short probe will confirm B-001/B-003 before removing the temporary diagnostic. No app-code changes or relaxed text match.

Bounded-scroll sidebar probe passed in 74.495 s: exact full-title StaticText queries found B-001 and B-003, both fully visible below the navigation bar. Host screenshots confirm Regulations and Policies fits and Station Assembly, Practice and Safety wraps to two complete lines without an ellipsis. Removed the temporary diagnostic. Final change is only bounded slow scrolling when a virtualized title does not yet exist; exact full-text/frame/height assertions remain unchanged. Committing this fix before the required four-case final run.

Final validation 2026-10-21: all four cases passed with final glyph helper and exact full-title sidebar query at implementation commit 9218ddfcc35989e2538c4c6c6e6654d16762c5a6. iPhone 17 Pro / iOS 27.0 (24A434): testCategoryTitlesEnglishDefaultSize 667.752 s; testCategoryTitlesEnglishLargestAccessibilitySize 1236.626 s; testCategoryTitlesFrenchDefaultSize 682.248 s; testCategoryTitlesFrenchLargestAccessibilitySize 1356.760 s. xcresulttool confirms 4 passed, 0 failed, 0 skipped; xbuild ended XBUILD_EXIT=0. Evidence: docs/evidence/task-52/README.md, test-summary.json, per-test-results.json, all 92 final session/module measurements, eight final-run portrait images (including confirmed native Large Content Viewer) and two explicitly labelled default-sidebar probe host images. Result bundle /tmp/task-52/final-confirmed.xcresult; log /tmp/task-52/final-confirmed.log. Each case covers all 8 Basic + 7 Advanced Home/Practice cards, sessions/native labels, regular-width sidebar rows, all 8 Study cards/modules/native labels and weak areas (77 screenshots per case). AC #1 verified under the documented coordinator-approved native-navigation ellipsis exception only: complete native accessibility label and full wrapped same-screen content header remain required; cards/lists/content headers passed strict checks. No app-code or navigation-title changes; no shrinking or custom bars. Test guard self-test and diff against fetched origin/main (4c9dbc0fb260a70e669f80459e3c197c2816f785) passed with no guarded changes. Two XcodeGen runs left generated project diff empty; git diff --check passed. macOS/tvOS/visionOS/Pro Max/full suites/figures skipped because this branch only adds iOS UI tests/resources and evidence; all existing tests/audits/shared helpers unchanged. Shared lock respected; no other build interrupted. No PR opened; independent reviewer gate still required.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Verified every Basic/Advanced category title across iPhone Home, Practice, Study, weak areas and regular-width sidebar in EN/FR at default and AX-XXXL sizes. Added four strict UI tests/resources and evidence; fixed only the new evidence helper's bounded scrolling so virtualized sidebar rows are not skipped. All four final cases pass (4 passed / 0 failed / 0 skipped); guard and XcodeGen determinism checks pass. docs/evidence/task-52 contains screenshots, per-test timings and 92 final native-title measurements. Native navigation ellipses remain solely as the coordinator-approved exception with full accessibility labels and wrapped same-screen content headers. No app code changed. Ready for independent review; no PR opened.
<!-- SECTION:FINAL_SUMMARY:END -->
