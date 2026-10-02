---
id: TASK-4
title: Final app icon artwork approval
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 01:26'
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
1. Add a deterministic raster brush renderer under design/app-icon/concepts that keeps all output isolated from existing exports/src assets.\n2. Generate four ham-radio antenna concepts (Yagi beam, lattice tower + beam, vertical ground-plane, wire dipole) with sumi-e dry-brush texture on the warm cream field.\n3. Iterate through at least three render/read critique passes, recording notes in design/app-icon/concepts/README.md and improving small-size readability.\n4. Commit the concept generator, concept PNGs/descriptions, comparison sheet, and task notes while leaving task-4 In Progress for owner approval.
<!-- SECTION:PLAN:END -->
