# M1 principles: taught-facts comparison (TASK-46.8)

## Scope and method

Baseline: main `8a82709b`, captured before rewriting on 2026-10-21. The inventory below extracts every reference-table fact from all six M1 lessons, not just their coverage IDs. Repeated facts are retained in this audit so consolidation cannot hide a loss. The final comparison also checks prose-only teaching and all 199 B-001 bank items against the teaching section, not just a quiz list.

## Format decision

Keep M1 principles-led and reference-only. The owner approved principles, a qualification-by-privilege matrix, Why columns and a numbers board, not a new set of regulatory practice questions. Tables state the rules in original wording; nearby prose teaches their relationships. Quizzes keep every official ID and `conceptChecks: []`. There are no new Try-its, worked question-and-answer exercises or concept checks. The teaching guide and existing M1 reference-only test remain applicable. Section-sized quiz delivery is TASK-46.8.1, dependent on TASK-50.14.2.

## Regulatory source boundary

The active bank is `content/generated/basic-2025-07-15/questions.json`. Regulatory cross-checks use the repository-verified RBR-4 and RIC-3 facts in `docs/exam-facts.md` and `docs/teaching-guide.md`. Attempts to retrieve both current ISED pages on 2026-10-21 returned HTTP 503 on the canonical and www hosts. This rewrite preserves the verified legal facts; a Why column explains a relationship or study distinction, not a new legal exemption or invented rationale.

## L-001-01 baseline inventory

| Before section | Taught fact before rewrite | After section / comparison |
|---|---|---|
| Reference facts: Authority and source roles | Radiocommunication Act: Authority to make Canadian radiocommunication regulations; authority to publish amateur-station operating standards; source of radiocommunication offences and penalties. | Retained; reference-facts-authority-comes-from-named-sources. |
| Reference facts: Authority and source roles | Radiocommunication Regulations: Define the Canadian amateur radio service. | Retained; reference-facts-authority-comes-from-named-sources. |
| Reference facts: Authority and source roles | Innovation, Science and Economic Development Canada (ISED): Administers the Radiocommunication Act. | Retained; reference-facts-authority-comes-from-named-sources. |
| Reference facts: Authority and source roles | ISED operating standards: RBR-4, the amateur-service operating standards, tells amateur stations how to operate. | Retained; reference-facts-authority-comes-from-named-sources. |
| Reference facts: Authority and source roles | Certificate and call sign: Identify the holder's qualifications and station identity for amateur operation. | Retained; reference-facts-authority-comes-from-named-sources. |
| Reference facts: Certificate records, addresses, and call-sign fees | Certificate validity: Life. | Retained; reference-facts-a-lifetime-certificate-needs-current-records. |
| Reference facts: Certificate records, addresses, and call-sign fees | Certificate retention: Retained at the station and at the address provided to ISED. | Retained; reference-facts-a-lifetime-certificate-needs-current-records. |
| Reference facts: Certificate records, addresses, and call-sign fees | Inspector request: The holder has 48 hours to show the certificate or a copy. | Retained; reference-facts-a-lifetime-certificate-needs-current-records. |
| Reference facts: Certificate records, addresses, and call-sign fees | Mailing-address change: ISED must be informed within 30 days of a mailing-address change. | Retained; reference-facts-a-lifetime-certificate-needs-current-records. |
| Reference facts: Certificate records, addresses, and call-sign fees | First Amateur Radio Operator Certificate: Free. | Retained; reference-facts-a-lifetime-certificate-needs-current-records. |
| Reference facts: Certificate records, addresses, and call-sign fees | Replacement call sign with a new prefix after moving to a new province or territory: Free. | Retained; reference-facts-a-lifetime-certificate-needs-current-records. |
| Reference facts: Certificate records, addresses, and call-sign fees | Voluntary call-sign change, including a two-letter call sign: $60. | Retained; reference-facts-a-lifetime-certificate-needs-current-records. |
| Reference facts: Offences, penalties, and process boundaries | Transmitting outside amateur bands: Prohibited; penalties could be assessed to the control operator. | Retained; reference-facts-trust-needs-honest-signals-and-fair-process. |
| Reference facts: Offences, penalties, and process boundaries | False distress wording when there is no emergency: A false or fraudulent message. | Retained; reference-facts-trust-needs-honest-signals-and-fair-process. |
| Reference facts: Offences, penalties, and process boundaries | Transmitting false information: Prohibited. | Retained; reference-facts-trust-needs-honest-signals-and-fair-process. |
| Reference facts: Offences, penalties, and process boundaries | False or fraudulent distress signal or message: Fine up to $5 000, prison term up to one year, or both. | Retained; reference-facts-trust-needs-honest-signals-and-fair-process. |
| Reference facts: Offences, penalties, and process boundaries | Interfering with or obstructing radio communication without lawful cause: Fine up to $5 000, prison term up to one year, or both. | Retained; reference-facts-trust-needs-honest-signals-and-fair-process. |
| Reference facts: Offences, penalties, and process boundaries | Dwelling entry by inspector: Consent or a warrant is required for dwelling entry. | Retained; reference-facts-trust-needs-honest-signals-and-fair-process. |
| Reference facts: Offences, penalties, and process boundaries | Inspection warrant safeguards: When entry is refused and entry is needed for inspector duties, the inspector may obtain a warrant; warrant-related force requires authorization and a peace officer. | Retained; reference-facts-trust-needs-honest-signals-and-fair-process. |
| Reference facts: Offences, penalties, and process boundaries | Certificate suspension: Notice and an opportunity to make representations are part of the suspension process. | Retained; reference-facts-trust-needs-honest-signals-and-fair-process. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Basic age: No age limit. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Candidate address: A valid address in Canada is required. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | First amateur examination sequence: Basic must be passed before the Amateur Radio Operator Certificate is issued. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Later amateur qualifications: After Basic is issued, additional qualifications may be examined in any order. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Morse qualification: 5 words per minute sending and receiving. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Other radio services: Operation in another radio service requires authority for that service. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Maritime radio certificate path: The Canadian Radiocommunication Operator General Certificate Maritime (RGMC) can lead to amateur certification. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | ISED office qualification examinations: No charge. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Accredited examiner: May charge a fee to recover examination administration costs. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Accredited-examiner qualifications: Basic, Advanced, and Morse code qualifications. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Disability-related examination delivery: Exams may be oral or tailored to the candidate's ability, such as dividing the exam into segments when an accessibility option is needed. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Morse sending accommodation: A disabled candidate may be allowed to recite the examination text in Morse code sounds. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Required examination portions: All required portions of the examination remain part of an accommodated exam. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Reading difficulty or language barrier: After a written-exam failure caused by reading difficulty or because English or French is not the candidate's usual language, oral examination delivery may be available. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Language-related examination delivery: The candidate answers personally in English or French; oral delivery is the supported language aid. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Basic eligibility, qualifications, exams, and accommodations | Medical evidence: An examiner may request evidence from a practising medical physician before accommodating testing. | Retained; reference-facts-qualifications-follow-a-learning-path. |
| Reference facts: Exam day materials and virtual exams | Closed book: The Basic exam is closed book. Reference material must not be used during the exam except for the ISED-approved Basic formula and block diagram sheet. | Retained; reference-facts-exam-aids-support-skills-not-stored-answers. |
| Reference facts: Exam day materials and virtual exams | Permitted reference sheet: The only reference material named by ISED for the Basic exam is the ISED-approved formula and block diagram sheet titled "Reference Material for Amateur Radio Exam – Basic Qualification". | Retained; reference-facts-exam-aids-support-skills-not-stored-answers. |
| Reference facts: Exam day materials and virtual exams | Calculator: A calculator is permitted only if it cannot store formulas or text. | Retained; reference-facts-exam-aids-support-skills-not-stored-answers. |
| Reference facts: Exam day materials and virtual exams | Virtual exam setup: Use a computer with a camera, microphone, and stable internet connection. | Retained; reference-facts-exam-aids-support-skills-not-stored-answers. |
| Reference facts: Exam day materials and virtual exams | Virtual answer sheet: For a virtual exam, the examiner emails a blank answer sheet in advance. Print it, write answers on it during the exam, and follow the examiner's submission instructions. | Retained; reference-facts-exam-aids-support-skills-not-stored-answers. |

## L-001-02 baseline inventory

