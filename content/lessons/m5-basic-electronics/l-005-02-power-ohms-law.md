---
type: lesson
id: L-005-02
moduleId: M5
categoryIds:
  - B-005
title:
  en: "Power and Ohm’s law"
  fr: null
covers:
  - B-005-003
  - B-005-004
objectives:
  - "Define electrical power and continuity."
  - "Use Ohm’s law to solve voltage, current, and resistance."
  - "Recognize open and short circuit symptoms."
prerequisites:
  - L-005-01
estimatedMinutes: 35
quizIds:
  - QZ-L-005-02-A
status: draft
---
# Power and Ohm’s law

In Lesson 1, you learned the names of the quantities. Now we connect them. Ohm’s law describes how voltage, current, and resistance fit together. Power describes how quickly electrical energy is being used. It may be changed into heat, light, sound, RF output, or motion.

The ISED reference sheet uses E for voltage, I for current, R for resistance, and P for power. These lessons use that notation so the formulas match the reference sheet you are given in the exam.

## Learning objectives

By the end of this lesson, you can:

- explain power as the rate of using electrical energy;
- use P = I x E to calculate power;
- use E = I x R, I = E / R, and R = E / I;
- recognize open circuits, closed circuits, short circuits, and continuity; and
- estimate whether an answer is reasonable before choosing it.

## Power: how fast energy is used

Power tells how quickly electrical energy is used or converted. The unit of electrical power is the watt. A 75 W work light uses electrical energy faster than a 15 W night-light. A hot resistor is often a sign of too much power turning into heat.

The power formula on the reference sheet is:

P = I x E

::figure power-triangle
Alt text: Power triangle with P above I and E, showing that P = I x E and the rearranged forms come from covering the unknown.
::

That means power in watts equals current in amperes times voltage in volts.

### Memory trick: P over I E

- Helps remember: P = I x E, I = P / E, and E = P / I.
- Trick: put P above I and E. Cover the unknown.
- Limit: this is a memory aid, not a derivation. In AC circuits with reactance, real power and apparent power need care.

### Worked example: phone charger power

A charger label says 9.0 V at 3.0 A.

- Given: E = 9.0 V; I = 3.0 A.
- Find: power P.
- Formula: P = I x E.
- Substitute: P = 3.0 A x 9.0 V.
- Answer: P = 27 W.
- Sanity check: this is a realistic rating for a fast charger.

### Worked example: radio accessory power

A field-day audio interface runs from 13.8 V and draws 0.45 A.

- Given: E = 13.8 V; I = 0.45 A.
- Find: power P.
- Formula: P = I x E.
- Substitute: P = 0.45 A x 13.8 V.
- Answer: P = 6.21 W, about 6.2 W.
- Sanity check: an audio interface is a small accessory, so a few watts makes sense.

### Misconception: current is used up

- Mistaken idea: a lamp or resistor uses up current.
- Correction: current flows through the loop. The part converts electrical energy into heat, light, sound, or another form.

## Ohm’s law

Ohm’s law links voltage, current, and resistance. The reference sheet gives the three rearranged forms:

| Find this | Use this formula | Plain-language meaning |
|---|---|---|
| Voltage E | E = I x R | Current through resistance produces voltage across it. |
| Current I | I = E / R | More voltage gives more current; more resistance gives less current. |
| Resistance R | R = E / I | Resistance is voltage divided by current. |

::figure ohms-law-triangle
Alt text: Ohm’s law triangle with E above I and R, showing E = I x R, I = E / R, and R = E / I.
::

Always use volts, amperes, and ohms together. If the current is in milliamperes, convert it to amperes before using Ohm’s law.

::figure ohms-law-power-wheel
Alt text: Ohm’s law and power wheel with quadrants for P, E, I, and R and three formulas in each quadrant.
Text equivalent:
- To find P: I x E; I² x R; E² / R.
- To find E: I x R; P / I; √(P x R).
- To find I: E / R; P / E; √(P / R).
- To find R: E / I; E² / P; P / I².
::

### Memory trick: E over I R

- Helps remember: E = I x R, I = E / R, and R = E / I.
- Trick: put E above I and R. Cover the unknown.
- Limit: this applies directly to resistance in simple DC or purely resistive circuits.

### Worked example: find voltage

A 470 ohm resistor has 0.020 A through it.

- Given: R = 470 ohms; I = 0.020 A.
- Find: voltage E.
- Formula: E = I x R.
- Substitute: E = 0.020 A x 470 ohms.
- Answer: E = 9.4 V.
- Sanity check: 20 mA through a few hundred ohms should be in the low-voltage range.

### Worked example: find current

A 150 ohm resistor is connected across 18 V.

- Given: E = 18 V; R = 150 ohms.
- Find: current I.
- Formula: I = E / R.
- Substitute: I = 18 V / 150 ohms.
- Answer: I = 0.12 A, or 120 mA.
- Sanity check: 150 ohms is a modest resistance, so 18 V gives more than a few milliamperes.

### Worked example: find resistance

A circuit draws 0.60 A from a 13.8 V source.

- Given: E = 13.8 V; I = 0.60 A.
- Find: resistance R.
- Formula: R = E / I.
- Substitute: R = 13.8 V / 0.60 A.
- Answer: R = 23 ohms.
- Sanity check: more current from the same voltage means lower resistance.

### Worked example: convert first

A panel lamp draws 80 mA through a 150 ohm limiting resistor.

