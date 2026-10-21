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

### Faded practice: finish a series string

A parts drawer has equal resistors for a bench circuit.

- Given: five 27 ohm resistors in series.
- Find: total resistance Rt.
- Formula: Rt = sum of the series resistances.
- Complete: Rt = 27 + 27 + 27 + ___ + ___ = ___ ohms.
- Sanity check: Is the total larger than any single part?

Fill the gaps before checking below.

### Check your work: finish a series string

Rt = 135 ohms. The same current passes through every part of this series string.

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

### Faded practice: finish an unequal parallel pair

Two unequal resistors share the same pair of terminals.

- Given: R1 = 270 ohms; R2 = 540 ohms.
- Find: total resistance Rt.
- Formula: Rt = (R1 x R2) / (R1 + R2), for a pair only.
- Complete: Rt = (270 x ___) / (270 + 540) = ___ ohms.
- Sanity check: Is your result below the smaller branch resistance?

Fill the gaps before checking below.

### Check your work: finish an unequal parallel pair

Rt = 145 800 / 810 = 180 ohms. The equal-value shortcut would be wrong because the branches differ.

## Current sharing in parallel

Each branch current depends on that branch resistance. Suppose a branch across 14 V draws 70 mA while another branch across the same supply draws 35 mA. Ohm’s law gives 200 ohms for the higher-current branch and 400 ohms for the lower-current branch.

That is just Ohm’s law again: I = E / R. With the same E, lower R gives higher I.

### Faded practice: finish branch-current totals

Two branches draw different currents from a common supply.

- Given: E = 10.08 V; R1 = 240 ohms; R2 = 480 ohms.
- Find: each branch current and their total.
- Formula: I1 = E / R1; I2 = E / R2; total I = I1 + I2.
- Complete: I1 = 10.08 / 240 = 0.042 A; I2 = 10.08 / ___ = ___ A; total I = ___ A.
- Sanity check: Does the higher-resistance branch draw less current?

Fill the gaps before checking below.

### Check your work: finish branch-current totals

I2 = 0.021 A. Total I = 0.042 + 0.021 = 0.063 A, or 63 mA. Each branch has the full 10.08 V across it.

### In the real world: batteries in series and parallel

Battery packs can be wired in series or parallel. In series, voltages add. In parallel, capacity can add. Battery safety matters, so use matched battery type, age, and state of charge when a pack is designed for series or parallel use.

Ah means ampere-hour, a battery capacity rating. Wh means watt-hour, an energy rating.

Three 1.2 V cells in series make 3.6 V. If each cell is rated 2.4 Ah, the pack is still 2.4 Ah. Energy is 3.6 V x 2.4 Ah = 8.64 Wh.

A matched pair of 7.4 V, 2.6 Ah packs in parallel keeps the voltage at 7.4 V. The capacity adds to 5.2 Ah. Energy is 7.4 V x 5.2 Ah = 38.48 Wh.

### Faded practice: finish pack energy

Treat these as ideal matched packs designed for the stated arrangement.

- Given: four 1.2 V, 2.2 Ah cells in series; a separate pair of 6.4 V, 3.2 Ah packs in parallel.
- Find: voltage, capacity, and energy of each arrangement.
- Formula: series voltages add; parallel capacities add; Wh = V x Ah.
- Complete: series E = 4 x 1.2 = ___ V, capacity = 2.2 Ah, energy = ___ Wh; parallel E = 6.4 V, capacity = ___ Ah, energy = ___ Wh.
- Sanity check: Did series capacity stay unchanged and parallel voltage stay unchanged?

Fill the gaps before checking below.

### Check your work: finish pack energy

Series: 4.8 V at 2.2 Ah, or 10.56 Wh. Parallel: 6.4 V at 6.4 Ah, or 40.96 Wh. Real battery packs require compatible cells and safe pack design.

### In the real world: a voltage divider can be loaded

A voltage divider uses a top resistor and a lower resistor in series and takes the output from the junction between them. It is useful for small signals and light loads.

With a 15 kilohm top resistor and a 15 kilohm lower resistor across 9 V, the output across the lower resistor is 4.5 V.

