---
id: TASK-46.11
title: 'Decision: declare cross-module prerequisites in lesson front matter'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:58'
updated_date: '2026-10-13 00:12'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
priority: low
ordinal: 109000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Needs an owner decision; see docs/lesson-review/README.md. Once decided, add the implementation plan and acceptance criteria, or close as declined.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Owner decision recorded
- [ ] #2 Every lesson lists its real cross-module prerequisites; the apps show them; a checker validates they exist
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inventory existing lesson front matter and parser/checker/web paths.
2. Add prerequisite metadata to lessons only where needed, preserving recommended order and no Apple app edits.
3. Extend content tooling/tests to validate prerequisite existence, acyclicity, and ordering.
4. Render prerequisites on the web lesson page with localized EN/FR accessible links.
5. Update lesson README and teaching guide rules, run requested checks, record reasoning/results in Backlog, and commit.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision 2026-10-12: YES. Declare cross-module prerequisites in lesson front matter (teaching-guide front-matter freeze lifted for this field).

Implemented prerequisite reasoning by lesson: L-005-01 none (course starts with units/current); L-005-02 requires L-005-01 units/current; L-005-03 requires L-005-02 Ohm's law and power; L-005-04 requires L-005-03 series/parallel and ratings before AC/dB/reactance; L-005-05 requires L-005-04 AC/reactance before transformers/resonance/meters. L-004-01 requires L-005-02 Ohm's law/power and L-005-04 AC/dB; L-004-02 requires L-004-01 active/diode foundations; L-004-03 now requires L-005-01 prefixes/kilohms and L-005-03 resistor ratings instead of unrelated transistors. L-006-01 requires L-005-04 impedance/reactance vocabulary; L-006-02 requires L-006-01 feedlines plus L-005-04 dB/reactance; L-006-03 requires L-006-02 SWR/matching plus L-005-04 reactance for loading; L-006-04 requires L-006-03 300/f and L-005-04 dB; L-006-05 requires L-006-04 patterns/lengths and L-005-05 resonance for traps. L-003-01 requires L-006-02 SWR/tuners, L-004-01 filters/diodes/amplifier blocks, and L-005-04 harmonics/dB/filter foundations; L-003-02 requires L-003-01 station blocks; L-003-03 requires L-003-02 signal paths, L-004-01 rectification/diodes, and L-005-05 transformers/meters; L-003-04 requires L-003-03 receiver/power context and L-006-04 Yagi parts; L-003-05 requires L-003-04 receiver/spec context; L-003-06 requires L-003-05 signal-quality/mode context; L-003-07 requires L-003-06 station control context, L-003-03 supplies, and L-005-02 power math; L-003-08 requires L-003-07 DC/supply safety and L-006-04 antenna/gain context. L-007-01 requires L-006-03 wavelength and band-name context; L-007-02 requires L-007-01 ionosphere/skip; L-007-03 requires L-007-02 MUF/solar context. L-008-01 requires L-003-01 station filtering, L-003-05 key clicks/splatter and signal quality, L-004-01 non-linear devices/rectification, and L-005-04 ferrite/reactance/dB; L-008-02 requires L-008-01 interference symptoms, L-003-01 low-pass placement, and L-007-01 band/propagation context. L-002-01 requires L-003-05 modes/sideband quality and L-006-02 tuner/dummy-load/SWR context; L-002-02 requires L-002-01 operating procedure and L-005-04 dB for S-units; L-002-03 requires L-002-01 voice procedure and L-003-07 emergency power context; L-002-04 requires L-002-01 operating procedure and L-007-01 path/band context for maps. L-001-01 remains no technical prerequisite because authority/exam rules stand alone; L-001-02 requires L-001-01 authority plus L-003-01 station/control vocabulary; L-001-03 requires L-001-02 station responsibility, L-002-03 emergency procedure, and L-008-01 interference context; L-001-04 requires L-001-03 rule context, L-003-05 emission/modulation quality, L-005-02 power, and L-006-04 antenna gain; L-001-05 requires L-001-04 privileges and L-002-04 location/map terms; L-001-06 requires L-001-05 location/rule context, L-003-08 safety, L-006-04 antenna/gain context, and L-008-01 EMC/interference context. Apple display is deferred until task-38.1 merges because LessonReaderView is being rewritten; no Apple app files were changed, and AC #2 remains unchecked for that reason.

Validation passed: pnpm --dir packages/content-tools check:coverage; pnpm --filter @canadian-ham/content-tools test -- check-lesson-coverage.test.ts; pnpm --filter @canadian-ham/web test -- App.test.tsx; pnpm typecheck; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift. Web prerequisites are shown as localized EN/FR lesson-page links. Apple app UI remains deferred, so task remains In Progress with AC #2 unchecked.

Dependency note: Apple prerequisite display follows task-38.1 because that task rewrites LessonReaderView; this task remains content and web only until then.

Review follow-up applied: L-001-02 now depends on L-001-01, L-002-01 repeaters, and L-003-06 remote control; dropped L-003-01. L-006-04 now directly lists L-005-05 for resonant traps; removed redundant L-005-04 transitive links from L-006-02/-03/-04. L-008-02 dropped redundant L-003-01 and keeps direct L-008-01 plus L-007-01. Checker duplicate lessonIds reporting and prerequisite-order tests were expanded. Web prerequisite links now leave modifier-clicks to the browser for new-tab/window behavior. Validation passed again: pnpm --dir packages/content-tools check:coverage; pnpm --filter @canadian-ham/content-tools test -- check-lesson-coverage.test.ts; pnpm --filter @canadian-ham/web test -- App.test.tsx; pnpm typecheck; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift.

Copilot follow-up PRRT_kwDOUxZq_M6rpOpj addressed: checker now tracks prerequisite IDs per lesson and reports repeated IDs once per repeated prerequisite; added fixture test for duplicate lesson prerequisite IDs. Validation passed: pnpm --dir packages/content-tools check:coverage; pnpm --filter @canadian-ham/content-tools test -- check-lesson-coverage.test.ts; pnpm --filter @canadian-ham/content-tools typecheck.
<!-- SECTION:NOTES:END -->
