---
id: TASK-43
title: 'Exam day information (what to bring, allowed calculator and reference sheet)'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:38'
updated_date: '2026-10-12 17:10'
labels:
  - content
  - web
  - apple
dependencies: []
priority: medium
ordinal: 92000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner request 2026-10-12. Add accurate exam-day guidance citing ISED RIC-1 section 7.2: exams are closed book; the only permitted reference material is ISED's 'Reference Material for Amateur Radio Exam - Basic Qualification' sheet; calculators are allowed if they can't store formulas or text; virtual exam specifics (camera check, emailed answer sheet). Scrap paper is examiner discretion (not stated in RIC-1).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 docs/exam-facts.md records the RIC-1 section 7.2 rules with the source URL and access date
- [x] #2 Learners see an 'Exam day' section (in an appropriate lesson and in About or Learn) on web and Apple, plain language, EN UI chrome with French translations, linking to ISED's downloads page for the official reference sheet
- [x] #3 Content checks pass; facts verified against RIC-1
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Re-verify RIC-1 section 7.2/7.2.1 and the ISED downloads page, then add the exam-day facts and access date to docs/exam-facts.md.
2. Extend L-001-01 with a reference-facts table and plain-language Exam day prose, linking learners to the ISED downloads page without restating official questions or answers.
3. Add a short reachable Exam day note in existing Learn/About surfaces on web and Apple, with French UI translations where needed.
4. Run content originality, coverage, quiz, explanation, link, web, and Apple localization/text-source checks; record evidence, check ACs, finalize, and commit each focused slice.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified RIC-1 §7.2/§7.2.1 and the ISED downloads page on 2026-10-12; added closed-book, reference-sheet, calculator, virtual-exam, and scrap-paper caution facts to docs/exam-facts.md.

Added learner-facing Exam day material rules to L-001-01 in the reference-style format, including the ISED downloads page URL for the unlabelled Basic reference sheet and virtual-exam setup notes.

Added an Exam day card to Learn on web and Apple linking to L-001-01, with web French strings and Apple Localizable.xcstrings translations added via a Python JSON round-trip.

Updated the existing French Apple UI test to assert the new Learn Exam day section and localized link.

Web dist URL audit failed on the new official ISED downloads citation; added that exact official downloads URL to the audit allowlist and covered it in the audit tests, then reran web typecheck/tests/audit successfully.

Validation passed: fetched RIC-1 and ISED downloads page on 2026-10-12; pnpm --dir packages/content-tools check:lesson-originality:all; pnpm --dir packages/content-tools check:coverage; pnpm --dir packages/content-tools check:quizzes; pnpm --dir packages/content-tools check:explanations; pnpm check:links; pnpm --filter @canadian-ham/web test; node scripts/check-apple-text-sources.ts; pnpm check:apple-l10n; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice test CODE_SIGNING_ALLOWED=NO; pnpm typecheck; pnpm build:web; pnpm --filter @canadian-ham/web typecheck; pnpm --filter @canadian-ham/web test; pnpm --filter @canadian-ham/web audit:urls.

Review follow-up from r43: tightening lesson facts versus tips, removing unsourced photo-ID wording, adding web Learn tests, rerunning requested checks including Apple network, and adding task-44 follow-up note.

Review follow-up validation passed: pnpm --dir packages/content-tools check:lesson-originality:all; pnpm --dir packages/content-tools check:coverage; pnpm --dir packages/content-tools check:quizzes; pnpm --dir packages/content-tools check:explanations; pnpm check:links; pnpm --filter @canadian-ham/web typecheck; pnpm --filter @canadian-ham/web test; pnpm build:web; pnpm --filter @canadian-ham/web audit:urls; node scripts/check-apple-text-sources.ts; pnpm check:apple-network; pnpm check:apple-l10n (first run timed out while waiting on the build lock, rerun passed); DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice test CODE_SIGNING_ALLOWED=NO.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Addressed r43 review feedback: removed unsourced photo-ID claims, kept the L-001-01 fact table to sourced exam rules, moved practice/in-person/app guidance into tips prose, clarified that the examiner supplies the exam sheet while learners practise with the downloaded English unlabelled sheet, fixed the summary overclaim and French wording, and added web coverage that the Learn Exam day button opens L-001-01 without rendering/fetching an ISED link. Also added the requested task-44 note for future in-app exam tools copy updates. Validation passed with content checks, web checks, Apple text/localization/network checks, and the targeted iOS UI test.
<!-- SECTION:FINAL_SUMMARY:END -->