| Before section | Taught fact before rewrite | After section / comparison |
|---|---|---|
| Reference facts: Work done for another person | Advanced holder installing, placing in operation, modifying, or repairing radio apparatus for another person: The other person must hold an authorization for the apparatus. | Retained; reference-facts-both-sides-need-authority. |
| Reference facts: Work done for another person | Reprogramming a land-mobile transmitter for another person's two-metre amateur use: The other person must hold an Amateur Radio Operator Certificate. | Retained; reference-facts-both-sides-need-authority. |
| Reference facts: Work done for another person | Installing an amateur radio transmitter for another person: Both people must hold Amateur Radio Operator Certificates. | Retained; reference-facts-both-sides-need-authority. |
| Reference facts: Work done for another person | Basic and Morse holder installing another person's amateur station: The other person must hold a valid Amateur Radio Operator Certificate. | Retained; reference-facts-both-sides-need-authority. |
| Reference facts: Work done for another person | Repairing an amateur radio transmitter for another person: Both people must hold Amateur Radio Operator Certificates. | Retained; reference-facts-both-sides-need-authority. |
| Reference facts: Work done for another person | Placing an amateur radio transmitter in service for another person: Both people must hold Amateur Radio Operator Certificates. | Retained; reference-facts-both-sides-need-authority. |
| Reference facts: Amateur service boundaries | Even a 2 W amateur station: Still must be under supervision of a certificate holder with a call sign. | Retained; reference-facts-both-sides-need-authority. |
| Reference facts: Amateur service boundaries | Amateur station communications: With stations operated under similar authorizations. | Retained; reference-facts-both-sides-need-authority. |
| Reference facts: Amateur service boundaries | Amplifying a licence-exempt transmitter with amateur equipment: Prohibited. | Retained; reference-facts-both-sides-need-authority. |
| Reference facts: Amateur service boundaries | Amateur equipment outside amateur bands: Transmitting outside amateur bands with amateur equipment, modified or not, is prohibited because the equipment has no certification for other bands. | Retained; reference-facts-both-sides-need-authority. |
| Reference facts: Amateur service boundaries | Amateur-authorized apparatus in other services: Aeronautical, marine, and land-mobile operation require the applicable service authorization. | Retained; reference-facts-both-sides-need-authority. |
| Reference facts: Amateur service boundaries | VHF/UHF FM radio also programmed for land-mobile service: Permissible only if the radio is certified and licensed for land-mobile use. | Retained; reference-facts-both-sides-need-authority. |
| Reference facts: Communications that fit amateur radio | Recreation planning, code-practice planning, or emergency planning on a club net: Permitted amateur discussion examples. | Retained; reference-facts-messages-stay-open-and-non-commercial. |
| Reference facts: Communications that fit amateur radio | Business planning or business communications: Prohibited. | Retained; reference-facts-messages-stay-open-and-non-commercial. |
| Reference facts: Communications that fit amateur radio | Broadcasts intended for the general public: Prohibited. | Retained; reference-facts-messages-stay-open-and-non-commercial. |
| Reference facts: Communications that fit amateur radio | Radio-control commands to model craft, brief transmissions to adjust the station, and Morse code practice: Permitted one-way examples. | Retained; reference-facts-messages-stay-open-and-non-commercial. |
| Reference facts: Communications that fit amateur radio | Q codes, abbreviations, and procedural signals: Permitted when the signals or codes have open meaning. | Retained; reference-facts-messages-stay-open-and-non-commercial. |
| Reference facts: Communications that fit amateur radio | New digital encoding technique: Must be published in the public domain before use on amateur bands. | Retained; reference-facts-messages-stay-open-and-non-commercial. |
| Reference facts: Communications that fit amateur radio | Secret code, unpublished encoding, programming from a broadcasting undertaking, or commercially recorded material: Prohibited. | Retained; reference-facts-messages-stay-open-and-non-commercial. |
| Reference facts: Communications that fit amateur radio | Background music or non-amateur audio reaching the microphone: Keep microphone audio limited to amateur communication. | Retained; reference-facts-messages-stay-open-and-non-commercial. |
| Reference facts: Station privileges and construction | Operating an amateur station in Canada: Certificate holders may operate anywhere in Canada, subject to their privileges and the other rules in this course. | Retained; reference-facts-qualification-by-privilege-matrix-for-station-work. |
| Reference facts: Station privileges and construction | Assembling commercially available transmitter kits of professional design: Basic. | Retained; reference-facts-qualification-by-privilege-matrix-for-station-work. |
| Reference facts: Station privileges and construction | Operating cross-band repeaters: Basic. | Retained; reference-facts-qualification-by-privilege-matrix-for-station-work. |
| Reference facts: Station privileges and construction | Beacon station one-way communications: A beacon station may transmit one-way communications. | Retained; reference-facts-qualification-by-privilege-matrix-for-station-work. |
| Reference facts: Station privileges and construction | Installing a single-band voice repeater: Basic and Advanced. | Retained; reference-facts-qualification-by-privilege-matrix-for-station-work. |
| Reference facts: Station privileges and construction | Installing an amateur radio club station: Basic and Advanced. | Retained; reference-facts-qualification-by-privilege-matrix-for-station-work. |
| Reference facts: Station privileges and construction | Installing or operating a transmitter or RF amplifier that is neither professionally designed nor commercially manufactured for amateur use: Basic and Advanced. | Retained; reference-facts-qualification-by-privilege-matrix-for-station-work. |
| Reference facts: Station privileges and construction | Remotely operating a transmitter while changing frequency, emission mode, or output power: Basic and Advanced. | Retained; reference-facts-qualification-by-privilege-matrix-for-station-work. |
| Reference facts: Control operator and station owner | Responsibility for station operation: Both the control operator and the station owner. | Retained; reference-facts-control-stays-with-responsible-people. |
| Reference facts: Control operator and station owner | Transmitting from another amateur station: Both the visiting operator and the station owner are responsible. | Retained; reference-facts-control-stays-with-responsible-people. |
| Reference facts: Control operator and station owner | Station owner responsibility: Operation of the station in accordance with the regulations. | Retained; reference-facts-control-stays-with-responsible-people. |
| Reference facts: Control operator and station owner | Choice of control operator: Any qualified amateur radio operator chosen by the station owner. | Retained; reference-facts-control-stays-with-responsible-people. |
| Reference facts: Control operator and station owner | Need for a control operator: Whenever the station is transmitting. | Retained; reference-facts-control-stays-with-responsible-people. |
| Reference facts: Control operator and station owner | Control-operator location during transmission: At the station's control point. | Retained; reference-facts-control-stays-with-responsible-people. |
| Reference facts: Control operator and station owner | Unqualified family member alone with equipment: Transmitting as control operator requires suitable amateur qualifications. | Retained; reference-facts-control-stays-with-responsible-people. |
| Reference facts: Control operator and station owner | Owner allowing another person to operate: May allow operation under supervision and in the presence of a certificate holder. | Retained; reference-facts-control-stays-with-responsible-people. |
| Reference facts: Control operator and station owner | Person without an Amateur Radio Operator Certificate: May operate only under supervision and in the presence of a person holding appropriate qualifications. | Retained; reference-facts-control-stays-with-responsible-people. |

## L-001-03 baseline inventory

| Before section | Taught fact before rewrite | After section / comparison |
|---|---|---|
| Reference facts: Interference and shared bands | Transmission that disturbs other communications: Harmful interference. | Retained; reference-facts-share-spectrum-without-harm. |
| Reference facts: Interference and shared bands | Serious degradation, obstruction, or repeated interruption of a radiocommunication service: Harmful interference. | Retained; reference-facts-share-spectrum-without-harm. |
| Reference facts: Interference and shared bands | Deliberate interference with another amateur station: Unacceptable. | Retained; reference-facts-share-spectrum-without-harm. |
| Reference facts: Interference and shared bands | Two amateur operators wanting the same frequency: Both station operators have an equal right to operate on the frequency. | Retained; reference-facts-share-spectrum-without-harm. |
| Reference facts: Interference and shared bands | Amateur service as secondary user while another service is primary: Amateur operation must protect primary users from interference. | Retained; reference-facts-share-spectrum-without-harm. |
| Reference facts: Interference and shared bands | Ministerial finding of harmful interference: The station's operation can be ordered to cease or change. | Retained; reference-facts-share-spectrum-without-harm. |
| Reference facts: Interference and shared bands | 430.0 MHz to 450.0 MHz: Amateur operation must protect other radio services from interference because amateurs are secondary users in this range. | Retained; reference-facts-share-spectrum-without-harm. |
| Reference facts: Interference and shared bands | 902 MHz to 928 MHz: Amateur operation is not protected from interference by another service, and the band may be heavily occupied by licence-exempt devices. | Retained; reference-facts-share-spectrum-without-harm. |
| Reference facts: Interference and shared bands | Test transmissions: Allowed when they protect amateur stations and other services from interference. | Retained; reference-facts-share-spectrum-without-harm. |
| Reference facts: Emergency, disaster, and public-service communication | Ordinary amateur communication: Only with other amateur radio stations. | Retained; reference-facts-life-safety-has-narrow-exceptions. |
| Reference facts: Emergency, disaster, and public-service communication | Disaster-relief use outside amateur bands: Prohibited. | Retained; reference-facts-life-safety-has-narrow-exceptions. |
| Reference facts: Emergency, disaster, and public-service communication | Unanswered distress signal on an amateur band outside the operator's normal privileges: The operator may respond and offer assistance. | Retained; reference-facts-life-safety-has-narrow-exceptions. |
| Reference facts: Emergency, disaster, and public-service communication | Broadcasting exception: Radio communications required for the safety of life and property. | Retained; reference-facts-life-safety-has-narrow-exceptions. |
| Reference facts: Emergency, disaster, and public-service communication | Amateur operator in distress: May use any means of radiocommunication. | Retained; reference-facts-life-safety-has-narrow-exceptions. |
| Reference facts: Emergency, disaster, and public-service communication | Disaster-relief transmissions: May meet essential communication needs when normal systems are overloaded, damaged, or disrupted. | Retained; reference-facts-life-safety-has-narrow-exceptions. |
| Reference facts: Emergency, disaster, and public-service communication | Power limits for an amateur operator in distress: No limitations. | Retained; reference-facts-life-safety-has-narrow-exceptions. |
| Reference facts: Emergency, disaster, and public-service communication | Operators outside the active disaster-relief net: Keep the net frequency and nearby frequencies clear. | Retained; reference-facts-life-safety-has-narrow-exceptions. |
| Reference facts: Emergency, disaster, and public-service communication | Recognized public-service agency messages: May be handled during peace time, civil emergencies, and exercises. | Retained; reference-facts-life-safety-has-narrow-exceptions. |
| Reference facts: Emergency, disaster, and public-service communication | Interfering with another station's transmissions: Permitted only when your own station is directly involved with a distress situation. | Retained; reference-facts-life-safety-has-narrow-exceptions. |
| Reference facts: Privacy, payment, and message handling | Payment for third-party messages sent by an amateur station: No payment of any kind is allowed. | Retained; reference-facts-message-handling-stays-unpaid. |
| Reference facts: Privacy, payment, and message handling | Amateur-station non-broadcast radiocommunications: May be divulged or used. | Retained; reference-facts-message-handling-stays-unpaid. |
| Reference facts: Privacy, payment, and message handling | Remuneration for exchanging messages: Prohibited. | Retained; reference-facts-message-handling-stays-unpaid. |
| Reference facts: Privacy, payment, and message handling | Other non-broadcast radiocommunication content: Divulging content to answer media questions is the offence. | Retained; reference-facts-message-handling-stays-unpaid. |
| Reference facts: Station identification | Valid Canadian amateur call-sign example pattern: A Canadian call sign normally starts with VA, VE, VO, or VY. | Retained; reference-facts-make-the-station-traceable. |
| Reference facts: Station identification | Identifying the station: Transmit the call sign. | Retained; reference-facts-make-the-station-traceable. |
| Reference facts: Station identification | Beginning a contact: Each station transmits its own call sign. | Retained; reference-facts-make-the-station-traceable. |
| Reference facts: Station identification | Ending a contact: Each station transmits its own call sign. | Retained; reference-facts-make-the-station-traceable. |
| Reference facts: Station identification | Longest interval without identification: 30 minutes. | Retained; reference-facts-make-the-station-traceable. |
| Reference facts: Station identification | General timing rule: At the beginning and end of each contact and at maximum 30-minute intervals. | Retained; reference-facts-make-the-station-traceable. |
| Reference facts: Station identification | Test transmission identification: Same rules as a radio contact. | Retained; reference-facts-make-the-station-traceable. |
| Reference facts: Station identification | Language for identification: English or French. | Retained; reference-facts-make-the-station-traceable. |
| Reference facts: Station identification | Unidentified amateur communications: Only to control a model craft. | Retained; reference-facts-make-the-station-traceable. |

