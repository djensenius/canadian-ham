---
id: TASK-39.2
title: 'Lesson text revision: M5 basic electronics and M4 components'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 22:14'
updated_date: '2026-10-10 23:35'
labels:
  - content
dependencies:
  - TASK-39.1
parent_task_id: TASK-39
priority: medium
ordinal: 85000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Revise all lessons in m5-basic-electronics and m4-circuit-components to the teaching guide. These need the richest practical examples (LED circuits with a series resistor, voltage dividers, batteries in series/parallel, fuses, power supplies, diodes/transistors in everyday devices, resistor colour code tricks). Coordinate with task-38.1, which edits l-005-02's figure reference.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every lesson in scope is revised to docs/teaching-guide.md: plain language (terms defined at first use, short sentences, active voice), with a technical-accuracy pass
- [x] #2 Each technical lesson gains at least one 'In the real world' example tied to everyday or station hardware, with worked numbers where useful (rule-reference lessons follow the reference-style rules in content/lessons/README.md)
- [x] #3 Memory tricks from the guide are added where they help, are accurate and inoffensive, and say what they help remember
- [x] #4 Coverage, quiz, explanation, originality and link checks pass; lesson IDs, front matter coverage and quiz references are unchanged; Illustration brief sections are left intact for task-38
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Address every r1 finding in the scoped lesson prose while preserving front matter, coverage, quiz IDs, and Illustration brief sections.
2. Run a real readability pass over all 8 existing lessons: split long sentences, define E12/Ah/Wh/bleeder resistors and unclear terms, remove premature or duplicate callouts, and keep examples original.
3. Rerun the full required content/test command set, compare front matter/Illustration briefs against merge-base, record finding-by-finding notes, then set Done last.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
M5 pass: revised L-005-01 through L-005-05. Added prefix, Ohm/power and meter memory aids; phone-charger, LED, fuse, battery series/parallel, loaded divider, capacitor filter, ferrite choke, wall-wart transformer, resonance and meter examples. Numeric facts checked against B-005-001 through B-005-013 and teaching-guide example bank; no regulatory facts added. Required checks after M5 all passed.

M4 pass: revised L-004-01 through L-004-03. Added diode symbol/protection memory aid, USB and 9 V LED resistor examples with E12/power checks, NPN/terminal memory aids, transistor relay switch with flyback diode, tube safety context, and resistor colour-code mnemonic/examples including 4.7 kilohm and 220 ohm tolerance ranges. Facts checked against B-004-001 through B-004-006 and teaching-guide example bank; no regulatory facts added. Required checks after M4 all passed.

Final validation: coverage, quiz, explanation, originality, link, TZ=UTC pnpm test, and Swift content package tests all passed after M5 and again after M4/final. Script comparison against merge-base confirmed all 8 scoped lesson front matter blocks and Illustration brief sections are unchanged. Pinned L-005-01 tests still pass without expected-value updates.

Reviving for review r1 fixes: set task back to In Progress before edits. Will fix all Must fix, Should fix, and Minor notes unless explicitly answered in notes.

Review r1 fixes:
- Must 1 fixed: L-005-02 fuse example now distinguishes whole-radio DC supply connector power (276 W) from the Basic regulatory DC input limit at the transmitter final RF stage; radio-connection wording now says DC supply power, not loose DC input power.
- Must 2 fixed: L-005-03 Try it now states the resistor count with a solvable originality-safe series example: three 18 ohm resistors across 8.1 V.
- Must 3 fixed: L-005-02 now introduces LED forward voltage drop and the need for a series resistor, then works a USB 5.0 V LED example before the 9 V battery example; E12 is defined.
- Should 4 fixed: real readability pass across all 8 lessons split long sentences and clarified existing prose; E12, Ah, Wh, and bleeder resistor are defined.
- Should 5 fixed: removed ELI the ICE man from L-005-04 because the lesson does not teach L/C phase relationships.
- Should 6 fixed: product-over-sum now shows Rt = (R1 x R2) / (R1 + R2) and includes an unequal 330/470 ohm worked example.
- Should 7 fixed: equal-pair parallel example now uses Formula: Rt = R / 2; I = E / Rt.
- Should 8 fixed: prefix memory trick now matches the table and omits nano.
- Minor notes fixed: conductance wording clarified; L-005-03 uses output E instead of Vout and explains battery series/parallel directly; L-005-05 turns-ratio direction and wall-wart VA/loss caveats revised; LED resistor power rounded consistently; repeated offensive-mnemonic warning reduced; duplicate misconception/common-mistake repeats removed or reworded; M4 and L-005-03 Try it sections are numbered.
- Validation: final full run passed coverage, quizzes, lesson originality all, explanations, check:links, TZ=UTC pnpm test, and Swift content package tests. An interim Swift run failed after splitting the L-005-01 intro into a new paragraph; I restored the asserted block structure without weakening tests, and the final Swift run passed. Front matter and Illustration brief sections were script-compared against merge-base and remained unchanged.

