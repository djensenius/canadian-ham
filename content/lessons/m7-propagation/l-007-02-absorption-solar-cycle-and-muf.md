---
type: lesson
id: L-007-02
moduleId: M7
categoryIds:
  - B-007
title:
  en: "Absorption, solar cycle, and usable frequencies"
  fr: null
covers:
  - B-007-004
  - B-007-005
  - B-007-006
objectives:
  - "Describe daytime absorption and multipath fading."
  - "Relate sunspots and solar flux to ionization."
  - "Use MUF, critical frequency, and LUF as planning concepts."
prerequisites:
  - L-007-01
estimatedMinutes: 45
quizIds:
  - QZ-L-007-02-A
status: draft
---
# Absorption, solar cycle, and usable frequencies

HF propagation changes because the ionosphere changes. Sunlight can make the upper atmosphere more useful for long paths, while the lower daylight ionosphere can soak up energy on lower HF bands. The same signal can also arrive over several paths and fade as those paths add or cancel at the receiver.

This lesson gives you the vocabulary to read a propagation forecast without treating it as a promise. The goal is to choose a workable band and to know what to try when conditions change.

## Learning objectives

By the end of this lesson, you can:

- explain why lower HF bands are harder for long paths during daylight;
- describe multipath fading and selective fading;
- relate sunspots, solar flux, and the solar cycle to ionization;
- distinguish critical frequency, maximum usable frequency, lowest usable frequency, and optimum working frequency; and
- choose a sensible next band when absorption or MUF changes affect a contact.

## Absorption and fading

The D region is the usual daylight troublemaker for lower HF. A lower-frequency HF wave may be absorbed before enough energy reaches a higher region and returns. That is why lower HF and medium-frequency signals often improve after sunset, when the D region weakens.

Fading can happen even when the band is open. A signal may arrive by more than one path: perhaps a shorter hop and a longer hop, or different parts of a broad wavefront. If those components arrive with different phase, they can partly cancel. When the cancellation affects some audio frequencies or parts of a wider signal more than others, the result is selective fading and distortion.

On VHF and UHF, moving a handheld a small distance in a city can change the received signal dramatically. Reflections from walls, vehicles, and metal structures create multiple paths, so the signal strength can vary over a distance smaller than the operator's stride.

### Worked example: a fading voice signal

During an evening HF net, a station's signal is readable for a minute, then becomes hollow and weak, then returns. The operator at the receiver hears no local noise burst and sees no loose cable. A likely explanation is multipath fading: components of the same transmission are arriving with changing phase relationships as the ionosphere moves.

## Solar activity and the solar cycle

Sunspots are visible signs of solar magnetic activity. More sunspots usually mean more extreme-ultraviolet and related radiation that can increase ionization in the upper atmosphere. That tends to raise usable HF frequencies and can make higher HF bands more productive.

Solar flux is a measured radio-frequency output from the Sun and is used as a practical indicator of solar activity. A higher solar-flux value often goes with stronger ionization, though forecasts must still account for geomagnetic disturbance, time of day, season, and path direction.

The solar cycle rises and falls over about a decade. Near a strong high part of the cycle, upper HF and sometimes the lower edge of VHF can produce exciting long-distance openings. Near a low part of the cycle, lower HF may still work well, but higher HF bands may be quiet for long periods.

### Worked example: alternate band plans for a route

A station wants an afternoon contact across the continent. In a low-activity month, the operator starts on a mid-HF band and keeps a lower band ready for evening. In a high-activity month, the operator also checks a higher HF band because the ionosphere may support a higher frequency. The route is the same, but the Sun changed the menu of likely bands.

## MUF, LUF, critical frequency, and OWF

Critical frequency is measured for a region using a signal sent straight upward. It is the highest frequency that region can return for that vertical-incidence test at that moment.

Maximum usable frequency, or MUF, is path-specific. It means the highest frequency expected to support communication between two chosen places over a chosen ionospheric path. A signal sent at an oblique angle can work on a frequency above the local vertical critical frequency because the slanted path spends more distance in the refracting region.

