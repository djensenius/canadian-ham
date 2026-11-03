# M2 explanatory rewrite: taught-facts comparison (TASK-46.9)

## Baseline recorded before rewriting

Baseline: branch `task-46.9-m2-lessons`, starting commit `4c9dbc0f` (2026-10-20). Read all four lesson bodies and compared their teaching with every M2 record in `content/generated/basic-2025-07-15/questions.json`. The four unchanged official quiz lists contain 44 + 33 + 11 + 11 = 99 questions. The ledger below paraphrases teaching facts; it does not reproduce bank questions or answers.

All four lessons have `title.fr: null`. No French lesson bodies or French concept checks exist to update. Keep bilingual JSON fields with `fr: null`; do not create a translation in this task.

The original review is historical: [m1-m2.md](m1-m2.md). This ledger records the later format change, not new scores for that review.

## Lesson 1: L-002-01

| Bank IDs (suffixes within B-002) | Taught facts extracted from the old lesson | Revised teaching location / comparison |
|---|---|---|
| 001-001, 001-006, 003-011 | Directed voice calls name the destination before the caller; use “this is” to separate them. | Retained — Tell listeners who you want. |
| 001-002 | A well-sited repeater extends portable/mobile range by receiving and retransmitting on separate frequencies; separation prevents its transmitter blocking its receiver. | Retained — Choose a relay or a direct path. |
| 001-003 | VHF/UHF coordination recommends repeater channels to reduce neighbouring-system interference. | Retained — Choose a relay or a direct path. |
| 001-004, 001-007, 001-008, 001-009 | Listen, pause between overs, keep them short for others including emergencies; the timer cuts long transmissions; join with your call sign in a gap. | Retained — Leave room on the repeater. |
| 001-005, 001-011 | CTCSS is a low-frequency sub-audible access tone; matching output, input, tone and offset matters. Two-metre FM offset is 600 kHz; negative offset subtracts it. | Retained — Choose a relay or a direct path; Worked example: setting a negative offset. |
| 001-010 | Ask for location in plain words rather than 10-codes. | Retained — Use plain language for location (separate from the joining worked example). |
| 002-001 through 002-011 | ITU phonetics improve identification; A Alfa, B Bravo, D Delta, E Echo, G Golf, I India, L Lima, P Papa, R Romeo; full alphabet also supplied. | Retained — Make the call sign easy to copy. |
| 003-001, 003-002 | Voice CQ repeats CQ three times and the caller three times; answer with the other call once, “this is”, own call. | Retained — Tell listeners who you want. |
| 003-003, 003-004, 003-007 | Simplex uses a shared transmit/receive frequency; use it when direct copy is reliable; listen on the repeater input to test direct reception. | Retained — Use simplex for a direct path (its own concept heading, outside the offset worked example). |
| 003-005, 003-006, 003-008 | Prefer VHF/UHF for suitable local work; protect HF capacity. Avoid repeater inputs when choosing simplex and move if interfering with a repeater. | Retained — Use simplex for a direct path. |
| 003-009, 003-010 | Twenty-metre voice normally uses USB; the 3 755 kHz example uses LSB. | Retained — Give a voice signal enough space (adds the practical sideband convention). |
| 004-001, 004-011 | Listen before transmitting to protect existing contacts. | Retained — Leave room on the repeater; Give a voice signal enough space. |
| 004-002 | Reduce excessive power while preserving reliable copy. | Retained — Share the frequency, not just the microphone. |
| 004-003, 004-009 | Brief HF net tuner checks use a clear spot 3–5 kHz away; SSB needs roughly 3 kHz separation because it occupies about that width. | Retained — Give a voice signal enough space. |
| 004-004, 004-005 | A dummy load absorbs RF as heat for long tests without radiating test signals. | Retained — Give a voice signal enough space. |
| 004-006, 004-007, 004-008 | Nets do not own frequencies; net control asks current users or moves. Current users accommodate a starting net; increasing interference calls for a move. | Retained — Share the frequency, not just the microphone. |
| 004-010 | Band plans voluntarily group compatible modes and activities. | Retained — Share the frequency, not just the microphone. |

## Lesson 2: L-002-02