## L-001-04 baseline inventory

| Before section | Taught fact before rewrite | After section / comparison |
|---|---|---|
| Reference facts: Operator privileges and below-30-MHz access | Another operator with additional qualifications controls your station under your call sign: Only the privileges allowed by your qualifications. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| Reference facts: Operator privileges and below-30-MHz access | You control another station whose owner has more certificate qualifications: Only the privileges allowed by your qualifications. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| Reference facts: Operator privileges and below-30-MHz access | Frequencies below 30 MHz: In addition to Basic, the operator needs 80% on Basic, or Advanced, or Morse code. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| Reference facts: Operator privileges and below-30-MHz access | Radio-controlled models: Certificate holders may operate them on all amateur bands above 30 MHz. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| Reference facts: Operator privileges and below-30-MHz access | Basic-only repeater use: Holders with only Basic may use repeaters whose output is at 29.500 MHz and above; this row does not open ordinary below-30-MHz transmitting. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| Reference facts: Operator privileges and below-30-MHz access | Lowest Basic-only repeater output segment: 29.500 MHz to 29.700 MHz. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| Reference facts: HF band ranges | 160 metres: 1.8 MHz to 2.0 MHz. | Retained; reference-facts-band-edges-contain-the-whole-signal. |
| Reference facts: HF band ranges | 80 metres: 3.5 MHz to 4.0 MHz. | Retained; reference-facts-band-edges-contain-the-whole-signal. |
| Reference facts: HF band ranges | 40 metres: 7.0 MHz to 7.3 MHz. | Retained; reference-facts-band-edges-contain-the-whole-signal. |
| Reference facts: HF band ranges | 20 metres: 14.000 MHz to 14.350 MHz. | Retained; reference-facts-band-edges-contain-the-whole-signal. |
| Reference facts: HF band ranges | 15 metres: 21.000 MHz to 21.450 MHz. | Retained; reference-facts-band-edges-contain-the-whole-signal. |
| Reference facts: HF band ranges | 10 metres: 28.000 MHz to 29.700 MHz. | Retained; reference-facts-band-edges-contain-the-whole-signal. |
| Reference facts: Bandwidth and mode-fit cues | 50 MHz to 54 MHz and 144 MHz to 148 MHz: 30 kHz maximum bandwidth. | Retained; reference-facts-mode-width-must-fit-the-band. |
| Reference facts: Bandwidth and mode-fit cues | 28 MHz to 29.7 MHz: 20 kHz maximum bandwidth. | Retained; reference-facts-mode-width-must-fit-the-band. |
| Reference facts: Bandwidth and mode-fit cues | Amateur bands between 7 MHz and 25 MHz, except the special narrow band: 6 kHz maximum bandwidth. | Retained; reference-facts-mode-width-must-fit-the-band. |
| Reference facts: Bandwidth and mode-fit cues | 10.100 MHz to 10.150 MHz: 1 kHz maximum bandwidth in RBR-4, which is less than 6 kHz. | Retained; reference-facts-mode-width-must-fit-the-band. |
| Reference facts: Bandwidth and mode-fit cues | 10.100 MHz to 10.150 MHz: Single sideband is prohibited. | Retained; reference-facts-mode-width-must-fit-the-band. |
| Reference facts: Bandwidth and mode-fit cues | Transmitting near band edges: The entire occupied bandwidth must remain within the amateur band. | Retained; reference-facts-band-edges-contain-the-whole-signal. |
| Reference facts: Bandwidth and mode-fit cues | CW / Morse radiotelegraphy: Narrower than SSB voice and FM voice in the mode-width ordering. | Retained; reference-facts-mode-width-must-fit-the-band. |
| Reference facts: Bandwidth and mode-fit cues | FT8: A narrow digital mode, with many FT8 contacts fitting in the space needed for one SSB transmission. | Retained; reference-facts-mode-width-must-fit-the-band. |
| Reference facts: Bandwidth and mode-fit cues | SSB voice: Usual SSB bandwidth is between 2 kHz and 3 kHz. | Retained; reference-facts-mode-width-must-fit-the-band. |
| Reference facts: Bandwidth and mode-fit cues | FM voice: 5 kHz-deviation FM occupies between 10 kHz and 20 kHz; FM below 28 MHz exceeds regulatory bandwidth limits. | Retained; reference-facts-mode-width-must-fit-the-band. |
| Reference facts: Bandwidth and mode-fit cues | Fast-scan television on 145 MHz: Prohibited because ATV exceeds the 30 kHz limit for 144 MHz to 148 MHz. | Retained through the 2 m bandwidth rule; reference-facts-mode-width-must-fit-the-band. |
| Reference facts: Bandwidth and mode-fit cues | Fast-scan television on 14.23 MHz: Prohibited because ATV exceeds the 6 kHz limit for amateur bands between 7 MHz and 25 MHz. | Retained through the 20 m bandwidth rule; reference-facts-mode-width-must-fit-the-band. |
| Reference facts: Power quantities and limits | General operating power: Use the minimum legal power necessary to communicate. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. The matrix retains the general ceiling, including eligible HF bands. |
| Reference facts: Power quantities and limits | Power verification after RF exposure and radiated-power limits are determined: Verify at the output of the transmitter or external amplifier. | Retained; reference-facts-power-needs-a-quantity-and-a-measurement-point. |
| Reference facts: Power quantities and limits | Basic, DC input to the final RF stage: 250 W. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. The matrix retains the general ceiling, including eligible HF bands. |
| Reference facts: Power quantities and limits | Basic, single-sideband peak envelope power: 560 W PEP. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. The matrix retains the general ceiling, including eligible HF bands. |
| Reference facts: Power quantities and limits | Basic and Morse, SSB on 3750 kHz: 560 W PEP. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. The matrix retains the general ceiling, including eligible HF bands. |
| Reference facts: Power quantities and limits | Basic with Honours, SSB on 7055 kHz: 560 W PEP. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. The matrix retains the general ceiling, including eligible HF bands. |
| Reference facts: Power quantities and limits | Basic-only non-SSB emissions for an operator without Advanced: 190 W carrier power. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. The matrix retains the general ceiling, including eligible HF bands. |
| Reference facts: Power quantities and limits | Advanced, DC input to the final RF stage: 1 000 W. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. The matrix retains the general ceiling, including eligible HF bands. |
| Reference facts: Power quantities and limits | Advanced, single-sideband peak envelope power: 2 250 W PEP. | Retained; reference-facts-qualification-by-privilege-matrix-for-access-and-power. The matrix retains the general ceiling, including eligible HF bands. |
| Reference facts: Power quantities and limits | Advanced on the special band: On 60 metres, 100 W ERP expressed as PEP. | Retained; reference-facts-power-needs-a-quantity-and-a-measurement-point. |
| Reference facts: Power quantities and limits | 630 metres and 2200 metres: Antenna gain must be taken into account because limits are expressed as EIRP. | Retained; reference-facts-power-needs-a-quantity-and-a-measurement-point. |
| Reference facts: Repeaters, automatic transmissions, stability, and modulation quality | Repeater station: Automatically retransmits the signals of other stations. | Retained; reference-facts-automatic-signals-still-need-clean-control. |
| Reference facts: Repeaters, automatic transmissions, stability, and modulation quality | Unmodulated carrier: May be transmitted only for brief tests on frequencies below 30 MHz. | Retained; reference-facts-automatic-signals-still-need-clean-control. |
| Reference facts: Repeaters, automatic transmissions, stability, and modulation quality | Frequency stability: Equivalent to crystal control below 148 MHz; with crystal control, a quartz crystal sets the frequency so it drifts very little. | Retained; reference-facts-automatic-signals-still-need-clean-control. |
| Reference facts: Repeaters, automatic transmissions, stability, and modulation quality | Overmodulation indication or prevention: Required for SSB and for voice-transmission quality control; overmodulation means driving the audio past the clean limit so the signal distorts and can splatter. | Retained; reference-facts-automatic-signals-still-need-clean-control. |
| Reference facts: Repeaters, automatic transmissions, stability, and modulation quality | Voice modulation maximum: 100%, meaning full modulation without going past the clean voice limit. | Retained; reference-facts-automatic-signals-still-need-clean-control. |
| Reference facts: Repeaters, automatic transmissions, stability, and modulation quality | Frequency measurement: All amateur stations must be capable of reliably measuring frequency, regardless of emission mode. | Retained; reference-facts-automatic-signals-still-need-clean-control. |

## L-001-05 baseline inventory

