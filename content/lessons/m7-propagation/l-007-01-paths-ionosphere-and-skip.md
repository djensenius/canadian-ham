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

Radio waves do not all travel the same way. A nearby handheld signal may travel almost directly from antenna to antenna. A lower-frequency HF signal may cling to the ground for a while. Another HF signal may leave the antenna, bend through an ionized upper-atmosphere region, and arrive well beyond the local horizon.

Propagation is the name for all of those travel behaviours. Learning propagation does not let you guarantee a contact, but it helps you choose a band, antenna angle, time of day, and expectation that fit the path you are trying to use.

## Learning objectives

By the end of this lesson, you can:

- compare direct, ground-wave, sky-wave, and NVIS paths;
- describe how sunlight creates ionized regions above the lower atmosphere;
- arrange the D, E, F1, and F2 regions from lower to higher altitude;
- explain skip distance, skip zone, and hop length in plain language; and
- predict how antenna radiation angle and refracting-region height change the first return point.

## The main radio paths

Line-of-sight communication is the simplest picture: one antenna can "see" the other well enough for the radio wave to travel through the lower atmosphere. VHF and UHF work this way most of the time. The radio horizon is a little farther than the visible horizon because normal bending in the troposphere nudges the path downward.

A ground wave is the part of a signal that is guided by, and affected by, the surface of the Earth. It is most important at lower frequencies. As frequency increases, ground-wave range becomes less useful, so a station on the lower HF bands may have a ground-wave path that a much higher band would not provide.

A sky wave is an HF signal that goes upward and is refracted by the ionosphere so it returns to Earth. The ionosphere is not a shiny mirror; the bending is gradual. Operators still use everyday words such as "skip" because the result looks like the signal skipped over part of the ground before coming back down.

Near vertical incidence sky wave, usually called NVIS, uses a high-angle HF signal. Instead of trying for a distant low-angle hop, the station sends much of its energy upward so it returns over a regional area. NVIS can help with hilly or forested terrain where direct VHF paths are blocked, but it still depends on band choice and ionospheric conditions.

### Worked example: choosing the path first

A volunteer group wants to link a valley shelter, a ridge-top control point, and a town hall. The ridge can hear both sites on VHF, but the valley and town cannot hear each other directly. The planners choose VHF through the ridge for local tactical messages and add an HF NVIS circuit for a regional backup. The two choices are not competing answers; they serve different path shapes.

## The ionosphere in layers

The ionosphere forms when solar radiation removes electrons from atoms and molecules in the upper atmosphere. The result is a region with enough charged particles to affect radio waves. It changes with sunlight, season, solar activity, and time of day.

The usual beginner picture has these regions, from lower to higher:

- D region: lowest, present mainly in daylight, and often more important for absorption than for useful long-range return;
- E region: above D, involved in some ordinary refraction and in special events such as sporadic E;
- F region: above E, the main long-distance HF region; and
- F1 and F2: daytime sub-regions of F, with F2 higher and especially important for long paths.

At night the lower regions weaken quickly and the F region becomes less split. Shortly before sunrise, ionization is often near its daily low because the night has allowed many charged particles to recombine.

### Worked example: reading a layer sketch

Imagine a side-view drawing with the ground at the bottom and four labels above it: D, E, F1, and F2. A low HF signal that must pass through D before reaching F can lose energy in the lower layer. A higher-angle NVIS signal that reaches a useful F-region condition may return much closer to the transmitter than a low-angle DX signal.

## Skip distance and skip zone

Skip distance is the distance from the transmitter to the closest point reached by a returning sky wave for a chosen path. The skip zone is the gap after useful ground-wave coverage fades out but before that first sky-wave return point.

Hop length is the distance covered by a single sky-wave return. After the wave reaches Earth, some energy may reflect from the surface and go up again for another hop. Long HF contacts often use multiple hops, especially when a single return is not enough to cover the route.

A pair of geometry ideas matter:

- If the refracting region is higher, the first return point is farther away for the same launch angle.
- If the antenna launches at a lower angle above the ground, the first return point is farther away for the same layer height.

Accessible text formula: lower launch angle plus similar layer height means longer skip distance; higher launch angle plus similar layer height means shorter skip distance. That is a geometry statement, not a transmitter-power statement.

### Worked example: comparing two launch angles

A portable dipole is first hung low over a field and sends much of its HF energy upward. The first strong return is regional. Later the same operator uses a higher support and a sloping end that favours lower-angle radiation. The more shallow path reaches farther before returning. The transmitter power did not create the change; the path angle did.

## Try it

1. A club can work a repeater from both ends of a town, but simplex between two hand-held radios fails behind a hill. Which path limit are they seeing? They are seeing a mostly line-of-sight VHF limit; the hill blocks the direct path even though the repeater site has a better view.
2. An HF net wants regional coverage over rough terrain rather than an overseas contact. What radiation angle should the antenna system favour? A higher radiation angle supports NVIS-style regional coverage when the band conditions suit it.
3. In a layer diagram, a wave passes the D region and bends back from a much higher region. What practical concern belongs to the lower layer? Daylight absorption in the lower ionosphere can weaken the signal before it reaches the useful refracting region.
4. A sky-wave signal returns beyond nearby towns, leaving a gap after local coverage. What is that gap called? It is the skip zone, the area too far for the fading ground wave but too close for the first returning sky wave.
5. If the same HF antenna changes from high-angle to lower-angle radiation, what happens to the first return point? It moves farther away because the shallower path intersects the refracting region and Earth at a longer distance.

## Radio connection

Propagation choices turn abstract layers into practical operating. Before calling a net, ask: is this a nearby VHF line-of-sight path, a regional HF path, or a long-distance HF path? Then choose the band and antenna style that match that path. When a station is in the skip zone, adding power may not help much; changing band, time, or antenna angle often matters more.

For emergency practice, avoid promising that any mode is automatic. NVIS, repeaters, ground wave, and long-hop HF are tools. Conditions decide which tool works today.

## Common mistakes

- Treating the ionosphere as a hard mirror instead of a region that gradually refracts radio waves.
- Assuming more transmitter power eliminates a skip zone.
- Confusing ground wave with sky wave just because both can be heard beyond the visible horizon.
- Forgetting that the D region is lower than E and F and often causes loss rather than useful long-distance return.
- Calling every VHF opening "skip" when ordinary line-of-sight or tropospheric bending may be enough to explain it.

## Illustration brief

Alt text: Side-view Earth diagram showing direct VHF, ground wave, NVIS, and low-angle sky-wave paths through labelled D, E, F1, and F2 regions.

Description: Draw a gentle curved Earth at the bottom with three stations. Show a short VHF ray between two visible hilltops, a surface-hugging ground wave fading with distance, a steep NVIS ray returning nearby, and a shallow sky-wave ray returning farther away. Above the Earth, label the ionospheric regions in order as D, E, F1, and F2. Mark a bracket for the skip zone between the end of ground-wave coverage and the first sky-wave return.

## Summary

- VHF and UHF usually rely on line-of-sight paths, with the radio horizon slightly beyond the visual horizon.
- Ground wave is affected by the Earth's surface and is most useful at lower frequencies.
- Sky wave is HF energy refracted by the ionosphere back toward Earth.
- Solar radiation creates ionization; the D, E, F1, and F2 regions have different effects.
- Skip distance is the first sky-wave return distance, and the skip zone is the uncovered gap before that return.
- Layer height and launch angle set skip geometry more directly than transmitter power does.
