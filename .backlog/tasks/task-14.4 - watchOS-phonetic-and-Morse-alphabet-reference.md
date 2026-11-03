---
id: TASK-14.4
title: watchOS phonetic and Morse alphabet reference
status: Done
assignee:
  - '@worker'
created_date: '2026-10-25T17:02:00Z'
updated_date: '2026-10-25T21:02:00Z'
labels:
  - apple
  - watchos
milestone: m-1
dependencies:
  - TASK-14.3
documentation:
  - docs/proposals/watchos-companion.md
parent_task_id: TASK-14
type: feature
ordinal: 158000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A glanceable reference is useful between drills without the long lesson-reader navigation excluded from watch v1. Source phonetic spellings from the existing L-002-01 voice procedure table and Morse symbols from morse-swift; do not invent a second Morse mapping or copy the lesson/figure bundle.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The watch home navigation exposes a scrollable A-Z reference showing each letter, its standard phonetic spelling and its Morse dots/dashes, plus the Morse digits 0-9.
- [x] #2 Reference values match the existing L-002-01 phonetic table and morse-swift morseCodeTable; unit tests cover all 26 letters and 10 digits with no duplicate or missing entries.
- [x] #3 Rows remain readable and reachable on the smallest supported watch at large Dynamic Type, with VoiceOver labels that read letter/phonetic word and intelligible dot/dash names rather than punctuation alone.
- [x] #4 Targeted watch unit/UI tests through xbuild cover reference entry, scrolling to the last row and back navigation; no lesson/figure assets, persistence or networking are added, and results are recorded.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Replace the Alphabet placeholder with a watch-only reference model sourced from L-002-01 phonetics and the shared morseCodeTable, plus a wrapping semantic-font list and localized spoken dot/dash labels.
2. Add all-entry unit coverage, a pnpm-test source parity check against the lesson (not bundled on watch), and EN/FR watch navigation/last-row UI tests including large Dynamic Type.
3. Regenerate/check the Xcode project if file discovery requires it; run targeted watch tests, iOS build-for-testing, localization/text/network/iCloud/test guards and repository tests. Record evidence, complete ACs, commit and push without a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented a semantic-font List with A–Z ITU words (Alfa/Juliett unchanged in French), digits 0–9, shared morseCodeTable lookups, visual dots/dashes and combined spoken-word VoiceOver labels. Added 3 all-entry unit tests, 2 EN/FR reference UI tests, updated both existing navigation smoke tests, and a pnpm-test parity checker that reads L-002-01 without bundling it. The checker also rejected injected wrong spelling, duplicate/missing letter and missing-Z fixtures.
Targeted Series 12 42mm watch results now green: all 3 reference unit tests; 2 EN/FR navigation smoke tests; 2 reference UI tests, including largest Dynamic Type (confirmed by row-height comparison), full Juliett/9 row reachability, screenshots and back navigation. Fixed test setup (locale formats strings but does not select bundle language) by passing localized Dot/Dash words into the row formatter; UI tests verify actual EN/FR translations. Replaced flaky Crown-snapping test positioning with precise touch drags; production list remains native Crown/touch scrollable.
iOS build-for-testing passed; pnpm test, typecheck, apple-l10n export/builds, text-source self-test/check, network and iCloud guards passed. XcodeGen output identical over two generations; original xcstrings keys/values/order preserved with only Letters/Digits added. No lesson/figure/quiz/hint assets in the embedded watch bundle. Test guard against the implementation commit and final task evidence still to finish.

Final verification evidence: docs/testing/task-14.4-watch-alphabet.md records all 7 affected per-test watch results (3 reference unit + 2 reference UI + 2 EN/FR navigation smoke), exact targeted xbuild commands, iOS TEST BUILD SUCCEEDED, pnpm test/typecheck, localization, text-source, network/iCloud and test-guard checks. The final reference UI run passed 2/2 after replacing test-only Crown positioning with short touch drags; the large-type test verifies actual size application and complete Juliett/9 frames, and screenshots were visually inspected. No audits, exceptions, shared helpers or unrelated app behavior changed. Test guard against main base faaec618 passed with no findings. Full platform suites intentionally deferred to merge-batch policy; physical VoiceOver listening and broader audits remain TASK-14.5.
AC1: native watch home Alphabet destination and passing EN/FR last-row UI navigation. AC2: exhaustive 26-letter/10-digit unit coverage plus pnpm source parity check and negative mutation checks. AC3: combined word-based labels in both languages, semantic wrapping layout, verified largest Dynamic Type and complete row reachability on Series 12 42mm. AC4: targeted xbuild results recorded; iOS embedding build and resource inspection confirm no lesson/figure/quiz/hint additions; network/iCloud guards pass.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced the watch Alphabet placeholder with an offline A–Z ITU phonetic/Morse and 0–9 Morse reference. Shared morseCodeTable supplies all patterns; Alfa/Juliett and all international words match L-002-01 unchanged in French. Rows use semantic wrapping fonts, combined intelligible VoiceOver labels and localized section/dot/dash words. Three all-entry unit tests, two EN/FR reference UI tests (large Dynamic Type verified), both updated navigation smoke tests, and pnpm lesson-parity checks pass. iOS build-for-testing, localization/text/network/iCloud/test guards, pnpm test and typecheck pass; detailed per-test evidence in docs/testing/task-14.4-watch-alphabet.md. No persistence, network or lesson/figure assets added. Hardware VoiceOver and broader audits remain TASK-14.5; full suites remain the merge-batch gate.
<!-- SECTION:FINAL_SUMMARY:END -->