| Before section | Taught fact before rewrite | After section / comparison |
|---|---|---|
| Reference facts: Third-party and visiting-operator communication | Third-party communications: Conducted on behalf of a person without amateur radio certification. | Retained; reference-facts-a-guest-speaks-under-supervision. |
| Reference facts: Third-party and visiting-operator communication | Third-party content in the Canadian amateur service: Personal and non-commercial only. | Retained; reference-facts-a-guest-speaks-under-supervision. |
| Reference facts: Third-party and visiting-operator communication | Canadian third-party communications: May be provided with any other amateur radio station. | Retained; reference-facts-a-guest-speaks-under-supervision. |
| Reference facts: Third-party and visiting-operator communication | Canadian international third-party traffic: Canada permits international communications on behalf of third parties. | Retained; reference-facts-a-guest-speaks-under-supervision. |
| Reference facts: Third-party and visiting-operator communication | International emergency or disaster-relief third-party traffic: Expressly permitted; a specific prohibition by the foreign administration concerned is the only bar. | Retained; reference-facts-a-guest-speaks-under-supervision. |
| Reference facts: Third-party and visiting-operator communication | Foreign administration objection to communication: A country can preclude communication by filing an objection with the ITU. | Retained; reference-facts-international-permission-includes-purpose. |
| Reference facts: Third-party and visiting-operator communication | Foreign visitors other than United States citizens: Their country must have an agreement with Canada and the operator must have the appropriate permit. | Retained; reference-facts-visit-arrangements-pair-permission-with-identification. |
| Reference facts: Third-party and visiting-operator communication | CEPT amateur licence holders operating in Canada: Granted Advanced privileges by ISED. | Retained; reference-facts-visit-arrangements-pair-permission-with-identification. |
| Reference facts: Third-party and visiting-operator communication | United States-issued call sign holder operating in Canada: Must indicate location by city and province at least once during a contact. | Retained; reference-facts-visit-arrangements-pair-permission-with-identification. |
| Reference facts: Third-party and visiting-operator communication | United States-issued call sign holder in Canada using voice: Identifies with the call sign, mobile or portable qualifier, and the Canadian prefix for the station's geographic location. | Retained; reference-facts-visit-arrangements-pair-permission-with-identification. |
| Reference facts: Third-party and visiting-operator communication | Supervising a non-certified guest during a contact: Keep supervising and monitoring the guest, including if a foreign station joins, because you remain responsible for the station and international third-party traffic depends on the foreign administration not objecting. | Retained; reference-facts-a-guest-speaks-under-supervision. |
| Reference facts: Third-party and visiting-operator communication | Local non-certified participants at both ends: Both non-certified people are third parties. | Retained; reference-facts-a-guest-speaks-under-supervision. |
| Reference facts: International message purpose and regulatory source | Messages to an amateur station in a foreign country: Related to amateur-radio purposes or remarks of a personal nature. | Retained; reference-facts-international-permission-includes-purpose. |
| Reference facts: International message purpose and regulatory source | Operator duty for international communications: Limit them to amateur-radio purposes or personal remarks. | Retained; reference-facts-international-permission-includes-purpose. |
| Reference facts: International message purpose and regulatory source | Administration objection: International communications are permitted in the absence of a registered administration objection. | Retained; reference-facts-international-permission-includes-purpose. |
| Reference facts: International message purpose and regulatory source | Morse-code proficiency in ITU Radio Regulations: Administrations determine whether it is required for authorization. | Retained; reference-facts-international-permission-includes-purpose. |
| Reference facts: International message purpose and regulatory source | Radio regulations beyond Canadian Act and Regulations: International Telecommunication Union. | Retained; reference-facts-location-decides-the-applicable-limits. |
| Reference facts: ITU regions and operating location | Canada: ITU Region 2. | Retained; reference-facts-location-decides-the-applicable-limits. |
| Reference facts: ITU regions and operating location | Europe and Africa: ITU Region 1. | Retained; reference-facts-location-decides-the-applicable-limits. |
| Reference facts: ITU regions and operating location | Australia, Japan, and Southeast Asia: ITU Region 3. | Retained; reference-facts-location-decides-the-applicable-limits. |
| Reference facts: ITU regions and operating location | Canadian operator in Florida: Subject to frequency band limits applicable to United States amateur radio operators. | Retained; reference-facts-location-decides-the-applicable-limits. |
| Reference facts: ITU regions and operating location | Canadian operator seven kilometres offshore from Florida: Subject to frequency band limits applicable to United States amateur radio operators because 7 km is inside the United States territorial sea. | Retained; reference-facts-location-decides-the-applicable-limits. |
| Reference facts: United States and CEPT-style visits | Canadian operator in the United States: Basic is the minimum Canadian qualification for this visit arrangement. | Retained; reference-facts-visit-arrangements-pair-permission-with-identification. |
| Reference facts: United States and CEPT-style visits | Canadian operator in the United States using voice: Transmit the Canadian call sign, then portable or mobile as appropriate, then the prefix for the US call area being visited. | Retained; reference-facts-visit-arrangements-pair-permission-with-identification. |
| Reference facts: United States and CEPT-style visits | Canadian operator using a CEPT Amateur Radio Licence in a participating country: Advanced is the minimum Canadian qualification for this visit arrangement. | Retained; reference-facts-visit-arrangements-pair-permission-with-identification. |
| Reference facts: United States and CEPT-style visits | CEPT participating country using voice: Transmit the visited country's prefix, then "stroke," then the Canadian call sign. | Retained; reference-facts-visit-arrangements-pair-permission-with-identification. |

## L-001-06 baseline inventory

| Before section | Taught fact before rewrite | After section / comparison |
|---|---|---|
| Reference facts: Antenna siting and public consultation | Installation or modification of an antenna structure: Consultation duties can apply to antenna structures. | Retained; reference-facts-follow-the-applicable-consultation-process. |
| Reference facts: Antenna siting and public consultation | Antenna installations, including masts and towers: Authority rests with the Minister of Innovation, Science and Industry. | Retained; reference-facts-follow-the-applicable-consultation-process. |
| Reference facts: Antenna siting and public consultation | ISED-defined exclusion criterion: An exclusion can remove the requirement to contact land-use authorities to determine public consultation requirements. | Retained; reference-facts-follow-the-applicable-consultation-process. |
| Reference facts: Antenna siting and public consultation | No local land-use approval process: Follow ISED's default public consultation process. | Retained; reference-facts-follow-the-applicable-consultation-process. |
| Reference facts: Antenna siting and public consultation | ISED default-process elements: Provide written notice, address relevant questions, comments, and concerns, and give the public an opportunity to respond to the measures taken. | Retained; reference-facts-follow-the-applicable-consultation-process. |
| Reference facts: Antenna siting and public consultation | ISED default-process concerns: Address reasonable and relevant concerns provided in writing within the 30-day public comment period. | Retained; reference-facts-follow-the-applicable-consultation-process. |
| Reference facts: Antenna siting and public consultation | Municipality with a consultation process: Exclusion by the municipal process OR by CPC-2-0-03 can remove the public-consultation requirement. | Retained; reference-facts-follow-the-applicable-consultation-process. |
| Reference facts: Antenna siting and public consultation | Proponent and non-public stakeholder fail to agree: ISED makes the final decision. | Retained; reference-facts-follow-the-applicable-consultation-process. |
| Reference facts: Antenna siting and public consultation | Tallest structure without public consultation: The tallest exempted by the land-use authority or ISED. | Retained; reference-facts-follow-the-applicable-consultation-process. |
| Reference facts: Antenna siting and public consultation | Local process exists: The municipality or local land-use authority determines how public consultation should take place. | Retained; reference-facts-follow-the-applicable-consultation-process. |
| Reference facts: Safety Code 6 and RF exposure | Organization publishing guidelines for maximum RF energy near the human body: Health Canada. | Retained; reference-facts-protect-people-by-assessing-exposure. |
| Reference facts: Safety Code 6 and RF exposure | Purpose of Safety Code 6: Gives RF exposure limits for the human body. | Retained; reference-facts-protect-people-by-assessing-exposure. |
| Reference facts: Safety Code 6 and RF exposure | Greatest RF-energy risk range: 48 MHz to 300 MHz. | Retained; reference-facts-protect-people-by-assessing-exposure. |
| Reference facts: Safety Code 6 and RF exposure | Reason for the lowest exposure limit in that range: The human body absorbs RF energy the most in this range. | Retained; reference-facts-protect-people-by-assessing-exposure. |
| Reference facts: Safety Code 6 and RF exposure | Maximum safe power output to the antenna of a hand-held VHF or UHF radio: No specified value. | Retained; reference-facts-protect-people-by-assessing-exposure. |
| Reference facts: Safety Code 6 and RF exposure | Basic exposure situations: Controlled and uncontrolled environments; uncontrolled areas include the general public and have lower public limits. | Retained; reference-facts-protect-people-by-assessing-exposure. |
| Reference facts: Safety Code 6 and RF exposure | Other established adverse effect below 10 MHz: Nerve stimulation. | Retained; reference-facts-protect-people-by-assessing-exposure. |
| Reference facts: Safety Code 6 and RF exposure | Hand-held transmitters: Included in Safety Code 6 requirements. | Retained; reference-facts-protect-people-by-assessing-exposure. |
| Reference facts: Safety Code 6 and RF exposure | Transmitter exemptions: No transmitters are exempt. | Retained; reference-facts-protect-people-by-assessing-exposure. |
| Reference facts: Safety Code 6 and RF exposure | Exposure quantities: Safety Code 6 uses exposure quantities such as fields, currents, and absorption rate. | Retained; reference-facts-protect-people-by-assessing-exposure. |
| Reference facts: Safety Code 6 and RF exposure | Exposure factors: Antenna gain, distance, transmitter power, and frequency. | Retained; reference-facts-protect-people-by-assessing-exposure. |
| Reference facts: EMCAB-2 interference criteria | Stereo-system complaint: Lack of immunity is the cause when field strength at the neighbour's premises is below ISED's specified immunity criteria. | Retained; reference-facts-investigate-interference-at-the-affected-equipment. |
| Reference facts: EMCAB-2 interference criteria | Television-receiver complaint: The amateur transmission is the cause when field strength at the neighbour's premises is above ISED's specified immunity criteria. | Retained; reference-facts-investigate-interference-at-the-affected-equipment. |
| Reference facts: EMCAB-2 interference criteria | Home-entertainment devices outside the strict radio-apparatus category: Associated equipment, such as audio or video recorders, playback devices, and amplifiers used with radio apparatus. | Retained; reference-facts-investigate-interference-at-the-affected-equipment. |
| Reference facts: EMCAB-2 interference criteria | Garage door opener affected by transmissions: Radio-sensitive equipment, meaning other non-radio electronic equipment whose function can be affected by radio emissions. | Retained; reference-facts-investigate-interference-at-the-affected-equipment. |

