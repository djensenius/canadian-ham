---
id: TASK-46.12
title: Realign lesson figures after the TASK-46.10 coverage split
status: Done
assignee:
  - '@worker'
created_date: '2026-10-19 23:09'
updated_date: '2026-10-20 04:50'
labels:
  - content
dependencies:
  - TASK-46.10
parent_task_id: TASK-46
ordinal: 138000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
PR #302 review identified two figure/lesson mismatches after the lesson split: transformer-resonance-meters in L-005-06 still contains a resonance panel and high-impedance-at-resonance brief although resonance is now taught in L-005-05; communications-flowchart in L-001-03 retains a third-party lane although B-001-014 is now taught in L-001-05. Keep the diagrams, text equivalents and briefs aligned with the material taught in each lesson without changing official question-bank text.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The transformer/resonance/meters figure and its brief/text equivalent match their host lesson; resonance is explained with the L-005-05 material rather than presented as already taught in L-005-06.
- [x] #2 The communications flowchart, brief and text equivalent in L-001-03 no longer assume the third-party rules taught later in L-001-05.
- [x] #3 Figure, content-link and targeted lesson-figure accessibility checks pass for the changed figures/lessons.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the affected lessons, figures and UI-test specs; move the parallel LC panel into an original resonance figure for L-005-05 if no existing figure covers it.
2. Rework the transformer/meters and communications figures, synchronizing lesson directives, author briefs, text equivalents and UI-test expectations without changing bank text or coverage.
3. Regenerate Apple assets, render and inspect changed SVGs, run the requested content/package checks and targeted iPhone figure audits, then record evidence, commit and push for internal review.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation: split the original parallel LC panel into parallel-lc-resonance and placed it beside the resonance explanation in L-005-05; no existing figure covered resonance. Kept the stable transformer-resonance-meters id, removed its LC content and tightened its layout to transformers/meters only in L-005-06. Removed the third-party lane from communications-flowchart in L-001-03. Synchronized all three directives, briefs, text equivalents, Apple vector assets/metadata, and UI-test specs; added Module5 LightPart5 so both split lessons remain audited. No question-bank, coverage, quiz or prerequisite changes.
Validation so far: figure fix/check (39 SVGs/references) and checker self-test (53 fixtures), links, all-lesson originality (0 issues), complete hints (984/984), coverage (100/100, no duplicates), and pnpm test pass (153 content-tools, 21 Morse engine, 127 calculator engine, 223 web). qlmanage -t -s 800 rendered all three changed SVGs into /tmp/f4612; opened every PNG and confirmed clear labels, circuit connections, two remaining communications lanes and no clipping. Artwork remains currentColor-only; real app supplies token ink/cream.
Extra teaching-guide validation: swift test --package-path packages/content-swift ran 23 tests, 22 passed; testLoadsRealRepositoryContent has three pre-existing failures at lines 15-17 expecting 36 lessons/orderedLessons/quizzes while the existing TASK-46.10 split gives 37. These source assertions are unchanged from base a056c773; this task adds no lesson or quiz files. All-lesson Markdown parsing and shared figure fixtures pass. Kept this unrelated issue out of scope and notified coordinator. Targeted iPhone 17 Pro figure audits are running via nohup/xbuild; waited for the shared build lock without interfering with other builds.

Initial targeted iOS run passed 3/3 on iPhone 17 Pro: testModule1LessonFiguresLightPart2 (L-001-03), 194.000 s; testModule5LessonFiguresLightPart4 (L-005-05), 211.471 s; testModule5LessonFiguresLightPart5 (L-005-06), 298.424 s. Result bundle /tmp/f4612-ios.xcresult; log /tmp/f4612-xbuild.log; exit 0. Existing test wrappers had writeEvidence default false, so successful runs retained no figure screenshots. Enabled the existing writeEvidence option for exactly these three cases without changing any audit/helper/visibility assertion, then started a second targeted run to inspect actual Apple-rendered labels as required by docs/figures.md. Result bundle will be /tmp/f4612-ios-evidence.xcresult; log /tmp/f4612-xbuild-evidence.log. Test guard passes with no guarded changes. Base tree independently confirmed 37 lesson files and 37 quiz files while the unchanged Swift content-package test expects 36.

Final targeted iOS evidence run PASSED (3/3, 0 failures, 647.653 s) on iPhone 17 Pro: CanadianHamLessonFiguresUITests/testModule1LessonFiguresLightPart2 (L-001-03), 191.859 s; testModule5LessonFiguresLightPart4 (L-005-05), 197.948 s; testModule5LessonFiguresLightPart5 (L-005-06), 257.845 s. Command: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination "platform=iOS Simulator,name=iPhone 17 Pro" -parallel-testing-enabled NO -only-testing:CanadianHamUITests/CanadianHamLessonFiguresUITests/testModule1LessonFiguresLightPart2 -only-testing:CanadianHamUITests/CanadianHamLessonFiguresUITests/testModule5LessonFiguresLightPart4 -only-testing:CanadianHamUITests/CanadianHamLessonFiguresUITests/testModule5LessonFiguresLightPart5 -resultBundlePath /tmp/f4612-ios-evidence.xcresult test CODE_SIGNING_ALLOWED=NO (nohup, grep-only log polling; exit 0). Waited for the shared build lock. No full Apple suites or macOS/tvOS/visionOS runs: task requested targeted iPhone audits, with broader Apple testing deferred to coordinator merge-batch policy.
Exported screenshot attachments from the final result bundle into /tmp/f4612-app-evidence and opened all three named PNGs: testModule1LessonFiguresLightPart2.png, testModule5LessonFiguresLightPart4.png, testModule5LessonFiguresLightPart5.png. Verified real Apple fallback-font labels are all present, clear of strokes and unclipped; ink-on-cream styling, two communications lanes, parallel LC high-Z caption in the resonance lesson, and transformer/meter-only panels in the meter lesson render correctly. Source SVG thumbnails remain in /tmp/f4612. No new regulatory or numeric claims were introduced; figure facts reuse their host lessons.
Acceptance evidence: AC1 verified by source/directive/brief/text-equivalent alignment and both M5 screenshot/audit passes; AC2 verified by the removed lane, synchronized figure prose, and M1 screenshot/audit pass; AC3 verified by 39-source/reference figure check, links check, and all three targeted accessibility checks. Test guard passes without any approval marker; no audit or positioning helper changed. Code commits: 05c251566d4ef5f20445d22988f747fdecbd21d5 and 4607501e (screenshot retention). Internal review and PR opening remain coordinator-owned; no PR opened.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Realigned the split lessons with their original SVG art: moved the parallel LC resonance panel into its own figure in L-005-05, kept only transformer/meter panels in L-005-06, and removed the third-party lane from L-001-03. Updated briefs, alt text, text equivalents, generated Apple assets/metadata and figure UI tests, retaining screenshots for the changed lessons. All requested figure, link, originality, hint, coverage, pnpm test and targeted iPhone accessibility checks pass; source thumbnails and all three Apple screenshots were inspected. Extra Swift content-package testing found only the pre-existing 36-versus-37 lesson/quiz count assertions, left unchanged and reported for follow-up. Ready for coordinator internal review; no PR opened.
<!-- SECTION:FINAL_SUMMARY:END -->