Lowest usable frequency, or LUF, is the low-frequency limit set mainly by absorption and required signal strength. If a frequency is below the LUF, too much energy is lost or the received signal is not usable.

Optimum working frequency, or OWF, is the practical choice a little below the MUF. Accessible text formula: choose a working frequency below the MUF but above the LUF. Too high may pass through; too low may be absorbed.

### Worked example: picking a working frequency

A forecast for a coastal-to-prairie path suggests the LUF is near 5.8 MHz and the MUF is near 18.6 MHz during the afternoon. A voice operator chooses a band in the middle part of that window rather than parking exactly at the top edge. If fading or absorption appears, the operator can test a nearby lower or higher band and compare actual signals.

## What to try when a path fails

When a lower HF band is poor in bright daylight, try a higher HF band if the path and licence privileges allow it. The higher frequency may suffer less D-region absorption while still being below the MUF. If a high band suddenly stops supporting the path, try a lower band because the MUF may have fallen.

During a sudden ionospheric disturbance, lower HF can be heavily absorbed on sunlit paths. The practical response is not to change sideband or blame microphone gain; it is to try a higher frequency or wait for the disturbance to pass.

Beacons and known broadcast or time-signal stations are useful clues. If signals near the frequency you want are being heard from the right direction, the band may be open. If they are absent, the path may still be closed or too weak for your station.

## Try it

1. A daytime regional net on a low HF band becomes weak and noisy, but a higher HF band is active. What should the net control try? Move to the higher suitable band, because daylight lower-ionosphere absorption is often worse on the lower HF band.
2. A wide digital signal sounds distorted while a narrow Morse signal on the same path remains copyable. What propagation effect might be stronger for the wider signal? Selective fading, because different frequency components can be affected differently by multipath.
3. A forecast says the path MUF is below the band you planned to use. Should you add power or choose another band first? Choose a lower suitable band first; power does not make a too-high frequency refract back.
4. A vertical ionosonde measurement is lower than a working long-distance frequency. How can the long-distance contact still happen? The long-distance signal enters at an oblique angle, so its path can support a frequency above the vertical critical-frequency measurement.
5. A solar-cycle high arrives and higher HF bands become lively. What changed physically? Greater solar activity increased ionization enough to support higher usable frequencies on some paths.

## Radio connection

Propagation reports are tools for deciding what to try first. MUF, LUF, solar flux, and sunspot numbers guide your plan, but your receiver gives the final evidence. Tune for beacons, check the noise floor, listen for other stations on the same path, and be ready to move.

For contesting and emergency exercises alike, the best operator is flexible. When a band closes, record what happened, try a band with a better reason to work, and keep the antenna and radio settings simple enough that you know the propagation changed rather than the station failing.

## Common mistakes

- Treating MUF as a guaranteed contact frequency instead of an upper limit for a particular path.
- Forgetting that LUF matters; a frequency can be too low because absorption wins.
- Assuming the Sun only matters during rare storms, even though daily radiation drives ordinary ionization.
- Blaming sideband selection for a propagation blackout.
- Confusing selective fading with ordinary low audio volume or a misadjusted squelch.

## Illustration brief

Alt text: Daytime HF path diagram with D-region absorption, F-region refraction, and a frequency window labelled LUF below and MUF above.

Description: Draw two panels. In the first, show the Sun lighting the lower ionosphere, with a thick D-region band absorbing a low-frequency HF ray and a higher-frequency HF ray reaching the F region. In the second, draw a horizontal frequency line labelled "too low: absorbed," "usable window," and "too high: passes through." Mark LUF at the lower edge, OWF inside the window, and MUF at the upper edge.

## Summary

- The D region often absorbs lower HF energy during daylight.
- Multipath propagation can cause fading, selective fading, and phase distortion.
- More sunspots and higher solar flux usually indicate stronger ionization and higher usable HF frequencies.
- Critical frequency is a vertical-incidence measurement; MUF is for a particular path.
- A practical working frequency is below the MUF and above the LUF.
- When propagation changes, changing band is often more useful than changing audio settings or adding power.
