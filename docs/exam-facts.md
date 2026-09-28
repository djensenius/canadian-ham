# Authoritative exam facts for Canadian Basic

This file is the project reference for facts about the Canadian Amateur Radio Operator Certificate, Basic Qualification. Other docs should link here rather than restating facts independently.

Source facts were verified by the coordinator on 2026-09-28. Do not add regulatory facts from memory. If a fact is not listed here with a source or coordinator verification note, place it in [Open questions](#open-questions) until it is verified.

## Official and reference sources

| Source | URL | Verified artifact details |
|---|---|---|
| Basic question bank delimited TXT, English and French | <https://apc-cap.ic.gc.ca/datafiles/amat_basic_quest.zip> | Downloaded 2026-09-28. Contains `amat_basic_quest_delim.txt`. SHA-256: `34c7cd7967addfde648c566d0ecf25bf3d1e071c603b5101cfecc7bd0cbc284f`. |
| Basic question bank PDF, English | <https://ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/sites/default/files/documents/amateur_basic_questions_en_2025-07-15.pdf> | Dated 15 July 2025. 109 pages. SHA-256: `4e59b09f7711319091adfb729b138f6ad953f2c3d43108352155bfaa4f456ae4`. |
| Reference material ZIP, English | <https://www.ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/sites/default/files/documents/Reference%20Material%20for%20Amateur%20Radio%20Basic%20EN%202025%20.zip> | Listed on ISED downloads page as available as of 2025-07-15. Contains the training and exam PDFs listed below. |
| Reference material, exam version | Same ZIP as above | `Reference Material for Amateur Radio Exam Basic EN 2025.pdf`; unlabelled formulas and block diagrams; may be used while writing the exam. SHA-256: `e4e6a0ec35d9ccec2732b6c2a950b3ea721f826d44160b54b4e6298e86b93ae9`. |
| Reference material, training version | Same ZIP as above | `Reference Material for Amateur Radio Training Basic EN 2025.pdf`; labelled study aid. SHA-256: `2e0bf5e30a621852db0bf3c1e3954bbd60f906b19c531d97eab9b35c8f1a831e`. |
| ISED downloads page | <https://www.ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/downloads> | Used to locate official downloads and the 2025-07-15 availability date for reference material. |
| ISED exam generator | <https://ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/amateur-radio-exam-generator> | Official exam generator page. |
| ISED online practice exam | <https://apc-cap.ic.gc.ca/pls/apc_anon/apeg_practice.practice_form?lang=en> | Practice exam states 100 questions from all categories. |
| RAC Basic requirements | <https://www.rac.ca/requirements/> | Used for pass and honours thresholds and examiner/district-office path. |
| RAC Basic and Advanced course page | <https://www.rac.ca/rac-basic-and-advanced-courses-fall-2026-register-now/> | Used only to flag RAC-stated Advanced extras; lessons must verify those items against RBR-4/RIC-3 before publishing. |
| RAC/HamStudy 2025 bank notes | <https://hamstudy.com/2025/lesson/changes-to-hamstudy-and-the-basic-question-bank/> | Used for exam structure corroboration. |
| SCARCS test summary | <https://scarcs.ca/hambasics/aboutthetest> | Used for exam structure corroboration. |
| RBR-4 operating standards | <https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service> | Used for privileges content, including RBR-4 section 10 power wording. |
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
| French category names | Open question until verified from an official source. | Project verification status. |
| Figures in questions | No questions require a figure. | Coordinator scan of all official question text, 2026-09-28. |
| Reference-sheet context | Some questions involve formulas/block diagrams that appear on ISED's reference sheet; lessons should teach that context. | ISED reference material and coordinator scan of official question text. |

| Category ID | English category name | Questions | Subsections | Mock-exam count | Source |
|---|---|---:|---:|---:|---|
| `B-001` | Regulations and Policies | 199 | 25 | 25 | Coordinator validation of official TXT counts; English name from verified ISED/RAC materials. |
| `B-002` | Operating and Procedures | 99 | 9 | 9 | Coordinator validation of official TXT counts; English name from verified ISED/RAC materials. |
| `B-003` | Station Assembly, Practice and Safety | 199 | 21 | 21 | Coordinator validation of official TXT counts; English name from verified ISED/RAC materials. |
| `B-004` | Circuit Components | 63 | 6 | 6 | Coordinator validation of official TXT counts; English name from verified ISED/RAC materials. |
| `B-005` | Basic Electronics and Theory | 142 | 13 | 13 | Coordinator validation of official TXT counts; English name from verified ISED/RAC materials. |
| `B-006` | Feedlines and Antenna Systems | 140 | 13 | 13 | Coordinator validation of official TXT counts; English name from verified ISED/RAC materials. |
| `B-007` | Radio Wave Propagation | 87 | 8 | 8 | Coordinator validation of official TXT counts; English name from verified ISED/RAC materials. |
| `B-008` | Interference and Suppression | 55 | 5 | 5 | Coordinator validation of official TXT counts; English name from verified ISED/RAC materials. |

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
| The unlabelled formula and block-diagram reference sheet may be used during the exam. | ISED reference material ZIP and exam-version PDF. |
| Time limit is unverified. Mock-exam timer must be optional and default off until verified. | Open verification status; no cited official time-limit source yet. |

## Privileges for learning content

These privilege facts are course content, not application authorization logic. Lessons must cite the applicable question IDs and RBR-4 where they teach privileges. T-103 validation must re-check the cited question IDs against the imported official data so the citations remain tied to the active bank.

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

- French names for the eight category headings are not yet verified from an official source.
- A French version of the 2025 Basic reference material ZIP/PDF has not yet been located.
- The Basic exam time limit is unverified.
- Permission record details for ISED Crown copyright clearance must be filled in, including reference number and date, in [content licensing](content-licensing.md).
