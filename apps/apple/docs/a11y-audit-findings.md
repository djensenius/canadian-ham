# Apple accessibility audit findings

T-516b changes make the default Apple accessibility audit deterministic and fast. The default UI suite now runs a regression audit with `performAccessibilityAudit()` and no allow-list in light and dark appearances for these states:

1. category list;
2. unanswered practice on fixed question `B-001-002-002` (`Regulations and Policies`);
3. answered practice for the same fixed question after selecting the correct answer.

Any audit issue fails the test. The default regression does not collect screenshots, position logs, raw finding attachments, handler screenshots, occlusion records, or measured allow-list evidence.

## Current default audit

- Test: `CanadianHamPracticeUITests.testAccessibilityAuditCategoryListUnansweredAndAnsweredPracticeScreens`
- Fixed practice question: `B-001-002-002`
- Appearances: light and dark
- Audit states per appearance: category list, unanswered practice, answered practice
- Allow-list: none
- Expected default evidence output: none beyond normal XCTest pass/fail output

The fast audit intentionally avoids the prior two-pass scrolled/occlusion workflow. If `performAccessibilityAudit()` reports a real issue in the default test, fix the UI rather than excluding the finding.

## Root cause of the T-516 audit flake

In the scrolled pass, elements sat under the navigation/status bars. `performAccessibilityAudit()` scrolled the `ScrollView` about 188 pt to reveal them, so contrast was sampled on other elements in mid-scroll or shifted positions. The reported frames matched the pre-audit records +188 pt, and the fully visible `answers-title` and answer C/D elements failed. The default audit now runs only at scroll offset 0, in a fixed answered state, where no element is under the bars.

## Test timings

Before timings are from the coordinator run on main at merge `88ff987`. After timings are from coordinator runs 1-3 on `4c004e9`, using the default full iOS suite; all three after runs passed.

| Test | Before | After runs 1 / 2 / 3 |
| --- | ---: | ---: |
| Accessibility audit | 254.9 s (flaky) | 57 / 51 / 56 s |
| French practice | 19.8 s | 25.3 / 24.6 / 24.4 s |
| Language picker | 30.2 s | 35.8 / 38.2 / 31.8 s |
| Longest answer | 27.2 s | 33.9 / 31.4 / 30.2 s |
| Largest text flow | 62.6 s | 80.7 / 79.6 / 62.5 s |
| Unit tests | < 1 s | < 2 s |

## Opt-in diagnostic harness

The heavier T-516 evidence harness is kept as an opt-in diagnostic and is skipped by default:

```sh
CANADIAN_HAM_RUN_A11Y_DIAGNOSTICS=1 DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testA11yDiagnosticsEvidenceHarness test CODE_SIGNING_ALLOWED=NO
```

After a diagnostic run, export attachments with:

```sh
apps/apple/scripts/export_a11y_evidence.sh /path/to/Test-CanadianHam-....xcresult
```

The diagnostic writes the same attachment payloads to `NSTemporaryDirectory()/CanadianHamA11yEvidence/<iteration>/` during execution; it does not write directly into this source tree during tests.

## Contrast measurement command

For diagnostic evidence that contains contrast findings, the measurement script samples screenshot pixels from the exported evidence directory. Expected token pairs are used only as labels for known elements; the reported ratio is computed from sampled pixels.

```sh
apps/apple/scripts/measure_a11y_contrast.py apps/apple/docs/a11y-evidence
```

Occluded element frames or mismatched audit-reported/recorded frames are refused instead of measured.

## Historical T-516 evidence

The committed `apps/apple/docs/a11y-evidence/` files are historical T-516 diagnostic evidence. T-516b did not refresh them because the opt-in diagnostic harness was not re-run after the redirect, so this evidence should be verified before relying on it.
