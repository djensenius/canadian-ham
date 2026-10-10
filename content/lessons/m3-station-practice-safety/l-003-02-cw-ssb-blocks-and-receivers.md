---
type: lesson
id: L-003-02
moduleId: M3
categoryIds:
  - B-003
title:
  en: "CW, SSB, and receiver signal paths"
  fr: null
covers:
  - B-003-004
  - B-003-005
  - B-003-006
objectives:
  - "Describe the oscillator, buffer, and amplifier roles in a CW transmitter."
  - "Trace SSB/CW receiver stages from antenna to speaker."
  - "Explain how SSB transmitters create and filter sidebands."
prerequisites:
  - L-003-01
estimatedMinutes: 50
quizIds:
  - QZ-L-003-02-A
status: draft
---
# CW, SSB, and receiver signal paths

CW and SSB are both narrow and efficient modes, but their block diagrams do different jobs. A CW transmitter keys a carrier. An SSB transmitter starts with speech, creates sidebands, removes the unwanted parts, and then moves the result to the operating frequency. A matching receiver reverses the trip by selecting one signal, converting it to IF, and recovering audio with the right detector.

The goal is not to memorize a circuit. The goal is to recognize what each block contributes to the signal path.

## Learning objectives

By the end of this lesson, you can:

- explain why a CW oscillator needs stability and buffering;
- describe what the key controls in a simple CW transmitter;
- trace antenna, RF amplifier, mixer, IF filter, IF amplifier, product detector, BFO, AF amplifier, and speaker in an SSB/CW receiver;
- explain how a fixed RF oscillator, speech amplifier, balanced modulator, sideband filter, mixer, VFO, and final amplifier fit into an SSB transmitter; and
- use simple sum-and-difference mixing examples with original numbers.

## Basic CW transmitter stages

A simple CW transmitter can be sketched as:

```text
oscillator -> driver/buffer -> power amplifier -> antenna system
                 ^                  ^
                 stable drive       keyed carrier power
```

The oscillator supplies the RF signal at the transmitted frequency in this basic diagram. It must be stable because drift or pulling becomes a directly transmitted error. A driver or buffer stage isolates the oscillator from load changes caused by later stages. Without buffering, changes in the amplifier or antenna system can tug the oscillator frequency around.

The transmitter stages are powered by direct current from the station power supply. The RF signal is created and amplified by the stages; the DC supply is the energy source. The key controls the carrier so Morse characters become on-off RF energy. Practical keying also uses controlled rise and fall times; edges that are too abrupt can spread energy as clicks. At the output, the power amplifier raises the signal to the station's intended transmit power.

### In the real world: chirp can start with power

A small CW transmitter may sound clean on receive, then chirp when it transmits at higher power. The higher current can pull the supply voltage down for an instant. That voltage change can tug the oscillator unless the supply, oscillator, and buffer are stable.

Before blaming the antenna, check supply voltage under load, keying shape, and whether the oscillator is isolated from the power stage.

### Worked example: why a buffer helps

Imagine a practice oscillator adjusted to 7.040 MHz. When a power stage is connected directly, its input loading changes slightly as it heats. If that loading shifts the oscillator by even 120 Hz, the note heard by another operator can sound unsteady.

Adding a buffer is like adding a one-way helper between a delicate source and a heavier load. The oscillator sees a steadier load, and the power stage still receives RF drive.

## SSB/CW receiver path

An SSB/CW receiver shares many superheterodyne blocks with other receivers, but the detector and audio filtering are chosen for narrow modes:

```text
antenna -> RF amplifier -> mixer -> IF filter -> IF amplifier -> product detector -> AF amplifier -> speaker
                         ^                                      ^
                         local oscillator                       beat frequency oscillator
```

The antenna converts the radio wave into a tiny current. The RF amplifier improves sensitivity when it adds useful gain without adding too much noise. The mixer and local oscillator convert the selected RF signal to IF. The IF filter gives most of the receiver's selectivity by keeping the desired narrow slice and rejecting nearby signals.

The IF amplifier provides most of the receiver gain after the desired signal has been converted and selected. The product detector needs a beat frequency oscillator, or BFO, so it can recover the missing carrier information used to turn SSB or CW back into audio. The AF amplifier raises the recovered audio level for headphones or a speaker. An audio band-pass filter may be placed in the AF chain to make CW tones easier to copy.

### Worked example: product detection idea

A receiver's IF signal is centred near 9.000 MHz, and the BFO is set so the product detector produces an 800 Hz CW tone. The exact internal frequencies are less important than the relationship: the detector mixes the incoming IF energy with a local reference and the difference becomes audio.

```text
small RF/IF frequency difference -> audio tone in hertz
```

That is why a CW operator can tune a signal for a comfortable tone instead of hearing silence from an unmodulated carrier.