| Bank IDs (suffixes within B-002) | Taught facts extracted from the old lesson | Revised teaching location / comparison |
|---|---|---|
| 005-001, 005-002, 005-003 | Morse CQ repeats CQ and the caller three times around DE; a reply repeats each call twice around DE. Call no faster than you can receive. | Retained — Build a contact from small pieces; Worked example: follow the direction of a reply. |
| 005-004 through 005-009, 005-011 | CQ invites all; DE marks the sender; K invites a reply; R confirms complete receipt; DX refers to distant stations; 73 closes with good wishes; QSK permits reception between keying elements. | Retained — Use short groups for clear jobs. |
| 005-010 | CW spacing is 150–500 Hz from an existing contact. | Retained — Use short groups for clear jobs. |
| 006-001, 006-002, 006-003, 006-004, 006-009, 006-010, 006-011 | Reports describe reception: R readability, S strength, T keyed-signal tone. Voice omits T. R1 unreadable, R3 readable with considerable difficulty, R4 quite readable with practically no difficulty, R5 perfect; S1 faint signals, barely perceptible, S3 weak, S5 fair, S7 moderately strong, S9 extremely strong; T9 clean tone. | Retained — Report what reaches your receiver (scale table); Voice reports use readability and strength; Worked example: keep the three observations separate (R4 now unambiguously practically no difficulty). |
| 006-005 | A dB suffix measures strength above S9. | Retained — Read strength above S9 (separate from the worked example). |
| 006-006 | Repeater reports describe the relayed audio actually heard, not the remote input signal. | Retained — Reports through a repeater (separate from the worked example). |
| 006-007, 006-008 | In the calibrated, stable-path model, each S-unit is 6 dB: two approximate power doublings or halvings; power ratio four upward, quarter downward. Real paths/meters limit the shortcut. | Retained — Connect meter steps to power ratios; Worked examples: predicting a rise / predicting a fall (both directions shown). |
| 007-001, 007-009 | QRS requests slower sending. | Retained — Choose Q signals by the task. |
| 007-002, 007-003, 007-004, 007-005 | QTH location, QRL? busy check, QSY frequency change, QSB fading. | Retained — Choose Q signals by the task. |
| 007-006, 007-010, 007-011 | QRZ? asks the unidentified caller to identify; QRX signals a later call. | Retained — Choose Q signals by the task. |
| 007-007, 007-008 | QRM interference from other signals; QRN natural noise/static. | Retained — Choose Q signals by the task. |
| Additional old teaching, no extra quiz mapping | QRV? readiness; QRU? pending traffic; QRT stop; QSL? acknowledge; QRK readability; QRP reduce/low power. Question marks distinguish questions from statements. Give honest reports rather than automatic perfect reports. Old memory cues pair QRM/man-made, QRN/natural, QTH/there, QSY/shift, and QRZ?/who is calling. | Retained — Choose Q signals by the task; In the real world: useful reports beat flattering reports; Memory trick: group Q signals by job (all five old cues restored). |

## Lesson 3: L-002-03

| Bank IDs (suffixes within B-002) | Taught facts extracted from the old lesson | Revised teaching location / comparison |
|---|---|---|
| 008-001 through 008-004, 008-010 | Immediate threat to life is distress: voice MAYDAY repeated three times, Morse SOS. Serious help without immediate life risk is urgent. Distress precedes emergency messages, which precede safety hazard information. | Retained — Match the priority to the danger; prose now explicitly places urgent help requests with emergency messages in that order. |
| 008-005, 008-009 | Break into busy repeater traffic between overs with call sign and situation; responders acknowledge, obtain location and assistance needed. | Retained — Open a path for help; Worked example: turn a break-in into useful action. |
| 008-006 through 008-008 | Alternate power enables outage communications; handhelds need charged spare batteries; portable HF can use a dipole or vertical. | Retained — Prepare the whole station. |
| 008-011 | If unable to help directly, contact authorities and keep monitoring. | Retained — Keep the link when help is indirect (separate from the break-in worked example). |
| Additional old teaching, no extra quiz mapping | Record time, calls, place, frequency, names supplied, needs and actions. Plain language reduces stress errors. Pack feedline/supports/settings with the radio. Estimate battery time as Ah / average A, with cold, age and reserve caveats. | Retained — Keep a record you can relay; Prepare the whole station; Worked example: estimate a battery budget. |

## Lesson 4: L-002-04

| Bank IDs (suffixes within B-002) | Taught facts extracted from the old lesson | Revised teaching location / comparison |
|---|---|---|
| 009-001, 009-005, 009-007 | QSL cards or web logs confirm contacts. Canadian amateur logs are optional but useful for awards, memory, confirmation matching and interference enquiries. Record UTC date/time, call, band/frequency, mode, report, location and station notes. | Retained — Make a contact easy to match; Worked example: a log narrows an interference enquiry. |
| 009-003 | Maidenhead codes describe location, with four or six characters; useful in VHF contests. | Retained — Use a compact location label. |
| 009-002, 009-004, 009-006, 009-008 | A station-centred azimuthal map gives bearings; long-path bearing is the reciprocal, 180 degrees away; try that direction when short path fails, without assuming success. | Retained — Take bearings from your own station; Worked example: aim the other way. |
| 009-009, 009-010 | UTC uses the Greenwich meridian reference. UTC-minus zones subtract the offset for local time, sometimes crossing into the previous local date. Bridge 24-hour times to AM/PM; keep UTC date with UTC time in records. | Retained — Keep one clock for the contact; Worked examples: a schedule in local evening time / crossing into the previous local date. |
| 009-011 | CHU, WWV and WWVH provide accurate frequency/time references. | Retained — Check time and frequency against a standard (separate from the date-conversion worked example). |

