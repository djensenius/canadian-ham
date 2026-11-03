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

Antennas launch electromagnetic waves. The electric field has an orientation. That orientation is the wave's polarization.

Antennas also have a physical size related to wavelength. Frequency and element length belong in the same mental picture.

## Learning objectives

By the end of this lesson, you can:

- explain horizontal and vertical polarization using the electric field;
- predict polarization from the orientation of a straight antenna element;
- estimate free-space wavelength from frequency;
- explain why shortening an antenna raises its resonant frequency; and
- describe how loading and traps affect antenna behaviour.

## Polarization

Polarization is named from the electric field of the radio wave. If the electric field is level with the ground, the wave is horizontally polarized. If the electric field is upright, the wave is vertically polarized.

A straight dipole or whip tends to radiate with the same polarization as the element. A vertical whip produces vertical polarization. A horizontal dipole produces horizontal polarization. A Yagi's polarization follows the orientation of its elements, not the direction the boom points.

Matching polarization matters most for local line-of-sight VHF and UHF contacts. A mobile whip is vertical, so a vertical receiving antenna is normally the better match. A ground wave travels along the Earth's surface. Near conductive ground, a horizontal electric field is strongly weakened by ground currents, while a vertical field meets the conducting ground at right angles, so the ground does not short it out. That is why a vertically polarized ground wave remains vertical at the receiving location. For ionospheric HF paths, reflection and refraction can twist the wave, so polarization can be less predictable at the far end.

### In the real world: matching a mobile whip

A car whip is usually vertical. A repeater antenna is usually vertical too. That shared orientation helps the electric fields line up for local VHF and UHF contacts.

If one station rotates a portable Yagi's elements from vertical to horizontal while the other station stays vertical, the contact may drop by many decibels. The radio did not become weak; the antennas stopped agreeing on polarization.

## Isotropic and dipole reference ideas

An isotropic radiator is an imaginary point source that radiates equally in every direction. It is not a buildable antenna, but it is useful as a reference. A perfect isotropic pattern would be a sphere.

A half-wave dipole in free space is different. It has maximum radiation broadside to the wire and very little radiation off the wire ends. In three dimensions, that pattern is often described as a doughnut around the wire.

## Wavelength and frequency

Radio waves in free space travel at about 300 000 km/s, or 300 000 000 m/s. A megahertz means a million cycles per second, so the metre and megahertz factors reduce to the Basic shortcut:

```text
wavelength in metres = 300 / frequency in MHz
```

::figure wavelength-dipole-example
Alt text: Wavelength formula λ in metres equals 300 divided by frequency in MHz, with free-space and practical first-cut half-wave dipole examples.
Text equivalent:
- Use λ(m) = 300 / f(MHz) for a free-space wavelength estimate.
- At 14.2 MHz, λ is about 21.1 m.
- A free-space half-wave is about 10.6 m total, with the feed point at the centre gap between the paired sides.
- A practical wire-dipole first cut uses about 143 / f(MHz), or about 10.1 m at 14.2 MHz.
::

The practical 143 / f first-cut estimate shown in the figure is explained below after the free-space wavelength examples.

The symbol often used for wavelength is lambda, written here as λ. Frequency and wavelength move in opposite directions. Higher frequency means shorter wavelength. Lower frequency means longer wavelength.

### Worked example: free-space wavelength

A signal is at 146 MHz. Estimate its wavelength.

- Given: frequency = 146 MHz.
- Find: free-space wavelength in metres.
- Formula: λ = 300 / f(MHz).
- Substitute: λ = 300 / 146.
- Answer: λ = 2.05 m.
- Sanity check: this is why this frequency belongs in the VHF amateur band named for about two metres.

At 440 MHz, the same rule gives λ = 300 / 440 = 0.682 m, or about 68 cm.

### Faded practice: finish a wavelength conversion

Estimate a free-space wave, not a finished antenna element.

- Given: f = 1.25 GHz = 1 250 MHz.
- Find: wavelength in metres and centimetres.
- Formula: λ(m) = 300 / f(MHz); centimetres = metres x 100.
- Complete: λ = 300 / ___ = ___ m = ___ cm.
- Sanity check: Should a higher microwave frequency have a shorter wavelength?

Fill the gaps before checking below.

### Check your work: finish a wavelength conversion

λ = 300 / 1 250 = 0.24 m, or 24 cm. Convert GHz to MHz before using the 300 shortcut.

### Memory trick: 100 MHz is 3 m

- Helps remember: wavelength in metres = 300 / frequency in MHz.
- Trick: anchor the rule at 100 MHz, because 300 / 100 = 3 m.
- Limit: this gives free-space wave size. Real antennas often need shortening factors, loading, or matching.

## Free-space estimates versus practical wire estimates

The 300 / f formula is a free-space wavelength estimate. The related 150 / f and 75 / f values are free-space half-wave and quarter-wave estimates. They help you check wave size.

Practical wire antennas are not exactly the same as bare fractions of a free-space wavelength. End effects, conductor diameter, insulation, and nearby objects often make HF dipoles and quarter-wave wires physically shorter than the free-space fraction.

