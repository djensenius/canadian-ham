# Teaching guide for lesson writers

This guide is the working standard for revising the 36 Basic lessons. It keeps the course plain, original, Canada-specific, and compatible with the current web and Apple Markdown renderers.

Use this guide with [content/lessons/README.md](../content/lessons/README.md), [docs/exam-facts.md](exam-facts.md), [docs/design.md](design.md), and [docs/accessibility.md](accessibility.md). The active exam source is `content/generated/basic-2025-07-15/questions.json`.

## 1. Plain-language standard

### Reading level and structure

- Target grade 7 to 8 English.
- Aim for 12 to 18 words per sentence. Split any sentence over about 25 words unless the sentence is a simple list.
- Use paragraphs of 1 to 3 short sentences. Keep one idea per paragraph.
- Use active voice: "The fuse opens the circuit," not "The circuit is opened by the fuse."
- Use concrete subjects. Say "a 13.8 V supply" instead of "the source" when the learner may have lost the reference.
- Define each technical term the first time it appears in a lesson. Put the plain meaning before the symbol when possible.
- Avoid Latin abbreviations. Use "for example," "that is," and "and so on" instead of "e.g.," "i.e.," and "etc."
- Lessons are English-only for this pass. Do not create French lesson prose.

### Terms, units, and number style

- Use the exam notation already used in the lessons: E for voltage, I for current, R for resistance, and P for power.
- Use `x` for multiply in prose and worked examples: `P = I x E`. This is the single course standard; when revising older lessons, replace `×` with `x` in learning prose and examples.
- Use `/` for division and keep formulas as real text, not images.
- Put a space between a number and a unit: `13.8 V`, `20 mA`, `146 MHz`.
- Use SI space grouping for thousands with a normal space character (`U+0020`): `1 000`, `2 250 W`, `3 525 kHz`, `13 800 mV`. Do not use commas or no-break spaces in authored lesson Markdown; the existing lessons use normal spaces, so keep them consistent (the originality tokenizer accepts either).
- Spell out ohms in running text. Use `Ω` only in compact tables when it improves readability.
- Convert before calculating. State the conversion step when a question gives milliamperes, kilohms, or kilohertz.
- Use `E` in Ohm's law and power examples even when an outside source uses `V` as the voltage symbol.
- Use Canadian spelling where it appears naturally in lesson prose, such as metre, colour, and licence-exempt.

### Tone

Write like a calm tutor. Do not make the learner feel foolish for a misconception. Prefer "Watch this common trap" over "Do not ever forget."

## 2. Markdown and lesson formats that render correctly

The web renderer and Apple Swift parser both support a small lesson-safe subset:

- headings using `#`, `##`, and `###`;
- paragraphs;
- simple unordered lists with `-`, with one physical line per list item;
- simple numbered lists, with one physical line per list item;
- pipe tables with a delimiter row; use leading and trailing `|` on every table row so Swift and web parse the same table;
- fenced code blocks with triple backticks; and
- the existing `## Illustration brief` block with `Alt text:` and `Description:` lines.

Do not add new syntax. Avoid raw HTML, LaTeX, footnotes, blockquotes (`>`), nested lists, task lists, definition lists, Mermaid diagrams, and images in lesson Markdown. Do not rely on bold, italics, or links to carry meaning because the renderers do not treat inline Markdown identically. Formulas must be selectable text.

Renderer details to remember: the web parser joins consecutive paragraph lines with spaces, while the Swift parser preserves paragraph newlines. Use blank lines or list items for labelled callout lines. Swift tables require leading and trailing `|` and stop when a row has a different column count; the web table parser is looser, so write tables to the stricter Swift shape.

### Front matter prerequisites

The front-matter freeze is still in force except where a task explicitly opens a field. The `prerequisites` field may name cross-module lesson IDs when a lesson genuinely relies on earlier material in the recommended order in `content/lessons/README.md`.

Rules for `prerequisites`:

- Use lesson IDs only, such as `L-005-04`; every ID must exist.
- List direct learning dependencies, not every transitive earlier lesson.
- Include cross-module dependencies when the lesson needs earlier concepts such as Ohm's law, dB, AC, impedance, 300 / f, station filtering, signal quality, or operating procedure.
- Do not list a later lesson. If a draft currently needs a later concept, define the concept locally and file or use the relevant content-fix task.
- Keep the graph acyclic. The lesson coverage checker enforces existing IDs, acyclicity, and recommended-order precedence.

### Standard headings for explanatory lessons

Use these headings when the lesson is not a reference-style rule lesson:

```text
# Lesson title

## Learning objectives

## Main concept heading

### Worked example: short real-world title

### In the real world: short title

### Memory trick: short title

### Misconception: short title

## Try it

## Radio connection

## Common mistakes

## Illustration brief

## Summary
```

Not every lesson needs every optional `###` callout. Use only what helps the objective.

### Reference-style rule modules

