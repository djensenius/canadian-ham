# Apple accessibility audit findings

Generated during T-516 fix round 3 on `feat/t516-apple-design-engine` with the iPhone 17 Pro simulator (iOS 27.0) using `performAccessibilityAudit()` in light and dark appearances.

Result bundle from the passing three-iteration iOS run: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-foyispdmcaiqxiclpwvlsywtmrxg/Logs/Test/Test-CanadianHam-2026.09.29_03-03-25--0400.xcresult`

## Summary

| Screen | Appearance | Audit issues reported | Excluded issues | Evidence |
|---|---:|---:|---:|---|
| Category list | Light | 0 | 0 | `a11y-evidence/category-list-light-accessibility-audit.png`; raw: `a11y-evidence/category-list-light-raw-accessibility-audit-findings.txt` |
| Category list | Dark | 0 | 0 | `a11y-evidence/category-list-dark-accessibility-audit.png`; raw: `a11y-evidence/category-list-dark-raw-accessibility-audit-findings.txt` |
| Answered practice | Light | 4 | 4 | `a11y-evidence/answered-practice-light-accessibility-audit.png`; raw: `a11y-evidence/answered-practice-light-raw-accessibility-audit-findings.txt` |
| Answered practice | Dark | 2 | 2 | `a11y-evidence/answered-practice-dark-accessibility-audit.png`; raw: `a11y-evidence/answered-practice-dark-raw-accessibility-audit-findings.txt` |

The UI test no longer suppresses every audit issue. It fails on any issue except a narrow allow-list keyed by both audit type and element identifier:

- Contrast (`XCUIAccessibilityAuditType(rawValue: 1)`) may be excluded only for identifiers rendered with declared design-token pairs: `practice-category-title`, `practice-category-summary`, `practice-session-tally`, `question-identifier`, `question-stem`, `answers-title`, `answer-A-chip`, `answer-A-text`, `answer-A-status`, `answer-B-chip`, `answer-B-text`, `answer-B-status`, `answer-C-chip`, `answer-C-text`, `answer-C-status`, `answer-D-chip`, `answer-D-text`, `answer-D-status`, `answer-feedback-title`, `answer-feedback-correct-answer`, and `answer-feedback-source`.
- Text clipping (`XCUIAccessibilityAuditType(rawValue: 131072)`) may be excluded only for wrapping answer/feedback text identifiers that are visible and unclipped in the matching screenshot: `question-stem`, `answer-A-text`, `answer-B-text`, `answer-C-text`, `answer-D-text`, `answer-feedback-title`, `answer-feedback-correct-answer`, and `answer-feedback-source`.

Any audit type or identifier outside those sets returns `false` from the handler and fails the test.

## Measurement method

`apps/apple/scripts/measure_a11y_contrast.py` is an offline Python stdlib script. It parses the raw XCTest finding files, converts each PNG screenshot to BMP with `sips`, maps XCTest point frames to screenshot pixels with the exported screen frame, samples pixels inside each reported contrast frame, clusters the darkest and lightest colours, and computes WCAG contrast ratios.

Command used for the current table:

```sh
apps/apple/scripts/measure_a11y_contrast.py apps/apple/docs/a11y-evidence
```

## Per-finding verdicts from the current passing iOS run

| Screen | Finding | Type | Identifier | Measured ratio | Verdict | Action |
|---|---|---|---|---:|---|---|
| Answered practice light | Random practice summary contrast | Contrast | `practice-category-summary` | 21.00:1 | False positive | Excluded by contrast + identifier; token colours exceed WCAG AA and screenshot matches audited state. |
| Answered practice light | Session tally contrast | Contrast | `practice-session-tally` | 20.81:1 | False positive | Excluded by contrast + identifier; token colours exceed WCAG AA and screenshot matches audited state. |
| Answered practice light | Question stem contrast | Contrast | `question-stem` | 16.54:1 | False positive | Excluded by contrast + identifier; token colours exceed WCAG AA and screenshot matches audited state. |
| Answered practice light | Answer D text contrast | Contrast | `answer-D-text` | 13.51:1 | False positive | Excluded by contrast + identifier; token colours exceed WCAG AA and screenshot matches audited state. |
| Answered practice dark | Answer A text clipped | Text clipped | `answer-A-text` | n/a | False positive | Excluded by clipping + identifier; screenshot shows the reported one-line answer text fully visible. Text has no line limit or fixed height. |
| Answered practice dark | Answers title contrast | Contrast | `answers-title` | 14.24:1 | False positive | Excluded by contrast + identifier; token colours exceed WCAG AA and screenshot matches audited state. |

## Root-cause work performed in round 3

- Restored VoiceOver semantics: the visible `Answers` title is a header and is no longer hidden.
- Removed `.accessibilityHidden(true)` from visible text in the practice screen; only the decorative SF Symbol image remains hidden.
- Restored per-element identifiers for practice header text, question text, answer rows/text/chips/status, and feedback text.
- Restored `DesignTokens.FontScale` throughout the practice screen, including serif title/headline use.
- Kept a standard navigation title and added scroll content top spacing so audited content is not hidden under the navigation bar at rest.
- Updated the UI audit to capture screenshots and raw issue descriptions inside the audit path, export them to `apps/apple/docs/a11y-evidence/`, and fail on any non-allow-listed finding.
- Updated answer chip colours to use visibly distinct declared token pairs: semantic chips invert the semantic text/background pair, while default chips keep paper inset/elevated pairs.

## Raw current findings

### Category list, light

```text
Screen: category-list-light
Screen frame: x: 0.0, y: 0.0, width: 402.0, height: 874.0

