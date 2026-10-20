# TASK-52: iPhone category titles

> **Status: In Progress — continuation required (2026-10-20).** These are
> investigative observations and screenshots, not final acceptance evidence.
> The final helper fixes the font-leading false positive, but the default-size
> regular-width sidebar selector still needs diagnosis. No visual sidebar
> truncation has been established. The final all-four-case run was interrupted
> after that selector failure with coordinator approval. All four cases must be
> rerun after the query fix; no acceptance criterion is checked yet.

## Baseline and navigation-title decision

TASK-55's inline practice navigation title fixes the originally reported English
`Regulations and Polici…` at default text size on iPhone 17 Pro. The full title and
wrapped content header are visible in [the baseline screenshot](session-en-default-B-001.png).
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
ellipsis, using native wrapping/hyphenation. Two host screenshots captured during
the held gesture (after 3- and 7-second capture delays) both show the overlay;
[the later capture is retained here](native-large-content-viewer-fr-accessibility-xxxl-B-003.png).
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

## Validation so far (not final acceptance)

Device: iPhone 17 Pro simulator, iOS 27.0 (24A434). No app-code changes remain.
Committed implementation: `c7365f585c7b48b714a1845e93f57b074516e65d`.
A temporary `testCategoryTitleSidebarDefaultDiagnostic` is uncommitted in the
worktree for the next worker; remove it after the sidebar inspection.

| Case/run | Outcome | Duration | Meaning |
| --- | --- | ---: | --- |
| French AX-XXXL, earlier leading-inclusive helper | Passed | 1278.551 s | All category surfaces passed; this is not the final helper. |
| English AX-XXXL, earlier leading-inclusive helper | Passed | 1383.723 s | All category surfaces passed; this is not the final helper. |
| English default, glyph helper `c7365f58` | Failed | 716.525 s | Home, Practice, all Study/module headers and weak areas passed; a standalone sidebar `StaticText` was not found. |
| All-four final-helper attempt | Interrupted | — | Coordinator approved stopping only our own already-failed run before diagnosing the sidebar selector. |

Other completed checks:

- `node scripts/check-test-guard.mjs --self-test`: passed.
- `node scripts/check-test-guard.mjs --base 4c9dbc0f --head c7365f58`: passed,
  no guarded changes.
- XcodeGen run twice after committing the intended project changes:
  `git diff --exit-code -- apps/apple/CanadianHam.xcodeproj` stayed empty.
- `git diff --check`: passed.
- No macOS, tvOS, visionOS, Pro Max, full app suites or figure suites were run
  for this task. Only iOS UI-test sources/test resources changed; no app code
  remains changed. The narrower Pro portrait layout and forced regular-width
  landscape sidebar are the intended iPhone coverage.

[Historical native-title measurements](native-title-measurements-so-far.tsv)
list 69 observed frames and complete accessibility titles, with the originating
helper/run explicitly identified. The 17-point width is a reference lower bound,
not a claim that the native bar always renders at 17 points. `interfaceLanguage`
is the UI language; Study module titles remain authored in English. This table
must be replaced or supplemented with the final all-four-case measurements.

Full local result bundles/logs are under `/tmp/task-52/`; the continuation steps
and exact probe/rerun commands are in `/tmp/task-52-handoff.md`. The short probe
was cancelled while still waiting for the shared lock, as requested by the
coordinator. The active full `CanadianHamLessonFigures` plan was not interrupted.