Reviving for review r2 fixes: set task back to In Progress. Will fix prefix-ladder skip rule, restore L-004-02 misconception callouts without duplicate Common-mistakes bullets, align turns-ratio wording, fix partial/new low notes, run taught-facts self-check for every lesson changed, and report the frozen L-005-01 Illustration brief ladder-arrow issue as a task-38 follow-up.

Review r2 fixes:
- Prefix ladder fixed: L-005-01 now states that the table skips nano, so micro to pico is a jump of 1 000 000 rather than a 1 000 step. Frozen Illustration brief follow-up for task-38: L-005-01 Illustration brief still describes every ladder arrow as "multiply/divide by 1 000" while the brief omits nano; I did not edit the brief per task-39.2/task-38 rules.
- L-004-02 misconception callouts restored: saturation and FET-gate misconceptions are back as `### Misconception:` sections; duplicate Common-mistakes bullets were removed instead.
- L-005-05 turns-ratio direction fixed: the step-up example now names primary-to-secondary ratio 1:4 and uses secondary-to-primary voltage ratio = 4 in the current calculation.
- Other r2/low notes fixed: L-005-03 formula now says I = E / Rt; L-005-02 explicitly says why the LED series resistor is needed; L-004-01 LED examples now use the same 2.1 V red-LED drop as L-005-02 and are recomputed.

