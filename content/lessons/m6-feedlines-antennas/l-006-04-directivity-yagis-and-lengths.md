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
  - L-005-04
estimatedMinutes: 45
quizIds:
  - QZ-L-006-04-A
status: draft
---
# Directivity, Yagis, and element lengths

Antenna gain does not create power from nothing. It concentrates radiation in some directions and reduces it in others. Directional antennas, such as Yagis, use element length and spacing to shape that pattern.

## Learning objectives

By the end of this lesson, you can:

- describe parasitic elements and how they are energized;
- identify driven elements, directors, reflectors, booms, and traps;
- distinguish gain, bandwidth, beamwidth, and front-to-back ratio;
- estimate quarter-wave and half-wave element lengths; and
- calculate first-cut Yagi element lengths using original scenarios.

## Directivity and gain

A reference antenna makes gain numbers meaningful. Gain in dBi compares an antenna to an isotropic radiator. Gain in dBd compares it to a standard dipole reference. The dipole reference is about 2.1 dB above an isotropic radiator.

Bandwidth is the range of frequencies over which an antenna performs acceptably. Beamwidth is the angular width of the main lobe. Front-to-back ratio compares radiation in the forward direction with radiation in the opposite direction.

Stacking an identical pair of antennas can add about 3 dB in the main direction before real-world losses. That 3 dB means the power density in the main direction roughly doubles because the combined pattern is concentrated. The transmitter has not created extra power.

### In the real world: aiming a small beam

A handheld beam for a fox hunt or satellite contact does not make the transmitter more powerful. It puts more of the pattern in one direction and less in another.

Point the main lobe at the wanted signal. You can also point the back or side of the antenna toward a noise source you want to reduce.

### Worked example: dBi and dBd

A small beam is listed as 8.6 dBi. To compare it with a dipole reference, subtract about 2.1 dB.

- Given: gain = 8.6 dBi; dipole reference offset = 2.1 dB.
- Find: gain in dBd.
- Formula: dBd ≈ dBi - 2.1 dB.
- Substitute: dBd ≈ 8.6 - 2.1.
- Answer: dBd ≈ 6.5 dBd.
- Sanity check: the antenna did not change; only the reference changed.

## Parasitic elements

A driven element is connected to the feedline. A parasitic element is not directly fed. It receives energy from the nearby driven element by electromagnetic coupling and re-radiates that energy.

In a simple Yagi, a reflector is slightly longer than the driven element and sits behind it. A director is slightly shorter and sits in front of it. Adding directors and increasing boom length can increase forward gain, but every design is a compromise among gain, bandwidth, mechanical size, and front-to-back ratio.

## Yagi structure and practical HF use

Yagis become more practical as frequency rises because their elements are shorter. HF beams are common on upper HF bands where a rotatable structure can fit on a tower or mast. Trap Yagis use resonant traps in the elements so one antenna can operate on several bands.

Element diameter matters. Larger-diameter elements can broaden the useful frequency range. Wider element spacing can raise gain, but it changes the pattern and mechanical size too. For a Yagi with a driven element, reflector, and director, about 0.2 λ, or a fifth of a wavelength, is the Basic-bank convention for balancing forward gain with rear rejection.

### Worked example: original Yagi element estimates

For an exercise near 24.2 MHz, use the practical half-wave estimate for the driven element. The 5% shorter director and 5% longer reflector are the Basic-bank convention for these estimates.

- Given: frequency = 24.2 MHz; director about 5% shorter; reflector about 5% longer.
- Find: first-cut driven element, director, and reflector lengths.
- Formula: driven element length ≈ 143 / f(MHz).
- Substitute: driven element length ≈ 143 / 24.2.
- Answer: driven element ≈ 5.91 m; director ≈ 5.91 x 0.95 = 5.61 m; reflector ≈ 5.91 x 1.05 = 6.21 m.
- Sanity check: the director is shorter than the driven element, and the reflector is longer.

Real Yagi dimensions are design-specific. The key relationship is director shorter, reflector longer.

## Quarter-wave and half-wave verticals

A quarter-wave vertical uses the ground, a vehicle body, or radial wires as the other half of the antenna system. The vertical element is symmetric around its upright axis, so no compass direction is favoured. That is why the simple horizontal pattern is the same all around the antenna. A useful first-cut length for many HF quarter-wave questions is:

```text
quarter-wave length in metres ≈ 71.3 / f(MHz)
```

