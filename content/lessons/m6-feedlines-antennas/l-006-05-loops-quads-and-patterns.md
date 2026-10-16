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
  - L-005-05
estimatedMinutes: 35
quizIds:
  - QZ-L-006-05-A
status: draft
---
# Loops, quads, and radiation patterns

Wire antennas can be simple, but their patterns are not all the same. A half-wave dipole, an end-fed wire, a quad, and a delta loop use different current paths and supports.

Understanding the shape helps you choose and troubleshoot antennas without memorizing every design.

## Learning objectives

By the end of this lesson, you can:

- describe the free-space pattern of a simple dipole;
- explain common random-wire and end-fed tradeoffs;
- identify quad and delta-loop construction;
- estimate full-wave loop and quad wire lengths; and
- choose feed-point placement for loop polarization at a beginner level.

## Dipole patterns

A half-wave dipole radiates strongest broadside to the wire and weakest off the ends. In three dimensions, the free-space pattern looks like a doughnut around the conductor. Fed at its centre in free space, a half-wave dipole has a feed-point impedance of about 73 ohms. Real installations near the ground vary from that figure.

Near real ground, the pattern changes with height, soil, and nearby objects. The broadside idea is still the starting point. Do not expect strongest radiation straight out of the wire ends.

### In the real world: choosing tree supports

If two good trees run east-west from the shack, a dipole between them is broadside north-south in its simplest free-space picture. That can help if the wanted stations are mostly north or south.

If the wanted direction is east-west, the same yard may need a different wire route, a vertical, or a rotatable antenna. The support locations are part of the antenna choice.

### Worked example: original dipole cut

A club wants a first-cut dipole near 18.9 MHz for a practice exercise.

- Given: frequency = 18.9 MHz.
- Find: overall dipole starting length and single leg length.
- Formula: length ≈ 143 / f(MHz).
- Substitute: length ≈ 143 / 18.9.
- Answer: length ≈ 7.57 m overall; each leg is 143 / 18.9 / 2 ≈ 3.78 m before trimming.
- Sanity check: each leg is half of the overall dipole length.

The installed antenna should be checked with an analyzer and adjusted in small steps.

## Random wires and end-fed antennas

A random-wire antenna can be simple to install. The station end may also carry RF voltage and current unless matching and counterpoise are handled well. That can cause RF feedback, audio distortion, computer glitches, or a hot-feeling microphone.

An end-fed half-wave antenna can be convenient for portable or small-property work. It can often operate on related bands with a suitable matching transformer. The feed point impedance is high, so ordinary coax is not usually attached directly.

Trap antennas can cover several bands by electrically isolating sections at selected frequencies. Because the same antenna is meant for multiband use, harmonic energy from a lower band can sometimes find another section that radiates it more readily. The cost is added parts, possible loss, extra power or bandwidth limits, and that harmonic-radiation risk.

## Quad antennas

A quad uses square loop elements. The driven loop is approximately a full wavelength of wire around its perimeter. A directional quad has multiple loop elements on a boom. Its parasitic loops work somewhat like a Yagi's reflector and director.

A delta loop with parasitic elements uses the same idea with triangular loops: each element is roughly one wavelength around the triangle. The extra loops act as coupled reflector or director elements.

A quad can perform well, but it has more wind area than a Yagi with straight elements. Weather loading is the major disadvantage. Loops and spreaders can collect ice and flex in wind.

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

The same total-wire idea applies to delta loops, but the shape is triangular instead of square. The formula distinction matters. The 300 / f formula estimates free-space wavelength. The 306 / f formula is a practical full-wave loop starting estimate.

### Misconception: loop formulas are shorter too

- Mistaken idea: because dipoles are cut shorter than the free-space half wave, full-wave loops should use less than 300 / f.
- Correction: practical full-wave loops and quads use about 306 / f, so their starting length is slightly longer than the free-space wavelength estimate.

## Delta loops and polarization

