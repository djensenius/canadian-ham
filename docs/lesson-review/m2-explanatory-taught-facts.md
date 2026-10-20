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
| 001-010 | Ask for location in plain words rather than 10-codes. | Retained — Leave room on the repeater. |
| 002-001 through 002-011 | ITU phonetics improve identification; A Alfa, B Bravo, D Delta, E Echo, G Golf, I India, L Lima, P Papa, R Romeo; full alphabet also supplied. | Retained — Make the call sign easy to copy. |
| 003-001, 003-002 | Voice CQ repeats CQ three times and the caller three times; answer with the other call once, “this is”, own call. | Retained — Tell listeners who you want. |
| 003-003, 003-004, 003-007 | Simplex uses a shared transmit/receive frequency; use it when direct copy is reliable; listen on the repeater input to test direct reception. | Retained — Choose a relay or a direct path. |
| 003-005, 003-006, 003-008 | Prefer VHF/UHF for suitable local work; protect HF capacity. Avoid repeater inputs when choosing simplex and move if interfering with a repeater. | Retained — Choose a relay or a direct path. |
| 003-009, 003-010 | Twenty-metre voice normally uses USB; the 3 755 kHz example uses LSB. | Retained — Give a voice signal enough space (adds the practical sideband convention). |
| 004-001, 004-011 | Listen before transmitting to protect existing contacts. | Retained — Share the frequency, not just the microphone; Give a voice signal enough space. |
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
| 006-001, 006-002, 006-003, 006-004, 006-009, 006-010, 006-011 | Reports describe reception: R readability, S strength, T keyed-signal tone. Voice omits T. R1 unreadable, R3 difficult, R4 quite readable, R5 perfect; S1 barely heard, S3 weak, S5 fair, S7 moderately strong, S9 extremely strong; T9 clean tone. | Retained — Report what reaches your receiver; Worked example: keep the three observations separate. |
| 006-005, 006-006 | A dB suffix measures strength above S9; repeater reports describe the relayed audio actually heard, not the remote input signal. | Retained — Report what reaches your receiver. |
| 006-007, 006-008 | In the calibrated, stable-path model, each S-unit is 6 dB: two approximate power doublings or halvings; power ratio four upward, quarter downward. Real paths/meters limit the shortcut. | Retained — Connect meter steps to power ratios; Worked examples: predicting a rise / predicting a fall (both directions shown). |
| 007-001, 007-009 | QRS requests slower sending. | Retained — Choose Q signals by the task. |
| 007-002, 007-003, 007-004, 007-005 | QTH location, QRL? busy check, QSY frequency change, QSB fading. | Retained — Choose Q signals by the task. |
| 007-006, 007-010, 007-011 | QRZ? asks the unidentified caller to identify; QRX signals a later call. | Retained — Choose Q signals by the task. |
| 007-007, 007-008 | QRM interference from other signals; QRN natural noise/static. | Retained — Choose Q signals by the task. |
| Additional old teaching, no extra quiz mapping | QRV? readiness; QRU? pending traffic; QRT stop; QSL? acknowledge; QRK readability; QRP reduce/low power. Question marks distinguish questions from statements. Give honest reports rather than automatic perfect reports. | Retained — Choose Q signals by the task; In the real world: useful reports beat flattering reports. |

## Lesson 3: L-002-03

| Bank IDs (suffixes within B-002) | Taught facts extracted from the old lesson | Revised teaching location / comparison |
|---|---|---|
| 008-001 through 008-004, 008-010 | Immediate threat to life is distress: voice MAYDAY repeated three times, Morse SOS. Serious help without immediate life risk is urgent. Distress precedes emergency messages, which precede safety hazard information. | Retained — Match the priority to the danger. |
| 008-005, 008-009 | Break into busy repeater traffic between overs with call sign and situation; responders acknowledge, obtain location and assistance needed. | Retained — Open a path for help; Worked example: turn a break-in into useful action. |
| 008-006 through 008-008 | Alternate power enables outage communications; handhelds need charged spare batteries; portable HF can use a dipole or vertical. | Retained — Prepare the whole station. |
| 008-011 | If unable to help directly, contact authorities and keep monitoring. | Retained — Open a path for help. |
| Additional old teaching, no extra quiz mapping | Record time, calls, place, frequency, names supplied, needs and actions. Plain language reduces stress errors. Pack feedline/supports/settings with the radio. Estimate battery time as Ah / average A, with cold, age and reserve caveats. | Retained — Keep a record you can relay; Prepare the whole station; Worked example: estimate a battery budget. |

## Lesson 4: L-002-04

| Bank IDs (suffixes within B-002) | Taught facts extracted from the old lesson | Revised teaching location / comparison |
|---|---|---|
| 009-001, 009-005, 009-007 | QSL cards or web logs confirm contacts. Canadian amateur logs are optional but useful for awards, memory, confirmation matching and interference enquiries. Record UTC date/time, call, band/frequency, mode, report, location and station notes. | Pending rewrite comparison. |
| 009-003 | Maidenhead codes describe location, with four or six characters; useful in VHF contests. | Pending rewrite comparison. |
| 009-002, 009-004, 009-006, 009-008 | A station-centred azimuthal map gives bearings; long-path bearing is the reciprocal, 180 degrees away; try that direction when short path fails, without assuming success. | Pending rewrite comparison. |
| 009-009, 009-010 | UTC uses the Greenwich meridian reference. UTC-minus zones subtract the offset for local time, sometimes crossing into the previous local date. Bridge 24-hour times to AM/PM; keep UTC date with UTC time in records. | Pending rewrite comparison. |
| 009-011 | CHU, WWV and WWVH provide accurate frequency/time references. | Pending rewrite comparison. |

## Verification after rewriting

Pending final comparison and checks. Lesson IDs, coverage, prerequisites, figure directives, and official quiz lists must stay unchanged. The total library must remain 37 lessons. All four lessons contain figures: the coordinator should schedule the `CanadianHamLessonFigures` test plan; no Apple UI suite runs in this content-only worker task.
