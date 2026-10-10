---
id: TASK-1.9
title: App Store listing material (EN/FR)
status: Done
assignee:
  - '@worker'
created_date: '2026-10-10 04:04'
updated_date: '2026-10-10 04:35'
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
- [x] #1 docs/release/app-store/ has EN and FR (fr-CA) drafts within Apple's limits: name (30), subtitle (30), promotional text (170), description (4000), keywords (100, comma-separated), what's new for v1; claims are accurate to the shipping v1 (offline, no data collected, Basic course; Advanced, Morse and iCloud described only as they ship)
- [x] #2 Age rating questionnaire answers, the App Privacy answers (consistent with docs/release/privacy-label-evidence.md: Data Not Collected), the category choice, support and marketing URL plan, and the ISED attribution wording for the listing (draft, pending task-1.1 permission)
- [x] #3 A screenshot plan per required device class (iPhone 6.9", iPad 13", Mac, Apple TV, Vision Pro) listing the screens, states, light/dark and EN/FR, with how to capture them using the app's existing DEBUG launch arguments; no screenshots committed yet
- [x] #4 French follows docs/french-style.md, and no wording overclaims accessibility, ISED endorsement or exam outcomes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Draft App Store listing metadata under docs/release/app-store/ in English and fr-CA, with character counts for each limited field and claims limited to the v1 Apple app.
2. Add release/submission support material: age rating, App Privacy answers, category and URL plan, draft ISED attribution, and screenshot capture plan using existing DEBUG launch arguments.
3. Verify French style, Apple field limits, link integrity, and commit the docs-only Backlog updates.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented docs/release/app-store/ with EN and fr-CA metadata drafts, submission notes, and screenshot plan. Validation passed: pnpm check:links; custom character-count/style/overclaim check; git diff --cached --check before commit. No Apple builds/tests were run because this is docs-only.

Review requested changes: platform scope, fr-CA terminology, screenshot capture details, attribution/disclaimer/accessibility wording, keyword and What's New notes. Set task back to In Progress and unchecked AC #1, #3 and #4 before fixing.

Review fixes implemented: platform scope now separates iPhone/iPad/Mac Basic lessons/quizzes/mocks/readiness/full Morse from Apple TV/Vision Pro Basic topic practice and Morse Quick listen; fr-CA copy now uses radioamateurisme, compétence supérieure, Écoute rapide, Police dynamique and no English Advanced/Quick listen/taps terms; screenshot plan names simulators and exact simctl/screencapture steps, removes the sending debug hook from capture args, and documents native Mac Settings capture; ISED keyword removed from keywords; What's New marked as later-release text; age rating notes say to complete App Store Connect's current questionnaire; attribution drafts cover Basic and Advanced and follow-up TASK-35 was created depending on task-1.4. Validation passed: pnpm check:links; field recounts EN 12/30, 23/30, 136/170, 91/100, 242/4000, 1835/4000 and FR 12/30, 22/30, 136/170, 76/100, 277/4000, 2371/4000; copy/style/overclaim/debug-hook check; git diff --check origin/main...HEAD.

Re-review APPROVE WITH NOTES (~/.cache/canadian-ham-reviews/t1.9-r2.md). Coordinator applied the notes in dcc4e12:
- 'conçu'; 'minutage des appuis' (the app's term);
- FR keyword 'radioamateur' added (89/100);
- the What's New 'kept for later' prefix moved out of the counted text (EN 218/4000, FR 235/4000);
- the screenshot plan explains setting the question language to French (no launch argument; don't reset after setting it), says both language arguments are required on TV/Vision, exports Mac progress before reset, uses window capture and activate/delay for Mac Settings, adds the iPad simulator fallback, and adds the short-mock caption caveat.

PR #164 Copilot fixes (b4b109a, coordinator): EN/FR descriptions say the interface and official ISED question banks are bilingual and the original lessons are English-only for now (counts EN 1,941/4,000, FR 2,504/4,000). The screenshot plan drops every question/session limit argument and the iPhone size-class override; the mock result shot uses a real submitted 100-question mock; iPad uses its native regular width.

PR #164 Copilot round 2 (f2e51d0): the Morse copy/exam screenshot row uses real timing; the DEBUG playback and review-duration overrides are listed as forbidden.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Addressed review feedback for task-1.9: corrected platform-scoped listing claims, updated fr-CA terminology to match the app, expanded screenshot capture instructions with simulator names and exact commands, documented native Mac Settings capture, removed the ISED keyword, marked What's New as later-release text, expanded age-rating notes, and created TASK-35 for future Advanced About attribution after permission. Verified with pnpm check:links, limited-field recounts, copy/style/overclaim checks, and git diff --check.
<!-- SECTION:FINAL_SUMMARY:END -->
