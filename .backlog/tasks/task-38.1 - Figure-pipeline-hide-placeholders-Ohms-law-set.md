---
id: TASK-38.1
title: 'Figure pipeline, hide placeholders, Ohm''s law set'
status: To Do
assignee: []
created_date: '2026-10-10 20:55'
updated_date: '2026-10-12 22:21'
labels:
  - content
  - apple
  - web
dependencies: []
parent_task_id: TASK-38
priority: medium
ordinal: 79000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Build the shared figure pipeline and prove it with the Ohm's law set. Figures are original SVG sources under content/figures/ referenced from lesson Markdown (alt text kept from the brief). Web renders them themed for light/dark; Apple renders the same sources (e.g. generated asset catalog with preserved vector data or build-time conversion), lessons only on iOS/iPadOS/macOS. Until a lesson has a figure, learners see nothing (the brief stays in source for authors).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Lessons without a drawn figure no longer show an 'Illustration placeholder'/'Illustration brief' card on web or Apple (brief kept in source; tests assert it)
- [ ] #2 Documented pipeline: SVG source location and naming, how lessons reference figures, how web and Apple render them, light/dark theming via design tokens, and a check that every referenced figure exists and every figure has alt text
- [ ] #3 Figures: Ohm's law triangle (E over I x R), power triangle (P over I x E), and Ohm's law/power wheel (P, E, I, R, 12 formulas) in the power/Ohm's law lesson; the wheel has a full text equivalent (formulas grouped by unknown) available to screen readers
- [ ] #4 Accessibility: text in figures meets 4.5:1 and graphics 3:1 in light and dark; figures scale with width and stay legible at the largest text sizes (zoom or enlarged view where needed); no meaning by colour alone; audits pass on the lesson screen in light and dark
- [ ] #5 Figures are original work (not traced from ISED reference material); an originality note is recorded
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision 2026-10-12 (1A): lesson and Morse screens must not render scroll content under the opaque navigation bar (clip at the bar). No audit exceptions for this family.
<!-- SECTION:NOTES:END -->