## Prose-only teaching comparison

The baseline inventory above includes all 202 reference-table rows (including repeated facts). The following checks cover teaching outside those tables. Shorter station stories retain their operating point; incidental packing or binder suggestions are not new rules.

| Lesson | Teaching extracted from baseline prose | After / comparison |
|---|---|---|
| L-001-01 | Act grants powers; Regulations and standards work in parallel, while ISED administers. Lifetime validity does not end address, retention or inspection duties. | Retained in Authority comes from named sources, A lifetime certificate needs current records, and How these rules fit together. |
| L-001-01 | RGMC is a named certificate route, not a derived calculation. Accommodations change delivery, not required content. Reading/language oral delivery follows a written failure; answers remain personal in English/French. Physician evidence may be required. | Retained in Qualifications follow a learning path. |
| L-001-01 | Study aids differ from exam aids. Download the unlabelled English ISED exam sheet; training version has labels. Follow examiner identification and scrap-paper instructions; virtual exams require workspace visibility, printed answer sheet, camera and microphone. Mock practice uses one item per subsection and an optional timer. | Retained in Exam aids support skills, not stored answers and Radio connection. The live downloads URL remains. |
| L-001-02 | Check both people's authorization and the service, not who owns tools. Channel memories do not merge services. Publishing a digital method answers openness only. | Retained in Both sides need authority, Messages stay open and non-commercial, How these rules fit together, and club work-day connection. |
| L-001-02 | Cross-band repeater receives on one band and sends on another; a beacon identifies or supports propagation checks. Control point is where the signal can be controlled/stopped. Control and ownership responsibilities continue during guest use. | Retained before/within the station-work matrix and Control stays with responsible people. |
| L-001-03 | Protect primary services; classify routine, own-distress, unanswered distress response and organized relief separately. Direct distress involvement of your own station is the interference exception. Safety broadcasting does not open general public broadcasting. | Retained in Share spectrum without harm and Life safety has narrow exceptions. |
| L-001-03 | Other non-broadcast disclosure has specific lawful purposes (protection, evidence, defence/security), not media enquiries. Identification is start/end/interval; a clock supports net discipline. | Retained in Message handling stays unpaid, Make the station traceable, and public-service net connection. |
| L-001-04 | Fewer qualifications governs both call-sign-owner and control-operator cases. Basic-only direct transmission stays above 30 MHz; the 29.500 MHz fact concerns repeater output. Honours/Morse keep Basic power. | Retained in companion access/power matrix, including distinction between repeater input and output. |
| L-001-04 | Whole emission must fit at an edge; dial value is not full signal width. Lower edges double 3.5 → 7 → 14 → 28 MHz; 21 MHz is 3 x 7. Upper edges must be learned separately. Thirty metres is too narrow for SSB. | Retained in Band edges contain the whole signal and Mode width must fit the band. The exact bank examples for ATV and SSB are now applications of these band-wide rules, not individual answer-key rows. |
| L-001-04 | DC input, carrier output, PEP, ERP and EIRP are different quantities. ERP uses dipole reference; EIRP isotropic reference; gain matters. Minimum-power and special-band/exposure ceilings coexist. | Retained in access/power matrix and Power needs a quantity and a measurement point. |
| L-001-04 | Whole-radio 20 A x 13.8 V = 276 W is not final-stage DC input; 100 W RF display is not DC input. Output connector is before tuner; radiated limits include gain. Quartz control resists drift; overdrive distorts/splatters. | Retained in supply-draw connection, power table and Automatic signals still need clean control. |
| L-001-05 | Third parties may be present at both stations; certified supervision continues if a foreign station joins. The foreign administration may object. | Retained in A guest speaks under supervision and International permission includes purpose. |
| L-001-05 | Region 2 includes the Americas; regions do not replace destination authority. Seven kilometres is about 3.8 nautical miles, inside the 12-nautical-mile (about 22 km) US territorial sea. | Retained in Location decides the applicable limits. |
| L-001-05 | US visits lead with home call, CEPT with host prefix. CEPT pairs with Advanced in both directions. Travel card records location, permission, limits, ID and third-party conditions. | Retained in Visit arrangements pair permission with identification, How these rules fit together and travel card connection. |
| L-001-06 | CPC-2-0-03 is ISED's siting procedure; local or ISED exclusion, default process, written concerns, applicable height exemption and final ISED decision are distinct checks. | Retained in Follow the applicable consultation process. |
| L-001-06 | Controlled environments have assessed fields and people who understand/can control exposure; uncontrolled includes public and has lower limits. Body resonance explains VHF absorption; 80 MHz half-wave about 1.9 m is only a rough body-length model. Power, gain, distance and frequency combine. | Retained in Protect people by assessing exposure; the model's limitation is stated explicitly. |
| L-001-06 | EMC means functioning in radio environment; EMCAB-2 compares fields at affected premises to category-specific immunity criteria. Radio-sensitive equipment excludes radio apparatus, distinct from broadcast receivers and associated equipment. Three records separate consultation, exposure and interference. | Retained in Investigate interference at the affected equipment, How these rules fit together and three-record connection. |

## Every-question teaching cross-check

Each row below was checked against the active bank and both lesson versions. The preceding inventory gives the baseline facts and original sections. Here, “Retained” means the revised principle teaches the needed rule, not merely that the ID is still in a quiz. Where an answer-key-shaped numeric case was consolidated, the band-wide or qualification-wide rule now teaches it. Each B-001 ID appears exactly once below.

