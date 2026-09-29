# Apple accessibility audit findings

Generated during the T-516 fix round on iPhone 17 Pro simulator (iOS 27.0) using `performAccessibilityAudit()` with the default audit type set in both light and dark appearances.

Result bundle: `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-foyispdmcaiqxiclpwvlsywtmrxg/Logs/Test/Test-CanadianHam-2026.09.29_02-09-17--0400.xcresult`

## Summary

| Screen | Appearance | Audit issues reported | Excluded issues | Evidence |
|---|---:|---:|---:|---|
| Category list | Light | 0 | 0 | `a11y-evidence/category-list-light-accessibility-audit.png`; raw: `a11y-evidence/category-list-light-raw-accessibility-audit-findings.txt` |
| Category list | Dark | 0 | 0 | `a11y-evidence/category-list-dark-accessibility-audit.png`; raw: `a11y-evidence/category-list-dark-raw-accessibility-audit-findings.txt` |
| Answered practice | Light | 8 | 0 | `a11y-evidence/answered-practice-light-accessibility-audit.png`; raw: `a11y-evidence/answered-practice-light-raw-accessibility-audit-findings.txt` |
| Answered practice | Dark | 11 | 0 | `a11y-evidence/answered-practice-dark-accessibility-audit.png`; raw: `a11y-evidence/answered-practice-dark-raw-accessibility-audit-findings.txt` |

No audit handler exclusions are currently applied. The UI test records findings and screenshots so the remaining checker output is visible in source control. The answered-screen reports below are not framed as fixed or false-positive counts; they are the raw current audit output to re-check in future Xcode/iOS simulator versions.

## Root-cause work performed

- Removed `.disabled(isAnswered)` from answer rows. Taps after answering are ignored in `select(_:)`, and answered rows keep their token colours instead of disabled dimming.
- Moved feedback and `Next question` below the entire answer list.
- Added an opaque iOS navigation-bar background and waits after scrolling so screenshots/audits are captured after the `Next question` control has settled.
- Removed fixed-size text modifiers in the practice screen and verified largest accessibility text size still reaches feedback and `Next question`.
- Changed the row layout so the status label sits below the answer text, reducing horizontal compression.
- Kept the audit call at the default `performAccessibilityAudit()` coverage for light and dark.

## Remaining raw findings

### Category list, light

```text
Screen: category-list-light

No accessibility audit issues reported.
```

### Category list, dark

```text
Screen: category-list-dark

No accessibility audit issues reported.
```

### Answered practice, light

```text
Screen: answered-practice-light

Issue 1:
auditType: XCUIAccessibilityAuditType(rawValue: 131072)
element.identifier:
element.label: Question identifier B-001-006-005
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 40.0, y: 118.63623046874989, width: 136.66666666666666, height: 20.333333333333314
compactDescription: Text clipped

Issue 2:
auditType: XCUIAccessibilityAuditType(rawValue: 131072)
element.identifier:
element.label: except for the amplification of the output power of licence-exempt radio apparatus operating outside authorized amateur radio service allocations
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 94.0, y: 630.3637695312498, width: 261.3333333333333, height: 108.3333333333336
compactDescription: Text clipped

Issue 3:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier:
element.label: Question identifier B-001-006-005
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 40.0, y: 118.63623046874989, width: 136.66666666666666, height: 20.333333333333314
compactDescription: Contrast failed

Issue 4:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier:
element.label: A
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 40.0, y: 369.3333333333333, width: 42.0, height: 42.0
compactDescription: Contrast failed

Issue 5:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier:
element.label: on aeronautical, marine or land mobile frequencies
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 94.0, y: 369.3028971354165, width: 238.33333333333331, height: 42.333333333333314
compactDescription: Contrast failed

Issue 6:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier:
element.label: only if the apparatus is maintained to the performance standards set by Innovation, Science and Economic Development Canada regulations and policies
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 94.0, y: 478.0304361979166, width: 264.6666666666667, height: 108.33333333333343
compactDescription: Contrast failed

Issue 7:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier:
element.label: C
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 40.0, y: 630.3333333333333, width: 42.0, height: 42.0
compactDescription: Contrast nearly passed

Issue 8:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier:
element.label: except for the amplification of the output power of licence-exempt radio apparatus operating outside authorized amateur radio service allocations
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 94.0, y: 630.3637695312498, width: 261.3333333333333, height: 108.3333333333336
compactDescription: Contrast nearly passed
```

### Answered practice, dark

```text
Screen: answered-practice-dark

Issue 1:
auditType: XCUIAccessibilityAuditType(rawValue: 131072)
element.identifier:
element.label: Be at least 14 years of age and a Canadian citizen or permanent resident
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 94.0, y: 732.36376953125, width: 250.0, height: 64.33333333333337
compactDescription: Text clipped

Issue 2:
auditType: XCUIAccessibilityAuditType(rawValue: 131072)
element.identifier:
element.label: Be a Canadian citizen or permanent resident
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 94.0, y: 560.0304361979166, width: 187.33333333333331, height: 42.33333333333337
compactDescription: Text clipped

Issue 3:
auditType: XCUIAccessibilityAuditType(rawValue: 131072)
element.identifier:
element.label: Question identifier B-001-004-007
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 40.0, y: 272.63623046875, width: 136.66666666666666, height: 20.333333333333258
compactDescription: Text clipped

Issue 4:
auditType: XCUIAccessibilityAuditType(rawValue: 131072)
element.identifier:
element.label: Have a valid address in Canada
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 94.0, y: 473.3028971354167, width: 236.66666666666663, height: 20.333333333333144
compactDescription: Text clipped

Issue 5:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier:
element.label: Regulations and Policies
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 40.0, y: 82.30289713541666, width: 318.3333333333333, height: 33.66666666666666
compactDescription: Contrast failed

Issue 6:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier:
element.label: A
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 40.0, y: 473.3333333333333, width: 42.0, height: 42.00000000000006
compactDescription: Contrast failed

Issue 7:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier:
element.label: Have a valid address in Canada
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 94.0, y: 473.3028971354167, width: 236.66666666666663, height: 20.333333333333144
compactDescription: Contrast failed

Issue 8:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier:
element.label: B
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 40.0, y: 560.0, width: 42.0, height: 42.0
compactDescription: Contrast failed

Issue 9:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier:
element.label: C
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 40.0, y: 646.3333333333334, width: 42.0, height: 42.0
compactDescription: Contrast failed

Issue 10:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier:
element.label: Be a Canadian citizen
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 94.0, y: 646.36376953125, width: 163.0, height: 20.33333333333337
compactDescription: Contrast failed

Issue 11:
auditType: XCUIAccessibilityAuditType(rawValue: 1)
element.identifier:
element.label: D
element.elementType: XCUIElementType(rawValue: 48)
element.frame: x: 40.0, y: 732.3333333333334, width: 42.0, height: 42.0
compactDescription: Contrast failed
```

## Evidence files

- `apps/apple/docs/a11y-evidence/category-list-light-accessibility-audit.png`
- `apps/apple/docs/a11y-evidence/category-list-dark-accessibility-audit.png`
- `apps/apple/docs/a11y-evidence/answered-practice-light-accessibility-audit.png`
- `apps/apple/docs/a11y-evidence/answered-practice-dark-accessibility-audit.png`
- Raw text attachments beside each screenshot in `apps/apple/docs/a11y-evidence/`.
