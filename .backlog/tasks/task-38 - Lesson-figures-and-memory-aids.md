---
id: TASK-38
title: Lesson figures and memory aids
status: Done
assignee: []
created_date: '2026-10-10 20:54'
updated_date: '2026-10-14 16:47'
labels:
  - content
  - apple
  - web
dependencies: []
priority: medium
ordinal: 78000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Every lesson has an '## Illustration brief' section (36 specs with alt text and a drawing description) that is currently rendered as an 'Illustration placeholder' card. Replace placeholders with original ink-on-cream vector figures shared by web and Apple, and add classic memory aids. Owner approved 2026-10-10; subtasks run in parallel where files don't overlap.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 All subtasks Done
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
All five subtasks are Done on task-38-figures-integration: task-38.1 and task-38.5 were already Done on main; task-38.2, task-38.3, and task-38.4 were finalized here after iOS light/dark lesson-figure audits and figure/content/web validation.

PR #238 review follow-up results: merged origin/main, removed the CanadianHamLessonFiguresUITests focus-frame audit filter so the class now uses the same occluded lesson text contrast helper as main, and changed figure evidence disk writes to require CANADIAN_HAM_FIGURE_EVIDENCE_DIR while keeping XCTAttachments by default. The first affected iOS rerun exposed real Text clipped failures in four long lesson navigation titles (Module 1 light part 2, Module 2 light part 2, Module 3 light part 1, Module 3 light part 2); the app fix gives lesson readers a short inline localized "Lesson" navigation title while the full lesson title remains the in-page lesson-reader-title.

Permanent targeted iOS per-test results for the PR #238 review fix: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination "platform=iOS Simulator,name=iPhone 17 Pro" with -only-testing for CanadianHamLessonFiguresUITests/testModule1LessonFiguresLightPart2, testModule2LessonFiguresLightPart2, testModule3LessonFiguresLightPart1, testModule3LessonFiguresLightPart2, and testModule3LessonFigureDarkSample passed 5/5 in /Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-fgptucrffrpctmbgqivwrseagjmq/Logs/Test/Test-CanadianHam-2026.10.14_12-06-52--0400.xcresult. Individual results: M1 light part 2 passed; M2 light part 2 passed; M3 light part 1 passed; M3 light part 2 passed; M3 dark sample passed. A default no-env rerun of testModule3LessonFigureDarkSample also passed in Test-CanadianHam-2026.10.14_12-36-52--0400.xcresult and left git status clean, proving normal runs attach screenshots without rewriting repo PNGs.

Copilot-round SVG/evidence revalidation: refreshed docs/evidence/task-38.3 PNGs for station-filtering-radio-blocks, digital-interface-linear-supply, communications-flowchart, cw-ssb-signal-paths, and distress-urgency-safety-board with qlmanage -t -s 1200 and inspected them with the read tool. Refreshed task-38-figures app evidence for the M3 light and dark station-filtering-radio-blocks samples from the passing rerun attachments. Validation passed: pnpm check:figures; node scripts/check-figures.mjs --self-test; pnpm check:apple-l10n.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Completed the lesson figures and memory aids initiative across the figure pipeline, checker, core memory aids, modules 1-4, and modules 5-8. Integration evidence includes passing figure/content/web checks, targeted iOS lesson-figure audits, and app screenshots under docs/evidence/task-38-figures/app/.
<!-- SECTION:FINAL_SUMMARY:END -->
