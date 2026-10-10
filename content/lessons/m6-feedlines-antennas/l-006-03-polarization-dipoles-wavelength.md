---
type: lesson
id: L-006-03
moduleId: M6
categoryIds:
  - B-006
title:
  en: "Polarization, dipoles, and wavelength"
  fr: null
covers:
  - B-006-007
  - B-006-008
objectives:
  - "Relate element orientation to wave polarization."
  - "Adjust dipole length to move resonant frequency."
  - "Estimate wavelength from frequency."
prerequisites:
  - L-006-02
estimatedMinutes: 35
quizIds:
  - QZ-L-006-03-A
status: draft
---
# Polarization, dipoles, and wavelength

Antennas launch electromagnetic waves. The electric field has an orientation, and that orientation is the wave's polarization. Antennas also have a physical size that relates to wavelength, so frequency and element length belong in the same mental picture.

## Learning objectives

By the end of this lesson, you can:

- explain horizontal and vertical polarization using the electric field;
- predict polarization from the orientation of a straight antenna element;
- estimate free-space wavelength from frequency;
- explain why shortening an antenna raises its resonant frequency; and
- describe how loading and traps affect antenna behaviour.

## Polarization

Polarization is named from the electric field of the radio wave. If the electric field is level with the ground, the wave is horizontally polarized. If the electric field is upright, the wave is vertically polarized. The magnetic field is also present, but Basic-level polarization questions are about the electric field.

A straight dipole or whip tends to radiate with the same polarization as the element. A vertical whip produces vertical polarization. A horizontal dipole produces horizontal polarization. A Yagi's polarization follows the orientation of its elements: turn the elements upright for vertical polarization or keep them level for horizontal polarization.

Matching polarization matters most for local line-of-sight VHF and UHF contacts. A mobile whip is vertical, so a vertical receiving antenna is normally the better match. For ionospheric HF paths, the wave can be twisted by reflection and refraction, so polarization can be less predictable at the far end.

### In the real world: matching a mobile whip

A car whip is usually vertical. A repeater antenna is usually vertical too. That shared orientation helps the electric fields line up for local VHF and UHF contacts.

If one station turns a portable Yagi sideways while the other station stays vertical, the contact may drop by many decibels. The radio did not become weak; the antennas stopped agreeing on polarization.

## Isotropic and dipole reference ideas

An isotropic radiator is an imaginary point source that radiates equally in every direction. It is not a buildable antenna, but it is useful as a reference. A perfect isotropic pattern would be a sphere.

A half-wave dipole in free space is different. It has maximum radiation broadside to the wire and very little off the wire ends. In three dimensions, that pattern is often described as a doughnut around the wire.

## Wavelength and frequency

Radio waves in free space travel at about the speed of light. For Basic calculations, use this convenient relationship:

```text
wavelength in metres = 300 / frequency in MHz
```

The symbol often used for wavelength is lambda, written here as λ. Frequency and wavelength move in opposite directions: higher frequency means shorter wavelength; lower frequency means longer wavelength.

### Worked example: free-space wavelength

A signal is at 146 MHz. Estimate its wavelength:

- Given: frequency = 146 MHz.
- Find: free-space wavelength in metres.
- Formula: λ = 300 / f(MHz).
- Substitute: λ = 300 / 146.
- Answer: λ = 2.05 m.
- Sanity check: this is why 146 MHz is part of the two-metre amateur band.

At 440 MHz, the same rule gives λ = 300 / 440 = 0.682 m, or about 68 cm.

### Memory trick: 100 MHz is 3 m

- Helps remember: wavelength in metres = 300 / frequency in MHz.
- Trick: anchor the rule at 100 MHz, because 300 / 100 = 3 m.
- Limit: this gives free-space wave size. Real antennas often need shortening factors, loading, or matching.

### Free-space estimates versus practical wire estimates

The 300 / f formula is a free-space wavelength estimate. The related 150 / f and 75 / f values come from simple free-space fractions of that wave-size estimate. Those quick values are useful when you are estimating wave size in open space or checking the order of magnitude.

Practical wire antennas are not exactly the same as bare fractions of a free-space wavelength. End effects, conductor diameter, insulation, and nearby objects make many HF wire antennas physically shorter than the free-space fraction. That is why the Basic-style starting formulas use about 143 / f for a dipole and 71.3 / f for a vertical element. If answer choices contain both pairs, ask whether the question is about a free-space wave estimate or a practical antenna cutting estimate.

