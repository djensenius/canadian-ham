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

CW and SSB are narrow, efficient modes. They use different blocks. A CW transmitter keys a carrier. An SSB transmitter starts with speech, creates sidebands, removes unwanted parts, and moves the result to the operating frequency.

A receiver reverses the trip. It selects one signal, converts it to IF, and recovers audio with the right detector. The goal is to know each block's job, not to memorize a full circuit.

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

The oscillator generates the RF signal at the frequency that will be transmitted. It must be stable because drift becomes a transmitted error. A driver or buffer isolates the oscillator from load changes caused by later stages.

The station power supply provides direct current. The RF stages create and amplify the RF signal from that energy. The oscillator keeps running; the key controls carrier amplitude in a driver or amplifier stage so Morse characters become on-off RF energy. Keying the oscillator itself would invite chirp.

Practical keying needs controlled rise and fall times. Edges that are too abrupt can spread energy as clicks. The power amplifier raises the keyed signal to the intended transmit power.

::figure cw-ssb-signal-paths
Alt text: Three labelled block diagrams show a CW transmitter, an SSB/CW receiver, and an SSB transmitter with signal-flow arrows.
Text equivalent:
- CW row: osc, buf, PA, and key feeding the PA.
- RX row: ant, RF, mix with LO, IF filter, IF amp, prod with BFO, AF, and spkr.
- SSB row: mic, spch, bal with fixed, filt, mix with VFO, and final.
::



### Worked example: supply sag can make chirp

A CW transmitter sounds steady at low power. At higher power, another operator reports that the note slides at the start of each element. The higher current may pull the DC supply voltage down for an instant.

- Given: supply at receive or low power = 13.8 V; supply during a key-down test = 12.9 V.
- Find: voltage sag.
- Formula: sag = starting voltage - loaded voltage.
- Substitute: sag = 13.8 V - 12.9 V.
- Answer: sag = 0.9 V.
- Sanity check: a nearly 1 V drop is large enough to investigate before blaming propagation.

Check the supply rating, cable size, connectors, oscillator stability, and buffer stage. Turning up RF power can make supply sag worse.

### Faded practice: compare loaded voltage

A training rig supply reads 13.6 V at idle and 12.8 V during a key-down test.

- Given: starting E = 13.6 V; loaded E = 12.8 V.
- Find: voltage sag.
- Formula: sag = starting E - loaded E.
- Complete: sag = 13.6 V - ___ V = ___ V.
- Sanity check: would more cable resistance at the same current make the sag larger or smaller?

Fill the gaps before checking below.

### Check your work: compare loaded voltage

The sag is 0.8 V. More cable resistance would add voltage drop. Check the DC path and regulation instead of assuming more RF power will cure an unsteady note.

### In the real world: why a buffer helps

A practice oscillator is adjusted to 7.040 MHz. A power stage connected directly changes its input loading as it warms. If that loading shifts the oscillator by 120 Hz, another operator hears an unsteady note.

A buffer acts like a one-way helper. The oscillator sees a steadier load, and the power stage still receives RF drive.

## SSB/CW receiver path

An SSB/CW receiver shares many superheterodyne blocks with other receivers. The detector and filters are chosen for narrow modes:

```text
antenna -> RF amplifier -> mixer -> IF filter -> IF amplifier -> product detector -> AF amplifier -> speaker
                         ^                                      ^
                         local oscillator                       beat frequency oscillator
```

The antenna converts the radio wave into a tiny current. The RF amplifier improves sensitivity if it adds useful gain without much noise. The mixer and local oscillator convert the selected RF signal to IF. The IF filter keeps the desired narrow slice and rejects nearby signals.

The IF amplifier provides most receiver gain after the desired signal has been selected. The product detector needs a beat frequency oscillator, or BFO. The detector mixes the IF signal with the BFO's reference signal to recover SSB or CW audio. The AF amplifier raises the recovered audio level for headphones or a speaker. An audio band-pass filter for CW tone shaping can sit in the AF amplifier chain.

### Worked example: product detection idea

A training product detector combines a CW signal at 9.0008 MHz with a BFO at 9.0000 MHz.

- Given: IF signal = 9.0008 MHz; BFO = 9.0000 MHz.
- Find: the difference-frequency audio tone.
- Formula: tone frequency = magnitude of the IF-to-BFO difference.
- Substitute: tone = 9.0008 MHz - 9.0000 MHz = 0.0008 MHz.
- Answer: tone = 800 Hz.
- Sanity check: the small RF difference lies in the audio range.

The detector's following audio path keeps that difference tone. Changing the BFO changes the pitch, not the station's transmitted frequency.

### Faded practice: recover a CW tone

The IF signal stays at 9.0008 MHz, but the BFO is now 9.0002 MHz.

- Given: IF = 9.0008 MHz; BFO = 9.0002 MHz.
- Find: the new audio tone.
- Formula: tone = magnitude of the IF-to-BFO difference.
- Complete: tone = 9.0008 - 9.0002 = ___ MHz = ___ Hz.
- Sanity check: moving the BFO closer to the IF should make this difference smaller.

Fill the gaps before checking below.

