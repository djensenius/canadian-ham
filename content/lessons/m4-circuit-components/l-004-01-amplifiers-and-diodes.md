---
type: lesson
id: L-004-01
moduleId: M4
categoryIds:
  - B-004
title:
  en: "Amplifiers and diodes"
  fr: null
covers:
  - B-004-001
  - B-004-002
objectives:
  - "State what an amplifier does to a signal."
  - "Explain why linearity matters in radio circuits."
  - "Identify common diode jobs such as rectification, detection, and protection."
prerequisites: []
estimatedMinutes: 30
quizIds:
  - QZ-L-004-01-A
status: draft
---
# Amplifiers and diodes

An amateur station is full of circuits that handle signals too small to be useful on their own. A receiver input may be listening for a tiny RF voltage from an antenna. A microphone may produce only a small audio signal. An amplifier is the block that raises a signal level so the next stage can use it.

Diodes are just as common. They are one-way semiconductor devices, so they can steer current, make DC from AC, recover audio from some modulated signals, regulate voltage, glow as indicators, or protect equipment from a backwards supply connection.

## Learning objectives

By the end of this lesson, you can:

- describe gain as an increase in useful signal level;
- choose between RF and audio amplifier jobs at a block-diagram level;
- explain why a non-linear amplifier creates unwanted products;
- describe positive feedback as useful only when controlled;
- identify anode and cathode as diode terminals; and
- match diode behaviour to rectification, detection, voltage regulation, light output, and reverse-polarity protection.

## Amplifiers raise signal level

An amplifier uses energy from a power supply to make a signal larger. The information in the signal should stay recognizable: the same voice waveform, code waveform, or RF pattern is present, but at a greater level.

The increase is called gain. Gain may describe voltage, current, or power, depending on what the circuit is meant to increase. A stage labelled with gain is therefore a stage that amplifies rather than one that intentionally reduces signal level.

An RF amplifier works with radio-frequency signals. In a receiver, it can raise a weak antenna signal before later stages select and process it. In a transmitter, later RF stages can raise a clean drive signal toward the power needed at the antenna connector.

An audio amplifier works with sound-frequency signals after a microphone, detector, or audio processing stage. Human speech occupies a modest audio band compared with RF, so an audio stage is designed for voice clarity rather than for a radio carrier frequency.

### Worked example: following a signal through a receiver

Imagine a small portable receiver connected to a short indoor antenna. The antenna delivers a weak RF signal. A front-end RF amplifier raises that RF signal while keeping the tuned frequency and modulation intact. Later, a detector recovers audio. The audio then goes to an audio amplifier so headphones or a speaker can be driven.

The two amplifiers do not do the same job. The first handles the radio-frequency signal. The second handles the sound-frequency signal.

### Worked example: voltage gain in plain language

A test generator applies 0.08 V of audio to a preamplifier. The preamplifier output is 0.80 V with the same waveform shape.

- The output voltage is larger than the input voltage.
- The ratio is 0.80 / 0.08.
- The voltage gain is 10 times.

This example uses ordinary ratio thinking. It does not say the amplifier created energy from nothing. The extra output energy comes from the amplifier power supply.

## Linearity keeps signals clean

A linear amplifier changes signal size without changing the shape more than intended. If the input waveform rises smoothly, the output should rise smoothly by the same proportion. If the input crosses through a low point, the output should cross through a matching low point.

A non-linear amplifier does not preserve that shape. Peaks may flatten, one half of a waveform may be treated differently from the other, or the stage may be driven outside its proper operating range. The result is distortion. In radio work, distortion is not only unpleasant audio. It can create unwanted frequency products that waste power and may interfere with other users.

Efficiency is a different idea. Amplifier efficiency is the ratio of useful output power to DC input power. A perfectly clean amplifier can still waste heat, and an efficient stage can still be badly distorted if it is misused. Keep the ideas separate: linearity is about signal shape; efficiency is about power conversion.

### Positive feedback and oscillation

Feedback means a portion of an output signal is returned to an input or earlier point. Negative feedback can be used in many circuits to make behaviour more stable. Positive feedback reinforces the signal. A small amount may be part of an oscillator design, but too much positive feedback in an amplifier stage can make the stage oscillate when it was supposed to amplify.

A squealing public-address system is an everyday analogy. Sound from the speaker re-enters the microphone, gets amplified again, and grows into a tone. RF circuits can do the same thing invisibly if layout, shielding, or feedback paths are poor.

## Diodes conduct mainly one way

A semiconductor diode has two electrodes: an anode and a cathode. In ordinary circuit language, the diode conducts when it is forward biased and blocks, except for tiny leakage or special breakdown behaviour, when it is reverse biased.

