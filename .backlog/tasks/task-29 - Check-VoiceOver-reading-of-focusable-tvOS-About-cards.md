---
id: TASK-29
title: Check VoiceOver reading of focusable tvOS About cards
status: To Do
assignee: []
created_date: '2026-10-02 08:06'
labels:
  - apple
  - tvos
  - accessibility
milestone: m-0
dependencies: []
priority: low
ordinal: 53000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: task-1.4 made each tvOS About card (attribution, disclaimer, privacy, sources) one focusable element so the remote can reach them. Combining a card into one element may make VoiceOver read the whole card as a heading (it inherits the title's header trait) and may drop the English language tag on legal text inside the French UI. The accessibility audit passes, but only a listening check on a device or simulator with VoiceOver confirms it.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 With VoiceOver on tvOS, each About card reads its title as a heading and its body as normal text, verified and recorded in docs/accessibility.md
- [ ] #2 In the French UI, the English legal text in the attribution and disclaimer cards is spoken with an English voice
- [ ] #3 If either fails, the header trait or language tag is moved to the right element and the tvOS suite, including accessibility audits, passes via xbuild
<!-- AC:END -->