### Check your work: recover a CW tone

The difference is 0.0006 MHz, or 600 Hz. The tone is lower because the two RF frequencies are closer together.

## SSB transmitter path

A typical SSB transmitter can be shown as:

```text
microphone -> speech amplifier -> balanced modulator -> sideband filter -> mixer -> driver/final amplifier
                         ^                              ^
                         fixed RF oscillator            variable frequency oscillator
```

The microphone signal is small, so the speech amplifier raises the audio. The fixed RF oscillator supplies a carrier frequency for the balanced modulator. The balanced modulator combines audio and RF while suppressing most of the carrier. It creates upper and lower sideband energy.

The sideband filter removes the unwanted sideband. The remaining single-sideband signal may still be at an internal frequency. A mixer uses a variable frequency oscillator, or VFO, to move it to the chosen transmit frequency. The balanced modulator creates the sideband energy; the mixer moves that filtered RF signal to the operating frequency. Driver and final amplifier stages then raise it to useful output power. The final amplifier is also where many SSB transmitters monitor load conditions and protect against excessive SWR.

### Worked example: translating an SSB signal

A training exciter produces a filtered SSB signal near 8.998 MHz. A VFO is set to 5.200 MHz, and the design uses the sum product.

- Given: filtered SSB frequency = 8.998 MHz; VFO = 5.200 MHz.
- Find: operating output frequency.
- Formula: output = filtered SSB frequency + VFO frequency.
- Substitute: output = 8.998 MHz + 5.200 MHz.
- Answer: output = 14.198 MHz.
- Sanity check: the mixer moved the sideband signal; it did not change the spoken message.

### Faded practice: choose a mixer product

A training SSB signal at 8.997 MHz mixes with a 5.300 MHz VFO. The following filter selects the sum.

- Given: sideband signal = 8.997 MHz; VFO = 5.300 MHz.
- Find: selected output frequency.
- Formula: sum output = sideband signal + VFO.
- Complete: sum = 8.997 + ___ = ___ MHz; rejected difference = 8.997 - 5.300 = ___ MHz.
- Sanity check: which product is above both input frequencies?

Fill the gaps before checking below.

### Check your work: choose a mixer product

The selected sum is 14.297 MHz. The difference is 3.697 MHz and is rejected here. The mixer moves the voice sideband to a new RF position.

## Try it

1. A filtered SSB signal at 9.000 MHz is mixed with a 5.000 MHz VFO, and the transmitter selects the difference product. What output should the next filter pass?

:::answer
It should pass 9.000 MHz - 5.000 MHz = 4.000 MHz and reject the sum product at 14.000 MHz.
:::

2. A receiver has 500 Hz and 2.4 kHz IF filters. Which one admits more nearby signals during a narrow CW contact?

:::answer
The 2.4 kHz filter admits more nearby spectrum.
:::

3. A CW operator moves the BFO 400 Hz higher while leaving the IF signal selected. What changes at the speaker?

:::answer
The recovered tone pitch shifts by about 400 Hz.
:::

4. A filtered voice sideband is centred at 9.001 MHz and mixed with a 12.500 MHz VFO using the sum output. What centre frequency leaves the mixer?

:::answer
The centre moves to 9.001 MHz + 12.500 MHz = 21.501 MHz.
:::

## Radio connection

When an SSB signal sounds badly tuned, the receiver may be only a few tens of hertz from the best setting. When a CW signal chirps, look near the oscillator, buffer, keying, or power supply. Block diagrams help you choose the likely area before you touch every control.

## Common mistakes

- Thinking the CW key sends an audio tone over the air. In basic CW, the RF carrier is switched on and off.
- Treating the buffer as only a power amplifier. Its isolation role is just as important.
- Confusing the local oscillator with the BFO. The local oscillator helps create the IF; the BFO helps recover audio.
- Assuming an SSB sideband filter is an audio tone-control filter. It operates near the transmitter's fixed RF or IF generation frequency.
- Swapping the balanced modulator and mixer jobs. The balanced modulator creates sideband energy; the mixer moves the filtered signal.

## Illustration brief

Alt text: Three labelled block diagrams show a CW transmitter, an SSB/CW receiver, and an SSB transmitter with signal-flow arrows.

Description: Draw three stacked brush diagrams. The CW row has oscillator, buffer, and power amplifier, with a key symbol controlling the carrier. The receiver row has antenna, RF amplifier, mixer with local oscillator, IF filter, IF amplifier, product detector with BFO, AF amplifier, and speaker. The SSB transmitter row has microphone, speech amplifier, balanced modulator with fixed RF oscillator, sideband filter, mixer with VFO, and final amplifier.

## Summary

- A basic CW transmitter creates a stable RF carrier, buffers it, amplifies it, and keys it on and off.
- Supply sag, poor buffering, or oscillator pulling can make a CW note chirp.
- Receiver selectivity mainly comes from IF filtering.
- A product detector and BFO recover SSB and CW audio from the IF signal.
- An SSB transmitter uses a speech amplifier, balanced modulator, sideband filter, mixer, VFO, and final amplifier.
- Mixing creates sum and difference products; filters choose the product the radio needs.
