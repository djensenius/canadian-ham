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

Power ratings are the other half of the story. A resistor value tells you how much it resists current. A wattage rating tells you how much heat it can safely release.

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

### Worked example: seven equal series resistors

Seven 13 ohm resistors are connected in series.

- Given: each resistor is 13 ohms; there are seven in series.
- Find: total resistance Rt.
- Formula: Rt = R1 + R2 + R3 ... + Rn.
- Substitute: Rt = 13 + 13 + 13 + 13 + 13 + 13 + 13.
- Answer: Rt = 91 ohms.
- Sanity check: the total is greater than any single resistor.

### Worked example: building a nearby series value

Three 47 ohm resistors are connected in series.

- Given: each resistor is 47 ohms; there are three in series.
- Find: total resistance Rt.
- Formula: Rt = R1 + R2 + R3.
- Substitute: Rt = 47 + 47 + 47.
- Answer: Rt = 141 ohms.
- Sanity check: the string is near 140 ohms, before tolerance is considered.

That series string can stand in for a single part near 140 ohms, if the tolerance and power ratings suit the circuit. Three resistors in series also share the heat, so each one dissipates a third of the total power.

## Parallel resistors make more paths

In a parallel circuit, each branch is connected across the same voltage. Current can flow through each branch. The total current is the sum of the branch currents.

For resistors in parallel, total resistance is less than the smallest branch resistance. The reference sheet gives:

1 / Rt = 1 / R1 + 1 / R2 + 1 / R3 ... + 1 / Rn

For equal-value resistors, there is a shortcut:

Rt = R / number of equal branches

::figure series-parallel-current-paths
Alt text: Cell feeding resistors in series, and the same cell feeding parallel resistor branches with total and branch current arrows.
Text equivalent:
- Series: a cell drives a single loop through the resistors; the same current is measured through each resistor, and series resistances add.
- Parallel: a cell feeds separate resistor branches; total current is measured on the rail before the first branch, while I1 and I2 are measured beside their branch resistors.
- The branch currents rejoin, so total current equals I1 plus I2.
::

### Memory trick: product over sum

- Helps remember: the shortcut for two resistors in parallel.
- Trick: for a pair of resistors, Rt = (R1 x R2) / (R1 + R2).
- Limit: this shortcut is for a pair. For larger networks, use the reciprocal formula or combine pairs carefully.

### Worked example: four 220 ohm resistors in parallel

Four equal 220 ohm resistors are in parallel across 11 V.

- Given: R = 220 ohms; four equal branches; E = 11 V.
- Find: total resistance Rt and total current I.
- Formula: Rt = R / number of branches; I = E / Rt.
- Substitute: Rt = 220 / 4 = 55 ohms; I = 11 V / 55 ohms.
- Answer: I = 0.20 A, or 200 mA.
- Sanity check: the total resistance is lower than 220 ohms, so the current is higher than one branch current.

### Worked example: a pair of 680 ohm resistors in parallel

A pair of equal 680 ohm resistors is in parallel across 10.2 V.

- Given: R = 680 ohms in each branch; E = 10.2 V.
- Find: total resistance Rt and current I.
- Formula: Rt = R / 2; I = E / Rt.
- Substitute: Rt = 680 / 2 = 340 ohms; I = 10.2 V / 340 ohms.
- Answer: I = 0.030 A, or 30 mA.
- Sanity check: adding an equal path lowers the total resistance.

### Worked example: two unequal resistors in parallel

Product over sum is handy when a pair of branch resistors are not equal.

- Given: R1 = 330 ohms; R2 = 470 ohms.
- Find: total resistance Rt.
- Formula: Rt = (R1 x R2) / (R1 + R2).
- Substitute: Rt = (330 x 470) / (330 + 470) = 155 100 / 800.
- Answer: Rt = 193.875 ohms, about 194 ohms.
- Sanity check: the total is lower than 330 ohms, the smaller branch value.

### Worked example: four 180 ohm resistors in parallel

Four equal 180 ohm resistors are in parallel.

- Given: R = 180 ohms; four equal branches.
- Find: total resistance Rt.
- Formula: Rt = R / number of branches.
- Substitute: Rt = 180 / 4.
- Answer: Rt = 45 ohms.
- Sanity check: this shortcut only works because all four values are equal.

## Current sharing in parallel

Each branch current depends on that branch resistance. Suppose a branch across 14 V draws 70 mA while another branch across the same supply draws 35 mA. Ohm’s law gives 200 ohms for the higher-current branch and 400 ohms for the lower-current branch.

That is just Ohm’s law again: I = E / R. With the same E, lower R gives higher I.

### In the real world: batteries in series and parallel

Battery packs can be wired in series or parallel. In series, voltages add. In parallel, capacity can add. Battery safety matters, so use matched battery type, age, and state of charge when a pack is designed for series or parallel use.

Ah means ampere-hour, a battery capacity rating. Wh means watt-hour, an energy rating.