| Bank ID | Fact checked before and after (original paraphrase) | Revised teaching location / comparison |
|---|---|---|
| B-001-001-001 | Act supplies regulation-making power. | Retained; L-001-01#reference-facts-authority-comes-from-named-sources. |
| B-001-001-002 | Act supplies power to issue operating standards. | Retained; L-001-01#reference-facts-authority-comes-from-named-sources. |
| B-001-001-003 | ISED administers the Act. | Retained; L-001-01#reference-facts-authority-comes-from-named-sources. |
| B-001-001-004 | Regulations supply the service definition. | Retained; L-001-01#reference-facts-authority-comes-from-named-sources. |
| B-001-002-001 | Address-update duty: notify ISED within 30 days. | Retained; L-001-01#reference-facts-a-lifetime-certificate-needs-current-records. |
| B-001-002-002 | Certificate lifetime validity. | Retained; L-001-01#reference-facts-a-lifetime-certificate-needs-current-records. |
| B-001-002-003 | Address-update duty also applies after a move. | Retained; L-001-01#reference-facts-a-lifetime-certificate-needs-current-records. |
| B-001-002-004 | Keep certificate at station. | Retained; L-001-01#reference-facts-a-lifetime-certificate-needs-current-records. |
| B-001-002-005 | 48-hour response to certificate inspection request. | Retained; L-001-01#reference-facts-a-lifetime-certificate-needs-current-records. |
| B-001-002-006 | First certificate has no fee. | Retained; L-001-01#reference-facts-a-lifetime-certificate-needs-current-records. |
| B-001-002-007 | Keep certificate at address supplied to ISED. | Retained; L-001-01#reference-facts-a-lifetime-certificate-needs-current-records. |
| B-001-002-008 | New provincial/territorial prefix after moving has no fee. | Retained; L-001-01#reference-facts-a-lifetime-certificate-needs-current-records. |
| B-001-002-009 | Voluntary call-sign change costs $60, including two-letter change. | Retained; L-001-01#reference-facts-a-lifetime-certificate-needs-current-records. |
| B-001-003-001 | Outside-band operation is prohibited and can penalize control operator. | Retained; L-001-01#reference-facts-trust-needs-honest-signals-and-fair-process. |
| B-001-003-002 | Distress wording without distress is false/fraudulent. | Retained; L-001-01#reference-facts-trust-needs-honest-signals-and-fair-process. |
| B-001-003-003 | False distress penalty: up to $5 000 and/or a year in prison. | Retained; L-001-01#reference-facts-trust-needs-honest-signals-and-fair-process. |
| B-001-003-004 | Act contains the offences and penalties. | Retained; L-001-01#reference-facts-authority-comes-from-named-sources. |
| B-001-003-005 | Suspension includes notice and opportunity to respond. | Retained; L-001-01#reference-facts-trust-needs-honest-signals-and-fair-process. |
| B-001-003-006 | Dwelling entry needs consent or warrant. | Retained; L-001-01#reference-facts-trust-needs-honest-signals-and-fair-process. |
| B-001-003-007 | False information is prohibited. | Retained; L-001-01#reference-facts-trust-needs-honest-signals-and-fair-process. |
| B-001-003-008 | Unlawful interference/obstruction has same fine/prison ceiling. | Retained; L-001-01#reference-facts-trust-needs-honest-signals-and-fair-process. |
| B-001-004-001 | Basic has no age restriction. | Retained; L-001-01#reference-facts-qualifications-follow-a-learning-path. |
| B-001-004-002 | Basic precedes initial certification. | Retained; L-001-01#reference-facts-qualifications-follow-a-learning-path. |
| B-001-004-003 | RGMC is the named alternate certificate route. | Retained; L-001-01#reference-facts-qualifications-follow-a-learning-path. |
| B-001-004-004 | Later qualification sequence is unrestricted after Basic. | Retained; L-001-01#reference-facts-qualifications-follow-a-learning-path. |
| B-001-004-005 | Morse sending and receiving rate is 5 words per minute. | Retained; L-001-01#reference-facts-qualifications-follow-a-learning-path. |
| B-001-004-006 | Advanced still authorizes only the amateur service. | Retained; L-001-01#reference-facts-qualifications-follow-a-learning-path. |
| B-001-004-007 | Candidate needs a valid Canadian address. | Retained; L-001-01#reference-facts-qualifications-follow-a-learning-path. |
| B-001-005-001 | Advanced apparatus work still requires the recipient to be authorized. | Retained; L-001-02#reference-facts-both-sides-need-authority. |
| B-001-005-002 | Recipient of 2 m reprogramming needs amateur certification. | Retained; L-001-02#reference-facts-both-sides-need-authority. |
| B-001-005-003 | Two certificates needed for installing another person’s amateur transmitter. | Retained; L-001-02#reference-facts-both-sides-need-authority. |
| B-001-005-004 | Basic-plus-Morse installer still checks recipient’s amateur certificate. | Retained; L-001-02#reference-facts-both-sides-need-authority. |
| B-001-005-005 | Two certificates needed for repairing another person’s amateur transmitter. | Retained; L-001-02#reference-facts-both-sides-need-authority. |
| B-001-005-006 | Two certificates needed for commissioning another person’s amateur transmitter. | Retained; L-001-02#reference-facts-both-sides-need-authority. |
| B-001-006-001 | 2 W does not remove qualified supervision and call-sign duties. | Retained; L-001-02#reference-facts-both-sides-need-authority. |
| B-001-006-002 | Normal contacts use stations with similar authorization. | Retained; L-001-02#reference-facts-both-sides-need-authority. |
| B-001-006-003 | Amateur amplifier cannot boost licence-exempt transmitter. | Retained; L-001-02#reference-facts-both-sides-need-authority. |
| B-001-006-004 | Modification does not certify amateur equipment for other bands. | Retained; L-001-02#reference-facts-both-sides-need-authority. |
| B-001-006-005 | Amateur authorization does not cover aeronautical, marine or land-mobile use. | Retained; L-001-02#reference-facts-both-sides-need-authority. |
| B-001-006-006 | Land-mobile channels require equipment certification and licensing for that service. | Retained; L-001-02#reference-facts-both-sides-need-authority. |
| B-001-007-001 | Club-net business planning is outside amateur purposes. | Retained; L-001-02#reference-facts-messages-stay-open-and-non-commercial. |
| B-001-007-002 | No routine broadcasting to the general public. | Retained; L-001-02#reference-facts-messages-stay-open-and-non-commercial. |
| B-001-007-003 | Occasional business is still business. | Retained; L-001-02#reference-facts-messages-stay-open-and-non-commercial. |
| B-001-007-004 | One-way amateur uses differ from public broadcasts. | Retained; L-001-02#reference-facts-messages-stay-open-and-non-commercial. |
| B-001-007-005 | New encoding must be publicly published before use. | Retained; L-001-02#reference-facts-messages-stay-open-and-non-commercial. |
| B-001-007-006 | Encoding must have open meaning. | Retained; L-001-02#reference-facts-messages-stay-open-and-non-commercial. |
| B-001-007-007 | Abbreviations and procedure signals must have open meaning. | Retained; L-001-02#reference-facts-messages-stay-open-and-non-commercial. |
| B-001-007-008 | Lower background audio so non-amateur material is not retransmitted. | Retained; L-001-02#reference-facts-messages-stay-open-and-non-commercial. |
| B-001-007-009 | Secret codes are prohibited. | Retained; L-001-02#reference-facts-messages-stay-open-and-non-commercial. |
| B-001-007-010 | Open Q codes are permitted. | Retained; L-001-02#reference-facts-messages-stay-open-and-non-commercial. |
| B-001-007-011 | Business traffic remains prohibited. | Retained; L-001-02#reference-facts-messages-stay-open-and-non-commercial. |
| B-001-008-001 | Certificate allows operation across Canada within applicable limits. | Retained; L-001-02#reference-facts-qualification-by-privilege-matrix-for-station-work. |
| B-001-008-002 | Beacon can send one-way signals. | Retained; L-001-02#reference-facts-qualification-by-privilege-matrix-for-station-work. |
| B-001-008-003 | Basic permits assembly of commercially available professional-design kits. | Retained; L-001-02#reference-facts-qualification-by-privilege-matrix-for-station-work. |
| B-001-008-004 | Installing a single-band voice repeater needs Basic plus Advanced. | Retained; L-001-02#reference-facts-qualification-by-privilege-matrix-for-station-work. |
| B-001-008-005 | Installing a club station needs Basic plus Advanced. | Retained; L-001-02#reference-facts-qualification-by-privilege-matrix-for-station-work. |
| B-001-008-006 | Gear lacking both professional design and amateur commercial manufacture needs Advanced for installation/use. | Retained; L-001-02#reference-facts-qualification-by-privilege-matrix-for-station-work. |
| B-001-008-007 | Basic permits cross-band repeater operation. | Retained; L-001-02#reference-facts-qualification-by-privilege-matrix-for-station-work. |
| B-001-008-008 | Remote changes to frequency, mode or power need Basic plus Advanced. | Retained; L-001-02#reference-facts-qualification-by-privilege-matrix-for-station-work. |
| B-001-009-001 | Owner and control operator both responsible. | Retained; L-001-02#reference-facts-control-stays-with-responsible-people. |
| B-001-009-002 | Visitor transmitting at another station shares responsibility with owner. | Retained; L-001-02#reference-facts-control-stays-with-responsible-people. |
| B-001-009-003 | Owner keeps responsibility for compliant operation. | Retained; L-001-02#reference-facts-control-stays-with-responsible-people. |
| B-001-009-004 | Owner selects a suitably qualified control operator. | Retained; L-001-02#reference-facts-control-stays-with-responsible-people. |
| B-001-009-005 | Every transmission needs a control operator. | Retained; L-001-02#reference-facts-control-stays-with-responsible-people. |
| B-001-009-006 | Control operator stays at control point during transmission. | Retained; L-001-02#reference-facts-control-stays-with-responsible-people. |
| B-001-009-007 | Unqualified family member alone cannot take control. | Retained; L-001-02#reference-facts-control-stays-with-responsible-people. |
| B-001-009-008 | Guest operation needs qualified presence and supervision. | Retained; L-001-02#reference-facts-control-stays-with-responsible-people. |
| B-001-009-009 | No-certificate participant needs appropriately qualified presence and supervision. | Retained; L-001-02#reference-facts-control-stays-with-responsible-people. |
| B-001-010-001 | Disturbing other communication is harmful interference. | Retained; L-001-03#reference-facts-share-spectrum-without-harm. |
| B-001-010-002 | No deliberate interference in ordinary operation. | Retained; L-001-03#reference-facts-share-spectrum-without-harm. |
| B-001-010-003 | Secondary use protects primary services. | Retained; L-001-03#reference-facts-share-spectrum-without-harm. |
| B-001-010-004 | Amateurs have equal frequency access rights. | Retained; L-001-03#reference-facts-share-spectrum-without-harm. |
| B-001-010-005 | Serious degradation, obstruction and repeated interruption are harmful interference. | Retained; L-001-03#reference-facts-share-spectrum-without-harm. |
| B-001-010-006 | Minister may order harmful operation stopped or changed. | Retained; L-001-03#reference-facts-share-spectrum-without-harm. |
| B-001-010-007 | 430–450 MHz requires protection of other services. | Retained; L-001-03#reference-facts-share-spectrum-without-harm. |
| B-001-010-008 | 902–928 MHz amateur use has no protection from other-service interference. | Retained; L-001-03#reference-facts-share-spectrum-without-harm. |
| B-001-010-009 | Tests protect amateur and other services from interference. | Retained; L-001-03#reference-facts-share-spectrum-without-harm. |
| B-001-010-010 | 902–928 MHz may have heavy licence-exempt use. | Retained; L-001-03#reference-facts-share-spectrum-without-harm. |
| B-001-011-001 | Normal amateur communication is between amateur stations. | Retained; L-001-03#reference-facts-life-safety-has-narrow-exceptions. |
| B-001-011-002 | Organized disaster relief stays on amateur bands. | Retained; L-001-03#reference-facts-life-safety-has-narrow-exceptions. |
| B-001-011-003 | Unanswered amateur-band distress may be answered beyond normal privileges. | Retained; L-001-03#reference-facts-life-safety-has-narrow-exceptions. |
| B-001-011-004 | Necessary life/property safety traffic has broadcasting exception. | Retained; L-001-03#reference-facts-life-safety-has-narrow-exceptions. |
| B-001-011-005 | Operator in distress may use any radiocommunication means. | Retained; L-001-03#reference-facts-life-safety-has-narrow-exceptions. |
| B-001-011-006 | Relief supports essential needs when normal systems are overloaded, damaged or disrupted. | Retained; L-001-03#reference-facts-life-safety-has-narrow-exceptions. |
| B-001-011-007 | Operator in distress has no power limitation. | Retained; L-001-03#reference-facts-life-safety-has-narrow-exceptions. |
| B-001-011-008 | Nonparticipants leave relief frequency and nearby space clear. | Retained; L-001-03#reference-facts-life-safety-has-narrow-exceptions. |
| B-001-011-009 | Agency traffic is allowed in peacetime, emergencies and exercises. | Retained; L-001-03#reference-facts-life-safety-has-narrow-exceptions. |
| B-001-011-010 | Own station’s direct distress involvement is the interference exception. | Retained; L-001-03#reference-facts-life-safety-has-narrow-exceptions. |
| B-001-012-001 | Third-party traffic accepts no payment of any kind. | Retained; L-001-03#reference-facts-message-handling-stays-unpaid. |
| B-001-012-002 | Non-broadcast amateur content can be shared/used. | Retained; L-001-03#reference-facts-message-handling-stays-unpaid. |
| B-001-012-003 | Message exchanges cannot earn remuneration. | Retained; L-001-03#reference-facts-message-handling-stays-unpaid. |
| B-001-012-004 | Other non-broadcast disclosure needs a lawful purpose; media enquiry is not one. | Retained; L-001-03#reference-facts-message-handling-stays-unpaid. |
| B-001-013-001 | Canadian call shape: recognized prefix, numeral, suffix. | Retained; L-001-03#reference-facts-make-the-station-traceable. |
| B-001-013-002 | Identification at contact start/end and within 30-minute intervals. | Retained; L-001-03#reference-facts-make-the-station-traceable. |
| B-001-013-003 | Identify with station call sign. | Retained; L-001-03#reference-facts-make-the-station-traceable. |
| B-001-013-004 | Both stations identify at start. | Retained; L-001-03#reference-facts-make-the-station-traceable. |
| B-001-013-005 | Both stations identify at end. | Retained; L-001-03#reference-facts-make-the-station-traceable. |
| B-001-013-006 | 30-minute maximum identification gap. | Retained; L-001-03#reference-facts-make-the-station-traceable. |
| B-001-013-007 | Model control is the only unidentified-communication exception. | Retained; L-001-03#reference-facts-make-the-station-traceable. |
| B-001-013-008 | Identification in English or French. | Retained; L-001-03#reference-facts-make-the-station-traceable. |
| B-001-013-009 | Contact endpoints plus 30-minute interval all apply. | Retained; L-001-03#reference-facts-make-the-station-traceable. |
| B-001-013-010 | Tests use contact identification rules. | Retained; L-001-03#reference-facts-make-the-station-traceable. |
| B-001-013-011 | Normal Canadian prefixes VA, VE, VO, VY. | Retained; L-001-03#reference-facts-make-the-station-traceable. |
| B-001-014-001 | Supervision continues if a foreign station joins guest contact. | Retained; L-001-05#reference-facts-a-guest-speaks-under-supervision. |
| B-001-014-002 | Non-US visitor needs agreement and appropriate permit. | Retained; L-001-05#reference-facts-visit-arrangements-pair-permission-with-identification. |
| B-001-014-003 | Canada permits international third-party traffic. | Retained; L-001-05#reference-facts-a-guest-speaks-under-supervision. |
| B-001-014-004 | Administration can bar contacts through ITU objection. | Retained; L-001-05#reference-facts-international-permission-includes-purpose. |
| B-001-014-005 | CEPT licence visitor receives Advanced privileges in Canada. | Retained; L-001-05#reference-facts-visit-arrangements-pair-permission-with-identification. |
| B-001-014-006 | Third parties lack certification; their traffic stays personal/non-commercial. | Retained; L-001-05#reference-facts-a-guest-speaks-under-supervision. |
| B-001-014-007 | International relief third-party traffic allowed unless foreign administration prohibits. | Retained; L-001-05#reference-facts-a-guest-speaks-under-supervision. |
| B-001-014-008 | Non-certified people at both stations both count as third parties. | Retained; L-001-05#reference-facts-a-guest-speaks-under-supervision. |
| B-001-014-009 | US call holder in Canada states city/province at least once per contact. | Retained; L-001-05#reference-facts-visit-arrangements-pair-permission-with-identification. |
| B-001-014-010 | US voice visitor adds mobile/portable and Canadian location prefix after home call. | Retained; L-001-05#reference-facts-visit-arrangements-pair-permission-with-identification. |
| B-001-014-011 | Canadian third-party traffic can use any other amateur station. | Retained; L-001-05#reference-facts-a-guest-speaks-under-supervision. |
| B-001-015-001 | Less-qualified call-sign holder limits more-qualified guest using that call. | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-015-002 | Less-qualified control operator limits operation at more-qualified owner’s station. | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-015-003 | Basic plus Honours (80%), Advanced or Morse opens below-30-MHz access. | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-015-004 | Model-control access is amateur bands above 30 MHz. | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-015-005 | 80 m edges: 3.5–4.0 MHz. | Retained; L-001-04#reference-facts-band-edges-contain-the-whole-signal. |
| B-001-015-006 | 160 m edges: 1.8–2.0 MHz. | Retained; L-001-04#reference-facts-band-edges-contain-the-whole-signal. |
| B-001-015-007 | 40 m edges: 7.0–7.3 MHz. | Retained; L-001-04#reference-facts-band-edges-contain-the-whole-signal. |
| B-001-015-008 | 20 m edges: 14.000–14.350 MHz. | Retained; L-001-04#reference-facts-band-edges-contain-the-whole-signal. |
| B-001-015-009 | 15 m edges: 21.000–21.450 MHz. | Retained; L-001-04#reference-facts-band-edges-contain-the-whole-signal. |
| B-001-015-010 | 10 m edges: 28.000–29.700 MHz. | Retained; L-001-04#reference-facts-band-edges-contain-the-whole-signal. |
| B-001-015-011 | Model-control access is amateur bands above 30 MHz. | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-016-001 | 6 m and 2 m bandwidth ceiling is 30 kHz. | Retained; L-001-04#reference-facts-mode-width-must-fit-the-band. |
| B-001-016-002 | 10 m bandwidth ceiling is 20 kHz. | Retained; L-001-04#reference-facts-mode-width-must-fit-the-band. |
| B-001-016-003 | 7–25 MHz amateur bands have 6 kHz ceiling except 30 m. | Retained; L-001-04#reference-facts-mode-width-must-fit-the-band. |
| B-001-016-004 | 144–148 MHz bandwidth ceiling is 30 kHz. | Retained; L-001-04#reference-facts-mode-width-must-fit-the-band. |
| B-001-016-005 | 50–54 MHz bandwidth ceiling is 30 kHz. | Retained; L-001-04#reference-facts-mode-width-must-fit-the-band. |
| B-001-016-006 | 10.100–10.150 MHz is narrower than 6 kHz (1 kHz in RBR-4). | Retained; L-001-04#reference-facts-mode-width-must-fit-the-band. |
| B-001-016-007 | SSB excluded from 10.100–10.150 MHz. | Retained; L-001-04#reference-facts-mode-width-must-fit-the-band. |
| B-001-016-008 | Entire emission remains inside band. | Retained; L-001-04#reference-facts-band-edges-contain-the-whole-signal. |
| B-001-016-009 | ATV is too wide for 2 m, including 145 MHz. | Retained; L-001-04#reference-facts-mode-width-must-fit-the-band. |
| B-001-016-010 | ATV is too wide for 20 m, including 14.23 MHz. | Retained; L-001-04#reference-facts-mode-width-must-fit-the-band. |
| B-001-016-011 | 30 m excludes SSB, including 10.12 MHz. | Retained; L-001-04#reference-facts-mode-width-must-fit-the-band. |
| B-001-017-001 | Use no more legal power than needed for communication. | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-017-002 | Advanced SSB ceiling: 2 250 W PEP. | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-017-003 | Check evaluated output power at transmitter/external amplifier output. | Retained; L-001-04#reference-facts-power-needs-a-quantity-and-a-measurement-point. |
| B-001-017-004 | Basic plus Morse retains 560 W SSB PEP on eligible HF (including 3 750 kHz). | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-017-005 | Honours retains 560 W SSB PEP on eligible HF (including 7 055 kHz). | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-017-006 | Advanced 60 m ceiling: 100 W ERP expressed as PEP. | Retained; L-001-04#reference-facts-power-needs-a-quantity-and-a-measurement-point. |
| B-001-017-007 | Advanced final-stage DC input ceiling: 1 000 W. | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-017-008 | 630 m and 2 200 m EIRP checks include antenna gain. | Retained; L-001-04#reference-facts-power-needs-a-quantity-and-a-measurement-point. |
| B-001-017-009 | Basic final-stage DC input ceiling: 250 W. | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-017-010 | Without Advanced, non-SSB carrier ceiling: 190 W. | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-018-001 | Repeater automatically retransmits other stations. | Retained; L-001-04#reference-facts-automatic-signals-still-need-clean-control. |
| B-001-018-002 | Below-30-MHz unmodulated carrier is for brief tests. | Retained; L-001-04#reference-facts-automatic-signals-still-need-clean-control. |
| B-001-018-003 | Basic-only repeater output lower boundary: 29.500 MHz; own input still above 30 MHz. | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-018-004 | Lowest Basic-only repeater output segment: 29.500–29.700 MHz. | Retained; L-001-04#reference-facts-qualification-by-privilege-matrix-for-access-and-power. |
| B-001-019-001 | Below-148-MHz stability equivalent to crystal control. | Retained; L-001-04#reference-facts-automatic-signals-still-need-clean-control. |
| B-001-019-002 | SSB needs overmodulation prevention or indication. | Retained; L-001-04#reference-facts-automatic-signals-still-need-clean-control. |
| B-001-019-003 | Voice quality controls address overmodulation. | Retained; L-001-04#reference-facts-automatic-signals-still-need-clean-control. |
| B-001-019-004 | Voice modulation maximum: 100%. | Retained; L-001-04#reference-facts-automatic-signals-still-need-clean-control. |
| B-001-019-005 | All modes require reliable frequency measurement. | Retained; L-001-04#reference-facts-automatic-signals-still-need-clean-control. |
| B-001-019-006 | Voice modulation maximum: 100%. | Retained; L-001-04#reference-facts-automatic-signals-still-need-clean-control. |
| B-001-020-001 | Foreign messages stay amateur-purpose or personal. | Retained; L-001-05#reference-facts-international-permission-includes-purpose. |
| B-001-020-002 | Operator ensures international message-purpose limit. | Retained; L-001-05#reference-facts-international-permission-includes-purpose. |
| B-001-020-003 | International permission depends on absence of administration objection. | Retained; L-001-05#reference-facts-international-permission-includes-purpose. |
| B-001-020-004 | Administrations decide Morse authorization requirements. | Retained; L-001-05#reference-facts-international-permission-includes-purpose. |
| B-001-020-005 | ITU supplies additional international radio regulations. | Retained; L-001-05#reference-facts-location-decides-the-applicable-limits. |
| B-001-021-001 | Canada is ITU Region 2. | Retained; L-001-05#reference-facts-location-decides-the-applicable-limits. |
| B-001-021-002 | Florida operation uses US band limits. | Retained; L-001-05#reference-facts-location-decides-the-applicable-limits. |
| B-001-021-003 | 7 km off Florida remains in US territorial waters and uses US band limits. | Retained; L-001-05#reference-facts-location-decides-the-applicable-limits. |
| B-001-021-004 | Australia/Japan/Southeast Asia are ITU Region 3. | Retained; L-001-05#reference-facts-location-decides-the-applicable-limits. |
| B-001-021-005 | Europe/Africa are ITU Region 1. | Retained; L-001-05#reference-facts-location-decides-the-applicable-limits. |
| B-001-021-006 | Canadian CEPT visitor needs Advanced. | Retained; L-001-05#reference-facts-visit-arrangements-pair-permission-with-identification. |
| B-001-021-007 | CEPT voice order: host prefix, stroke, Canadian call. | Retained; L-001-05#reference-facts-visit-arrangements-pair-permission-with-identification. |
| B-001-021-008 | Canadian US visitor needs at least Basic. | Retained; L-001-05#reference-facts-visit-arrangements-pair-permission-with-identification. |
| B-001-021-009 | US voice order: Canadian call, portable/mobile, US area prefix. | Retained; L-001-05#reference-facts-visit-arrangements-pair-permission-with-identification. |
| B-001-022-001 | ISED office qualification exams have no charge. | Retained; L-001-01#reference-facts-qualifications-follow-a-learning-path. |
| B-001-022-002 | Disability delivery changes do not waive required exam portions. | Retained; L-001-01#reference-facts-qualifications-follow-a-learning-path. |
| B-001-022-003 | Accredited examiner may recover administration costs. | Retained; L-001-01#reference-facts-qualifications-follow-a-learning-path. |
| B-001-022-004 | ISED office qualification exams have no charge. | Retained; L-001-01#reference-facts-qualifications-follow-a-learning-path. |
| B-001-022-005 | Candidate answers personally in English/French; oral delivery is language aid. | Retained; L-001-01#reference-facts-qualifications-follow-a-learning-path. |
| B-001-023-001 | Antenna installation/modification can require consultation. | Retained; L-001-06#reference-facts-follow-the-applicable-consultation-process. |
| B-001-023-002 | Minister has authority over installations, masts and towers. | Retained; L-001-06#reference-facts-follow-the-applicable-consultation-process. |
| B-001-023-003 | ISED exclusion can remove land-use-authority contact requirement. | Retained; L-001-06#reference-facts-follow-the-applicable-consultation-process. |
| B-001-023-004 | Without local process, use ISED default. | Retained; L-001-06#reference-facts-follow-the-applicable-consultation-process. |
| B-001-023-005 | Default process: written notice, address concerns, public response opportunity. | Retained; L-001-06#reference-facts-follow-the-applicable-consultation-process. |
| B-001-023-006 | Address reasonable/relevant written concerns within 30-day comment period. | Retained; L-001-06#reference-facts-follow-the-applicable-consultation-process. |
| B-001-023-007 | Local-process or CPC-2-0-03 exclusion can remove public consultation requirement. | Retained; L-001-06#reference-facts-follow-the-applicable-consultation-process. |
| B-001-023-008 | ISED settles unresolved disagreement with non-public stakeholder. | Retained; L-001-06#reference-facts-follow-the-applicable-consultation-process. |
| B-001-023-009 | Height without consultation follows applicable exemption, not universal height. | Retained; L-001-06#reference-facts-follow-the-applicable-consultation-process. |
| B-001-023-010 | Local authority determines process where one exists. | Retained; L-001-06#reference-facts-follow-the-applicable-consultation-process. |
| B-001-024-001 | Health Canada publishes human RF exposure guidelines. | Retained; L-001-06#reference-facts-protect-people-by-assessing-exposure. |
| B-001-024-002 | Safety Code 6 limits human RF exposure. | Retained; L-001-06#reference-facts-protect-people-by-assessing-exposure. |
| B-001-024-003 | 48–300 MHz has greatest absorption-related risk in bank facts. | Retained; L-001-06#reference-facts-protect-people-by-assessing-exposure. |
| B-001-024-004 | Stronger human absorption explains lower limits in that range. | Retained; L-001-06#reference-facts-protect-people-by-assessing-exposure. |
| B-001-024-005 | No universal specified safe antenna-input power for a handheld. | Retained; L-001-06#reference-facts-protect-people-by-assessing-exposure. |
| B-001-024-006 | Both controlled and uncontrolled environments covered. | Retained; L-001-06#reference-facts-protect-people-by-assessing-exposure. |
| B-001-024-007 | Below 10 MHz, nerve stimulation is another established effect. | Retained; L-001-06#reference-facts-protect-people-by-assessing-exposure. |
| B-001-024-008 | Handhelds remain subject to Safety Code 6. | Retained; L-001-06#reference-facts-protect-people-by-assessing-exposure. |
| B-001-024-009 | No transmitter category is exempt. | Retained; L-001-06#reference-facts-protect-people-by-assessing-exposure. |
| B-001-024-010 | Exposure uses field/current/absorption quantities, not just antenna-feed watts. | Retained; L-001-06#reference-facts-protect-people-by-assessing-exposure. |
| B-001-025-001 | Below criterion at neighbour’s premises: stereo immunity is cause. | Retained; L-001-06#reference-facts-investigate-interference-at-the-affected-equipment. |
| B-001-025-002 | Above criterion at neighbour’s premises: amateur transmission is cause. | Retained; L-001-06#reference-facts-investigate-interference-at-the-affected-equipment. |
| B-001-025-003 | Home-entertainment supporting devices are associated equipment. | Retained; L-001-06#reference-facts-investigate-interference-at-the-affected-equipment. |
| B-001-025-004 | Garage door opener uses radio-sensitive equipment category. | Retained; L-001-06#reference-facts-investigate-interference-at-the-affected-equipment. |

