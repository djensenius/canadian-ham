---
id: TASK-50
title: Question hints
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 07:57'
updated_date: '2026-10-16 11:49'
labels: []
dependencies: []
documentation:
  - docs/teaching-guide.md
  - docs/content-licensing.md
priority: medium
type: feature
ordinal: 114000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner-approved feature (2026-10-15): add per-question hints for the active ISED Basic bank, EN and FR, as original project content separate from official ISED data. Decisions: hints appear in practice and review sessions only, never mock exams; lesson quizzes are out of scope and need a future owner decision; each question has a two-step ladder where Hint 1 nudges the concept/formula/reference-sheet area and Hint 2 works the setup without giving the answer; answering after any hint records answered with help, does not count toward mastery or weak-area clearing, and returns sooner in spaced review; hints may point to a reference-sheet section in plain words only where that sheet is available and must never copy sheet content; initial platform order is content schema/checker/hint writing, then web UI in the existing exam-tools panel, then iOS/iPadOS/macOS after task-44.3, with tvOS/visionOS later. Content must never restate the correct answer, option text, or question wording; use docs/teaching-guide.md style including SI spacing, x for multiply, and E for voltage; include automated leakage/originality checks.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The Basic bank has tracked subtasks for schema/checking, pilot content, category content batches, web UI, Apple UI, tvOS/visionOS follow-up, and lesson-quiz follow-up.
- [ ] #2 Implementation order and owner decisions from 2026-10-15 are recorded so future workers do not add hints to mock exams or lesson quizzes without approval.
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Review follow-up hint style rules (owner rule: Hint 2 never gives the answer): hints must never eliminate answer options, paraphrase/list wrong options, or name/point at the correct answer's distinctive words. Hint 1 nudges toward the concept or principle. Hint 2 teaches the underlying relationship or setup well enough to reason from, and recall questions should explain how layers fit together without singling out the current option. Each hint must stand alone because practice order is random. Hints must not state facts that answer another question in the same subsection. French text must be natural and consistent, including ISED terminology such as "stations de radioamateur".

Owner recall-ladder ruling applied (2026-10-16): default A+C means Hint 2 teaches distinctions among the involved concepts and links to the lesson section, while not connecting the asked-for function to this question's option. The old subsection rule is relaxed to "never directly state another question's answer"; shared distinctions are allowed. B is allowed when a recall question cannot have a useful non-giveaway Hint 2: the file may contain only Hint 1, and must include singleLevelReason plus lessonLink.
<!-- SECTION:NOTES:END -->
