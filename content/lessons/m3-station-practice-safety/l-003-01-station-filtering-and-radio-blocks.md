---
type: lesson
id: L-003-01
moduleId: M3
categoryIds:
  - B-003
title:
  en: "Station filtering and radio blocks"
  fr: null
covers:
  - B-003-001
  - B-003-002
  - B-003-003
objectives:
  - "Place low-pass filters in a basic HF station."
  - "Trace audio through an FM transmitter."
  - "Name the main blocks of a superheterodyne receiver."
prerequisites: []
estimatedMinutes: 45
quizIds:
  - QZ-L-003-01-A
status: draft
---
# Station filtering and radio blocks

A station is easier to understand when you draw it as blocks instead of as a nest of cables. Each block has one main job. A filter cleans up unwanted RF products, a meter tells you how well the load is matched, an antenna tuner helps the transmitter see a usable load, and a receiver changes a radio signal into audio in several smaller steps.

In this lesson, keep asking one question: where is the unwanted or wanted signal at this moment? The best place for a block is usually where it can act before the next cable, amplifier, or antenna carries the problem farther along.

## Learning objectives

By the end of this lesson, you can:

- arrange common HF station accessories in a practical order;
- explain why a low-pass filter is placed near the transmitter or final amplifier output;
- describe how an FM transmitter turns voice audio into a frequency-varying RF signal;
- follow a superheterodyne receiver from antenna input to audio output; and
- distinguish RF, IF, detector, and AF blocks without needing a full schematic.

## The HF station as a chain

A simple HF station can be sketched as this chain:

```text
transceiver -> low-pass filter -> SWR meter -> antenna tuner -> antenna switch -> antenna or dummy load
```

If an external RF power amplifier is used, think of the amplifier as the new final RF source:

```text
transceiver -> external RF amplifier -> low-pass filter -> SWR meter -> tuner -> switch -> antenna
```

A low-pass filter passes the wanted HF signal while reducing energy at higher frequencies. Harmonics are higher-frequency multiples of the intended signal, so the filter belongs close to the output that can create or amplify those harmonics. Placing it later in the shack may leave an unnecessary length of cable carrying unwanted RF energy.

An SWR meter samples forward and reflected power so you can judge how well the transmitter is matched to the antenna system. An antenna tuner does not magically make a poor antenna efficient; it transforms impedance so the transmitter or amplifier sees a safer load. Because antenna impedance changes with frequency, the tuner may need readjustment after a frequency change even though the cables have not moved. An antenna switch chooses which antenna path, test load, or unused position is connected.

A dummy load is a non-radiating test load. It turns RF power into heat so you can tune or test without intentionally putting a signal on the air. Real dummy loads also have power and time limits, so a warming case is a reason to pause and check the rating.

### Worked example: locating the filter

A 20 m transceiver feeds a borrowed linear amplifier, then a short accessory tray with a power meter, a tuner, and a remote antenna switch. The filter question is not about which accessory is easiest to reach; it is about the first point after the last active RF source.

```text
20 m transceiver -> linear amplifier -> low-pass filter -> power meter -> tuner -> remote switch
```

If the amplifier is removed for a low-power test, the transceiver becomes the last active RF source for that path. The same rule still applies: put the filter close to the output that is actually delivering RF to the rest of the station.

## FM transmitter blocks

A basic FM transmitter can be followed from voice to antenna:

```text
microphone -> speech amplifier -> modulator -> oscillator -> frequency multiplier -> power amplifier -> antenna system
```

The microphone changes air pressure into a small electrical audio signal. The speech amplifier raises that signal to a useful level. In FM, the modulator changes the oscillator's frequency slightly above and below its centre value. Those frequency changes are the modulation.

A frequency multiplier produces a useful harmonic of the oscillator signal. Multipliers let the oscillator run at a convenient stable frequency while later stages reach the desired RF carrier frequency. Because multiplication scales frequency, a small FM frequency deviation is multiplied by the same factor. The power amplifier is the block that delivers the largest RF power to the antenna system, so it draws the most electrical power in this simplified chain.

### Worked example: a multiplier chain

A teaching transmitter uses an oscillator near 12.2 MHz and a multiplier stage that triples it.

```text
12.2 MHz x 3 = 36.6 MHz
```

If the voice modulator makes the oscillator frequency move slightly, the multiplied output moves too. The speech is carried as a controlled change in frequency, not as a change in RF amplitude.

## Superheterodyne receiver blocks