Module 1 regulation lessons follow the reference style in `content/lessons/README.md`. Module 2 operating lessons use the explanatory format above (owner approval 2026-10-12, TASK-46.9). They include concept sections, worked examples, Try it, common mistakes, and original concept checks. Keep the official quiz mappings intact and separate practice prompts from their feedback so learners can try before reading the answer.

For M1 reference-style lessons:

- organize the lesson around a few stated principles, introducing each `## Reference facts: ...` table with the principle it applies;
- keep single official facts in original wording and add a short `Why` column that explains a relationship, purpose or useful distinction, not an invented legal rationale;
- use `## How these rules fit together` for relationships and operating flow;
- use positive rule statements;
- avoid restating wrong answer options from the bank;
- do not include `## Try it`, worked question-and-answer examples, original practice items, or `## Common mistakes`; and
- keep lesson quiz JSON exhaustive for official question IDs and set `conceptChecks: []`.

TASK-46.8 retains M1's reference-only policy. Use the companion qualification-by-privilege matrices in L-001-02 and L-001-04 to distinguish station work, frequency access and power. The M1 numbers board in L-001-01 keeps similar values attached to their different jobs and units. A cue to cover table columns and recall the rule is allowed; it does not add a homemade regulatory question.

If a misconception needs coverage in an M1 lesson, handle it as a positive rule explanation in the relevant principle or `How these rules fit together`, not as a `Misconception` or `Common mistakes` section. Avoid naming wrong answer options from the bank.

## 3. Teaching patterns for self-study

### Worked example template

Use this exact pattern for calculations. Keep each step short.

```text
### Worked example: LED current from a USB supply

A red LED drops 2.0 V and should run near 20 mA from a 5.0 V USB supply.

- Given: source E = 5.0 V; LED drop = 2.0 V; resistor E = 3.0 V; target I = 20 mA = 0.020 A.
- Find: series resistance R.
- Formula: R = resistor E / I.
- Substitute: R = 3.0 V / 0.020 A.
- Answer: R = 150 ohms.
- Sanity check: the resistor drops the extra 3.0 V, and 150 ohms is a common value.
```

Use `Given`, `Find`, `Formula`, `Substitute`, `Answer`, and `Sanity check` in that order. If the algebra is already on the ISED reference sheet, do not invent extra algebra steps.

### Concrete-to-abstract pattern

Use this sequence when a concept is new:

1. Start with a real object: battery, lamp, fuse, coax, antenna, charger, or ferrite clamp.
2. Name the observable behaviour.
3. Introduce the circuit word.
4. Introduce the symbol or formula.
5. Return to the object and explain what the formula predicts.

Template:

```text
A fuse is a thin conductor chosen to melt before the wire overheats. That is the concrete part.
In circuit language, the fuse is in series with the load.
If current rises too high, heating rises and the fuse opens the circuit.
```

### Analogies with stated limits

Analogies are allowed only when the limit is stated near the analogy.

- Water pressure can help introduce voltage, and water flow can help introduce current.
- The limit: water can spill from a cut pipe, but current in a simple circuit needs a complete conductive path.
- A resistor can be compared to a restriction.
- The limit: a resistor does not use up electrons. It converts electrical energy into heat while current continues through the loop.

Use this format:

```text
### Analogy: water pressure and voltage

- Helpful part: pressure can push water through a pipe, like voltage can push charge through a circuit.
- Limit: a cut water pipe spills water, but a cut wire usually stops current because air is an insulator.
```

### In the real world sections

Use `### In the real world: ...` for a short practical example inside a concept section. Use `## Radio connection` near the end for the wider station link.

Format:

```text
### In the real world: ferrites on a noisy charger lead

A snap-on ferrite adds high impedance to RF current on the outside of a cable. It does not change the DC charging current in the normal power conductors.
```

### Memory trick sections

Use memory tricks sparingly. State what the trick helps remember and where it stops.

Format:

```text
### Memory trick: E over I R

- Helps remember: E = I x R, I = E / R, and R = E / I.
- Trick: put E above I and R. Cover the unknown.
- Limit: this is a memory aid, not a derivation. It applies directly to resistance in simple DC circuits.
```

Do not quote offensive historical mnemonics. For resistor colours, say that an offensive historical mnemonic exists and must never be used, without quoting it.

### Misconception callouts

Use `### Misconception: ...` in technical lessons and any non-reference operating lesson. Keep the correction factual.

Format:

```text
### Misconception: current is used up

- Mistaken idea: a lamp uses up current.
- Correction: current is the flow through the loop. The lamp converts electrical energy into light and heat.
```

Do not use this format in Module 1 reference-style lessons.

## 4. Real-world example bank

All numbers below have been recomputed for this guide. When an example depends on a rule in the Basic bank, the relevant question IDs are listed. When a practical convention is not in the bank, label it as a practical convention and do not turn it into an exam fact.

### M5: Basic electronics and theory

