# Apple accessibility audit findings

Generated during T-516 fix round 5 on `feat/t516-apple-design-engine` with the iPhone 17 Pro simulator using `performAccessibilityAudit()` in light and dark appearances.

Code commit used for the run: `aa72925aee9bde6f16188e0b77707feb1a9776cf`.

Result bundle from the passing three-iteration iOS run: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-foyispdmcaiqxiclpwvlsywtmrxg/Logs/Test/Test-CanadianHam-2026.09.29_05-56-05--0400.xcresult`

Evidence was attached to the XCTest result and exported with:

```sh
apps/apple/scripts/export_a11y_evidence.sh /Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-foyispdmcaiqxiclpwvlsywtmrxg/Logs/Test/Test-CanadianHam-2026.09.29_05-56-05--0400.xcresult
```

The UI test also writes the same attachment payloads to `NSTemporaryDirectory()/CanadianHamA11yEvidence/<iteration>/` during execution; it does not write directly into this source tree during tests.

## Audit method

Each screen and appearance is audited in two passes:

1. **Top pass**: content at the top/resting position, with the header, question, and first answers below the navigation bar.
2. **Scrolled pass**: content scrolled so the remaining answers, feedback, and Next button are visible.

Before every audit pass, the test records the current real frames for the identified elements of interest. On the answered-practice screen, both passes now record the header, question identifier/stem, answer heading, all answer rows/text/chips, feedback, and Next button. The audit handler matches a finding back to those pre-audit records by accessibility identifier, or by label when no identifier exists.

Bar occlusion is decided only from the pre-audit real frame, never from the audit-reported frame. The raw finding evidence records both frames. An occluded finding is excluded only when the same element was recorded as fully visible in the other pass; this is asserted in the handler. The measured contrast allow-list is empty.

## Summary from the current passing run

| Screen | Appearance | Pass | Iterations | Audit issues reported | Excluded issues | Evidence |
|---|---|---|---:|---:|---:|---|
| Category list | Light | Top | 3 | 0 | 0 | exported `category-list-light-top-iteration-*` attachments |
| Category list | Light | Scrolled | 3 | 0 | 0 | exported `category-list-light-scrolled-iteration-*` attachments |
| Category list | Dark | Top | 3 | 0 | 0 | exported `category-list-dark-top-iteration-*` attachments |
| Category list | Dark | Scrolled | 3 | 0 | 0 | exported `category-list-dark-scrolled-iteration-*` attachments |
| Answered practice | Light | Top | 3 | 0 | 0 | exported `answered-practice-light-top-iteration-*question-B-001-001-004*` attachments |
| Answered practice | Light | Scrolled | 3 | 0 | 0 | exported `answered-practice-light-scrolled-iteration-*question-B-001-001-004*` attachments |
| Answered practice | Dark | Top | 3 | 0 | 0 | exported `answered-practice-dark-top-iteration-*question-B-001-001-004*` attachments |
| Answered practice | Dark | Scrolled | 3 | 1 per iteration | 1 per iteration | exported `answered-practice-dark-scrolled-iteration-*question-B-001-001-004*` attachments |

## Per-finding table

| Screen | Appearance | Pass | Iteration/question | Identifier | Type | Audit-reported frame | Recorded real frame | Other-pass proof | Verdict | Action |
|---|---|---|---|---|---|---|---|---|---|---|
| Answered practice | Dark | Scrolled | `2026-09-29T095633-766Z-9BF9E62A` / `B-001-001-004` | `question-identifier` | Contrast | `x=40.0, y=204.6, w=136.7, h=20.3` | `x=40.0, y=16.6, w=136.7, h=20.3`; intersects status bar `y=0.0...62.0` and is below `navBar.maxY=116.0` only in the top pass. | Top-pass position log records `question-identifier` fully visible at `x=40.0, y=432.3, w=136.7, h=20.3`. | Bar-occluded false positive | Excluded as `occluded-by-bar`; no allow-list tuple used. |
| Answered practice | Dark | Scrolled | `2026-09-29T100404-968Z-E21B3F63` / `B-001-001-004` | `question-identifier` | Contrast | `x=40.0, y=204.6, w=136.7, h=20.3` | `x=40.0, y=16.6, w=136.7, h=20.3`; intersects status bar `y=0.0...62.0` and is below `navBar.maxY=116.0` only in the top pass. | Top-pass position log records `question-identifier` fully visible at `x=40.0, y=432.3, w=136.7, h=20.3`. | Bar-occluded false positive | Excluded as `occluded-by-bar`; no allow-list tuple used. |
| Answered practice | Dark | Scrolled | `2026-09-29T101147-028Z-6A95DADC` / `B-001-001-004` | `question-identifier` | Contrast | `x=40.0, y=204.6, w=136.7, h=20.3` | `x=40.0, y=16.6, w=136.7, h=20.3`; intersects status bar `y=0.0...62.0` and is below `navBar.maxY=116.0` only in the top pass. | Top-pass position log records `question-identifier` fully visible at `x=40.0, y=432.3, w=136.7, h=20.3`. | Bar-occluded false positive | Excluded as `occluded-by-bar`; no allow-list tuple used. |

No measured contrast exclusions were used. The allow-list is empty in the committed test code.

## Measurement command

```sh
apps/apple/scripts/measure_a11y_contrast.py apps/apple/docs/a11y-evidence
```

Output:

```text
| Screen | Appearance | Pass | Iteration | Question | Issue | Identifier | Label | Frame (pt) | Measured ratio | Text/background clusters | Samples |
|---|---|---|---|---|---|---|---|---|---:|---|---:|
| answered-practice | dark | scrolled | 2026-09-29T095633-766Z-9BF9E62A | B-001-001-004 | Issue 1 | question-identifier | B-001-001-004 | x=40.0, y=204.6, w=136.7, h=20.3 | REFUSED | refused: audit-reported frame and recorded real frame differ by more than 4.0pt (reported=Rect(x=40.0, y=204.6057942708333, width=136.66666666666666, height=20.333333333333314), recorded=Rect(x=40.0, y=16.605794270833314, width=136.66666666666666, height=20.333333333333314), deltas=(0.0, 187.99999999999997, 0.0, 0.0)) | 0 |
| answered-practice | dark | scrolled | 2026-09-29T100404-968Z-E21B3F63 | B-001-001-004 | Issue 1 | question-identifier | B-001-001-004 | x=40.0, y=204.6, w=136.7, h=20.3 | REFUSED | refused: audit-reported frame and recorded real frame differ by more than 4.0pt (reported=Rect(x=40.0, y=204.6057942708333, width=136.66666666666666, height=20.333333333333314), recorded=Rect(x=40.0, y=16.605794270833314, width=136.66666666666666, height=20.333333333333314), deltas=(0.0, 187.99999999999997, 0.0, 0.0)) | 0 |
| answered-practice | dark | scrolled | 2026-09-29T101147-028Z-6A95DADC | B-001-001-004 | Issue 1 | question-identifier | B-001-001-004 | x=40.0, y=204.6, w=136.7, h=20.3 | REFUSED | refused: audit-reported frame and recorded real frame differ by more than 4.0pt (reported=Rect(x=40.0, y=204.6057942708333, width=136.66666666666666, height=20.333333333333314), recorded=Rect(x=40.0, y=16.605794270833314, width=136.66666666666666, height=20.333333333333314), deltas=(0.0, 187.99999999999997, 0.0, 0.0)) | 0 |
```

## Notes

- The hard-coded top padding workaround remains removed. Practice content relies on the standard navigation-bar safe area at scroll position 0.
- Default answer chips use declared `ink`/paper token pairs so dark-mode chips remain visibly distinct.
- Category-list count checks now derive their expected labels from bundled question data, so the first and last category count rows are required and recorded.
- The evidence export script now chooses the implicit latest `.xcresult` by modification time; this run passed the result bundle explicitly.
