---
type: lesson
id: L-005-03
moduleId: M5
categoryIds:
  - B-005
title:
  en: "Series, parallel, and power ratings"
  fr: null
covers:
  - B-005-005
  - B-005-006
objectives:
  - "Compare series and parallel resistance behaviour."
  - "Calculate simple equal-value series and parallel combinations."
  - "Choose resistor and transformer power ratings with safe margins."
prerequisites:
  - L-005-02
estimatedMinutes: 35
quizIds:
  - QZ-L-005-03-A
status: draft
---
# Series, parallel, and power ratings

Most useful circuits have more than one part. Resistors can be connected end-to-end in series or side-by-side in parallel. The total resistance changes differently in each arrangement.

Power ratings are the other half of the story. A resistor value tells you how much it resists current. A wattage rating tells you how much heat it can safely dissipate.

## Learning objectives

By the end of this lesson, you can:

- find total resistance for simple series resistor circuits;
- find total resistance for equal-value parallel resistor circuits;
- explain how branch currents add in a parallel circuit;
- use P = I x E for supply and transformer power; and
- describe why physical size and wattage rating matter.

## Series resistors add

In a series circuit, current has only one path. It must pass through each resistor in turn. The reference sheet formula is:

Rt = R1 + R2 + R3 ... + Rn

Rt means total resistance. For resistors in series, add the values.

### Worked example: five equal series resistors

Five 10 ohm resistors are connected in series.

- Rt = 10 + 10 + 10 + 10 + 10.
- Rt = 50 ohms.

The total resistance is greater than any one resistor because each resistor adds more opposition to the same current path.

### Worked example: replacing 120 ohms

Five 24 ohm resistors in series make:

- Rt = 24 + 24 + 24 + 24 + 24.
- Rt = 120 ohms.

That series string can replace one 120 ohm resistor if the power and other circuit requirements are suitable.

## Parallel resistors make more paths

In a parallel circuit, each branch is connected across the same voltage. Current can flow through each branch. The total current is the sum of the branch currents.

For resistors in parallel, total resistance is less than the smallest branch resistance. The reference sheet gives:

1 / Rt = 1 / R1 + 1 / R2 + 1 / R3 ... + 1 / Rn

For equal-value resistors, there is a shortcut:

Rt = R / number of equal branches

### Worked example: four 100 ohm resistors in parallel

Four equal 100 ohm resistors are in parallel.

- Rt = R / 4.
- Rt = 100 / 4.
- Rt = 25 ohms.

Across 12 V, the total current is:

- I = E / R.
- I = 12 / 25.
- I = 0.48 A.
- 0.48 A = 480 mA.

### Worked example: two 1000 ohm resistors in parallel

Two equal 1000 ohm resistors in parallel make 500 ohms. Across 12 V:

- I = E / R.
- I = 12 / 500.
- I = 0.024 A.
- 0.024 A = 24 mA.

### Worked example: four 68 ohm resistors in parallel

For four equal resistors:

- Rt = 68 / 4.
- Rt = 17 ohms.

This shortcut only works because all four values are equal.

## Current sharing in parallel

Each branch current depends on that branch resistance. If two branches have the same voltage across them and resistor A carries twice the current of resistor B, resistor A has half the resistance of resistor B.

That is just Ohm’s law again: I = E / R. With the same E, lower R gives higher I.

## Power ratings and heat

A resistor wattage rating is about heat dissipation. A physically larger resistor of the same resistance can often dissipate more heat safely.

If two 500 ohm, 1 W resistors share power properly, their total safe dissipation can be 2 W. This can happen in a series pair or a parallel pair when the circuit applies voltage in a way that shares the load evenly. The value and the wattage are separate ideas.

### Worked example: transformer power

A load requires 12 V DC at 5 A.

- P = I x E.
- P = 5 A x 12 V.
- P = 60 W.

A transformer or supply must be rated for at least that power, and real designs normally add margin.

### Worked example: voltage doubled, power changes four times

For a fixed resistance, doubling voltage doubles current because I = E / R. Power is P = I x E, so both current and voltage doubled together make four times the power.

That is why applying too much voltage to a resistor can overheat it quickly.

### Worked example: dummy load from parallel resistors

A 50 ohm dummy load can be made from four 200 ohm resistors in parallel:

- Rt = 200 / 4 = 50 ohms.
- If each resistor is rated at 2 W and power shares evenly, total rating is 4 x 2 W = 8 W.

That is safely above 5 W, so the combination can dissipate 5 W if built correctly.

## Try it

1. Ten equal resistors of value R are in parallel. The total is R / 10.
2. Two 10 ohm resistors in series across 10 V give Rt = 20 ohms, I = 10 / 20 = 0.5 A, and P = 0.5 x 10 = 5 W.
3. A 12 V lamp rated 30 W draws I = P / E = 30 / 12 = 2.5 A.
4. Two 100 ohm resistors in parallel give 50 ohms. If each has the same wattage rating as a single 50 ohm resistor, the pair can share heat and increase total wattage.

## Radio connection

A dummy load lets you test a transmitter without radiating a signal. It often needs a 50 ohm resistance and enough wattage rating to turn RF energy into heat safely. Parallel resistor networks are a practical way to get the right resistance and spread heat across several parts.

Power supply sizing is another station skill. A radio that needs several amperes at 12 V requires a supply rated for the power and current, not just the voltage.

## Common mistakes

- Adding parallel resistors as if they were in series.
- Forgetting that total parallel resistance is lower than the smallest branch value.
- Using the equal-value shortcut when the resistors are not equal.
- Treating wattage rating as the same thing as resistance.
- Forgetting that doubling voltage across the same resistance makes power four times larger.

## Illustration brief

Alt text: Two resistor sketches: a single series path and a three-branch parallel path, with current arrows labelled.

Description: Draw a battery on the left. The top sketch has three resistors in one line with one current arrow. The bottom sketch has three parallel branches, each with its own arrow, joining back together. Add a small note: "Series resistance adds; parallel branch currents add."

## Summary

- Series resistances add directly.
- Equal-value parallel resistors divide: Rt = R / number of branches.
- Total current in a parallel circuit is the sum of branch currents.
- Lower branch resistance means higher branch current when voltage is the same.
- Resistor wattage ratings are heat ratings.
- Use P = I x E to size loads, supplies, and transformer ratings.

## Lesson quiz definition

Quiz ID: QZ-L-005-03-A

Official question IDs to present with shuffled answers:

- B-005-005-001
- B-005-005-002
- B-005-005-006
- B-005-005-008
- B-005-005-010
- B-005-006-002
- B-005-006-007
- B-005-006-008

Original concept-check questions:

1. Original: Three 15 ohm resistors are connected in series. What is the total resistance?
   - A. 45 ohms (correct)
   - B. 5 ohms
   - C. 15 ohms
   - D. 0.2 ohms
   - Explanation: Series resistances add directly: 15 + 15 + 15 = 45 ohms.
2. Original: Four equal 80 ohm resistors are in parallel. What is the total resistance?
   - A. 20 ohms (correct)
   - B. 320 ohms
   - C. 80 ohms
   - D. 40 ohms
   - Explanation: Equal parallel resistors use Rt = R / branches, so 80 / 4 = 20 ohms.
3. Original: Why might a physically larger resistor be chosen with the same ohm value?
   - A. It can safely dissipate more heat if rated for more watts. (correct)
   - B. It changes DC into AC.
   - C. It always has less resistance than marked.
   - D. It removes the need for a fuse.
   - Explanation: The larger part may have a higher power rating while keeping the same resistance.