| Example | Writer-ready numbers | Notes and source checks |
|---|---|---|
| LED from 9 V battery | Assume red LED drop 2.0 V and target current 20 mA = 0.020 A. Resistor drop = 9.0 V - 2.0 V = 7.0 V. Ideal R = 7.0 / 0.020 = 350 ohms. E12 choices: 390 ohms gives I = 7.0 / 390 = 0.0179 A and resistor P = 7.0 x 0.0179 = 0.126 W, so a 0.25 W resistor is suitable. | Original example. Ohm's law and power checks align with B-005-004 and B-005-006 power/resistor items. |
| LED from USB 5 V | Resistor drop = 5.0 V - 2.0 V = 3.0 V. R = 3.0 / 0.020 = 150 ohms. Resistor P = 0.020 x 3.0 = 0.060 W. | Use this before the 9 V example if learners need an easier standard value. |
| Batteries in series | Four 1.5 V cells in series give 6.0 V. If each cell is 2.0 Ah, the series pack is 6.0 V at 2.0 Ah, or 12 Wh. | Bank confirms series voltage/capacity pattern in B-003-016-010. |
| Batteries in parallel | Two 6 V, 10 Ah packs in parallel give 6 V at 20 Ah. Energy = 6 V x 20 Ah = 120 Wh. | Bank confirms the parallel voltage/capacity pattern in B-003-016-009, but these numbers avoid copying that item. Add a safety caveat about matching battery type and state of charge. |
| 13.8 V, 100 W-class transceiver fuse | If the radio manual states 20 A maximum DC draw, whole-radio DC supply draw at 13.8 V is P = I x E = 20 A x 13.8 V = 276 W. Teach writers to follow the manufacturer's fuse rating, often shown on the supplied DC cable, instead of deriving a universal fuse size from RF output power. | Avoid claiming a universal 125% or 150% fuse rule unless a lesson cites a source. Add the caveat that Canada's regulatory DC-input power limit is measured at the final RF stage, not at the whole radio's DC supply input. |
| Phone charger power | 5.0 V at 2.0 A gives P = 2.0 x 5.0 = 10 W. 9.0 V at 3.0 A gives 27 W. 20.0 V at 5.0 A gives 100 W. | Good first power examples because the ratings are printed on real devices. |
| Flashlight power | A two-cell flashlight using two 1.5 V cells in series has a 3.0 V supply. If the lamp or LED module draws 0.25 A, P = 0.25 x 3.0 = 0.75 W. | Original everyday power example; do not imply all flashlights use this current. |
| Voltage divider | With R1 = 10 kilohms and R2 = 10 kilohms across 12 V, Vout = 12 x 10 / (10 + 10) = 6.0 V. Loading caveat: if a 10 kilohm load is connected across R2, the lower leg becomes 5 kilohms, so Vout = 12 x 5 / (10 + 5) = 4.0 V. | Use only after series/parallel resistance. The loading caveat prevents overconfidence. |
| kWh cost | A 100 W device is 0.100 kW. For 10 h, energy = 0.100 x 10 = 1.0 kWh. At an example rate of $0.15 per kWh, cost = $0.15. | Mark the price as an example rate, not a Canadian rule. |
| 60 Hz mains | Canadian household AC is 60 Hz. One cycle is 1 / 60 s = 0.0167 s = 16.7 ms. A half-cycle is 8.33 ms. | The Basic bank checks the meaning of 60 Hz as 60 cycles per second in B-005-007-008. Also teach that 60 Hz hum is not a harmonic emission; harmonics are multiples of the operating frequency. Originality warning: B-005-007-008's question and answer both contain the number 60, so any M5 (B-005) lesson block containing a standalone "60" fails `check:lesson-originality`. Keep the 60 Hz example out of B-005 lesson blocks (put it in M3 power-supply or M8 hum context, or use another frequency such as 400 Hz as l-005-04 does), or route it through a reviewed allowlist entry. |
| dB rules of thumb | +3 dB is about 2 x power; -3 dB is about half power; +10 dB is 10 x power; +20 dB is 100 x power. If an S-meter follows 6 dB per S-unit, one S-unit is 4 x power. | S-meter 6 dB / power factor checks: B-002-006-007 and B-002-006-008. Do not copy the 6 dB/S-unit power-factor wording directly into M2 lessons; rewrite it with original numbers or prose. |

### M4: Circuit components

