---
id: TASK-43
title: 'Exam day information (what to bring, allowed calculator and reference sheet)'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:38'
updated_date: '2026-10-12 14:45'
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
- [ ] #1 docs/exam-facts.md records the RIC-1 section 7.2 rules with the source URL and access date
- [ ] #2 Learners see an 'Exam day' section (in an appropriate lesson and in About or Learn) on web and Apple, plain language, EN UI chrome with French translations, linking to ISED's downloads page for the official reference sheet
- [ ] #3 Content checks pass; facts verified against RIC-1
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
<!-- SECTION:NOTES:END -->
