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

In Lesson 1, you learned the names of the quantities. Now we connect them. Ohm’s law describes how voltage, current, and resistance fit together. Power describes how quickly electrical energy is being used or changed into heat, light, sound, RF output, or motion.

The ISED reference sheet uses E for voltage, I for current, R for resistance, and P for power. These lessons use that notation so the formulas match the reference sheet you are given in the exam.

## Learning objectives

By the end of this lesson, you can:

- explain power as the rate of using electrical energy;
- use P = I x E to calculate power;
- use E = I x R, I = E / R, and R = E / I;
- recognize open circuits, closed circuits, short circuits, and continuity; and
- estimate whether an answer is reasonable before choosing it.

## Power: how fast energy is used

Power tells how quickly electrical energy is used or converted. The unit of electrical power is the watt. A 75 W work light uses electrical energy faster than a 15 W night-light. A hot resistor is often a sign that it is dissipating too much power as heat.

The power formula on the reference sheet is:

P = I x E

::figure power-triangle
Alt text: Power triangle with P above I and E, showing that P = I x E and the rearranged forms come from covering the unknown.
::

That means power in watts equals current in amperes times voltage in volts.

### Worked example: radio accessory power

A field-day audio interface runs from 13.8 V and draws 0.45 A.

- P = I x E.
- P = 0.45 A x 13.8 V.
- P = 6.21 W.

So the interface uses about 6.2 watts of electrical power.

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

### Worked example: find voltage

A 470 ohm resistor has 0.020 A through it.

- E = I x R.
- E = 0.020 A x 470 ohms.
- E = 9.4 V.

So the voltage across the resistor is 9.4 volts.

### Worked example: find current

A 150 ohm resistor is connected across 18 V.

- I = E / R.
- I = 18 V / 150 ohms.
- I = 0.12 A.

So the current is 0.12 amperes, or 120 mA.

### Worked example: find resistance

A circuit draws 0.60 A from a 13.8 V source.

- R = E / I.
- R = 13.8 V / 0.60 A.
- R = 23 ohms.

The resistance is 23 ohms.

### Worked example: convert first

A panel lamp draws 80 mA through a 150 ohm limiting resistor.

- Convert current: 80 mA = 0.080 A.
- E = I x R.
- E = 0.080 A x 150 ohms.
- E = 12 V.

So the resistor has 12 volts across it.

## Open, closed, and short circuits

A closed circuit has a complete path for current. Continuity means the path is complete. A continuity test is often a quick way to ask, "Can current get through here?"

An open circuit has a break in the path. If a battery and load are connected through a broken wire or open switch, no current is drawn.

A short circuit is an unintended low-resistance path. It can draw too much current. That is why a fuse may blow immediately when equipment with a short is connected to a power supply.

## Try it

1. What resistance drops 7.5 V at 15 mA? Convert 15 mA to 0.015 A, then R = E / I = 7.5 / 0.015 = 500 ohms.
2. What voltage is across 220 ohms at 0.035 A? E = I x R = 0.035 x 220 = 7.7 V.
3. What resistance draws 120 mA from 18 V? Convert 120 mA to 0.120 A. R = 18 / 0.120 = 150 ohms.
4. A formula answer says R = E x I. Does that match the reference sheet? No. Resistance is R = E / I.

## Radio connection

A radio power connector, fuse, and supply are a practical Ohm’s law classroom. If the radio draws normal current, the fuse stays intact and voltage remains close to the supply voltage. If the radio input is shorted, current can become much larger than expected and the fuse opens to protect the wiring.

Power ratings matter too. A transmitter may run from 12 V, but the current draw tells you how much DC input power the supply must handle. A receiver accessory may draw only a few hundred milliamperes, while a transmitter can draw many amperes.

## Common mistakes

- Using milliamperes directly in Ohm’s law without converting to amperes.
- Multiplying when the formula requires division.
- Thinking power is the same as voltage. Power depends on both voltage and current.
- Calling every complete circuit a short circuit. A normal closed circuit has the intended load; a short has too little resistance.
- Assuming a hot resistor is only a voltage problem. Heat is caused by power dissipation.

## Illustration brief

Alt text: A triangle-style memory aid showing E at the top, I and R at the bottom, beside a separate power note P = I x E.

Description: Draw a simple original formula card. Put E above a horizontal line, with I and R below it. Add arrows to show E = I x R, I = E / R, and R = E / I. Beside it, sketch a resistor with small heat marks and the caption "Power becomes heat when a resistor dissipates energy."

## Summary

- Power is the rate of electrical energy use and is measured in watts.
- Use P = I x E for power with current in amperes and voltage in volts.
- Use E = I x R, I = E / R, and R = E / I for Ohm’s law.
- Convert milli values to base units before calculating.
- Continuity means a closed path; an open circuit has no complete path; a short circuit is an unintended low-resistance path that can draw too much current.