| Example | Writer-ready numbers | Notes and source checks |
|---|---|---|
| Resistor colour code: 4.7 kilohms | Yellow = 4, violet = 7, red multiplier = x100, gold = 5%. Value = 47 x 100 = 4 700 ohms = 4.7 kilohms. 5% range is 4 465 to 4 935 ohms. | Bank covers the band roles in B-004-006-001 through B-004-006-003 and example colour digits in B-004-006-011. |
| Resistor colour code: 220 ohms | Red = 2, red = 2, brown multiplier = x10, gold = 5%. Value = 22 x 10 = 220 ohms. 5% range is 209 to 231 ohms. | Use real photos or original illustrations only. |
| Capacitor everyday use | A power-supply filter capacitor charges near voltage peaks and supplies current between peaks, reducing ripple. | Bank concepts: capacitors in tuned circuits B-005-012-004 and safe discharge B-003-019-009. |
| Inductor everyday use | A ferrite choke on a cable has high reactance at RF and low effect at low frequencies or DC. | Bank verifies high reactance at radio frequencies in B-005-010-007. |
| Diode reverse-polarity protection | A series diode in the positive lead conducts when polarity is correct and blocks when polarity is reversed. | Bank directly verifies the series-diode purpose in B-004-002-001. Note that a fuse handles overcurrent; a diode handles direction. |
| Transistor as relay switch | A 3.3 V control pin drives a base resistor into an NPN transistor. With a 560 ohm base resistor and about 0.7 V base-emitter drop, base current is (3.3 - 0.7) / 560 = 0.0046 A, or 4.6 mA. That can switch a 12 V relay coil if the transistor and relay ratings allow it. | Keep ratings conditional. Add a flyback diode across a DC relay coil in practical diagrams so the coil's voltage spike does not damage the transistor. Bank verifies bipolar transistors can amplify small signals at low voltages in B-004-003-001; switching is a practical extension. |
| Speaker impedance | Treating an 8 ohm speaker as a simple 8 ohm resistance, 0.5 A (RMS) gives about P = I x I x R = 0.5 x 0.5 x 8 = 2 W. Say it is an approximation: a real speaker's impedance changes with frequency and includes reactance. | Original audio-load example for impedance and power. Don't add "1" or "one" to this block: with 0.5 and 2 it would match B-005-004-001. Keep it practical; do not turn speaker impedance into an antenna-feedline match rule. |
| Wall-wart transformer | A 120 V AC primary to 12 V AC secondary is a 10:1 step-down voltage ratio. If the secondary supplies 12 V at 2 A (RMS) to a resistive load (power factor 1), output power is 24 W; for a reactive load, 12 V x 2 A is 24 VA (apparent power), not necessarily 24 W. Ideal primary current is 24 W / 120 V = 0.20 A. | Bank transformer calculations appear in B-005-011, including primary current from power and voltage. |

### M6: Feedlines and antennas

| Example | Writer-ready numbers | Notes and source checks |
|---|---|---|
| Wavelength rule | Use wavelength in metres = 300 / frequency in MHz. Commercial FM broadcast near 100 MHz has wavelength 300 / 100 = 3.0 m. At 146 MHz, wavelength is 300 / 146 = 2.05 m. At 440 MHz, wavelength is 0.682 m, or 68 cm. | Bank checks include B-006-008-003 and B-006-008-011; the 100 MHz FM example is original background. |
| 2.45 GHz wavelength | 2.45 GHz = 2 450 MHz. Wavelength = 300 / 2 450 = 0.122 m = 12.2 cm. The amateur band name is 13 cm, not 12 cm. | Corrects the research brief. Do not imply microwave ovens are amateur transmitters. |
| Dipole and half-wave length conventions | The practical shortening-factor formula is 142.5 / f(MHz), so a 146 MHz wire dipole starting point is 142.5 / 146 = 0.976 m, or 48.8 cm per leg. For bank explanations, match the convention of the covered item: B-006-012-001 and B-006-012-009 use about 143 / f for half-wave dipoles, while B-006-010-003 uses about 150 / f for a VHF half-wavelength vertical. | Cite the half-wave bank items when explaining their answers. Bank also gives the related quarter-wave below-30-MHz formula 71.3 / f in B-006-010-001. |
| 75 ohm TV coax vs 50 ohm radio coax | Teach only the practical contrast: TV/cable systems often use 75 ohm coax, while amateur transmitters and dummy loads commonly expect 50 ohms. A 50 ohm line needs a 50 ohm load for full absorption. | Bank verifies 50 ohm matching in B-006-001-006 and 50 ohm coax examples in B-006-002-005 and B-006-010-008. The reason 75 ohms is common in TV is outside the Basic bank; mark it as background if used. |
| SWR reflected power | Reflection coefficient = (SWR - 1) / (SWR + 1). At 1.5:1, reflected power is 0.2 x 0.2 = 4%. At 2:1, it is 0.333 x 0.333 = 11%. At 3:1, it is 0.5 x 0.5 = 25%. | Bank verifies SWR meaning and forward/reflected voltage in B-006-005-001 and B-006-005-009. Do not say reflected power is simply lost, and don't give one fixed fate either: what happens to it depends on the transmitter end (its matching network, tuner or protection circuits), and some is lost as heat in the feedline. Keep the lesson rule simple: a good match means less reflected power, and many solid-state transmitters reduce (fold back) output when SWR is high. |

### M3: Station assembly, practice, and safety

