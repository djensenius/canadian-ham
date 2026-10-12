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

A station is easier to learn when you draw it as blocks. Each block has one main job. A filter reduces unwanted RF products. A meter reports a condition. A tuner transforms impedance. A receiver turns a radio signal into audio in stages.

As you read, ask where the signal is at that moment. Put each block where it can act before the next cable, amplifier, or antenna carries the problem farther.

## Learning objectives

By the end of this lesson, you can:

- arrange common HF station accessories in a practical order;
- explain why a low-pass filter is placed near the transmitter or final amplifier output;
- describe how an FM transmitter turns voice audio into a frequency-varying RF signal;
- follow a superheterodyne receiver from antenna input to audio output; and
- distinguish RF, IF, detector, and AF blocks without needing a full schematic.

## The HF station as a chain

A simple HF station often follows this order:

```text
transceiver -> low-pass filter -> SWR meter -> antenna tuner -> antenna switch -> antenna or dummy load
```

SWR means standing wave ratio. It is a match reading based on forward and reflected waves on a transmission line. The SWR meter reports the match; it does not fix the match.

A low-pass filter passes the wanted HF signal and reduces higher-frequency harmonics. Harmonics are unwanted signals at whole-number multiples of the intended signal. The filter belongs close to the output stage that can make or amplify those harmonics.

An antenna tuner transforms impedance so the transmitter sees a safer load. It does not remove harmonics. Antenna impedance changes with frequency, so you may need to readjust the tuner after moving to a new frequency. An antenna switch selects the antenna path, test load, or unused position.

A dummy load is a non-radiating test load. It turns RF power into heat so you can tune or test without intentionally radiating a signal. Real dummy loads have power and time limits. If the case warms, stop and check the rating.

If an external RF power amplifier is used, the amplifier becomes the final RF source:

```text
transceiver -> external RF amplifier -> low-pass filter -> SWR meter -> tuner -> switch -> antenna
```

### In the real world: filter before the long jumper

A 14.2 MHz HF transmitter can also produce a second harmonic at 28.4 MHz.

- Given: wanted frequency = 14.2 MHz; harmonic number = 2.
- Find: second-harmonic frequency.
- Formula: harmonic frequency = operating frequency x harmonic number.
- Substitute: harmonic frequency = 14.2 MHz x 2.
- Answer: harmonic frequency = 28.4 MHz.
- Sanity check: the harmonic is above the wanted HF signal, so a low-pass filter can reduce it.

Place the low-pass filter before a long accessory cable. Then the cable is less likely to carry the unwanted harmonic around the station.

### Worked example: locating the filter

A 20 m transceiver feeds a borrowed linear amplifier. The station also has a power meter, a tuner, and a remote antenna switch. Put the low-pass filter at the first point after the last active RF source.

```text
20 m transceiver -> linear amplifier -> low-pass filter -> power meter -> tuner -> remote switch
```

If the amplifier is removed, the transceiver is the final RF source. The same rule still applies.

## FM transmitter blocks

A basic FM transmitter can be followed from voice to antenna:

```text
microphone -> speech amplifier -> modulator -> oscillator -> frequency multiplier -> power amplifier -> antenna system
```

The microphone turns the air-pressure changes of sound into a small electrical audio signal. The speech amplifier raises that signal. In FM, the modulator changes the oscillator frequency slightly above and below its centre value. Those small frequency changes carry the speech.

A frequency multiplier produces a useful harmonic of the oscillator signal. This lets the oscillator run at a stable lower frequency while later stages reach the desired RF carrier frequency. The power amplifier delivers the largest RF power to the antenna system, so it draws the most electrical power in this simplified chain.

### Worked example: a multiplier chain

A teaching transmitter uses an oscillator near 12.2 MHz and a multiplier stage that triples it.

- Given: oscillator frequency = 12.2 MHz; multiplier = 3.
- Find: output frequency.
- Formula: output frequency = oscillator frequency x multiplier.
- Substitute: output frequency = 12.2 MHz x 3.
- Answer: output frequency = 36.6 MHz.
- Sanity check: the output is three times the oscillator frequency.

If voice modulation moves the oscillator frequency a little, the multiplied output moves too. FM carries speech as a controlled frequency change, not as a planned amplitude change.

## Superheterodyne receiver blocks

A superheterodyne receiver does not process every signal at its original radio frequency all the way to the speaker. It converts the selected signal to an intermediate frequency, or IF. Filtering and gain are easier to make stable at a fixed IF.

A simplified FM receiver looks like this:

