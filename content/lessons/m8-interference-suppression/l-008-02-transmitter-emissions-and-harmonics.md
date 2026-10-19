---
type: lesson
id: L-008-02
moduleId: M8
categoryIds:
  - B-008
title:
  en: "Transmitter emissions, harmonics, and keying faults"
  fr: null
covers:
  - B-008-003
  - B-008-004
objectives:
  - "Distinguish intermodulation, spurious emissions, harmonics, parasitic oscillation, splatter, and key clicks."
  - "Trace simple harmonic frequencies using multiplication."
  - "Explain how overdrive, overmodulation, shielding problems, and keying waveform faults create unwanted transmitted energy."
prerequisites:
  - L-008-01
  - L-007-01
estimatedMinutes: 35
quizIds:
  - QZ-L-008-02-A
status: draft
---
# Transmitter emissions, harmonics, and keying faults

A transmitter is intended to put most of its RF energy on the selected operating frequency and within the needed bandwidth. Real circuits need filtering, shielding, clean drive, and proper keying shape because non-linear stages can create energy at other frequencies.

The previous lesson covered receiver-side and device-side cures. This lesson covers transmitter-side faults. If your station is producing unwanted transmitted outputs, stop using that setup until the cause is found and corrected.

## Learning objectives

By the end of this lesson, you can:

- define harmonic emissions as multiples of a fundamental frequency;
- trace simple harmonic frequencies using multiplication;
- distinguish out-of-band emissions from other spurious emissions;
- explain how overdrive and overmodulation create unwanted transmitted energy;
- recognize key clicks and parasitic oscillation as transmitter problems; and
- connect transmitter emission symptoms to filtering, shielding, drive, and repair.

## Spurious emissions and intermodulation

Intermodulation happens when RF signals pass through a non-linear stage and the stage makes extra sum-and-difference signals. The non-linear stage may be in a receiver, in external metalwork, or in transmitting equipment.

Out-of-band emission is unwanted energy just outside the necessary bandwidth that comes from the modulation process, such as splatter or key clicks. Spurious emissions are other unwanted transmitter outputs outside the necessary bandwidth. They can appear near or far from the signal, and include harmonics, parasitic oscillations, and mixing products.

A spurious emission may come from poor shielding, faulty stages, unwanted mixing, overdriven circuits, or oscillation inside equipment. Unlike receiver overload, this is a transmitter or transmitter-accessory problem and must be corrected.

A clean transmitter has filtering, shielding, and stages adjusted so the wanted signal dominates and unwanted outputs are suppressed. Operating equipment with covers or shields removed can change grounding and shielding enough to let unwanted energy radiate.

::figure interference-troubleshooting-map
Alt text: A troubleshooting map that separates receiver overload, audio rectification, and transmitter spurious emissions.
Text equivalent:
- Overload panel: a large off-channel arrow and a smaller wanted arrow enter the receiver input.
- Audio rectification panel: a speaker lead picks up RF and feeds a diode-like detector at a speaker input.
- Spurious outputs panel: the transmitter has a thick wanted output arrow plus smaller unwanted output paths above and below it.
::

## Harmonics

A harmonic is a signal at an integer multiple of a fundamental frequency. The fundamental frequency is the operating frequency or source frequency you start from. The second harmonic is the fundamental x 2. The third harmonic is the fundamental x 3.

Accessible text formula:

harmonic frequency = fundamental frequency x harmonic number

Harmonics from a transmitter are unwanted because they can fall in other services or other amateur bands. A harmonic problem often affects only devices or receivers whose frequency range lines up with a multiple. That differs from broad receiver overload, which tends to be less selective.

If a problem gives a band name instead of a frequency, use the compact band-name table from L-007-01. Band names are only rough wavelength labels. For example, a 17 m signal near 18.1 MHz has a second harmonic near 36.2 MHz.

Switching supplies can also make harmonics of their switching rate. For example, if a charger switches at 100 kHz, its 70th harmonic is 70 x 100 kHz = 7 000 kHz = 7.0 MHz.

Filtering and shielding reduce the strength of that harmonic, not its frequency. This power-supply example shows why small supplies can matter to HF reception.