If a 15 kilohm load is connected across the lower resistor, that leg becomes 7.5 kilohms because the equal lower paths share current. Now output E = 9 V x 7.5 / (15 + 7.5) = 3.0 V.

The caveat is important: a divider is not a power supply. A load can pull the output away from the no-load value.

### Faded practice: finish a loaded divider

A load is added across the lower part of a divider.

- Given: source E = 8.0 V; top R = 14 kilohms; lower R = 14 kilohms; load R = 14 kilohms.
- Find: output voltage before and after adding the load.
- Formula: output E = source E x lower-leg R / (top R + lower-leg R).
- Complete: unloaded output = 8.0 x 14 / 28 = ___ V; loaded lower leg = 14 / 2 = ___ kilohms; loaded output = 8.0 x ___ / (14 + ___) ≈ ___ V.
- Sanity check: Does loading pull the output below its no-load value?

Fill the gaps before checking below.

### Check your work: finish a loaded divider

Unloaded output = 4.0 V. The loaded lower leg is 7 kilohms, giving 8.0 x 7 / 21 ≈ 2.67 V. Ratios use the same resistance units throughout; 14 kilohms = 14 000 ohms.

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

### Faded practice: finish supply sizing

A DC station accessory has a stated load current.

- Given: E = 13.6 V; I = 2.5 A.
- Find: required output power before design margin.
- Formula: P = I x E.
- Complete: P = ___ A x 13.6 V = ___ W.
- Sanity check: Does a supply need both enough current and enough power at the required voltage?

Fill the gaps before checking below.

### Check your work: finish supply sizing

P = 34 W. A practical supply needs suitable current and power ratings with margin, not just the right voltage.

### Principle: voltage doubled, power changes four times

For any fixed resistance, doubling voltage doubles current because I = E / R. Power is P = I x E, so both current and voltage doubled together make four times the power.

That is why applying too much voltage to a resistor can overheat it quickly.

### Faded practice: finish a voltage-change comparison

Compare heat in a fixed resistor at two DC voltages.

- Given: R = 240 ohms; E rises from 6.0 V to 12.0 V.
- Find: initial and final power.
- Formula: I = E / R; P = I x E.
- Complete: initial I = 6.0 / 240 = 0.025 A, P = 0.15 W; final I = 12.0 / ___ = ___ A; final P = ___ W.
- Sanity check: Did both voltage and current increase, making power rise faster than voltage?

Fill the gaps before checking below.

### Check your work: finish a voltage-change comparison

Final I = 0.050 A and P = 0.60 W. The voltage doubled and the heat power became four times larger.

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

### Faded practice: finish a shared load rating

Build a temporary resistive bench load with equal branches.

- Given: four 320 ohm resistors in parallel; each rated 3 W; equal sharing and suitable cooling.
- Find: total resistance and combined heat rating.
- Formula: Rt = R / branches; total rating = branch rating x branches.
- Complete: Rt = 320 / ___ = ___ ohms; total rating = 3 x ___ = ___ W.
- Sanity check: Have you kept resistance and heat rating as separate quantities?

Fill the gaps before checking below.

### Check your work: finish a shared load rating

Rt = 80 ohms; combined rating = 12 W under the stated sharing and cooling conditions. Unequal sharing can overload one part before reaching that total.

## Try it

Try these before reading the feedback below.

1. Compare total resistance with branch resistance for equal parallel resistors.

:::answer
Total resistance is lower than any branch resistance.
:::

2. Find resistance, current, and power for three 18 ohm series resistors across 8.1 V.

:::answer
Rt = 54 ohms; I = 8.1 / 54 = 0.15 A; P = 0.15 x 8.1 = 1.215 W, about 1.2 W.
:::

3. Find the current of a 13.8 V cooling fan rated 18 W.

:::answer
I = P / E = 18 / 13.8 ≈ 1.3 A.
:::

4. What changes when matched battery packs are placed in parallel?

:::answer
Voltage stays the same; capacity can add if the packs are designed and matched for that arrangement.
:::

5. Before increasing power into a temporary load made of identical resistors on a heat sink, what should you check?

:::answer
Confirm even current sharing and that each part remains within its own heat rating.
:::

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
