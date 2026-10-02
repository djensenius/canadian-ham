---
id: TASK-4
title: Final app icon artwork approval
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 01:55'
labels:
  - design
  - blocked
  - 'legacy:T-011b'
milestone: m-0
dependencies: []
ordinal: 11000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner task. The current generated icon draft (design/app-icon/exports) is wired into all Apple targets, but the final artwork is not approved (the review scored it 5/10). Choose more generated rounds or a hand-drawn SVG, then replace the exports. Legacy: T-011b.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The owner has approved the final icon artwork
- [ ] #2 The exports in design/app-icon/exports are replaced
- [ ] #3 The icon assets are updated in every Apple target and the web manifest
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a deterministic raster brush renderer under design/app-icon/concepts that keeps all output isolated from existing exports/src assets.
2. Generate four ham-radio antenna concepts (Yagi beam, lattice tower + beam, vertical ground-plane, wire dipole) with sumi-e dry-brush texture on the warm cream field.
3. Iterate through at least three render/read critique passes, recording notes in design/app-icon/concepts/README.md and improving small-size readability.
4. Commit the concept generator, concept PNGs/descriptions, comparison sheet, and task notes while leaving task-4 In Progress for owner approval.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Generated four isolated app icon concepts under design/app-icon/concepts with deterministic raster brush script, descriptions, comparison sheet, and three README-recorded render/critique passes. Left task In Progress because AC #1 requires owner approval before exports/assets are replaced.

Round 2: replaced the hairline concept renderer with filled sumi-e stroke construction, regenerated four antenna concepts plus comparison/closeups, and recorded texture-test plus three render/critique passes. Task remains In Progress for owner review.

Round 2 steering: added owner-requested 05-hex-beam concept, expanded comparison.png and closeups.png to five columns/tiles, and kept task In Progress for owner artwork review.

Round 3: replaced the round-2 concept folders with four hex-beam studies, regenerated comparison/closeups, and recorded three render-critique passes. Task remains In Progress for owner artwork review.
<!-- SECTION:NOTES:END -->
