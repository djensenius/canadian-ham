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

An amateur station is full of circuits that handle tiny signals. A receiver input may be listening for a weak radio-frequency signal, or RF signal, from an antenna. A microphone may produce only a small audio signal.

An amplifier raises a signal level so the next stage can use it.

Diodes are just as common. They are one-way semiconductor devices. They can steer current and make direct current from alternating current. They can also recover audio from some modulated signals, regulate voltage, glow as indicators, or protect equipment from a backwards supply connection.

## Learning objectives

By the end of this lesson, you can:

- describe gain as an increase in useful signal level;
- choose between RF and audio amplifier jobs at a block-diagram level;
- explain why a non-linear amplifier creates unwanted products;
- describe positive feedback as useful only when controlled;
- identify anode and cathode as diode terminals; and
- match diode behaviour to rectification, detection, voltage regulation, light output, and reverse-polarity protection.

## Amplifiers raise signal level

An amplifier uses energy from a power supply to make a signal larger. The information in the signal should stay recognizable. The same voice waveform, code waveform, or RF pattern is present, but at a greater level.

The increase is called gain. Gain may describe voltage, current, or power, depending on what the circuit is meant to increase. A stage labelled with gain is therefore a stage that amplifies rather than one that intentionally reduces signal level.

An RF amplifier works with radio-frequency signals. In a receiver, it can raise a weak antenna signal before later stages select and process it. In a transmitter, later RF stages can raise a clean drive signal toward the power needed at the antenna connector.

An audio amplifier works with sound-frequency signals after a microphone, detector, or audio processing stage. Human speech occupies a modest audio band compared with RF.

For communications work, the important speech information is commonly treated as roughly 300 Hz to 3 000 Hz. An audio stage is designed for voice clarity in that range, not for a radio carrier frequency.

### In the real world: following a signal through a receiver

A small portable receiver starts with a weak RF signal from the antenna. A front-end RF amplifier raises that RF signal while keeping the tuned frequency and modulation intact.

Later, a detector recovers audio. The audio then goes to an audio amplifier so headphones or a speaker can be driven. The first amplifier handles RF; the second handles sound-frequency audio.

### Worked example: voltage gain in plain language

A test generator applies 0.08 V of audio to a preamplifier. The preamplifier output is 0.80 V with the same waveform shape.

- Given: input E = 0.08 V; output E = 0.80 V.
- Find: voltage gain ratio.
- Formula: gain = output / input.
- Substitute: gain = 0.80 / 0.08.
- Answer: gain = 10 times.
- Sanity check: the waveform is larger, but the extra output energy comes from the amplifier power supply.

## Linearity keeps signals clean

A linear amplifier changes signal size without changing the shape more than intended. If the input waveform rises smoothly, the output should rise smoothly by the same proportion. If the input crosses through a low point, the output should cross through a matching low point.

A non-linear amplifier does not preserve that shape. Peaks may flatten. One half of a waveform may be treated differently from the other. The stage may also be driven outside its proper operating range.

The result is distortion. In radio work, distortion can create unwanted frequency products that waste power and may interfere with other users.

Efficiency is a different idea. Amplifier efficiency is the ratio of useful output power to DC power taken from the supply. A clean amplifier can still waste heat, and an efficient stage can still be badly distorted if it is misused. Keep the ideas separate: linearity is about signal shape; efficiency is about power conversion.

### Positive feedback and oscillation

Feedback means a portion of an output signal is returned to an input or earlier point. Negative feedback can make many circuits more stable. Positive feedback reinforces the signal.

A small amount may be part of an oscillator design. Too much positive feedback in an amplifier stage can make the stage oscillate when it was supposed to amplify.

A squealing public-address system is an everyday analogy. Sound from the speaker re-enters the microphone, gets amplified again, and grows into a tone. RF circuits can do the same thing invisibly if layout, shielding, or feedback paths are poor.

### Misconception: louder always means better

- Mistaken idea: any larger output signal is an improvement.
- Correction: the wanted signal must stay clean enough for the job. Distortion can create unwanted products.

## Diodes conduct mainly one way

A semiconductor diode has two electrodes: an anode and a cathode. In ordinary circuit language, the diode conducts when it is forward biased. It blocks, except for tiny leakage or special breakdown behaviour, when it is reverse biased.

