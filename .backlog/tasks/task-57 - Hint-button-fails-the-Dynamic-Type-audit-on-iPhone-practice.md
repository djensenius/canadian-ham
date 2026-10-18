---
id: TASK-57
title: Hint button fails the Dynamic Type audit on iPhone practice
status: To Do
assignee: []
created_date: '2026-10-18 05:52'
labels: []
dependencies: []
priority: high
ordinal: 133000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Regression from #279 (task-50.12). On iPhone 17 Pro, main's CanadianHamPracticeUITests testAccessibilityAuditPracticeSessionLight/Dark fail at CanadianHamPracticeUITests.swift:2321 with 'Dynamic Type font sizes are partially unsupported'. The flagged element is the exam-tools row Hint button ('User will not be able to change the font size of this SwiftUI.AccessibilityNode'); the Calculator button with the same style is not flagged. An earlier unexplained minWidth:160 on exam-tool buttons (removed before merge) had masked it. The same finding appears on the iPhone Duo (TASK-55). Evidence: /tmp/t15-reg-main-pro.log and xcresult attachments in /tmp/ax-att.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The root cause of the Hint button Dynamic Type audit finding is identified and fixed in the app, without filtering the audit or adding unexplained fixed widths
- [ ] #2 testAccessibilityAuditPracticeSessionLight/Dark pass on iPhone 17 Pro and the hint audit tests still pass on iPhone 17 Pro and iPad
- [ ] #3 The fix is checked against the TASK-55 Duo Dynamic Type finding, and TASK-55 notes are updated
<!-- AC:END -->
