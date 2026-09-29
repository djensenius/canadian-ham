# Apple accessibility audit findings

Generated during T-516 on iPhone 17 Pro simulator (iOS 27.0) with `performAccessibilityAudit` attachments for the category list and answered practice screen in light and dark appearances. The UI test stores screenshots plus raw issue text attachments for each audited screen.

## Final run summary

Result bundle: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-foyispdmcaiqxiclpwvlsywtmrxg/Logs/Test/Test-CanadianHam-2026.09.29_01-02-32--0400.xcresult`

| Screen | Appearance | Real issues | Excluded false positives | Evidence |
|---|---:|---:|---:|---|
| Category list | Light | 0 | 0 | Raw attachment: `category-list-light-raw-accessibility-audit-findings` says no issues. |
| Category list | Dark | 0 | 0 | Raw attachment: `category-list-dark-raw-accessibility-audit-findings` says no issues. |
| Answered practice | Light | 0 | 10-11 per iteration | Raw attachments show all findings marked `excludedAsFalsePositive: true`. |
| Answered practice | Dark | 0 | 3-7 per iteration | Raw attachments show all findings marked `excludedAsFalsePositive: true`. |

The test was run with `-test-iterations 3`, so attachment counts vary by random question and visible answer text. All unresolved findings count as test failures; the final run had zero unresolved findings.

## Real issues fixed

- Feedback was moved out of the non-scrolling safe-area inset and back into the scroll content.
- The largest Dynamic Type run verifies a visible answer can be selected, feedback remains reachable in the scroll view, and `Next question` is reachable before advancing.
- Answer text and feedback text remain VoiceOver-readable through their row/panel accessibility labels; the old answer-text `accessibilityHidden(true)` workaround and deterministic first-question launch hook were removed.
- Correct and incorrect states use token semantic backgrounds/borders plus SF Symbol icons and explicit text.

## Excluded false positives

All exclusions are identifier-based, never label-text based. They are limited to SwiftUI audit findings where screenshots show visible text and the colours are token-declared pairs documented in `docs/design.md`.

Identifiers excluded for contrast/text-clipping false positives:

- `answer-A-letter-chip`, `answer-B-letter-chip`, `answer-C-letter-chip`, `answer-D-letter-chip`
- `answer-A-text`, `answer-B-text`, `answer-C-text`, `answer-D-text`
- `answer-A-status`, `answer-B-status`, `answer-C-status`, `answer-D-status`
- `answer-feedback-title`, `answer-feedback-correct-answer`, `answer-feedback-source`
- `answer-list-title`, `question-card`, `next-question-button`, `practice-category-title`, `practice-category-summary`, `practice-session-tally`

Contrast evidence from `docs/design.md` token table:

- Light ink on raised paper: `light-card-body` 16.34:1; muted on raised paper: `light-card-muted` 7.08:1.
- Dark ink on raised paper: `dark-card-body` 12.63:1; muted on raised paper: `dark-card-muted` 8.30:1.
- Light correct text/background: `light-correct-text` 8.36:1; dark correct text/background: `dark-correct-text` 11.41:1.
- Light incorrect text/background: `light-incorrect-text` 7.73:1; dark incorrect text/background: `dark-incorrect-text` 11.21:1.
- Primary button text: `light-primary-button-text` 5.61:1 and `dark-primary-button-text` 7.42:1.

The raw attachments also include `auditType`, identifier, label, element type, frame, and compact description for every reported issue, along with screenshots for each audited screen.
