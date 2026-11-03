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
  - L-004-01
  - L-005-06
estimatedMinutes: 40
quizIds:
  - QZ-L-003-03-A
status: draft
---
# Digital interfaces and linear supplies

Computer-based amateur modes often use audio as the bridge between a radio and software. The radio still transmits RF. The computer handles bits and symbols. The interface keeps signal type and level under control.

Power supplies are also easier to learn as blocks. A linear supply changes AC mains into steady DC. It does that with a transformer, rectifier, filter, and regulator.

## Learning objectives

By the end of this lesson, you can:

- describe receive and transmit audio conversion in a computer-based digital station;
- explain push-to-talk switching, audio coupling, isolation transformers, and built-in audio codecs;
- identify transformer, rectifier, filter, regulator, heat sink, and overvoltage monitoring blocks in a linear supply;
- trace AC, pulsating DC, filtered DC, and regulated DC through the supply; and
- use simple ripple and load examples with original numbers.

## Computer audio interfaces for digital modes

A basic digital-mode station has two audio paths:

```text
receive: antenna -> transceiver audio out -> interface -> computer software
transmit: computer software -> interface -> transceiver audio in -> RF output
```

On receive, the transceiver demodulates RF into audio tones. The interface or sound card converts that analog audio into digital samples for the computer. On transmit, the computer creates samples. The interface turns them into analog audio tones for the transceiver.

Many interfaces also switch the radio between receive and transmit. They may use a push-to-talk line, a data-control signal, or a radio-specific connection. Switching is separate from decoding text or drawing a waterfall display.

Isolation transformers often sit in the audio lines. They pass audio but break direct electrical paths. That can reduce hum, ground-loop current, or computer noise. Level controls or fixed pads keep audio strong enough to decode but not strong enough to overdrive the radio. A fixed pad is a set attenuator that reduces signal level by a known amount.

Some radios include their own audio codec. A codec converts between analog audio and digital samples. In that design, the connector is only the access point; the codec is the conversion block.

::figure digital-interface-linear-supply
Alt text: A split diagram shows a computer audio interface between a transceiver and laptop, plus a linear power supply chain from AC mains to DC output.
Text equivalent:
- RX arrows run radio to interface to laptop.
- TX arrows run laptop to interface to radio, and a PTT line runs from the interface to the radio.
- The supply chain is AC, xfmr coils, rect, shunt cap across the rails, reg with fins, positive and return DC output terminals, and a sense feedback line.
::



### In the real world: setting interface levels

A club laptop sends a digital-mode audio tone that is too strong for the radio data input. The transmitted signal becomes wide and splattery. The cure is not more RF power.

The operator lowers the computer playback level from 80% to 35%. That is a 45 percentage-point reduction in audio drive. The large audio reduction can clean the signal without changing antenna power.

After that, raise the radio data input gain only enough to reach the needed transmitter drive.

## Linear power supply blocks

A linear DC supply can be shown as:

```text
AC mains -> transformer -> rectifier -> filter -> regulator -> DC output
```

The transformer steps the AC voltage up or down, depending on its turns ratio, and provides isolation from the mains. A low-voltage station supply steps it down. The rectifier changes alternating current into one-polarity, pulsating direct current. The filter, often a large capacitor, smooths the pulses. The regulator holds the output voltage closer to a constant value as line voltage and load current change.

A regulator that drops voltage while carrying current makes heat. That is why the regulator stage often needs a heat sink. Rectifiers and transformers can also get warm, but the regulator is the series control stage deliberately turning voltage drop times current into heat.

Overvoltage protection must monitor the regulated output. The radio is connected to the output terminals, so that is where unsafe voltage must be detected.

### Worked example: transformer and rectifier roles

A bench supply transformer reduces mains voltage to 18 V AC RMS. RMS is the effective AC value; for a sine wave, its peak is about 1.414 times larger. A bridge rectifier steers both halves into the same polarity. The capacitor charges near the peaks.

- Given: secondary E = 18 V AC RMS; sine-wave peak factor = 1.414.
- Find: peak voltage before allowing for diode drops.
- Formula: peak E = RMS E x 1.414.
- Substitute: peak E = 18 V x 1.414.
- Answer: peak E is about 25.5 V before diode drops, or roughly 23 V to 24 V after the bridge, before ripple and load.
- Sanity check: filtered DC is related to the sine-wave peaks, not simply the AC RMS label.

The regulator then holds the output near 13.8 V DC. The separate regulator-heat example below starts with a different stated DC input. Real diode drops, ripple, and loading change the available voltage.

### Faded practice: estimate a sine-wave peak

A separate training transformer has a 16 V AC RMS secondary. Estimate its sine-wave peak before bridge-diode drops.

- Given: RMS E = 16 V; peak factor = 1.414.
- Find: peak E before diode drops.
- Formula: peak E = RMS E x 1.414.
- Complete: peak E = ___ V x 1.414 = about ___ V.
- Sanity check: should the peak exceed the RMS label?

