---
id: TASK-46.4
title: >-
  Lesson accuracy and coverage fixes: M1 and M2 (within the current reference
  style; the restructure is a separate decision task)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:57'
updated_date: '2026-10-12 15:35'
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
- [x] #1 Every High finding in docs/lesson-review/m1-m2.md is fixed (or declined with a recorded reason), with question IDs listed in the notes
- [x] #2 Every covered question flagged as untaught or answer-key only is now taught with a reason
- [x] #3 Coverage, quizzes, originality, explanations and links checks pass; the taught-facts check finds no regressions
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Verify the M1/M2 review findings against the active question bank and primary sources, including extracting the ISED reference PDFs for reference-sheet claims.\n2. Make narrow paragraph/table/explanation edits for every High finding, plus quick Medium accuracy/definition/example fixes within current M1/M2 reference style.\n3. Run the required content, link, web, and Swift package checks; fix regressions.\n4. Record finding-by-finding notes with question IDs, source URLs/access dates, checked acceptance criteria, final summary, and mark Done.

5. Address reviewer request changes after merging main: restore dropped L-002-01 taught facts, fix should/low findings, perform and record an explicit old-vs-new taught-facts line comparison, rerun checks, then refinalize.

6. Apply approve-with-notes items 1-5, rerun requested content checks and web tests, commit, push, open PR, and request Copilot review.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation notes (2026-10-12):\n- High 1 fixed L-001-03 and EXP-B-001-011-010 for B-001-011-010 by changing the distress-interference exception to 'your own station' and adding prose reconciling it with the ordinary no-deliberate-interference rule.\n- High 2 fixed L-001-03 for B-001-011-002/-003/-005/-007 by separating own distress, unanswered distress on an amateur band, and organized relief work.\n- High 3 fixed L-001-03 for B-001-014-001 by adding the supervised non-certified guest / foreign station monitoring rule.\n- High 4 fixed L-001-04 for B-001-018-003/-004 and B-001-008-007 by reframing 29.500 MHz as a repeater-output rule and explicitly keeping the Basic-only operator's own transmissions above 30 MHz unless they have the below-30-MHz gate.\n- High 5 fixed L-001-06 for B-001-023-005/-007/-009, B-001-024-003/-004/-006/-007/-008/-009/-010, and B-001-025-001 through -004 with positive default-consultation elements, controlled/uncontrolled definitions, VHF body-absorption explanation, nerve-stimulation note, hand-held/no-exemption wording, and EMCAB-2 equipment-category explanations.\n- High 6 fixed L-001-05 and EXP-B-001-021-003 for B-001-021-003 by explaining that 7 km offshore Florida is still inside the U.S. territorial sea.\n- Medium quick fixes included: L-001-01 RBR-4/accommodation/RGMC wording (B-001-004-003, B-001-022); L-001-02 2 W, visiting operator, control point, beacon and cross-band definitions (B-001-006-001, B-001-008-007, B-001-009-002); L-001-03 not-protected 902 MHz and secondary 430 MHz wording plus broadcast/privacy distinctions (B-001-010-007/-008/-010, B-001-007-002, B-001-011-004, B-001-012-004); L-001-04 fewer-qualifications, modulation/stability, band-edge, narrow-band, 60 m and power-measurement explanations (B-001-015, -016, -017-006, -019); L-001-05 region and visit-order aids (B-001-021); L-002-01 repeater offset reason, CTCSS, 10-code/plain-language location, sideband anchors and SSB spacing (B-002-001-010, B-002-003-009/-010, B-002-004-003); L-002-02 S9 wording and S-unit quartering example (B-002-006-007/-008); L-002-03 emergency-priority and break-in wording (B-002-008-005/-010); L-002-04 UTC subtract/12-hour bridge (B-002-009).\n- Explanation files fixed where the review flagged ambiguity or missing why: b-001-010-008.json, b-001-011-010.json, b-001-021-003.json.\n- Skipped as out of scope and already assigned: lesson splits/coverage moves (task-46.10), cross-module prerequisite front matter (task-46.11), M1 restructure (task-46.8), M2 format change (task-46.9), Try-it answer hiding (task-46.5), faded practice/stronger concept checks (task-46.6), and interleaving (task-46.7). Low section-order and estimated-minutes changes were also skipped.\n- Source verification: active bank content/generated/basic-2025-07-15/questions.json; ISED question bank source URL https://apc-cap.ic.gc.ca/datafiles/amat_basic_quest.zip; RBR-4 https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service; RIC-1 https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-1-guide-examiners-accredited-conduct-examinations-amateur-radio-operator-certificates; RIC-3 https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-3-information-amateur-radio-service; Health Canada Safety Code 6 https://www.canada.ca/en/health-canada/services/publications/health-risks-safety/limits-human-exposure-radiofrequency-electromagnetic-energy-range-3-300.html; ISED CPC-2-0-03 https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/learn-more/key-documents/procedures/client-procedures-circulars-cpc/cpc-2-0-03-radiocommunication-and-broadcasting-antenna-systems; ISED EMCAB-2 https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/safety-and-compliance/electromagnetic-compatibility-advisory-bulletins-emcab/emcab-2-criteria-resolution-immunity-complaints-involving-fundamental-emissions-radiocommunications; NOAA/U.S. Office of Coast Survey maritime limits https://www.nauticalcharts.noaa.gov/data/us-maritime-limits-and-boundaries.html. All accessed 2026-10-12.\n- Extracted the ISED Basic exam and training reference PDFs from content/sources/ised/basic-2025-07-15/reference/ with Swift/PDFKit to /tmp/ised-basic-exam-reference.txt and /tmp/ised-basic-training-reference.txt. M1/M2 lesson prose has no 'reference sheet' claims; extracted files were checked so none needed updating.

