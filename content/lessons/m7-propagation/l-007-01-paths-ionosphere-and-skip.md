---
type: lesson
id: L-007-01
moduleId: M7
categoryIds:
  - B-007
title:
  en: "Wave paths, ionosphere, and skip"
  fr: null
covers:
  - B-007-001
  - B-007-002
  - B-007-003
objectives:
  - "Compare ground wave, sky wave, line-of-sight, and NVIS paths."
  - "Name ionospheric regions and what creates ionization."
  - "Explain skip distance, skip zone, and hop length."
prerequisites:
  - L-006-03
estimatedMinutes: 40
quizIds:
  - QZ-L-007-01-A
status: draft
---
# Wave paths, ionosphere, and skip

Radio waves do not all travel the same way. A nearby handheld signal may travel almost straight from antenna to antenna. A lower-frequency HF signal can also follow the ground for a while or bend through the ionosphere and return far away.

Propagation means the way a radio wave travels. It does not guarantee a contact. It helps you choose a band, antenna angle, time of day, and backup path.

## Learning objectives

By the end of this lesson, you can:

- compare direct, ground-wave, sky-wave, and NVIS paths;
- describe how sunlight creates ionized regions above the lower atmosphere;
- arrange the D, E, F1, and F2 regions from lower to higher altitude;
- explain skip distance, skip zone, and hop length in plain language; and
- predict how antenna angle and ionosphere height change the first return point.

## The main radio paths

Line-of-sight communication is the simplest path. One antenna has a clear enough view of the other for the radio wave to travel through the lower atmosphere. VHF and UHF use this path most of the time.

The radio horizon sits a little beyond what your eyes can see. The reason is ordinary bending through the troposphere, the lower atmosphere where weather happens.

A ground wave is the part of a signal that follows the Earth's surface and is affected by it. Ground wave matters most at lower frequencies. In daytime, the D region absorbs much of the lower-HF sky wave, so ground wave is what makes many regional contacts out to roughly 200 km possible when conditions and antennas cooperate. Near-vertical sky wave can also cover that range when the frequency is low enough, as described below.

A sky wave, also called an ionospheric wave, goes upward and is refracted by the ionosphere. The ionosphere is an ionized upper-atmosphere region with charged particles that affect radio waves. It is not a hard mirror; it bends the wave gradually. Exams and operators may still say a sky wave is reflected by the ionosphere as shorthand for the returned path.

Near vertical incidence sky wave, or NVIS, uses a high-angle HF signal from a low horizontal antenna. The signal goes mostly upward and returns over a regional area. Because the path is nearly vertical, NVIS needs a frequency below the critical frequency that the next lesson defines. NVIS can help in hilly or forested terrain, but it still depends on band choice and ionospheric conditions.

### In the real world: valley, ridge, and town

A volunteer group needs links between a valley shelter, a ridge control point, and a town hall. The ridge can hear both sites on VHF, but the valley and town cannot hear each other directly.

The planners use VHF through the ridge for local traffic. They add an HF NVIS circuit as a regional backup. The two paths solve different problems.

### In the real world: choosing a path before adding power

A club tries to link two low sites across town. Handheld VHF fails because buildings and a ridge block the direct path. A repeater site, a relay station, or a regional HF path may solve the problem better than extra handheld power.

## The ionosphere in layers

The ionosphere forms when solar radiation removes electrons from atoms and molecules in the upper atmosphere. Ultraviolet radiation is especially important. The ionized region changes with sunlight, season, solar activity, and time of day.

Daily ionization is usually strongest around midday. It is often weakest shortly before sunrise because the night gives charged particles time to recombine.

The usual beginner picture has these regions, from lower to higher:

- D region: lowest, mainly a daylight absorber on lower HF;
- E region: above D, involved in some ordinary refraction and sporadic E openings;
- F region: above E, the main long-distance HF region; and
- F1 and F2: daytime parts of F, with F2 higher and important for the longest paths.

At night the lower regions weaken quickly, and daytime F1 and F2 merge toward one F region. A lower HF signal often works better after dark because it loses less energy in the D region before reaching a higher region.

### Memory trick: D, E, F climb upward

- Helps remember: D is lowest, then E, then F.
- Trick: read the letters in alphabet order as you climb away from Earth.
- Limit: the trick gives the order only. It does not tell you which band will work today.

### Memory trick: D is for daytime damping

- Helps remember: the D region often absorbs lower-frequency HF in daylight.
- Trick: D can stand for daytime and damping.
- Limit: the D region is not the useful long-distance return layer.

### In the real world: reading a layer sketch

Imagine a side-view drawing with the ground at the bottom and four labels above it: D, E, F1, and F2. A lower HF signal must pass through D before reaching F. In daylight, that lower layer can remove a lot of energy.

A high-angle NVIS signal that reaches useful F-region conditions may return close to the transmitter. A low-angle DX signal from the same site may return much farther away.