Fill the gaps before checking below.

### Check your work: estimate a sine-wave peak

16 x 1.414 = 22.624, or about 22.6 V. Bridge drops, ripple, and load reduce the DC available to a regulator. This is not a measurement instruction for an open mains supply.

### In the real world: ripple after filtering

A training supply has a rectifier-only test point and a filtered test point. Under the same load, the rectifier-only point has a strong rising and falling waveform. The filtered point has a smaller ripple riding on DC, such as 0.35 V peak-to-peak.

The filter has not regulated the final voltage. It has given the regulator a steadier input to control.

### In the real world: stored charge after unplugging

Never open or probe inside a mains-powered supply unless you are qualified and equipped for that work. Unplug the supply. Use the service procedure and a proper insulated discharge tool with an inline resistor. Verify with a meter that stored charge is gone. A bleeder resistor may help, but it can fail or take longer than expected, so waiting for it is not a safe substitute for controlled discharge and verification. Do not trust a dark pilot lamp or unlit power LED as proof that capacitors are discharged.

### Worked example: regulator heat

A regulator has 18 V DC at its input. It supplies 13.8 V DC at its output and carries 2.5 A to a receiver and accessories.

- Given: input E = 18 V DC; output E = 13.8 V DC; I = 2.5 A.
- Find: regulator heat.
- Formula: heat power = (input E - output E) x I.
- Substitute: heat power = (18 V - 13.8 V) x 2.5 A.
- Answer: heat power = 4.2 V x 2.5 A = 10.5 W.
- Sanity check: this is the power lost in the regulator, not power delivered to the radio.

About ten watts of heat is enough to require serious heat sinking.

### Faded practice: finish a heat budget

A linear regulator supplies 13.6 V from 17.6 V DC while carrying 1.8 A.

- Given: input E = 17.6 V; output E = 13.6 V; I = 1.8 A.
- Find: heat in the regulator.
- Formula: heat power = voltage drop x current.
- Complete: drop = 17.6 - 13.6 = ___ V; heat = ___ V x 1.8 A = ___ W.
- Sanity check: would a larger input voltage at the same output and load make more heat?

Fill the gaps before checking below.

### Check your work: finish a heat budget

The drop is 4.0 V and heat is 7.2 W. A larger input-output difference at the same current makes more heat; it does not give the radio more output voltage.

## Try it

1. A digital station keys the transmitter correctly, but the other station hears silence instead of tones. What separate path should be traced?

:::answer
Trace transmit audio from the software output through the interface to the radio data input.
:::

2. A digital-mode signal becomes wide after the computer playback slider is raised from 35% to 90%. What should you adjust first?

:::answer
Reduce playback or interface drive until the radio input is not overdriven.
:::

3. In a training model, the smoothing capacitor is disconnected from the rectifier output. What happens to the regulator input waveform?

:::answer
It rises and falls much more because the filter is no longer smoothing the pulses.
:::

4. A regulator input is 20 V, the output is 13.5 V, and load current is 1.2 A. Estimate heat in the regulator.

:::answer
The regulator drops 20 V - 13.5 V = 6.5 V. Heat is about 6.5 V x 1.2 A = 7.8 W.
:::

## Radio connection

Digital-mode problems often begin as audio problems. Too much audio drive can make a signal too wide. Poor isolation can add hum. Power-supply problems can create noise, instability, or shutdowns. Block diagrams tell you whether to look at audio conversion, transmit switching, DC regulation, or protection sensing.

## Common mistakes

- Saying the interface demodulates RF. The transceiver demodulates RF; the interface passes and converts audio.
- Assuming the external connector alone identifies the conversion block. The needed function is the audio codec.
- Confusing a rectifier with a regulator. The rectifier changes AC to pulsating DC; the regulator holds the output steady.
- Placing overvoltage sensing before the regulator, where it cannot verify the voltage delivered to the radio.
- Forgetting that a linear regulator can waste substantial power as heat.

## Illustration brief

Alt text: A split diagram shows a computer audio interface between a transceiver and laptop, plus a linear power supply chain from AC mains to DC output.

Description: Draw a brush-style laptop on the left, transceiver on the right, and an interface box between them. Use two arrows labelled receive audio samples and transmit audio tones, plus a small push-to-talk control line. Below it, draw transformer, rectifier, filter capacitor, regulator with heat sink, and DC output terminals. Mark overvoltage sensing at the output.

## Summary

- Computer digital modes commonly use audio tones between software and the transceiver.
- Sound-card interfaces convert, couple, isolate, set levels, and often control transmit/receive switching.
- Built-in digital-mode audio depends on an audio codec to convert between audio and digital samples.
- A linear supply sequence is transformer, rectifier, filter, regulator, output.
- Overvoltage protection watches the regulated output.
- A regulator may need a heat sink because voltage drop times current becomes heat.
