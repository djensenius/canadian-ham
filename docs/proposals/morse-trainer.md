# Morse Trainer Proposal: Canadian 5 wpm Morse Qualification and Trainer Design

**Audit date:** 2026-10-01
**Source-check method:** I read the current ISED documents directly: RIC-1 Issue 8 (May 2025), RIC-3 Issue 5 (March 2022), RBR-4 Issue 3 (July 2022) and the ISED certificate-services FAQ. I also read the 2020 Canada Gazette Part II, two RAC pages, Apple Developer documentation (the JSON documentation endpoints), MDN and W3C WCAG. Some items rest only on search-engine excerpts or secondary sources; those are marked in the table.

**Bottom line:**
- **The qualification still exists.** The Morse code (5 wpm) qualification is current. With Basic, it gives access to all amateur bands below 30 MHz. Examiners must hold it.
- **The "100%" vs "≤5 errors" contradiction isn't real.** ISED defines a mark of 100% as 5 errors or fewer, and 100% is the pass mark.
- **12 wpm character speed is confirmed.** ISED's spacing approximation (about 7 dots between letters and 17 between words) doesn't add up to 5 wpm, though. By ISED's own PARIS check it works out to about 7.9 wpm. The proposed trainer's default timing should match the PARIS-calibrated 12/5 mode.
- **Other corrections:** one history date (2002 → 2005), the haptics and flashing-light design, and the legacy `PLAN.md` rows (this project now tracks work in Backlog.md).

---

## Verification summary