| Example | Writer-ready details | Notes and source checks |
|---|---|---|
| Fuse purpose | A fuse protects wiring and equipment from excessive current and heating. It is not a shock-proofing device for the operator. | Use with power supply and mobile wiring lessons. Bank safety and power-supply items include B-003-019. |
| CSA C22.1 | The Canadian Electrical Code, CSA C22.1, is a national model code; it becomes law when a province or territory adopts an edition (often with local amendments), and the local authority having jurisdiction enforces it. Say "your provincial or territorial electrical code" rather than presenting C22.1 text as uniformly binding. Do not quote code requirements unless a lesson has a verified source for the exact rule. | The task requires this Canadian note; use it as a source checkpoint, not as copied code text. |
| Safety Code 6 | Safety Code 6 gives RF exposure limits for the human body, covers controlled and uncontrolled environments, and no transmitter category is exempt from regulation. | Bank checks: B-001-024-002, B-001-024-006, B-001-024-009. |
| Microwave oven and RF exposure | A 2.45 GHz microwave has a 12.2 cm free-space wavelength. Use it to teach non-ionizing RF heating, then point to Safety Code 6 for exposure limits. | Bank checks Safety Code 6 facts above. Do not call 2.45 GHz the 12 cm amateur band; it is in the 13 cm region. |

### M7: Radio wave propagation

| Example | Writer-ready details | Notes and source checks |
|---|---|---|
| AM broadcast at night | Lower-frequency broadcast signals often travel farther at night because daytime D-region absorption is reduced after dark, while higher ionospheric regions can return signals. | Bank verifies D-region absorption in B-007-004-001, midday maximum ionization in B-007-002-006, and minimum ionization before dawn in B-007-002-007. |
| Radio horizon | Use only as a practical estimate, not as an ISED formula: radio horizon in km is about 4.12 x square root of antenna height in metres. A 1.8 m handheld horizon is 4.12 x 1.34 = 5.5 km. A 100 m repeater horizon is 4.12 x 10 = 41.2 km. Together, the path estimate is 46.7 km before terrain and clutter. | Bank verifies that VHF and higher radio horizon extends beyond visible horizon due to normal tropospheric refraction in B-007-001-004, but it does not teach this formula. Label the formula as a practical estimate. |

### M8: Interference and suppression

| Example | Writer-ready details | Notes and source checks |
|---|---|---|
| Everyday RFI and ferrites | Phone chargers, LED lamps, computers, and solar electronics can make RF noise. A ferrite choke can add high RF impedance to common-mode current on a cable while leaving intended low-frequency or DC power mostly unchanged. | Bank checks ferrite reactance in B-005-010-007 and ferrite cores for home-entertainment interference in B-008-002-001. |
| Low-pass filter misconception | A low-pass filter on an HF transmitter is for reducing harmonics above the operating frequency. Do not teach it as a general receiver static cure. | Bank checks low-pass filter placement in B-003-001-001 and B-003-001-002, and harmonics in B-008-004-002. |

### M2: Operating and procedures

| Example | Writer-ready details | Notes and source checks |
|---|---|---|
| Repeater vs simplex contact | Simplex means transmitting and receiving on the same frequency. A repeater receives on one frequency and retransmits on another. For the two-metre FM repeater offset covered by the bank, the standard difference is 600 kHz. If a repeater output is 146.940 MHz with a negative offset, the radio transmits on 146.340 MHz. | Simplex checks: B-002-003-003 and B-002-003-004. Repeater offset check: B-002-001-011. The example output frequency is illustrative; local coordination decides real channels. |
| Joining a repeater conversation | Wait for a break between transmissions and say your call sign. For distress, break in between transmissions and state your call sign and situation. | Bank checks: B-002-001-009 and B-002-008-005. Do not teach "Break Break" as a casual entry phrase. |
| RST | RST means readability, signal strength, tone. Voice reports usually use R and S, such as 59. Tone is for Morse/CW signal quality. | Bank checks: B-002-006-001, B-002-006-002, B-002-006-003, B-002-006-009. |

### M1: Regulations and policies

| Example | Writer-ready details | Notes and source checks |
|---|---|---|
| Certificate validity | The Amateur Radio Operator Certificate is valid for life. Address changes must be reported within 30 days. | Bank checks: B-001-002-002, B-001-002-001, B-001-002-003. |
| Identification interval | Identify at the beginning and end of each contact and at intervals not greater than 30 minutes. | Bank checks: B-001-013-006 and B-001-013-009. |
| Qualification and band access | Basic covers amateur bands above 30 MHz. Operation below 30 MHz also requires 80% on Basic, Advanced, or Morse. | Below-30-MHz gate check: B-001-015-003. The above-30-MHz Basic summary is recorded in `docs/exam-facts.md` from the active bank and RBR-4. |
| Power by qualification | Basic, with or without Honours or Morse: 250 W DC input to the final RF stage, 560 W PEP for SSB, and 190 W carrier power for non-SSB emissions unless the operator also has Advanced. Advanced gives 1 000 W DC input and 2 250 W PEP SSB. Honours and Morse add below-30-MHz access, not extra power. | Bank checks: B-001-017-009, B-001-017-004, B-001-017-005, B-001-017-010, B-001-017-007, B-001-017-002. This corrects the research brief: Honours does not raise the general power ceiling to Advanced levels. |
| RAC band plans | Band plans are voluntary divisions used to reduce interference between incompatible modes. | Bank checks the voluntary band-plan concept in B-002-004-010. Verify any specific frequency, calling channel, or 70 cm offset against a current RAC or local coordination source before teaching it. |