```text
antenna -> RF amplifier -> mixer -> IF filter -> IF amplifier -> limiter -> discriminator -> AF amplifier -> speaker
                         ^
                         local oscillator
```

The RF amplifier is the front end. It should add little noise, because weak signals can be spoiled before later stages help. The local oscillator sets the tune point. The mixer combines the incoming signal with the local oscillator signal to create the IF.

The IF filter provides adjacent-channel selectivity. The IF amplifier supplies most of the receiver gain before detection. For FM, the limiter removes unwanted amplitude changes. The discriminator recovers audio from frequency changes. The AF amplifier raises the recovered audio for headphones or a speaker. In this block view, volume and squelch controls act in the AF amplifier section.

### Worked example: IF conversion with original numbers

A training receiver is tuned to 146.520 MHz. It uses a 10.700 MHz IF, and the local oscillator is above the signal.

- Given: received frequency = 146.520 MHz; IF = 10.700 MHz.
- Find: local oscillator frequency.
- Formula: local oscillator = received frequency + IF.
- Substitute: local oscillator = 146.520 MHz + 10.700 MHz.
- Answer: local oscillator = 157.220 MHz.
- Sanity check: with high-side injection, the oscillator is above the received signal.

The mixer makes several products. The IF stages keep the 10.700 MHz difference product and reject the rest.

## Try it

1. A transmitter on 7.1 MHz can create a second harmonic. Where is that harmonic? It is at 7.1 MHz x 2 = 14.2 MHz.
2. Why should the harmonic filter act before a long accessory cable? The unwanted energy should be reduced before the cable can carry it around the station.
3. An FM exciter at 10.000 MHz has an instant when modulation nudges it 1.5 kHz above centre. A doubler follows. What are the doubled centre frequency and offset? The centre becomes 20.000 MHz, and the 1.5 kHz offset becomes 3.0 kHz.
4. A superheterodyne receiver has a noisy first RF stage. Why can later audio gain not fully repair that problem? Later gain amplifies the wanted signal and the noise already added.
5. A receiver with a 9.000 MHz IF tunes 28.400 MHz with a high-side oscillator. What oscillator frequency is the first estimate? Add the IF: 28.400 MHz + 9.000 MHz = 37.400 MHz.

## Radio connection

Block diagrams turn a vague symptom into a place to look. A harmonic problem points near the final RF output and low-pass filter. Poor adjacent-channel rejection points toward receiver filtering. High SWR points toward the antenna system, feedline, matching device, or connectors.

## Common mistakes

- Putting a low-pass filter at the far end of the accessory chain instead of near the final RF source.
- Expecting an antenna tuner to reduce harmonics; that is the filter's job.
- Treating an SWR meter as if it changes the match; it measures, while the tuner transforms impedance.
- Thinking FM means the transmitter's amplitude is intentionally varied by speech.
- Confusing IF amplification with audio amplification. IF stages still handle radio-frequency signals at the intermediate frequency.

::figure station-filtering-radio-blocks
Alt text: Two block diagrams show an HF station accessory chain and an FM superheterodyne receiver chain, with arrows marking signal flow.
Text equivalent:
- HF station chain: transceiver or amplifier, low-pass filter close to the final RF output, SWR meter, tuner, antenna switch, antenna, or dummy load.
- FM superheterodyne receiver chain: antenna, RF amplifier, mixer with local oscillator, IF filter, IF amplifier, limiter, discriminator/audio stages, and speaker.
::

## Illustration brief

Alt text: Two block diagrams show an HF station accessory chain and an FM superheterodyne receiver chain, with arrows marking signal flow.

Description: Draw a brush-style station chain across the top: transceiver or amplifier, low-pass filter, SWR meter, tuner, antenna switch, antenna or dummy load. Highlight the low-pass filter as close to the final RF output. Below it, draw a receiver chain with antenna, RF amplifier, mixer, IF filter, IF amplifier, limiter, discriminator, AF amplifier, and speaker. Add a local oscillator arrow into the mixer.

## Summary

- Draw station equipment as signal-flow blocks.
- A low-pass filter belongs close to the final RF source.
- An SWR meter measures match; a tuner transforms impedance; a dummy load absorbs RF as heat.
- In an FM transmitter, speech changes oscillator frequency through the modulator.
- A superheterodyne receiver converts the selected RF signal to an IF for stable filtering and gain.
- The RF amplifier, mixer, local oscillator, IF filter, IF amplifier, detector, and AF amplifier each solve a different receive problem.
