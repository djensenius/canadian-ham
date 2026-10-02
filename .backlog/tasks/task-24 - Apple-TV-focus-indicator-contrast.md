---
id: TASK-24
title: Apple TV focus indicator contrast
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:10'
updated_date: '2026-10-02 02:06'
labels:
  - apple
  - accessibility
  - tvos
milestone: m-0
dependencies: []
priority: medium
ordinal: 32000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the task-8 review found the tvOS focus ring (#8F2E1D) sits on the #A53A2A primary button at roughly 1.3:1, so focus shows mostly through the button growing. Answer and category buttons use the same colour pairing. tvOS users navigate entirely by focus, so the focused control must be clearly distinguishable (WCAG 2.2 SC 1.4.11 non-text contrast, with SC 2.4.13 focus appearance as the target). Fix the focus appearance across tvOS buttons in light and dark modes, keeping the ink-brush-on-cream design.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every focusable tvOS control's focus indicator has at least 3:1 contrast against both the unfocused state and the adjacent background, in light and dark modes, with the measured values recorded in docs/accessibility.md
- [x] #2 The indicator does not rely on scale alone (for example a light outer ring or a contrasting outline) and still works with Reduce Motion on
- [x] #3 tvOS UI tests and the tvOS accessibility audit pass via xbuild, and updated screenshots of focused primary, answer and category buttons are committed under docs/evidence
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect tvOS button/focus styling and existing accessibility docs/evidence conventions.
2. Update shared tvOS focus indicator styling to preserve the cream ink-brush look while adding a high-contrast, non-scale-only ring across focusable tvOS controls.
3. Add tvOS UI coverage to capture one focused primary, answer, and category state PNG under docs/evidence and verify visibility.
4. Record computed light/dark contrast ratios from actual colors in docs/accessibility.md.
5. Run the required tvOS xbuild suite/audit, then check acceptance criteria, summarize, and set Done as the final task change.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented tvOS two-stroke focus rings for app-owned controls: category cards, answer choices, primary actions, secondary navigation/actions, and the language toggle. Removed remaining default bordered buttons/picker from the tvOS app-owned chrome.
Evidence for AC1: docs/accessibility.md records WCAG contrast calculations from actual sRGB token values for light and dark modes; recorded minima are >=3:1 against unfocused border/fill and adjacent backgrounds (lowest recorded ratio 3.55:1).
Evidence for AC2: focus indication is a 12 pt outer stroke plus 4 pt inner stroke and remains visible when Reduce Motion disables focus scale via accessibilityReduceMotion guards.
Evidence for AC3: committed one PNG per state under docs/evidence (tvos-category-focus-ring.png, tvos-answer-focus-ring.png, tvos-primary-focus-ring.png). Opened each PNG and confirmed the ring is visible and the focused control is on screen. Final validation command passed: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamTV -destination platform=tvOS Simulator,name=Apple TV 4K (3rd generation) -resultBundlePath /tmp/canadian-ham-task-24-tvos-final.xcresult test CODE_SIGNING_ALLOWED=NO. Per-test: 3 CanadianHamTVTests passed and 6 CanadianHamTVUITests passed, including light/dark accessibility-audit tests and focus-ring screenshot evidence test.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added a reusable two-stroke tvOS focus indicator that preserves the ink-on-cream visual style while meeting non-text contrast requirements across primary, answer, category, secondary, and language controls. Documented measured light/dark contrast ratios in docs/accessibility.md, committed one evidence PNG for focused category/answer/primary states, and verified with the full CanadianHamTV xbuild test suite plus tvOS accessibility audits.
<!-- SECTION:FINAL_SUMMARY:END -->