## 5. Vetted memory tricks

| Topic | Helps remember | Exact form | Source or status | Caveat |
|---|---|---|---|---|
| Ohm's law | E, I, and R formulas | Put E above I and R. Cover the unknown: E = I x R, I = E / R, R = E / I. | Traditional teaching aid; no primary attribution claimed. Formula checks align with the ISED reference sheet and B-005-004 calculations. | Works directly for resistance in simple DC or purely resistive circuits. |
| Power | P, I, and E formula | Put P above I and E: P = I x E, I = P / E, E = P / I. | Traditional teaching aid; no primary attribution claimed. Power facts align with B-005-003 and B-005-006. | In AC with reactance, apparent power and real power need care. Keep Basic examples simple. |
| Resistor colours | Digit order 0 to 9 | Black, brown, red, orange, yellow, green, blue, violet, grey, white. Optional inoffensive sentence: "Better Be Right Or Your Great Big Venture Goes Wrong." | Traditional mnemonic; no primary attribution claimed. Bank verifies band roles in B-004-006 and sample digits in B-004-006-011. | An offensive historical mnemonic exists. Never quote it. |
| Metric prefixes | Powers of 1 000 used in electronics | Giga, mega, kilo, base, milli, micro, nano, pico. A possible sentence is "Great Mighty Kings Make Micro Nano Pico." | Traditional mnemonic; no primary attribution claimed. Metric conversions are tested throughout B-005-001. | Direction matters: 1 000 mA = 1 A, not 1 000 A. |
| ITU phonetics | Clear call sign spelling | Alfa, Bravo, Charlie, Delta, Echo, Foxtrot, Golf, Hotel, India, Juliett, Kilo, Lima, Mike, November, Oscar, Papa, Quebec, Romeo, Sierra, Tango, Uniform, Victor, Whiskey, X-ray, Yankee, Zulu. | ISED Basic bank B-002-002 verifies ITU use and several words; RIC-3 is the broader Canadian amateur-service reference. | Do not invent words for formal identification. |
| Q signals | Short operating codes | QRM means interference; QRN means static; QTH means location; QSY means change frequency; QRZ? asks who is calling. | ISED Basic bank B-002-007 checks the listed Q signals. | Do not over-teach codes outside the Basic bank in lesson prose. |
| RST | Signal report order | Readability, signal strength, tone. | ISED Basic bank B-002-006-001 and B-002-006-002. | Tone is for CW/Morse quality, not ordinary voice reports. |
| Wavelength | Metres from MHz | Wavelength in metres = 300 / f in MHz. Anchor: 100 MHz is 3 m. | ISED Basic bank checks wavelength examples in B-006-008; the 100 MHz anchor avoids copying a bank item. | Physical antennas need shortening or design factors. |
| Ionosphere layers | D-region daytime absorption | D can stand for daytime and dampening lower-frequency HF. | Traditional mnemonic; no primary attribution claimed. Bank verifies D-region absorption in B-007-004-001. | Do not say the D region is useful for long-distance reflection. |
| ELI the ICE man | AC phase in ideal L and C | In an inductor L, E leads I: E-L-I. In a capacitor C, I leads E: I-C-E. | Traditional mnemonic; no primary attribution claimed. | Use only if the lesson actually teaches AC phase. The Basic bank emphasizes reactance trends more than phase mnemonics. |
| Product over sum | Two parallel resistors | For two resistors only: Rtotal = (R1 x R2) / (R1 + R2). | Traditional circuit shortcut; no primary attribution claimed. Bank checks parallel resistance concepts in B-005-005. | For three or more resistors, use reciprocal method or combine pairs carefully. |

Do not attribute common mnemonics to IEEE, ARRL, NEETS, or any other source unless the exact source has been verified.

## 6. Common misconceptions to address

