# TASK-52: iPhone category titles

> **Validation complete — 2026-10-21.** All four final-helper cases passed:
> English and French at default and Accessibility XXXL sizes, including both
> banks' regular-width sidebar. Cards, lists and content headers passed strict
> full-text/frame/height checks. Native navigation ellipses remain only under
> the documented coordinator-approved exception below. No app code changed.
> Independent branch review is still required before opening a PR.

## Baseline and navigation-title decision

TASK-55's inline practice navigation title fixes the originally reported English
`Regulations and Polici…` at default text size on iPhone 17 Pro. The full title and
wrapped content header are visible in [the final confirmation screenshot](session-en-default-B-001.png).
The longer English B-003 title also fits at default size.

The native navigation bar still visually ellipsizes longer titles. In particular,
French B-003 (`Montage d'une station, pratique et sécurité`) at Accessibility XXXL
has a 314-point navigation text frame; even its 17-point text requires 342.7 points.
[This screenshot](native-fr-accessibility-xxxl-B-003.png) shows the ellipsis and the
complete wrapped title in the content header on the same screen. The native
navigation element's accessibility label remains the complete category name,
without an ellipsis.

**Coordinator decisions, 2026-10-20 (the owner may revisit):** retain the native
category navigation titles chosen in TASK-55. The owner previously rejected a
generic `Practice` title. Native navigation-bar visual ellipses are accepted at
both default and accessibility sizes when the native title cannot fit, provided
its accessibility label is complete and the full title wraps in the prominent
content header on the same screen. This exception does not apply to category
lists, cards, or content headers.

An unscaled, multiline SwiftUI principal toolbar title was investigated and
reverted: UIKit's fixed bar height did not accommodate it. At Accessibility XXXL
the title extended from y = -201.7 for 571.3 points, outside the bar and screen.
No custom bar, capped font, font shrinking, generic navigation title, or app layout
change is included in this task.

## Surface inventory

- **Home and Practice category cards:** `CategoryCard` in `StudyViews.swift`,
  shared by both lists. Tests load every Basic and Advanced EN/FR title from the
  source category JSON, position its rendered text frame on screen, and compare
  its height with the full string's Dynamic Type font metrics. Measurements
  preserve the text language and native hyphenation (for example, French
  `Composants` can render as `Compo-` / `sants` without changing the bank text).
- **Practice category sessions:** every Basic and Advanced title is checked in
  the native navigation accessibility label and the existing combined content
  header. The header keeps its existing accessibility hierarchy; title bounds
  are inferred from its actual width, serif title font, and content padding.
  Screenshots supplement this geometry check because the combined accessibility
  element also contains the session tally and summary.
- **Study/Learn:** all eight module cards use the corresponding Basic category
  names. Lessons/modules remain authored in English in the French interface.
  Every module also exercises its content header and native navigation
  accessibility label, including the original long examples B-001 and B-003.
- **Weak areas:** uses the same practice-session header, with the localized
  `Weak areas` / `Points faibles` scope title rather than a category-name list.
  The seeded weak-area flow is checked in both languages and sizes.
- **Regular-width sidebar:** `CategoryRow` in `RootView.swift`. The existing
  DEBUG regular-size-class override on a landscape iPhone exercises this list
  for both banks. At Accessibility XXXL, wrapped rows can exceed the short
  landscape viewport; tests require full text height, column-width fit, and
  reachability by scrolling rather than shrinking them.
- **Mock exam:** source inspection of `MockExamView`, its result breakdown, and
  `QuestionCard` in `StudyViews.swift` confirms that they display category IDs
  (`B-001`, etc.), not the long category names. No category-name layout exists
  there to modify. Existing mock tests/audits are unchanged.

The metric helper measures glyph/line fragments without outer font leading,
which SwiftUI excludes from its text frame. A complete default-size one-line
frame is 20.333 points high; including outer leading incorrectly estimated 22
points. The unchanged 1-point pixel-rounding tolerance cannot hide a missing
line (about 20 points or more). For each measured multi-line title, the helper
also checks that subtracting a full line makes the same height predicate fail.
The coordinator approved this correction and required a fresh run of all four
cases with the final helper.

Four source-named tests in `CanadianHamPracticeUITests` cover English and French
at default size and `UICTContentSizeCategoryAccessibilityXXXL`. Appearance is
fixed to light for each test; it is never toggled while an app is running. All
pre-existing tests, audits, and shared helpers remain byte-identical.

## Native Large Content Viewer

**Confirmed on the iPhone 17 Pro simulator at Accessibility XXXL.** Holding the
French B-003 native navigation title for ten seconds opens the system Large
Content Viewer. Its overlay displays the complete category title without an
ellipsis, using native wrapping/hyphenation. Earlier 3- and 7-second host captures
both showed the overlay; [the retained image](native-large-content-viewer-fr-accessibility-xxxl-B-003.png)
is a fresh host capture seven seconds into the final four-case run's gesture.
The gesture and an accessibility hierarchy attachment are also recorded by
`testCategoryTitlesFrenchLargestAccessibilitySize`. No app implementation of a
custom viewer, toolbar, or navigation bar was added.

## Native Study navigation titles

