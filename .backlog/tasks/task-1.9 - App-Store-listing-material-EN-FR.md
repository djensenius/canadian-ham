---
id: TASK-1.9
title: App Store listing material (EN/FR)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 04:04'
updated_date: '2026-10-10 04:05'
labels: []
dependencies: []
parent_task_id: TASK-1
priority: medium
ordinal: 73000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: v1 needs App Store Connect metadata ready for the day ISED permission arrives. Draft the listing so release isn't blocked on copywriting. Nothing is submitted or published (the repo stays private until task-1.7).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 docs/release/app-store/ has EN and FR (fr-CA) drafts within Apple's limits: name (30), subtitle (30), promotional text (170), description (4000), keywords (100, comma-separated), what's new for v1; claims are accurate to the shipping v1 (offline, no data collected, Basic course; Advanced, Morse and iCloud described only as they ship)
- [ ] #2 Age rating questionnaire answers, the App Privacy answers (consistent with docs/release/privacy-label-evidence.md: Data Not Collected), the category choice, support and marketing URL plan, and the ISED attribution wording for the listing (draft, pending task-1.1 permission)
- [ ] #3 A screenshot plan per required device class (iPhone 6.9", iPad 13", Mac, Apple TV, Vision Pro) listing the screens, states, light/dark and EN/FR, with how to capture them using the app's existing DEBUG launch arguments; no screenshots committed yet
- [ ] #4 French follows docs/french-style.md, and no wording overclaims accessibility, ISED endorsement or exam outcomes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Draft App Store listing metadata under docs/release/app-store/ in English and fr-CA, with character counts for each limited field and claims limited to the v1 Apple app.\n2. Add release/submission support material: age rating, App Privacy answers, category and URL plan, draft ISED attribution, and screenshot capture plan using existing DEBUG launch arguments.\n3. Verify French style, Apple field limits, link integrity, and commit the docs-only Backlog updates.
<!-- SECTION:PLAN:END -->