| Module | Positive rule or concept to reinforce | Source check |
|---|---|---|
| M1 | Basic, Basic with Honours, and Basic plus Morse share the Basic power limits; Honours and Morse add below-30-MHz access, not Advanced power. | Basic and Advanced power checks: B-001-017-009, B-001-017-004, B-001-017-010, B-001-017-007, B-001-017-002. Below-30-MHz gate: B-001-015-003. |
| M1 | The Canadian Amateur Radio Operator Certificate is valid for life, and address changes must still be reported within 30 days. | B-001-002-002, B-001-002-001, and B-001-002-003. |
| M1 | RAC band plans are voluntary operating plans; legal limits come from ISED rules. | The voluntary band-plan concept is checked in B-002-004-010. |
| M2 | To join an ordinary repeater conversation, wait for a break and say your call sign; for distress, break in and state your call sign and situation. | B-002-001-009 and B-002-008-005. |
| M2 | Voice signal reports normally use readability and strength; tone is part of the RST system for CW/Morse quality. | B-002-006-002, B-002-006-003, and B-002-006-009. |
| M3 | A fuse protects a person from any electric shock. | Incorrect. Teach fuses as overcurrent protection for wiring and equipment. Use separate RF exposure and electrical safety guidance for people. |
| M3 | Safety Code 6 names one safe antenna power for every handheld. | Incorrect. The bank says a maximum safe output to a hand-held VHF/UHF antenna is not specified: B-001-024-005. |
| M4 | A diode is a current limiter. | Incorrect. A diode is direction-selective. A series diode in the positive lead is for reverse polarity protection: B-004-002-001. |
| M4 | A capacitor is just a small battery. | Incomplete. Capacitors store energy in an electric field and can charge and discharge quickly; batteries store energy chemically. Keep this as plain contrast, not an exam quote. |
| M5 | Current is used up by a lamp or resistor. | Incorrect. Energy is converted; current flows through the loop. Use hot-resistor power examples tied to B-005-003-009. |
| M5 | Doubling voltage only doubles resistor heating. | Incorrect for fixed resistance. The bank checks that doubling voltage across series resistors increases total power four times: B-005-006-006. |
| M6 | High SWR means extra power is being radiated. | Incorrect. SWR indicates mismatch and reflected voltage. Bank checks 1:1 as best match and forward/reflected voltage measurement: B-006-005-001 and B-006-005-009. |
| M6 | An antenna tuner at the radio changes the physical antenna length. | Incorrect. It transforms the impedance seen by the transmitter. Bank checks tuner use with mismatched antennas in B-006-006-010. |
| M7 | More power makes VHF bend around Earth like HF. | Incorrect. VHF and higher are strongly tied to line of sight and tropospheric effects. Bank checks radio horizon extension from tropospheric refraction in B-007-001-004. |
| M7 | The D region is the layer that returns low-frequency HF for distance in daylight. | Incorrect. The D region absorbs lower-frequency HF waves in daytime: B-007-004-001. |
| M8 | Ferrites reduce the wanted signal inside coax. | Overstated. A ferrite choke is usually used to impede unwanted common-mode RF current on cable exteriors or leads. Bank checks ferrite high RF reactance in B-005-010-007. |
| M8 | A low-pass filter on a receiver is the main cure for static. | Incorrect for the Basic transmitter-interference context. Low-pass filters belong near transmitter or amplifier outputs to reduce harmonics: B-003-001-001, B-003-001-002, B-008-004-002. |

## 7. Canadian accuracy notes

- Identification: teach beginning, end, and intervals not greater than 30 minutes. Cite B-001-013-006 and B-001-013-009.
- Certificate validity: valid for life; address changes must be reported within 30 days. Cite B-001-002-002, B-001-002-001, and B-001-002-003.
- Basic band access: Basic gives amateur bands above 30 MHz according to `docs/exam-facts.md`; below 30 MHz also needs 80% on Basic, Advanced, or Morse. Cite B-001-015-003 for the below-30-MHz gate and the privilege rows in `docs/exam-facts.md` for the above-30-MHz summary.
- Power: Basic, with or without Honours or Morse, is 250 W DC input to the final RF stage, 560 W PEP for SSB, and 190 W carrier power for non-SSB emissions unless the operator also has Advanced. Advanced is 1 000 W DC input and 2 250 W PEP SSB. Honours and Morse add below-30-MHz access, not extra power. Cite B-001-017-009, B-001-017-004, B-001-017-005, B-001-017-010, B-001-017-007, and B-001-017-002. Remind writers that the DC-input limit applies to the final RF stage, not the whole radio's supply draw.
- Band plans: the bank defines band plans as voluntary divisions to avoid interference. Cite B-002-004-010. Verify specific calling frequencies, repeater channels, and 70 cm offsets against current RAC or local coordinator material before teaching them as facts.
- 60 Hz: use it as Canadian/North American mains context and cite B-005-007-008 for 60 cycles per second (keep it out of B-005 lesson blocks; see the originality warning in the example bank). Do not call 60 Hz hum a harmonic emission; harmonics are unwanted emissions at multiples of the operating frequency, checked by B-008-004-002.
- Safety Code 6: Health Canada publishes RF exposure limits. It covers controlled and uncontrolled environments, and no transmitters are exempt. Cite B-001-024-001, B-001-024-002, B-001-024-006, and B-001-024-009.
- CSA C22.1: this is not tested in the Basic question bank and is not summarized in `docs/exam-facts.md`. If a lesson needs Canadian Electrical Code details, verify the exact CSA C22.1 claim from an approved source before using it; do not copy code text or invent section-level requirements.
- 2.45 GHz: wavelength is 12.2 cm, and the amateur band name in that region is 13 cm. Do not call it the 12 cm band.
- 146.520 MHz: do not teach it as an exam-bank fact. If a lesson needs a national or local calling frequency, verify it against a current RAC band plan or local coordination source and say it is a band-plan convention.
- 70 cm repeater offsets: the Basic bank verifies the two-metre 600 kHz offset, not a general 70 cm offset. Verify any 70 cm example before use.

