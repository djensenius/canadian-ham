---
type: lesson
id: L-004-03
moduleId: M4
categoryIds:
  - B-004
title:
  en: "Resistor colour codes"
  fr: null
covers:
  - B-004-006
objectives:
  - "Decode four-band resistor values."
  - "Identify tolerance-band meaning."
  - "Check decoded values against expected circuit use."
prerequisites:
  - L-004-02
estimatedMinutes: 25
quizIds:
  - QZ-L-004-03-A
status: draft
---
# Resistor colour codes

Many through-hole resistors are too small to print a value clearly, so coloured bands identify the nominal resistance and tolerance. The skill is a mix of lookup, place value, and common sense.

You do not need to guess from memory at first. Use the reference table, keep the bands in order, then check whether the result is reasonable for the circuit. A decoded value that seems wildly wrong is a signal to reread the bands from the other end or check the tolerance band.

## Learning objectives

By the end of this lesson, you can:

- read the digit bands, multiplier band, and tolerance band on a common resistor;
- calculate nominal resistance from colour digits and multiplier;
- explain how tolerance gives an allowed range around the nominal value;
- distinguish tolerance, power rating, ohmic value, and temperature coefficient; and
- avoid common reading errors caused by lighting, body colour, or reversed orientation.

## Reading direction and band jobs

A common colour-code resistor has bands grouped closer to one end, with a tolerance band often spaced farther away. Read from the end where the value bands begin. In the usual style taught for Basic study:

- the first value band gives the tens digit;
- the second value band gives the ones digit;
- the multiplier band tells how many zeros, or what decimal multiplier, to apply; and
- the separated tolerance band gives the allowed percentage variation.

Think of the first two bands as making a two-digit number. Then multiply that number. The tolerance band does not change the nominal value; it tells how far the real part may be from that nominal value while still meeting its rating.

### Colour digits, multipliers, and tolerance

| Colour | Digit | Multiplier | Common tolerance use |
|---|---:|---:|---:|
| black | 0 | x 1 | — |
| brown | 1 | x 10 | ±1% |
| red | 2 | x 100 | ±2% |
| orange | 3 | x 1 000 | — |
| yellow | 4 | x 10 000 | — |
| green | 5 | x 100 000 | ±0.5% |
| blue | 6 | x 1 000 000 | ±0.25% |
| violet | 7 | x 10 000 000 | ±0.1% |
| grey | 8 | x 100 000 000 | ±0.05% |
| white | 9 | x 1 000 000 000 | — |
| gold | — | x 0.1 | ±5% |
| silver | — | x 0.01 | ±10% |

This table is a reference aid. Real exam reference material may provide a colour-code table, and real bench work often uses a meter to confirm the part.

## Worked examples

### Worked example: brown black orange gold

Read the bands in order:

- brown = 1;
- black = 0;
- orange multiplier = x 1 000; and
- gold tolerance = ±5%.

The first two bands make 10. Apply the multiplier:

10 x 1 000 = 10 000 ohms.

So the nominal value is 10 kilohms, with a tolerance of ±5%.

### Worked example: blue grey brown silver

Read the bands in order:

- blue = 6;
- grey = 8;
- brown multiplier = x 10; and
- silver tolerance = ±10%.

The first two bands make 68. Apply the multiplier:

68 x 10 = 680 ohms.

So the nominal value is 680 ohms, with a tolerance of ±10%.

### Worked example: green blue black brown

Read the bands in order:

- green = 5;
- blue = 6;
- black multiplier = x 1; and
- brown tolerance = ±1%.

The first two bands make 56. Apply the multiplier:

56 x 1 = 56 ohms.

So the nominal value is 56 ohms, with a tolerance of ±1%.

## Tolerance ranges

Tolerance is not an error you add on purpose. It is the allowed manufacturing variation around the nominal value. A smaller percentage means higher precision.

For a tolerance range:

allowed change = nominal value x tolerance fraction

low end = nominal value - allowed change

high end = nominal value + allowed change

### Worked example: tolerance around a nominal value

A 220 ohm resistor has a ±5% tolerance.

