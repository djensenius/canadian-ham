---
type: lesson
id: L-006-05
moduleId: M6
categoryIds:
  - B-006
title:
  en: "Loops, quads, and radiation patterns"
  fr: null
covers:
  - B-006-012
  - B-006-013
objectives:
  - "Compare dipole, random-wire, quad, and loop antenna patterns."
  - "Estimate quad driven-element length for a target band."
  - "Identify tradeoffs between simple wires and directional loops."
prerequisites:
  - L-006-04
estimatedMinutes: 35
quizIds:
  - QZ-L-006-05-A
status: draft
---
# Loops, quads, and radiation patterns

Wire antennas can be simple, but their patterns are not all the same. A half-wave dipole, an end-fed wire, a quad, and a delta loop use different current paths and support arrangements. Understanding the shape helps you choose and troubleshoot an antenna without memorizing every possible design.

## Learning objectives

By the end of this lesson, you can:

- describe the free-space pattern of a simple dipole;
- explain common random-wire and end-fed tradeoffs;
- identify quad and delta-loop construction;
- estimate full-wave loop and quad wire lengths; and
- choose feed-point placement for loop polarization at a beginner level.

## Dipole patterns

A half-wave dipole radiates strongest broadside to the wire and weakest off the ends. In three dimensions, the free-space pattern looks like a doughnut around the conductor. If a practice dipole is strung from the northeast corner of a yard toward the southwest corner, the broadside directions are northwest and southeast.

Near real ground, the pattern changes with height, soil, and nearby objects. The broadside idea is still the starting point: do not expect strongest radiation straight out of the wire ends.

### In the real world: choosing tree supports

If two good trees run east-west from the shack, a dipole between them is broadside north-south in its simplest free-space picture. That can be helpful if the stations you want are mostly north or south.

If the wanted direction is east-west, the same yard may need a different wire route, a vertical, or a rotatable antenna. The support locations are part of the antenna choice.

### Worked example: original dipole cut

A club wants a first-cut dipole near 18.9 MHz for a practice exercise.

- Given: frequency = 18.9 MHz.
- Find: overall dipole starting length and single leg length.
- Formula: length ≈ 143 / f(MHz).
- Substitute: length ≈ 143 / 18.9.
- Answer: length ≈ 7.57 m overall; each leg is roughly 3.79 m before trimming.
- Sanity check: the feed point is in the centre, so each leg is 7.57 m / 2 = 3.79 m.

The installed antenna should then be checked with an analyzer and shortened or lengthened in small steps.

## Random wires and end-fed antennas

A random-wire antenna is attractive because it can be simple to install, but the station end may carry RF voltage and current unless the matching and counterpoise are handled well. That can cause RF feedback: audio distortion, computer glitches, or a hot-feeling microphone.

An end-fed half-wave antenna can be convenient for portable or small-property work and can often operate on related bands with a suitable matching transformer. The feed point impedance is high, so directly attaching ordinary coax without matching is not the usual approach.

Trap antennas can cover several bands by electrically isolating sections at selected frequencies. The cost is added parts, possible loss, and extra limits on power or bandwidth.

## Quad antennas

A quad uses square loop elements. The driven loop is approximately a full wavelength of wire around its perimeter. A directional quad has multiple loop elements on a boom, with parasitic loops working somewhat like a Yagi's reflector and director.

A quad can perform well, but it presents more wind area and support complexity than a Yagi with straight elements. Weather loading matters: loops and spreaders can collect ice, flex in wind, and require a stronger support.

### Worked example: original quad estimate

For a quad driven loop near 24.6 MHz, use the one-wavelength loop estimate:

```text
loop length in metres ≈ 306 / f(MHz)
```

- Given: frequency = 24.6 MHz.
- Find: total wire around a square driven loop and one side length.
- Formula: loop length ≈ 306 / f(MHz).
- Substitute: loop length ≈ 306 / 24.6.
- Answer: loop length ≈ 12.44 m around the full square; each side is about 3.11 m.
- Sanity check: a square has four sides, so 12.44 m / 4 = 3.11 m.

The same total-wire idea applies to delta loops, but the shape is triangular instead of square. Notice the formula distinction: 300 / f is the free-space wavelength estimate, while 306 / f is the practical full-wave loop starting estimate used for these wire-loop questions.

## Delta loops and polarization

A delta loop is a triangular loop with an overall length of roughly one wavelength. When the bottom side is horizontal, feeding the centre of the bottom side tends to produce horizontal polarization. Feeding a side can produce vertical polarization in common beginner configurations.

The feed point and height affect impedance and pattern, so practical loop antennas often need a matching device. As with other antennas, the formula gives a first cut, not a finished guarantee.

### Worked example: original horizontal loop

A full-wave horizontal loop is planned near 10.1 MHz.

- Given: frequency = 10.1 MHz.
- Find: total wire for a full-wave loop.
- Formula: loop length ≈ 306 / f(MHz).
- Substitute: loop length ≈ 306 / 10.1.
- Answer: loop length ≈ 30.30 m total wire.
- Sanity check: if it is a square loop, each side starts near 30.30 m / 4 = 7.58 m.

The final shape may be irregular if the available trees are not in perfect positions, so expect to measure and adjust.

## Try it

1. A dipole wire runs northeast-southwest in free space. Where are its strongest directions? Broadside to the wire, so the strongest directions are roughly northwest and southeast.
2. A random wire causes audio distortion during transmit. What should you investigate? Look for RF feedback, bonding, matching, and counterpoise issues because RF may be returning through the operating position.
3. A one-wavelength square loop is cut for a higher frequency. What happens to total wire length? It becomes shorter because wavelength and frequency move in opposite directions.
4. A full-wave loop is planned for 15 MHz. Which estimate is the practical loop starting length? Use 306 / 15 = 20.4 m total wire; 300 / 15 = 20.0 m is the free-space wavelength estimate.
5. The same triangular loop is fed at a different point. What antenna property can change? Polarization can change because feed-point location affects current distribution and the electric-field orientation.

## Radio connection

Wire antennas invite experimentation. You may have room for a dipole on one band, an end-fed wire for portable work, or a loop supported by trees. The exam facts are not meant to freeze a single perfect antenna in your mind. They give you a safe vocabulary: pattern, feed point, impedance, polarization, traps, and full-wave or dipole-length estimates.

## Common mistakes

- Expecting a dipole to radiate mainly off its ends.
- Calling any long wire a good match to coax without considering the feed point impedance.
- Forgetting that a quad driven element is a loop, not a single straight half-wave wire.
- Treating weather survival as separate from electrical design.
- Using the calculated wire length as a final cut with no allowance for supports, insulation, and ground effects.

## Illustration brief

Alt text: A dipole doughnut pattern beside a square quad loop and a triangular delta loop, with feed points marked.

Description: Draw three ink-brush panels. First, show a straight dipole with a doughnut-shaped pattern broadside to the wire. Second, show two square quad loops on a short boom. Third, show a triangular delta loop with dots at possible feed points: bottom centre for horizontal polarization and side feed for vertical polarization. Add the formula 306 / f(MHz) beside the loop panels.

## Summary

- A dipole radiates broadside to the wire and has weak radiation off the ends.
- Random-wire and end-fed antennas can be useful but need careful matching and RF return paths.
- Trap antennas can support multiband use, with added parts and possible tradeoffs.
- Quad and delta-loop driven elements are approximately a full wavelength around the loop.
- Use about 306 / f(MHz) for practical full-wave loop starting length; 300 / f(MHz) is the free-space wavelength estimate.
- Loop feed-point location influences polarization and impedance.
