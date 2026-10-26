---
id: TASK-76
title: 'French Morse dah term: make ''points et traits'' consistent with ''Tiret'''
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T22:27:00Z'
updated_date: '2026-10-26T13:35:00Z'
labels:
  - l10n
dependencies: []
priority: low
ordinal: 161000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The app's Dash key translates to 'Tiret', and the watch uses 'tiret'. One iOS Morse string (Meet %@… dits and dahs) still says 'points et traits'. Pick one French term for dah across iOS, macOS, tvOS, visionOS and watch ('trait' is common in French Morse usage; 'tiret' is what the app uses now) and make every string consistent. Found in the TASK-14.5 review.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 One French dah term is used in every Apple string-catalogue entry and the web French copy where Morse appears
- [ ] #2 pnpm check:apple-l10n and the affected Apple l10n tests pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inventory French Morse terminology across Apple catalogues, web, content and engines, preserving official ISED wording.
2. Normalize authored dah labels to trait and dit labels to point; update label assertions and regression coverage without changing English or catalogue key order.
3. Run localization/text checks, web checks and targeted watch/macOS/iOS tests through xbuild; record per-test evidence.
4. Commit and push the implementation, verify acceptance criteria and finalize TASK-76 without opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Inventory (2026-10-26, before edits): Localizable.xcstrings fr and fr-CA have the same 12 entries using tiret(s): Dash; Dash paddle; Send dash; dot/dash feedback format; no-feedback instruction; insufficient-dots-and-dashes feedback; notation warning; straight-key accessibility hint; sending-practice instructions; and all three watch haptic-style descriptions. Contrary to the handoff parenthetical, all three style descriptions still used tiret, so these are included. Point(s) already appears correctly in Dot, Send dot, Dot paddle and those shared instructions/formats. Meet %@ already uses points et traits and stays unchanged. No ti/ta labels. Audited every key mentioning dash/dah/dit/dot/Morse and every French value with these terms in both locales.
Other catalogue: watch InfoPlist.xcstrings contains only bundle display/name translations, no Morse terms. Web: apps/web/src/lib/i18n.ts contains nine Morse entries with tiret(s): notation warning, sending intro, keyboard help, straight-key hint, dash paddle/title hint, no-feedback copy, feedback summary, unavailable ratio. Point(s) and course Meet points et traits already correct; keyboard trait d’union denotes the physical hyphen key and stays unchanged. No ti/ta. No other French Morse UI labels in packages/morse-engine or packages/morse-swift; engines use language-neutral dot/dash identifiers. Alphabet parity script checks only ITU spellings, not translated labels.
Content: Morse operating-procedure lesson and Koch-course metadata have no authored French Morse terminology requiring edits. Official ISED Basic B-002-005-009, B-003-011-001 and B-003-014-002 already use point(s)/trait(s) in source/generated French answers; no official tiret occurrence found. All content/generated and content/sources preserved verbatim. iOS UI grep found Morse tests only in English and no existing French Morse text assertion; new LocalizationCatalogTests coverage exercises both compiled French bundles.

Implemented 12 catalogue key changes in both fr and fr-CA (24 values), nine French web messages and watch label assertions. Added testFrenchMorseCopyUsesPointsAndTraitsInBothLocales for all 16 authored point/trait keys against compiled fr and fr-CA bundles, and a French web Morse terminology regression. Python JSON round-trip is byte-stable except the 24 intended value changes; main catalogue key order, non-French values, InfoPlist and official content verified unchanged. Additional authored French hints mention Morse but contain no dah/dit terms needing edits.
Checks passed: node scripts/check-apple-text-sources.ts; pnpm test (content-tools 250, morse-engine 21, calculator 127, web 282/18 files; plus watch-alphabet parity, official-reference and release-permission checks); pnpm typecheck; pnpm build:web; pnpm --filter @canadian-ham/web audit:urls (URL/CSP pass). Known non-failing output: jsdom canvas not implemented; Vite large-chunk warning. Apple localization export completed without catalogue rewrite; gate continues through platform builds, sharing xbuild lock with TASK-74.
<!-- SECTION:NOTES:END -->