## Reflection, refraction, diffraction, and scattering

These four words are close, but they describe different effects.

| Word | Plain meaning | Propagation use |
|---|---|---|
| Reflection | A wave changes direction at a boundary | Part of a sky wave can leave the ground and head upward again for another hop |
| Refraction | A wave bends gradually while travelling through a changing medium | The ionosphere returns many sky-wave paths by gradual bending |
| Diffraction | A wave bends around an edge or obstacle | Lower-frequency ground waves can follow terrain better than higher-frequency waves |
| Scattering | Small pieces of a wave are redirected in many directions | Weak scatter can be heard from places that are not on the main returned path |

## Band names and quick frequency estimates

Amateur band names often use an approximate wavelength in metres. The ISED exam reference sheet gives wavelength in metres = 300 / frequency in MHz, and frequency in MHz = 300 / wavelength in metres. The name is only approximate: the rule gives 15 MHz for a 20 m wavelength, but the amateur band is near 14 MHz. Use real band frequencies for harmonic checks.

### HF and shortwave references

Use this table as a compact reference, not as a full band-plan chart.

| Name | Quick frequency reference | Why it matters here |
|---|---|---|
| 160 m | About 1.8 MHz to 2.0 MHz | Lowest-frequency amateur band in this group, with the best ground-wave reach |
| 80 m | About 3.5 MHz to 4.0 MHz | Lower HF, strongly affected by daytime D-region absorption |
| 40 m | About 7 MHz | Below the 31 m shortwave broadcast band |
| 31 m broadcast | About 9.7 MHz by 300 / 31 | Shortwave broadcast band between the 40 m and 30 m amateur bands; receive-only context for amateurs |
| 30 m | About 10.1 MHz | Above the 31 m broadcast band |
| 20 m | About 14 MHz | A daylight HF planning anchor |
| 17 m | 18.068 MHz to 18.168 MHz | Useful when comparing a forecast window with real amateur bands |
| 15 m | About 21 MHz | Upper-HF band that opens more readily near solar maximum |
| 12 m | 24.890 MHz to 24.990 MHz | Another upper-HF band that can open during higher solar activity |
| 10 m | About 28 MHz | High-HF band often checked with same-band beacons |

### VHF and UHF references

| Name | Quick frequency reference | Why it matters here |
|---|---|---|
| 6 m | 50 MHz to 54 MHz | Classic amateur band for sporadic E |
| 2 m | 144 MHz to 148 MHz | Common VHF local and repeater band |
| 70 cm | 430 MHz to 450 MHz | Common UHF local and repeater band |

### Faded practice: finish a rough wave-label estimate

Use a hypothetical wavelength label to practise the shortcut, not to select a transmit frequency.

- Given: wavelength = 54 m.
- Find: approximate frequency in megahertz.
- Formula: f(MHz) = 300 / wavelength(m).
- Complete: f ≈ 300 / ___ ≈ ___ MHz.
- Sanity check: Is a larger wavelength label associated with a lower frequency?

Fill the gaps before checking below.

### Check your work: finish a rough wave-label estimate

f ≈ 5.56 MHz. Real amateur band names are rounded labels; look up actual band frequencies and privileges before operating.

::figure propagation-paths-skip-zone
Alt text: Side-view Earth diagram showing VHF direct, ground wave, NVIS, and low-angle sky-wave paths through labelled D, E, F1, and F2 regions.
Text equivalent:
- The ionosphere labels climb upward as D, E, F1, and F2.
- A VHF direct path runs between two hilltops.
- A ground-wave path follows the Earth and fades after a short distance.
- A steep NVIS path rises to the F-region area and returns nearby.
- A lower-angle sky-wave path rises to the F-region area and returns much farther away; a skip-zone bracket is shown for that low-angle path.
::

## Skip distance and skip zone

Skip distance is the distance from the transmitter to the closest point reached by a returning sky wave on a chosen path. The skip zone is the gap after useful ground-wave coverage fades out but before the first sky-wave return point.

Hop length is the distance covered by a sky-wave return. After the wave reaches Earth, some energy may reflect from the surface and go up again for another hop. Long HF contacts often use several hops.

Typical upper single-hop scales are about 2 000 km for an E-region return and about 4 000 km for an F2-region return. E is lower, so its single-hop path is shorter. A longer route may need more hops or a different time or band.

Geometry ideas matter:

- A higher refracting region puts the first return point farther away for the same launch angle.
- A lower antenna launch angle puts the first return point farther away for the same layer height.

Accessible text formula: lower launch angle plus similar layer height means longer skip distance. Higher launch angle plus similar layer height means shorter skip distance. This is geometry, not a power rule.

### Worked example: comparing hop scales

A field station needs to report expected coverage to a served agency. A route is about 9 000 km.

