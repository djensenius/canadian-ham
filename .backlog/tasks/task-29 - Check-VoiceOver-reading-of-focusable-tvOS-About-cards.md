---
id: TASK-29
title: Check VoiceOver reading of focusable tvOS About cards
status: In Progress
assignee:
  - '@pi-worker'
created_date: 2026-10-02 08:06
updated_date: '2026-10-25T17:05:00Z'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect tvOS About focus/heading/language structure and capture EN/FR focused-card labels and debug descriptions with targeted UI tests before changing semantics.
2. Keep the existing visual cards and one remote focus stop per card; remove inherited whole-card Header traits and provide a single attributed legal-card label with explicit English body runs if needed. Extend structural EN/FR assertions without weakening audits.
3. Run targeted About tests and the existing tvOS UI/full suite through nohup xbuild with grep polling on Apple TV 4K (3rd generation); run localization/text-source checks.
4. Document structural evidence and exact owner VoiceOver listening steps; leave AC1/AC2 pending and TASK-29 In Progress, check AC3 only on passing suite, commit and push (no PR).
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Structural verification complete in EN/FR on Apple TV 4K (3rd generation), tvOS 27.0: baseline and final focused debugDescription captures report StaticText/Focused and no literal Header for all five cards (Bank included). The snapshot format does not expose every UIKit trait or attributed language run; no listening claim is made. Before: title child .isHeader plus implicit .combine and separate en-CA legal child labels. After: one explicit attributed label from the visible strings, title-only h2 run, normal body runs, en legal bodies/fr-CA French titles, aggregate .isHeader removed, .combine retained (no guarded .ignore or audit exceptions).
Added EN/FR UI assertions for single combined label, remote focus order, title/body/full legal paragraphs, StaticText and no reported Header; keepAlways full debugDescription attachments. Added TVAboutCardText unit tests for per-run headings/languages. Targeted xbuild About+metadata run passed 7/7 including existing light/dark About audits; pnpm check:apple-l10n and node scripts/check-apple-text-sources.ts passed. Full tvOS suite running via nohup/xbuild.
AC1/AC2 evidence: structural verification done; listening check pending owner. Exact owner EN/FR VoiceOver steps and structural limitations are documented in docs/accessibility.md; label/Attributes excerpts are in docs/evidence/tvos-about-card-accessibility.txt. TASK-29 remains In Progress.
<!-- SECTION:NOTES:END -->
