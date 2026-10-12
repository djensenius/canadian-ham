---
id: TASK-46.4
title: >-
  Lesson accuracy and coverage fixes: M1 and M2 (within the current reference
  style; the restructure is a separate decision task)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:57'
updated_date: '2026-10-12 15:15'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
priority: high
ordinal: 102000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Apply the High findings (and Medium ones that are a sentence or two) from docs/lesson-review/m1-m2.md. Follow docs/teaching-guide.md and content/lessons/README.md. Verify every new fact against the bank and primary sources (RBR-4, RIC-1, NRC and so on), and check the reference-sheet claims the reviewer could not verify against the ISED reference PDF. Never restate ISED question or answer text. Fix matching explanation files where the review flags them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every High finding in docs/lesson-review/m1-m2.md is fixed (or declined with a recorded reason), with question IDs listed in the notes
- [ ] #2 Every covered question flagged as untaught or answer-key only is now taught with a reason
- [ ] #3 Coverage, quizzes, originality, explanations and links checks pass; the taught-facts check finds no regressions
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Verify the M1/M2 review findings against the active question bank and primary sources, including extracting the ISED reference PDFs for reference-sheet claims.\n2. Make narrow paragraph/table/explanation edits for every High finding, plus quick Medium accuracy/definition/example fixes within current M1/M2 reference style.\n3. Run the required content, link, web, and Swift package checks; fix regressions.\n4. Record finding-by-finding notes with question IDs, source URLs/access dates, checked acceptance criteria, final summary, and mark Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation notes (2026-10-12):\n- High 1 fixed L-001-03 and EXP-B-001-011-010 for B-001-011-010 by changing the distress-interference exception to 'your own station' and adding prose reconciling it with the ordinary no-deliberate-interference rule.\n- High 2 fixed L-001-03 for B-001-011-002/-003/-005/-007 by separating own distress, unanswered distress on an amateur band, and organized relief work.\n- High 3 fixed L-001-03 for B-001-014-001 by adding the supervised non-certified guest / foreign station monitoring rule.\n- High 4 fixed L-001-04 for B-001-018-003/-004 and B-001-008-007 by reframing 29.500 MHz as a repeater-output rule and explicitly keeping the Basic-only operator's own transmissions above 30 MHz unless they have the below-30-MHz gate.\n- High 5 fixed L-001-06 for B-001-023-005/-007/-009, B-001-024-003/-004/-006/-007/-008/-009/-010, and B-001-025-001 through -004 with positive default-consultation elements, controlled/uncontrolled definitions, VHF body-absorption explanation, nerve-stimulation note, hand-held/no-exemption wording, and EMCAB-2 equipment-category explanations.\n- High 6 fixed L-001-05 and EXP-B-001-021-003 for B-001-021-003 by explaining that 7 km offshore Florida is still inside the U.S. territorial sea.\n- Medium quick fixes included: L-001-01 RBR-4/accommodation/RGMC wording (B-001-004-003, B-001-022); L-001-02 2 W, visiting operator, control point, beacon and cross-band definitions (B-001-006-001, B-001-008-007, B-001-009-002); L-001-03 not-protected 902 MHz and secondary 430 MHz wording plus broadcast/privacy distinctions (B-001-010-007/-008/-010, B-001-007-002, B-001-011-004, B-001-012-004); L-001-04 fewer-qualifications, modulation/stability, band-edge, narrow-band, 60 m and power-measurement explanations (B-001-015, -016, -017-006, -019); L-001-05 region and visit-order aids (B-001-021); L-002-01 repeater offset reason, CTCSS, 10-code/plain-language location, sideband anchors and SSB spacing (B-002-001-010, B-002-003-009/-010, B-002-004-003); L-002-02 S9 wording and S-unit quartering example (B-002-006-007/-008); L-002-03 emergency-priority and break-in wording (B-002-008-005/-010); L-002-04 UTC subtract/12-hour bridge (B-002-009).\n- Explanation files fixed where the review flagged ambiguity or missing why: b-001-010-008.json, b-001-011-010.json, b-001-021-003.json.\n- Skipped as out of scope and already assigned: lesson splits/coverage moves (task-46.10), cross-module prerequisite front matter (task-46.11), M1 restructure (task-46.8), M2 format change (task-46.9), Try-it answer hiding (task-46.5), faded practice/stronger concept checks (task-46.6), and interleaving (task-46.7). Low section-order and estimated-minutes changes were also skipped.\n- Source verification: active bank content/generated/basic-2025-07-15/questions.json; ISED question bank source URL https://apc-cap.ic.gc.ca/datafiles/amat_basic_quest.zip; RBR-4 https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service; RIC-1 https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-1-guide-examiners-accredited-conduct-examinations-amateur-radio-operator-certificates; RIC-3 https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-3-information-amateur-radio-service; Health Canada Safety Code 6 https://www.canada.ca/en/health-canada/services/publications/health-risks-safety/limits-human-exposure-radiofrequency-electromagnetic-energy-range-3-300.html; ISED CPC-2-0-03 https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/learn-more/key-documents/procedures/client-procedures-circulars-cpc/cpc-2-0-03-radiocommunication-and-broadcasting-antenna-systems; ISED EMCAB-2 https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/safety-and-compliance/electromagnetic-compatibility-advisory-bulletins-emcab/emcab-2-criteria-resolution-immunity-complaints-involving-fundamental-emissions-radiocommunications; NOAA/U.S. Office of Coast Survey maritime limits https://www.nauticalcharts.noaa.gov/data/us-maritime-limits-and-boundaries.html. All accessed 2026-10-12.\n- Extracted the ISED Basic exam and training reference PDFs from content/sources/ised/basic-2025-07-15/reference/ with Swift/PDFKit to /tmp/ised-basic-exam-reference.txt and /tmp/ised-basic-training-reference.txt. M1/M2 lesson prose has no 'reference sheet' claims; extracted files were checked so none needed updating.
<!-- SECTION:NOTES:END -->
