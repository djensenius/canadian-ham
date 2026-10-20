---
id: TASK-46.12
title: Realign lesson figures after the TASK-46.10 coverage split
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-19 23:09'
updated_date: '2026-10-20 04:24'
labels:
  - content
dependencies:
  - TASK-46.10
parent_task_id: TASK-46
ordinal: 138000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
PR #302 review identified two figure/lesson mismatches after the lesson split: transformer-resonance-meters in L-005-06 still contains a resonance panel and high-impedance-at-resonance brief although resonance is now taught in L-005-05; communications-flowchart in L-001-03 retains a third-party lane although B-001-014 is now taught in L-001-05. Keep the diagrams, text equivalents and briefs aligned with the material taught in each lesson without changing official question-bank text.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The transformer/resonance/meters figure and its brief/text equivalent match their host lesson; resonance is explained with the L-005-05 material rather than presented as already taught in L-005-06.
- [ ] #2 The communications flowchart, brief and text equivalent in L-001-03 no longer assume the third-party rules taught later in L-001-05.
- [ ] #3 Figure, content-link and targeted lesson-figure accessibility checks pass for the changed figures/lessons.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the affected lessons, figures and UI-test specs; move the parallel LC panel into an original resonance figure for L-005-05 if no existing figure covers it.
2. Rework the transformer/meters and communications figures, synchronizing lesson directives, author briefs, text equivalents and UI-test expectations without changing bank text or coverage.
3. Regenerate Apple assets, render and inspect changed SVGs, run the requested content/package checks and targeted iPhone figure audits, then record evidence, commit and push for internal review.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation: split the original parallel LC panel into parallel-lc-resonance and placed it beside the resonance explanation in L-005-05; no existing figure covered resonance. Kept the stable transformer-resonance-meters id, removed its LC content and tightened its layout to transformers/meters only in L-005-06. Removed the third-party lane from communications-flowchart in L-001-03. Synchronized all three directives, briefs, text equivalents, Apple vector assets/metadata, and UI-test specs; added Module5 LightPart5 so both split lessons remain audited. No question-bank, coverage, quiz or prerequisite changes.
Validation so far: figure fix/check (39 SVGs/references) and checker self-test (53 fixtures), links, all-lesson originality (0 issues), complete hints (984/984), coverage (100/100, no duplicates), and pnpm test pass (153 content-tools, 21 Morse engine, 127 calculator engine, 223 web). qlmanage -t -s 800 rendered all three changed SVGs into /tmp/f4612; opened every PNG and confirmed clear labels, circuit connections, two remaining communications lanes and no clipping. Artwork remains currentColor-only; real app supplies token ink/cream.
Extra teaching-guide validation: swift test --package-path packages/content-swift ran 23 tests, 22 passed; testLoadsRealRepositoryContent has three pre-existing failures at lines 15-17 expecting 36 lessons/orderedLessons/quizzes while the existing TASK-46.10 split gives 37. These source assertions are unchanged from base a056c773; this task adds no lesson or quiz files. All-lesson Markdown parsing and shared figure fixtures pass. Kept this unrelated issue out of scope and notified coordinator. Targeted iPhone 17 Pro figure audits are running via nohup/xbuild; waited for the shared build lock without interfering with other builds.
<!-- SECTION:NOTES:END -->
