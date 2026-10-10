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

A transmitter is intended to put most of its RF energy on the selected operating frequency and within the needed bandwidth. Real circuits need filtering and proper adjustment because non-linear stages can create energy at other frequencies.

Filters pass useful energy and reject unwanted energy. This lesson connects harmonics, splatter, 60 Hz hum, and common filter types to practical interference decisions.

## Learning objectives

By the end of this lesson, you can:

- define harmonic emissions as multiples of a fundamental frequency;
- trace simple harmonic frequencies using multiplication;
- explain how overdrive and overmodulation create unwanted transmitted energy;
- choose low-pass, high-pass, band-pass, band-reject, and notch filters for common situations; and
- explain why filter impedance and placement matter.

## Harmonics

A harmonic is a signal at an integer multiple of a fundamental frequency. The fundamental frequency is the operating frequency or source frequency you start from. The second harmonic is the fundamental x 2. The third harmonic is the fundamental x 3.

Accessible text formula:

harmonic frequency = fundamental frequency x harmonic number

Harmonics from a transmitter are unwanted because they can fall in other services or other amateur bands. A harmonic problem often affects only devices or receivers whose frequency range lines up with a multiple. That differs from broad receiver overload, which tends to be less selective.

Switching supplies can also make harmonics of their switching rate. For example, if a charger switches at 100 kHz, its 70th harmonic is 70 x 100 kHz = 7 000 kHz = 7.0 MHz.

That number is before any filtering or shielding. It shows why small power supplies can matter to HF reception.

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

## Overdrive, flat topping, and splatter

Amplifiers and modulators must operate in their intended linear range. If an SSB transmitter is driven too hard, the peaks can be clipped or flattened. This non-linear operation creates extra side energy and distortion.

On the air, other stations may describe the result as splatter because the signal spreads beyond its necessary bandwidth. When extra RF appears just beyond the bandwidth the transmission needs, that case is out-of-band emission.

Excessive microphone gain is a common cause of SSB overdrive. More audio gain does not make the signal more readable once the transmitter is clipping. It usually makes the signal wider and less pleasant.

RF power amplifier stages can also generate excessive harmonics if they are overdriven. Proper drive level, correct loading, intact output filtering, and manufacturer-recommended adjustments all matter.

### In the real world: microphone gain

An operator increases microphone gain until the power meter hardly rises on voice peaks, but reports from nearby channels get worse. Reducing the gain makes the average reading slightly lower, yet the audio becomes clearer and reports improve.

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

### Memory trick: pass names say what gets through

- Helps remember: low-pass, high-pass, and band-pass names describe the wanted frequencies that pass.
- Trick: read the name as a sentence: low-pass passes lows, high-pass passes highs, band-pass passes a band.
- Limit: the name does not tell you the cut-off frequency, power rating, impedance, or where to install it.

## Low-pass filters

A low-pass filter passes frequencies below its cut-off and attenuates frequencies above it. At a transmitter output, a low-pass filter can reduce harmonics that are above the fundamental. In an AC line filter for station equipment, the wanted power frequency is very low, so the filter should pass the power frequency while attenuating RF noise.

### Worked example: low-pass choice

A workshop receiver is meant to monitor a 4.2 MHz propagation beacon, but it sits beside a test rack with a 24 MHz clock oscillator. When the rack is on, the receiver front end overloads even though the wanted beacon is far lower in frequency.

A low-pass filter ahead of the receiver with a cut-off above 4.2 MHz and well below 24 MHz can pass the beacon while reducing the clock energy. Choose the cut-off so the desired signals are passed and the unwanted higher-frequency energy is reduced.

### In the real world: noisy LED lamp

A desk receiver hears a buzz whenever a nearby LED lamp is on. The buzz is strongest below 10 MHz and drops when the lamp is unplugged.

