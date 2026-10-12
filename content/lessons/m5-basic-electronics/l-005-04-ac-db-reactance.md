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
  - "Use simple dB power-ratio shortcuts, including S-meter readings above S9."
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

Alternating current, or AC, changes direction repeatedly. Radio signals are AC at radio frequencies. Audio tones, household power, and RF carriers are different in frequency. The same ideas of cycles, wavelength, phase, and reactance help describe them.

This lesson connects four areas: AC words, decibel shortcuts, simple capacitor and inductor combinations, and frequency-dependent opposition called reactance.

## Learning objectives

By the end of this lesson, you can:

- define frequency, wavelength, phase, sine wave, and harmonic;
- identify audio and HF frequency ranges as general radio concepts;
- recognize LF, MF, HF, and VHF as increasing frequency ranges;
- use common decibel power-ratio shortcuts and S-meter readings above S9;
- combine equal capacitors and inductors in simple series or parallel circuits;
- explain the construction factors for coils and capacitors; and
- predict how inductors and capacitors behave as AC frequency changes.

## AC basics

Frequency is the number of complete cycles per second. The unit is hertz. A 400 Hz tone completes 400 cycles each second.

Most humans can hear roughly 20 Hz to 20 000 Hz. That is why this range is called audio frequency. Radio frequencies are much higher. HF means high frequency and covers 3 MHz to 30 MHz, so many familiar shortwave amateur bands sit in HF. From lower to higher radio-frequency labels, the order is LF, MF, HF, then VHF.

Wavelength is the distance a signal travels during a complete cycle. As frequency increases, wavelength decreases. As wavelength gets shorter, frequency is higher.

Phase describes timing between waveforms. A pair of AC signals may have the same frequency but not start their cycles at the same instant; that timing difference is phase.

A sine wave is the smooth waveform associated with ideal AC. Household mains from a receptacle is AC and is intended to be sinusoidal. A harmonic is a signal at an integer multiple of a fundamental frequency, so harmonic signals sit above the fundamental at regular frequency intervals.

### Misconception: phase is the same as DC polarity

- Mistaken idea: phase and polarity are two names for the same thing.
- Correction: phase is timing between AC waveforms. DC polarity is positive and negative direction.

## Decibels as power ratios

The decibel compares two levels. Receiver signal reports may use an S-meter reading such as S9. For stronger signals, the report may add decibels above S9.

For example, a monitor reading of S9 plus 18 dB that loses 6 dB would be expected near S9 plus 12 dB. The change is subtracted from the amount above S9.

For Basic-level estimating, use practical power shortcuts:

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

::figure db-power-ratio-table
Alt text: Decibel power-ratio shortcut table for 3, 6, 10, and 20 dB changes, with increase and decrease columns.
Text equivalent:
- 3 dB: increase x 2, decrease ÷ 2.
- 6 dB: increase x 4, decrease ÷ 4.
- 10 dB: increase x 10, decrease ÷ 10.
- 20 dB: increase x 100, decrease ÷ 100.
::

### Worked example: gain

A 4 W handheld feeds a 7 dB gain amplifier. A 7 dB power increase is roughly a fivefold power change.

- Given: starting power = 4 W; gain = about 5:1.
- Find: estimated output power.
- Formula: output power = starting power x power ratio.
- Substitute: 4 W x 5.
- Answer: about 20 W.
- Sanity check: the estimate is above the starting power but still in a small-amplifier range.

### Worked example: feedline loss

A transmitter is 30 W and the line loss is 5 dB. A 5 dB loss leaves a bit less than a third of the original power.

- Given: starting power = 30 W; remaining ratio is about 0.3.
- Find: power reaching the antenna.
- Formula: antenna power = starting power x remaining ratio.
- Substitute: 30 W x 0.3.
- Answer: about 9 W.
- Sanity check: a loss must leave less power than the transmitter started with.

### Worked example: large power reduction

A test setup uses attenuators that leave 0.20 and 0.25 of the incoming power.

- Given: starting power = 24 W; remaining ratios are 0.20 and 0.25.
- Find: final power.
- Formula: final power = starting power x first ratio x second ratio.
- Substitute: 24 W x 0.20 x 0.25.
- Answer: 1.2 W.
- Sanity check: cascaded attenuators reduce power more than either attenuator alone.

