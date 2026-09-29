# Apple accessibility audit findings

Generated during T-516 fix round 4 on `feat/t516-apple-design-engine` with the iPhone 17 Pro simulator using `performAccessibilityAudit()` in light and dark appearances.

Result bundle from the passing three-iteration iOS run: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-foyispdmcaiqxiclpwvlsywtmrxg/Logs/Test/Test-CanadianHam-2026.09.29_05-09-42--0400.xcresult`

Evidence was attached to the XCTest result and exported with:

```sh
apps/apple/scripts/export_a11y_evidence.sh /Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-foyispdmcaiqxiclpwvlsywtmrxg/Logs/Test/Test-CanadianHam-2026.09.29_05-09-42--0400.xcresult
```

The UI test also writes the same attachment payloads to `NSTemporaryDirectory()/CanadianHamA11yEvidence/<iteration>/` during execution; it no longer writes directly into this source tree.

## Audit method

Each screen and appearance is audited in two passes:

1. **Top pass**: content at the top/resting position, with the header, question, and first answers below the navigation bar.
2. **Scrolled pass**: content scrolled so the remaining answers, feedback, and Next button are visible.

Before every audit pass, the test attaches an `audit-position-log` proving each audited element of interest is either fully below `navigationBar.maxY`/the status bar and inside the window, or entirely off-screen/under the protected top area. The audit handler separately classifies bar-occluded findings from the navigation/status bar frames; such findings are only excluded when the same element is fully visible in the other pass.

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

| Screen | Appearance | Pass | Iteration/question | Identifier | Type | Measured ratio or occlusion proof | Verdict | Action |
|---|---|---|---|---|---|---|---|---|
| Answered practice | Dark | Scrolled | `2026-09-29T091012-803Z-A2F8F23E` / `B-001-001-004` | `question-identifier` | Contrast | 10.82:1, text/background clusters `#FCD8CC / #3C241E`, frame `x=40.0, y=204.6, w=136.7, h=20.3`, 22624 samples; frame is below the nav/status bars. | False positive | Excluded by exact tuple `(answered-practice, dark, question-identifier, .contrast)` with measured evidence. |
| Answered practice | Dark | Scrolled | `2026-09-29T091631-663Z-4C04B90B` / `B-001-001-004` | `question-identifier` | Contrast | 10.82:1, text/background clusters `#FCD8CC / #3C241E`, frame `x=40.0, y=204.6, w=136.7, h=20.3`, 22624 samples; frame is below the nav/status bars. | False positive | Excluded by exact tuple `(answered-practice, dark, question-identifier, .contrast)` with measured evidence. |
| Answered practice | Dark | Scrolled | `2026-09-29T092245-884Z-650BFA43` / `B-001-001-004` | `question-identifier` | Contrast | 10.82:1, text/background clusters `#FCD8CC / #3C241E`, frame `x=40.0, y=204.6, w=136.7, h=20.3`, 22624 samples; frame is below the nav/status bars. | False positive | Excluded by exact tuple `(answered-practice, dark, question-identifier, .contrast)` with measured evidence. |

No bar-occlusion exclusions were needed in the current three-iteration run; all occlusion sections say `Occluded-by-bar findings: none`.

## Measurement command

```sh
apps/apple/scripts/measure_a11y_contrast.py apps/apple/docs/a11y-evidence
```

Output:

```text
| Screen | Appearance | Pass | Iteration | Question | Issue | Identifier | Label | Frame (pt) | Measured ratio | Text/background clusters | Samples |
|---|---|---|---|---|---|---|---|---|---:|---|---:|
| answered-practice | dark | scrolled | 2026-09-29T091012-803Z-A2F8F23E | B-001-001-004 | Issue 1 | question-identifier | B-001-001-004 | x=40.0, y=204.6, w=136.7, h=20.3 | 10.82:1 | #FCD8CC / #3C241E | 22624 |
| answered-practice | dark | scrolled | 2026-09-29T091631-663Z-4C04B90B | B-001-001-004 | Issue 1 | question-identifier | B-001-001-004 | x=40.0, y=204.6, w=136.7, h=20.3 | 10.82:1 | #FCD8CC / #3C241E | 22624 |
| answered-practice | dark | scrolled | 2026-09-29T092245-884Z-650BFA43 | B-001-001-004 | Issue 1 | question-identifier | B-001-001-004 | x=40.0, y=204.6, w=136.7, h=20.3 | 10.82:1 | #FCD8CC / #3C241E | 22624 |
```

## Notes

- The hard-coded top padding workaround was removed. Practice content now relies on the standard navigation-bar safe area at scroll position 0.
- Default answer chips now use declared `ink`/paper token pairs so dark-mode chips remain visibly distinct.
- `.fixedSize(horizontal:vertical:)` was removed from app views; the dedicated largest Dynamic Type UI test uses the longest English answer in the bank (`B-001-022-001`) and verifies the multi-line text exposes its full scrollable height rather than clipping to one line.