Conventional current is described as flowing from anode to cathode when a diode conducts. Electron flow is opposite: electrons move from cathode toward anode. Both descriptions appear in electronics, so always notice which convention is being used.

The circuit symbol is a triangle-like wedge touching a line. The line marks the cathode side in the usual schematic symbol. Real parts often have a band or marking near the cathode lead.

### Memory trick: cathode has the bar

- Helps remember: the cathode end of a common diode symbol.
- Trick: the cathode is on the line, or bar, side of the symbol.
- Limit: this helps with the schematic symbol. Always check the datasheet or package marking for a real part.

## Rectifiers, detectors, and protectors

Rectification is changing alternating current into current that flows one way. A single diode can pass one half of an AC waveform, producing pulsating DC. A power supply normally follows the rectifier with filtering so the result becomes smoother DC.

Detection uses diode non-linearity to recover information from some RF signals. For example, a simple envelope detector can recover audio variations from an amplitude-varying RF signal. The important Basic-level idea is that a diode can recover information; receiver design details come later.

A diode can also protect against reverse polarity. If a series diode is installed in the positive lead, it conducts when the supply is connected correctly. It blocks if the supply is connected backwards.

A fuse handles overcurrent; a diode in this example handles direction.

### In the real world: reverse-polarity protection

A club builds a small field-day accessory with a series diode at the DC input. With the battery connected the intended way, the diode is forward biased and the accessory receives power.

If the leads are accidentally swapped, the diode is reverse biased and current is blocked, helping prevent damage. That protection has trade-offs, such as a voltage drop across the diode.

## Special-purpose diodes

A Zener diode is designed to operate in reverse breakdown at a specified voltage. Used with a current-limiting resistor, it can hold a point in a circuit near a chosen voltage. That makes it useful for simple voltage regulation or voltage reference duties.

A light-emitting diode, or LED, emits light when forward current flows through it. The colour depends mainly on the semiconductor material and device construction, not on the colour you see from the outside of the package. LEDs are common on radios as power, transmit, receive, and status indicators.

Diode ratings matter. A real diode has a maximum forward current, a reverse-voltage rating, heat limits, and switching-speed limits. For this lesson, focus first on recognizing what the diode is being asked to do.

### In the real world: USB LED indicator

An LED needs a series resistor. Suppose a red LED drops about 2.1 V and should run near 20 mA from a 5.0 V USB source.

- Given: source E = 5.0 V; LED drop = 2.1 V; resistor E = 2.9 V; target I = 20 mA = 0.020 A.
- Find: series resistance R.
- Formula: R = resistor E / I.
- Substitute: R = 2.9 V / 0.020 A.
- Answer: R = 145 ohms ideal.
- Sanity check: the resistor drops the extra voltage that the LED does not use.

E12 is a common resistor-value series. The nearest E12 value above 145 ohms is 150 ohms. With 150 ohms, current is I = 2.9 V / 150 ohms = 0.0193 A, or 19.3 mA. Resistor power is P = 0.0193 A x 2.9 V = 0.056 W, so a 0.25 W resistor has margin.

### In the real world: 9 V battery LED indicator

The same red LED from a 9.0 V battery needs more series resistance because the resistor must drop more voltage.

- Given: source E = 9.0 V; LED drop = 2.1 V; resistor E = 6.9 V; target I = 20 mA = 0.020 A.
- Find: series resistance R.
- Formula: R = resistor E / I.
- Substitute: R = 6.9 V / 0.020 A.
- Answer: R = 345 ohms ideal.
- Sanity check: a higher source voltage needs more resistance for the same LED current.

A common E12 choice above the ideal value is 390 ohms. Current becomes I = 6.9 V / 390 ohms = 0.0177 A, or 17.7 mA. Resistor power is P = 0.0177 A x 6.9 V = 0.122 W, so a 0.25 W resistor is suitable.

## Try it

1. A receiver preselector already chose the station, but the signal is still too small for the mixer. The next block should raise the RF level without changing the station's frequency.
2. A speech processor receives a few millivolts from a headset mic and must feed a modulator input. Choose an audio gain stage because the information is still sound-frequency speech.
3. A battery-powered accessory includes a series diode and now measures about one diode drop less at its circuit board. Explain the trade-off: the diode can block a reversed battery, but it also drops some voltage during normal operation.
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
- An LED indicator needs a series resistor sized for current and power.