- Given: route distance = 9 000 km; F2 single-hop planning scale = about 4 000 km.
- Find: whether a single F2 hop is enough on paper.
- Formula: hops must cover the route distance.
- Substitute: even two F2-scale hops are about 8 000 km, which is less than 9 000 km.
- Answer: plan for several hops if HF conditions support the route.
- Sanity check: extra hops add surface returns and loss, so conditions and antennas still matter.

For a mid-distance check-in area, an E-region return has a shorter single-hop planning scale, up to about 2 000 km in good conditions. The actual opening still depends on frequency, time, and ionization.

### Faded practice: finish a hop-scale comparison

Compare distance scales on paper before considering whether the path is open.

- Given: route = 7 200 km; F2 single-hop scale ≈ 4 000 km.
- Find: whether a single hop or a pair has enough planning distance.
- Formula: compare route length with the sum of the hop scales.
- Complete: a single F2 scale covers 4 000 km; a pair covers ___ + ___ = ___ km, so the route needs at least ___ hops on this simple plan.
- Sanity check: Does enough distance on paper prove that usable propagation exists?

Fill the gaps before checking below.

### Check your work: finish a hop-scale comparison

A pair covers about 8 000 km, so the simple plan needs at least two hops. Real ionization, angles, surface returns, and losses still decide whether signals arrive.

### Misconception: more power fills the skip zone

- Mistaken idea: raising transmitter power will fill every gap between ground wave and the first sky-wave return.
- Correction: a skip zone is mainly a path-geometry problem. A different band, time, relay, or antenna angle is often more useful.

## Try it

Try these before reading the feedback below.

1. A VHF antenna moves from a low parking lot to a clear mast. The same radios now cover more of town. Explain the planning lesson.

:::answer
Height and a clearer path improve ordinary radio-horizon coverage; the radios did not make the ionosphere return VHF.
:::

2. An HF net needs regional coverage over rough terrain rather than an overseas contact. What antenna-angle tradeoff fits?

:::answer
Favour higher-angle radiation when frequency and ionospheric conditions support a closer regional return.
:::

3. A layer sketch shows a wave passing through D before bending back from a higher region. What concern belongs to D?

:::answer
Daylight absorption in D can weaken the wave before it reaches the useful refracting region.
:::

4. Reports are reliable close to a transmitter and far away, with few in the middle. What should net control plan?

:::answer
Arrange an alternate band, relay, or antenna angle rather than assuming more power fills the gap.
:::

5. A trainee draws sky wave as a sharp bounce from a shiny ceiling. How should the caption explain it instead?

:::answer
Describe gradual refraction through an ionized region. Skip describes the return location, not a metal-like mirror.
:::

## Radio connection

Propagation choices turn layers into operating decisions. Before calling a net, ask whether the path is nearby VHF line of sight, regional HF, or long-distance HF. Then choose the band and antenna style that match that path.

When a station is in the skip zone, adding power may not help much. Changing band, time, relay point, or antenna angle often matters more.

For emergency practice, avoid promising that any mode is automatic. NVIS, repeaters, ground wave, and long-hop HF are tools. Conditions decide which tool works today.

## Common mistakes

- Treating the ionosphere as a hard metal-like mirror instead of a region that gradually refracts radio waves.
- Assuming more transmitter power eliminates a skip zone.
- Confusing ground wave with sky wave just because both can be heard beyond the visible horizon.
- Forgetting that the D region is lower than E and F and often causes loss rather than useful long-distance return.
- Calling every VHF opening "skip" when ordinary line of sight or tropospheric bending may explain it.

## Illustration brief

Alt text: Side-view Earth diagram showing direct VHF, ground wave, NVIS, and low-angle sky-wave paths through labelled D, E, F1, and F2 regions.

Description: Draw a gentle curved Earth at the bottom with three stations. Show a short VHF ray between two visible hilltops, a surface-hugging ground wave fading with distance, a steep NVIS ray returning nearby, and a shallow sky-wave ray returning farther away. Above the Earth, label the ionospheric regions in order as D, E, F1, and F2. Mark a bracket for the skip zone between the end of ground-wave coverage and the first sky-wave return.

## Summary

- VHF and UHF usually rely on line-of-sight paths, with the radio horizon slightly beyond the visual horizon.
- Ground wave follows and is affected by the Earth's surface, and it is most useful at lower frequencies.
- Sky wave, or ionospheric wave, is energy refracted by the ionosphere back toward Earth.
- Solar ultraviolet radiation is a major source of ionization; daily ionization is usually highest around midday and lowest shortly before sunrise.
- D, E, F1, and F2 are ordered upward, and the D region is often a daylight absorber on lower HF.
- Skip distance is the first sky-wave return distance, and the skip zone is the uncovered gap before that return.
- E-region single-hop paths are shorter than F2 single-hop paths; use about 2 000 km and about 4 000 km as planning scales.
- Layer height and launch angle set skip geometry more directly than transmitter power does.
