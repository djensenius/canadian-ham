---
type: lesson
id: L-007-03
moduleId: M7
categoryIds:
  - B-007
title:
  en: "VHF, UHF, and unusual propagation modes"
  fr: null
covers:
  - B-007-007
  - B-007-008
objectives:
  - "Explain sporadic E and tropospheric effects on VHF/UHF."
  - "Recognize scatter and ducting clues."
  - "Choose operating expectations for weak or distorted signals."
prerequisites:
  - L-007-02
estimatedMinutes: 35
quizIds:
  - QZ-L-007-03-A
status: draft
---
# VHF, UHF, and unusual propagation modes

VHF and UHF are usually local, but "usually" does not mean always. The lower atmosphere can bend or scatter signals. Dense patches near the E region can open six metres. Aurora and meteor trails can create brief or distorted paths.

These modes are exciting because they break the everyday range expectation. They are not dependable replacements for ordinary coverage.

## Learning objectives

By the end of this lesson, you can:

- describe sporadic E and why six metres is the classic amateur band for it;
- explain tropospheric bending, ducting, and scatter on VHF/UHF;
- recognize auroral propagation and why CW often survives distortion better than voice FM;
- explain how meteor scatter produces short VHF opportunities; and
- distinguish weak scatter from ordinary ground-wave, sky-wave, or line-of-sight paths.

## Ordinary VHF range starts with height

Most VHF and UHF contacts begin with line of sight and radio horizon. Antenna height, terrain, buildings, trees, and receiver sensitivity all matter. More transmitter power cannot make a blocked path bend around Earth like HF sky wave.

Normal tropospheric refraction extends the radio horizon a little beyond the visible horizon. This is an everyday lower-atmosphere effect, not ionospheric skip.

### In the real world: handheld to repeater range

A practical radio-horizon estimate is:

radio horizon in km = 4.12 x square root of antenna height in metres

This is a planning estimate, not an ISED exam formula.

- Given: handheld antenna height = 1.8 m; repeater antenna height = 100 m.
- Find: combined horizon estimate.
- Formula: path estimate = handheld horizon + repeater horizon; each horizon = 4.12 x square root of antenna height in metres.
- Substitute: path estimate = 4.12 x 1.34 + 4.12 x 10.
- Answer: path estimate = 5.5 km + 41.2 km = 46.7 km.
- Sanity check: the tall repeater site does most of the work, and terrain can still shorten the path.

This explains why an FM repeater on a hill can cover much more area than two handhelds in streets. It also explains why a better antenna location often helps more than a small power increase.

### Faded practice: finish a combined radio horizon

Use the practical horizon model, not a terrain guarantee.

- Given: antenna heights = 4 m and 81 m; their square roots = 2 and 9.
- Find: combined horizon estimate.
- Formula: combined distance ≈ 4.12 x √h1 + 4.12 x √h2, with heights in metres and distance in kilometres.
- Complete: distance ≈ 4.12 x ___ + 4.12 x ___ = ___ km.
- Sanity check: Do both antenna heights contribute, and can terrain still shorten the path?

Fill the gaps before checking below.

### Check your work: finish a combined radio horizon

Distance ≈ 8.24 + 37.08 = 45.32 km. Buildings, terrain, clutter, and actual propagation can change coverage. The model is a practical estimate, not an ISED exam formula.

### Misconception: VHF range is only about watts

- Mistaken idea: doubling power makes a VHF handheld cover far beyond the horizon.
- Correction: power can improve a marginal path, but height and blockage usually set the first range limit.

## Sporadic E and six metres

Sporadic E is a patchy, dense ionization condition at E-region height. It can refract signals that normally would not return from that region. The six-metre band is famous for this.

On an ordinary day, six metres behaves much like a local VHF band. During a sporadic-E opening, it can produce contacts far outside normal line-of-sight range.

