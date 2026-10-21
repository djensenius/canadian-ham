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
| Reference facts: Operator privileges and below-30-MHz access | Another operator with additional qualifications controls your station under your call sign: Only the privileges allowed by your qualifications. | Pending rewrite comparison. |
| Reference facts: Operator privileges and below-30-MHz access | You control another station whose owner has more certificate qualifications: Only the privileges allowed by your qualifications. | Pending rewrite comparison. |
| Reference facts: Operator privileges and below-30-MHz access | Frequencies below 30 MHz: In addition to Basic, the operator needs 80% on Basic, or Advanced, or Morse code. | Pending rewrite comparison. |
| Reference facts: Operator privileges and below-30-MHz access | Radio-controlled models: Certificate holders may operate them on all amateur bands above 30 MHz. | Pending rewrite comparison. |
| Reference facts: Operator privileges and below-30-MHz access | Basic-only repeater use: Holders with only Basic may use repeaters whose output is at 29.500 MHz and above; this row does not open ordinary below-30-MHz transmitting. | Pending rewrite comparison. |
| Reference facts: Operator privileges and below-30-MHz access | Lowest Basic-only repeater output segment: 29.500 MHz to 29.700 MHz. | Pending rewrite comparison. |
| Reference facts: HF band ranges | 160 metres: 1.8 MHz to 2.0 MHz. | Pending rewrite comparison. |
| Reference facts: HF band ranges | 80 metres: 3.5 MHz to 4.0 MHz. | Pending rewrite comparison. |
| Reference facts: HF band ranges | 40 metres: 7.0 MHz to 7.3 MHz. | Pending rewrite comparison. |
| Reference facts: HF band ranges | 20 metres: 14.000 MHz to 14.350 MHz. | Pending rewrite comparison. |
| Reference facts: HF band ranges | 15 metres: 21.000 MHz to 21.450 MHz. | Pending rewrite comparison. |
| Reference facts: HF band ranges | 10 metres: 28.000 MHz to 29.700 MHz. | Pending rewrite comparison. |
| Reference facts: Bandwidth and mode-fit cues | 50 MHz to 54 MHz and 144 MHz to 148 MHz: 30 kHz maximum bandwidth. | Pending rewrite comparison. |
| Reference facts: Bandwidth and mode-fit cues | 28 MHz to 29.7 MHz: 20 kHz maximum bandwidth. | Pending rewrite comparison. |
| Reference facts: Bandwidth and mode-fit cues | Amateur bands between 7 MHz and 25 MHz, except the special narrow band: 6 kHz maximum bandwidth. | Pending rewrite comparison. |
| Reference facts: Bandwidth and mode-fit cues | 10.100 MHz to 10.150 MHz: 1 kHz maximum bandwidth in RBR-4, which is less than 6 kHz. | Pending rewrite comparison. |
| Reference facts: Bandwidth and mode-fit cues | 10.100 MHz to 10.150 MHz: Single sideband is prohibited. | Pending rewrite comparison. |
| Reference facts: Bandwidth and mode-fit cues | Transmitting near band edges: The entire occupied bandwidth must remain within the amateur band. | Pending rewrite comparison. |
| Reference facts: Bandwidth and mode-fit cues | CW / Morse radiotelegraphy: Narrower than SSB voice and FM voice in the mode-width ordering. | Pending rewrite comparison. |
| Reference facts: Bandwidth and mode-fit cues | FT8: A narrow digital mode, with many FT8 contacts fitting in the space needed for one SSB transmission. | Pending rewrite comparison. |
| Reference facts: Bandwidth and mode-fit cues | SSB voice: Usual SSB bandwidth is between 2 kHz and 3 kHz. | Pending rewrite comparison. |
| Reference facts: Bandwidth and mode-fit cues | FM voice: 5 kHz-deviation FM occupies between 10 kHz and 20 kHz; FM below 28 MHz exceeds regulatory bandwidth limits. | Pending rewrite comparison. |
| Reference facts: Bandwidth and mode-fit cues | Fast-scan television on 145 MHz: Prohibited because ATV exceeds the 30 kHz limit for 144 MHz to 148 MHz. | Pending rewrite comparison. |
| Reference facts: Bandwidth and mode-fit cues | Fast-scan television on 14.23 MHz: Prohibited because ATV exceeds the 6 kHz limit for amateur bands between 7 MHz and 25 MHz. | Pending rewrite comparison. |
| Reference facts: Power quantities and limits | General operating power: Use the minimum legal power necessary to communicate. | Pending rewrite comparison. |
| Reference facts: Power quantities and limits | Power verification after RF exposure and radiated-power limits are determined: Verify at the output of the transmitter or external amplifier. | Pending rewrite comparison. |
| Reference facts: Power quantities and limits | Basic, DC input to the final RF stage: 250 W. | Pending rewrite comparison. |
| Reference facts: Power quantities and limits | Basic, single-sideband peak envelope power: 560 W PEP. | Pending rewrite comparison. |
| Reference facts: Power quantities and limits | Basic and Morse, SSB on 3750 kHz: 560 W PEP. | Pending rewrite comparison. |
| Reference facts: Power quantities and limits | Basic with Honours, SSB on 7055 kHz: 560 W PEP. | Pending rewrite comparison. |
| Reference facts: Power quantities and limits | Basic-only non-SSB emissions for an operator without Advanced: 190 W carrier power. | Pending rewrite comparison. |
| Reference facts: Power quantities and limits | Advanced, DC input to the final RF stage: 1 000 W. | Pending rewrite comparison. |
| Reference facts: Power quantities and limits | Advanced, single-sideband peak envelope power: 2 250 W PEP. | Pending rewrite comparison. |
| Reference facts: Power quantities and limits | Advanced on the special band: On 60 metres, 100 W ERP expressed as PEP. | Pending rewrite comparison. |
| Reference facts: Power quantities and limits | 630 metres and 2200 metres: Antenna gain must be taken into account because limits are expressed as EIRP. | Pending rewrite comparison. |
| Reference facts: Repeaters, automatic transmissions, stability, and modulation quality | Repeater station: Automatically retransmits the signals of other stations. | Pending rewrite comparison. |
| Reference facts: Repeaters, automatic transmissions, stability, and modulation quality | Unmodulated carrier: May be transmitted only for brief tests on frequencies below 30 MHz. | Pending rewrite comparison. |
| Reference facts: Repeaters, automatic transmissions, stability, and modulation quality | Frequency stability: Equivalent to crystal control below 148 MHz; with crystal control, a quartz crystal sets the frequency so it drifts very little. | Pending rewrite comparison. |
| Reference facts: Repeaters, automatic transmissions, stability, and modulation quality | Overmodulation indication or prevention: Required for SSB and for voice-transmission quality control; overmodulation means driving the audio past the clean limit so the signal distorts and can splatter. | Pending rewrite comparison. |
| Reference facts: Repeaters, automatic transmissions, stability, and modulation quality | Voice modulation maximum: 100%, meaning full modulation without going past the clean voice limit. | Pending rewrite comparison. |
| Reference facts: Repeaters, automatic transmissions, stability, and modulation quality | Frequency measurement: All amateur stations must be capable of reliably measuring frequency, regardless of emission mode. | Pending rewrite comparison. |

