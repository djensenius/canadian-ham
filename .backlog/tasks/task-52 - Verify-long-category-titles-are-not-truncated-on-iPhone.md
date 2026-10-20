---
id: TASK-52
title: Verify long category titles are not truncated on iPhone
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 08:06'
updated_date: '2026-10-20 13:45'
labels:
  - apple
dependencies: []
priority: low
ordinal: 115000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Seen during task-44.3 work: long category titles such as 'Regulations and Policies' appeared truncated ('Regulations and Polici…') in some iPhone layouts. Check every category list, card and header on iPhone at default and large Dynamic Type sizes, and fix any truncation without minimumScaleFactor or layout changes made just to pass tests.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every category title on iPhone wraps or fits at default and accessibility text sizes, with screenshots or a test as evidence
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Verify the TASK-55 default-size baseline and inventory Home, Practice, Study, weak areas, mock category IDs and the regular-width sidebar.
2. Add EN/FR default and AX-XXXL UI coverage for every Basic/Advanced category list/card/session header plus Study/weak-area headers; retain all existing tests and shared helpers unchanged.
3. Apply the coordinator-approved native navigation exception: keep original titles, require complete accessibility labels and wrapped same-screen content headers, document measured ellipses, and check Large Content Viewer behaviour. No app layout changes remain.
4. Run only the added tests through nohup xbuild on iPhone 17 Pro, save screenshots/results in docs/evidence/task-52, verify deterministic project generation, then finalize, commit and push without a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Baseline targeted UI test confirms TASK-55 removed the original default-size English Regulations and Policies truncation; the longer Basic Station Assembly, Practice and Safety navigation title and wrapped content header also fit on iPhone 17 Pro. Continuing largest-accessibility French coverage and all shared category surfaces (including Advanced). Test header identifiers resolve to the existing combined accessibility header; tests preserve that hierarchy and all shared helpers.

Reproduced remaining native inline-navigation truncation in French B-003 at Accessibility XXXL. Regression test detects a 314-pt one-line navigation frame where even 17-pt text requires 342.7 pt; screenshot retained from baseline-fr-ax-3.xcresult. Testing a wrapping principal toolbar Text while retaining the system navigation title, with no font shrinking or point-width rules.

Coordinator decision 2026-10-20 (owner may revisit): retain TASK-55 native inline category navigation titles; the owner previously rejected generic Practice titles. Native inline truncation at accessibility sizes is accepted platform behaviour provided VoiceOver receives the full title and the prominent scrollable header visibly wraps the complete category name. Reverted the multiline principal-toolbar experiment: UIKit constrained the bar and the unscaled AX-XXXL title overflowed (y=-201.7, height=571.3). Tests will assert complete native navigation accessibility labels plus full wrapped content headers and investigate native Large Content Viewer support. No font capping/shrinking, custom navigation bar, or generic title changes approved.

Coordinator clarification 2026-10-20: the native navigation-bar visual-ellipsis exception also applies at default text size wherever long native practice or Study module titles cannot fit. Each case must retain the complete accessibility label and the full wrapped title in the content header on that screen. Cards, lists and content headers retain strict no-truncation checks. Evidence will list the specific titles/sizes so the owner can revisit this decision; French B-003 requires 342.7 pt at 17-pt text versus 314 pt available.
<!-- SECTION:NOTES:END -->