The word sporadic matters. These openings can appear quickly, cover a surprising area, and disappear just as quickly. The six-metre band is about 50 MHz by the 300 / f wavelength rule. Operators watch beacon clusters, call frequencies, and reports so they notice the opening while it lasts.

### In the real world: a sudden six-metre map

A station hears no distant signals on six metres at lunch. Later in the afternoon, several stations from one region appear with strong but changing signals.

The local VHF repeater coverage has not changed. A good working explanation is a sporadic-E patch affecting six metres, not a permanent improvement in the station antenna.

## Tropospheric bending, ducting, and scatter

The troposphere is the lower atmosphere where weather happens. Normal refraction slightly extends the radio horizon. When that lower-atmosphere bending lets a VHF or UHF path skim farther along Earth than line of sight alone, operators call it a tropospheric-wave path. That is different from ground wave, which follows and is affected by the surface itself.

Without an enhanced mode, VHF tropospheric communication is still limited. The handheld-to-repeater estimate above was for ordinary line-of-sight service with one low antenna. Treat roughly 800 km as a broad upper planning scale for normal VHF tropospheric range between high, well-equipped weak-signal stations, not a daily promise for handhelds. A VHF path well beyond that scale is a clue that tropospheric ducting or another enhancement is present.

Stronger changes in temperature, humidity, and pressure can bend VHF and UHF signals more than usual. A temperature inversion can form a duct. A duct traps part of the wave so it travels much farther than expected.

Tropospheric scatter is different from ducting. It uses small variations in lower-atmosphere density and water-vapour content to redirect a small amount of energy beyond the radio horizon. Scattering sends small pieces of a wave in many directions instead of bending the whole wave smoothly.

Accessible text formula: ordinary VHF range starts with antenna height and radio horizon. Enhanced tropospheric propagation adds bending, ducting, or scatter when lower-atmosphere conditions help.

### In the real world: lake-path ducting

After a calm evening, cool air settles over a large lake while warmer air sits above it. A coastal station suddenly hears distant VHF repeaters across the water.

The path follows the weather boundary for a while. The opening may vanish when wind mixes the layers.

## Aurora, meteor scatter, and distorted signals

Auroral propagation uses disturbed ionization near E-region height in high-latitude directions. In the northern hemisphere, operators often aim antennas northward to use the auroral region. The reflected or scattered signal can sound raspy or fluttery because the aurora is moving and irregular.

CW is often more readable than analog voice through auroral distortion because it is narrow and uses a simple on-off tone. Wide, natural speech is harder to understand when the path adds rapid flutter.

Meteor scatter uses brief ionized trails left by meteors. VHF energy can reflect or scatter from the trail for a short burst. The 30 MHz to 100 MHz range fits well. Below about 30 MHz, ordinary ionospheric paths and absorption dominate. Above about 100 MHz, the trails return much less energy and fade faster. Six metres sits in that useful range.

HF scatter can put weak, distorted signals into a skip zone. Near the MUF, the main sky-wave return is marginal and the skip zone can be wide, so weak scattered energy becomes noticeable. Only a small part of the transmitted energy is redirected toward the receiver, and multiple paths can smear the signal.

::figure vhf-unusual-propagation-modes
Alt text: Four mini-panels showing sporadic E, tropospheric ducting, auroral scatter, and meteor scatter paths.
Text equivalent:
- Sporadic E panel: a six-metre path returns from a patchy E-region cloud.
- Ducting panel: a VHF path is trapped between paired weather layers over water.
- Aurora panel: a small beam points north toward a wavy auroral curtain, with a raspy signal label.
- Meteor panel: a burst path touches a short meteor trail between the stations.
::

### In the real world: choosing the mode for a rough auroral path

A VHF operator hears signals from the north with a harsh, buzzing tone. FM voice is difficult to understand, but short Morse characters can still be copied.

The operator switches to a mode and message style that tolerate distortion instead of assuming the receiver has failed.

## Recognizing the clues

