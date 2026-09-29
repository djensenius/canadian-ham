---
type: lesson
id: L-006-04
moduleId: M6
categoryIds:
  - B-006
title:
  en: "Directivity, Yagis, and element lengths"
  fr: null
covers:
  - B-006-009
  - B-006-010
  - B-006-011
objectives:
  - "Describe how parasitic elements shape antenna directivity."
  - "Estimate quarter-wave and half-wave element lengths."
  - "Recognize Yagi driven elements, directors, reflectors, and traps."
prerequisites:
  - L-006-03
estimatedMinutes: 45
quizIds:
  - QZ-L-006-04-A
status: draft
---
# Directivity, Yagis, and element lengths

Antenna gain does not create power from nothing. It concentrates radiation in some directions and reduces it in others. Directional antennas such as Yagis use element length and spacing to shape that concentration.

## Learning objectives

By the end of this lesson, you can:

- describe parasitic elements and how they are energized;
- identify driven elements, directors, reflectors, booms, and traps;
- distinguish gain, bandwidth, beamwidth, and front-to-back ratio;
- estimate quarter-wave and half-wave vertical lengths; and
- calculate first-cut Yagi element lengths using original scenarios.

## Directivity and gain

A reference antenna makes gain numbers meaningful. Gain in dBi compares an antenna to an isotropic radiator. Gain in dBd compares it to the standard dipole reference. That dipole reference is about 2.1 dB above an isotropic radiator, so dBi numbers are about 2.1 dB higher than dBd numbers for the same antenna.

Bandwidth is the range of frequencies over which an antenna performs acceptably. Beamwidth is the angular width of the main lobe. Front-to-back ratio compares radiation in the forward direction with radiation in the opposite direction.

### Worked example: dBi and dBd

A small beam is listed as 8.6 dBi. To compare it with a dipole reference, subtract about 2.1 dB:

- gain over dipole ≈ 8.6 dBi - 2.1 dB
- gain over dipole ≈ 6.5 dBd

The antenna did not change; only the reference changed.

## Parasitic elements

A driven element is connected to the feedline. A parasitic element is not directly fed. It receives energy from the nearby driven element by electromagnetic coupling and then re-radiates. That re-radiation can strengthen the signal in one direction and weaken it in another.

In a simple Yagi, a reflector is slightly longer than the driven element and sits behind it. A director is slightly shorter and sits in front of it. Adding directors and increasing boom length can increase forward gain, though every design is a compromise among gain, bandwidth, mechanical size, and front-to-back ratio.

## Yagi structure and practical HF use

Yagis become more practical as frequency rises because the elements are shorter. HF beams are common on the upper HF bands where a rotatable structure can fit on a tower or mast. Trap Yagis use resonant traps in the elements so one antenna can operate on multiple bands.

Element diameter also matters. Larger-diameter elements can broaden the useful frequency range. Spacing affects gain and pattern shape. For a three-element Yagi, a spacing near a small fraction of a wavelength is commonly used as a compromise rather than as a magic maximum.

### Worked example: original Yagi element estimates

For an exercise near 24.2 MHz, use the half-wave estimate for the driven element:

- driven element length ≈ 143 / 24.2
- driven element length ≈ 5.91 m

A director might be about 5 percent shorter:

- director estimate ≈ 5.91 x 0.95
- director estimate ≈ 5.61 m

A reflector might be about 5 percent longer:

- reflector estimate ≈ 5.91 x 1.05
- reflector estimate ≈ 6.21 m

Real Yagi dimensions are design-specific, but the relationships are the key: director shorter, reflector longer.

The 143 / f half-wave estimate is the practical wire starting point used for these antenna-length problems. The free-space half-wave estimate, 150 / f, is useful for wave-size estimates and rough checking, but it does not include the shortening normally applied to a resonant wire element.

## Quarter-wave verticals and radials

A quarter-wave vertical uses the ground, a vehicle body, or radial wires as the other half of the antenna system. A useful first-cut length is:

```text
quarter-wave length in metres ≈ 71.3 / f(MHz)
```

Some reference material rounds the constant slightly; keep the formula style and units clear. The free-space quarter-wave value is 75 / f, half of the free-space half-wave estimate; 71.3 / f is the practical antenna starting estimate. Downward-sloping quarter-wave radials can bring an elevated vertical's feed point closer to a fifty-ohm coax match.

### Worked example: original vertical estimate

A portable vertical is planned near 18.1 MHz.

- length ≈ 71.3 / 18.1
- length ≈ 3.94 m

The antenna will still need trimming and matching after it is installed, especially because nearby ground and supports change the feed point impedance.

## Mobile verticals and loading coils

A mobile HF whip is often much shorter than a natural quarter wavelength. Electrically, that short conductor looks capacitive, so a loading coil adds series inductance to tune out some of that capacitive reactance. The tradeoff is that compact loaded antennas may be narrow-band and less efficient than full-sized antennas.

A five-eighths-wavelength VHF or UHF vertical can have more gain at useful low angles than a quarter-wave vertical, but it usually needs matching because its feed impedance is not the same as the simple quarter-wave case.

## Try it

1. A Yagi's elements are horizontal. What polarization should you expect? Horizontal, because polarization follows the element orientation.
2. Which parasitic element is a little shorter than the driven element and placed toward the desired signal direction? The director is shorter and sits in the forward direction.
3. Which parasitic element is a little longer than the driven element and sits behind it? The reflector is longer and sits behind the driven element.
4. A stacked pair of identical antennas is compared with one antenna before real-world losses. What ideal gain change is expected? About 3 dB, because the useful radiated power is roughly doubled.
5. A quarter-wave vertical is planned for 25 MHz. Which practical starting length should you use? Use 71.3 / 25 = 2.85 m; 75 / 25 = 3.0 m is the free-space quarter-wave check.

## Radio connection

When you rotate a Yagi, you are rotating the main lobe of its pattern. That can improve a desired station and reduce interference from another direction. When you add radials to a vertical, you are improving the return path so less power is wasted in the earth. Both changes are about using the RF energy where you want it.

## Common mistakes

- Thinking antenna gain means an amplifier has been added.
- Confusing bandwidth with beamwidth.
- Swapping the jobs of director and reflector.
- Treating every Yagi with the same number of elements as if it had identical gain.
- Forgetting that a short mobile HF antenna usually needs loading and has tradeoffs.

## Illustration brief

Alt text: Top view of a three-element Yagi with a long reflector, driven element, and shorter director on a boom, plus a forward-arrow main lobe.

Description: Draw a brush-style top view. Label the rear element "reflector, slightly longer," the middle element "driven, feedline here," and the front element "director, slightly shorter." Add a bold arrow labelled "main lobe" pointing from reflector through director. Include a small vertical antenna with downward-sloping radials and the formula 71.3 / f(MHz).

## Summary

- Gain describes concentration compared with a reference antenna.
- A parasitic element is energized by nearby RF fields, not by a direct feedline connection.
- Directors are slightly shorter; reflectors are slightly longer.
- Use about 143 / f(MHz) for practical HF half-wave estimates and 71.3 / f(MHz) for practical quarter-wave estimates; 150 / f and 75 / f are free-space estimates.
- Radials reduce ground losses and can help a vertical feed point approach common coax impedances.
- Yagi design balances gain, bandwidth, front-to-back ratio, boom length, and mechanical strength.
