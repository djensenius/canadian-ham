# Authoritative exam facts for Canadian Basic

This file is the project reference for facts about the Canadian Amateur Radio Operator Certificate, Basic Qualification. Other docs should link here rather than restating facts independently.

Source facts were verified by the coordinator on 2026-09-28. Do not add regulatory facts from memory. If a fact is not listed here with a source or coordinator verification note, place it in [Open questions](#open-questions) until it is verified.

## Official and reference sources

| Source | URL | Verified artifact details |
|---|---|---|
| Basic question bank delimited TXT, English and French | <https://apc-cap.ic.gc.ca/datafiles/amat_basic_quest.zip> | Downloaded 2026-09-28. Contains `amat_basic_quest_delim.txt`. SHA-256: `34c7cd7967addfde648c566d0ecf25bf3d1e071c603b5101cfecc7bd0cbc284f`. |
| Basic question bank PDF, English | <https://ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/sites/default/files/documents/amateur_basic_questions_en_2025-07-15.pdf> | Dated 15 July 2025. 109 pages. SHA-256: `4e59b09f7711319091adfb729b138f6ad953f2c3d43108352155bfaa4f456ae4`. |
| Reference material ZIP, English | <https://www.ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/sites/default/files/documents/Reference%20Material%20for%20Amateur%20Radio%20Basic%20EN%202025%20.zip> | Listed on ISED downloads page as available as of 2025-07-15. Contains the training and exam PDFs listed below; not shipped in the apps. |
| Reference material, exam version | Same ZIP as above | `Reference Material for Amateur Radio Exam Basic EN 2025.pdf`; unlabelled formulas and block diagrams; may be used while writing the exam. SHA-256: `e4e6a0ec35d9ccec2732b6c2a950b3ea721f826d44160b54b4e6298e86b93ae9`. Not shipped in the apps. |
| Reference material, training version | Same ZIP as above | `Reference Material for Amateur Radio Training Basic EN 2025.pdf`; labelled study aid. SHA-256: `2e0bf5e30a621852db0bf3c1e3954bbd60f906b19c531d97eab9b35c8f1a831e`. Not shipped in the apps. |
| ISED downloads page | <https://www.ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/downloads> | Used to locate official downloads and the 2025-07-15 availability date for reference material. Rechecked for the reference-sheet listing and download wording on 2026-10-12. |
| ISED exam generator | <https://ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/amateur-radio-exam-generator> | Official exam generator page. |
| ISED French Exam Generator study page | <https://apc-cap.ic.gc.ca/pls/apc_anon_f/apeg_study.study_questions_intro> | Category dropdown lists the official French Basic category names. Checked for task-6 on 2026-10-02. |
| ISED online practice exam | <https://apc-cap.ic.gc.ca/pls/apc_anon/apeg_practice.practice_form?lang=en> | Practice exam states 100 questions from all categories. |
| RAC Basic requirements | <https://www.rac.ca/requirements/> | Used for pass and honours thresholds and examiner/district-office path. |
| RAC Basic and Advanced course page | <https://www.rac.ca/rac-basic-and-advanced-courses-fall-2026-register-now/> | Used only to flag RAC-stated Advanced extras; lessons must verify those items against RBR-4/RIC-3 before publishing. |
| RAC/HamStudy 2025 bank notes | <https://hamstudy.com/2025/lesson/changes-to-hamstudy-and-the-basic-question-bank/> | Used for exam structure corroboration. |
| SCARCS test summary | <https://scarcs.ca/hambasics/aboutthetest> | Used for exam structure corroboration. |
| RBR-4 operating standards | <https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service> | Used for privileges content, including RBR-4 section 10 power wording. |
| CIR-1, 8th edition, May 2025 | <https://ised-isde.canada.ca/site/gestion-spectre-telecommunications/fr/licences-certificats/circulaires-dinformation-radiocom-cir/cir-1-guide-lintention-examinateurs-accredites-charges-dadministrer-examens-menant-lobtention> | §7.2 says no exam time limit is fixed and gives normal completion-time guidance. Checked for task-6 on 2026-10-02. §8.3 (`#s8.3`) has the official French Morse sample recorded verbatim in `fixtures/morse/word-weighting.json` (task-12.8; cite the page body, not its stale meta description). |
| RIC-1, Issue 8, May 2025 | <https://www.ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-1-guide-examiners-accredited-conduct-examinations-amateur-radio-operator-certificates> | §7.2 says no exam time limit is specified and gives normal completion-time guidance. Checked for task-6 on 2026-10-02. §7.2 also says exams are closed book, identifies the only permitted Basic reference sheet, and states the calculator condition; §7.2.1 gives virtual-exam procedures. Rechecked for task-43 on 2026-10-12. §8.3 (`#s8.3`) has the official English Morse sample recorded verbatim in `fixtures/morse/word-weighting.json` (task-12.8). |
| CIR-3, 5th edition, March 2022 | <https://www.ised-isde.canada.ca/site/gestion-spectre-telecommunications/fr/licences-certificats/circulaires-dinformation-radiocom-cir/cir-3-renseignements-service-radioamateur> | §5.1 lists the French Basic category names; §5.3.1–5.3.7 (`#s5.3`) list the French Advanced category names (verified for task-11.10); §5.4 says no time limit is fixed. Checked for task-6 on 2026-10-02. |
| ISED French Exam Generator, Advanced level | <http://cap-apc.ic.gc.ca/pls/apc_anon_f/apeg_study.study_questions_intro?p_level_id=1> | Category dropdown lists the official French Advanced category names, matching CIR-3 §5.3 word for word (task-11.10). |
| RIC-3, Issue 5, March 2022 | <https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-3-information-amateur-radio-service> | §5.4 says no time limit is specified; preface says the circulars have no status in law. Checked for task-6 on 2026-10-02. |
| ISED terms and conditions | <https://ised-isde.canada.ca/site/ised/en/terms-and-conditions> | Licensing reference. |
| ISED copyright written permission | <https://www.ised-isde.canada.ca/site/ised/en/copyright-written-permission> | Licensing reference. |

## Question bank version

| Fact | Source |
|---|---|
| The product uses only the 2025 Basic question bank effective 2025-07-15. | ISED downloads page and 2025-07-15 Basic PDF/TXT artifacts. |
| Legacy banks are out of scope. | Project scope decision in [requirements](requirements.md), tied to the active ISED 2025-07-15 artifacts. |
| The ISED ZIP may be regenerated with changing file modification times. The importer must verify content by checksum and structural validation, not by ZIP or file dates. | Coordinator verification of downloaded ISED ZIP behavior and recorded TXT SHA-256. |

## Delimited file format

The canonical data source is `amat_basic_quest_delim.txt` from `amat_basic_quest.zip`.

| Format fact | Verified value | Source |
|---|---|---|
| Encoding | UTF-8, no byte order mark. | Coordinator inspection of official delimited TXT, 2026-09-28. |
| Line endings | CRLF. | Coordinator inspection of official delimited TXT, 2026-09-28. |
| Separator | Semicolon (`;`). | Official delimited TXT. |
| Header | One header row. | Official delimited TXT. |
| Field count | 11 fields per record. | Official delimited TXT and coordinator count validation. |
| Header parsing | Importers trim header names only, including the trailing space in `question_id `. | Official delimited TXT header. |
| Field value parsing | Importers do not trim question or answer field values; official wording is preserved verbatim. | Verbatim-text requirement and official delimited TXT. |
| Quoting and embedded newlines | The current file contains no quoted fields and no embedded newlines; the importer must assert this format. | Coordinator inspection of official delimited TXT, 2026-09-28. |
| Correct-answer column | The correct answer is always in the first answer column. Apps must shuffle answer order. | Official delimited TXT column layout. |
| Answer letters in PDF | ISED's PDF varies answer letters. | Coordinator observation of the 2025-07-15 English PDF answer key. |
| Position-dependent answers | The coordinator checked that answers are not position-dependent, such as "all of the above" or "A and B". The importer should still lint for position-dependent phrases. | Coordinator scan of official question/answer text, 2026-09-28. |

Header fields, exactly as present before trimming:

1. `question_id `, with a trailing space that importers must trim.
2. `question_english`
3. `correct_answer_english`
4. `incorrect_answer_1_english`
5. `incorrect_answer_2_english`
6. `incorrect_answer_3_english`
7. `question_french`
8. `correct_answer_french`
9. `incorrect_answer_1_french`
10. `incorrect_answer_2_french`
11. `incorrect_answer_3_french`

## Bank size and structure

| Fact | Value | Source |
|---|---:|---|
| Total questions | 984 | Coordinator validation of official delimited TXT. |
| Fields per question | 11 | Official delimited TXT. |
| Duplicate IDs | 0 | Coordinator validation of official delimited TXT. |
| Missing French question or answer text | 0 | Coordinator validation of official delimited TXT. |
| First ID | `B-001-001-001` | Official delimited TXT. |
| Last ID | `B-008-005-011` | Official delimited TXT. |
| Question ID format | `B-CCC-SSS-NNN`, meaning category, subsection, and question number. | Coordinator validation of official delimited TXT IDs. |
| Subsections | 100 | Coordinator validation of official delimited TXT. |
| Questions per subsection | 4 to 11 | Coordinator validation of official delimited TXT. |
| Category names in TXT | Not present. Store category names in a hand-maintained categories file. | Official delimited TXT. |
| English category-name source | ISED/RAC materials. | ISED/RAC source review recorded by coordinator. |
| French category names | Verified official names from ISED CIR-3 §5.1.1–5.1.8 and the French Exam Generator category dropdown. The source text uses straight ASCII apostrophes in `d'une`, `l'électronique`, and `d'antenne`. | Task-6 source check, 2026-10-02. |
| Figures in questions | No questions require a figure. | Coordinator scan of all official question text, 2026-09-28. |
| Reference-sheet context | Some questions involve formulas/block diagrams that appear on ISED's reference sheet; lessons should teach that context. | ISED reference material and coordinator scan of official question text. |

| Category ID | English category name | French category name | Questions | Subsections | Mock-exam count | Source |
|---|---|---|---:|---:|---:|---|
| `B-001` | Regulations and Policies | Règlements et politiques | 199 | 25 | 25 | Counts from official TXT; French name from ISED CIR-3 §5.1.1 and French Exam Generator. |
| `B-002` | Operating and Procedures | Exploitation et procédures | 99 | 9 | 9 | Counts from official TXT; French name from ISED CIR-3 §5.1.2 and French Exam Generator. |
| `B-003` | Station Assembly, Practice and Safety | Montage d'une station, pratique et sécurité | 199 | 21 | 21 | Counts from official TXT; French name from ISED CIR-3 §5.1.3 and French Exam Generator. |
| `B-004` | Circuit Components | Composants des circuits | 63 | 6 | 6 | Counts from official TXT; French name from ISED CIR-3 §5.1.4 and French Exam Generator. |
| `B-005` | Basic Electronics and Theory | Éléments et théorie de l'électronique | 142 | 13 | 13 | Counts from official TXT; French name from ISED CIR-3 §5.1.5 and French Exam Generator. |
| `B-006` | Feedlines and Antenna Systems | Descentes d'antenne et systèmes d'antenne | 140 | 13 | 13 | Counts from official TXT; French name from ISED CIR-3 §5.1.6 and French Exam Generator. |
| `B-007` | Radio Wave Propagation | Propagation des ondes radioélectriques | 87 | 8 | 8 | Counts from official TXT; French name from ISED CIR-3 §5.1.7 and French Exam Generator. |
| `B-008` | Interference and Suppression | Brouillage et suppression | 55 | 5 | 5 | Counts from official TXT; French name from ISED CIR-3 §5.1.8 and French Exam Generator. |

## Exam rules

| Rule | Source |
|---|---|
| The Basic exam is 100 multiple-choice questions. | ISED online practice exam; RAC Basic requirements; RAC/HamStudy and SCARCS corroboration. |
| Each question has four answer choices. | Official delimited TXT and English PDF. |
| The exam contains one randomly chosen question from each of the 100 subsections. | Coordinator verification against official data plus RAC/HamStudy and SCARCS corroboration. |
| Per-category exam counts equal the subsection counts: `25 / 9 / 21 / 6 / 13 / 13 / 8 / 5` for categories `B-001` through `B-008`. | Derived from one-question-per-subsection rule and coordinator-verified subsection counts. |
| Passing score is 70%: at least 70 correct answers out of 100. | RAC Basic requirements. |
| Basic with Honours is 80% or more: at least 80 correct answers out of 100. | RAC Basic requirements. |
| Exams are given by Accredited Examiners (RIC-1) or by an ISED district office. | RAC Basic requirements. |
| The unlabelled formula and block-diagram reference sheet may be used during the exam. The ISED downloads page lists the ZIP as `Reference Material for Amateur Radio Exam – Basic Qualification` and says the ZIP contains a labelled study-aid PDF and an identical unlabelled PDF that may be used as an aid while writing the exam. | ISED downloads page, rechecked 2026-10-12. |
| Basic exams are closed book. Reference material must not be used during the exam except for the ISED-approved formula and block diagram sheet titled `Reference Material for Amateur Radio Exam – Basic Qualification`. | RIC-1 §7.2, Issue 8, May 2025, rechecked 2026-10-12. |
| Calculators may be used only if the calculator cannot store formulas or text. | RIC-1 §7.2, Issue 8, May 2025, rechecked 2026-10-12. |
| Virtual exams must meet the in-person requirements in RIC-1 §§7.1-7.4 plus §7.2.1's virtual procedures. The candidate and examiner need camera, microphone, and stable internet; the exam is one-on-one by two-way video; the candidate shows the examiner that nothing within reach or view could affect exam integrity; the examiner emails a blank answer sheet in advance; the candidate prints it and records answers on it; the examiner screen-shares the exam questions; the candidate keeps camera and microphone on during the exam. | RIC-1 §7.2.1, Issue 8, May 2025, rechecked 2026-10-12. |
| RIC-1 §7.2 and §7.2.1 do not state that scrap paper is generally allowed for written exams. Do not teach a general scrap-paper entitlement; tell learners to follow the examiner's instructions. | Task-43 verification of RIC-1 §7.2 and §7.2.1, rechecked 2026-10-12. |
| No fixed time limit is specified for the Basic exam. RIC-1 §7.2 says: "There is no specified time limit for the examinations. Most examinations are completed within one (1) hour and would normally not take more than two (2) hours to complete. Examiners will use their discretion in ensuring that reasonable time is made available for the examination." CIR-3 §5.4 likewise says: « Aucune limite de temps n'est fixée pour compléter les examens. La majorité des candidats finissent l'examen en moins d'une heure, et les autres ne devraient pas prendre plus de deux heures pour le terminer. Les examinateurs useront de jugement pour allouer suffisamment de temps pour compléter l'examen. » | RIC-1 §7.2 and CIR-1 §7.2, Issue/8th edition May 2025; RIC-3 §5.4 and CIR-3 §5.4, Issue/5th edition March 2022. |
| Time-limit guidance is in ISED information circulars, not regulations; RIC-3 states that these circulars "have no status in law". | RIC-3 preface. |
| Mock-exam timer must remain optional and default off. An optional elapsed-time timer is product guidance only, not an ISED time limit. | Product decision based on the no-fixed-time-limit guidance above. |

## Morse qualification test standard (TASK-80)

**Primary-source recheck: 2026-10-27 (2026-10-28 UTC).** Read the current ISED
HTML pages in both languages and downloaded the official bilingual Basic bank
ZIP again; its TXT SHA-256 is unchanged from the artifact above. The Morse test
is practical, not a multiple-choice exam. The written Basic exam's no-fixed-time
rule does **not** replace the Morse test's three-minute requirement.

Sources (section numbers below apply in both languages):

- **[RIC-1, Issue 8, May 2025][morse-ric1] / [CIR-1, 8e édition, mai 2025][morse-cir1]**, §§8.1–8.7: examiner procedures.
- **[RIC-3, Issue 5, March 2022][morse-ric3] / [CIR-3, 5e édition, mars 2022][morse-cir3]**, §5.2: qualification exam and pass mark.
- **[RBR-4, Issue 3, July 2022][morse-rbr4] / [IPR-4, 3e édition, juillet 2022][morse-ipr4]**, Schedule I / annexe I: qualification definition, not detailed exam procedures.
- **[Official bilingual Basic bank TXT][morse-bank]**, `B-001-004-005`: correct answer **“5 wpm” / « 5 mots/min »** to the sending-and-receiving speed question. This is the effective test speed, not the examiner's character speed.

| Requirement | Primary-source wording and interpretation |
|---|---|
| **Qualification name** | RBR-4 Schedule I defines “5” as “Amateur Radio Operator Certificate with Morse Code (5 w.p.m.) Qualification”; French IPR-4 annexe I: « Certificat d’opérateur radioamateur de compétence en code Morse (cinq mots par minute) ». These schedules do not set the sending duration or grading algorithm; those details are in RIC-1/CIR-1 and RIC-3/CIR-3 below. |
| **Speed, duration and sending format** | RIC-1 §8.2: “correctly send, by hand, a plain-language text, in international Morse code, for a minimum of three (3) consecutive minutes, at a speed of not less than 5 wpm”, using an ordinary radiotelegraph, semi-automatic or electronic hand key. CIR-1: « pendant au moins trois minutes consécutives à une vitesse d'au moins 5 mots/min ». RIC-3 §5.2 says sending **and** receiving at ≥5 wpm “for three consecutive minutes”; CIR-3: « pendant trois minutes consécutives ». **The app's standard sending allowance is therefore 180 s, not the old 120 s UI-test override.** |
| **Receiving format** | RIC-1 §8.2 requires receiving “by ear”, copying plain language legibly by hand, typewriter or word processor; CIR-1: « recevoir correctement, à l'oreille » and « copier le texte lisiblement ». The same ≥5 wpm / minimum three consecutive minutes applies. §§8.1.1 and 8.6 require handwritten copy for virtual exams and two minutes for review after receiving (not an extra sending allowance): « deux minutes à la fin de l'épreuve de réception ». |
| **Length and word weighting** | RIC-1 §8.2: “A Morse code "word" consists of five characters”; A–Z count one each, figures and punctuation two each. CIR-1: « Un « mot » en code Morse comprend cinq caractères ». Sending requires “at least 75 characters” in the three minutes; CIR-1: « au moins 75 caractères pendant les trois minutes allouées ». Read with the weighting definition, this is a minimum of **75 weighted characters**, not an official requirement for exactly 75 raw characters. |
| **Character speed versus overall speed** | RIC-1 §8.2: “Morse code shall be sent at a character speed of 12 wpm”, with longer letter/word spaces to set test speed. CIR-1: « La vitesse de transmission des caractères en code Morse doit être de 12 mots/min. » **For candidate sending**, the same section explicitly says “the speed of the characters is immaterial, as long as the necessary number of characters is sent”; CIR-1: « la vitesse d'émission des caractères importe peu ». Do not grade the candidate's character-speed or dot/dash consistency as an extra pass condition. |
| **Speed calibration** | RIC-1 §8.2: “the word "Paris" sent five times in one minute results in a code speed of 5 wpm”; CIR-1: « l'émission du mot « Paris » cinq fois en une minute correspond à une vitesse de 5 mots/min ». The app's `isedParis` 12/5 profile meets this check. The same section's **approximate** seven-dot letter / seventeen-dot word gaps yield about 7.9 wpm with 12-wpm characters (project calculation), not 5; `ric1Literal` remains separately labelled harder practice. See the [timing analysis](proposals/morse-trainer.md). ISED does not specify which spacing implementation examiners' software uses. |
| **Character set** | RIC-1 §8.2: letters, numbers, “the period, the comma, the question mark, the dash and the fraction bar” only, and “Accented letters are not to be used”. CIR-1: « point final, virgule, point d'interrogation, tiret et barre oblique »; « Les lettres avec un accent ne doivent pas être utilisées ». Thus A–Z, 0–9, `. , ? - /`. Q signals are allowed as letters. RIC-3/CIR-3 §5.2 additionally mention “emergency signals” / « signaux d'urgence » but do not name a particular signal or prescribe a generated passage. |
| **Pass mark and error counting** | RIC-3 §5.2 applies to both sending and receiving: “A mark of 100% is awarded for five errors or less” and “The pass mark is 100%.” Six errors = 99%, seven = 98%, etc. RIC-1/CIR-1 §8.7 agree on the receiving threshold: « cinq erreurs ou moins ». Each omitted or incorrectly sent/received character is **one error**, including a figure or punctuation mark (not two errors despite length weighting). |
| **French source discrepancy** | CIR-3 §5.2 literally says « moins de cinq erreurs », whereas English RIC-3 says “five errors or less” and newer CIR-1 §8.7 says « cinq erreurs ou moins ». Do not silently change the quote to hide this discrepancy. The engine retains the existing **≤5 errors** boundary, supported by RIC-3 EN and RIC-1/CIR-1. |
| **Omissions and corrections** | RIC-1 §8.2: “Any characters omitted at the end of the text due to lack of time will count as errors”; CIR-1: « Tout caractère omis à la fin du texte en raison d'un manque de temps compte comme une erreur. » §8.6 permits an error signal and resending the character, but within the allotted time: « la transmission du texte intégral doit se faire dans le délai prescrit ». Neither an automatic timeout failure in addition to the error count nor a separate timing-quality pass threshold is specified. RIC-1 does not specify the error signal's dot count (the engine's eight-dot signal comes from ITU-R M.1677-1, cited in the proposal). |
| **Distinct passages and timing** | RIC-1/CIR-1 §8.4 require different sending and receiving texts; §8.5 requires both tests to be timed. §8.3's sample “shall not be used in an examination” / « Cet exemple ne doit pas faire partie de l'examen ». The generator uses project-authored sentences, not that sample. |

### App comparison and intentionally labelled practice differences

- **Apple (iOS/iPadOS/macOS) and web:** the **“Sending practice”** / **“Exam-style
  check”** screens use a **three-minute deadline**, `isedParis` to generate a
  plain-language passage of **at least 75 weighted characters**, and the same
  ≤5-error grading. The production duration was already 180 s. TASK-80 names that
  duration in both engines and removes the three sending-results tests' 120 s
  overrides; the DEBUG fill hook changes the answer only, not the duration.
- Sending calls `generateMorseExamText(..., minDurationSeconds: 0)`: the generator
  appends whole sentences until ≥75 weighted characters. A passage may exceed
  75; ISED specifies a **minimum**, not an exact text length. A sending passage's
  hypothetical playback duration is not its deadline: **candidate character
  speed is immaterial**. Receiving generation separately requires ≥180 s of
  playback. Do not copy that receiving constraint into sending generation.
- This is a **practice check**, not an accredited qualification exam. Flexible
  keyer speeds, on-screen paddles, feedback, and the explicitly labelled **“End
  and grade”** action allow rehearsal and early results. An early manual grade
  (or a DEBUG-filled answer) is **not evidence of three consecutive minutes of
  actual sending**. The official practical test still requires that duration
  and a permitted key. The screen labels and controls expose these differences;
  the test fixture uses the real allowance but fills and grades without waiting
  for the deadline.
- The engine counts inserted characters as errors and ignores word-space
  differences in alignment. **ISED does not prescribe an insertion penalty or
  an alignment/space-normalization algorithm**; those are conservative practice
  scoring choices, not quoted official rules. Unsent characters at timeout are
  counted as omissions; five omissions may still pass, rather than adding an
  unsourced blanket timeout failure. Dot/dash ratio and consistency are feedback
  only. Existing shared scoring fixtures cover these rules; TASK-80 adds exact
  five/six missing-character cases including figures and punctuation, a shared
  sending-passage fixture, and paired duration/profile/generation tests.
- Short DEBUG duration overrides remain for deadline/cancellation regression
  tests, and the separate main/exam-screen audit keeps its existing extended
  preparation allowance. None of the **three sending-results tests** selects
  an override. They assert the initial **3:00** and retain every previous
  assertion and full accessibility audit.

[morse-ric1]: https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-1-guide-examiners-accredited-conduct-examinations-amateur-radio-operator-certificates#s8.2
[morse-cir1]: https://ised-isde.canada.ca/site/gestion-spectre-telecommunications/fr/licences-certificats/circulaires-dinformation-radiocom-cir/cir-1-guide-lintention-examinateurs-accredites-charges-dadministrer-examens-menant-lobtention#s8.2
[morse-ric3]: https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-3-information-amateur-radio-service#s5.2
[morse-cir3]: https://ised-isde.canada.ca/site/gestion-spectre-telecommunications/fr/licences-certificats/circulaires-dinformation-radiocom-cir/cir-3-renseignements-service-radioamateur#s5.2
[morse-rbr4]: https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service#sA
[morse-ipr4]: https://ised-isde.canada.ca/site/gestion-spectre-telecommunications/fr/licences-certificats/incorporations-renvoi-ipr/ipr-4-normes-relatives-lexploitation-stations-radio-service-radioamateur#sA
[morse-bank]: https://apc-cap.ic.gc.ca/datafiles/amat_basic_quest.zip

## Privileges for learning content

These privilege facts are course content, not application authorization logic. Lessons must cite the applicable question IDs and RBR-4 where they teach privileges. T-102 importer validation must re-check the cited question IDs against the imported official data so the citations remain tied to the active bank.

| Fact | Source |
|---|---|
| Basic qualification: all amateur bands above 30 MHz. | Correct answers for official TXT question IDs `B-001-017-009`, `B-001-017-010`, `B-001-017-004`, `B-001-017-005`; RBR-4. |
| Basic maximum power: 250 W DC input to the transmitter final stage that supplies radio frequency energy to the antenna, or 560 W PEP for SSB, or 190 W carrier power for transmitters that produce any other type of emission. | Correct answers for official TXT question IDs `B-001-017-009`, `B-001-017-010`, `B-001-017-004`, `B-001-017-005`; RBR-4 section 10. |
| Operation below 30 MHz requires 80% on Basic, or Advanced, or Morse. | Correct answer for official TXT question ID `B-001-015-003`; RBR-4. |
| Advanced qualification includes 1000 W DC input and 2250 W PEP SSB. | Correct answers for official TXT question IDs `B-001-017-007`, `B-001-017-002`; RBR-4. |
| Advanced extras include higher power, remote-controlled station operation, repeaters, club station trustee responsibilities, and Accredited Examiner eligibility if the operator also has Morse qualification. | Per RAC Basic and Advanced course page; lessons must verify against RBR-4/RIC-3 before publishing. |
| Morse qualification is 5 wpm. | Correct answer for official TXT question ID `B-001-004-005`. |
| There is no age limit for Basic. | Correct answer for official TXT question ID `B-001-004-001`. |

## How to re-verify when ISED updates the bank

1. Download the current official source ZIP and PDF from the ISED downloads page.
2. Record the download date and canonical source URLs in this file.
3. Extract the delimited TXT without changing line endings or encoding.
4. Calculate SHA-256 checksums for the ZIP contents and PDF files.
5. Run the importer validation suite against the extracted TXT.
6. Confirm the TXT is UTF-8 without BOM, CRLF-delimited, semicolon-separated, and contains one header row.
7. Confirm header names after trimming match the 11 expected field names.
8. Confirm every data row has 11 fields and that field values are not trimmed or rewritten.
9. Confirm the current source still has no quoted fields and no embedded newlines, or update the importer format contract through a reviewed bank-version migration.
10. Confirm total question count, duplicate ID count, missing French count, first ID, last ID, and subsection counts.
11. Confirm category totals and subsection totals match the expected values for the selected bank version, or document changed counts as a bank-version migration.
12. Run the position-dependent-answer lint before enabling answer shuffling for the new bank.
13. Compare ISED PDF spot checks to ensure the correct answer is not assumed to be a fixed letter.
14. Update fixture expectations in `fixtures/` only through an intentional migration task.
15. Update [requirements](requirements.md), [architecture](architecture.md), and [content licensing](content-licensing.md) if the source format, permission scope, or exam rules changed.
16. Keep old bank artifacts out of the active content package unless an explicit later requirement adds historical-bank support.

## Open questions

- A French version of the 2025 Basic reference material ZIP/PDF has not yet been located.
- ISED permission request is pending; see [content licensing](content-licensing.md) for the interim policy, public-release gate, and pending record fields.