Conventional current is described as flowing from anode to cathode when a diode conducts. Electron flow is opposite: electrons move from cathode toward anode. Both descriptions appear in electronics; always notice which convention is being used.

The circuit symbol is a triangle-like arrowhead or wedge touching a line. The line marks the cathode side in the usual schematic symbol. Real parts often have a band or marking near the cathode lead.

## Rectifiers, detectors, and protectors

Rectification is changing alternating current into current that flows one way. A single diode can pass one half of an AC waveform, producing pulsating DC. A power supply normally follows the rectifier with filtering so the result becomes smoother DC.

Detection uses diode non-linearity to recover information from some RF signals. For example, a simple envelope detector can recover audio variations from an amplitude-varying RF signal. The important Basic-level idea is that a diode can recover information; receiver design details come later.

A diode can also protect against reverse polarity. If a series diode is installed in the positive lead, it conducts when the supply is connected correctly and blocks if the supply is connected backwards. Other protection arrangements use diodes across supply rails or relay coils, but the one-way behaviour is the shared idea.

### Worked example: one-way protection path

A club builds a small accessory for field day. The accessory uses a series diode at the DC input. With the battery connected the intended way, the diode is forward biased and the accessory receives power. If the leads are accidentally swapped, the diode is reverse biased and current is blocked, helping prevent damage.

That protection has trade-offs, such as a voltage drop across the diode, but the Basic exam point is the direction-selective behaviour.

## Special-purpose diodes

A Zener diode is designed to operate in reverse breakdown at a specified voltage. Used with a current-limiting resistor, it can hold a point in a circuit near a chosen voltage. That makes it useful for simple voltage regulation or voltage reference duties.

A light-emitting diode, or LED, emits light when forward current flows through it. The colour depends on the semiconductor material and construction, not on paint inside the package. LEDs are common on radios as power, transmit, receive, and status indicators.

Diode ratings matter. A real diode has a maximum forward current, a reverse-voltage rating, heat limits, and switching-speed limits. For this lesson, focus first on recognizing what the diode is being asked to do.

## Try it

1. A receiver block is before the mixer and handles the incoming tuned RF signal. Name its likely job before checking: RF amplification.
2. A microphone signal is too small for the modulator input. The useful block is an audio amplifier, because the signal represents sound rather than RF.
3. A diode in a supply path passes current with correct battery polarity and blocks it with reversed leads. That is reverse-polarity protection.
4. A waveform leaving an amplifier has clipped peaks. That is a warning sign of non-linearity and distortion.
5. A small diode circuit changes a sine-like AC waveform into pulses all in one direction. That action is rectification.

## Radio connection

Amplifiers and diodes are not isolated textbook parts. In a handheld transceiver, small-signal amplifiers handle receive signals, microphone audio, and speaker audio. Diodes may protect the DC input, steer signals, detect RF, clamp relay-coil voltage spikes, or light the front panel.

When troubleshooting, ask what role a part is playing. A failed amplifier may make a signal weak or distorted. A failed diode may leave a supply unprotected, stop rectification, defeat detection, or keep an indicator dark.

## Common mistakes

- Treating gain as the same thing as volume. Gain can apply to RF voltage, RF power, audio voltage, or other signal quantities.
- Assuming any larger output is good. An amplifier must increase the wanted signal without unacceptable distortion.
- Confusing an oscillator with an amplifier. An oscillator creates a repeating signal; an amplifier raises an existing signal level.
- Forgetting that electron flow and conventional current use opposite directions in a diode.
- Thinking a Zener diode boosts voltage. Its Basic-level role is to regulate or maintain a voltage when used in a suitable circuit.
- Assuming reverse-polarity protection is the same as overcurrent protection. A fuse or current limiter handles excessive current; a diode handles direction in the examples here.

## Illustration brief

Alt text: A clean block diagram showing a weak signal entering an amplifier, a larger matching signal leaving it, and a diode symbol labelled anode and cathode.

Description: Draw two ink-brush panels. In the first panel, a small sine wave enters a rectangle labelled "amplifier" and a taller sine wave leaves it; add a tiny battery symbol to show power-supply energy. In the second panel, draw a diode schematic symbol with the anode on the left and the cathode line on the right. Add arrows for forward conventional current and a note that electron flow is opposite.

## Summary

- An amplifier increases signal level using energy from its power supply.
- Gain may describe voltage, current, or power increase.
- RF amplifiers handle radio-frequency signals; audio amplifiers handle sound-frequency signals.
- Linearity preserves waveform shape; non-linearity causes distortion and unwanted products.
- Excess positive feedback can make an amplifier oscillate.
- A diode has an anode and cathode and conducts mainly when forward biased.
- Diodes are used for rectification, detection, voltage regulation, light emission, and polarity protection.
