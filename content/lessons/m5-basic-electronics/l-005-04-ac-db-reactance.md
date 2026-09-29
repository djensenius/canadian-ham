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
- identify audio and HF frequency ranges used in the question bank;
- use 3 dB, 6 dB, 9 dB, 10 dB, and 30 dB power-ratio shortcuts;
- combine equal capacitors and inductors in simple series or parallel circuits;
- explain the construction factors for coils and capacitors; and
- predict how inductors and capacitors behave as AC frequency changes.

## AC basics

Frequency is the number of complete cycles per second. The unit is hertz. A 400 Hz tone completes 400 cycles each second.

Most humans can hear roughly 20 Hz to 20 000 Hz. That is why this range is called audio frequency. Radio frequencies are much higher. For example, a signal around 14 MHz is in the HF range.

Wavelength is the distance a signal travels during one complete cycle. As frequency increases, wavelength decreases. As wavelength gets shorter, frequency is higher.

Phase describes timing between waveforms. Two AC signals may have the same frequency but not start their cycles at the same instant; that timing difference is phase.

A sine wave is the smooth waveform associated with ideal AC. A harmonic is a signal at an integer multiple of a fundamental frequency. If a fundamental is 1.5 kHz, then 3 kHz is the second harmonic.

## Decibels as power ratios

The decibel compares two levels. In these Basic questions, use practical power shortcuts:

| dB change | Power ratio |
|---:|---:|
| +3 dB | multiply power by about 2 |
| -3 dB | divide power by about 2 |
| +6 dB | multiply power by 4 |
| -6 dB | divide power by 4 |
| +9 dB | multiply power by 8 |
| +10 dB | multiply power by 10 |
| -10 dB | divide power by 10 |
| -30 dB | divide power by 1000 |

### Worked example: gain

A 3 W handheld feeds a 7 dB gain amplifier. A 7 dB power increase can be estimated as +10 dB followed by -3 dB.

- +10 dB multiplies by 10: 3 W becomes 30 W.
- -3 dB cuts that approximately in half: 30 W becomes about 15 W.

The output is about 15 W.

### Worked example: feedline loss

A transmitter is 40 W and the line loss is 3 dB.

- A 3 dB loss divides power by about 2.
- 40 W / 2 = 20 W.

About 20 W reaches the antenna.

### Worked example: large power reduction

If a station needs a 20 dB reduction for a close-range test, the power must be divided by 100. A reduction from 25 W to 0.25 W is two 10 dB steps.

For a 30 dB reduction, divide by 1000. A 250 W signal reduced by 30 dB becomes 0.25 W.

## Inductors and capacitors in combinations

An inductor stores energy in a magnetic field. A capacitor stores energy in an electric field.

The reference sheet gives these relationships:

| Component | Series total | Parallel total |
|---|---|---|
| Inductors | Lt = L1 + L2 + ... + Ln | 1 / Lt = 1 / L1 + 1 / L2 + ... + 1 / Ln |
| Capacitors | 1 / Ct = 1 / C1 + 1 / C2 + ... + 1 / Cn | Ct = C1 + C2 + ... + Cn |

Notice that capacitors are opposite to resistors for series and parallel totals. Inductors follow the resistor pattern in the simple ideal cases shown here.

### Worked examples

- Two equal inductors in series make twice the inductance of one.
- Two equal inductors in parallel make half the inductance of one.
- Two equal capacitors in series make half the capacitance of one.
- Two equal capacitors in parallel make twice the capacitance of one.

So two 7 mH chokes in series make 14 mH. Two 18 mH inductors in parallel make 9 mH. Two 33 µF capacitors in series make 16.5 µF. Two 47 µF capacitors in parallel make 94 µF.

## What sets inductance and capacitance?

For an air-core coil, inductance depends mainly on coil diameter, coil length, and number of turns. A larger or longer coil, or more turns, changes the magnetic field and therefore the inductance.

For a simple air-spaced capacitor, capacitance depends on plate area and spacing. Larger facing plate area gives more capacitance. More spacing gives less capacitance.

Polarized electrolytic capacitors need correct polarity. Never apply reverse voltage to a polarized electrolytic capacitor.

## Reactance and impedance

Reactance is opposition to AC caused by capacitance or inductance. Unlike ordinary resistance, reactance changes with frequency.

Inductive reactance increases as frequency increases. This is why an RF choke can block radio-frequency current while letting lower-frequency or DC current pass more easily.

Capacitive reactance decreases as frequency increases. This is why a bypass capacitor can provide an easy path for unwanted RF while having little effect on audio when chosen correctly.

Impedance is the combined effect of resistance and reactance in an AC circuit. It is also the ratio of AC voltage to AC current.

## Try it

1. What does 400 Hz mean? Four hundred complete cycles each second.
2. If power doubles, what is the dB change? About +3 dB.
3. If transmitter power goes from 4 W to 40 W, the power ratio is 10, so the gain is 10 dB.
4. If frequency increases, what happens to inductive reactance? It increases.
5. If frequency increases, what happens to capacitive reactance? It decreases.

## Radio connection

Every tuned receiver and transmitter uses these ideas. A band change changes frequency and wavelength. An amplifier gain or feedline loss is often stated in dB. Chokes and bypass capacitors help keep RF out of places it should not go. Inductors and capacitors also form tuned circuits, which are the subject of the next lesson.

## Common mistakes

- Thinking dB is an absolute watt value. A decibel is a ratio between two levels.
- Forgetting that +3 dB is approximately double power, while +10 dB is ten times power.
- Treating inductors and capacitors as if their reactance stayed constant with frequency.
- Mixing up capacitor series and parallel rules.
- Ignoring electrolytic capacitor polarity.
- Confusing phase with polarity. Phase is AC timing; polarity is DC direction or sign.

## Illustration brief

Alt text: A split diagram showing a sine wave with one cycle marked and a frequency-reactance comparison for inductors and capacitors.

Description: Draw a smooth sine wave with one full cycle bracketed and labelled "one cycle." Beside it, draw two simple line graphs: inductive reactance rising as frequency rises, and capacitive reactance falling as frequency rises. Use distinct line styles, not colour alone, so the meaning survives grayscale rendering.

## Summary

- Frequency is cycles per second; wavelength gets shorter as frequency increases.
- Phase is timing difference between AC waveforms.
- Harmonics are integer multiples of a fundamental frequency.
- Decibels compare levels; 3 dB is about a factor of 2 in power, and 10 dB is a factor of 10.
- Inductors add in series; capacitors add in parallel.
- Inductive reactance increases with frequency; capacitive reactance decreases with frequency.
- Impedance combines resistance and reactance in AC circuits.