## Dipole length and resonance

A simple half-wave dipole is roughly 0.5 wavelength long, but practical wire antennas are shortened by end effects and nearby materials. The exam-style estimate for an HF dipole of that type is:

```text
half-wave length in metres ≈ 143 / f(MHz)
```

To move a wire antenna lower in frequency, make it longer. To move it higher in frequency, make it shorter. That rule is more important than any single trimmed length, because real installations need final adjustment.

### Worked example: practical dipole starting length

You want a first cut for a wire dipole near 10.6 MHz.

- Given: frequency = 10.6 MHz.
- Find: overall half-wave dipole starting length.
- Formula: length ≈ 143 / f(MHz).
- Substitute: length ≈ 143 / 10.6.
- Answer: length ≈ 13.49 m overall, or about 6.75 m per side.
- Sanity check: this is shorter than the free-space half-wave estimate, 150 / 10.6 = 14.15 m.

After installation, an analyzer can show whether the resonant point is above or below the desired frequency.

## Loading, traps, and end insulators

A short antenna can be made electrically longer by adding inductance in series. This is why a compact HF mobile antenna often uses a loading coil. The coil helps cancel capacitive reactance from an element that is physically short for the band.

A trap is a parallel coil-and-capacitor circuit placed in an antenna element. At some frequencies it isolates part of the antenna; at other frequencies more of the conductor participates. That can allow multiband operation, but traps add complexity and can introduce loss or unwanted harmonic behaviour.

End insulators on a suspended wire mark where the antenna conductor ends electrically and where the support rope begins. They help keep the antenna's electrical length from silently extending into a wet rope, tree, or support.

## Try it

1. A vertical handheld whip is used with a vertical repeater antenna. Do their polarizations match? Yes. Both electric fields are vertical, which is normally best for local VHF/UHF work.
2. A horizontal dipole is made slightly shorter. What happens to resonant frequency? It moves upward because shorter antennas resonate at higher frequencies.
3. A 100 MHz signal is being estimated as a free-space wave. What wavelength should you use? λ = 300 / 100 = 3 m, so the free-space wavelength is about 3 m.
4. A resonant wire dipole is planned for 14.2 MHz. Which first-cut formula is the practical antenna estimate: 150 / f or 143 / f? Use 143 / 14.2 = 10.07 m overall as a practical starting length; 150 / f is the free-space fraction estimate.
5. A short mobile HF whip is far shorter than a quarter wavelength. What part helps it tune? A loading coil adds series inductance so the short whip behaves electrically longer.

## Radio connection

On VHF and UHF simplex, a pair of stations can lose many decibels if the transmit antenna is vertical and the receive antenna is horizontal. That can feel like weak transmitter power even when both radios are working normally. On HF, length errors can show up as a shifted SWR dip. An analyzer lets you see the trend without transmitting high power while you trim.

## Common mistakes

- Naming polarization from the feedline direction instead of the electric field direction.
- Expecting a horizontal antenna to receive a local vertical mobile signal as well as a vertical antenna would.
- Forgetting that longer means lower resonant frequency.
- Treating the first-cut formula as a guarantee instead of a starting point.
- Confusing a trap with a loading coil; both use inductance, but their jobs are different.

## Illustration brief

Alt text: A vertical whip and a horizontal dipole, each with electric-field arrows showing matching polarization.

Description: Draw two small ink-brush scenes. In the first, a car whip has upright electric-field arrows and a receiving ground-plane antenna also upright. In the second, a horizontal wire dipole has sideways electric-field arrows. Add a small wavelength ruler labelled λ = 300 / f(MHz), with a longer wave at lower frequency and a shorter wave at higher frequency.

## Summary

- Polarization follows the electric-field orientation relative to the ground.
- Straight antenna elements generally radiate with the element's orientation.
- Use λ(m) = 300 / f(MHz) for free-space wavelength estimates; 150 / f and 75 / f are the free-space half-wave and quarter-wave estimates.
- Use about 143 / f(MHz) for a practical HF half-wave dipole starting length and about 71.3 / f(MHz) for a practical quarter-wave starting length.
- Lengthening lowers resonant frequency; shortening raises it.
- Loading coils, traps, and end insulators all change how the antenna behaves electrically.
