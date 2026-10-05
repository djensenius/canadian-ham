---
id: TASK-11.5
title: Course switcher and Advanced practice and mock exams
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-05 04:30'
labels:
  - web
  - apple
  - accessibility
milestone: m-1
dependencies:
  - TASK-11.4
parent_task_id: TASK-11
priority: medium
ordinal: 37000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner chose one app with a course switcher (2026-10-02). Learners need to pick Basic or Advanced and practise or sit 50-question mocks, without the Basic reference sheet being presented as allowed for Advanced. See docs/proposals/advanced-course.md (owner decisions in task-11 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Web and Apple apps have an accessible course switcher, with the choice stored locally and no network use
- [ ] #2 Advanced practice by topic and 50-question mock exams work offline on web and Apple; Advanced shows no lessons until they exist
- [x] #3 No Basic reference material is shown as exam-allowed for Advanced
- [ ] #4 Accessibility audits, French UI checks, web tests and the four-platform xbuild suites pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect existing multi-bank plumbing in engine-ts, engine-swift, generated Basic/Advanced data, web preferences/progress/exam flows, and Apple target membership in apps/apple/project.yml.\n2. Add a persisted Basic/Advanced course selection in web and Apple iPhone/iPad/Mac UI, defaulting to Basic, with accessible labels and French strings.\n3. Route web and Apple practice/mock/progress/readiness/export flows through the selected bank; hide lessons for Advanced and prevent Basic reference material from appearing as Advanced exam-allowed material.\n4. Bundle content/generated/advanced-2025-02-04 for web and the CanadianHam Apple target only, keep tvOS/visionOS Basic-only, regenerate XcodeGen twice, and update tests for switcher, Advanced 50-question mocks, scoring, persistence, accessibility and French behavior.\n5. Run targeted checks while iterating, then required web and affected Apple full suites; record per-test names and task evidence before finalizing.

6. Fix review blockers: scope Apple progress imports by bank, add Apple French catalogue entries, add required Apple UI/web French tests, then rerun targeted checks and one final full suite per affected Apple platform with per-test names.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented web and Apple course selection defaulting to Basic with local preference persistence. Advanced uses content/generated/advanced-2025-02-04 for web and iOS/macOS app/tests; apps/apple/project.yml intentionally keeps tvOS/visionOS generated resources Basic-only while shared Basic-compatible model/loader changes still compile there. Advanced lessons show coming-soon copy, Basic reference-sheet copy is suppressed for Advanced, and Advanced French category labels fall back to English/lang=en because task-11.10 remains open.

Validation passed: pnpm --filter @canadian-ham/web exec tsc --noEmit; pnpm --filter @canadian-ham/web test (124 tests); pnpm check:schemas; pnpm build:web; pnpm --filter @canadian-ham/web exec node scripts/audit-dist-urls.ts; pnpm check:apple-l10n; node scripts/check-apple-text-sources.ts; XcodeGen generate twice; iOS xbuild full suite; macOS xbuild suite; tvOS xbuild suite; visionOS xbuild suite.

Apple per-test results: iOS CanadianHamTests 47 tests passed and CanadianHamUITests 52 tests passed; macOS CanadianHamTests 47 tests passed with UI tests skipped; tvOS CanadianHamTVUITests 12 tests passed plus bundled unit tests; visionOS CanadianHamVisionTests 3 tests passed and CanadianHamVisionUITests 9 tests passed. Targeted iOS Advanced tests passed before full runs: QuestionBankTests/testAdvancedBundledJSONDecodesExpectedCountsAndEnglishCategoryFallbacks and testAdvancedMockExamUsesFiftyQuestionsAndNoHonours.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added a persisted Basic/Advanced course switcher across web and iPhone/iPad/Mac, bundled Advanced generated data for web and CanadianHam iOS/macOS targets, kept tvOS/visionOS Basic-only resources, routed Advanced practice/mock/readiness/progress/export by bankId, hid lessons/reference-sheet material for Advanced, and verified with web/schema/build/audit/l10n checks plus iOS, macOS, tvOS and visionOS xbuild suites.
<!-- SECTION:FINAL_SUMMARY:END -->