The free-space quarter-wave value is 75 / f. The 71.3 / f value is the practical starting estimate used for many HF quarter-wave antenna questions. Downward-sloping quarter-wave radials can bring an elevated vertical's feed point closer to a fifty-ohm coax match.

Some VHF half-wave vertical exam items use the plain free-space half-wave convention:

```text
half-wave length in metres ≈ 150 / f(MHz)
```

Use that convention when the question is asking for the Basic bank's approximate VHF half-wave vertical length. A real antenna design may still account for end effects, element diameter, matching, and installation details.

### Worked example: original vertical estimate

A portable vertical is planned near 18.1 MHz.

- Given: frequency = 18.1 MHz.
- Find: quarter-wave starting length.
- Formula: length ≈ 71.3 / f(MHz).
- Substitute: length ≈ 71.3 / 18.1.
- Answer: length ≈ 3.94 m.
- Sanity check: the free-space quarter-wave estimate is 75 / 18.1 = 4.14 m, so the practical starting length is a little shorter.

The antenna still needs trimming and matching after installation.

### Worked example: VHF half-wave exam convention

A VHF half-wave vertical is estimated for 146 MHz using the Basic exam convention.

- Given: frequency = 146 MHz.
- Find: approximate half-wave length.
- Formula: half-wave length ≈ 150 / f(MHz).
- Substitute: length ≈ 150 / 146.
- Answer: length ≈ 1.03 m.
- Sanity check: this is a free-space half-wave convention, not a final construction drawing.

## Mobile verticals and loading coils

A mobile HF whip is often much shorter than a natural quarter wavelength. Electrically, that short conductor looks capacitive. A loading coil adds series inductance to tune out some of that capacitive reactance.

Compact loaded antennas may be narrow-band and less efficient than full-sized antennas. A five-eighths-wavelength VHF or UHF vertical can have more useful low-angle gain than a quarter-wave vertical, but it usually needs matching.

## Try it

1. A Yagi's elements are horizontal. What polarization should you expect? Horizontal, because polarization follows element orientation.
2. Which parasitic element is a little shorter than the driven element and placed toward the desired signal direction? The director.
3. Which parasitic element is a little longer than the driven element and sits behind it? The reflector.
4. A stacked pair of identical antennas is compared with one antenna before real-world losses. What ideal gain change is expected? About 3 dB, because the main-direction power density roughly doubles when the combined pattern is concentrated.
5. A quarter-wave vertical is planned for 25 MHz. Which practical starting length should you use? Use 71.3 / 25 = 2.85 m; 75 / 25 = 3.0 m is the free-space quarter-wave check.

## Radio connection

When you rotate a Yagi, you rotate the main lobe of its pattern. That can improve a desired station and reduce interference from another direction. When you add radials to a vertical, you improve the return path so less power is wasted in the earth.

## Common mistakes

- Thinking antenna gain means an amplifier has been added.
- Confusing bandwidth with beamwidth.
- Swapping the jobs of director and reflector.
- Treating every Yagi with the same number of elements as if it had identical gain.
- Forgetting that stacking concentrates the pattern; it does not create transmitter power.
- Forgetting that a short mobile HF antenna usually needs loading and has tradeoffs.

## Illustration brief

Alt text: Top view of a three-element Yagi with a long reflector, driven element, and shorter director on a boom, plus a forward-arrow main lobe.

Description: Draw a brush-style top view. Label the rear element "reflector, slightly longer," the middle element "driven, feedline here," and the front element "director, slightly shorter." Add a bold arrow labelled "main lobe" pointing from reflector through director. Include a small vertical antenna with downward-sloping radials and the formula 71.3 / f(MHz).

## Summary

- Gain describes concentration compared with a reference antenna.
- A parasitic element is energized by nearby RF fields, not by a direct feedline connection.
- Directors are slightly shorter; reflectors are slightly longer, and wider spacing can raise gain.
- A driven-element, reflector, and director Yagi spacing near 0.2 λ, or a fifth of a wavelength, is the Basic-bank convention for balancing forward gain and rear rejection.
- Use about 143 / f(MHz) for practical HF half-wave estimates and 71.3 / f(MHz) for practical HF quarter-wave estimates.
- A quarter-wave vertical is horizontally omnidirectional because it is symmetric around its upright axis.
- Some VHF half-wave vertical exam items use 150 / f(MHz) as the stated convention.
- Radials reduce ground losses and can help a vertical feed point approach common coax impedances.