Review-fix notes (2026-10-12): merged origin/main first; task-file conflict kept branch version as instructed. Fixed reviewer blockers/should/low items:
- Restored L-002-01 B-002-001-002 repeater purpose: the repeater increases practical range of portable/mobile stations while keeping the new input/output reason.
- Restored L-002-01 B-002-004-009 SSB spacing from a contact in progress as its own sentence while keeping the new signal-width explanation.
- L-001-01 B-001-022-005 now states the failure condition for oral delivery and that the candidate answers personally in English/French. RIC-1 Issue 8, §6.4 says: "Exams or parts of the exam may be administered orally" and "Exams may be divided into segments that can then be completed at the candidate's own pace"; RIC-1 §7.2 says candidates must understand terminology and technical language "without the need for detailed explanations by the examiner." The bank supplies the written-exam-failure/interpreter discrimination.
- L-002-01 B-002-003-009/-010 now gives a reason for the LSB/USB anchors: expected sideband lets receivers recover normal-sounding audio. I did not add a broad below/above-10-MHz convention as an exam fact because I did not verify it from a current Canadian primary source.
- L-001-06 B-001-025-003/-004 now separates associated equipment from radio-sensitive equipment using the Radiocommunication Act/EMCAB-2 distinction. EMCAB-2 quotes the Act definition: "radio-sensitive equipment means any device, machinery or equipment, other than radio apparatus, the use or functioning of which is or can be adversely affected by radiocommunication emissions"; EMCAB-2 then treats broadcast receivers, associated equipment, and other non-radio electronic equipment separately. This is why I did not use the review's "contains a receiver" shortcut.
- L-001-03 B-001-014-001 row now gives the reason: the certificate holder keeps supervising/monitoring and remains responsible; international third-party traffic also depends on no foreign-administration objection.
- L-001-04 B-001-019-001 crystal-control wording now explains a quartz crystal sets frequency with little drift; B-001-016-006/-007 narrow-segment reason now links tighter bandwidth to SSB not being allowed; B-001-017-006 row reference now matches the Advanced/special-band table row without triggering originality; B-001-018-002 unmodulated-carrier prose now says it is a narrow test allowance, not a frequency-holding/contact permission.
- b-001-010-008.json now uses no-protection wording consistently and gives distinct distractor reasons.
- Low wording fixes: L-001-03 summary no longer says reduced protection; L-001-03 distress prose says "your own station's"; L-002-03 no longer says "the bank calls"; L-001-06 no longer says "in the lesson"; RGMC wording is no longer "named bridge credential"; EMCAB-2 is expanded; nerve stimulation is explained as RF current stimulating nerves. RBR-4 §11 quote checked for 29.5 MHz: "Signals may not be automatically retransmitted in a frequency band below 29.5 MHz unless those signals are received from a station operated by a person qualified to transmit in the frequency bands below 30 MHz."

