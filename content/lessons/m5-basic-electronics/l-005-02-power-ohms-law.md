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

The ISED reference sheet uses E for voltage, I for current, R for resistance, and P for power. These lessons use that notation so the formulas match the sheet you will see while studying.

## Learning objectives

By the end of this lesson, you can:

- explain power as the rate of using electrical energy;
- use P = I x E to calculate power;
- use E = I x R, I = E / R, and R = E / I;
- recognize open circuits, closed circuits, short circuits, and continuity; and
- estimate whether an answer is reasonable before choosing it.

## Power: how fast energy is used

Power is the rate at which electrical energy is used or converted. The unit of electrical power is the watt. A 100 W lamp uses electrical energy faster than a 40 W lamp. A hot resistor is often a sign that it is dissipating too much power as heat.

The power formula on the reference sheet is:

P = I x E

That means power in watts equals current in amperes times voltage in volts.

### Worked example: radio accessory power

A device runs from 12 V and draws 0.5 A.

- P = I x E.
- P = 0.5 A x 12 V.
- P = 6 W.

So the device uses 6 watts of electrical power.

## Ohm’s law

Ohm’s law links voltage, current, and resistance. The reference sheet gives the three rearranged forms:

| Find this | Use this formula | Plain-language meaning |
|---|---|---|
| Voltage E | E = I x R | Current through resistance produces voltage across it. |
| Current I | I = E / R | More voltage gives more current; more resistance gives less current. |
| Resistance R | R = E / I | Resistance is voltage divided by current. |

Always use volts, amperes, and ohms together. If the current is in milliamperes, convert it to amperes before using Ohm’s law.

### Worked example: find voltage

A 2 ohm resistor has 0.5 A through it.

- E = I x R.
- E = 0.5 A x 2 ohms.
- E = 1.0 V.

So the voltage across the resistor is 1.0 volts.

### Worked example: find current

A 30 ohm resistor is connected across 6 V.

- I = E / R.
- I = 6 V / 30 ohms.
- I = 0.2 A.

So the current is 0.2 amperes, or 200 mA.

### Worked example: find resistance

A circuit draws 0.25 A from a 12 V source.

- R = E / I.
- R = 12 V / 0.25 A.
- R = 48 ohms.

The resistance is 48 ohms.

### Worked example: convert first

A relay needs 200 mA and has a resistance of 25 ohms.

- Convert current: 200 mA = 0.2 A.
- E = I x R.
- E = 0.2 A x 25 ohms.
- E = 5 V.

So the relay needs 5 volts.

## Open, closed, and short circuits

A closed circuit has a complete path for current. Continuity means the path is complete. A continuity test is often a quick way to ask, "Can current get through here?"

An open circuit has a break in the path. If a battery and load are connected through a broken wire or open switch, no current is drawn.

A short circuit is an unintended low-resistance path. It can draw too much current. That is why a fuse may blow immediately when equipment with a short is connected to a power supply.

## Try it

1. What resistance drops 9 V at 10 mA? Convert 10 mA to 0.010 A, then R = E / I = 9 / 0.010 = 900 ohms.
2. What voltage is across 50 ohms at 0.44 A? E = I x R = 0.44 x 50 = 22 V.
3. What resistance draws 300 mA from 3 V? Convert 300 mA to 0.3 A. R = 3 / 0.3 = 10 ohms.
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

## Lesson quiz definition

Quiz ID: QZ-L-005-02-A

Official question IDs to present with shuffled answers:

- B-005-003-001
- B-005-003-004
- B-005-003-005
- B-005-003-007
- B-005-003-010
- B-005-004-001
- B-005-004-006
- B-005-004-010

Original concept-check questions:

1. Original: A 12 V circuit draws 2 A. What power is being used?
   - A. 24 W (correct)
   - B. 6 W
   - C. 14 W
   - D. 0.17 W
   - Explanation: P = I x E, so 2 x 12 = 24 W.
2. Original: A learner calculates resistance from 5 V and 0.5 A. Which setup is correct?
   - A. R = 5 / 0.5 (correct)
   - B. R = 5 x 0.5
   - C. R = 0.5 / 5
   - D. R = 5 + 0.5
   - Explanation: The reference-sheet form is R = E / I.
3. Original: Which fault is most likely to blow a fuse right away?
   - A. An unintended very low-resistance path. (correct)
   - B. A switch that is open and stops all current.
   - C. A meter connected with correct polarity.
   - D. A load that is disconnected from both wires.
   - Explanation: A short circuit can draw excessive current until protection opens the circuit.
