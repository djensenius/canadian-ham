---
type: lesson
id: L-008-02
moduleId: M8
categoryIds:
  - B-008
title:
  en: "Harmonics and filters"
  fr: null
covers:
  - B-008-004
  - B-008-005
objectives:
  - "Identify harmonic-emission problems and likely symptoms."
  - "Select low-pass, high-pass, band-pass, and notch filter roles."
  - "Place filters where they address the actual unwanted energy."
prerequisites:
  - L-008-01
estimatedMinutes: 40
quizIds:
  - QZ-L-008-02-A
status: draft
---
# Harmonics and filters

A transmitter is intended to put most of its RF energy on the selected operating frequency and within the needed bandwidth. Real circuits also need filtering and proper adjustment because non-linear stages can create energy at other frequencies. Filters are the tools that pass useful energy and reject unwanted energy.

This lesson connects harmonic emissions, splatter, and common filter types to practical interference-suppression decisions.

## Learning objectives

By the end of this lesson, you can:

- define harmonic emissions as multiples of a fundamental frequency;
- trace simple harmonic frequencies using multiplication;
- explain how overdrive and overmodulation create unwanted transmitted energy;
- choose low-pass, high-pass, band-pass, band-reject, and notch filters for common situations; and
- explain why filter impedance and placement matter.

## Harmonics

A harmonic is a signal at an integer multiple of a fundamental frequency. The second harmonic is twice the fundamental. The third harmonic is three times the fundamental. Harmonics are easy to calculate with the accessible formula:

harmonic frequency = fundamental frequency x harmonic number

For example, if a test oscillator is set to 3.2 MHz, its second harmonic is 6.4 MHz and its third harmonic is 9.6 MHz. Those are original example numbers; the method is the important part.

Harmonics from a transmitter are unwanted because they can fall in other services or other amateur bands. A harmonic problem often affects only devices or receivers whose frequency range lines up with one of those multiples. That differs from broad receiver overload, which tends to be less selective.

### Worked example: finding a harmonic

A transmitter is operating on 4.6 MHz in a workshop test. A measuring receiver hears an unwanted signal at 13.8 MHz.

- Use the formula: harmonic number = unwanted frequency / operating frequency.
- 13.8 / 4.6 = 3.
- The unwanted signal is the third harmonic of the operating frequency.

The cure is not to retune the measuring receiver. The transmitter output filtering, drive level, and amplifier operation need attention.

### Worked example: not every multiple is the same symptom

A low-power oscillator produces a tiny signal at 18.4 MHz while operating at 9.2 MHz. A nearby communications receiver can hear it only when connected to a laboratory antenna.

That is a second-harmonic relationship. Whether it is a harmful station problem depends on level, path, and regulations, but the diagnostic word is still harmonic because the frequency is an exact integer multiple of the fundamental.

## Overdrive, flat topping, and splatter

Amplifiers and modulators must operate in their intended linear range. If an SSB transmitter is driven too hard, the peaks can be clipped or flattened. This non-linear operation creates extra side energy and distortion. On the air, other stations may describe the result as splatter because the signal spreads beyond its necessary bandwidth.

Excessive microphone gain is a common cause of SSB overdrive. More audio gain does not make the signal more readable once the transmitter is clipping. It usually makes the signal wider and less pleasant.

RF power amplifier stages can also generate excessive harmonics if they are overdriven. Proper drive level, correct loading, intact output filtering, and manufacturer-recommended adjustments all matter.

### Worked example: microphone gain

An operator increases microphone gain until the power meter hardly rises on voice peaks but reports from nearby channels get worse. Reducing the gain makes the average reading slightly lower, yet the audio becomes clearer and reports improve.

The original setting was likely pushing stages into non-linear operation. The better setting trades a misleading meter impression for a cleaner signal.

## Filter vocabulary

A filter is described by what it passes and what it attenuates.

| Filter type | Main action | Common interference use |
|---|---|---|
| Low-pass | Passes lower frequencies and attenuates higher frequencies | Reduce transmitter harmonics above the operating range or keep RF noise out of equipment through an AC-line filter |
| High-pass | Passes higher frequencies and attenuates lower frequencies | Keep HF energy out of a VHF/UHF television or receiver input |
| Band-pass | Passes a selected range and attenuates frequencies above and below it | Protect a receiver at a multi-station event by admitting only its assigned band |
| Band-reject | Attenuates a range and passes frequencies outside that range | Remove a strong service or broadcast band while receiving on nearby lower and higher ranges |
| Notch | Attenuates one narrow frequency and passes most others | Reduce a single strong carrier close to the desired signal |

The cut-off frequency is the boundary region where a low-pass or high-pass filter changes from mostly passing to mostly attenuating. Real filters do not switch instantly; they transition over a range.

## Low-pass filters

A low-pass filter passes frequencies below its cut-off and attenuates frequencies above it. At a transmitter output, a low-pass filter can reduce harmonics that are above the fundamental. In an AC line filter for station equipment, the wanted power frequency is very low, so the filter should pass the power frequency while attenuating RF noise.

### Worked example: low-pass choice

A receiver used for shortwave listening is being upset by very strong signals from much higher-frequency services. A low-pass filter ahead of the receiver can pass the lower shortwave range while reducing energy above the chosen cut-off.

Choose the cut-off so the desired signals are passed and the unwanted higher-frequency energy is reduced. Also match the filter impedance to the receiver and feedline system.

## High-pass filters