Real taught-facts old-vs-new comparison for changed lesson lines:
| Lesson/change area | Covered fact(s) taught by old text | New text still teaches |
|---|---|---|
| L-001-01 objective/offence wording | False information, false distress, unlawful obstruction, and due process belong with legal authority/process | Yes: objective still covers offence penalties and due-process protections; table rows unchanged for B-001-001/B-001-003 facts. |
| L-001-01 operating standards row | ISED operating standards provide amateur-station operating standards | Yes: row names RBR-4 as the amateur-service operating standards telling stations how to operate. |
| L-001-01 disability/oral/tailored rows | Exams may be oral/tailored; no exemption from portions; Morse accommodation; oral support for reading/language; interpreter not supported; medical evidence may be requested | Yes: disability row keeps oral/tailored and adds RIC-1 segment example; required portions/Morse/medical rows unchanged; reading/language row adds the written-failure condition; language row says candidate answers personally in English/French with oral delivery as support. |
| L-001-01 RGMC/progression prose | Basic first, later qualifications any order; RGMC can lead to amateur certification; accommodations change delivery only | Yes: all facts remain; prose now describes RGMC as a maritime radio certificate and preserves no-content-exemption point. |
| L-001-01 memory trick | Certificate life and 30-day address deadline; old aside also mentioned 30-minute ID | Yes: certificate life and 30-day address remain here; 30-minute ID remains taught in L-001-03 table and memory trick, so no covered fact is dropped. |
| L-001-02 2 W station row | Low-power amateur station still requires certificate-holder/call-sign supervision | Yes: row now explicitly teaches even a 2 W station needs that supervision. |
| L-001-02 visiting station row | Visitor transmitting from another amateur station and station owner are both responsible | Yes: "visiting operator" replaces misleading "visiting transmitter" while preserving both-responsible fact. |
| L-001-02 station privileges/control prose | Basic enough for some work; repeater/club/home-built/remote-control settings need Basic+Advanced; transmitting station needs control operator at control point; owner responsible; unqualified person needs qualified supervision/presence | Yes: all old facts remain; new prose adds cross-band repeater, beacon, cross-band, and control-point definitions without dropping any privilege/supervision fact. |
| L-001-02 home radio practice | Amateur memories stay in amateur service; check channel; keep background audio/business talk off mic | Yes: new line keeps amateur memories/channel check and specifically says turn down non-amateur background audio. |
| L-001-03 shared-band rows | 430-450 MHz amateurs protect other services; 902-928 MHz had reduced/no protection and licence-exempt occupancy | Yes: 430 row now gives secondary-user reason; 902 row correctly says not protected and still mentions licence-exempt occupancy. |
| L-001-03 distress interference row/prose | Interference exception only in distress involvement; emergency exceptions are narrow; relief-net categories stay separate | Yes: row and prose now specify your own station's direct involvement; emergency prose separates own distress, unanswered distress call, and relief work. |
| L-001-03 third-party guest row | Previously B-001-014-001 was absent | Now taught with reason: keep supervising/monitoring non-certified guest if a foreign station joins because operator remains responsible and foreign objections matter. |
| L-001-03 privacy/payment prose | Amateur message handling is non-commercial; public-service messages can be legitimate; payment/remuneration prohibited | Yes: old facts remain; new prose adds lawful non-broadcast disclosure reasons and media-question exclusion for B-001-012-004. |
| L-001-03 ID memory trick | Identify at start/end and within 30 minutes | Yes: remains; only unrelated 30-day pairing was removed. |
| L-001-04 PEP/ERP/EIRP intro | PEP, ERP, EIRP are distinct quantities; old PEP wording was SSB-only | Yes: PEP is now modulated-envelope crest and power table still applies SSB limits; ERP/EIRP definitions remain. |
| L-001-04 Basic-only repeater rows/prose/summary | Basic-only holders may use repeaters with output at/above 29.500 MHz and 29.500-29.700 output segment; below-30-MHz access normally needs Honours/Advanced/Morse | Yes: repeater fact remains but is correctly framed as output-frequency use, not ordinary below-30-MHz transmitting by the Basic-only operator. |
| L-001-04 stability/modulation rows | Frequency stability equivalent to crystal control below 148 MHz; overmodulation indication/prevention required; voice modulation max 100% | Yes: all facts remain with reasons for crystal stability and overmodulation/splatter. |
| L-001-04 privilege prose | Transmission stays within privileges of operator/call sign governing operation | Yes: fewer-qualifications rule now states this directly for both owner/operator cases. |
| L-001-04 bandwidth/band-edge prose | Occupied signal must stay inside band; signal width matters near edge | Yes: old facts remain; new prose adds HF-edge memory aid and narrow-segment/SSB reason. |
| L-001-04 power prose/example | DC input, carrier power, PEP, ERP/EIRP distinctions; min power and ceilings; 276 W whole-radio supply draw is not final-stage DC input; transmitter/amplifier output measured before tuner | Yes: all old distinctions remain; 100 W RF-output caveat and special-band ERP-as-PEP reason added. |
| L-001-04 repeater/signal-quality prose | Repeater automatic retransmission; unmodulated carrier only brief tests below 30 MHz; frequency measurement/stability/overmodulation remain needed | Yes: all facts remain; new prose clarifies unmodulated-carrier rule as narrow test allowance. |
| L-001-05 objective/region/offshore/location prose | International purpose; ITU role; regions as map references; location can make U.S. limits apply; US/CEPT visit qualification and ID order | Yes: all facts remain; Region 2/1/3 geography, U.S. territorial-sea reason, and home-call/host-prefix memory aid added. |
| L-001-06 objectives/default consultation rows | Antenna authority/process/exclusions/concerns; ISED default-process boundary; exposure framework and factors; EMCAB categories | Yes: objectives still cover those topics; default-process row now states positive elements (written notice, concerns, response opportunity). |
| L-001-06 controlled/uncontrolled row/prose | Safety Code 6 covers controlled and uncontrolled environments | Yes: row/prose still teach both and add uncontrolled public/lower-limit reason. |
| L-001-06 EMCAB rows/prose | Stereo below criterion means lack of immunity; TV above criterion means transmission cause; associated equipment; radio-sensitive equipment | Yes: all rows remain; associated vs RSE distinction now uses EMCAB/Radiocommunication Act categories. |
| L-001-06 antenna process prose | Use local/ISED process/exclusions; written concerns; ISED final decision | Yes: old facts remain; CPC-2-0-03, applicable exemption, and no universal-height shortcut added. |
| L-001-06 RF exposure prose/summary | Human RF exposure, Health Canada code, exposure situations, frequency effects, all transmitter types, power/gain/distance/frequency factors | Yes: all old facts remain; VHF body resonance, low-frequency nerve stimulation, hand-held inclusion/no exemptions, and field/current/SAR summary remain. |
| L-002-01 repeater paragraph | Repeater receives/retransmits; better site extends range of portable/mobile stations | Yes: restored explicit range sentence and kept new separate input/output offset reason. |
| L-002-01 CTCSS row | CTCSS is a low-frequency access tone and expected tone opens repeater audio | Yes: still taught, now adds sub-audible. |
| L-002-01 phonetics/location prose | Use standard phonetics; plain-language location/status on repeaters | Yes: still taught; adds plain location instead of 10-codes for B-002-001-010. |
| L-002-01 sideband paragraph | Upper sideband on 20 m and lower sideband around 3 755 kHz; conventions make signals line up/audio orientation expected | Yes: both anchors remain with SI grouping; reason now says expected sideband gives normal-sounding recovered audio. |
| L-002-01 tuner/spacing paragraph | Tune 3-5 kHz from active net; return when net clear; SSB contacts need about 3 kHz separation from contact in progress | Yes: tuner distance and return condition remain; B-002-004-009 spacing restored as its own sentence. |
| L-002-02 RST table | S9 strength meaning | Yes: updated from weaker wording to conventional "extremely strong." |
| L-002-02 S-unit prose | Stable 10 W to 40 W quadrupling gives about one S-unit | Yes: old example remains; 6 dB=2x2 and downward 60 W to 15 W example added. |
| L-002-03 priority/safety prose/table/summary | Distress before emergency/urgency; safety traffic hazard info; break in between transmissions with call sign/situation; notes/illustration show priority order | Yes: emergency-message priority remains without course meta; safety no longer includes unsupported operating conditions; break-in now matches call sign/situation first. |
| L-002-04 UTC prose/examples | UTC-5 means subtract five hours and adjust date; 2100 UTC to 1600 local; 0300 UTC to previous-date 2200 | Yes: all old UTC facts remain; new text warns not to add and bridges 1600 to 4 PM. |