No accessibility audit issues reported.
```

### Category list, dark

```text
Screen: category-list-dark
Screen frame: x: 0.0, y: 0.0, width: 402.0, height: 874.0

No accessibility audit issues reported.
```

### Answered practice, light

```text
Screen: answered-practice-light
Screen frame: x: 0.0, y: 0.0, width: 402.0, height: 874.0

Issue 1:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier: practice-category-summary
element.label: Random practice from 199 official Basic questions.
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 40.0, y: 38.93912760416666, width: 261.3333333333333, height: 42.33333333333334
compactDescription: Contrast failed

Issue 2:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier: practice-session-tally
element.label: Session tally: 0 correct out of 1 answered
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 40.0, y: 89.2724609375, width: 236.66666666666663, height: 42.333333333333314
compactDescription: Contrast failed

Issue 3:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier: question-stem
element.label: Unless an operator holds an Amateur Radio Operator Certificate with Advanced Qualification, what is the maximum carrier power that an amateur radio station may use on emissions other than SSB?
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 24.0, y: 204.0, width: 354.0, height: 206.0
compactDescription: Contrast failed

Issue 4:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier: answer-D-text
element.label: 750 watts
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 94.0, y: 748.3942057291666, width: 75.33333333333331, height: 20.333333333333485
compactDescription: Contrast failed
```

### Answered practice, dark

```text
Screen: answered-practice-dark
Screen frame: x: 0.0, y: 0.0, width: 402.0, height: 874.0

Issue 1:
auditType: XCUIAccessibilityAuditType(rawValue: 131072)
element.identifier: answer-A-text
element.label: Anywhere in Canada
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 94.0, y: 492.3028971354167, width: 156.0, height: 20.333333333333314
compactDescription: Text clipped

Issue 2:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier: answers-title
element.label: Answers
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 24.0, y: 437.9695638020833, width: 93.0, height: 26.33333333333337
compactDescription: Contrast failed
```

## Evidence files

- `apps/apple/docs/a11y-evidence/category-list-light-accessibility-audit.png`
- `apps/apple/docs/a11y-evidence/category-list-dark-accessibility-audit.png`
- `apps/apple/docs/a11y-evidence/answered-practice-light-accessibility-audit.png`
- `apps/apple/docs/a11y-evidence/answered-practice-dark-accessibility-audit.png`
- Raw text attachments beside each screenshot in `apps/apple/docs/a11y-evidence/`.

## Doc changes needed

None. The current chip colours use existing declared semantic and paper token pairs.
