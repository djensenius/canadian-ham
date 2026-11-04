---
id: TASK-93
title: Make App Store-eligible packaging the TestFlight default
status: In Progress
assignee:
  - '@worker'
created_date: '2026-11-04T02:25:00Z'
labels:
  - release
  - apple
dependencies:
  - TASK-86
  - TASK-85
priority: high
type: enhancement
ordinal: 176000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner request 2026-11-03: new TestFlight builds should also be eligible for later App Store distribution, and this should be the standard. Existing beta lanes default to internal-only exports and opt in the restricted official reference sheet. Change packaging defaults without changing permission, upload, tester, submission, Xcode Cloud ownership or signing gates. Requested upload is separately blocked by TASK-1.7; export-only preparation is allowed.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All four beta lanes default to App Store-eligible export options and exclude the internal-only official reference sheet; explicit internal-only mode remains available.
- [ ] #2 Invalid and conflicting options fail closed; App Store-eligible uploads and protected distribution artifact uploads remain blocked by existing gates; permitted internal fallback delivery explicitly remains internal-only.
- [ ] #3 Active TestFlight, distribution, owner-gate and agent instructions consistently document the new default, explicit fallback, and unchanged owner/upload/licensing gates.
- [ ] #4 Focused Fastlane, reference-sheet, Xcode Cloud and documentation checks pass and signed export inspection evidence is recorded without claiming an upload.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Default the existing distribution option to true, retaining explicit distribution:false for the internal-only reference-sheet fallback and preserving export-only restrictions. 2. Add focused safety/default-mode tests and align active release documentation and agent guidance, including owner-only Xcode Cloud settings. 3. Run focused local harnesses; obtain independent and Copilot review and green exact-head CI before normal merge. 4. Prepare permitted signed export-only artifacts through xbuild, inspect packaging/privacy/entitlements and record actual evidence. Never upload before existing gates.
<!-- SECTION:PLAN:END -->