## L-001-05 baseline inventory

| Before section | Taught fact before rewrite | After section / comparison |
|---|---|---|
| Reference facts: Third-party and visiting-operator communication | Third-party communications: Conducted on behalf of a person without amateur radio certification. | Pending rewrite comparison. |
| Reference facts: Third-party and visiting-operator communication | Third-party content in the Canadian amateur service: Personal and non-commercial only. | Pending rewrite comparison. |
| Reference facts: Third-party and visiting-operator communication | Canadian third-party communications: May be provided with any other amateur radio station. | Pending rewrite comparison. |
| Reference facts: Third-party and visiting-operator communication | Canadian international third-party traffic: Canada permits international communications on behalf of third parties. | Pending rewrite comparison. |
| Reference facts: Third-party and visiting-operator communication | International emergency or disaster-relief third-party traffic: Expressly permitted; a specific prohibition by the foreign administration concerned is the only bar. | Pending rewrite comparison. |
| Reference facts: Third-party and visiting-operator communication | Foreign administration objection to communication: A country can preclude communication by filing an objection with the ITU. | Pending rewrite comparison. |
| Reference facts: Third-party and visiting-operator communication | Foreign visitors other than United States citizens: Their country must have an agreement with Canada and the operator must have the appropriate permit. | Pending rewrite comparison. |
| Reference facts: Third-party and visiting-operator communication | CEPT amateur licence holders operating in Canada: Granted Advanced privileges by ISED. | Pending rewrite comparison. |
| Reference facts: Third-party and visiting-operator communication | United States-issued call sign holder operating in Canada: Must indicate location by city and province at least once during a contact. | Pending rewrite comparison. |
| Reference facts: Third-party and visiting-operator communication | United States-issued call sign holder in Canada using voice: Identifies with the call sign, mobile or portable qualifier, and the Canadian prefix for the station's geographic location. | Pending rewrite comparison. |
| Reference facts: Third-party and visiting-operator communication | Supervising a non-certified guest during a contact: Keep supervising and monitoring the guest, including if a foreign station joins, because you remain responsible for the station and international third-party traffic depends on the foreign administration not objecting. | Pending rewrite comparison. |
| Reference facts: Third-party and visiting-operator communication | Local non-certified participants at both ends: Both non-certified people are third parties. | Pending rewrite comparison. |
| Reference facts: International message purpose and regulatory source | Messages to an amateur station in a foreign country: Related to amateur-radio purposes or remarks of a personal nature. | Pending rewrite comparison. |
| Reference facts: International message purpose and regulatory source | Operator duty for international communications: Limit them to amateur-radio purposes or personal remarks. | Pending rewrite comparison. |
| Reference facts: International message purpose and regulatory source | Administration objection: International communications are permitted in the absence of a registered administration objection. | Pending rewrite comparison. |
| Reference facts: International message purpose and regulatory source | Morse-code proficiency in ITU Radio Regulations: Administrations determine whether it is required for authorization. | Pending rewrite comparison. |
| Reference facts: International message purpose and regulatory source | Radio regulations beyond Canadian Act and Regulations: International Telecommunication Union. | Pending rewrite comparison. |
| Reference facts: ITU regions and operating location | Canada: ITU Region 2. | Pending rewrite comparison. |
| Reference facts: ITU regions and operating location | Europe and Africa: ITU Region 1. | Pending rewrite comparison. |
| Reference facts: ITU regions and operating location | Australia, Japan, and Southeast Asia: ITU Region 3. | Pending rewrite comparison. |
| Reference facts: ITU regions and operating location | Canadian operator in Florida: Subject to frequency band limits applicable to United States amateur radio operators. | Pending rewrite comparison. |
| Reference facts: ITU regions and operating location | Canadian operator seven kilometres offshore from Florida: Subject to frequency band limits applicable to United States amateur radio operators because 7 km is inside the United States territorial sea. | Pending rewrite comparison. |
| Reference facts: United States and CEPT-style visits | Canadian operator in the United States: Basic is the minimum Canadian qualification for this visit arrangement. | Pending rewrite comparison. |
| Reference facts: United States and CEPT-style visits | Canadian operator in the United States using voice: Transmit the Canadian call sign, then portable or mobile as appropriate, then the prefix for the US call area being visited. | Pending rewrite comparison. |
| Reference facts: United States and CEPT-style visits | Canadian operator using a CEPT Amateur Radio Licence in a participating country: Advanced is the minimum Canadian qualification for this visit arrangement. | Pending rewrite comparison. |
| Reference facts: United States and CEPT-style visits | CEPT participating country using voice: Transmit the visited country's prefix, then "stroke," then the Canadian call sign. | Pending rewrite comparison. |