Three 1.2 V cells in series make 3.6 V. If each cell is rated 2.4 Ah, the pack is still 2.4 Ah. Energy is 3.6 V x 2.4 Ah = 8.64 Wh.

A matched pair of 7.4 V, 2.6 Ah packs in parallel keeps the voltage at 7.4 V. The capacity adds to 5.2 Ah. Energy is 7.4 V x 5.2 Ah = 38.48 Wh.

### In the real world: a voltage divider can be loaded

A voltage divider uses a top resistor and a lower resistor in series and takes the output from the junction between them. It is useful for small signals and light loads.

With a 15 kilohm top resistor and a 15 kilohm lower resistor across 9 V, the output across the lower resistor is 4.5 V.

If a 15 kilohm load is connected across the lower resistor, that leg becomes 7.5 kilohms because the equal lower paths share current. Now output E = 9 V x 7.5 / (15 + 7.5) = 3.0 V.

The caveat is important: a divider is not a power supply. A load can pull the output away from the no-load value.

## Power ratings and heat

A resistor wattage rating is about heat dissipation. A physically larger resistor of the same resistance can often dissipate more heat safely.

If three equal 330 ohm, 0.5 W resistors share power properly, their total safe dissipation can be 1.5 W. The rule is simple: N equal resistors in series or in parallel can dissipate N times the rating of one resistor when the current and heat share evenly. The value and the wattage are separate ideas.

### Worked example: transformer or supply power

A portable station load requires 13.8 V DC at 4 A.

- Given: E = 13.8 V; I = 4 A.
- Find: power P.
- Formula: P = I x E.
- Substitute: P = 4 A x 13.8 V.
- Answer: P = 55.2 W.
- Sanity check: a supply must be rated for at least that much output, and practical designs add margin.

### Principle: voltage doubled, power changes four times

For any fixed resistance, doubling voltage doubles current because I = E / R. Power is P = I x E, so both current and voltage doubled together make four times the power.

That is why applying too much voltage to a resistor can overheat it quickly.

### Misconception: a larger resistor body means more ohms

- Mistaken idea: a physically larger resistor must have a higher resistance value.
- Correction: physical size often indicates heat rating. The colour code or marking gives the ohmic value.

### Worked example: shared power in a test load

A temporary 72 ohm bench test load can be made from three 216 ohm resistors in parallel.

- Given: three equal 216 ohm resistors; each resistor is rated 4 W.
- Find: total resistance and shared power rating.
- Formula: Rt = R / branches; total rating = branch rating x branches when sharing is even.
- Substitute: Rt = 216 / 3; total rating = 4 W x 3.
- Answer: Rt = 72 ohms and total rating = 12 W.
- Sanity check: the network rating is higher than an 8 W test level, but only if the parts share current and are cooled correctly.

## Try it

1. Equal resistors in parallel have a lower total resistance than any one branch.
2. Three 18 ohm resistors in series across 8.1 V give Rt = 54 ohms, I = 8.1 / 54 = 0.15 A, and P is about 1.2 W.
3. A 13.8 V cooling fan rated 18 W draws I = P / E = 18 / 13.8, or about 1.3 A.
4. Matched battery packs in parallel keep the same voltage but can supply more ampere-hours if the packs are designed for that use.
5. A temporary test load uses several identical resistors on a heat sink. Before increasing the test level, confirm that current is sharing evenly and that each part remains within its own heat rating.

## Radio connection

A dummy load lets you test a transmitter without radiating a signal. It often needs a 50 ohm resistance and enough wattage rating to turn RF energy into heat safely. Parallel resistor networks are a practical way to get the right resistance and spread heat across several parts.

Power supply sizing is another station skill. A radio that needs several amperes at 12 V requires a supply rated for the power and current, not just the voltage.

## Common mistakes

- Adding parallel resistors as if they were in series.
- Forgetting that total parallel resistance is lower than the smallest branch value.
- Using the equal-value shortcut when the resistors are not equal.
- Treating wattage rating as the same thing as resistance.
- Forgetting that doubling voltage across the same resistance makes power four times larger.
- Trusting an unloaded voltage divider after a load has been connected.

## Illustration brief

Alt text: Resistor sketches showing a single series path and a multi-branch parallel path, with current arrows labelled.

Description: Draw a battery on the left. The top sketch has several resistors in a single line with a shared current arrow. The bottom sketch has parallel branches, each with its own arrow, joining back together. Add a small note: "Series resistance adds; parallel branch currents add."

## Summary

- Series resistances add directly.
- Equal-value parallel resistors divide: Rt = R / number of branches.
- Total current in a parallel circuit is the sum of branch currents.
- Lower branch resistance means higher branch current when voltage is the same.
- Battery voltages add in series; capacity adds in parallel when packs are designed and matched for it.
- Resistor wattage ratings are heat ratings.
- Use P = I x E to size loads, supplies, and transformer ratings.
