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
prerequisites: []
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

A ground wave is the part of a signal that follows the Earth's surface and is affected by it. Ground wave matters most at lower frequencies. The lower the frequency, the farther the ground wave can usually travel. On lower HF in daytime, it can reach around 200 km when conditions and antennas cooperate.

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

Amateur band names often use an approximate wavelength in metres. The ISED exam reference sheet gives wavelength in metres = 300 / frequency in MHz, and frequency in MHz = 300 / wavelength in metres. Use the table as a compact reference, not as a full band-plan chart.

| Name | Quick frequency reference | Why it matters here |
|---|---|---|
| 160 m | About 1.8 MHz to 2.0 MHz | Lowest-frequency amateur band in this group, with the best ground-wave reach |
| 80 m | About 3.5 MHz to 4.0 MHz | Lower HF, strongly affected by daytime D-region absorption |
| 40 m | About 7 MHz | Below the 31 m shortwave broadcast band |
| 31 m broadcast | About 9.7 MHz by 300 / 31 | Sits between 40 m and 30 m receiver coverage |
| 30 m | About 10.1 MHz | Above the 31 m broadcast band |
| 20 m | About 14 MHz | A daylight HF planning anchor |
| 15 m | About 21 MHz | Harmonics can land in VHF television ranges |
| 10 m | About 28 MHz | Use 10 m beacons when checking a 28 MHz path |

## Skip distance and skip zone

Skip distance is the distance from the transmitter to the closest point reached by a returning sky wave on a chosen path. The skip zone is the gap after useful ground-wave coverage fades out but before the first sky-wave return point.

Hop length is the distance covered by a sky-wave return. After the wave reaches Earth, some energy may reflect from the surface and go up again for another hop. Long HF contacts often use several hops.

Typical upper single-hop scales are about 2 000 km for an E-region return and about 4 000 km for an F2-region return. E is lower, so its single-hop path is shorter. A longer route may need more hops or a different time or band.

Geometry ideas matter:

- A higher refracting region puts the first return point farther away for the same launch angle.
- A lower antenna launch angle puts the first return point farther away for the same layer height.

Accessible text formula: lower launch angle plus similar layer height means longer skip distance. Higher launch angle plus similar layer height means shorter skip distance. This is geometry, not a power rule.

### Worked example: comparing hop scales

A field station needs to report expected coverage to a served agency. A route is about 5 000 km.

- Given: route distance = 5 000 km; F2 single-hop planning scale = about 4 000 km.
- Find: whether a single F2 hop is enough on paper.
- Formula: hops must cover the route distance.
- Substitute: a single F2 hop is about 4 000 km, which is less than 5 000 km.
- Answer: plan for a multi-hop path if HF conditions support it.
- Sanity check: extra hops add surface returns and loss, so conditions and antennas still matter.

For a mid-distance check-in area, an E-region return has a shorter single-hop planning scale, up to about 2 000 km in good conditions. The actual opening still depends on frequency, time, and ionization.

### Misconception: more power fills the skip zone

- Mistaken idea: raising transmitter power will fill every gap between ground wave and the first sky-wave return.
- Correction: a skip zone is mainly a path-geometry problem. A different band, time, relay, or antenna angle is often more useful.

## Try it

1. A club moves a VHF antenna from a low parking lot to a clear mast on a nearby building, and the same radios cover more of town. Explain the planning lesson. Extra height and a clearer path improve the radio horizon; the radios did not make the ionosphere return the signal.
2. An HF net wants regional coverage over rough terrain rather than an overseas contact. What antenna-angle tradeoff should it favour? Favour higher-angle radiation when conditions suit it, because the goal is a closer regional return.
3. In a layer diagram, a wave passes through D and bends back from a much higher region. What concern belongs to the lower layer? Daylight absorption in the lower ionosphere can weaken the signal before it reaches the useful refracting region.
4. A route map shows reliable reports close to the transmitter and again much farther out, but very few in the middle. What planning step should net control take? Plan an alternate band, relay, or antenna angle instead of assuming extra power will fill the gap.
5. A trainee draws an HF sky-wave path as a sharp bounce from a shiny ceiling above Earth. What wording should the caption use instead? Show gradual refraction through an ionized region; skip describes where the signal returns, not a metal-like reflection.

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