### Worked example: finding a harmonic

A transmitter is operating on 4.6 MHz in a workshop test. A measuring receiver hears an unwanted signal at 13.8 MHz.

- Given: operating frequency = 4.6 MHz; unwanted frequency = 13.8 MHz.
- Find: harmonic number.
- Formula: harmonic number = unwanted frequency / operating frequency.
- Substitute: harmonic number = 13.8 / 4.6.
- Answer: harmonic number = 3, so the unwanted signal is the third harmonic.
- Sanity check: 4.6 MHz x 3 = 13.8 MHz.

The cure is not to retune the measuring receiver. The transmitter output filtering, drive level, and amplifier operation need attention.

### In the real world: 60 Hz hum is a different problem

Canadian household AC power is 60 Hz. A full cycle takes 1 / 60 s = 0.0167 s, or 16.7 ms. That low audio-frequency hum often points to power wiring, grounding, shielding, or audio coupling.

A transmitter harmonic is different. If an RF signal starts at 3.7 MHz, the next integer multiples are 7.4 MHz and 11.1 MHz. Those are RF frequencies, not a 60 Hz hum.

### Misconception: hum is the same as RF harmonics

- Mistaken idea: a power-line hum during transmitting is the same problem as RF harmonics.
- Correction: hum and RF harmonics have different causes and frequencies. Check the symptom before choosing a filter.

## Overdrive, overmodulation, flat topping, and splatter

Amplifiers and modulators must operate in their intended linear range. If an SSB transmitter is driven too hard, the peaks can be clipped or flattened. This non-linear operation creates extra side energy and distortion.

Overmodulation means the audio drive or modulation level is too high for the transmitter to reproduce cleanly. On the air, other stations may describe the result as splatter because the signal spreads beyond its necessary bandwidth. When extra RF from the modulation process appears just beyond the bandwidth the transmission needs, that case is out-of-band emission. Spurious emissions are other unwanted outputs outside the necessary bandwidth, and can include harmonics, parasitic oscillations, or mixing products.

Excessive microphone gain is a common cause of SSB overdrive and overmodulation. More audio gain does not make the signal more readable once the transmitter is clipping. It usually makes the signal wider and less pleasant.

RF power amplifier stages can also generate excessive harmonics if they are overdriven. Proper drive level, correct loading, intact output filtering, and manufacturer-recommended adjustments all matter.

A low-pass filter at a transmitter output can reduce harmonics above the operating range. It must have the correct impedance and power rating, and it belongs before the antenna system radiates the unwanted energy.

### In the real world: microphone gain

An operator increases microphone gain past the point where voice peaks produce much extra RF output, but reports from nearby channels get worse. Reducing the gain makes the average reading slightly lower, yet the audio becomes clearer and reports improve.

The original setting was likely pushing stages into non-linear operation. The better setting trades a misleading meter impression for a cleaner signal.

## Key clicks and waveform shape

In Morse transmission, the carrier should rise and fall smoothly enough that the signal occupies a reasonable bandwidth. If the carrier turns on and off too abruptly, the sharp edges contain extra side energy. Distant receivers hear this as clicks near the signal.

There are two related clues. Local RF interference from key clicks can come from the making and breaking of the key circuit itself. Key clicks heard at a distant receiver usually point to rise and decay times of the transmitted carrier that are too sharp.

Key clicks are not fixed by sending slower with the same harsh waveform. The transmitter's keying waveform, keying filter, and later RF stages need attention. The goal is to shape the rise and decay times, not to hide the problem.

### Worked example: sharp keying

A home-built CW transmitter sounds strong at the station monitor, but a friend several kilometres away reports clicking above and below the signal. The sidetone in the shack sounds normal.

The monitor tone only proves that the operator can hear keying locally. The wide clicking report points to a transmitter waveform problem. Inspect the keying-shape network, amplifier bias during keying, and any stages that are being driven abruptly.

## Parasitic oscillation

A parasitic problem occurs when a stage starts generating extra RF on its own instead of doing only its intended job. The usual trigger is unintended positive feedback through stray capacitance, lead inductance, layout, or poor neutralization. Neutralization means cancelling unwanted feedback in an amplifier stage. The extra frequency may sit above or below the intended operating frequency and does not have to be an exact harmonic.

