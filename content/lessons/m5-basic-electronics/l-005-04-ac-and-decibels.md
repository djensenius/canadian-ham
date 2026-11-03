---
type: lesson
id: L-005-04
moduleId: M5
categoryIds:
  - B-005
title:
  en: "AC and decibels"
  fr: null
covers:
  - B-005-007
  - B-005-008
objectives:
  - "Describe frequency, wavelength, phase, harmonics, and audio range."
  - "Use simple dB power-ratio shortcuts, including S-meter readings above S9."
prerequisites:
  - L-005-03
estimatedMinutes: 30
quizIds:
  - QZ-L-005-04-A
status: draft
---
# AC and decibels

Alternating current, or AC, changes direction repeatedly. Radio signals are AC at radio frequencies. Audio tones, household power, and RF carriers are different in frequency. The same ideas of cycles, wavelength, phase, and harmonics help describe them.

This lesson also introduces decibels. A decibel is a ratio, not a watt value. It lets radio operators describe gain, loss, and signal-strength changes without writing long multiplication chains.

## Learning objectives

By the end of this lesson, you can:

- define frequency, wavelength, phase, sine wave, and harmonic;
- identify audio and HF frequency ranges as general radio concepts;
- recognize LF, MF, HF, and VHF as increasing frequency ranges;
- use common decibel power-ratio shortcuts; and
- adjust an S-meter reading that is stated in decibels above S9.

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

The decibel compares two levels. Receiver signal reports may use an S-meter, the receiver's signal-strength meter. A reading such as S9 can be extended with decibels above S9 for stronger signals.

For example, a monitor reading of S9 plus 18 dB that loses 6 dB would be expected near S9 plus 12 dB. The change is subtracted from the amount above S9.

For Basic-level estimating, use practical power shortcuts. Decibel values add when power ratios multiply. For example, three +3 dB steps stack to about 8x power. A +10 dB step followed by a -3 dB step leaves about 5x power. Three -10 dB steps stack to 1/10 x 1/10 x 1/10, or 1/1000 power.

When attenuators are cascaded, add their dB losses first and then convert the total. A 13 dB loss uses the tenfold-loss row plus one 3 dB loss step, so its ratio is about 0.1 x 0.5 = 0.05.

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
- 3 dB: increase approximately x 2, decrease approximately / 2.
- 6 dB: increase approximately x 4, decrease approximately / 4.
- 10 dB: increase x 10, decrease / 10.
- 20 dB: increase x 100, decrease / 100.
::

### Worked example: gain

A 4 W handheld feeds a 7 dB gain amplifier.

- Given: starting power = 4 W; gain = 7 dB.
- Find: estimated output power.
- Formula: 7 dB is 3 dB below the tenfold-gain row, so use that row and then halve it.
- Substitute: 4 W x tenfold x 0.5.
- Answer: about 20 W.
- Sanity check: the estimate is above the starting power but still in a small-amplifier range.

### Worked example: feedline loss

A transmitter is 44 W and the line loss is 7 dB.

- Given: starting power = 44 W; loss = 7 dB.
- Find: power reaching the antenna.
- Formula: 7 dB loss is one 3 dB step less loss than the tenfold-loss row, so use 0.1 / 0.5 = 0.2.
- Substitute: 44 W x 0.2.
- Answer: about 8.8 W.
- Sanity check: a loss must leave less power than the transmitter started with.

### Worked example: large power reduction

A test setup uses cascaded attenuators with a total loss of 13 dB.

- Given: starting power = 24 W; total loss = 13 dB.
- Find: final power.
- Formula: 13 dB loss uses the tenfold-loss row plus one 3 dB loss step, so the ratio is 0.1 x 0.5.
- Substitute: 24 W x 0.1 x 0.5.
- Answer: about 1.2 W.
- Sanity check: adding dB losses is the same as multiplying their power ratios.

### Faded practice: finish cascaded losses