- Given: I = 80 mA = 0.080 A; R = 150 ohms.
- Find: voltage E across the resistor.
- Formula: E = I x R.
- Substitute: E = 0.080 A x 150 ohms.
- Answer: E = 12 V.
- Sanity check: converting 80 mA to 0.080 A keeps the answer in a normal low-voltage range.

### In the real world: USB LED with a series resistor

An LED is a light-emitting diode. When it is on, it has a forward voltage drop. That means the LED takes part of the supply voltage, and the resistor must drop the rest.

Suppose a red LED drops about 2.1 V and should run near 20 mA from a 5.0 V USB source. Use a series resistor so the LED current stays near the target. Without that resistor, the LED can draw too much current and fail.

- Given: source E = 5.0 V; LED drop = 2.1 V; resistor E = 5.0 V - 2.1 V = 2.9 V; target I = 20 mA = 0.020 A.
- Find: series resistance R.
- Formula: R = resistor E / I.
- Substitute: R = 2.9 V / 0.020 A.
- Answer: R = 145 ohms ideal.
- Sanity check: the resistor drops the extra voltage that the LED does not use.

E12 is a common resistor-value series. The nearest E12 value above 145 ohms is 150 ohms. With 150 ohms, current is I = 2.9 V / 150 ohms = 0.0193 A, or 19.3 mA. Resistor power is P = 0.0193 A x 2.9 V = 0.056 W, so a 0.25 W resistor has margin.

### In the real world: 9 V battery LED choice

The same red LED from a 9.0 V battery needs a larger series resistor. The resistor must drop more voltage.

- Given: source E = 9.0 V; LED drop = 2.1 V; resistor E = 9.0 V - 2.1 V = 6.9 V; target I = 20 mA = 0.020 A.
- Find: series resistance R.
- Formula: R = resistor E / I.
- Substitute: R = 6.9 V / 0.020 A.
- Answer: R = 345 ohms ideal.
- Sanity check: a higher supply voltage needs more resistance for the same LED current.

A common E12 value above 345 ohms is 390 ohms. With 390 ohms, current is I = 6.9 V / 390 ohms = 0.0177 A, or 17.7 mA. Resistor power is P = 0.0177 A x 6.9 V = 0.122 W, so a 0.25 W resistor is suitable.

## Open, closed, and short circuits

A closed circuit has a complete path for current. Continuity means the path is complete. A continuity test is often a quick way to ask, "Can current get through here?"

An open circuit has a break in the path. If a battery and load are connected through a broken wire or open switch, no current is drawn.

A short circuit is an unintended low-resistance path. It can draw too much current. That is why a fuse may blow immediately when equipment with a short is connected to a power supply.

### In the real world: fuses protect wiring

A fuse is a thin conductor chosen to melt before the wire overheats. It is placed in series with the load, so all load current passes through it.

If a radio manual states a 20 A maximum DC draw at 13.8 V, calculate the whole-radio supply power this way:

P = I x E = 20 A x 13.8 V = 276 W

That is the power at the radio's DC supply connector, not the Basic regulatory DC input limit. The Basic limit applies to DC input to the transmitter final RF stage. Follow the manufacturer's fuse value for the radio and cable. Do not guess a universal fuse size from RF output power.

## Try it

1. What resistance drops 7.5 V at 15 mA? Convert 15 mA to 0.015 A, then R = E / I = 7.5 / 0.015 = 500 ohms.
2. What voltage is across 220 ohms at 0.035 A? E = I x R = 0.035 x 220 = 7.7 V.
3. What resistance draws 120 mA from 18 V? Convert 120 mA to 0.120 A. R = 18 / 0.120 = 150 ohms.
4. A formula answer says R = E x I. Does that match the reference sheet? No. Resistance is R = E / I.

## Radio connection

A radio power connector, fuse, and supply are a practical Ohm’s law classroom. If the radio draws normal current, the fuse stays intact and voltage remains close to the supply voltage. If the radio input is shorted, current can become much larger than expected and the fuse opens to protect the wiring.

Power ratings matter too. A transmitter may run from 12 V, but the current draw tells you how much DC supply power the supply must handle. A receiver accessory may draw only a few hundred milliamperes, while a transmitter can draw many amperes.

## Common mistakes

- Using milliamperes directly in Ohm’s law without converting to amperes.
- Multiplying when the formula requires division.
- Thinking power is the same as voltage. Power depends on both voltage and current.
- Calling every complete circuit a short circuit. A normal closed circuit has the intended load; a short has too little resistance.
- Assuming a hot resistor is only a voltage problem. Heat is caused by power dissipation.
- Choosing an LED resistor without checking both current and resistor power.

## Illustration brief

Alt text: A triangle-style memory aid showing E at the top, I and R at the bottom, beside a separate power note P = I x E.

Description: Draw a simple original formula card. Put E above a horizontal line, with I and R below it. Add arrows to show E = I x R, I = E / R, and R = E / I. Beside it, sketch a resistor with small heat marks and the caption "Power becomes heat when a resistor dissipates energy."

## Summary

- Power is the rate of electrical energy use and is measured in watts.
- Use P = I x E for power with current in amperes and voltage in volts.
- Use E = I x R, I = E / R, and R = E / I for Ohm’s law.
- Convert milli values to base units before calculating.
- An LED series resistor sets current and must have enough wattage rating.
- Continuity means a closed path; an open circuit has no complete path; a short circuit is an unintended low-resistance path that can draw too much current.
