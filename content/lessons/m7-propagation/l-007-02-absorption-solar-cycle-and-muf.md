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

HF propagation changes because the ionosphere changes. Sunlight can make the upper atmosphere more useful for long paths. The lower daylight ionosphere can also soak up energy on lower HF bands.

The same signal can arrive over several paths and fade as those paths add or cancel at the receiver. This lesson gives you the words to read a propagation forecast without treating it as a promise.

## Learning objectives

By the end of this lesson, you can:

- explain why lower HF bands are harder for long paths during daylight;
- describe multipath fading and selective fading;
- relate sunspots, solar flux, and the solar cycle to ionization;
- distinguish critical frequency, maximum usable frequency, lowest usable frequency, and optimum working frequency; and
- choose a sensible next band when absorption or MUF changes affect a contact.

## Absorption and fading

The D region is the usual daylight troublemaker for lower HF. A lower-frequency HF wave may lose too much energy before it reaches a higher region and returns. That is why lower HF and medium-frequency signals often improve after sunset, when the D region weakens.

Fading can happen even when the band is open. A signal may arrive by a shorter hop and a longer hop at the same time. If those components arrive with different phase, they can partly cancel.

Different delays can also smear the signal's phase relationships. That can cause phase distortion, not just a change in strength.

Selective fading happens when those phase differences cancel some parts of the transmitted signal more than others. It can make a wider voice or data signal sound hollow, rough, or distorted.

On VHF and UHF, moving a handheld less than a metre in a city can change the received signal. Reflections from walls, vehicles, and metal structures create multiple paths. A small move can turn cancellation into reinforcement.

Polarization means the orientation of the radio wave's electric field. On VHF and UHF line-of-sight contacts, matching antenna polarization can make a large difference. On HF sky-wave paths, the ionosphere can rotate or otherwise change the wave's polarization as it refracts the signal.

Faraday rotation is that polarization twist as a wave travels through an ionized region in the Earth's magnetic field. Reflection can also change the arriving polarization.

### In the real world: why AM broadcast carries farther at night

AM broadcast stations are in the medium-frequency range, below the amateur HF bands. In daytime, the D region absorbs much of that lower-frequency sky-wave energy. The station may be heard mainly by ground wave.

After sunset, the D region weakens. Less energy is absorbed on the way up, so higher ionospheric regions can return some signals to Earth. That is why distant AM stations often appear at night.

### In the real world: fading in an evening net

During an evening HF net, a station is readable for a minute, then becomes hollow and weak, then returns. The receiver hears no local noise burst and the antenna connection is sound.

A likely explanation is multipath fading. Parts of the same transmission are arriving over changing paths as the ionosphere moves.

### Misconception: volume fixes propagation fading

- Mistaken idea: a louder speaker setting fixes a fading radio path.
- Correction: volume changes audio after reception. Fading happens before that, along the RF path.

## Solar activity and the solar cycle

Sunspots are visible signs of solar magnetic activity. More sunspots usually mean more ultraviolet (UV) and X-ray radiation that can increase ionization in the upper atmosphere. Day to day, both the Sun's electromagnetic radiation and its particle radiation shape the ionosphere. Storms such as coronal mass ejections are occasional disturbances on top of that.

Solar flux is radio-frequency energy from the Sun measured as a practical activity indicator. The common solar-flux index is measured at a fixed wavelength of 10.7 cm, or 2 800 MHz, so readings can be compared over time. In Canada, NRC reports solar radio flux from the Dominion Radio Astrophysical Observatory near Penticton, BC. A higher solar-flux value often goes with stronger ionization. Forecasts must still account for geomagnetic disturbance, time of day, season, and path direction.

The solar cycle rises and falls over an average of about 11 years. Near a strong high part of the cycle, upper HF and sometimes around 40 MHz or a little higher can produce long-distance openings. Near a low part, lower HF may still work well, but higher HF bands may be quiet for long periods.

The 20-metre band is a useful daylight planning anchor. It often supports worldwide propagation during low, middle, and high parts of the cycle because 14 MHz commonly stays below the daytime F2 MUF. The exact hours and paths still change.

### In the real world: a changing band menu

A station wants an afternoon contact across the continent. In a low-activity month, the operator starts on a mid-HF band and keeps a lower band ready for evening.

In a high-activity month, the operator also checks a higher HF band because the ionosphere may support it. The route is the same, but the Sun changed the menu of likely bands.

## MUF, LUF, critical frequency, and OWF

Critical frequency is measured with a signal sent straight upward. It is the highest frequency that an ionospheric region can return for that vertical test at that moment.

Maximum usable frequency, or MUF, is path-specific. It means the highest frequency expected to support communication between two chosen places over a chosen ionospheric path.

A signal sent at a slant can work above the local vertical critical frequency. A wave arriving at a shallow angle needs less bending to turn back, so the same layer can return a higher frequency than it returns for a straight-up test.

Lowest usable frequency, or LUF, is the low-frequency limit set mainly by absorption and needed signal strength. LUF is a planning term, not a Basic-bank definition. If a frequency is below the LUF, too much energy is lost or the received signal is not usable.

Optimum working frequency, or OWF, is the practical choice a little below the MUF. Accessible text formula: choose a working frequency below the MUF but above the LUF. Too high may pass through; too low may be absorbed.