A high-pass filter passes frequencies above its cut-off and attenuates frequencies below it. If an HF station is overloading a receiver that is meant to receive much higher frequencies, a high-pass filter at that receiver input may be the right first cure. It rejects the lower-frequency amateur energy before the receiver front end is driven non-linear.

Do not put a high-pass filter in the HF transmitter line if the goal is to transmit HF. That would attenuate the wanted signal. Filter placement must match the symptom.

## Band-pass, band-reject, and notch filters

A band-pass filter admits a planned range and rejects energy outside that range. It is useful when several stations operate close together, such as a club exercise where each receiver should hear only its own assigned band.

A band-reject filter, sometimes called a band-stop filter, rejects a wider range while passing frequencies below and above it. Use it when one strong band is the problem and you still need to hear on both sides of that range.

A notch filter is narrower. It is aimed at a single interfering frequency or a very small slice of spectrum. It can be effective against one steady carrier close to the desired signal, but it will not remove a whole band of strong signals.

### Worked example: choosing the range

A station wants to monitor 5.4 MHz and 7.8 MHz, but a very strong utility transmitter around 6.6 MHz overloads the receiver. A band-reject filter centred on the utility transmitter range is a better fit than a simple low-pass or high-pass filter, because the station wants to keep receiving on both sides of the unwanted signal.

If the problem were one narrow carrier at 6.61 MHz, a notch might be enough. If the problem were many transmitters across a wider allocation, a band-reject filter would be more realistic.

## Filter impedance and placement

A filter is part of the RF system. Its impedance should match the line or equipment where it is inserted. A serious mismatch can create reflections, loss, or misleading measurements. In common amateur coax systems, that often means using a filter designed for the same nominal impedance as the feedline and radio.

Placement matters as much as type:

- transmitter harmonic filters belong in the transmitter output path before the antenna system radiates the unwanted energy;
- receiver overload filters belong before the receiver stage that overloads;
- ferrite chokes for cable pickup belong close to the affected device or at the point where common-mode current begins; and
- AC line filters belong in the power lead of the equipment that needs noise reduction.

## A troubleshooting sequence

When interference appears, move from broad observations to specific filters.

1. Identify the affected device and the symptom.
2. Check whether the problem occurs on many transmit frequencies or only those with a harmonic relationship.
3. Reduce power for a brief test and see whether the symptom changes smoothly.
4. Confirm that the amateur transmitter is not being overdriven.
5. Choose a filter for the unwanted energy path, not just any available filter.
6. Verify the result with the same test conditions.

Keep notes. A written log prevents circular troubleshooting and makes it easier to ask another amateur or technician for help.

## Try it

1. Question: A transmitter on 6.3 MHz is suspected of producing an unwanted signal at 18.9 MHz. Which harmonic is that? Answer: Divide 18.9 by 6.3. The result is 3, so it is the third harmonic.
2. Question: A receiver needs signals around 11 MHz, but strong signals above 30 MHz are causing overload. Which filter family should be considered first? Answer: A low-pass filter can pass the lower desired range while attenuating higher-frequency energy.
3. Question: A television receiver needs higher-frequency broadcast signals but is upset by nearby HF transmissions. Where does the likely high-pass filter belong? Answer: At the affected receiver input, before the HF energy overloads the receiver front end.
4. Question: A single steady carrier sits almost on top of a weak signal. Is a broad band-reject filter always the best first choice? Answer: No. A notch filter may be better for one narrow frequency because it removes less nearby spectrum.
5. Question: An SSB signal becomes wider and harsher when microphone gain is increased. What adjustment should be tried before adding external filters? Answer: Reduce the audio drive or microphone gain so the transmitter stages operate linearly.

## Radio connection

Filters are not magic boxes. They are frequency-selective circuits made from the same resistance, capacitance, and inductance ideas used throughout radio. A low-pass output filter protects other spectrum users from your transmitter's harmonics. A high-pass input filter can protect a receiver from strong lower-frequency RF. A band-pass filter keeps a multi-station operation manageable. The correct choice depends on the unwanted energy path.

## Common mistakes

- Calling every interference problem a harmonic because it happens during transmitting.
- Forgetting to multiply the fundamental by an integer when checking harmonic relationships.
- Increasing microphone gain to solve weak audio reports when the real problem is overdrive.
- Installing a transmitter low-pass filter to fix receiver front-end overload in a neighbour's device.
- Using a notch filter when an entire band of strong signals must be reduced.
- Ignoring filter impedance and creating a mismatch where the filter is inserted.
- Judging a filter by its name instead of by what it passes, what it attenuates, and where it is installed.

## Illustration brief

Alt text: Frequency-response sketches for low-pass, high-pass, band-pass, band-reject, and notch filters.

Description: Draw five small graphs with frequency increasing left to right and response increasing upward. Show low-pass high on the left and low on the right, high-pass low on the left and high on the right, band-pass high only in the middle, band-reject low over a middle band, and notch as one narrow dip. Label pass and attenuate regions with text, not colour alone.

## Summary

- Harmonics are unwanted signals at integer multiples of the operating frequency.
- Overdriven RF stages and excessive audio drive can create harmonics, flat topping, and splatter.
- Low-pass filters pass lower frequencies and attenuate higher ones.
- High-pass filters pass higher frequencies and attenuate lower ones.
- Band-pass filters pass a range; band-reject filters attenuate a range; notch filters attenuate a narrow frequency.
- A filter should match the system impedance and be placed before the stage or path where the unwanted energy causes trouble.