Taught-facts self-check for changed lessons: checked each listed correct answer from `questions.json` against the revised lesson and merge-base lesson intent; all merge-base exam-relevant facts remain taught, with rewording only and no deleted/weak facts.
- L-004-01 covers B-004-001/B-004-002. Correct-answer list checked: B-004-001-001=Amplifier; B-004-001-002=become distorted; B-004-001-003=an RF amplifier; B-004-001-004=an audio amplifier; B-004-001-005=300 Hz to 3 000 Hz; B-004-001-006=Voltage; B-004-001-007=gain; B-004-001-008=amplification; B-004-001-009=amplifier; B-004-001-010=Efficiency; B-004-001-011=Oscillations appear; B-004-002-001=Reverse polarity protection; B-004-002-002=detection; B-004-002-003=regulate or maintain a constant voltage; B-004-002-004=rectification; B-004-002-005=anode and cathode; B-004-002-006=Pulsating direct current; B-004-002-007=cathode to anode; B-004-002-008=A light-emitting diode; B-004-002-009=It conducts in one direction only; B-004-002-010=forward biased. Result: retained amplifier/gain/RF/audio/linearity/efficiency/feedback facts and diode rectification/detection/Zener/LED/anode-cathode/forward-bias/reverse-polarity facts.
- L-004-02 covers B-004-003/B-004-004/B-004-005. Correct-answer list checked: B-004-003-001=Bipolar transistor; B-004-003-002=Transistor; B-004-003-003=Collector, emitter and base; B-004-003-004=Amplification; B-004-003-005=The polarities are reversed; B-004-003-006=Bipolar transistor; B-004-003-007=NPN and PNP; B-004-003-008=Excessive heat; B-004-003-009=Base; B-004-003-010=Base; B-004-003-011=A switch; B-004-004-001=N channel and P channel; B-004-004-002=Field-effect transistor; B-004-004-003=Gate; B-004-004-004=Source; B-004-004-005=Drain; B-004-004-006=The gate never conducts current; B-004-004-007=Gate; B-004-004-008=The reverse bias is decreased; B-004-004-009=Emitter; B-004-004-010=Collector; B-004-004-011=Source and drain; B-004-005-001=It may be able to handle higher power; B-004-005-002=Cathode and plate; B-004-005-003=can amplify signals; B-004-005-004=Plate; B-004-005-005=Field-effect transistor; B-004-005-006=Grid; B-004-005-007=Cathode; B-004-005-008=A vacuum; B-004-005-009=Triode. Result: retained bipolar transistor terminals/control/polarity/amplification/switching/heat facts, FET channel/gate/source/drain/high-impedance/control facts, and triode cathode/grid/plate/vacuum/high-power/amplification facts.
- L-005-01 covers B-005-001/B-005-002. Correct-answer list checked: B-005-001-001=3 525 kHz; B-005-001-002=3 amperes; B-005-001-003=1 000 Hz; B-005-001-004=1 microfarad; B-005-001-005=0.5 watts; B-005-001-006=1000 ohms; B-005-001-007=7.040 MHz; B-005-001-008=250 milliamperes; B-005-001-009=2 000 mV; B-005-001-010=Divide by 1 000; B-005-001-011=10 millihenries; B-005-002-001=Gold, silver and aluminum; B-005-002-002=Glass, air and porcelain; B-005-002-003=Current; B-005-002-004=Copper; B-005-002-005=Conductor; B-005-002-006=Low resistance; B-005-002-007=resistance; B-005-002-008=Conductance; B-005-002-009=The loss of voltage caused by the flow of current through a circuit; B-005-002-010=temperature; B-005-002-011=Polarity. Result: retained all prefix conversions including microfarad/picofarad, conductor/insulator examples, current/resistance/conductance/voltage-drop/temperature/polarity facts.
- L-005-02 covers B-005-003/B-005-004. Correct-answer list checked: B-005-003-001=Power; B-005-003-002=The 100-watt bulb; B-005-003-003=The watt; B-005-003-004=An open circuit; B-005-003-005=A short circuit; B-005-003-006=watts; B-005-003-007=Voltage and current; B-005-003-008=Volts and amperes; B-005-003-009=power; B-005-003-010=The circuit is a closed circuit; B-005-003-011=A short circuit; B-005-004-001=1.0 volts; B-005-004-002=Current equals voltage divided by resistance; B-005-004-003=Resistance equals voltage divided by current; B-005-004-004=Voltage equals current multiplied by resistance; B-005-004-005=48 ohms; B-005-004-006=900 ohms; B-005-004-007=22 volts; B-005-004-008=0.2 amperes; B-005-004-009=5 volts; B-005-004-010=R = E / I; B-005-004-011=10 ohms. Result: retained power/watt/open-closed-short/continuity facts and all Ohm's-law forms/calculation skills.
- L-005-03 covers B-005-005/B-005-006. Correct-answer list checked: B-005-005-001=It equals the sum of the branch current through each resistor; B-005-005-002=480 mA; B-005-005-003=It is less than the smallest resistor; B-005-005-004=24 milliamperes; B-005-005-005=greater than the resistance of any one resistor; B-005-005-006=50 ohms; B-005-005-007=Five 24-ohm resistors; B-005-005-008=R / 10; B-005-005-009=17 ohms; B-005-005-010="A" has half the resistance of "B"; B-005-005-011=sum of the currents through all the parallel branches; B-005-006-001=For greater power dissipation; B-005-006-002=60 watts; B-005-006-003=6 watts; B-005-006-004=2 watts; B-005-006-005=2 watts; B-005-006-006=Increase four times; B-005-006-007=Four 2-watt 200-ohm resistors in parallel; B-005-006-008=2.5 amperes; B-005-006-009=5 watts; B-005-006-010=Same resistance but greater power rating; B-005-006-011=determined by heat dissipation qualities. Result: retained series/parallel resistance, branch-current summing, equal-parallel shortcut, lower branch resistance/higher current, power-rating/heat, transformer/supply power, and voltage-doubling power facts.
- L-005-05 covers B-005-011/B-005-012/B-005-013. Correct-answer list checked: B-005-011-001=2.1 amperes; B-005-011-002=By carrying different voltages and currents in each winding; B-005-011-003=5 amperes; B-005-011-004=240 V; B-005-011-005=directly proportional to the current in the conductor; B-005-011-006=current is going through its greatest rate of change; B-005-011-007=2 amperes; B-005-011-008=250 mA; B-005-011-009=When the wires are close and parallel; B-005-011-010=steel; B-005-011-011=Warm iron laminations; B-005-012-001=inductive reactance and capacitive reactance are equal; B-005-012-002=High impedance; B-005-012-003=Bandwidth; B-005-012-004=Inductor and capacitor; B-005-012-005=resonant frequency; B-005-012-006=high impedance; B-005-012-007=low impedance; B-005-012-008=add a resistor to the circuit; B-005-012-009=select the desired signal frequencies; B-005-012-010=inductive reactance and capacitive reactance are equal and opposite in sign; B-005-012-011=It reaches maximum; B-005-013-001=In parallel with the circuit; B-005-013-002=In series with the circuit; B-005-013-003=Voltage, current and resistance; B-005-013-004=An ammeter; B-005-013-005=A high value resistance; B-005-013-006=A low value resistance; B-005-013-007=RF wattmeter; B-005-013-008=a voltmeter; B-005-013-009=Ammeter; B-005-013-010=Accuracy. Result: retained transformer ideal power/turns/current/magnetic-coupling/core-loss facts, resonance/series/parallel/bandwidth/selectivity facts, and meter selection/series-parallel/high-low-resistance/accuracy facts.

Validation after r2 fixes: content checks passed (coverage, quizzes, lesson-originality all, explanations, links). First full run and first TZ=UTC pnpm test rerun hit unrelated web timing failures in different App.test.tsx cases; reran the required `TZ=UTC pnpm test` unchanged and it passed. Swift content package test with DEVELOPER_DIR and --package-path passed. Script comparison confirmed front matter and Illustration brief sections unchanged for all 8 scoped lessons.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Addressed review r2 on task-39.2: fixed the prefix-ladder skip rule, restored L-004-02 misconception callouts while removing duplicate bullets, made the transformer turns-ratio direction consistent, fixed the remaining formula/LED consistency/series-resistor notes, and recorded the frozen L-005-01 Illustration brief ladder issue for task-38 follow-up. Performed taught-facts self-check for every changed lesson against questions.json correct answers and confirmed no merge-base exam-relevant facts were dropped or weakened. Verified with coverage, quizzes, lesson-originality all, explanations, link check, TZ=UTC pnpm test, Swift content package tests, and front-matter/Illustration-brief comparison.
<!-- SECTION:FINAL_SUMMARY:END -->