That is why many practical dipole starting formulas use about 143 / f. The HF quarter-wave starting formula is about 71.3 / f. If answer choices contain both pairs, ask whether the item is about free-space wave size or practical antenna cutting.

### Misconception: every practical antenna is shorter

- Mistaken idea: every practical wire antenna is shorter than the matching free-space fraction.
- Correction: practical dipoles are often shorter than 150 / f, but full-wave loops and quads use a starting estimate greater than 300 / f. Lesson 5 uses 306 / f for those loops.

## Dipole length and resonance

A simple half-wave dipole is roughly a half wavelength long. Practical wire dipoles are usually shortened from the free-space half-wave value. A common starting estimate is:

```text
half-wave length in metres ≈ 143 / f(MHz)
```

To move a wire antenna lower in frequency, make it longer. To move it higher in frequency, make it shorter. This trend matters more than any first-cut length, because real installations need final adjustment.

### Worked example: practical dipole starting length

You want a first cut for a wire dipole near 10.6 MHz.

- Given: frequency = 10.6 MHz.
- Find: overall half-wave dipole starting length.
- Formula: length ≈ 143 / f(MHz).
- Substitute: length ≈ 143 / 10.6.
- Answer: length ≈ 13.49 m overall, or about 6.75 m per side.
- Sanity check: this is shorter than the free-space half-wave estimate, 150 / 10.6 = 14.15 m.

After installation, an analyzer can show whether the resonant point is above or below the desired frequency.

### Faded practice: finish a practical dipole first cut

Use the practical wire estimate rather than a free-space half wave.

- Given: f = 12.7 MHz.
- Find: overall starting length and each leg.
- Formula: overall length ≈ 143 / f(MHz); leg length = overall length / 2.
- Complete: overall length ≈ 143 / ___ ≈ ___ m; each leg ≈ ___ m.
- Sanity check: Is the overall result a little shorter than the free-space half-wave value?

Fill the gaps before checking below.

### Check your work: finish a practical dipole first cut

Overall length ≈ 11.26 m; each leg ≈ 5.63 m. The free-space half wave is about 11.81 m. Check the installed antenna and trim gradually.

## Loading, traps, and end insulators

A short antenna can be made electrically longer by adding inductance in series. That is why a compact HF mobile antenna often uses a loading coil. The coil helps cancel capacitive reactance from an element that is physically short for the band. Added series inductance lowers the resonant frequency for a given physical length.

A trap is a parallel coil-and-capacitor circuit placed in an antenna element. At some frequencies it isolates part of the antenna. At other frequencies more of the conductor participates. This can allow multiband operation, but traps add complexity and possible loss.

End insulators on a suspended wire mark where the antenna conductor ends electrically and where the support rope begins. They help keep a wet rope, tree, or support from changing the antenna's electrical length.

## Try it

Try these before reading the feedback below.

1. Do vertical handheld and repeater antennas have matching polarization?

:::answer
Yes. Their electric fields are vertical.
:::

2. What happens to a horizontal wire dipole's resonant frequency if it is shortened?

:::answer
Resonance moves upward.
:::

3. Estimate the free-space wavelength at 72 MHz.

:::answer
λ = 300 / 72 ≈ 4.17 m.
:::

4. Which first-cut estimate suits a practical wire dipole at 14.2 MHz: 150 / f or 143 / f?

:::answer
143 / 14.2 ≈ 10.07 m overall is the practical starting estimate.
:::

5. What helps a short mobile HF whip tune below its natural resonant frequency?

:::answer
A loading coil adds series inductance, making it electrically longer.
:::

## Radio connection

On local VHF and UHF paths, polarization mismatch can feel like weak transmitter power even when both radios work normally. On HF, length errors can show up as a shifted standing wave ratio, or SWR, dip. An analyzer lets you see the trend without transmitting high power while you trim.

## Common mistakes

- Naming polarization from the feedline direction instead of the electric field direction.
- Expecting a horizontal antenna to receive a local vertical mobile signal as well as a vertical antenna would.
- Forgetting that longer means lower resonant frequency.
- Treating the first-cut formula as a finished length with no trimming.
- Confusing a trap with a loading coil; both use inductance, but their jobs are different.

## Illustration brief

Alt text: A vertical whip and a horizontal dipole, each with electric-field arrows showing matching polarization.

Description: Draw two small ink-brush scenes. In the first, a car whip has upright electric-field arrows and a receiving ground-plane antenna also upright. In the second, a horizontal wire dipole has sideways electric-field arrows. Add a small wavelength ruler labelled λ = 300 / f(MHz), with a longer wave at lower frequency and a shorter wave at higher frequency.

## Summary

- Polarization follows the electric-field orientation relative to the ground.
- Straight antenna elements generally radiate with the element's orientation.
- Use λ(m) = 300 / f(MHz) for free-space wavelength estimates based on about 300 000 km/s.
- Use about 143 / f(MHz) for a practical HF half-wave dipole starting length and about 71.3 / f(MHz) for a practical quarter-wave starting length.
- Lengthening lowers resonant frequency; shortening raises it.
- Loading coils, traps, and end insulators all change how the antenna behaves electrically.
