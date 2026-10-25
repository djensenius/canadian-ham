---
id: TASK-14.5
title: watchOS EN-FR and accessibility polish with audits
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-25T17:02:00Z'
updated_date: '2026-10-25T21:44:00Z'
labels:
  - apple
  - watchos
  - accessibility
milestone: m-1
dependencies:
  - TASK-14.4
documentation:
  - docs/proposals/watchos-companion.md
parent_task_id: TASK-14
type: feature
ordinal: 159000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
After the practice, Morse and reference flows exist, polish the complete watch experience for both interface languages and assistive technologies rather than treating a phone layout as watch-ready. The official bank is bilingual; existing explanations are currently EN-only and must be transparently labelled as a fallback. The installed watchOS XCUIAutomation header declares accessibility audits from watchOS 10, but actual simulator behaviour still needs validation. This task does not translate explanation content or widen previously approved audit exceptions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All watch interface strings, errors, settings, feedback and accessibility labels are localized EN/FR and follow system language with a session-only Settings override; official EN/FR question/answer text is unchanged, and English-only explanation fallback is labelled and correctly language-tagged.
- [ ] #2 Quick practice, Morse, reference and Settings support largest Dynamic Type and the smallest supported watch layout without truncating question/answer text or hiding controls; Crown and tap paths, selection and textual correctness feedback remain operable.
- [ ] #3 VoiceOver order, adjustable Crown/alternative tap controls, labels, selected state and feedback announcements are verified without revealing Morse answers early; haptics and optional tones have a usable non-flashing text alternative.
- [ ] #4 Reduce Motion removes ornamental animation, Morse never requires a flashing beacon, and output stops on inactivity/navigation; manual VoiceOver/Reduce Motion checks and physical-watch output observations are recorded with device/OS.
- [ ] #5 Targeted EN/FR watch UI tests and full performAccessibilityAudit calls on supported home/practice/feedback/Morse/reference/settings states pass via xbuild. Actual unsupported audit/runtime behaviour is documented and escalated with a manual audit record, not silently skipped or covered by new exception handlers.
- [ ] #6 pnpm check:apple-l10n and node scripts/check-apple-text-sources.ts pass with watch source/catalogue membership covered; targeted watch unit/UI per-test results are recorded and no existing platform audit is weakened.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect watch flows, app localization and carried-over review items. 2. Implement in-memory session language Settings, localized bundle lookup and accessible wrapping/VoiceOver playback and feedback. 3. Add EN/FR largest-size UI coverage and unfiltered default audits, isolate cold-load test and add reference guard self-tests. 4. Run full watch scheme, smallest-watch targeted UI, localization/text/network/iCloud/test guards, iOS build and localization units, and macOS units; document exact per-test results and owner-only checks. 5. Commit and push milestones; leave manual/hardware-dependent criteria blocked rather than claiming completion.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
From the TASK-14.2 review: (1) check in the VoiceOver listening pass that the Crown sheet's Correct/Incorrect announcement isn't cut off by the sheet dismissing (WatchPracticeView submit, then dismiss); if it is, post the announcement after dismissal. (2) The cold-load unit test relies on alphabetical order and a shared loader; keep test-order randomisation off for the watch plan, or isolate it.

From TASK-14.3 approved review findings 6/7: add full performAccessibilityAudit runs on the Practice and Morse screens/states (not only structural checks); give bare-letter answer buttons localized labels such as "Letter A" without early answer disclosure; announce when answer choices appear after playback; check VoiceOver Play/Replay announcements versus the first tone and resolve audible overlap. These remain TASK-14.5 work; no audit exceptions approved.

From the TASK-14.4 review: (1) Alphabet spoken patterns join with spaces ('Dot Dash'), but Morse uses ', '; make both use ', ' so VoiceOver pauses between elements. (2) French dah terminology: the 'Dash' key gives 'Tiret', but the 14.3 haptic-style strings say 'trait'; pick one. 'Trait' is the usual French Morse term, so consider changing 'Dash' to 'Trait' everywhere, checking the iOS Morse trainer first. (3) WatchAlphabetReferenceTests' en/fr/fr-CA loop hard-codes the words and only tests joining; rename it or check real localization. (4) Add a --self-test to scripts/check-watch-alphabet-reference.mjs. (5) Smallest-watch layout: only Series 12 42mm was tested; the smallest supported watch is still part of AC2 here.

Implemented session-only Settings locale + explicit lproj lookup (phone persists AppleLanguages and requires restart, so that persistence is deliberately not reused); retained app-wide French Tiret and aligned three watch haptic descriptions. Added Letter labels, comma-separated spoken patterns, choices announcement, 1.5 s VoiceOver output lead-in and Crown feedback after dismissal. Default home accessibility audit succeeded on watchOS 27 / Series 12 42mm at largest text; no exception handler. Created (not booted yet) SE 3 40mm simulator 596608F4-525A-4BED-8642-151C0E69842D for targeted smallest-layout run. Cold probes now use independent caches and assert construction does not warm shared cache; reference guard self-test passes.

Milestone ff25c9fe pushed. Full Series 12 42mm watch scheme: all 28 units passed and 24/27 UI passed; all 16 EN/FR largest-text full default audits passed with no exception handlers. Three test expectation typos (Vibrations and comma separators) fixed; targeted Series 12 rerun passed session override + both reference tests (54.682/54.664/83.197 s). Added selected-trait assertions and explicit official-text speech language metadata; now validating these with smallest-watch AX UI runs. No audit/runtime limitation encountered.

Smallest SE 3 40mm / watchOS 27 targeted run: 1 new localization unit, both reference UI tests, both practice UI tests, EN/FR AX control/long-question walks and all 16 default audits passed. Session-override test exposed a real watchOS navigation-title cache issue on revisiting Settings: content switched to English but title stayed French. Fixed by explicitly resolving the title via the selected bundle. Smallest targeted rerun passed EN Settings audit (9.359s), FR Settings audit (8.288s), full override/reset regression (68.787s). No audit handler/skip/filter added. Manual listening/hardware remains owner-pending.
<!-- SECTION:NOTES:END -->