## SSB transmitter path

A typical SSB transmitter can be shown as:

```text
microphone -> speech amplifier -> balanced modulator -> sideband filter -> mixer -> driver/final amplifier
                         ^                              ^
                         fixed RF oscillator            variable frequency oscillator
```

The microphone signal is small, so the speech amplifier raises the audio. The fixed RF oscillator supplies a carrier frequency for the balanced modulator. The balanced modulator combines audio and RF while suppressing most of the carrier, creating upper and lower sideband energy. The sideband filter, usually near the fixed oscillator frequency, removes the unwanted sideband.

The remaining single-sideband signal is still not necessarily at the operating frequency. A mixer uses a variable frequency oscillator, or VFO, to move it to the chosen transmit frequency. Later driver and final amplifier stages raise it to useful output power. The final amplifier is also where modern radios commonly monitor output conditions such as excessive SWR and reduce power or protect themselves.

### Worked example: translating an SSB signal

A training exciter produces a filtered SSB signal near 8.998 MHz. A VFO is set to 5.200 MHz, and the design uses the sum product.

```text
operating output = filtered SSB frequency + VFO frequency
operating output = 8.998 MHz + 5.200 MHz
operating output = 14.198 MHz
```

The voice information has not changed into a different message. The mixer has moved the whole sideband signal to another RF frequency.

## Try it

Question: A filtered SSB signal at 9.000 MHz is mixed with a 5.000 MHz VFO, and the transmitter design selects the difference product. What output frequency should the next filter pass, and what other mixer product should it reject?

Worked answer: The difference product is 9.000 MHz - 5.000 MHz = 4.000 MHz, so that is the wanted output. The same mixer also creates a sum product at 14.000 MHz, which later filtering should reject.

Question: A receiver has both a 500 Hz IF filter and a 2.4 kHz IF filter. Predict which one will admit more nearby signals during a narrow CW contact, and why.

Worked answer: The 2.4 kHz filter admits more nearby spectrum. The 500 Hz filter is narrower, so less off-frequency energy reaches the detector.

Question: A CW operator moves the BFO 400 Hz higher while leaving the IF signal selected. What changes at the speaker?

Worked answer: The recovered tone pitch shifts by the BFO change. The product detector is comparing the IF energy with that local reference to make audio.

Question: A filtered voice sideband is centred at 9.001 MHz and mixed with a 12.500 MHz VFO using the sum output. What centre frequency leaves the mixer, and what happens to the voice information?

Worked answer: The centre moves to 9.001 MHz + 12.500 MHz = 21.501 MHz. The voice information moves with the translated sideband; the mixer changes the RF frequency rather than the message.

## Radio connection

When an SSB signal sounds badly tuned, the receiver may be only a few tens of hertz away from the best setting. When a CW signal sounds like it slides during each keying element, the transmitter oscillator or power supply may be unstable. Block diagrams help you decide whether to look near the oscillator, the filter, the detector, or the audio controls.

## Common mistakes

- Thinking the CW key sends an audio tone over the air. In basic CW transmission, the RF carrier is switched on and off.
- Treating the buffer as a power amplifier only. Its isolation role is just as important.
- Confusing the local oscillator with the BFO. The local oscillator helps create the IF; the BFO helps recover audio in the product detector.
- Assuming an SSB sideband filter is an audio tone-control filter. It operates near the transmitter's fixed RF/IF generation frequency.
- Swapping the balanced modulator and mixer jobs. The balanced modulator creates sideband energy from audio and RF; the mixer moves the filtered SSB signal to the operating frequency.

## Illustration brief

Alt text: Three labelled block diagrams show a CW transmitter, an SSB/CW receiver, and an SSB transmitter with signal-flow arrows.

Description: Draw three stacked brush diagrams. The CW row has oscillator, buffer, and power amplifier, with a key symbol controlling the carrier. The receiver row has antenna, RF amplifier, mixer with local oscillator, IF filter, IF amplifier, product detector with BFO, AF amplifier, and speaker. The SSB transmitter row has microphone, speech amplifier, balanced modulator with fixed RF oscillator, sideband filter, mixer with VFO, and final amplifier.

## Summary

- A basic CW transmitter creates a stable RF carrier, buffers it, amplifies it, and keys it on and off.
- Receiver selectivity mainly comes from IF filtering; in the SSB/CW block diagram, the IF amplifier provides most receiver gain while the RF amplifier mainly protects weak-signal sensitivity.
- A product detector and BFO recover SSB and CW audio from the IF signal.
- An SSB transmitter uses a speech amplifier, balanced modulator, sideband filter, mixer, VFO, and final amplifier in sequence.
- Mixing creates sum and difference products; filters choose the product the radio needs.