A delta loop is a triangular loop with an overall length of roughly one wavelength. When the bottom side is horizontal, feeding the centre of the bottom side tends to produce horizontal polarization. Feeding a side can produce vertical polarization in common beginner configurations.

A square quad's feed point also affects polarization. The strongest current points set the main electric-field direction. Moving the feed from the bottom horizontal side to an upright side shifts those current peaks, so the usual polarization changes from horizontal to vertical.

Feed point and height affect impedance and pattern, so practical loop antennas often need a matching device. The formula gives a first cut, not a finished guarantee.

::figure loop-antenna-patterns
Alt text: A dipole broadside pattern beside paired square quad loops and a triangular delta loop with H and V feed points marked.
Text equivalent:
- The dipole panel shows a short wire through a vertical doughnut-like pattern, with a broadside label above and weak labels near the wire ends.
- The quad panel shows paired square loops on a boom with a feed point marked on the driven loop.
- The delta panel shows a triangular loop with H feed at the bottom and V feed on the side.
- The formula below the loop panels is loop length ≈ 306 / f(MHz).
::

### Worked example: original horizontal loop

A full-wave horizontal loop is planned near 10.1 MHz.

- Given: frequency = 10.1 MHz.
- Find: total wire for a full-wave loop.
- Formula: loop length ≈ 306 / f(MHz).
- Substitute: loop length ≈ 306 / 10.1.
- Answer: loop length ≈ 30.30 m total wire.
- Sanity check: if it is a square loop, each side starts near 306 / 10.1 / 4 ≈ 7.57 m.

The final shape may be irregular if the available trees are not in perfect positions.

## Try it

1. A dipole wire runs northeast-southwest in free space. Where are its strongest directions? Broadside to the wire, roughly northwest and southeast.
2. A random wire causes audio distortion during transmit. What should you investigate? Look for RF feedback, bonding, matching, and counterpoise issues.
3. A one-wavelength square loop is cut for a higher frequency. What happens to total wire length? It becomes shorter because wavelength and frequency move in opposite directions.
4. A full-wave loop is planned for 15 MHz. Which estimate is the practical loop starting length? Use 306 / 15 = 20.4 m total wire; 300 / 15 = 20.0 m is the free-space wavelength estimate.
5. The same triangular loop is fed at a different point. What antenna property can change? Polarization can change because feed-point location affects current distribution and electric-field orientation.

## Radio connection

Wire antennas invite experimentation. You may have room for a dipole on one band, an end-fed wire for portable work, or a loop supported by trees. The exam facts give you a safe vocabulary: pattern, feed point, impedance, polarization, traps, and length estimates.

## Common mistakes

- Expecting a dipole to radiate mainly off its ends.
- Calling any long wire a good match to coax without considering feed point impedance.
- Forgetting that a quad driven element is a loop, not a single straight half-wave wire.
- Treating weather loading as a minor detail for quads and loops.
- Using the calculated wire length as a final cut with no allowance for supports, insulation, and ground effects.

## Illustration brief

Alt text: A dipole doughnut pattern beside a square quad loop and a triangular delta loop, with feed points marked.

Description: Draw three ink-brush panels. First, show a straight dipole with a doughnut-shaped pattern broadside to the wire. Second, show two square quad loops on a short boom. Third, show a triangular delta loop with dots at possible feed points: bottom centre for horizontal polarization and side feed for vertical polarization. Add the formula 306 / f(MHz) beside the loop panels.

## Summary

- A dipole radiates broadside to the wire and has weak radiation off the ends.
- Random-wire and end-fed antennas can be useful but need careful matching and RF return paths.
- Trap antennas can support multiband use, with added parts, possible loss, and harmonic-radiation tradeoffs because different sections can work on related bands.
- Quad and delta-loop driven elements are approximately a full wavelength around the loop, and parasitic loop elements can make them directional.
- Use about 306 / f(MHz) for practical full-wave loop starting length; 300 / f(MHz) is the free-space wavelength estimate.
- Loop feed-point location influences polarization and impedance.