A bench setup has two attenuators in series.

- Given: input power = 18 W; losses = 3 dB and 10 dB.
- Find: total dB loss and approximate output power.
- Formula: add dB losses; multiply the corresponding power ratios.
- Complete: total loss = 3 + ___ = ___ dB; output ≈ 18 x 0.5 x ___ = ___ W.
- Sanity check: Must a loss leave less power than the input?

Fill the gaps before checking below.

### Check your work: finish cascaded losses

Total loss = 13 dB. Output ≈ 18 x 0.5 x 0.1 = 0.9 W. These are Basic-level dB shortcuts, so the result is approximate.

### In the real world: dB on a station checklist

Antenna switches, filters, and feedlines may list gain or loss in dB. A short patch cable with a small loss may not matter much. A long feedline at VHF or UHF can lose enough power to change station performance.

The dB number is a ratio, not a watt value. You need the starting power before you can estimate the final power.

### Worked example: power ratio to S-meter reading

A station is reported as S9 plus 25 dB while transmitting 80 W. The operator reduces power to 40 W.

- Given: 80 W to 40 W is a -3 dB power change.
- Find: the new S-meter reading above S9.
- Formula: subtract the dB reduction from the amount above S9.
- Substitute: 25 dB - 3 dB.
- Answer: S9 plus 22 dB.
- Sanity check: the signal is still above S9, but by a smaller amount.

### Faded practice: finish a signal-report adjustment

Assume the propagation path and receiver settings stay unchanged.

- Given: initial report = S9 plus 19 dB; transmitter power falls from 48 W to 24 W.
- Find: new amount above S9.
- Formula: halving power is a drop of about 3 dB; subtract 3 dB from the initial amount above S9.
- Complete: new report = S9 plus (19 - ___) dB = S9 plus ___ dB.
- Sanity check: Is the report lower while still above S9?

Fill the gaps before checking below.

### Check your work: finish a signal-report adjustment

The report is about S9 plus 16 dB. This compares received levels; it is not a change in the report's readability part.

## Try it

Try these before reading the feedback below.

1. Which ranges contain the second and third harmonics of 14.1 MHz?

:::answer
The second is 28.2 MHz, in HF; the third is 42.3 MHz, in VHF.
:::

2. What rough power ratio matches a rise of about 7 dB?

:::answer
About five times: tenfold gain followed by a halving.
:::

3. What approximate dB change matches an eightfold power rise?

:::answer
About +9 dB, using three approximate doubling steps.
:::

## Radio connection

Every receiver and transmitter uses AC ideas. A band change changes frequency and wavelength. An amplifier gain or feedline loss is often stated in dB. Later lessons use these ideas when they explain reactance, tuned circuits, antennas, signal reports, and interference.

## Common mistakes

- Thinking dB is an absolute watt value. A decibel is a ratio between two levels.
- Forgetting that small positive dB changes multiply power, while negative dB changes reduce it.
- Confusing phase with polarity. Phase is AC timing; polarity is DC direction or sign.
- Treating a harmonic as a random nearby signal instead of an integer multiple of a starting frequency.

## Illustration brief

Alt text: A split diagram showing a sine wave with one cycle marked beside a decibel power-ratio shortcut table.

Description: Draw a smooth sine wave with a full cycle bracketed and labelled "cycle." Beside it, draw a compact table or ladder showing +3 dB as about 2x power, +10 dB as 10x power, and loss steps as the matching reductions. Use labels and line patterns rather than colour alone.

## Summary

- Frequency is cycles per second; wavelength gets shorter as frequency increases.
- Phase is timing difference between AC waveforms.
- Harmonics are integer multiples of a fundamental frequency.
- Audio, HF, LF, MF, and VHF name useful frequency ranges.
- Decibels compare levels; positive values mean a power increase and negative values mean a power reduction.
- Add dB values when gain or loss steps are cascaded, then convert the total to a power ratio.