A superheterodyne receiver does not process every signal at its original radio frequency all the way to the speaker. Instead, it converts the selected signal to an intermediate frequency, or IF, where filtering and gain can be made stable and repeatable.

A simplified FM receiver looks like this:

```text
antenna -> RF amplifier -> mixer -> IF filter -> IF amplifier -> limiter -> discriminator -> AF amplifier -> speaker
                         ^
                         local oscillator
```

The RF amplifier is the front-end block. It must add as little noise as practical because weak signals can be spoiled before later stages have a chance to help. The local oscillator sets the tune point. The mixer combines the incoming signal with the local oscillator signal to create the IF. The IF filter provides adjacent-channel selectivity. The IF amplifier supplies most of the gain before detection.

For FM, the limiter removes unwanted amplitude variations. The discriminator recovers the original modulation from the frequency variations. The AF amplifier then raises the recovered audio to a useful level; volume and squelch are associated with this audio section in the block-level view.

### Worked example: IF conversion with original numbers

Suppose a training receiver is tuned to 146.520 MHz and uses a 10.700 MHz IF with the local oscillator above the signal.

```text
local oscillator frequency = received frequency + IF
local oscillator frequency = 146.520 MHz + 10.700 MHz
local oscillator frequency = 157.220 MHz
```

The mixer output includes several products, but the IF stages are designed to keep the 10.700 MHz difference product and reject the rest.

## Try it

Question: A 14.2 MHz transmitter can also create energy at 28.4 MHz. Explain why the harmonic filter should act before a long accessory cable.

Worked answer: The unwanted 28.4 MHz energy should be reduced before the cable carries it around the station. Filtering late may leave extra wiring radiating or coupling the harmonic.

Question: An FM exciter at 10.000 MHz has an instant when modulation nudges it 1.5 kHz above centre, and then a doubler follows. What are the doubled centre frequency and the doubled instant offset?

Worked answer: The doubled centre frequency is 20.000 MHz. The 1.5 kHz upward deviation is doubled too, so the output is 3.0 kHz above its centre at that instant.

Question: A superheterodyne receiver has a noisy first RF stage. Why can later audio gain not fully repair that problem?

Worked answer: Later gain amplifies the wanted signal and the noise that was already added. A low-noise front end protects weak signals before conversion and detection.

Question: In a receiver with a 9.000 MHz IF, a signal at 28.400 MHz uses a high-side oscillator. What oscillator frequency is the first estimate?

Worked answer: Add the IF to the received signal: 28.400 MHz + 9.000 MHz = 37.400 MHz.

## Radio connection

When another station reports that your signal is causing TV or VHF interference, a low-pass filter near the transmitting output is one of the first station-layout items to check. When your receiver has poor adjacent-channel rejection, the IF filter is the block to think about. The same block-diagram habit turns a vague symptom into a likely area to inspect.

## Common mistakes

- Putting a low-pass filter at the far end of the accessory chain instead of near the final RF source.
- Expecting an antenna tuner to reduce harmonics; that is the filter's job.
- Treating an SWR meter as if it changes the match; it measures, while the tuner transforms impedance.
- Thinking FM means the transmitter's amplitude is intentionally varied by speech.
- Confusing IF amplification with audio amplification. IF stages still handle radio-frequency signals at the intermediate frequency.

## Illustration brief

Alt text: Two block diagrams show an HF station accessory chain and an FM superheterodyne receiver chain, with arrows marking signal flow.

Description: Draw a brush-style station chain across the top: transceiver or amplifier, low-pass filter, SWR meter, tuner, antenna switch, antenna or dummy load. Highlight the low-pass filter as close to the final RF output. Below it, draw a receiver chain with antenna, RF amplifier, mixer, IF filter, IF amplifier, limiter, discriminator, AF amplifier, and speaker. Add a local oscillator arrow into the mixer.

## Summary

- A low-pass filter belongs close to the final RF output stage: the transceiver output when no external amplifier is used, or the external amplifier output when one is used.
- SWR meters measure match, antenna tuners transform impedance, antenna switches select paths, and dummy loads absorb RF without intended radiation.
- In an FM transmitter, speech audio changes oscillator frequency through the modulator.
- A superheterodyne receiver converts the selected RF signal to an IF so stable filtering and gain can be applied.
- The RF amplifier, mixer, local oscillator, IF filter, IF amplifier, detector, and AF amplifier each solve a different part of the receive problem.