::figure daytime-absorption-frequency-window
Alt text: Daytime HF path diagram with D-region absorption, F-region return, and a frequency window labelled LUF, OWF, and MUF.
Text equivalent:
- The left panel shows the Sun, a lower D band, and a higher F line.
- A lower HF ray stops at the D band beside the D absorbs label.
- A higher HF ray passes the D band, reaches the F line, and returns to Earth.
- The right panel marks LUF at the lower edge of the usable window, OWF closer to MUF, and MUF at the upper edge.
- Frequencies below the window are labelled too low and absorbed; frequencies above it are labelled too high and through.
::

### Worked example: picking a working frequency

A forecast for a coastal-to-prairie path suggests the LUF is near 5.8 MHz and the MUF is near 18.6 MHz during the afternoon. A common planning estimate for OWF is about 85 % of the MUF.

- Given: MUF = 18.6 MHz; planning factor = 85 % = 0.85.
- Find: estimated OWF.
- Formula: OWF = MUF x 0.85.
- Substitute: OWF = 18.6 MHz x 0.85.
- Answer: OWF = 15.8 MHz, rounded to one decimal place.
- Sanity check: 15.8 MHz is below the MUF and above the example LUF.

The 20-metre band is comfortably inside that usable window. The 17-metre band is closer to the upper edge. A voice operator would start with a real band inside the window rather than park at the top edge.

### Faded practice: finish an OWF planning check

Use the planning factor, then check the whole usable window.

- Given: path MUF = 23.4 MHz; LUF = 6.8 MHz; planning factor = 85 % = 0.85.
- Find: estimated OWF and whether it lies inside the forecast window.
- Formula: estimated OWF = MUF x 0.85.
- Complete: OWF ≈ 23.4 x ___ = ___ MHz; compare that with ___ MHz at the lower edge and ___ MHz at the upper edge.
- Sanity check: Is the result below MUF and above LUF?

Fill the gaps before checking below.

### Check your work: finish an OWF planning check

OWF ≈ 19.89 MHz, or about 19.9 MHz. It lies between 6.8 and 23.4 MHz. This is a planning target, not an assigned channel; choose a permitted real band and verify conditions.

## What to try when a path fails

When a lower HF band is poor in bright daylight, try a higher HF band if the path and licence privileges allow it. The higher frequency may suffer less D-region absorption while still being below the MUF. If a high band suddenly stops supporting the path, try a lower band because the MUF may have fallen.

Season changes the low bands too. Summer daylight is usually hardest on 160 and 80 metres for sky-wave paths beyond ground-wave range because long daylight and stronger D-region absorption reduce sky-wave usefulness. Winter evenings are often friendlier because darkness weakens the D region.

During a sudden ionospheric disturbance, a solar flare's X-rays can quickly increase D-region absorption on sunlit paths. Lower HF usually suffers most. The practical response is not to change sideband or blame microphone gain. Try a higher frequency or wait for the disturbance to pass.

Use evidence from the band you want to use. A beacon in that same amateur band and from the right direction is useful evidence. Signals on other bands or far-away time-signal frequencies do not prove that your planned path is open.

## Try it

Try these before reading the feedback below.

1. Microphone gain fails to improve a sunlit low-band path. Why would an RF planning change help more?

:::answer
Daylight lower-ionosphere absorption acts before audio controls matter. A suitable band or time addresses the path.
:::

2. A wide digital signal sounds distorted while a narrow signal remains copyable on the same path. What might help?

:::answer
Try a narrower mode or bandwidth. Multipath can affect different parts of a wide signal unequally.
:::

3. The path MUF falls below the planned band. Why is more transmitter power insufficient?

:::answer
More power does not raise the path frequency limit. Try a suitable lower band.
:::

4. With LUF 5.8 MHz and MUF 18.6 MHz, compare 20 metres and 17 metres as first attempts.

:::answer
Both are inside the window. Twenty metres is the more conservative first try near the OWF estimate; 17 metres is closer to the upper edge and may fail sooner if MUF falls.
:::

5. Higher HF bands become lively near a solar-cycle high. What changed physically?

:::answer
Greater solar activity increased ionization enough to support higher usable frequencies on some paths.
:::

## Radio connection

Propagation reports are tools for deciding what to try first. MUF, LUF, solar flux, and sunspot numbers guide your plan, but your receiver gives the final evidence. Tune for beacons, check the noise floor, listen for other stations on the same path, and be ready to move.

For contesting and emergency exercises alike, the best operator is flexible. When a band closes, record what happened, try a band with a better reason to work, and keep the station settings simple enough that you know propagation changed rather than the station failing.

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

- The D region often absorbs lower HF and medium-frequency energy during daylight.
- Distant AM broadcast signals often carry farther at night because D-region absorption is reduced.
- Multipath propagation can cause fading, selective fading, and phase distortion.
- More sunspots and higher 10.7 cm solar flux usually indicate stronger ionization and higher usable HF frequencies; the average solar cycle is about 11 years.
- HF sky-wave paths can change polarization through refraction, reflection, and Faraday rotation.
- Critical frequency is a vertical-incidence measurement; MUF is for a particular path.
- A practical working frequency is below the MUF and above the LUF, often estimated near 85 % of the MUF for planning.
- When propagation changes, changing band is often more useful than changing audio settings or adding power.
