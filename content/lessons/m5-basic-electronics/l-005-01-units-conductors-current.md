---
type: lesson
id: L-005-01
moduleId: M5
categoryIds:
  - B-005
title:
  en: "Units, conductors, and current"
  fr: null
covers:
  - B-005-001
  - B-005-002
objectives:
  - "Convert between common radio units and prefixes."
  - "Distinguish conductive and insulating materials."
  - "Relate electric charge flow to current in a circuit."
prerequisites: []
estimatedMinutes: 30
quizIds:
  - QZ-L-005-01-A
status: draft
---
# Units, conductors, and current

Radio starts with a few simple measurements. A receiver dial, a power supply label, a capacitor value, and a battery current reading all use metric prefixes. A prefix moves the decimal point by a known amount.

Do not try to memorize every possible conversion as a separate fact. Learn the common prefixes, keep the unit attached to the number, and ask whether the answer should become larger or smaller when you change units.

## Learning objectives

By the end of this lesson, you can:

- convert between hertz, kilohertz, megahertz, and gigahertz;
- convert between amperes, milliamperes, volts, millivolts, watts, milliwatts, ohms, kilohms, farads, picofarads, henries, microhenries, and millihenries;
- identify common conductors and insulators;
- describe current as electric charge moving through a complete path; and
- explain why resistance, conductance, voltage drop, temperature, and DC polarity matter in simple circuits.

## The metric prefix ladder

A prefix tells you how many base units are being counted. In Basic exam electronics, the most common prefixes are these:

| Prefix | Symbol | Meaning | Example |
|---|---:|---:|---|
| giga | G | 1 000 000 000 times the base unit | 4 GHz = 4 000 MHz |
| mega | M | 1 000 000 times the base unit | 7 MHz = 7 000 kHz |
| kilo | k | 1 000 times the base unit | 2.5 kHz = 2 500 Hz |
| base unit | none | a whole unit | ampere is the base current unit |
| milli | m | a thousandth | 0.37 A = 370 mA |
| micro | µ | a millionth | 4 mH = 4 000 µH |
| pico | p | a trillionth | 0.47 µF = 470 000 pF |

When you change from a large unit to a smaller unit, the number gets larger. When you change from a small unit to a larger unit, the number gets smaller.

### Memory trick: prefix ladder

- Helps remember: the usual electronics prefix order from large to small.
- Trick: giga, mega, kilo, base, milli, micro, nano, pico can be remembered as "Great Mighty Kings Make Micro Nano Pico."
- Limit: the sentence skips the base unit and still has several M words, so use it with the table rather than by itself. This lesson's table skips nano; most adjacent rows differ by 1 000, but micro to pico is a jump of 1 000 000 when nano is not shown.

### Worked example: MHz to kHz

A frequency is 14.230 MHz.

- Given: frequency = 14.230 MHz; mega is 1 000 times kilo.
- Find: the frequency in kilohertz.
- Formula: kHz = MHz x 1 000.
- Substitute: 14.230 x 1 000 = 14 230.
- Answer: 14.230 MHz = 14 230 kHz.
- Sanity check: kilohertz is the smaller unit, so the number is larger.

### Worked example: mA to A

A receiver accessory draws 450 mA.

- Given: current = 450 mA; milli means a thousandth of the base unit.
- Find: current in amperes.
- Formula: amperes = milliamperes / 1 000.
- Substitute: 450 / 1 000 = 0.45.
- Answer: 450 mA = 0.45 A.
- Sanity check: amperes are larger units, so the number is smaller.

### Worked example: pF to µF

A small bypass capacitor is marked 470 000 pF.

- Given: capacitance = 470 000 pF; a microfarad contains a million picofarads.
- Find: capacitance in microfarads.
- Formula: µF = pF / 1 000 000.
- Substitute: 470 000 / 1 000 000 = 0.47.
- Answer: 470 000 pF = 0.47 µF.
- Sanity check: picofarads are tiny, so the number is much smaller in microfarads.

### In the real world: reading a charger label

A phone charger may say 9.0 V at 3.0 A. The volts tell the electrical pressure. The amperes tell the current the charger can supply under that rating.

The same label might also list watts. If it says 27 W, that matches P = I x E because 3.0 A x 9.0 V = 27 W. You will use that power formula in the next lesson.

### Analogy: electrical pressure and voltage

- Helpful part: pressure can push water through a pipe, like voltage can push charge through a circuit.
- Limit: a cut water pipe can spill water, but a broken wire usually stops current because air is an insulator.

## Conductors, insulators, and semiconductors