## Verification after rewriting

Result: no covered regulatory or operating fact lost. The rewrite consolidates repeated facts and teaches the exact bank cases through the applicable general rule instead of one row per question. All six full front-matter blocks, every figure directive (including alt text and text equivalent), and every ordered official quiz list are unchanged from `8a82709b`. All six M1 quizzes still have `conceptChecks: []`. There is no lesson/quiz ID or coverage migration.

All 199 B-001 hint links now point to the teaching principle, including special cases where the fact moved between tables. Hint text, French fields, reference-sheet metadata and ladder levels are unchanged. The new `m1-principles.test.ts` checks the specific destination for every question, not just anchor existence. It also checks the companion matrix rows, Why columns, numbers board and completeness of this question index. The existing M1 reference-only checks in `lesson-faded-practice.test.ts` remain unchanged.

All six changed lessons contain figure directives: L-001-01 (`authority-records-exams`), L-001-02 (`station-control-decision-tree`), L-001-03 (`communications-flowchart`), L-001-04 (`privileges-station-checklist`), L-001-05 (`international-location-checklist`), L-001-06 (`antenna-rf-emc-checklists`). The directives and illustration briefs are unchanged. The coordinator runs the separate Apple figure plan because lesson positioning can change.

### Check results (2026-10-21)