| # | Claim (from brief) | Status | Source and exact supporting passage |
|---|---|---|---|
| 1 | Morse code (5 wpm) is a current ISED qualification | **Verified** | RIC-1 §7.1 ([URL](https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-1-guide-examiners-accredited-conduct-examinations-amateur-radio-operator-certificates)): "There are four (4) qualifications associated with Amateur Radio Operator certificates: Basic · Basic with Honours · Advanced · Morse code (5 wpm)". RBR-4 Schedule I ([URL](https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service)): "**5:** Amateur Radio Operator Certificate with Morse Code (5 w.p.m.) Qualification" |
| 2 | Document issues: RBR-4 Issue 3 (Jul 2022), RIC-1 Issue 8 (May 2025), RIC-3 Issue 5 (Mar 2022) | **Verified** | Page headers: "Issue 3 July 2022" (RBR-4), "Issue 8 May 2025" (RIC-1), "Issue 5 March 2022" (RIC-3) |
| 3 | RBR-4 Schedule I Column IV for bands below 30 MHz is "B and 5, B/H, B and A" | **Verified, with a refinement** | RBR-4 Schedule I: "3 1.800-2.000 MHz 6 kHz - B and 5, B/H, B and A … 16 28.000-29.700 MHz 20 kHz - B and 5, B/H, B and A". **Refinement:** the same column also covers LF/MF ("1 135.7-137.8 kHz … B and 5, B/H, B and A"; "2 472-479 kHz … B and 5, B/H, B and A"), so this isn't HF only. Bands from 50 MHz up are "B". |
| 4 | Morse 5 wpm gives a Basic holder (no Honours) access to all bands below 30 MHz | **Verified, with caveats** | RIC-3 §4.5.3: "Morse Code (with either Basic Qualification or both Basic Qualification and Advanced Qualification) … access to all amateur bands". ISED FAQ ([URL](https://ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/frequently-asked-questions)): "The Morse code certification is one of three means of obtaining access to frequency bands below 30 MHz". **Caveats:** (a) Basic certificates issued before 2002-04-02 already carry Honours-equivalent privileges (RIC-3 §4.3). (b) Morse 5 wpm doesn't count toward the International Amateur Radio Permit (IARP) class (RIC-3 §8.2.2: "The Advanced Qualification and Morse Code (5 w.p.m.) are not considered when determining the class of the IARP"). (c) It doesn't add Advanced-level privileges; the 250 W Basic power limit in RIC-3 §4.5.1 still applies. (c) is my reading of the §4.5.1–4.5.3 lists, not an explicit statement. |
| 5 | Basic pass mark is 70%, Honours is ≥80% | **Verified** | RIC-3 §5.1: "The pass mark is 70%. A score of 80% or above will grant the individual additional privileges commensurate with the Basic Qualification with Honours." |
| 6 | Question bank item B-001-015-003 lists Morse as an HF pathway | **Verified (indirect)** | ISED 2025-07-15 Basic question bank PDF ([URL](https://ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/sites/default/files/documents/amateur_basic_questions_en_2025-07-15.pdf)), via search-index excerpt: "In addition to passing the Basic written examination, what must you do before you are allowed to use amateur radio frequencies below 30 MHz? … You must attain a mark of 80% on the Basic examination, or pass an Advanced or Morse code examination". The PDF text couldn't be extracted locally. Cross-checked against the hamstudy.dev 2025 pool. |
| 7 | Examiners must hold Basic, Morse 5 wpm and Advanced (RIC-1 §3.2) | **Verified** | RIC-1 §3.2: "All individuals who administer qualification examinations must hold an Amateur Radio Operator Certificate with Basic, Morse code (5 wpm) and Advanced qualifications, and be 18 years of age or older." The ISED FAQ says the same. |
| 8 | The exam is a receiving test and a sending test, each at least 3 consecutive minutes at ≥5 wpm | **Verified** | RIC-1 §8.2: "correctly send, by hand, a plain-language text … for a minimum of three (3) consecutive minutes, at a speed of not less than 5 wpm, using an ordinary radiotelegraph key, a semi-automatic key or an electronic hand key" and "correctly receive, by ear … copying legibly by hand, typewriter or word processor". RIC-3 §5.2: "consists of sending and receiving Morse Code at a speed of not less than 5 words per minute (w.p.m.) for three consecutive minutes." |
| 9 | The exam is given by an accredited examiner **or the ISED district office** | **Corrected** | RIC-3 §6.2: "Most examinations are conducted by accredited examiners. In circumstances where this is not possible, ISED personnel may be able to conduct the examination. Candidates can contact the Amateur Radio Service Centre". ISED exams are a fallback through the Amateur Radio Service Centre (ARSC), not a parallel route. RAC's older page still says "be examined at the local district office of ISED" ([URL](https://www.rac.ca/requirements/)). |
| 10 | Virtual Morse exams are allowed | **Verified (wrong section cited)** | RIC-1 **§8.1.1** (the brief cited §7.2.1): "the examiner must have a prepared audio file of a text in Morse code that meets the specifications outlined in section 8.2" and "the candidate must have blank writing materials that they will use to transcribe". Virtual receiving copy is **handwritten**, and an image is sent to the examiner. |
| 11 | Characters are sent at **12 wpm** | **Verified** | RIC-1 §8.2: "Morse code shall be sent at a character speed of 12 wpm. It is the length of the spacing between characters and between words that determines the speed of the test." |
| 12 | Farnsworth spacing of about 7 dots between letters and 17 dots between words gives 5 wpm | **ISED wording verified; the arithmetic doesn't support 5 wpm** | RIC-1 §8.2: "for the 5 wpm test, the spaces between letters would be approximately 7 dots in length, and the spaces between words approximately 17 dots in length." **My calculation (inference):** 12 wpm dot = 0.1 s. PARIS has 31 units of characters plus 4 letter gaps and 1 word gap: 3.1 + 4×0.7 + 1.7 = 7.6 s, which is **≈7.9 wpm**. If "dots" means 5-wpm dots (0.24 s), it's ≈4.3 wpm. Either way, ISED's own PARIS check isn't met. The ARRL/Bloom Farnsworth standard for c=12, s=5 gives Ta = (60·12 − 37.2·5)/(5·12) = 8.9 s, so the letter gap is **1.405 s** and the word gap **3.279 s**. PARIS then takes exactly 12.0 s, which is 5.0 wpm. Formula from ARRL ([URL](https://www.arrl.org/files/file/Technology/x9004008.pdf), read via a docest transcription): "Ta = (60c - 37.2s)/sc · Tc = (3Ta)/19 · Tw = (7Ta)/19". |
| 13 | "PARIS" sent 5 times in 1 minute is 5 wpm | **Verified** | RIC-1 §8.2: "To verify the speed of a Morse code sending machine, the word 'Paris' sent five times in one minute results in a code speed of 5 wpm." |
| 14 | A word is 5 characters; figures and punctuation count as 2 | **Verified** | RIC-1 §8.2: "A Morse code 'word' consists of five characters. The letters A through Z are counted as one (1) character each, and figures and punctuation signs are counted as two (2) characters each." |
| 15 | Allowed characters: A–Z, 0–9, `. , ? - /`, Q-signals and emergency signals ("SOS"); no accented letters | **Partly corrected** | RIC-1 §8.2: "Morse code tests shall only use letters of the alphabet, numbers, the period, the comma, the question mark, the dash and the fraction bar" and "Accented letters are not to be used". RIC-3 §5.2 adds "Q-signals and emergency signals" but never names SOS. The brief's SOS example is its own interpretation. Under RIC-1's "shall only use" list, SOS would have to be sent as the letters S-O-S, not as a run-together prosign. |
| 16 | Test length: at least 75 characters (about 75–80) | **Verified (in the sending context)** | RIC-1 §8.2: "at 5 wpm, at least 75 characters are sent in the three (3) minutes allocated." The RIC-1 §8.3 sample works out to 78 weighted characters (my count). |
| 17 | **Pass mark is 100% = 5 errors or fewer** (the brief's "contradiction") | **Verified; there's no contradiction** | RIC-1 §8.7: "giving a mark of 100% where there are 5 errors or less, 99% for 6 errors, 98% for 7 errors … The pass mark for code receiving is 100%." RIC-3 §5.2 applies this to **both** tests: "In both the sending and receiving examinations … A mark of 100% is awarded for five errors or less … The pass mark is 100%." **Note:** RIC-1 states the pass mark explicitly only for receiving. The sending pass mark comes from RIC-3 §5.2. |
| 18 | Each wrong or missing character is 1 error, figures and punctuation included | **Verified** | RIC-1 §8.7: "each character, including figures and punctuation, that is omitted or incorrectly sent or received, is counted as one (1) error." Figures and punctuation weigh 2 for length but count as only 1 error. |
| 19 | Characters "omitted at the end … due to falling behind" are errors | **Verified, but it's a sending-test rule** | RIC-1 §8.2: "When the text is sent by the candidate, the speed of the characters is immaterial, as long as the necessary number of characters is sent … Any characters omitted at the end of the text due to lack of time will count as errors." On the receiving side, omissions are already errors under §8.7. |
| 20 | 2 minutes to review the copy after receiving | **Verified** | RIC-1 §8.6: "Examiners shall allow two (2) minutes at the end of the receiving test for candidates to review their copy and make any changes or corrections". RIC-3 §5.2 says the same. |
| 21 | When sending, the candidate may give the **8-dot** error signal and resend | **Verified (from two sources)** | RIC-1 §8.6: "candidates may send the error signal and resend the character as many times as they wish, but they must send the complete text within the time allotted." The 8 dots come from ITU-R M.1677-1 ([URL](https://www.itu.int/dms_pubrec/itu-r/rec/m/R-REC-M.1677-1-200910-I!!PDF-E.pdf), search excerpt): "Error (eight dots) . . . . . . . ." RIC-1 doesn't specify the dot count itself. |
| 22 | Writing dots and dashes on the paper is grounds for rejection | **Verified** | RIC-1 §8.7: "Notations of dots and dashes on an examination paper will be considered as evidence of inability and cause for rejection of the test." |
| 23 | Accommodations (RIC-1 §8.1.2) | **Verified (wording refined)** | RIC-1 §8.1.2: "the sending portion … should be conducted by asking the candidate to recite the exam text in Morse code. For the receiving portion … the examiner should send the required text manually and have the candidate verbalize the characters … Code speed cannot be taken into account in these cases." |
| 24 | The 12 wpm qualification was discontinued in 2001 | **Unclear (year unconfirmed)** | ISED confirms it's no longer issued. Canada Gazette II, 2020-12-23 ([URL](https://canadagazette.gc.ca/rp-pr/p2/2020/2020-12-23/html/sor-dors278-eng.html)): "As ISED no longer issues the Morse Code (12 w.p.m.) certificate … The Regulations would retain a reference to Morse Code (12 w.p.m.) so that individuals with this qualification can continue to operate." The year 2001 appears only in secondary sources (hamstudy "freebasic"; an eHam item on a notice effective 2001-05-19). |
| 25 | Morse was "replaced by the 80% Honours threshold in **April 2002**" | **Corrected** | The Honours alternative came in **July 2005**. It applied to Basic holders certified after 2002-04-01 who scored ≥80%; earlier holders were grandfathered. ARRL Letter, 2005-07-29 ([URL](http://mailman.qth.net/pipermail/ham-news/2005/000454.html)): "Industry Canada … has essentially removed the requirement … to obtain a 'Morse Qualification' for access to bands below 30 MHz … Licensees holding only the Basic Qualification who were certified after April 1, 2002, and who achieved a passing grade of at least 80 percent also are allowed to operate on HF." RAC CARAB-25 minutes (search excerpt only): "gazetted July 28, 2005". The current position is in RIC-3 §4.4. |
| 26 | WRC-03 dropped the international Morse requirement | **Verified (secondary)** | ARRL Letter 2005, quoting Industry Canada. Question bank item B-001-020-004 (RAC 2025 copy): "Administrations determine if proficiency in Morse code is a requirement for authorization". |
| 27 | RAC confirms examiner delivery and virtual-exam procedures | **Partly verified** | RAC requirements page: "Accredited Examiners are available in many areas throughout Canada to provide both Morse code and written examinations". RAC's pages **don't** describe virtual exams; that comes from RIC-1 §7.2.1/§8.1.1. The RAC page is dated (it still says "Industry Canada"). |
| 28 | Koch method (Koch, 1936): 2 starting characters, add one at 90% | **Unverified at primary level; practice confirmed** | G4FON ([URL](https://www.g4fon.net/CW%20Trainer.php), search excerpt): "start off just learning two letters at full speed and add an additional letter once you reach 90% proficiency". I couldn't get Koch's 1936 original. The brief's sequence is the **G4FON order** (K M R S U A P T L O W I . N J E F 0 Y , V G 5 / Q 9 Z H 3 8 B ? 4 2 7 C 1 D 6 X) with "-" added. That's a common convention, not "the standard Koch sequence". |
| 29 | Web Audio: schedule on `audioContext.currentTime` and use AudioParam ramps | **Verified, plus an omission** | MDN Best practices ([URL](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API/Best_practices)): "if your website or application requires timing and scheduling, it's best to stick with the AudioParam methods". **Omission:** the browser autoplay rule says "Create or resume context from inside a user gesture". The trainer needs an explicit Start tap. |
| 30 | AVAudioEngine and AVAudioSourceNode run on iOS, iPadOS, macOS, tvOS and visionOS | **Verified** | Apple documentation JSON. AVAudioEngine: iOS 8.0, macOS 10.10, tvOS 9.0, visionOS 1.0. AVAudioSourceNode: iOS 13.0, macOS 10.15, tvOS 13.0, visionOS 1.0. Both are far below the project's 27.0 minimums. |
| 31 | Haptics via `UIImpactFeedbackGenerator` or Core Haptics on iOS/iPadOS | **Corrected (narrower than stated)** | Apple: `UIImpactFeedbackGenerator` platforms are only "iOS 10.0, iPadOS 10.0, Mac Catalyst 13.1", so not tvOS, visionOS or native macOS. `CHHapticEngine` exists on iOS/iPadOS/macOS/tvOS 14/visionOS, but hardware support has to be checked at runtime with `CHHapticDeviceCapability.supportsHaptics` ("whether the device supports haptic event playback"). That in practice it works mainly on iPhone is my inference; Apple's pages don't list devices. |
| 32 | A high-contrast flashing lamp meets WCAG "Guideline 2.3 (Three Flashes…)", or fades are enough | **Corrected** | The requirement is **Success Criterion 2.3.1** ([URL](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html)): content may not flash "more than three times in any one second period, or the flash is below the general flash and red flash thresholds". W3C's Understanding note defines the area threshold as more than 25% of any 10-degree visual field, equivalent to 25% of a 341×256 CSS-pixel rectangle, or **21,824 CSS px**. A general flash also depends on a ≥10% relative-luminance change (with the darker state below 0.80), and saturated-red transitions have their own red-flash threshold. **Inference:** at a 12 wpm character speed a dot plus its gap takes 0.2 s, so H, S, 5 and similar give 4–5 flashes per second. A large high-contrast or saturated-red lamp would fail. The default visual beacon must stay below both thresholds: keep the combined flashing area under 21,824 CSS px and avoid saturated red, or cap the beacon at ≤3 flashes/s; also keep luminance changes below the general-flash threshold where possible. Smooth fades alone don't satisfy 2.3.1. |
| 33 | Track the work as "rows to add to `tasks/PLAN.md`" | **Corrected (project rule)** | Repo [`AGENTS.md`](../../AGENTS.md): "Track all work in Backlog.md … `tasks/PLAN.md` is only a pointer and legacy ID map." New work should be Backlog tasks created with the `backlog` CLI. |
| 34 | Pedagogy defaults (15–18 wpm characters, 650 Hz tone, 5 ms ramps) and the IndexedDB/SwiftData schema | **Unverified (design choices)** | These are engineering or teaching judgments, not facts with an authority behind them. I didn't check them against the codebase's existing persistence layer. |

---

## Audit findings

### 1. Verified claims
The core regulatory facts are all supported by current primary ISED text (high confidence):
- The qualification exists, and Basic plus Morse gives access below 30 MHz (rows 1–8).
- Examiners must hold Basic, Morse 5 wpm and Advanced.
- 12 wpm character speed, the PARIS check, word weighting, at least 75 characters, the 2-minute review, error counting, the rejection rule for dot/dash notes, and the accommodations (rows 11, 13, 14, 16–23).
- On the brief's own question: **the pass mark is 100%, and 100% means ≤5 errors**. RIC-3 §5.2 applies this to both the receiving and sending tests. RIC-1 §8.7 states it explicitly only for receiving.

### 2. Contradicted claims
- **Spacing math (row 12).** "7-dot letter pause, 17-dot word pause" doesn't give 5 wpm effective. It gives about 7.9 wpm by ISED's own PARIS check (my arithmetic; ISED itself says "approximately"). The brief applied these numbers as "exact ISED timing" while also calling them 5 wpm effective. That can't be both.
- **History (row 25).** The Honours route to HF dates from July 2005, not April 2002.
- **Examiner channels (row 9).** ISED staff are a fallback, not an equal option to accredited examiners.
- **Haptics and flashing (rows 31–32).** Platform scope and the WCAG reading were wrong.
- **Task tracking (row 33).** `tasks/PLAN.md` is no longer where tasks live.

### 3. Weak, unclear or unsupported claims
- The 12 wpm qualification's end year of 2001 rests only on secondary sources (row 24).
- The SOS example (row 15) is the brief's interpretation.
- RAC as a source for virtual exams isn't supported (row 27).
- The Koch 1936 citation and "standard Koch sequence" aren't verified (row 28).
- **Levenshtein grading (inference):** RIC-1 counts characters "omitted or incorrectly sent or received". It doesn't say how to count **inserted** extra characters. Counting insertions is a design choice, not something ISED states.

### 4. Source-quality concerns
- The brief's RIC-1 link (`ic.gc.ca/eic/site/smt-gst.nsf/eng/sf01007.html`) is a legacy URL. It currently resolves to Issue 8; the canonical `ised-isde.canada.ca` URL is used below.
- The RAC requirements page is dated (it still says "Industry Canada").
- The 2005 history rests on the ARRL Letter (secondary but contemporary) and an excerpt from RAC CARAB minutes. I didn't locate the original 2005 Gazette notice.
- The question bank and ITU passages come from search-index excerpts because PDF extraction failed in this environment.

### 5. Missing evidence
- No ISED statement says what spacing examiners' software actually uses (true PARIS-calibrated Farnsworth vs the literal 7/17 dots).
- No primary source was found for the 2001 date.
- I didn't fetch Koch's original 1936 work.

### 6. Contradictions between sources
- **RIC-1 vs RIC-3 on the character set.** RIC-1 §8.2 lists only letters, numbers and `. , ? - /`. RIC-3 §5.2 also allows "Q-signals and emergency signals". RIC-1 is the newer, examiner-facing document, and Q-signals are made of letters anyway. Practical approach: use RIC-1's set and send any "emergency signal" as ordinary letters.
- **Pass mark scope.** RIC-1 §8.7 states it for receiving only; RIC-3 §5.2 applies it to both tests. The two don't conflict, but sending has no separately written rule in RIC-1.
- **RIC-1's spacing text vs its own PARIS check** (row 12). This one is inside a single ISED document.

### 7. What this changes in the brief's conclusion
The recommendation to build an offline Koch/Farnsworth trainer with a simulated ISED exam still stands. The changes:
- **(a)** The timing engine must offer a PARIS-calibrated 12/5 mode (letter gap 1.405 s, word gap 3.279 s). The literal RIC-1 7/17-dot spacing can be an optional, harder mode. This adds a new owner decision.
- **(b)** Grading: ≤5 errors passes for both receiving and sending. Each figure or punctuation mark counts as 1 error. The sending test passes only if the whole text (at least 75 weighted characters) is sent within 3 minutes.
- **(c)** Haptics only where `supportsHaptics` is true; the visual beacon follows WCAG 2.3.1 by staying small, avoiding saturated red, reducing luminance change, or limiting flash cadence.
- **(d)** Create Backlog tasks instead of `PLAN.md` rows.
- **(e)** Fix the history wording.

---

# Corrected brief: Canadian Morse Code 5 WPM Qualification and In-App Trainer Design (T-702)

## Summary
Canada still maintains the Morse Code (5 wpm) Qualification under ISED (RBR-4 Issue 3, July 2022; RIC-1 Issue 8, May 2025; RIC-3 Issue 5, March 2022).

**The exam.** Accredited examiners give it. ISED staff can do so only where an accredited examiner isn't available. It has two parts:
- a receiving test of at least 3 consecutive minutes;
- a sending test of at least 3 consecutive minutes.

Both use plain language at a speed of not less than 5 wpm. Examiners send at a **12 wpm character speed** and slow the overall speed by lengthening the spaces.

**Passing.** The pass mark is 100%, which ISED defines as **5 errors or fewer**. RIC-3 §5.2 applies this to both tests. Each omitted or wrong character is one error, figures and punctuation included.

**What it grants.** With Basic, it gives access to all amateur bands below 30 MHz (LF, MF and HF). That matters mainly to Basic holders certified after 2002-04-01 who scored 70–79%. It's also required to become an accredited examiner. It doesn't add Advanced privileges, and it doesn't affect the International Amateur Radio Permit (IARP) class.

**Recommendation.** Build a self-contained, offline Morse trainer:
- Koch method with Farnsworth timing;
- Web Audio API on the web and AVAudioEngine/AVAudioSourceNode on Apple platforms;
- a WCAG 2.3.1-compliant visual beacon and capability-gated haptics;
- a 3-minute simulated receiving exam with ISED-faithful grading, plus keyboard/touch sending practice;
- local-only persistence, consistent with the zero-telemetry design.

**Timing note.** ISED's wording ("approximately 7 dots / 17 dots") works out to about 7.9 wpm by ISED's own PARIS check. The default exam mode should therefore use PARIS-calibrated 12/5 Farnsworth timing. The literal-RIC-1 spacing can be an optional, harder mode (see Owner Decision 4).

---

## Findings

### 1. Current Canadian regulatory status and operating privileges
1. **Claim:** The Morse Code (5 wpm) qualification is a current ISED qualification. **Verified.**
   - **Sources:**
     - RIC-1 Issue 8 §7.1 ("four (4) qualifications … Morse code (5 wpm)").
     - RBR-4 Issue 3 Schedule I definitions ("**5:** … Morse Code (5 w.p.m.) Qualification").
     - RIC-3 Issue 5 §4.1, §4.5.3, §5.2.
     - ISED FAQ.
   - **Confidence:** High.
   - **Detail:**
     - In RBR-4 Schedule I (Column IV), every band below 30 MHz requires "B and 5, B/H, B and A". That includes 135.7–137.8 kHz and 472–479 kHz as well as 1.8–29.7 MHz. B = Basic, 5 = Morse Code (5 w.p.m.), B/H = Basic with Honours (≥80%), A = Advanced.
     - The 12 wpm qualification is no longer issued (Canada Gazette II, 2020-12-23), but existing holders keep it.
     - The brief's end date of 2001 for 12 wpm rests only on secondary sources (unverified).

2. **Claim:** What the qualification grants. **Verified, with caveats.**
   - **Sources:** RIC-3 §4.3–4.5.3, §5.1, §8.2.2; RBR-4 Schedule I; ISED Basic question bank (2025-07-15) item B-001-015-003; ISED FAQ.
   - **Detail:**
     - Basic plus Morse gives "access to all amateur bands" (RIC-3 §4.5.3).
     - It's one of three routes below 30 MHz: Basic ≥80%, Advanced, or Morse (ISED FAQ; B-001-015-003).
     - It matters to Basic holders certified **after 2002-04-01** who scored 70–79%. Holders certified before 2002-04-02 already have Honours-equivalent privileges (RIC-3 §4.3–4.4).
     - It doesn't add Advanced privileges: the 250 W DC input limit and the limits on building transmitters remain. This is my reading of RIC-3 §4.5.1 versus §4.5.2.
     - It's not considered for the IARP class (RIC-3 §8.2.2).
     - It's **required for accredited examiners**, along with Basic, Advanced and age 18+ (RIC-1 §3.2).
     - It's also valued in clubs as a mark of operating skill. That's informal, with no source behind it.

### 2. Exam structure, rules and pass criteria
1. **Claim:** The exam is a receiving test and a sending test, each at least 3 consecutive minutes at ≥5 wpm in plain language. **Verified** (RIC-1 §8.2; RIC-3 §5.2).
   - **Who gives it:** accredited examiners. "In circumstances where this is not possible, ISED personnel may be able to conduct the examination", through the Amateur Radio Service Centre (RIC-3 §6.2; corrected).
   - **Virtual exams** are allowed under RIC-1 **§8.1.1**:
     - the examiner plays a prepared audio file that meets §8.2;
     - the candidate copies by hand on blank paper and sends an image of it;
     - the examiner watches the sending part live over video.
   - **In person,** copy may be "by hand, typewriter or word processor" (RIC-1 §8.2).
   - **Sending keys:** an "ordinary radiotelegraph key, a semi-automatic key or an electronic hand key".
   - **Timing:** the examiner must time both tests (RIC-1 §8.5).
   - **Texts:** the sending text must differ from the receiving text (RIC-1 §8.4).

2. **Claim:** Characters, word length, speed and timing (RIC-1 §8.2).
   - **Character speed: verified.** "Morse code shall be sent at a character speed of 12 wpm." The standard element timing at 12 wpm:
     - dot = 0.1 s;
     - dash = 0.3 s;
     - gap between elements of a character = 0.1 s.
   - **Spacing: ISED text verified; its arithmetic is wrong.**
     - RIC-1 says the spaces between letters are "approximately 7 dots" and between words "approximately 17 dots".
     - With 12 wpm dots, PARIS takes 3.1 + 4×0.7 + 1.7 = 7.6 s, about **7.9 wpm** (my calculation).
     - The ARRL/Bloom Farnsworth standard gives Ta = (60c − 37.2s)/(sc) = 8.9 s for c = 12, s = 5. That makes the **letter gap 1.405 s** and the **word gap 3.279 s**. PARIS then takes 12.0 s, exactly 5 wpm.
     - The brief's "ratio ≈2.5×" paraphrases ISED's own approximation ("approximately 2.5 times").
   - **Speed check: verified.** "PARIS" sent five times in one minute is 5 wpm.
   - **Word definition: verified.** A word is 5 characters. A–Z count 1 each; figures and punctuation count 2 each.
   - **Allowed characters: partly corrected.**
     - RIC-1: letters, numbers, period, comma, question mark, dash and fraction bar only. No accented letters.
     - RIC-3 §5.2 also mentions Q-signals and "emergency signals". Q-signals are letter groups such as QTH, QSL and QSJ (QSJ appears in the RIC-1 sample).
     - "SOS" isn't named in either document. If used, send it as the letters S O S, not as a prosign.
   - **Length: verified.** "At 5 wpm, at least 75 characters are sent in the three (3) minutes". The RIC-1 §8.3 sample is about 78 weighted characters.

3. **Claim:** Scoring and pass criteria. **Verified; the brief's apparent contradiction is resolved.**
   - **Sources:** RIC-1 §8.2, §8.6, §8.7; RIC-3 §5.2.
   - **Rules:**
     - **Marking:** 100% for ≤5 errors, 99% for 6, 98% for 7, 97% for 8, and so on. **The pass mark is 100%,** so a pass means ≤5 errors. "100%" and "≤5 errors" say the same thing.
     - **Scope of the pass mark:** RIC-1 §8.7 states it for receiving. RIC-3 §5.2 applies it to both sending and receiving.
     - **What counts as an error:** each character omitted or wrongly sent or received is 1 error, including figures and punctuation. A figure weighs 2 characters for length but counts as only 1 error.
     - **Running out of time (sending):** characters left unsent at the end for lack of time count as errors. Character speed doesn't matter in the sending test, as long as enough characters (at least 75 in 3 minutes) are sent (RIC-1 §8.2).
     - **Copy review:** 2 minutes after the receiving test (RIC-1 §8.6).
     - **Corrections while sending:** the candidate may send the error signal and resend as often as they like, but must finish the whole text in the time allowed (RIC-1 §8.6). The error signal is eight dots (`........`) under ITU-R M.1677-1.
     - **Dots and dashes on the paper:** "evidence of inability and cause for rejection" (RIC-1 §8.7).
     - **Accommodations (RIC-1 §8.1.2):** for sending, the candidate recites the text in Morse aloud. For receiving, the examiner sends by hand and the candidate says the characters aloud. Marking is on errors only, and code speed isn't considered.
     - **Inserted extra characters:** ISED doesn't say how these count. Treating them as errors is our own conservative choice.

---

### 3. Proposed Morse trainer architecture for `canadian-ham`

#### A. Teaching method: Koch with Farnsworth spacing
- **Why Koch?** Practitioner consensus (G4FON, LCWO, LICW) is to learn characters at full speed so learners don't count dots and dashes. The 1936 primary source isn't verified here.
- **Recommended parameters:**
  - **Character speed:** 15–20 wpm (default 15 wpm). The ISED exam sends at 12 wpm; training faster makes 12 wpm sound easy. This is a teaching judgment.
  - **Effective speed:** 5 wpm, using the **PARIS-calibrated** Farnsworth spacing from the ARRL/Bloom formula.
  - **Koch progression:** start with 2 characters (`K`, `M`) and add the next one at ≥90% accuracy in a 1-minute drill (G4FON practice). The order is the **G4FON sequence**, adjusted to ISED's character set: `K M R S U A P T L O W I . N J E F 0 Y , V G 5 / Q 9 Z H 3 8 B ? 4 2 7 C 1 D 6 X -`. Prosigns are replaced by `-`, giving 41 characters in 40 lessons.

#### B. Canadian practice exam
- **Receiving exam mode:**
  - Generates plain-language text using only RIC-1 §8.2 characters: letters, digits, `. , ? - /`, and Q-signals sent as letters. No accented letters and no prosigns.
  - Target: **at least 75 weighted characters and at least 180 s of audio**. In literal-RIC-1 mode about 118 weighted characters are needed to fill 3 minutes, because that spacing runs at roughly 7.9 wpm.
  - **Timing modes:**
    - **(default) "ISED 5 wpm (PARIS-calibrated)":** 12 wpm characters, 1.405 s letter gap, 3.279 s word gap.
    - **(optional) "RIC-1 literal spacing":** 0.7 s letter gap and 1.7 s word gap, a harder practice mode of about 7.9 wpm.
  - Audio can't be paused during the timed stream.
  - Copy by live typing, or on paper and then typed in. A "virtual-exam style" option reminds the user to copy by hand, matching RIC-1 §8.1.1.
  - A **2-minute review countdown** follows playback (RIC-1 §8.6).
  - **Deterministic grading:**
    - Align the copy to the source text (Levenshtein/optimal alignment).
    - Count each omitted or wrong character as 1 error, figures and punctuation included.
    - Count insertions as errors as a conservative choice, labelled as not specified by ISED.
    - ≤5 errors is shown as 100% PASS; more than 5 is 99%, 98% and so on, FAIL. Show an item-by-item diff.
    - Show a warning if the user enters dot/dash notation.
- **Sending practice mode (keyer):**
  - Spacebar or touch straight key, plus an iambic paddle emulation.
  - Instant feedback on dot/dash lengths, and a state-machine decoder.
  - **Exam-style sending check:**
    - the full text (at least 75 weighted characters) must be finished within 3:00;
    - the 8-dot error signal followed by a resend is accepted;
    - ≤5 errors passes;
    - character speed is shown but **not** graded, per RIC-1 §8.2.
  - Label it as practice: the real exam needs a physical radiotelegraph, semi-automatic or electronic hand key.

#### C. Audio generation: offline and native
- **Requirements:** no network requests, no third-party audio libraries, works fully offline.
- **Web app (Web Audio API):**
  - `AudioContext`, `OscillatorNode` (sine, default 650 Hz) and `GainNode`.
  - About 5 ms gain ramps on each element edge to prevent key clicks.
  - All events scheduled against `audioContext.currentTime` using AudioParam methods (MDN best practice).
  - The context must be created or resumed from a user gesture (browser autoplay policy), so use an explicit Start button.
- **Apple apps:**
  - `AVAudioEngine` with `AVAudioSourceNode`, or with pre-rendered PCM buffers.
  - Both are available on iOS, iPadOS, macOS, tvOS and visionOS (Apple documentation); no extra frameworks needed.
- **Settings:**
  - Tone frequency: 400–900 Hz (default 650 Hz).
  - Character speed: 12–25 wpm (default 15).
  - Effective speed: 5 wpm up to the selected character speed (never faster). Farnsworth spacing only stretches the gaps between characters and words, so an effective speed above the character speed would need negative gaps under the Bloom formula; the setting is clamped to the character speed.
  - Exam timing mode: PARIS-calibrated or RIC-1 literal.
  - Trainer volume separate from system volume.

#### D. Accessibility and multimodal delivery
- **Visual beacon:**
  - Synchronized with the tone; essential for deaf and hard-of-hearing users.
  - **Constraint (corrected):** it must meet **WCAG 2.2 SC 2.3.1**. Morse at 12+ wpm character speed can exceed 3 flashes per second, so the default beacon should be small enough to keep the combined flashing area under the threshold (**≤21,824 CSS px**, 25% of a 341×256 CSS-pixel 10-degree field) and should avoid saturated red. Larger or high-contrast alternatives must be capped at ≤3 flashes/s or held below the general-flash luminance threshold.
  - Fades alone don't satisfy 2.3.1, and saturated-red flashes are checked against the separate red-flash threshold.
  - Offer a non-flashing alternative: a scrolling dot/dash "tape" display.
- **Haptics (corrected):**
  - Use Core Haptics (`CHHapticEngine`) only when `CHHapticEngine.capabilitiesForHardware().supportsHaptics` is true.
  - `UIImpactFeedbackGenerator` is iOS/iPadOS/Mac Catalyst only.
  - Expect support mainly on iPhone (inference). Hide haptic options on devices that lack it, including tvOS and visionOS unless the capability check says otherwise.
- **Screen readers / VoiceOver:** during timed audio drills, suppress live-region and VoiceOver announcements so they don't drown out the tone. Afterwards, expose transcripts, error counts and grading results with full semantics. This is a design choice.

#### E. Local-only progress storage
- **Storage:** a web IndexedDB store `morse_progress` next to the existing progress store, and Apple models `MorseProgress` and `MorseExamAttempt`. I didn't check these names against the current persistence code; confirm them in the scout step.
- **Metrics:**
  - Koch lesson (1–40);
  - per-character accuracy and a confusion matrix;
  - exam attempt history: date, timing mode, error count, pass/fail and the characters missed.
- **Import, export and reset:** included in the existing user-initiated JSON export/import and "Reset All Data". No network.

---

## Contradictions
- **Claim found online:** Morse testing in Canada ended after WRC-03.
  - **Resolution:** false. WRC-03 (2003) left Morse requirements to each country. In **July 2005**, Industry Canada made Morse one of several routes to HF; it had been the only extra requirement for Basic holders. The other routes: Basic certified before 2002-04-02, Basic with ≥80% after 2002-04-01, or Advanced.
  - The 5 wpm qualification is still current: RBR-4 Issue 3 Schedule I, RIC-3 Issue 5 §4.5.3/§5.2, and RIC-1 Issue 8 §7.1/§8.
  - The brief's "April 2002" date for the Honours change is corrected (ARRL Letter, 2005-07-29; RAC CARAB-25 minutes: "gazetted July 28, 2005").
- **Inside ISED's own text:** RIC-1 §8.2's "approximately 7/17 dots" spacing doesn't produce 5 wpm by RIC-1's own PARIS check. The trainer offers both modes (Owner Decision 4).
- **RIC-1 vs RIC-3 character set:** RIC-1 restricts the set to letters, numbers and `. , ? - /`; RIC-3 adds Q-signals and emergency signals. The generator follows RIC-1 and sends any Q-signals or emergency signals as plain letters.
- **The brief's own "100%" vs "≤5 errors":** not a contradiction. A mark of 100% is defined as ≤5 errors.

## Missing evidence
- **Morse question bank:** none exists; the exam is entirely practical. No changes to the question-bank importer are needed.
- **Official sample texts:** RIC-1 §8.3 gives one example ("FORECAST PERIODS WILL BE SHORTENED…QSJ 1962.") and says it "shall not be used in an examination". The generator therefore builds random texts that follow RIC-1 §8.2.
- **Examiner software timing:** no ISED source says which spacing examiners' audio files actually use. This is why the trainer offers both modes.
- **The 2001 date for the end of 12 wpm:** no primary source found.

---

## Sources

### Kept (primary)
1. **ISED RBR-4, Issue 3 (July 2022).** Schedule I sets the qualification needed for each band. [URL](https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service)
2. **ISED RIC-1, Issue 8 (May 2025).** Examiner requirements (§3.2), virtual exams (§7.2.1, §8.1.1), accommodations (§8.1.2), Morse specifications (§8.2), review (§8.6) and marking (§8.7). Canonical [URL](https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-1-guide-examiners-accredited-conduct-examinations-amateur-radio-operator-certificates). The legacy `ic.gc.ca/eic/site/smt-gst.nsf/eng/sf01007.html` link also resolves to Issue 8.
3. **ISED RIC-3, Issue 5 (March 2022).** Qualifications (§4), the Morse exam (§5.2), ISED examiners (§6.2) and IARP (§8.2.2). [URL](https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-3-information-amateur-radio-service)
4. **ISED Amateur Radio Operator Certificate Services FAQ.** Morse as one of three routes below 30 MHz; examiner qualifications. [URL](https://ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/en/frequently-asked-questions)
5. **ISED Basic question bank (2025-07-15),** item B-001-015-003. [URL](https://ised-isde.canada.ca/site/amateur-radio-operator-certificate-services/sites/default/files/documents/amateur_basic_questions_en_2025-07-15.pdf)
6. **Canada Gazette Part II, 2020-12-23 (SOR/2020-278).** The 12 wpm qualification is no longer issued but still recognized. [URL](https://canadagazette.gc.ca/rp-pr/p2/2020/2020-12-23/html/sor-dors278-eng.html)
7. **ITU-R M.1677-1.** International Morse code, including the eight-dot error signal. [URL](https://www.itu.int/dms_pubrec/itu-r/rec/m/R-REC-M.1677-1-200910-I!!PDF-E.pdf)
8. **ARRL / J. Bloom KE3Z, "A Standard for Morse Timing Using the Farnsworth Technique" (QEX, April 1990).** Farnsworth formulas. [URL](https://www.arrl.org/files/file/Technology/x9004008.pdf)
9. **Apple Developer documentation:** AVAudioEngine, AVAudioSourceNode, CHHapticEngine, CHHapticDeviceCapability.supportsHaptics, UIImpactFeedbackGenerator (platform availability). [URL](https://developer.apple.com/documentation/avfaudio/avaudioengine)
10. **MDN, Web Audio API best practices.** Autoplay rules and AudioParam scheduling. [URL](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API/Best_practices)
11. **W3C, Understanding WCAG 2.2 SC 2.3.1.** Three-flashes rule, general-flash luminance threshold, red-flash threshold and 10-degree-field area threshold. [URL](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html)

### Kept (secondary)
- **RAC requirements and examiners pages.** Confirm that accredited examiners give Morse exams. Dated, and silent on virtual exams. [URL](https://www.rac.ca/requirements/), [URL](https://www.rac.ca/examiners/)
- **ARRL Letter, Vol. 24 No. 29 (2005-07-29).** Covers the July 2005 HF-access change. [URL](http://mailman.qth.net/pipermail/ham-news/2005/000454.html)
- **G4FON Koch trainer.** Source of the Koch practice and character order. [URL](https://www.g4fon.net/CW%20Trainer.php)

### Rejected / deprioritized
- **Old RIC-7/RIC-8 PDFs:** superseded and not about Morse.
- **Third-party tutors (LCWO, CWops, ARRL courses):** useful only to support the teaching approach.

---

## Recommended phased implementation plan

### Phase M1: Shared Morse audio and timing engine
- `@canadian-ham/morse-engine` (TypeScript) and `CanadianHamMorseEngine` (SwiftPM).
- A deterministic generator that turns text into timed symbols, with **two named timing profiles**:
  - `isedParis`: 12/5 using the Bloom formula, letter gap 1.405 s, word gap 3.279 s;
  - `ric1Literal`: letter gap 0.7 s, word gap 1.7 s.
  - Plus general Farnsworth (c, s).
- Shared fixtures in `fixtures/morse/`:
  - PARIS at 12/5 `isedParis` = 12.0 s;
  - PARIS at 12/5 `ric1Literal` = 7.6 s;
  - word-weight counts (the RIC-1 §8.3 sample = 78 weighted characters);
  - each figure or punctuation mark = 1 error;
  - 5 errors = PASS (100%), 6 errors = FAIL (99%);
  - insertion handling.
- **Rough effort:** 2–3 days.

### Phase M2: Audio output and accessibility layers
- Web Audio driver: `OscillatorNode` with about 5 ms gain ramps, started by a user gesture.
- AVAudioEngine/AVAudioSourceNode driver for all Apple platforms.
- Settings for tone, character speed, effective speed and timing mode.
- A visual beacon that meets WCAG 2.3.1 (small area, no saturated red, luminance/cadence limits), plus a non-flashing "tape" display.
- Core Haptics gated on `supportsHaptics`.
- **Rough effort:** 3–4 days.

### Phase M3: Koch drills and local progress
- A 40-lesson Koch curriculum (G4FON order adapted to the ISED character set).
- Drill view with instant keyboard entry and feedback.
- Local IndexedDB (web) and Apple persistence for character mastery.
- **Rough effort:** 3–4 days.

### Phase M4: Simulated Canadian 5 wpm exam
- A 3-minute text generator following RIC-1 §8.2 (≥75 weighted characters and ≥180 s for the chosen timing).
- Uninterrupted playback, then the 2-minute review.
- Grading: ≤5 errors = PASS (100%), more than 5 = FAIL, with a diff.
- Exam-style sending check: whole text within 3:00, error signal accepted, ≤5 errors.
- **Rough effort:** 3–4 days.

**Total estimate:** about 11–15 engineering days. The second timing profile adds roughly half a day inside M1.

---

## Owner decisions needed
1. **Scope:** an integrated module or a separate app? **Recommendation (updated 2026-10-03):** keep it in the monorepo as its own route or tab (`canadian-ham/morse`). The Morse section is now a visible top-level preview; course, copy-practice, and exam drills remain coming soon until their Backlog work lands.
2. **Default character speed:** 12 wpm (the ISED exam's character speed) or 15–18 wpm (usual Koch practice)? **Recommendation (unchanged):** 15 wpm characters at 5 wpm effective, with a one-tap "ISED exam" preset at 12/5.
3. **Sending evaluation:** microphone pitch detection or tap timing? **Recommendation (unchanged):** tap timing on keyboard or touch. No microphone permission, which keeps the no-permissions, no-data design.
4. **(New) Exam timing profile:** RIC-1's spacing text ("≈7 / ≈17 dots") and its PARIS check disagree (≈7.9 wpm vs 5 wpm). **Recommendation:** default the exam to the **PARIS-calibrated 12/5** profile, which meets RIC-1's own speed check. Offer "RIC-1 literal spacing (≈7.9 wpm, harder)" as an option so candidates have a margin if an examiner's file runs faster. Optionally ask ISED's Amateur Radio Service Centre or RAC which spacing examiners' software actually uses.
5. **(New) Haptics scope:** ship haptics only where `supportsHaptics` is true (in practice iPhone), with no haptic UI on tvOS and visionOS? **Recommendation:** yes.

---

## Backlog tasks to create (replaces "PLAN.md rows to add")
Per [`AGENTS.md`](../../AGENTS.md), track this work in Backlog.md, not `tasks/PLAN.md`. The task content is kept below, with corrected facts for future Backlog tasks:

| ID (proposed) | Depends on | Task |
|---|---|---|
| T-702a | v1 release | Morse engine spec and shared fixtures: Farnsworth timing with `isedParis` (12/5, Bloom formula: 1.405 s / 3.279 s) and `ric1Literal` (0.7 s / 1.7 s) profiles; element mapping limited to RIC-1 §8.2 characters; PARIS fixtures (12.0 s / 7.6 s); word weighting (figures and punctuation = 2); error scoring per RIC-1 §8.7 / RIC-3 §5.2 (each character = 1 error; ≤5 errors = 100% pass). TS and Swift packages. |
| T-702b | T-702a | Audio drivers: Web Audio oscillator/gain envelope with a user-gesture start; AVAudioEngine/AVAudioSourceNode for iOS, iPadOS, macOS, tvOS and visionOS; no third-party audio dependencies. |
| T-702c | T-702b | Visual beacon meeting WCAG 2.2 SC 2.3.1 (small area, no saturated red, luminance/cadence limits), a non-flashing tape alternative, Core Haptics gated on `supportsHaptics`, and VoiceOver/ARIA coordination during playback. |
| T-702d | T-702b | Koch curriculum (G4FON order adapted to ISED characters, 40 lessons, 90% unlock) and drill UI for web and Apple; local persistence of character progress. |
| T-702e | T-702a, T-702b | Canadian 5 wpm mock exam: RIC-1 §8.2 text generator (≥75 weighted characters, ≥180 s), uninterrupted playback, 2-minute review, grading of ≤5 errors = PASS (100%), diff view, timing-profile selector. |
| T-702f | T-702e | Sending practice: keyboard/touch straight key and paddle emulation, dot/dash ratio feedback, exam-style check (whole text within 3:00, 8-dot error signal and resend accepted, ≤5 errors); no microphone permission. |

---

## Residual risks
- **Spacing math:** the RIC-1 inconsistency is my own arithmetic. ISED's "approximately" may simply be loose wording. What examiners actually do is unknown.
- **Unextracted PDFs:** the question bank and ITU-R M.1677-1 passages were checked through search-index excerpts and mirrors, because PDF extraction failed here.
- **2005 history:** rests on secondary but contemporary sources (ARRL Letter, CARAB excerpt). I didn't find the original 2005 Gazette notice.
- **Device haptics:** that haptics work mainly on iPhone is an inference. Apple's pages only give API availability and the runtime check.
- **Not audited:** the teaching parameters, and whether the proposed storage names fit the existing persistence code.