## Verification after rewriting

All ledger facts were compared with the revised teaching locations above: no covered fact was removed. The revised lessons retain all 99 M2 official questions and add three original concept checks per lesson (12 total). Each lesson now has concept sections, worked examples, Try-it prompts separated from feedback, and corrective common-mistake notes. Numerical lessons also include partly completed practice. Retrieval includes earlier signal-quality, power, and operating ideas.

A before/after script verified that every lesson's entire front matter, figure directive, and ordered official quiz list is unchanged from `4c9dbc0f`. It also expanded the ID ranges in this ledger and confirmed that all 99 M2 question IDs appear in the comparison. The library remains at 37 lessons; no progress migration is needed. No bank records, explanations, figure assets, or French hint prose changed.

Both M2 calling-pattern originality exceptions were removed: the reorganized, reworded teaching no longer needs them. Renamed sections required updates to all 99 M2 hint deep links. A JSON comparison verified that only `lessonLink.sectionAnchor` changed in those hint files.

### Checks run (2026-10-20)

| Command | Result |
|---|---|
| `node packages/content-tools/src/check-lesson-coverage.ts` | Passed: 100/100 subsections, 37 lessons, no duplicate coverage. |
| `pnpm --dir packages/content-tools check:lesson-originality:all` | Passed: 37 lessons, 0 originality issues, 0 stale exceptions. |
| `pnpm --dir packages/content-tools check:explanations` | Passed: 984 explanations and 2 952 per-choice notes. |
| `pnpm --dir packages/content-tools check:quizzes` | Passed: 37 quizzes, 521 official references, 92 concept checks repository-wide; M2 remains 99 official references plus 12 new checks. |
| `pnpm check:links` | Passed: relative Markdown links resolve. |
| `pnpm check:figures` | Passed: 53 self-test fixtures, 39 SVGs/references, Apple assets in sync. |
| `pnpm check:hints -- --require-complete` | Passed after remapping the renamed section anchors: 984/984 hints. |
| `pnpm check:schemas` | Passed: 2 034 validation targets and 55 tests. |
| `pnpm import:check` | Passed: Basic and Advanced generated banks plus 34 reference-sheet entries. |
| `pnpm test` | Release-permission self-test, content-tools 153/153, Morse 21/21, calculator 127/127 passed. Web: 221/223 passed; two unchanged tests timed out. See focused reruns below. |
| `cd packages/content-swift && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test` | Passed: 23/23, including real-repository loading (unchanged 37-lesson assertion), every-lesson Markdown parsing, and bundled hint-anchor resolution. |

The two web failures were `App.test.tsx` / “surfaces Settings import/reset UI errors and confirmations with focus management” (still loading at its wait deadline) and `progressStore.test.ts` / “migrates coherent stored device rows during the v6 upgrade and drops incoherent metadata” (5 s timeout). Both passed focused reruns with their default deadlines. The migration case first timed out again in isolation, then passed a diagnostic `--testTimeout=30000` run in under a second of test time and passed the subsequent default-timeout rerun. No app code, test source, timeout configuration, or assertions were changed. The original aggregate `pnpm test` invocation remains a recorded failure; the focused reruns resolve the two failing cases, not a second full-suite result.

Focused commands:

- `pnpm --filter @canadian-ham/web test src/App.test.tsx -t 'surfaces Settings import/reset UI errors and confirmations with focus management'`
- `pnpm --filter @canadian-ham/web test src/lib/progressStore.test.ts -t 'migrates coherent stored device rows during the v6 upgrade and drops incoherent metadata'`
- Diagnostic only: the same migration command with `--testTimeout=30000`.

### Internal-review fix round (2026-10-20)

Addressed both blocking findings and notes 3–9 from the internal review of `52b9e572`. No official question references, concept IDs, French fields, front matter, figure directives, text equivalents, or illustration briefs changed in this round.

The six flagged checks now require a changed-condition inference or a transfer to a different situation, rather than repeating the lesson's Try-it answer or asking for a bank definition:

| Concept check | New reasoning task | Difference from the Try-it |
|---|---|---|
| 01-C1 | Diagnose mismatched transmit/receive frequencies when radios keep repeater settings after the relay goes off. | The Try-it checks whether both operators can hear directly; this check diagnoses why retained split settings fail. Uses “On a direct test” instead of “Away from the relay”. |
| 01-C3 | Decide what a dummy-load test cannot establish after an antenna replaces the load. | The Try-it diagnoses distorted speech; this check evaluates evidence after the RF destination changes. |
| 02-C1 | Revise an assumption of a free channel when a contact becomes audible after an unanswered QRL?. | The Try-it selects pace/fading groups; this check weighs new listening evidence rather than recalling a code meaning. |
| 03-C3 | Recognize the untested dependence on a powered repeater despite charged handhelds. | The Try-it asks how to relay distress when direct assistance is unavailable; this check transfers readiness planning to infrastructure failure. |
| 04-C1 | Update a local reminder after a seasonal offset change while keeping the UTC schedule fixed. | The Try-it performs a stated-offset subtraction; this check decides which representation changes when the offset changes. |
| 04-C3 | Use an antenna-change log note as evidence to investigate, not proof of a cause. | The Try-it matches contact records; this check transfers the limits of log evidence to reception changes. |

The JSON format has a shared explanation rather than per-option feedback fields. Each revised explanation addresses the correct reasoning and all three distractors. Each check still has exactly one correct option. Across the 12 M2 checks, the correct positions are 2/3/1, 3/1/4, 3/2/4, and 2/3/1.

Misplaced teaching now has its own concept heading, outside the worked-example blocks. Twelve hints were retargeted precisely:

- B-002-003-003 through 003-008 → `use-simplex-for-a-direct-path`.
- B-002-001-010 → `use-plain-language-for-location`.
- B-002-006-005 → `read-strength-above-s9`.
- B-002-006-006 → `reports-through-a-repeater`.
- B-002-006-011 → `voice-reports-use-readability-and-strength`.
- B-002-008-011 → `keep-the-link-when-help-is-indirect`.
- B-002-009-011 → `check-time-and-frequency-against-a-standard`.

The ledger above now names these teaching locations. R1, R3, and S1 use the standard scale wording; both the R4 table entry and worked example say practically no difficulty. The priority prose links urgent requests with emergency messages. The distress common-mistake correction now says to keep the channel for the caller and acknowledge them. All five old Q-signal memory cues are present, including QTH/there, QSY/shift, and QRZ?/who is calling. The grid-square and tuner-test paragraphs now lead with the location-label and shared-spectrum principles while retaining their tested facts.

Review-round validation:

| Command | Result |
|---|---|
| `node packages/content-tools/src/check-lesson-coverage.ts` | Passed: 100/100 subsections across 37 lessons, no duplicate coverage. |
| `pnpm --dir packages/content-tools check:lesson-originality:all` | Passed: 37 lessons, 0 issues, 0 stale exceptions. |
| `pnpm --dir packages/content-tools check:explanations` | Passed: 984 explanations, 2 952 per-choice notes. |
| `pnpm --dir packages/content-tools check:quizzes` | Passed: 37 quizzes, 521 official references, 92 concept checks; rerun after final distractor wording. |
| `pnpm check:links` | Passed: relative Markdown links resolve. |
| `pnpm check:figures` | Passed: 53 self-test fixtures, 39 SVGs/references, Apple assets in sync. |
| `pnpm check:hints -- --require-complete` | Passed: 984/984 hints. |
| `node packages/content-tools/src/check-hints.ts --category B-002 --require-complete` | Passed: all 99 M2 hints, including every retargeted heading anchor. |
| `pnpm check:schemas` | Passed: 2 034 validation targets, 55/55 tests. |
| `pnpm import:check` | Passed: both generated banks, 34 reference-sheet entries. |
| `cd packages/content-swift && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test` | Passed: 23/23, including bundled hint anchors and all real lesson Markdown parsing. |
| `python3 /tmp/task-46.9-review-invariants.py` | Passed: comparison against `52b9e572` confirms byte-identical front matter, four figure blocks and briefs, unchanged ordered 99 official references and 12 concept IDs, exactly six revised checks, one correct answer each, and only anchor changes in the 12 affected hints. Expanded ledger ranges still cover all 99 IDs. |
| `git diff --check` | Passed. |

Local validation output is in `/tmp/task-46.9-review-content-checks.log`, `/tmp/task-46.9-review-links-schemas.log`, `/tmp/task-46.9-review-content-swift.log`, and `/tmp/task-46.9-review-invariants.log`. No web/app code or test infrastructure changed; the earlier aggregate web timeout result above is historical, not a result of a new full run. No Apple app builds or UI suites ran in this fix round.

### Deferred platform validation

All four lessons contain figures: the coordinator should schedule the `CanadianHamLessonFigures` test plan. No Apple UI suite or app build ran in this content-only worker task, as requested. Figure sources, directives, text equivalents, alt text, and illustration briefs are unchanged; figure layout may still shift because the surrounding lesson text changed.