A ferrite on the lamp lead may reduce common-mode RF on the cord. A mains-rated AC line filter is a low-pass filter in this job: it passes power-line frequency and attenuates RF noise. If used, it belongs in the noisy lamp's power path or at the affected equipment's power input, according to the filter design. If the lamp itself is poorly designed or failing, replacing it may be safer and more effective than adding parts around it.

## High-pass filters

A high-pass filter passes frequencies above its cut-off and attenuates frequencies below it. If an HF station overloads a receiver meant for much higher frequencies, a high-pass filter at that receiver input may be the right first cure. It rejects lower-frequency amateur energy before the receiver front end is driven non-linear.

Do not put a high-pass filter in the HF transmitter line if the goal is to transmit HF. That would attenuate the wanted signal. Filter placement must match the symptom.

## Band-pass, band-reject, and notch filters

A band-pass filter admits a planned range and rejects energy outside that range. It is useful when several stations operate close together, such as a club exercise where each receiver should hear only its assigned band.

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
- ferrite chokes for common-mode cable pickup belong close to the affected device or at the point where common-mode current begins; and
- AC line filters belong in the power lead of the equipment that needs noise reduction.

### In the real world: solar-inverter noise path

A station hears a rough buzz across several HF bands when a nearby solar inverter starts. The noise may leave on DC panel leads, AC power wiring, control cables, or the inverter case and bonding path.

The cure depends on the path. Common-mode ferrites on a cable can reduce RF current on that cable. A mains-rated filter belongs in the power path it is designed for. Internal repair or replacement belongs to qualified service people because inverter wiring can be hazardous.

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

1. A transmitter on 5.1 MHz is suspected of producing an unwanted signal at 20.4 MHz. Which harmonic is that? Divide 20.4 by 5.1. The result is 4, so it is the fourth harmonic.
2. A receiver needs a 5.0 MHz time signal, but a telemetry rack near 42 MHz is causing overload. Which filter family should be considered first? A low-pass filter can pass the lower desired signal while attenuating the higher-frequency telemetry energy.
3. An air-band receiver near 122 MHz is upset whenever a nearby 7 MHz station transmits. Where does the likely high-pass filter belong? At the affected air-band receiver input, before the lower-frequency HF energy overloads the receiver front end.
4. A calibration receiver needs to hear a weak signal at 10.140 MHz, but one stable birdie sits 700 Hz away. Is a broad band-reject filter always the best first choice? No. A notch filter may be better for one narrow frequency because it removes less nearby spectrum.
5. An RF power amplifier's drive control is advanced until output current rises sharply and a spectrum display shows stronger multiples of the carrier. What adjustment should be tried before blaming the antenna? Reduce RF drive and tune the amplifier as recommended so the stage stays closer to linear operation.

## Radio connection

Filters are not magic boxes. They are frequency-selective circuits made from the same resistance, capacitance, and inductance ideas used throughout radio. A low-pass output filter protects other spectrum users from your transmitter's harmonics. A high-pass input filter can protect a receiver from strong lower-frequency RF.

A band-pass filter keeps a multi-station operation manageable. A ferrite choke helps when the unwanted path is common-mode current on a cable. The correct choice depends on the unwanted energy path.

## Common mistakes

- Calling every interference problem a harmonic because it happens during transmitting.
- Forgetting to multiply the fundamental by an integer when checking harmonic relationships.
- Confusing power-line hum with RF harmonics from a transmitter.
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
- A 60 Hz hum is a low-frequency power or audio problem, not proof of transmitter RF harmonics.
- Overdriven RF stages and excessive audio drive can create harmonics, flat topping, splatter, and out-of-band emission.
- Low-pass filters pass lower frequencies and attenuate higher ones.
- High-pass filters pass higher frequencies and attenuate lower ones.
- Band-pass filters pass a range; band-reject filters attenuate a range; notch filters attenuate a narrow frequency.
- A filter should match the system impedance and be placed before the stage or path where the unwanted energy causes trouble.
- Ferrites help common-mode cable currents; other noise paths may need different filters, repair, or replacement.