Validation after review fixes: node packages/content-tools/src/check-lesson-coverage.ts; pnpm --dir packages/content-tools check:quizzes; pnpm --dir packages/content-tools check:lesson-originality:all; pnpm --dir packages/content-tools check:explanations; pnpm check:links; cd apps/web && npx vitest run; DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift all passed on 2026-10-12.

Approve-with-notes follow-up (2026-10-12): applied r464-2 notes 1-5.
- L-001-04 unmodulated-carrier prose is now positive only: it states the allowance is a narrow brief-test allowance in the named range, without restating frequency-holding/contact wrong options.
- L-001-04 special narrow segment now records the verified RBR-4 Schedule I limit: 10.100-10.150 MHz has 1 kHz maximum bandwidth. The prose says that 1 kHz is narrower than an SSB voice signal, so SSB voice is not allowed there. Source: RBR-4, Schedule I frequency bands and bandwidths, item for 10.100-10.150 MHz (accessed 2026-10-12).
- L-001-04 row reference now matches the table wording: the table row is "Advanced on the special band" and the prose refers to "The Advanced on the special band row"; the row itself still teaches that it is on 60 metres.
- L-001-01 language row now says oral delivery may be available after a written-exam failure caused by reading difficulty or because English or French is not the candidate's usual language.
- Correction to the taught-facts table note: the L-001-02 home radio practice row should not have said every old fact stayed in that same sentence. The specific "business talk" phrase was removed from that sentence, but the covered fact is still taught by L-001-02's Communication rules prose and by the business-communications table row, so no taught fact was dropped.
- Validation after approve-with-notes follow-up passed: node packages/content-tools/src/check-lesson-coverage.ts; pnpm --dir packages/content-tools check:quizzes; pnpm --dir packages/content-tools check:lesson-originality:all; pnpm --dir packages/content-tools check:explanations; pnpm check:links; cd apps/web && npx vitest run.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Applied approve-with-notes follow-up items 1-5 after the re-review: positive unmodulated-carrier wording, verified 1 kHz RBR-4 limit for 10.100-10.150 MHz, matching special-band row reference, clearer L-001-01 language-row wording, and taught-facts note correction. Re-ran the requested content checks and web Vitest; all passed. Content-only change; no Apple app suites run.
<!-- SECTION:FINAL_SUMMARY:END -->