## 8. Originality and source use

Lesson prose must be original. Do not copy ISED reference material, RAC pages, commercial study guides, web articles, or this research brief.

Allowed:

- cite official question IDs and subsection IDs;
- state single official facts in reference-style tables where the lesson format allows it;
- write original explanations and examples around those facts;
- use common formulas and standard circuit laws; and
- use short, common mnemonics when they are not offensive and not falsely attributed.

Not allowed:

- pasting ISED question or answer text into lesson bodies beyond the narrow allowances in `content/lessons/README.md`;
- copying third-party study-guide paragraphs;
- creating concept checks that restate official question text and answer text;
- quoting offensive mnemonics for historical colour-code teaching; or
- adding unverified Canadian regulatory claims from memory.

When the bank is silent, either cite a verified external source in task notes or mark the point as practical background instead of an exam fact. If the claim is not needed, drop it.

## 9. How to revise a lesson

Use this checklist for tasks 39.2 through 39.5.

1. Read the lesson front matter and keep `type`, `id`, `moduleId`, `categoryIds`, `title`, `covers`, `objectives`, `prerequisites`, `estimatedMinutes`, `quizIds`, and `status` intact unless the task explicitly says otherwise. When a task does open `prerequisites`, follow the front-matter prerequisite rules above and keep every prerequisite earlier than the lesson in the recommended order.
2. Keep coverage IDs unchanged unless a coordinator approves a coverage move.
3. Keep quiz references unchanged. Do not edit quiz JSON unless the task says to revise quizzes.
4. Keep the `## Illustration brief` heading and both `Alt text:` and `Description:` lines. Improve them only if the lesson change requires it.
5. Check whether the lesson is reference-style. M1 remains reference-style; M2 uses the explanatory format under TASK-46.9. Do not add Try-its, worked Q&A, original practice items, or Common mistakes to M1 lessons.
6. Replace abstract paragraphs with concrete-to-abstract teaching where it helps.
7. Add worked examples only where the lesson teaches calculations or practical sizing.
8. Add memory tricks only from the vetted table or after verifying the trick and its limits.
9. Add misconception callouts only to non-reference lessons.
10. Recompute every number. Show unit conversions.
11. Verify Canadian regulatory facts against `questions.json`, `docs/exam-facts.md`, or a cited official/current source.
12. Preserve originality. Do not copy source prose.
13. Run the relevant checks from the repository root:
    - `node packages/content-tools/src/check-lesson-coverage.ts`
    - `pnpm --dir packages/content-tools check:quizzes`
    - `pnpm --dir packages/content-tools check:explanations`
    - `pnpm --dir packages/content-tools check:lesson-originality:all`
    - `pnpm check:links`
    - `pnpm test`
    - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path packages/content-swift` (run from the repository root; `xcode-select` on the build host points at the Command Line Tools)
14. If a task changes TypeScript or renderer behaviour, also run `pnpm typecheck`. Lesson-text-only changes usually do not require Apple app builds, but they still need the Swift package test above because it parses real lesson Markdown.
15. Watch pinned lesson tests: web tests assert content from `L-005-01` and `L-006-03`, while Swift `ContentLibraryTests` assert block order, table data, and illustration-brief parsing for real lessons including `L-005-01` and every lesson file.
16. Record in Backlog notes which regulatory and numeric claims were checked and which were dropped.

## 10. Sources used for this guide

Repository sources:

- `content/generated/basic-2025-07-15/questions.json`, active ISED Basic 2025-07-15 question bank imported in this repository.
- [docs/exam-facts.md](exam-facts.md), especially the exam rules and privileges tables that record coordinator verification against RBR-4, RIC-1, RIC-3, RAC Basic requirements, and the active ISED bank.
- [content/lessons/README.md](../content/lessons/README.md), especially reference-style and originality rules.
- [docs/design.md](design.md), lesson-page and accessibility-related design constraints.
- [docs/accessibility.md](accessibility.md), especially formulas as text, diagram captions and alt text, text zoom, and colour-independent state.
- `apps/web/src/components/MarkdownContent.tsx`, current web lesson Markdown renderer.
- `packages/content-swift/Sources/CanadianHamContent/MarkdownLessonContent.swift`, current Swift lesson Markdown parser.

Primary references to use when lesson writers need to verify claims beyond the bank:

- ISED RBR-4, Standards for the Operation of Radio Stations in the Amateur Radio Service: <https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service>.
- ISED RIC-3, Information on the Amateur Radio Service: <https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-3-information-amateur-radio-service>.
- Health Canada Safety Code 6: <https://www.canada.ca/en/health-canada/services/publications/health-risks-safety/limits-human-exposure-radiofrequency-electromagnetic-energy-range-3-300.html>.
- RAC 2 m band plan page for voluntary operating-plan details: <https://www.rac.ca/144-mhz-2m-page/>. Use current RAC or local frequency-coordination material for specific calling frequencies, repeater channels, and offsets.
