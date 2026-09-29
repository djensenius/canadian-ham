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

Radio starts with a few simple measurements. A receiver dial, a power supply label, a capacitor value, and a battery current reading all use the same metric-prefix idea: a prefix moves the decimal point by a known amount.

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

### Worked example: MHz to kHz

A frequency is 14.230 MHz. Mega is the next larger prefix above kilo, and each step here is a factor of 1 000.

- Mega to kilo is a single prefix step, so multiply the MHz value by 1 000.
- 14.230 MHz = 14.230 x 1 000 kHz.
- 14.230 x 1 000 = 14 230.

So 14.230 MHz is 14 230 kHz.

### Worked example: mA to A

A receiver accessory draws 450 mA. Milli means a thousandth of an ampere.

- Milli is a thousandth of the base unit.
- To convert milliamperes to amperes, divide by 1 000.
- 450 mA / 1 000 = 0.45 A.

So 450 mA is 0.45 amperes.

### Worked example: pF to µF

A small bypass capacitor is marked 470 000 pF. Pico is much smaller than micro.

- A microfarad contains a million picofarads.
- 470 000 pF is 0.47 of that amount, so it is 0.47 µF.

This is a good reminder that capacitor values may look huge in picofarads but ordinary in microfarads.

## Conductors, insulators, and semiconductors

A conductor lets electric charge move easily. Copper, silver, gold, and aluminum are good conductors. Copper is widely used in radio equipment and house wiring because it conducts well and is practical to use.

An insulator resists current flow. Glass, air, porcelain, many plastics, Teflon, mica, and dry wood are common insulating materials. Insulators hold conductors apart so current goes where the circuit designer intended.

A semiconductor is between those two behaviours. Silicon is the everyday semiconductor example. Carbon can appear in resistive materials, so treat it separately from both good metal conductors and common insulators. Semiconductors become very important in diodes and transistors, but this lesson is about the basic material categories.

## Current, resistance, and conductance

Current is charge moving through a complete circuit path. The symbol for current is I, and the unit is the ampere, abbreviated A.

Resistance is opposition to current flow. Its symbol is R, and its unit is the ohm. Low resistance means current can flow easily. High resistance means current has a harder path.

Conductance is the inverse of resistance. If resistance is high, conductance is low. If resistance is low, conductance is high. For the Basic exam, the important word is inverse: conductance is the opposite way of describing how easy a path is.

## Voltage drop and polarity

Voltage is electrical pressure or potential difference. When current flows through a resistance, some voltage is used across that resistance. That is a voltage drop.

In a DC circuit, polarity names the direction or sign of the voltage and current path: positive and negative. Many radio accessories care about polarity. Reversing DC polarity can damage equipment.

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

Conductors and insulators are just as practical. Coaxial cable works because the centre conductor carries RF current, an insulator keeps it separated from the shield, and the shield provides the return path and shielding. If the insulator fails or a conductor touches where it should not, the circuit behaviour changes immediately.

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