Study modules retain their existing native automatic/large-title style, rather
than the inline style used in practice. For B-003 at AX-XXXL, that bar displays
`Station Ass…` in a 346.3 × 71.7-point accessibility frame; its full accessibility
label and complete wrapped content header both pass. [The same-screen evidence](native-study-fr-accessibility-xxxl-B-003.png)
shows the distinction. The coordinator explicitly confirmed on 2026-10-20 that
the exception also covers this existing native large-title style; no title or
style change is included.

## Default sidebar diagnosis

The short hierarchy probe passed in **37.018 s**. At default size the sidebar
virtualizes its rows: B-001 does not initially exist in the accessibility tree,
and one full swipe jumps past B-001/B-002 to B-003 at y = -32. The displayed rows
still have exact full-title `StaticText` descendants inside buttons whose labels
include the complete title and counts. There was no merged-label query problem
and no visual truncation finding.

The fix preserves the exact full-title query and all text/frame/height checks.
Only the new evidence-positioning helper's not-found branch changes: a slow drag
of one-third of the visible height replaces the full swipe, preventing skipped
virtualized rows. A second probe passed in **74.495 s**, checking B-001 and B-003
fully below the navigation bar. Host captures show [B-001 fitting](sidebar-en-default-B-001-probe.png)
and [B-003 wrapping fully to two lines](sidebar-en-default-B-003-probe.png).
These two supplemental images are from that bounded-scroll probe, not the final
four-case run. The temporary diagnostic was removed before committing the fix.

## Final validation

Device: iPhone 17 Pro simulator, iOS 27.0 (24A434). Final test implementation:
`9218ddfcc35989e2538c4c6c6e6654d16762c5a6`. Result: **4 passed, 0 failed,
0 skipped**, confirmed by `xcresulttool` ([summary](test-summary.json),
[per-test results and screenshot counts](per-test-results.json)).

| `CanadianHamPracticeUITests` case | Outcome | Duration |
| --- | --- | ---: |
| `testCategoryTitlesEnglishDefaultSize` | Passed | 667.752 s |
| `testCategoryTitlesEnglishLargestAccessibilitySize` | Passed | 1236.626 s |
| `testCategoryTitlesFrenchDefaultSize` | Passed | 682.248 s |
| `testCategoryTitlesFrenchLargestAccessibilitySize` | Passed | 1356.760 s |

Each case covers all 8 Basic and 7 Advanced titles on Home, Practice cards,
session headers/native labels and the regular-width sidebar; all 8 Study
cards/module headers/native labels; and the weak-area header. Each case retained
77 screenshots in the result bundle. All eight portrait images in this directory
are replaced with final-run evidence, including the native Large Content Viewer
host capture. The two landscape probe images are explicitly identified above.

Representative additional final-run screenshots:

- [Advanced French Practice card at AX-XXXL](practice-fr-accessibility-xxxl-A-007.png).
- [Advanced French session header at AX-XXXL](session-fr-accessibility-xxxl-A-007.png).
- [French weak-area header at AX-XXXL](weak-areas-fr-accessibility-xxxl.png).
- [French Home card with native hyphenation at AX-XXXL](home-fr-accessibility-xxxl-B-004.png).

[Final native-title measurements](native-title-measurements.tsv) contain all
**92** session/module frames and complete accessibility labels from the four-case
log. The 17-point width is a reference lower bound, not a claim that the native
bar always renders at 17 points. `interfaceLanguage` is the UI language; Study
module titles remain authored in English. French B-003's inline frame remains
314 points wide versus a 342.7-point reference string, and its Study large title
remains 346.3 × 71.7 points at AX-XXXL, under the documented exception.

Reproduce the final run (one simulator, no full suite):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testCategoryTitlesEnglishDefaultSize \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testCategoryTitlesEnglishLargestAccessibilitySize \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testCategoryTitlesFrenchDefaultSize \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testCategoryTitlesFrenchLargestAccessibilitySize \
  -resultBundlePath /tmp/task-52/final-confirmed.xcresult \
  test CODE_SIGNING_ALLOWED=NO
```

The actual run used `nohup`, grep-only polling and a fresh result path, and ended
`XBUILD_EXIT=0`. Full local evidence: `/tmp/task-52/final-confirmed.xcresult`,
`/tmp/task-52/final-confirmed.log`, `/tmp/task-52/final-attachments/`. Use a new
result path when rerunning. Earlier failed/interrupted investigative runs do not
substitute for this final run; their diagnosis is recorded in the task notes.

Other completed checks:

- `node scripts/check-test-guard.mjs --self-test`: passed.
- `node scripts/check-test-guard.mjs --base origin/main --head HEAD`: passed,
  no guarded changes (fetched base `4c9dbc0fb260a70e669f80459e3c197c2816f785`).
- XcodeGen run twice after the scrolling fix using
  `cd apps/apple && /opt/homebrew/bin/xcodegen generate --spec project.yml`:
  `git diff --exit-code -- apps/apple/CanadianHam.xcodeproj` stayed empty after
  each generation.
- `git diff --check`: passed.
- No macOS, tvOS, visionOS, Pro Max, full app suites or figure suites were run
  for this task. Only iOS UI-test sources/test resources changed; no app code
  remains changed. The narrower Pro portrait layout and forced regular-width
  landscape sidebar are the intended iPhone coverage. No other build was
  interrupted; shared-lock waits were respected.