Use the band and the symptom together:

- Six metres with sudden distant stations: suspect sporadic E, meteor scatter, or aurora depending on timing and direction.
- Two metres or higher with distant coastal or flatland paths during stable weather: suspect tropospheric enhancement or ducting.
- Weak, distorted HF from a normally skipped-over area: suspect scatter near the usable-frequency limit.
- Very brief VHF bursts: suspect meteor scatter, especially during known shower periods.
- Raspy VHF signals from a northern direction: suspect auroral propagation in northern-hemisphere operating.

Do not turn these clues into guarantees. The same station may need a higher antenna for ordinary range, a different band for an HF path, or patience for the next opening.

## Try it

Try these before reading the feedback below.

1. A six-metre opening vanishes after twenty minutes. Which operating habits fit?
2. A long two-metre contact occurs over water during a calm evening. What evidence should be recorded before treating it as everyday range?
3. Raspy VHF signals arrive from the north during short call-sign and grid exchanges. What operating style fits?
4. A marginal HF path alternates intelligible peaks with smeared audio. What should be logged before blaming the radio?
5. Why might a meteor-shower schedule use fast digital bursts instead of long voice transmissions?

### Try-it feedback

1. Keep exchanges short, log quickly, and monitor beacons; the patch can move or fade.
2. Note weather layering, antenna direction and heights, time, and distance to test for enhanced lower-atmosphere conditions.
3. Use a narrow, simple mode and short messages that tolerate flutter and distortion.
4. Record frequency, time, strength, and distortion pattern to compare mixed propagation with later openings.
5. Ionized trails last briefly. Short structured messages can fit into the brief reflection windows.

## Radio connection

Unusual propagation rewards listening. Keep a memory channel or receiver slice on local beacons, note weather patterns, and compare what you hear with the direction of your antenna. When an opening starts, use concise exchanges and suitable modes; the path may be short-lived.

For station planning, do not rely on unusual modes for routine safety coverage. Use them as learning opportunities while ordinary communication plans depend on repeaters, line-of-sight paths, HF nets, or other dependable systems.

## Common mistakes

- Assuming every distant VHF signal is ionospheric skip.
- Treating sporadic E as predictable daily coverage.
- Confusing tropospheric ducting with meteor scatter just because both can extend VHF range.
- Expecting wideband FM voice to sound clean on an auroral path.
- Forgetting that scatter signals are often weak because only a small portion of energy reaches the receiver.

## Illustration brief

Alt text: Four mini-panels showing sporadic E, tropospheric ducting, auroral scatter, and meteor scatter paths.

Description: Draw four labelled sketches on a single page. Panel A shows a six-metre ray bending from a small E-region patch. Panel B shows a VHF ray trapped between a pair of lower-atmosphere layers over water. Panel C shows a directional antenna aimed north at a shimmering auroral curtain. Panel D shows a short meteor trail with a burst path between a station pair. Use small notes for "patchy," "weather layer," "distorted," and "brief burst."

## Summary

- Ordinary VHF and UHF range starts with antenna height, radio horizon, and clear paths.
- Sporadic E is patchy E-region ionization and is especially important on six metres.
- Tropospheric bending slightly extends VHF/UHF range; a tropospheric wave is kept near the surface by lower-atmosphere bending, not by surface-following ground-wave action.
- Ordinary VHF tropospheric range is roughly limited to an 800 km planning scale for high, well-equipped stations unless enhancement is present.
- Tropospheric scatter redirects a small amount of VHF/UHF energy beyond the normal horizon.
- Auroral propagation is often distorted; CW is usually more readable than analog voice FM.
- Meteor scatter uses brief ionized trails and is most useful from about 30 MHz to 100 MHz, where trails can scatter VHF wavelengths for short bursts.
- Scattering redirects parts of a wave in many directions, so received signals are often weak or smeared.
- Unusual modes are opportunities, not guaranteed everyday coverage.