A conductor lets electric charge move easily. Silver, copper, gold, and aluminum are all good conductors. Copper conducts better than aluminum, and it is common in radio gear, power cables, and house wiring because it conducts well and is practical to use.

An insulator resists current flow. Glass, air, porcelain, many plastics, Teflon, mica, and dry wood are common insulating materials. Insulators hold conductors apart so current goes where the circuit designer intended.

A semiconductor is between those two behaviours. Silicon is the everyday semiconductor example. Carbon conducts, but much worse than good metals. That is why carbon can be useful in resistive materials, but it is neither a good conductor nor a good insulator.

### In the real world: a coax cable cross-section

A coaxial cable is a good parts lesson in one object. The centre conductor carries signal current. Plastic insulation keeps it from touching the shield. The shield provides a return path and helps keep unwanted fields out.

If the centre conductor touches the shield, the cable can become a short circuit. If the centre conductor breaks, the cable can become an open circuit. The conductor and insulator jobs both matter.

## Current, resistance, and conductance

Current is charge moving through a complete circuit path. The symbol for current is I, and the unit is the ampere, abbreviated A.

Resistance is opposition to current flow. Its symbol is R, and its unit is the ohm. Low resistance means current can flow easily. High resistance means current has a harder path.

Conductance is the inverse of resistance. It describes how easily current can flow. If resistance is high, conductance is low. If resistance is low, conductance is high.

### Misconception: current can cross any gap

- Mistaken idea: current can keep flowing through a simple broken wire because voltage is still present.
- Correction: current in an ordinary low-voltage circuit needs a complete conductive path. Air is normally an insulator.

## Voltage drop and polarity

Voltage is electrical pressure or potential difference. When current flows through a resistance, some voltage appears across that resistance. That is a voltage drop.

In a DC circuit, polarity names the positive and negative direction of the connection. Many radio accessories care about polarity. Reversing DC polarity can damage equipment.

Temperature can change the resistance of a conductor. In many metal conductors, resistance rises as the conductor gets hotter. That is one reason hot wires and hot resistors deserve attention.

## Try it

Do these in your head before checking the answer.

1. A trail radio beacon produces 750 mW. Since milli means a thousandth, 750 mW is 0.75 W.
2. A resistor is marked 4.7 kilohms. Kilo means 1 000, so 4.7 kilohms is 4 700 ohms.
3. A frequency is 21 375 kHz. Divide by 1 000 to get megahertz: 21.375 MHz.
4. A current is 0.18 A. An ampere is 1 000 mA, so 0.18 A is 180 mA.
5. A supply is 13.8 V. Each volt is 1 000 mV, so 13.8 V is 13 800 mV.

## Radio connection

A real station uses these conversions all the time. HF frequencies may be written as 14.230 MHz in a logging program and as 14 230 kHz in a band plan. A handheld may advertise 750 mW on low power, which is 0.75 W. A small accessory may draw 180 mA, which is 0.18 A from the battery.

Conductors and insulators are just as practical. Coaxial cable works because each layer has a job. The centre conductor carries RF current. The insulator keeps it separated from the shield. The shield provides the return path and shielding.

If the insulator fails or a conductor touches where it should not, the circuit behaviour changes immediately.

## Common mistakes

- Moving the decimal point the wrong way. Ask: am I changing to a smaller unit or a larger unit?
- Forgetting that milli means one thousandth, not one millionth.
- Treating good conductors and good insulators as opposite lists but then mixing in semiconductors such as silicon.
- Thinking current can flow through an open path. Current needs a complete circuit.
- Confusing polarity with antenna polarization. Polarity is about positive and negative direction in a DC circuit; polarization is used later for radio waves and antennas.

## Illustration brief

Alt text: A horizontal metric-prefix ladder from giga to pico, with arrows showing when to multiply or divide by 1 000.

Description: Draw a simple ink-brush ladder with labelled steps: G, M, k, base, m, µ, p. Add a small radio dial labelled 14.230 MHz beside the MHz step and 14 230 kHz beside the kHz step. Use arrows that say "multiply by 1 000" when moving toward smaller units and "divide by 1 000" when moving toward larger units.

## Summary

- Metric prefixes are powers of 1 000 for the values used here.
- Large-to-small unit conversions make the number larger; small-to-large conversions make it smaller.
- Current is moving electric charge, measured in amperes.
- Resistance opposes current; conductance is its inverse.
- Conductors such as copper allow current flow; insulators such as glass, air, and porcelain resist it.
- DC polarity matters because many circuits are designed for a specific direction of connection.