| Command | Result |
|---|---|
| `node packages/content-tools/src/check-lesson-coverage.ts` | Passed: 100/100 subsections, 37 lessons, 8 modules, no duplicate coverage. |
| `pnpm --filter @canadian-ham/content-tools check:lesson-originality:all` | Passed: 37 lessons, 984 bank items, 0 issues, 15 active exceptions and 0 stale exceptions. M1 now needs only 7 numeric reference-table exceptions, down from 18 mixed numeric/wording exceptions. |
| `pnpm --filter @canadian-ham/content-tools check:explanations` | Passed: 984 explanations, 2 952 per-choice notes. |
| `pnpm --filter @canadian-ham/content-tools check:quizzes` | Passed: 37 quizzes, 521 official references and 92 concept checks repository-wide; M1's 199 official references and empty concept checks are unchanged. |
| `pnpm check:links` | Passed: relative Markdown links resolve. |
| `pnpm check:figures` | Passed: 53 checker fixtures, 39 SVGs and lesson references; Apple assets in sync. |
| `pnpm check:hints -- --require-complete` | Passed: 984/984 hints; all 199 B-001 anchors also checked against specific teaching destinations in the new regression test. |
| `pnpm check:schemas` | Passed: 2 071 validation targets, 58 tests. |
| `pnpm import:check` | Passed: both generated banks unchanged, 34 reference-sheet entries validated. |
| `node --test packages/content-tools/test/m1-principles.test.ts packages/content-tools/test/lesson-faded-practice.test.ts` | Passed: 71/71 tests, including 10 new M1 tests and the unchanged reference-only checks. |
| `pnpm test` (after installing all workspace dependencies) | Passed: release-permission self-test; content-tools 226/226; Morse 21/21; calculator 127/127; web 245/245 across 16 files. No load-flaky web reruns needed. |
| `pnpm typecheck` (after installing all workspace dependencies) | Passed across the workspace. |
| `cd packages/content-swift && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test` | Passed: 24/24, including bundled hint-anchor resolution, real-repository content loading and every-lesson Markdown parsing. |
| Before/after source invariant comparison against `8a82709b` | Passed: six entire front matters, six figure directives/text equivalents, six illustration briefs and six full quiz JSON files unchanged; 202 baseline table rows, 199 official questions and 199 anchor-only hint JSON changes. |

Initial environment-only failures: before a full workspace install, `pnpm test` stopped after the passing content-tools tests because Morse's `vitest` executable was missing; `pnpm typecheck` could not find `tsc` in sibling packages. `pnpm install --frozen-lockfile` installed the missing workspace dependencies without changing tracked files. Both full commands then passed. An initial new matrix-test selector also included the separate Basic-only repeater row; narrowing the selector to qualification rows fixed the test, with no content change or assertion removal.

The web run emitted existing jsdom canvas `getContext()` warnings but all 245 tests passed. No Apple app suites were run: this branch changes no Apple source, target membership, renderer or assets. The coordinator still runs the separate iOS lesson-figure plan for the six edited lessons listed above. UI round delivery is intentionally unimplemented here and leaves parent AC #3 open in TASK-46.8.1.
