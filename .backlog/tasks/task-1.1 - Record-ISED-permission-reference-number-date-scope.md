---
id: TASK-1.1
title: 'Record ISED permission (reference number, date, scope)'
status: In Progress
assignee:
  - '@djensenius'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 12:37'
labels:
  - release
  - blocked
  - 'legacy:T-007'
milestone: m-0
dependencies: []
parent_task_id: TASK-1
priority: high
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner task. The permission request letter (covering the Basic and Advanced banks) is drafted but not yet sent. Once ISED grants written permission, record the reference number, date and exact scope (including bundling verbatim question text as app data) in docs/content-licensing.md. Blocks every public-release step. Legacy: T-007.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The permission request has been sent to ISED
- [ ] #2 The written permission reference number, date and scope are recorded in docs/content-licensing.md
- [ ] #3 The recorded scope explicitly covers bundling verbatim EN/FR question text in the web and Apple apps
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Record the 2026-10-02 ISED online Crown copyright clearance submission facts in the task notes and mark only AC #1 as satisfied.\n2. Update licensing documentation, requirements, content manifest, and About-page strings/tests to reflect request submitted but permission not granted.\n3. Run web/content/localization/network checks plus Apple xbuild suites, then record validation while leaving task-1.1 In Progress until written permission exists.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
AC #1 evidence: Owner reported submitting the permission request through ISED's online 'Apply for Crown Copyright Clearance' form at https://ised-isde.canada.ca/site/ised/en/apply-crown-copyright-clearance on 2026-10-02 at 08:34 local time. Submitted as applicant type Individual; purpose Reproduction and Adaptation; languages English and French (ISED's own versions); Electronic only; Non-commercial; 1 electronic edition; price 0.00 CAD. Work scope: Basic Qualification Question Bank for Amateur Radio Operator Certificate Examinations (15 July 2025), year 2025, electronic delimited TXT (amat_basic_quest.zip) and PDF, EN/FR, URL https://www.ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/downloads; materials Whole Work, Text, Database. Additional details requested the same permission for the Advanced bank (amat_adv_quest.zip and EN/FR PDFs, current edition and future revisions), publishing question text in the app's public source code, future revisions, and stated the app is always free/open source and collects no data. Not requested: reference sheets/reference PDFs, commercial use, revision, or translation. No confirmation/reference number has been reported; AC #2/#3 remain unchecked until written permission exists.
<!-- SECTION:NOTES:END -->
