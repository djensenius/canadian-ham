# Research (source-checked): ISED Advanced Qualification Course Investigation (T-701)

> **Status snapshot (2026-10-01):** permission statements in this brief predate the request. The ISED request was submitted on 2026-10-02 and is awaiting a reply; see the [permission record](../content-licensing.md#permission-record) for the current status.
>
> **Live-bank import note (2026-10-02):** task-11.4 fetched the live 2025-02-04 Advanced delimited TXT from ISED and found it is valid UTF-8 with CRLF line endings. The historical 2024-08-28 archive findings below are kept unchanged because they explain why the importer still has an explicit Windows-1252 fallback for older or republished legacy bytes.

Checked 2026-10-01. Original brief: `advanced.md`. Status labels used here: **Verified** (official or authoritative source, with the supporting passage), **Corrected** (the right fact, with its source), **Unverified** (what was searched). Statements marked *Inference* or *Estimate* are mine or the original author's and are not sourced facts.

## Verification summary

| # | Claim (original brief) | Status | Source(s) |
|---|---|---|---|
| 1 | ISED publishes the Advanced bank as delimited TXT in `amat_adv_quest.zip` | Verified | ISED Downloads: "Amateur advanced questions (delimited TXT format) … a full set of all possible questions for the advanced level amateur exam" → `https://apc-cap.ic.gc.ca/datafiles/amat_adv_quest.zip` |
| 2 | EN PDF at `http://apc-cap.ic.gc.ca/datafiles/amateur_advanced_questions_en.PDF`; FR PDF at `http://cap-apc.ic.gc.ca/datafiles/amateur_advanced_questions_fr.PDF` | Verified (exact hrefs on the ISED pages; the files themselves were not downloaded) | EN and FR "Print all advanced questions" pages (raw HTML) |
| 3 | Both English and French official texts are available | Verified | FR PDF page; the TXT has 5 French columns (readme_adv.txt in archived ZIP); CIR-3 (FR) |
| 4 | Current bank edition or effective date | **Unverified**: the brief gave none. ISED says only "effective the date printed on the title page". Page metadata: created 2014-03-05, modified 2017-03-08 | Print-all-advanced page; title-page PDF not parsed |
| 5 | Bank descends from RIC-8, now web-generator only | Verified, with a nuance: RIC-8 Issue 3 (effective Apr 1, 2007) used IDs like `A-001-01-01`; the current file uses `A-001-001-001` | ISED RIC index; publications.gc.ca Iu64-119/2007E |
| 6 | 7 categories A-001 to A-007, 50 topic areas (5+12+6+4+9+5+9) | Verified | RIC-3 Issue 5 §5.3.1–5.3.7 |
| 7 | ID format `A-CCC-SSS-###` | Verified | ISED Help: Study questions ("format L-CCC-SSS-### … L is the level (i.e. A for Advanced …)") |
| 8 | French category names | Verified (as CIR-3 syllabus headings) | CIR-3 §5.3.1–5.3.7 (FR) |
| 9 | Syllabus subsection wording | Corrected (minor): 3-4 "marking generator"; 4-1 lists only "PIP" | RIC-3 §5.3.3, §5.3.4 |
| 10 | About 500 questions, roughly 10 per topic | **Corrected: 549 questions** (A-001 54, A-002 132, A-003 66, A-004 44, A-005 99, A-006 55, A-007 99) | 2024-08-28 archive of the ISED ZIP (header + 549 rows); third-party parse of the live ZIP; hamprep.ca. No first-party count. |
| 11 | 11-column semicolon-delimited schema, same as Basic | Verified | readme_adv.txt in archived ZIP; file header row |
| 12 | File encoding and header | **New finding**: the file is not UTF-8 (accented French shows as replacement characters when read as UTF-8; probably Windows-1252 or Latin-1). There is a header row with a trailing space (`question_id ;…`). ZIP also holds `readme_adv.txt` and `lisezmoi_sup.txt` | Archived file (2024-08-28) |
| 13 | Exam is 50 questions, one from each of the 50 topic areas | Verified | RIC-3 §5.3; ISED Help: Printing an exam |
| 14 | Pass mark 70% (35/50); no Advanced Honours | Verified | RIC-3 §5.3; RIC-1 §7.3; ISED Help: Printing an exam |
| 15 | "Closed book; calculators … prohibited" (RIC-3 §5.4 quote) | **Corrected**: RIC-1 Issue 8 (May 2025) now permits calculators that can't store formulas or text. The only reference material allowed is the Basic sheet; there is none for Advanced | RIC-1 §7.2 |
| 16 | Basic is a prerequisite for Advanced (cited as RIC-3 §4.1) | Corrected: RIC-3 §4.1 doesn't say this. RIC-1 §7.1: a candidate may attempt any qualification at any time, but no certificate is issued until Basic is passed | RIC-1 §7.1 |
| 17 | Power: 1,000 W DC input / 2,250 W PEP SSB / 750 W carrier (Basic: 250 / 560 / 190) | Verified | RBR-4 Issue 3 §10.2–10.3 |
| 18 | Home-built transmitters and amplifiers; physical modification | Verified | SOR/96-484 s.44(a); RIC-3 §4.5.2 |
| 19 | Repeaters and club stations | Verified, with a wording correction: s.44(b) covers *installing* repeater and club-station apparatus. "Trustee/sponsor" is interpretation | SOR/96-484 s.44(b); RIC-3 §4.5.2 |
| 20 | Remote control, including radio links | Verified | RIC-3 §4.5.1–4.5.2 |
| 21 | All HF below 30 MHz regardless of Basic Honours | Verified | RIC-3 §4.4(1), §4.5.2; RBR-4 Sch. I Col. IV "B and A" |
| 22 | CEPT T/R 61-01 needs Basic and Advanced | Verified (also requires the call sign on the certificate) | RIC-3 §8.2.1 |
| 23 | Accredited examiner needs Advanced plus Morse | Verified, with additions: also Basic and age 18+ | RIC-1 §3.2 |
| 24 | RIC-3 Issue 5 (Mar 2022); RBR-4 Issue 3 (Jul 2022) | Verified | RIC-3; RBR-4 |
| 25 | Regulations "ss. 42 and 44" govern Advanced | Corrected (minor): s.26(1)(e)(iv) defines the qualification; s.44 gives Advanced-only privileges; s.42 is general operating eligibility | SOR/96-484 |
| 26 | Licence terms for Advanced are the same as for Basic (ISED terms) | Verified, plus: ISED requires permission for commercial use *and* for any revision or adaptation | ISED Terms and conditions; Copyright—Written permission |
| 27 | Drafted permission request covers the Advanced bank; not granted | Verified | `docs/content-licensing.md` |
| 28 | Permission request already "sent to ISED" (Decision 3) | **Corrected**: drafted 2026-09-28; sent: pending | `docs/content-licensing.md` permission record |
| 29 | Vendoring Advanced files for private development is allowed | **Corrected**: the interim policy only lists Basic 2025 artifacts under `basic-2025-07-15/`; Advanced needs an owner OK to extend it | `docs/content-licensing.md` (Interim policy; Source update policy step 3) |
| 30 | RAC/ISED rewriting the Advanced bank, release "late 2026" | **Corrected and qualified** (see §1.2) | RAC esc_cne; hamstudy.com/2025; GBARC forum (VE3WI, 2026-06-12); ISED exam generator page |
| 31 | Basic 2025: more than 80% of questions changed | **Corrected**: RAC lists 201 new questions out of 984 (about 20%). All 984 were reviewed. No source supports "more than 80%" | RAC release (2025-07-15) |
| 32 | Basic has 984 questions and 100 topic areas | Verified | RAC release; ISED exam generator / help pages |
| 33 | New bank will have about 500–600 questions | Unverified (no source on the new bank's size) | Searched RAC, ISED, Hamstudy |
| 34 | Repo: `ACTIVE_BANK_ID = "basic-2025-07-15"`; 100-subsection mock-exam guard; `honours: percent >= 80`; readiness includes `honours-ready` | Verified | `packages/content-tools/src/active-bank.ts`; `packages/engine-ts/src/exam.ts`, `scoring.ts`, `readiness.ts` |
| 35 | `ExamScore` includes `bankId` | **Corrected**: the engine-ts `ExamScore` interface has no `bankId`; `GeneratedExam` and `ExamGenerationInput` do | `packages/engine-ts/src/scoring.ts`, `exam.ts` |
| 36 | SwiftData `QuestionProgressRecord` stores `bankId` | Unverified (Swift sources not inspected) | — |
| 37 | Effort figures (1.5× explanation time, phase sizes, 30–40 lessons) | Unverified (author estimates) | — |
| 38 | Apple Developer documentation claims | Not applicable: the brief makes no Apple-platform claim that needs Apple docs | — |

---

## Summary (corrected)

ISED runs the Advanced Qualification under:
- **Radiocommunication Regulations (SOR/96-484):** s.26(1)(e)(iv) defines the qualification; s.44 grants the Advanced-only privileges.
- **RIC-3 Issue 5 (March 2022):** syllabus and privileges.
- **RIC-1 Issue 8 (May 2025):** exam procedures.
- **RBR-4 Issue 3 (July 2022):** power limits and bands.

**The current bank**
- ISED publishes it as `amat_adv_quest.zip` (semicolon-delimited TXT, English and French) and as EN and FR PDFs.
- It has **549 questions** in 7 categories and 50 topic areas.
- The exam is 50 questions, one per topic area. The pass mark is 70% (35/50). There is no Advanced Honours.
- Calculators that can't store formulas or text are allowed. There is no Advanced reference sheet.

**The rewrite**
- RAC's Examination Standards Committee drafted a revised Advanced bank. RAC said the work was "expected to be complete in 2026", and RAC-owned Hamstudy says ISED "will be implementing a new Advanced Question Bank in late 2026".
- In June 2026 a committee member reported the draft had been with ISED for "more than a year" and was not yet issued.
- As of 2026-10-01, ISED has announced no new Advanced bank and no effective date.
- *Inference:* for Basic, ISED published the bank on Jan 27, 2025 and it took effect July 15, 2025, about 5.5 months later. If Advanced follows that pattern, the current 549-question bank will likely stay the examined bank into 2027.

The recommendation still stands: treat Advanced as a separate, phased course and build multi-bank support rather than hardcoding one bank. Vendoring the Advanced files first needs an owner decision (see Decisions).

---

## Findings

### 1. Official question bank details and artifacts

1. **Distribution (Verified).**
   - **TXT ZIP:** `https://apc-cap.ic.gc.ca/datafiles/amat_adv_quest.zip`. The ISED Downloads page says: "Amateur advanced questions (delimited TXT format) — This link provides a ZIP file containing a delimited text listing of a full set of all possible questions for the advanced level amateur exam." <https://www.ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/downloads>
   - **EN PDF:** the EN page (<https://ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/amateur-radio-exam-generator/print-all-advanced-questions>) links `http://apc-cap.ic.gc.ca/datafiles/amateur_advanced_questions_en.PDF` ("Print full set of advanced questions in PDF format").
   - **FR PDF:** the FR page (<https://www.ised-isde.canada.ca/site/services-certificats-operateur-radioamateur/fr/generation-dexamens-radioamateurs/imprimer-toutes-questions-niveau-superieur>) links `http://cap-apc.ic.gc.ca/datafiles/amateur_advanced_questions_fr.PDF`. Note the host is spelled differently (`cap-apc`). I did not test whether it resolves.
   - **French TXT:** the French Downloads page lists the same file as "Liste des questions d'examens radioamateurs du niveau supérieur (en format TXT délimité)".
   - **Edition (Unverified):** ISED says only "This question bank contains the questions that will be used effective the date printed on the title page." I couldn't parse the title-page date (PDF extraction failed). Page metadata: created 2014-03-05, modified 2017-03-08. **Action:** read the date from the PDF title page and use it as the bank ID.

2. **Lineage and rewrite status (Corrected and qualified).**
   - *Verified:* the ISED RIC index says: "RIC-8 - Advanced Qualification Question Bank … No longer available as a Radiocom Information Circulars (RIC). Refer to Amateur Radio Operator Certificates : Print All Advanced Questions." <https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric>
   - *Verified:* RIC-8 Issue 3 took effect April 1, 2007 and used IDs like `A-001-01-01` (publications.gc.ca Iu64-119/2007E). The current file uses `A-001-001-001`, so ISED renumbered at some point. The original bank's date is unknown.
   - *Verified (RAC):* "Most of these volunteers are also working on the update to the Advanced Question Bank. This work is expected to be complete in 2026." <https://www.rac.ca/esc_cne/> and <https://www.rac.ca/update-of-basic-amateur-radio-exam-ised/>
   - *Verified (RAC-owned Hamstudy):* "Innovation, Science and Economic Development (ISED) Canada will be implementing a new Advanced Question Bank in late 2026. Hamstudy Advanced 2021 is available now and it will prepare you for success on the current Advanced Amateur Radio Certificate exam." <https://hamstudy.com/2025/>
   - *Secondary (RAC committee member, forum post 2026-06-12):* "Now if they would just get off the pot and issue the revised Advanced question bank - it's been more than a year since we submitted the draft." Dave VE3WI, <https://www.gbarc.ca/ForumBB/showthread.php?tid=1698>
   - *Verified (as of 2026-10-01):* the ISED exam generator page announces only the Basic update of July 15, 2025, with no Advanced update. <https://ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/amateur-radio-exam-generator>
   - **Correction:** "late 2026" is RAC's and Hamstudy's expectation, not an ISED commitment. The RAC draft is waiting on ISED, and no effective date exists. The brief's "actively being rewritten" is stale.

3. **Structure and IDs.**
   - *Verified, RIC-3 §5.3:* "An examination of 50 questions is prepared by drawing one question from a series of questions applicable to the following 50 topic areas. The pass mark is 70%." <https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-3-information-amateur-radio-service>
   - *Verified, ISED Help: Study questions:* "The 'Question ID' must be typed in the format L-CCC-SSS-### … L is the level (i.e. A for Advanced and B for Basic). C is the category number, S is the subcategory number, and ### is the question number." <https://www.ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/help/help-study-questions>
   - **Categories:** EN names from RIC-3; FR names verified from CIR-3, <https://ised-isde.canada.ca/site/gestion-spectre-telecommunications/fr/licences-certificats/circulaires-dinformation-radiocom-cir/cir-3-renseignements-service-radioamateur>.

     | Category | EN | FR | Topics | Questions* |
     |---|---|---|---|---|
     | A-001 | Advanced Theory | Théorie avancée | 5 | 54 |
     | A-002 | Advanced Components and Circuits | Notions avancées sur les composants et les circuits | 12 | 132 |
     | A-003 | Measurements | Mesures | 6 | 66 |
     | A-004 | Power Supplies | Alimentation | 4 | 44 |
     | A-005 | Transmitters, Modulation and Processing | Émetteurs, modulation et traitement | 9 | 99 |
     | A-006 | Receivers | Récepteurs | 5 | 55 |
     | A-007 | Feedlines - Matching and Antenna Systems | Descentes d'antenne - adaptation et systèmes d'antenne | 9 | 99 |
     | **Total** | | | **50** | **549** |

     \*Question counts come from a third-party tool's parse of the live ZIP (<https://github.com/lpaseen/ca_ham_license_quiz>) and match my line count of the 2024-08-28 archived ISED file (<https://github.com/amingilani/canada-amateur-radio-test-bank-archive>: header plus 549 rows, first `A-001-001-001`, last `A-007-009-011`). hamprep.ca also says "549 published questions". *Inference:* about 11 questions per topic (10.8 in A-001). I did not count each topic directly.

   - **Topic lists:** the 50 topic areas in the original brief match RIC-3 §5.3.1–5.3.7, with these corrections:
     - 3-2: "PEP, PEP relative to average power, PEP relative to voltage across load"
     - 3-4: "crystal calibrator, **marking** generator, frequency counter"
     - 4-1: "transformer and rectifier circuits, voltage doubler circuit, **PIP**" (RIC-3 does not list "PIV")
   - The FR category names are the CIR-3 syllabus headings. I did not confirm that the exam generator's French dropdown uses the same strings; check before showing French headings, per `docs/content-licensing.md`.

---

### 2. Exam rules and qualifications

1. **50 questions, one per topic (Verified).**
   - RIC-3 §5.3 (quoted above).
   - ISED Help: Printing an exam: "Questions are chosen automatically from all categories with at least one question from each sub-category. … 'Advanced Amateur' exams have 50 questions." <https://ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/help/help-printing-exam>
   - Fix the brief's RIC-3 URL typo: "radiocommonication" should be "radiocom-information".

2. **Pass mark 70%, no Advanced Honours (Verified).**
   - RIC-3 §5.3: "The pass mark is 70%."
   - ISED Help: "The pass mark is 70% or more. The pass mark for 'Basic with Honours' is 80% or more."
   - RIC-1 §7.3: "The pass mark for a written examination is 70%. However, a pass mark of 80% provides the candidate with additional high frequency (HF) operating privileges … referred to as 'Basic with Honours'." <https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-1-guide-examiners-accredited-conduct-examinations-amateur-radio-operator-certificates>

3. **What Advanced grants.**
   - **Eligibility (Corrected):** RIC-1 §7.1: "A candidate may attempt one or all qualifications at any time, but no certificate will be issued unless the candidate has passed the examination for the Basic Qualification." RIC-3 §4.1 does not state a prerequisite. Hamstudy's "You must first pass the Basic Qualification before you are eligible to attempt the Advanced exam" contradicts RIC-1 (see Contradictions).
   - **Power (Verified), RBR-4 §10.3:** "1,000 W to the anode or collector circuit … 2,250 W peak envelope power for transmitters that produce any type of single sideband emission, or 750 W carrier power for transmitters that produce any other type of emission." §10.2 sets Basic at 250 W / 560 W PEP / 190 W. <https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service>
   - **Home-built equipment and repeaters (Verified, wording corrected), SOR/96-484 s.44:** "must hold an Amateur Radio Operator Certificate with Advanced Qualification in order to (a) install or operate a transmitter or a radio frequency amplifier that is not commercially manufactured … ; or (b) install any radio apparatus to be used specifically (i) for receiving and automatically retransmitting radiotelephone communications within the same frequency band, or (ii) for an amateur radio club station." <https://laws-lois.justice.gc.ca/eng/regulations/SOR-96-484/FullText.html>
     - RIC-3 §4.5.2 adds "modify radio apparatus by computer program or physical modifications to the circuitry" and "establishment of repeaters and club stations".
     - Basic limits (RIC-3 §4.5.1): kits only; software reprogramming only; cross-band repeaters allowed.
     - Calling the Advanced holder a club "trustee/sponsor" is interpretation, not regulatory text.
   - **Remote control (Verified):** RIC-3 §4.5.2: "remote control of fixed stations, including the use of radio links". §4.5.1: Basic has "no remote control of fixed stations permitted".
   - **HF (Verified):** RIC-3 §4.4(1): "Amateurs holding both basic and advanced qualifications will be allowed to operate in the HF bands below 30 MHz". RBR-4 Schedule I Column IV lists HF bands as "B and 5, B/H, B and A".
   - **CEPT (Verified):** RIC-3 §8.2.1: "a Canadian needs to hold an Amateur Radio Operator Certificate with Basic Qualification and Advanced Qualification and have their call sign on their certificate."
   - **Accredited examiner (Verified, with additions):** RIC-1 §3.2: "must hold an Amateur Radio Operator Certificate with Basic, Morse code (5 wpm) and Advanced qualifications, and be 18 years of age or older."

---

### 3. Licensing terms and public-release policy

1. **Same ISED terms as Basic (Verified).** I found no Advanced-specific licence.
   - ISED Terms, non-commercial reproduction: "you may reproduce the materials in whole or in part for non-commercial purposes … without charge or further permission". Commercial: "you may not reproduce materials … for the purposes of commercial redistribution without prior written permission". <https://ised-isde.canada.ca/site/ised/en/terms-and-conditions>
   - ISED Copyright—Written permission adds: "Permission is always required when the work is being revised, adapted, or translated…" <https://www.ised-isde.canada.ca/site/ised/en/copyright-written-permission>
   - *Inference:* structured app data with shuffled choices may count as adaptation, which supports keeping T-007 scope explicit.

2. **Permission request covers Advanced; not granted (Verified).** `docs/content-licensing.md`: "Covered source artifacts | Pending scope: request includes … Advanced question bank …". **Correction:** the request is drafted but not sent ("Drafted (2026-09-28 owner decision); sent: pending; granted: pending").

3. **Vendoring Advanced for private development (Corrected).**
   - The interim private-development policy lets the project commit only the listed Basic 2025 artifacts under `content/sources/ised/basic-2025-07-15/`.
   - The Source update policy step 3 says: "Confirm private-development handling or written permission scope covers the new source version before committing it."
   - It also keeps "legacy bank support out of scope unless separately approved".
   - So vendoring Advanced files needs the owner to extend the interim policy first. Public distribution stays blocked by T-007 and the public-release gate (Verified).

---

### 4. Differences from Basic affecting pipeline, engine and content

1. **Delimited file and importer.**
   - *Verified:* the ZIP contains `amat_adv_quest_delim.txt`, `readme_adv.txt` and `lisezmoi_sup.txt`. The readme says: "Each record has the following data, separated by ';'", followed by the same 11 fields as Basic.
   - **New finding, header:** there is a header row: `question_id ;question_english;…;incorrect_answer_3_french`. Note the trailing space after `question_id`.
   - **New finding, encoding:** the archived file is not valid UTF-8; accented French characters fail to decode. *Inference:* Windows-1252 or ISO-8859-1. The importer must decode explicitly and keep the French text verbatim. Re-check against the live file and record its SHA-256.
   - **Differences from Basic (Verified):** `A-` prefix; 7 categories with no regulations category; 50 topics instead of 100; 549 questions instead of 984. A separate `categories-advanced.json` and checksum manifest are needed.

2. **Engine rules (Verified against official rules and the repo).**
   - Exam: 50 questions, one per topic. Pass if ≥ 70% (≥ 35/50). No Honours.
   - Current repo code:
     - `scoreExam` returns `honours: percent >= 80`.
     - `generateExam` throws unless there are exactly 100 subsections when `requireFullMockExam` is set.
     - `computeReadiness` order: fewer than 2 exams gives `not-enough-data`; weak categories (< 70%) or 5+ due reviews give `needs-review`; 2 of the last 3 exams at ≥ 80% give `honours-ready`; 2 at ≥ 70% give `pass-ready`.
   - For Advanced, `honours-ready` must be suppressed and the subsection count parameterized.
   - `categoryIdFromQuestionId` and `subsectionIdFromQuestionId` (slice 0–5 and 0–9) already work for `A-` IDs (*Inference* from the code).

3. **Reference material and calculators (Corrected).**
   - RIC-1 Issue 8 §7.2, which replaces the RIC-3 §5.4 quote: "Examinations are closed book. Reference material must not be used during the examination except for the ISED-approved formula and block diagram sheet labelled 'Reference Material for Amateur Radio Exam – Basic Qualification' … The use of calculators is permitted provided that the calculator does not have the capability of storing formulas or text."
   - For Advanced: no reference sheet, but a basic non-storing calculator is allowed.
   - Explanations can assume a simple calculator, and formulas must be memorized. The app must not present the Basic sheet as allowed on the Advanced exam.
   - The math topics listed in the original brief match the RIC-3 syllabus (time constant, resonance, Q, RMS/PEP, op-amps, matching, FM deviation). The formulas themselves are standard engineering knowledge, not ISED text.

---

### 5. Architectural reuse and multi-bank plumbing

1. **Reusable as-is.**
   - The PRNG, Leitner logic and shuffling are generic (not re-audited beyond `exam.ts`).
   - `ExamGenerationInput` and `GeneratedExam` carry `bankId` (Verified).
   - **Correction:** the engine-ts `ExamScore` interface (`scoring.ts`) has no `bankId`.
   - The `Question`/`Answer` schemas and the SwiftData `QuestionProgressRecord` `bankId` claim are **Unverified**; I did not inspect them.
   - Design tokens and UI reuse are a design judgement, not checked.

2. **Needs plumbing (Verified against code).**
   - Hardcoded `ACTIVE_BANK_ID = "basic-2025-07-15"`.
   - The 100-subsection guard in `generateExam`.
   - The fixed 80% Honours in `scoreExam` and `computeReadiness`.
   - Plus course selection, progress export namespacing, and bank-filtered queries (design items).
   - **Add:** importer encoding handling and header-row skipping for the Advanced file.

---

### 6. Content effort and sizing (corrected)

- **Questions:** **549** official questions in the current bank (Corrected from about 500). The size of the future bank is unknown (Unverified).
- **Subsections:** 50.
- **Lessons:** about 30–40 (*Estimate*).
- **Explanations:** about 549 for the current bank (*Estimate*: one per question).
- **French:** verbatim ISED FR text comes from the TXT; original lesson and explanation prose needs project translation if French UI is kept (consistent with project policy).
- **Basic comparison (Verified):** 984 questions and 100 topics. Advanced is about 56% of Basic's question volume and half the topics. "1.5× longer per explanation" is an unverified *Estimate*.

---

### 7. Key strategic risks

1. **Bank replacement risk (HIGH, but the timing has changed).**
   - *Finding (Corrected):* RAC finished and submitted a draft revised bank (by about mid-2025, per VE3WI). ISED has not published it or set an effective date as of 2026-10-01. "Late 2026" is RAC's and Hamstudy's expectation only.
   - *Basic precedent (Verified):* published Jan 27, 2025, effective July 15, 2025. 201 of 984 questions were new; all 984 were reviewed.
   - **Correction:** the claim that ">80% of Basic changed" is unsupported.
   - *Inference:* the share of Advanced questions rewritten is unknown. It may be closer to Basic's (about 20% new plus edits) than to "60–80%". Wasted effort is still real, because edited wording changes explanations.
   - **Recommendation (kept, adjusted):** build multi-bank and importer infrastructure first. Hold off on heavy curriculum authoring until ISED publishes the new bank. Revisit this hold if ISED has not published by an owner-chosen review date (suggested 2027-03-31). Given the Basic notice period, the current bank is likely to remain examinable well into 2027 (*Inference*).

2. **Public release gate and licensing (MEDIUM, Verified).**
   - No public release of Advanced features until T-007 records written permission whose scope explicitly covers Advanced data.
   - **Added:** private vendoring of Advanced files also needs an owner-approved extension of the interim policy.

---

## Contradictions

1. **Basic prerequisite.** Hamstudy says you must pass Basic before you may *attempt* Advanced. RIC-1 Issue 8 §7.1 says candidates may attempt any qualification at any time, but no certificate is issued until Basic is passed. RIC-1 is the authoritative source.
2. **Calculators.** RIC-3 Issue 5 §5.4 (2022) prohibits "calculators or any other similar device that are capable of storing information in memory". RIC-1 Issue 8 §7.2 (2025) permits calculators that can't store formulas or text and allows only the Basic reference sheet. Both effectively allow simple calculators. RIC-1 is newer and more specific; treat RIC-3 §5.4 as superseded on this point.
3. **Rewrite timing.** RAC (Jan 2025): work "expected to be complete in 2026". Hamstudy: ISED "will be implementing" in late 2026. RAC committee member (June 2026): the draft was submitted more than a year earlier and ISED has not issued it. ISED: no announcement. These can't be reconciled into a firm date.
4. **Basic change scale.** The brief's ">80% changed" conflicts with RAC's "201 new questions" out of 984.

## Missing evidence

- The edition or effective date printed on the current Advanced PDF title page.
- SHA-256 and question count of the **live** `amat_adv_quest.zip`. 549 rests on a 2024-08-28 archive plus third-party parses of the live file.
- The exact text encoding of the live TXT.
- Any ISED notice of the new Advanced bank (release date, effective date, size, structure, whether a reference sheet will be added).
- French category labels as shown in ISED's exam generator (CIR-3 headings verified only).
- The Swift `QuestionProgressRecord` and TS `Question`/`Answer` `bankId` fields.

## Sources

**Kept (official):**
- RIC-3 Issue 5 (EN): <https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-3-information-amateur-radio-service>
- CIR-3 (FR): <https://ised-isde.canada.ca/site/gestion-spectre-telecommunications/fr/licences-certificats/circulaires-dinformation-radiocom-cir/cir-3-renseignements-service-radioamateur>
- RIC-1 Issue 8 (May 2025): <https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-1-guide-examiners-accredited-conduct-examinations-amateur-radio-operator-certificates>
- RBR-4 Issue 3: <https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service>
- SOR/96-484: <https://laws-lois.justice.gc.ca/eng/regulations/SOR-96-484/FullText.html>
- ISED Downloads: <https://www.ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/downloads>
- ISED Print all advanced questions (EN and FR), Help: Printing an exam, Help: Study questions, Exam generator (URLs above)
- ISED RIC index: <https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric>
- ISED Terms and conditions; ISED Copyright—Written permission
- publications.gc.ca RIC-8 Issue 3 (2007): <https://publications.gc.ca/site/eng/9.888025/publication.html>

**Kept (RAC):**
- <https://www.rac.ca/esc_cne/>
- <https://www.rac.ca/update-of-basic-amateur-radio-exam-ised/>
- <https://hamstudy.com/2025/> (RAC-owned)

**Secondary (used only for corroboration):**
- GBARC forum (VE3WI, 2026-06-12)
- lpaseen/ca_ham_license_quiz (live-ZIP parse)
- amingilani/canada-amateur-radio-test-bank-archive (2024-08-28 ZIP mirror; the archive may have stopped updating)
- hamprep.ca/advanced/cheatsheet

---

## Next steps and phased plan (adjusted)

| Phase | Title | Scope | Effort (estimate) |
|---|---|---|---|
| A | Multi-bank architecture | Parameterize bank ID, subsection count (50/100), category set and Honours flag in content-tools, engine-ts and CanadianHamEngine. Add `bankId` where scores and progress need it (engine-ts `ExamScore` currently lacks it). Namespace progress export. | Medium (1.5–2 weeks) |
| B | Advanced ingestion (**gated on owner approval to extend the interim policy**) | Vendor the current Advanced ZIP and PDFs under `content/sources/ised/advanced-<title-page-date>/` with SHA-256. Write an importer with explicit legacy-encoding decoding and header-row handling. Validate 549 questions, 7 categories and 50 subsections. Add a fixture for 50-question exams and no-Honours scoring. | Small (3–5 days) |
| C | Multi-course UI | Course switcher; Advanced practice and 50-question mock exams without lessons. Do not show the Basic reference sheet as exam-allowed for Advanced. Keep the offline and no-data rules. | Medium (1–2 weeks) |
| D | Curriculum authoring (gated on ISED publishing the new bank, or an owner review date) | Vendor the new bank; 30–40 lessons; one original explanation per question, written assuming a basic calculator and no formula sheet. | Large (4–6 weeks) |

## Decisions needed from the owner

1. **Launch timing vs. the ISED rewrite.**
   - *Option 1 (recommended):* Phases A–C now on the current 549-question bank. Defer heavy authoring until ISED publishes the new bank. **Added:** set a review date (e.g., 2027-03-31) to reconsider if ISED still hasn't published, because "late 2026" has no ISED backing.
   - *Option 2:* author against the current bank now, accepting rework.
2. **App packaging.** Unchanged. Option 1 (one app with a course selector) recommended, or Option 2 (a separate Advanced app).
3. **ISED permission request (corrected).** The request is drafted, not sent. Before sending, confirm the scope explicitly names the current Advanced bank (TXT and PDFs), future Advanced revisions, and adapted or structured formats. ISED requires permission for adaptation.
4. **New: interim private-development policy.** Approve, or decline, extending the interim policy in `docs/content-licensing.md` to cover verbatim Advanced source files under `content/sources/ised/advanced-…/`. Phase B is blocked until this is approved and documented.

## Proposed Backlog tasks (replaces "PLAN.md task rows")

Per AGENTS.md, Backlog.md is the source of truth and `tasks/PLAN.md` is only a pointer. Search first, then create these with the `backlog` CLI on a branch, with `--ac` and `--dep`:

| Proposed task | Depends on | Key acceptance criteria |
|---|---|---|
| Multi-bank engine and schema plumbing | T-701, v1 release | `bankId` parameterized in content-tools, engine-ts and CanadianHamEngine; 50-subsection mock exams; 7 categories; Honours disabled and `honours-ready` suppressed for Advanced; `bankId` on scores and progress |
| Owner decision: extend interim policy to Advanced sources | — | `docs/content-licensing.md` updated by the owner-approved change |
| Vendor current Advanced bank and importer | the two tasks above | Verbatim ZIP and PDFs with SHA-256; title-page date recorded as the bank ID; legacy-encoding decoding; header-row handling; validation of 549 / 7 / 50 against the live file |
| Multi-course UI integration | importer task | Course switcher (web and Apple); Advanced practice and 50-question mocks; no Basic reference sheet shown as allowed for Advanced |
| Ingest new ISED Advanced bank (blocked) | ISED publication | Re-verify checksums, counts, categories, exam rules and effective date |
| Author Advanced curriculum (blocked) | new-bank ingest, or owner review date | 30–40 lessons; one original explanation per question |

## Residual risks

- The 549 count and file layout rest on a 2024-08-28 archive plus third-party parses. The live file could have changed. Hash and count it at ingestion.
- No first-party source gives the current bank's edition or effective date.
- The French TXT encoding is inferred from the archived copy's bytes, not confirmed.
- ISED's timing for the new bank is unknown. "Late 2026" may slip well into 2027 or later.
- Licensing scope depends on T-007. ISED's adaptation clause may bear on shuffled or structured formats.
- The Swift and TS schema `bankId` claims were not inspected.
