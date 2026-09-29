---
type: lesson
id: L-003-03
moduleId: M3
categoryIds:
  - B-003
title:
  en: "Digital interfaces and linear supplies"
  fr: null
covers:
  - B-003-007
  - B-003-008
objectives:
  - "Explain the role of a sound-card interface in computer-based modes."
  - "Identify transformer, rectifier, filter, and regulator blocks in a linear supply."
  - "Relate overvoltage monitoring to equipment protection."
prerequisites:
  - L-003-02
estimatedMinutes: 40
quizIds:
  - QZ-L-003-03-A
status: draft
---
# Digital interfaces and linear supplies

Computer-based amateur modes often use ordinary audio as the bridge between a radio and software. The radio still transmits RF. The computer still handles bits and symbols. The interface between them makes sure the right kind of signal, at the right level, reaches the right device.

Power supplies are another block-diagram topic. A linear supply changes AC mains into steady DC by passing energy through a transformer, rectifier, filter, and regulator. If you can name the job of each block, troubleshooting becomes much less mysterious.

## Learning objectives

By the end of this lesson, you can:

- describe receive and transmit audio conversion in a computer-based digital station;
- explain push-to-talk switching, audio coupling, isolation transformers, and built-in audio codecs;
- identify transformer, rectifier, filter, regulator, heat sink, and overvoltage monitoring blocks in a linear supply;
- trace AC, pulsating DC, filtered DC, and regulated DC through the supply; and
- use simple ripple and load examples with original numbers.

## Computer audio interfaces for digital modes

A basic digital-mode station can be shown as two paths:

```text
receive: antenna -> transceiver audio out -> interface -> computer software
transmit: computer software -> interface -> transceiver audio in -> RF output
```

On receive, the transceiver demodulates the RF signal into analog audio tones. The interface or sound card converts that analog audio into digital samples the computer can process. On transmit, the computer creates digital samples that become analog audio tones for the transceiver to transmit.

Many interfaces also switch the radio between receive and transmit. They may use a push-to-talk line, a data-control signal, or a radio-specific connection. That switching job is separate from decoding text or creating a waterfall display; software handles the message interpretation.

Isolation transformers are often included in the audio lines. They pass audio while breaking direct electrical paths that can carry hum, ground-loop current, or computer noise into the transmitted signal. Level controls or fixed pads keep the audio strong enough to decode but not so strong that it overdrives the radio.

Some radios do not need a separate sound-card box because an audio codec is built into the transceiver. A USB connector by itself is not the whole explanation; the important internal block is the codec that converts between analog audio and digital samples.

### Worked example: setting interface levels

A club laptop sends a digital-mode audio tone that is too hot for the radio's data input. The transmitted signal becomes wide and splattery. The cure is not more RF power. The operator lowers the computer audio level from 80 percent to 35 percent and raises the radio's data input gain only enough to reach the desired transmitter drive.

The block lesson is simple: keep audio levels clean before the signal reaches the RF transmitter chain.

## Linear power supply blocks

A linear DC supply can be shown as:

```text
AC mains -> transformer -> rectifier -> filter -> regulator -> DC output
```

The transformer changes the AC voltage up or down as needed and provides isolation from the mains. The rectifier changes alternating current into pulsating direct current. The filter, usually involving large capacitors and sometimes inductors, smooths the pulses. The regulator holds the output voltage closer to a constant value as line voltage and load current vary.

A regulator that drops voltage while carrying current dissipates heat. That is why the regulator stage commonly needs a heat sink. Rectifiers and transformers can also get warm in real equipment, but the block-level question about heat sinking points to the voltage regulator in a linear supply.

Overvoltage protection must monitor the regulated output, not an earlier point in the chain. The radio is connected to the output terminals, so that is where an unsafe voltage must be detected.

### Worked example: transformer and rectifier roles

A bench supply uses a transformer to reduce 120 V AC mains to 18 V AC at its secondary. A bridge rectifier then turns that AC waveform into pulsating DC. A filter capacitor charges near the peaks and supplies current between peaks. The regulator finally holds the output near 13.8 V DC for the radio.

The numbers are approximate because real supplies include diode drops, ripple, and load changes. The sequence of jobs is what matters for the block diagram.

### Worked example: regulator heat

A regulator has 18 V DC at its input, supplies 13.8 V DC at its output, and carries 2.5 A to a receiver and accessories.

```text
voltage dropped by regulator = 18 V - 13.8 V = 4.2 V
heat in regulator ≈ voltage drop x current
heat in regulator ≈ 4.2 V x 2.5 A = 10.5 W
```

About ten watts of heat is enough to require serious heat sinking. The regulator is doing useful work, but that work creates heat.

## Try it

Question: A digital station decodes signals on receive but transmits a loud hum. Which interface feature should you inspect first?

Worked answer: Inspect audio isolation and grounding. Isolation transformers help prevent ground-loop hum and computer noise from entering the transmit audio path.

Question: A radio has a USB data port and works with digital-mode software without an external sound box. What internal function must the radio provide?

Worked answer: It needs an audio codec or equivalent conversion between analog audio and digital samples.

Question: In a linear supply, where would you look for a waveform that has one polarity but still rises and falls strongly?

Worked answer: Look after the rectifier and before the filter. The rectifier has made pulsating DC, but the filter has not yet smoothed it.

Question: A regulator input is 20 V, the output is 13.5 V, and load current is 1.2 A. Estimate heat in the regulator.

Worked answer: The regulator drops 20 V - 13.5 V = 6.5 V. Heat is about 6.5 V x 1.2 A = 7.8 W.

## Radio connection

Digital-mode problems often sound like RF problems but begin as audio problems. Too much audio drive can make a signal wider than needed; poor isolation can add hum. Power-supply problems can also show up as noise, instability, or equipment shutdown. Block diagrams tell you whether to look at audio conversion, transmit switching, DC regulation, or protection sensing.

## Common mistakes

- Saying the interface demodulates the RF signal. The transceiver demodulates RF; the interface passes and converts audio.
- Assuming a USB connector proves that a radio has a sound card. The needed function is the audio codec.
- Confusing a rectifier with a regulator. The rectifier changes AC to pulsating DC; the regulator holds the output steady.
- Placing overvoltage sensing before the regulator, where it cannot directly verify the voltage being delivered to the radio.
- Forgetting that a linear regulator can waste substantial power as heat.

## Illustration brief

Alt text: A split diagram shows a computer audio interface between a transceiver and laptop, plus a linear power supply chain from AC mains to DC output.

Description: Draw a brush-style laptop on the left, transceiver on the right, and an interface box between them. Use two arrows labelled receive audio samples and transmit audio tones, plus a small push-to-talk control line. Below it, draw transformer, rectifier, filter capacitor, regulator with heat sink, and DC output terminals. Mark overvoltage sensing at the output.

## Summary

- Computer digital modes commonly use audio tones between software and the transceiver.
- Sound-card interfaces convert, couple, isolate, set levels, and often control transmit/receive switching.
- Built-in digital-mode audio needs a codec, not merely a connector.
- A linear supply sequence is transformer, rectifier, filter, regulator, output.
- Overvoltage protection watches the regulated output, and a regulator may need a heat sink because voltage drop times current becomes heat.
