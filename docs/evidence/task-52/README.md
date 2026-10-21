# TASK-52: iPhone category titles

> **Dedicated-plan validation passed — 2026-10-21.** All four review-fixed cases
> passed in `CanadianHamTitleSweeps`: English and French at default and
> Accessibility XXXL sizes, including both
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
  preserve the text language and enable native hyphenation only for `fr-CA`,
  as confirmed on screen (`Composants` renders as `Compo-` / `sants` without
  changing the bank text). English measurements do not assume hyphenation.
- **Practice category sessions:** every Basic and Advanced title is checked in
  the native navigation accessibility label and the existing combined content
  header. The header keeps its existing accessibility hierarchy; title bounds
  are inferred from its actual width, serif title font, and content padding.
  The geometry check alone cannot prove title wrapping because the combined
  accessibility element also contains the session tally and summary. Wrapping
  is guaranteed by the title's `lineLimit(nil)` and `.fixedSize(horizontal: false,
  vertical: true)` in `StudyViews.swift:505-506`, together with the screenshots.
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
  reachability by scrolling rather than shrinking them. Unlike the portrait
  card checks, the sidebar does not separately call
  `assertFullyVisibleBelowNavigationBar`: the positioning helper fails unless
  it can place the complete row below the bar, or make an oversized AX row
  reachable within the viewport. The exact text and full-height checks still apply.
- **Mock exam:** source inspection of `MockExamView`, its result breakdown, and
  `QuestionCard` in `StudyViews.swift` confirms that they display category IDs
  (`B-001`, etc.), not the long category names. No category-name layout exists
  there to modify. Existing mock tests/audits are unchanged.

The metric helper measures glyph/line fragments without outer font leading,
which SwiftUI excludes from its text frame. A complete default-size one-line
frame is 20.333 points high; including outer leading incorrectly estimated 22
points. The unchanged 1-point pixel-rounding tolerance cannot hide a missing
line (about 20 points or more). A separate fixture measures the known title
`Station Assembly, Practice and Safety` at 17 pt semibold and 200 pt width with
the same metric helper, verifies that it is exactly two lines, and asserts that
its measured height passes the shared height predicate while a height of
(measured height − one line) fails. This replaces the review's identified no-op
per-element negative check; every sweep executes the fixture before launching
an app. The dedicated-plan rerun below passed with this fixture and French-only
hyphenation.

Four source-named tests in `CanadianHamPracticeUITests` cover English and French
at default size and `UICTContentSizeCategoryAccessibilityXXXL`. Appearance is
fixed to light for each test; it is never toggled while an app is running. All
pre-existing tests, audits, and shared helpers remain byte-identical. The four
sweeps run only in `CanadianHamTitleSweeps`, are excluded from
`CanadianHamDefault`, and have code coverage disabled. See AGENTS.md for the
category-title/layout change triggers and release-candidate requirement.

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

## Visually truncated native titles (width-derived inventory)

The following explicit inventory is derived from the frames in
[native-title-measurements.tsv](native-title-measurements.tsv). These are the
**native navigation titles only**; every corresponding full accessibility label
and same-screen content header passed. Category cards, lists and content headers
are not covered by the exception. IDs below identify the exact full labels in
the TSV, not abbreviated strings supplied by the app.

### Inline practice-session titles

The cut titles reach the 314-pt frame cap. At default size their 17-pt reference
width exceeds that cap; at AX-XXXL the native text grows (also apparent in the
uncapped short-title frames), so the 17-pt reference alone understates the width.

| UI language | Text size | Visually truncated native titles |
| --- | --- | --- |
| English | Default | A-005 **Transmitters, Modulation and Processing**; A-007 **Feedlines - Matching and Antenna Systems** |
| English | AX-XXXL | B-003 **Station Assembly, Practice and Safety**; A-002 **Advanced Components and Circuits**; A-005 **Transmitters, Modulation and Processing**; A-007 **Feedlines - Matching and Antenna Systems** |
| French | Default | B-003 **Montage d'une station, pratique et sécurité**; B-006 **Descentes d'antenne et systèmes d'antenne**; B-007 **Propagation des ondes radioélectriques**; A-002 **Notions avancées sur les composants et les circuits**; A-007 **Descentes d'antenne - adaptation et systèmes d'antenne** |
| French | AX-XXXL | B-003 **Montage d'une station, pratique et sécurité**; B-005 **Éléments et théorie de l'électronique**; B-006 **Descentes d'antenne et systèmes d'antenne**; B-007 **Propagation des ondes radioélectriques**; A-002 **Notions avancées sur les composants et les circuits**; A-005 **Émetteurs, modulation et traitement**; A-007 **Descentes d'antenne - adaptation et systèmes d'antenne** |

All other inline category titles fit at the indicated language/size.

### Study module large titles

**Nearly every Study module large title is visually cut even at default size, in
both UI languages.** The titles remain English in the French UI. The default
large-title font is about 34 pt, not the TSV's 17-pt reference: single-line widths
are approximately twice that column. Seven titles exceed their approximately
351–364-pt frames. Only B-004 fits (316.7 pt). At AX-XXXL even B-004 reaches the
available width instead of its full large-font width; all eight titles are cut.

| Native module title (both English and French UI) | Default visually truncated | AX-XXXL visually truncated |
| --- | --- | --- |
| B-001 Regulations and Policies | Yes | Yes |
| B-002 Operating and Procedures | Yes | Yes |
| B-003 Station Assembly, Practice and Safety | Yes | Yes |
| B-004 Circuit Components | **No** | Yes |
| B-005 Basic Electronics and Theory | Yes | Yes |
| B-006 Feedlines and Antenna Systems | Yes | Yes |
| B-007 Radio Wave Propagation | Yes | Yes |
| B-008 Interference and Suppression | Yes | Yes |

This is a width-derived exception inventory, not a claim of per-row OCR. The
screenshots show representative inline and large-title ellipses and the complete
wrapped content headers, so the owner can revisit the exception with its full
scope visible.

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

## Baseline validation (before review fixes)

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

## Review-fixed dedicated-plan validation

All four sweeps passed in **one run** of `CanadianHamTitleSweeps` at implementation
commit `cdd2b25e618b0af59194d82d40f2d752a2ee367e`, on the same iPhone 17 Pro
simulator / iOS 27.0 (24A434), device ID
`DFEE5295-C8D6-4B87-8A04-1A15AF991B3E`. The plan selects only these four tests and
has code coverage disabled. [Review-run summary](review-test-summary.json) and
[per-test results](review-per-test-results.json) are extracted from the result
bundle, separately from the historical baseline JSON and images above.

| `CanadianHamPracticeUITests` case | Outcome | Duration |
| --- | --- | ---: |
| `testCategoryTitlesEnglishDefaultSize` | Passed | 673.640 s |
| `testCategoryTitlesEnglishLargestAccessibilitySize` | Passed | 1243.685 s |
| `testCategoryTitlesFrenchDefaultSize` | Passed | 689.232 s |
| `testCategoryTitlesFrenchLargestAccessibilitySize` | Passed | 1357.641 s |

`xcresulttool` confirms **4 passed, 0 failed, 0 skipped** and the environment
`CanadianHamTitleSweeps`. Each case again retained 77 screenshots. All 92 native
navigation widths and full labels exactly match the retained baseline TSV;
height values match within 1e-9 pt (only floating-point serialization differs).
Thus the width-derived truncation inventory remains unchanged. The measured
two-line negative fixture runs in each sweep, and English now has hyphenation
disabled; all strict full-text/height checks still pass. No app code changed.

The default-plan exclusion probe is queued on the shared build lock. It selects
the same four methods with `-only-testing:` under `CanadianHamDefault` and must
execute zero tests; its result will be recorded before finalizing these fixes.

Reproduce the review-fixed dedicated-plan run (one simulator, all four sweeps,
no full suite):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -testPlan CanadianHamTitleSweeps \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO \
  -resultBundlePath /tmp/task-52/title-sweeps-review.xcresult \
  test CODE_SIGNING_ALLOWED=NO
```

The review-fixed run used `nohup`, grep-only polling and a fresh result path, and
ended `XBUILD_EXIT=0`. Full local evidence:
`/tmp/task-52/title-sweeps-review.xcresult` and
`/tmp/task-52/title-sweeps-review.log`. Historical baseline evidence remains at
`/tmp/task-52/final-confirmed.xcresult`, `/tmp/task-52/final-confirmed.log`, and
`/tmp/task-52/final-attachments/`. Use a new result path when rerunning. Earlier
failed/interrupted investigative runs do not substitute for these successful
runs; their diagnosis is recorded in the task notes.

Other baseline checks (review-fix checks are recorded below):

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