- Convert 5% to 0.05.
- allowed change = 220 x 0.05.
- allowed change = 11 ohms.
- low end = 220 - 11 = 209 ohms.
- high end = 220 + 11 = 231 ohms.

So a part in that tolerance class could measure from 209 ohms to 231 ohms and still match its nominal rating.

Higher precision means the allowed band is narrower. For example, a ±0.1% resistor is more precise than a ±5% resistor because its allowed percentage variation is smaller. A ±20% resistor is much less precise because it permits a wider spread.

## What the colour code does not tell you

The colour bands identify nominal resistance and tolerance. They do not tell you everything about the part.

Power rating is about heat. A small and a large resistor can have the same ohmic value but different wattage ratings. If a circuit dissipates too much power in a resistor, the value code will not save it from overheating.

Temperature coefficient describes how resistance changes as temperature changes. It is commonly specified as a small fractional change per degree of temperature, often in parts per million per degree Celsius. Some resistors rise in value with temperature, some fall, and precision parts are chosen when that drift matters.

Ohmic value is simply the nominal resistance in ohms. Tolerance is the permitted percentage variation. Power rating is the heat rating. Temperature coefficient is drift with temperature. Keep those four labels separate.

## Differentiating similar values

The band that changes depends on which part of the value changes.

If two resistors have the same multiplier and the same first digit but different second digits, the second value band distinguishes them. If the two-digit value is the same but one resistor has an extra zero, the multiplier band distinguishes them.

### Worked example: same digits, different multiplier

A resistor marked brown red brown has value digits 1 and 2, with multiplier x 10:

12 x 10 = 120 ohms.

A resistor marked brown red red has the same value digits, but multiplier x 100:

12 x 100 = 1 200 ohms.

Only the multiplier band changed, so the nominal resistance changed by a factor of ten.

## Try it

1. Orange orange brown gold: digits 3 and 3, multiplier x 10, so nominal value is 330 ohms with ±5% tolerance.
2. Yellow violet orange gold: digits 4 and 7, multiplier x 1 000, so nominal value is 47 kilohms with ±5% tolerance.
3. Brown green black brown: digits 1 and 5, multiplier x 1, so nominal value is 15 ohms with ±1% tolerance.
4. A ±1% part is more precise than a ±10% part because the allowed percentage spread is smaller.
5. If two resistors share the same first two digit bands but one has a larger multiplier, the multiplier band is what changed the value.

## Radio connection

Resistors appear in audio filters, bias networks, meter circuits, pull-up resistors, attenuators, dummy loads, and timing circuits. Reading colour bands helps you identify a part before soldering and helps you spot a wrong part during troubleshooting.

On the bench, colour-code reading is a first pass. Confirm critical parts with an ohmmeter, especially when bands are faded, the body colour is dark, or the circuit requires a tight tolerance.

## Common mistakes

- Reading from the tolerance end instead of the value end.
- Treating the tolerance band as another value digit.
- Forgetting that the multiplier changes the place value, not the tolerance.
- Assuming a resistor with the same ohmic value always has the same power rating.
- Thinking every resistor increases in value as it warms. The direction and size of change depend on temperature coefficient.
- Confusing higher precision with a larger percentage. Higher precision means a smaller tolerance percentage.

## Illustration brief

Alt text: A resistor with coloured bands labelled as first digit, second digit, multiplier, and tolerance, plus a small tolerance range line.

Description: Draw a simple horizontal resistor in ink brush style. Put four bands on it with callouts: first digit, second digit, multiplier, tolerance. Below it, draw a number line centred on a nominal value, with arrows to the lower and upper allowed limits. Add a small magnifying glass and a note: "Confirm critical values with a meter."

## Summary

- The first two value bands form a two-digit number.
- The multiplier band scales that number to the nominal resistance in ohms.
- The tolerance band gives allowed percentage variation around nominal value.
- Smaller tolerance percentage means higher precision.
- Power rating, tolerance, ohmic value, and temperature coefficient are different ratings.
- Temperature coefficient determines how resistance changes with temperature.
- Use a meter when the value is critical or the colour bands are hard to read.