## L-001-06 baseline inventory

| Before section | Taught fact before rewrite | After section / comparison |
|---|---|---|
| Reference facts: Antenna siting and public consultation | Installation or modification of an antenna structure: Consultation duties can apply to antenna structures. | Pending rewrite comparison. |
| Reference facts: Antenna siting and public consultation | Antenna installations, including masts and towers: Authority rests with the Minister of Innovation, Science and Industry. | Pending rewrite comparison. |
| Reference facts: Antenna siting and public consultation | ISED-defined exclusion criterion: An exclusion can remove the requirement to contact land-use authorities to determine public consultation requirements. | Pending rewrite comparison. |
| Reference facts: Antenna siting and public consultation | No local land-use approval process: Follow ISED's default public consultation process. | Pending rewrite comparison. |
| Reference facts: Antenna siting and public consultation | ISED default-process elements: Provide written notice, address relevant questions, comments, and concerns, and give the public an opportunity to respond to the measures taken. | Pending rewrite comparison. |
| Reference facts: Antenna siting and public consultation | ISED default-process concerns: Address reasonable and relevant concerns provided in writing within the 30-day public comment period. | Pending rewrite comparison. |
| Reference facts: Antenna siting and public consultation | Municipality with a consultation process: Exclusion by the municipal process OR by CPC-2-0-03 can remove the public-consultation requirement. | Pending rewrite comparison. |
| Reference facts: Antenna siting and public consultation | Proponent and non-public stakeholder fail to agree: ISED makes the final decision. | Pending rewrite comparison. |
| Reference facts: Antenna siting and public consultation | Tallest structure without public consultation: The tallest exempted by the land-use authority or ISED. | Pending rewrite comparison. |
| Reference facts: Antenna siting and public consultation | Local process exists: The municipality or local land-use authority determines how public consultation should take place. | Pending rewrite comparison. |
| Reference facts: Safety Code 6 and RF exposure | Organization publishing guidelines for maximum RF energy near the human body: Health Canada. | Pending rewrite comparison. |
| Reference facts: Safety Code 6 and RF exposure | Purpose of Safety Code 6: Gives RF exposure limits for the human body. | Pending rewrite comparison. |
| Reference facts: Safety Code 6 and RF exposure | Greatest RF-energy risk range: 48 MHz to 300 MHz. | Pending rewrite comparison. |
| Reference facts: Safety Code 6 and RF exposure | Reason for the lowest exposure limit in that range: The human body absorbs RF energy the most in this range. | Pending rewrite comparison. |
| Reference facts: Safety Code 6 and RF exposure | Maximum safe power output to the antenna of a hand-held VHF or UHF radio: No specified value. | Pending rewrite comparison. |
| Reference facts: Safety Code 6 and RF exposure | Basic exposure situations: Controlled and uncontrolled environments; uncontrolled areas include the general public and have lower public limits. | Pending rewrite comparison. |
| Reference facts: Safety Code 6 and RF exposure | Other established adverse effect below 10 MHz: Nerve stimulation. | Pending rewrite comparison. |
| Reference facts: Safety Code 6 and RF exposure | Hand-held transmitters: Included in Safety Code 6 requirements. | Pending rewrite comparison. |
| Reference facts: Safety Code 6 and RF exposure | Transmitter exemptions: No transmitters are exempt. | Pending rewrite comparison. |
| Reference facts: Safety Code 6 and RF exposure | Exposure quantities: Safety Code 6 uses exposure quantities such as fields, currents, and absorption rate. | Pending rewrite comparison. |
| Reference facts: Safety Code 6 and RF exposure | Exposure factors: Antenna gain, distance, transmitter power, and frequency. | Pending rewrite comparison. |
| Reference facts: EMCAB-2 interference criteria | Stereo-system complaint: Lack of immunity is the cause when field strength at the neighbour's premises is below ISED's specified immunity criteria. | Pending rewrite comparison. |
| Reference facts: EMCAB-2 interference criteria | Television-receiver complaint: The amateur transmission is the cause when field strength at the neighbour's premises is above ISED's specified immunity criteria. | Pending rewrite comparison. |
| Reference facts: EMCAB-2 interference criteria | Home-entertainment devices outside the strict radio-apparatus category: Associated equipment, such as audio or video recorders, playback devices, and amplifiers used with radio apparatus. | Pending rewrite comparison. |
| Reference facts: EMCAB-2 interference criteria | Garage door opener affected by transmissions: Radio-sensitive equipment, meaning other non-radio electronic equipment whose function can be affected by radio emissions. | Pending rewrite comparison. |