Symptoms can include unstable output, unusual current, reports of interference away from the operating frequency, or trouble that appears only with a particular load or power level. Because parasitics can damage equipment and radiate unwanted energy, stop transmitting until the cause is found.

## A transmitter-side troubleshooting sequence

When a symptom points back to your transmitted signal, move from broad observations to the transmitter chain.

1. Confirm whether the problem has a harmonic relationship to the operating frequency.
2. Reduce power or drive for a brief test and see whether the unwanted output changes smoothly.
3. Confirm that audio or RF drive is not excessive.
4. Check covers, shields, grounding, and output filtering.
5. Inspect keying-shape circuits if the symptom is clicking near a CW signal.
6. Stop using any setup that shows parasitic oscillation, strong harmonics, or other spurious emissions until it is repaired.

Keep notes. A written log prevents circular troubleshooting and makes it easier to ask another amateur or technician for help.

## Try it

1. A transmitter on 5.1 MHz is suspected of producing an unwanted signal at 20.4 MHz. Which harmonic is that? Divide 20.4 by 5.1. The result is 4, so it is the fourth harmonic.
2. A CW exciter change reduces the RF-envelope rise time from about 6 ms to less than 1 ms, and a monitor several kilohertz away hears ticks. Why is simply sending slower not a cure? The problem is the abrupt edge of each keyed carrier element, so the keying-shape network and following RF stages need correction before on-air use.
3. An RF power amplifier's drive control is advanced until output current rises sharply and a spectrum display shows stronger multiples of the carrier. What adjustment should be tried before blaming the antenna? Reduce RF drive and tune the amplifier as recommended so the stage stays closer to linear operation.
4. A signal appears just outside the needed bandwidth during voice peaks. Which transmitter setting should be checked early? Check audio drive or microphone gain because overmodulation can create splatter.
5. A transmitter works normally with one load but becomes unstable and radiates an extra output with another load. What kind of fault should be considered? A parasitic oscillation or unwanted feedback path should be investigated before further transmitting.

## Radio connection

A clean transmitted signal protects other spectrum users and other amateurs. Harmonics, spurious emissions, splatter, key clicks, and parasitic oscillations waste power and can create interference far from the intended contact.

The same station can have both receiver-side and transmitter-side work to do. Receiver input filters and ferrites help when the problem is pickup or overload. Transmitter filtering, shielding, proper drive, and repair help when your station is making unwanted outputs.

## Common mistakes

- Calling every interference problem a harmonic because it happens during transmitting.
- Forgetting to multiply the fundamental by an integer when checking harmonic relationships.
- Confusing power-line hum with RF harmonics from a transmitter.
- Increasing microphone gain to solve weak audio reports when the real problem is overdrive.
- Ignoring key clicks because the local sidetone sounds normal.
- Continuing to transmit after credible evidence of spurious emissions from your station.
- Operating equipment with covers or shields removed and assuming the RF output is unchanged.

## Illustration brief

Alt text: A troubleshooting map that separates receiver overload, audio rectification, and transmitter spurious emissions.

Description: Draw three columns. The first column shows a receiver input with a large off-channel arrow crowding a small wanted arrow, labelled "front-end overload." The second shows a speaker lead acting as an antenna feeding a small diode symbol, labelled "audio rectification." The third shows a transmitter with one wanted output arrow and smaller unwanted arrows, labelled "spurious outputs." Use simple line art and text labels rather than colour-only coding.

## Summary

- Intermodulation creates new frequency components in non-linear devices.
- Spurious emissions are transmitter outputs outside the necessary bandwidth and include harmonics, parasitics, and some mixing products.
- Harmonics are unwanted signals at integer multiples of the operating frequency.
- A 60 Hz hum is a low-frequency power or audio problem, not proof of transmitter RF harmonics.
- Overdriven RF stages and excessive audio drive can create harmonics, flat topping, splatter, and out-of-band emission.
- Key clicks come from abrupt CW keying edges or key-circuit interference paths.
- Parasitic oscillation means a stage is generating unwanted RF and should be fixed before transmitting.
