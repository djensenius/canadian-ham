---
type: lesson
id: L-005-04
moduleId: M5
categoryIds:
  - B-005
title:
  en: "AC, decibels, capacitors, inductors, and reactance"
  fr: null
covers:
  - B-005-007
  - B-005-008
  - B-005-009
  - B-005-010
objectives:
  - "Describe frequency, wavelength, phase, harmonics, and audio range."
  - "Use simple dB power-ratio shortcuts."
  - "Combine equal inductors and capacitors in series or parallel."
  - "Predict how inductive and capacitive reactance change with frequency."
prerequisites:
  - L-005-03
estimatedMinutes: 45
quizIds:
  - QZ-L-005-04-A
status: draft
---
# AC, decibels, capacitors, inductors, and reactance

Alternating current, or AC, changes direction repeatedly. Radio signals are AC at radio frequencies. Audio tones, household power, and RF carriers are different in frequency, but the same ideas of cycles, wavelength, phase, and reactance help describe them.

This lesson connects four areas: AC words, decibel shortcuts, simple capacitor and inductor combinations, and frequency-dependent opposition called reactance.

## Learning objectives

By the end of this lesson, you can:

- define frequency, wavelength, phase, sine wave, and harmonic;
- identify audio and HF frequency ranges as general radio concepts;
- use common decibel power-ratio shortcuts;
- combine equal capacitors and inductors in simple series or parallel circuits;
- explain the construction factors for coils and capacitors; and
- predict how inductors and capacitors behave as AC frequency changes.

## AC basics

Frequency is the number of complete cycles per second. The unit is hertz. A 400 Hz tone completes 400 cycles each second.

Most humans can hear roughly 20 Hz to 20 000 Hz. That is why this range is called audio frequency. Radio frequencies are much higher. For example, a signal around 14 MHz is in the HF range.

Wavelength is the distance a signal travels during a complete cycle. As frequency increases, wavelength decreases. As wavelength gets shorter, frequency is higher.

Phase describes timing between waveforms. A pair of AC signals may have the same frequency but not start their cycles at the same instant; that timing difference is phase.

A sine wave is the smooth waveform associated with ideal AC. A harmonic is a signal at an integer multiple of a fundamental frequency, so harmonic signals sit above the fundamental at regular frequency intervals.

## Decibels as power ratios

The decibel compares two levels. For Basic-level estimating, use practical power shortcuts:

| dB change | Power ratio |
|---:|---:|
| +3 dB | roughly 2x power |
| -3 dB | roughly 1/2 power |
| +6 dB | roughly 4x power |
| -6 dB | roughly 1/4 power |
| +9 dB | roughly 8x power |
| +10 dB | roughly 10x power |
| -10 dB | roughly 1/10 power |
| -30 dB | roughly 1/1000 power |

### Worked example: gain

A 4 W handheld feeds a 7 dB gain amplifier. A 7 dB power increase is roughly a fivefold power change.

- Estimate the ratio as about 5:1.
- 4 W x 5 gives about 20 W.

The output is about 20 W.

### Worked example: feedline loss

A transmitter is 30 W and the line loss is 5 dB.

- A 5 dB loss leaves a bit less than a third of the original power.
- Use about 9 W as a quick estimate.

About 9 W reaches the antenna.

### Worked example: large power reduction

If a station needs a large reduction for a close-range test, combine standard attenuator steps rather than guessing. For example, an attenuator that leaves one-fifth of the power followed by one that leaves one-quarter gives one-twentieth of the starting power.

A 24 W signal through that pair of attenuators is reduced to about 1.2 W.

## Inductors and capacitors in combinations

An inductor stores energy in a magnetic field. A capacitor stores energy in an electric field.

The reference sheet gives these relationships:

| Component | Series total | Parallel total |
|---|---|---|
| Inductors | Lt = L1 + L2 + ... + Ln | 1 / Lt = 1 / L1 + 1 / L2 + ... + 1 / Ln |
| Capacitors | 1 / Ct = 1 / C1 + 1 / C2 + ... + 1 / Cn | Ct = C1 + C2 + ... + Cn |

Notice that capacitors are opposite to resistors for series and parallel totals. Inductors follow the resistor pattern in the simple ideal cases shown here.

### Worked examples

- A matched pair of inductors in series has the sum of both inductances.
- A matched pair of inductors in parallel has less inductance than either part alone.
- A matched pair of capacitors in series has less capacitance than either part alone.
- A matched pair of capacitors in parallel has the sum of both capacitances.

So a pair of 7 mH chokes in series make 14 mH. A pair of 18 mH inductors in parallel make 9 mH. A pair of 33 µF capacitors in series make 16.5 µF. A pair of 47 µF capacitors in parallel make 94 µF.

## What sets inductance and capacitance?

For an air-core coil, inductance depends mainly on the coil's size, its winding count, and its shape. Changing the diameter, length, or turn count changes the magnetic field and therefore the inductance.

For a simple air-spaced capacitor, capacitance depends on plate area and spacing. Larger facing plate area gives more capacitance. More spacing gives less capacitance.

Polarized electrolytic capacitors need correct polarity. Never apply reverse voltage to a polarized electrolytic capacitor.

## Reactance and impedance

Reactance is opposition to AC caused by capacitance or inductance. Unlike ordinary resistance, reactance changes with frequency.

Inductive reactance increases as frequency increases. This is why an RF choke can block radio-frequency current while letting lower-frequency or DC current pass more easily.

Capacitive reactance decreases as frequency increases. This is why a bypass capacitor can provide an easy path for unwanted RF while having little effect on audio when chosen correctly.

Impedance is the combined effect of resistance and reactance in an AC circuit. You can find it by comparing AC voltage with AC current.

## Try it

1. What does 400 Hz mean? A waveform completes 400 cycles each second.
2. If a signal level rises by about 7 dB, what rough power ratio can you use? About five times.
3. If transmitter power goes from 7 W to 21 W, what happened to the power? It became three times larger.
4. If frequency increases, what happens to inductive reactance? It increases.
5. If frequency increases, what happens to capacitive reactance? It decreases.

## Radio connection

Every tuned receiver and transmitter uses these ideas. A band change changes frequency and wavelength. An amplifier gain or feedline loss is often stated in dB. Chokes and bypass capacitors help keep RF out of places it should not go. Inductors and capacitors also form tuned circuits, which are the subject of the next lesson.

## Common mistakes

- Thinking dB is an absolute watt value. A decibel is a ratio between two levels.
- Forgetting that small positive dB changes multiply power, while negative dB changes reduce it.
- Treating inductors and capacitors as if their reactance stayed constant with frequency.
- Mixing up capacitor series and parallel rules.
- Ignoring electrolytic capacitor polarity.
- Confusing phase with polarity. Phase is AC timing; polarity is DC direction or sign.

## Illustration brief

Alt text: A split diagram showing a sine wave with one cycle marked and a frequency-reactance comparison for inductors and capacitors.

Description: Draw a smooth sine wave with a full cycle bracketed and labelled "cycle." Beside it, draw paired line graphs: inductive reactance rising as frequency rises, and capacitive reactance falling as frequency rises. Use distinct line styles, not colour alone, so the meaning survives grayscale rendering.

## Summary

- Frequency is cycles per second; wavelength gets shorter as frequency increases.
- Phase is timing difference between AC waveforms.
- Harmonics are integer multiples of a fundamental frequency.
- Decibels compare levels; positive values mean a power increase and negative values mean a power reduction.
- Inductors add in series; capacitors add in parallel.
- Inductive reactance increases with frequency; capacitive reactance decreases with frequency.
- Impedance combines resistance and reactance in AC circuits.