### In the real world: dB on a station checklist

Antenna switches, filters, and feedlines may list gain or loss in dB. A short patch cable with a small loss may not matter much. A long feedline at VHF or UHF can lose enough power to change station performance.

The dB number is a ratio, not a watt value. You need the starting power before you can estimate the final power.

## Inductors and capacitors in combinations

An inductor stores energy in a magnetic field. A capacitor stores energy in an electric field.

The reference sheet gives these relationships:

| Component | Series total | Parallel total |
|---|---|---|
| Inductors | Lt = L1 + L2 + ... + Ln | 1 / Lt = 1 / L1 + 1 / L2 + ... + 1 / Ln |
| Capacitors | 1 / Ct = 1 / C1 + 1 / C2 + ... + 1 / Cn | Ct = C1 + C2 + ... + Cn |

Notice that capacitors are opposite to resistors for series and parallel totals. Inductors follow the resistor pattern in the simple ideal cases shown here.

### Worked example: equal parts

Equal parts often make the pattern easier to see.

- Given: two 7 mH inductors in series; two 18 mH inductors in parallel; two 33 µF capacitors in series; two 47 µF capacitors in parallel.
- Find: each total value.
- Formula: equal inductors add in series and halve in parallel; equal capacitors halve in series and add in parallel.
- Substitute: 7 + 7; 18 / 2; 33 / 2; 47 + 47.
- Answer: 14 mH, 9 mH, 16.5 µF, and 94 µF.
- Sanity check: the capacitor series answer is smaller than either capacitor, while the capacitor parallel answer is larger.

## What sets inductance and capacitance?

For an air-core coil, inductance depends mainly on the coil's size, its winding count, and its shape. Changing the diameter, length, or turn count changes the magnetic field. That changes the inductance.

For a simple air-spaced capacitor, capacitance depends on plate area and spacing. Larger facing plate area gives more capacitance. More spacing gives less capacitance.

Polarized electrolytic capacitors need correct polarity. Never apply reverse voltage to a polarized electrolytic capacitor.

### In the real world: power-supply filter capacitor

A filter capacitor in a power supply charges near the voltage peaks after rectification. Between peaks, it gives energy back to the load. That reduces ripple, which is unwanted rise and fall on the DC output.

This does not make a capacitor a battery. A capacitor stores energy in an electric field and charges or discharges quickly. A battery stores energy chemically and is meant to supply energy for longer.

## Reactance and impedance

Reactance is opposition to AC caused by capacitance or inductance. Unlike ordinary resistance, reactance changes with frequency.

Inductive reactance increases as frequency increases. This is why an RF choke can block radio-frequency current while letting lower-frequency or DC current pass more easily.

Capacitive reactance decreases as frequency increases. This is why a bypass capacitor can provide an easy path for unwanted RF while having little effect on audio when chosen correctly.

Impedance is the combined effect of resistance and reactance in an AC circuit. You can find it by comparing AC voltage with AC current.

### In the real world: ferrite choke on a noisy lead

A ferrite choke around a cable acts like an inductor for unwanted RF current. At radio frequencies it can add high reactance. At DC or low audio frequencies, it has much less effect on the intended power or audio path.

That is why snap-on ferrites are common on computer leads, charger leads, and station accessory cables. They are not magic noise erasers, but they can make an unwanted RF path harder to use.

### Misconception: reactance is fixed like a resistor value

- Mistaken idea: a stated reactance stays the same at every frequency.
- Correction: inductive reactance rises with frequency, while capacitive reactance falls with frequency.

## Try it

1. A 14.1 MHz signal has harmonics at integer multiples of that frequency. Which ranges contain its second and third harmonics? The second harmonic is 28.2 MHz, still HF; the third is 42.3 MHz, now VHF.
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
- Household mains is sinusoidal AC, while radio signals use much higher AC frequencies.
- HF spans 3 MHz to 30 MHz, with LF, MF, HF, and VHF in increasing frequency order.
- Decibels compare levels; positive values mean a power increase and negative values mean a power reduction.
- Inductors add in series; capacitors add in parallel.
- Inductive reactance increases with frequency; capacitive reactance decreases with frequency.
- Impedance combines resistance and reactance in AC circuits.
