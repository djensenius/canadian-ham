---
type: lesson
id: L-004-02
moduleId: M4
categoryIds:
  - B-004
title:
  en: "Transistors, FETs, and tubes"
  fr: null
covers:
  - B-004-003
  - B-004-004
  - B-004-005
objectives:
  - "Compare bipolar transistor, FET, and triode control terminals."
  - "Recognize why different active devices appear in RF circuits."
  - "Describe control of a larger current by a smaller signal."
prerequisites:
  - L-004-01
estimatedMinutes: 40
quizIds:
  - QZ-L-004-02-A
status: draft
---
# Transistors, FETs, and tubes

Diodes are mostly one-way devices. Transistors and tubes go a step farther: a signal at one terminal can control a larger current through the device. That control is what makes amplification and electronic switching possible.

This lesson compares three active-device families at a Basic exam level: bipolar junction transistors, field-effect transistors, and triode vacuum tubes. You do not need to design an amplifier from scratch here. You do need to recognize terminal names, control action, and the reasons a circuit might use one family instead of another.

## Learning objectives

By the end of this lesson, you can:

- name the collector, base, and emitter of a bipolar transistor;
- distinguish NPN and PNP polarity families;
- describe how a base signal controls transistor action;
- name the gate, source, and drain of a field-effect transistor;
- explain why the FET gate is treated as a high-impedance control terminal;
- compare FET source and drain roles with bipolar emitter and collector roles; and
- identify the cathode, grid, and plate in a triode vacuum tube.

## Bipolar transistors: current-controlled devices

A bipolar transistor is a semiconductor device that can amplify a small signal at low circuit voltages. The word bipolar reminds you that both electrons and holes take part in its operation, but the Basic exam mostly cares about its terminals and behaviour.

The three electrodes are:

- emitter: the terminal associated with carriers entering or leaving the active region;
- base: the thin control region; and
- collector: the terminal that collects the controlled current.

In many common explanations, a small base current controls a larger collector-emitter current. That is enough to understand why a transistor can act as an amplifier. A small changing input at the base can produce a larger changing output in the collector circuit, as long as the transistor is biased in its active region.

### Memory trick: transistor terminal jobs

- Helps remember: the bipolar terminal names.
- Trick: the emitter emits carriers, the base controls, and the collector collects.
- Limit: the phrase helps with names only. It does not replace polarity, bias, or datasheet checks.

### NPN and PNP polarity

The two main bipolar polarities are NPN and PNP. They are not drop-in replacements for each other because the required polarities are reversed. A circuit designed for one type has its supply, signal, and bias directions arranged for that type.

A useful memory aid is the emitter-arrow symbol. In an NPN symbol, the emitter arrow points out. In a PNP symbol, the emitter arrow points in. The arrow is part of the schematic symbol and helps prevent mixing the two in a real circuit.

### Memory trick: NPN arrow

- Helps remember: the NPN emitter arrow direction.
- Trick: NPN can mean "not pointing in." The NPN emitter arrow points out.
- Limit: this only helps read the symbol. It does not identify a loose transistor package without its part number or datasheet.

### In the real world: transistor as a small audio amplifier

A simple audio preamplifier receives a 12 mV microphone signal. Its transistor is biased so the base signal makes the collector current vary smoothly. The output taken from the collector circuit is a larger audio voltage with the same speech pattern.

The transistor is not changing audio into RF and it is not detecting a signal. It is amplifying because a small input variation controls a larger output variation.

## Transistor switching

A transistor can also be used as an electronic switch. In cut-off, it is treated as off because the controlled current is very small. In saturation, it is treated as on because it is driven hard enough that the output path is strongly conducting.

A switching transistor is often used to control a relay, lamp, fan, or logic signal. The base is still the control electrode in a bipolar transistor. The difference is that the circuit deliberately drives the device between off and on states instead of keeping it in the smooth active region used for linear amplification.

Heat is a common way to destroy semiconductors. Too much current, too much voltage, poor heat sinking, or incorrect bias can raise the device temperature beyond its rating. Saturation and cut-off are useful operating states for switching; excessive heat is a failure condition.

### In the real world: relay switch with a flyback diode

A 3.3 V control pin can drive an NPN transistor through a base resistor. The transistor then switches a separate 12 V relay coil, if the relay and transistor ratings allow it.

- Given: control E = 3.3 V; base-emitter drop is about 0.7 V; base resistor = 560 ohms.
- Find: base current.
- Formula: I = resistor E / R.
- Substitute: I = (3.3 V - 0.7 V) / 560 ohms = 2.6 V / 560 ohms.
- Answer: I = 0.0046 A, or 4.6 mA.
- Sanity check: a few milliamperes is reasonable for a small control output, but the transistor datasheet still decides what load it can switch.

A relay coil is an inductor. When the transistor turns off, the coil can make a voltage spike. A flyback diode across a DC relay coil gives that current a safe path and helps protect the transistor.

### In the real world: switching a cooling fan

A microcontroller output cannot supply a station accessory fan directly. It drives a resistor connected to a transistor base instead. When the base drive is present, the collector-emitter path conducts and the fan runs. When the base drive is removed, the transistor turns off and the fan stops.

The small control signal is not doing the fan's work by itself. It is controlling current from the supply through the transistor and fan.

### Misconception: saturation is always bad

- Mistaken idea: a saturated transistor is always faulty.
- Correction: saturation is often the intended on state for a switching transistor. It is not the same as overheating.

## Field-effect transistors: voltage-controlled channel devices

A field-effect transistor, usually shortened to FET, controls current through a channel. Its three terminals are:

- source: the terminal where carriers enter the channel;
- drain: the terminal where carriers leave the channel; and
- gate: the control terminal that changes channel conduction.

At a Basic level, the FET gate is treated as high impedance because it draws little or no steady current in normal operation. That makes FETs useful where a circuit should not load the previous stage heavily.

The two channel polarities are N channel and P channel. Those names describe the semiconductor channel type between source and drain. Do not mix them up with NPN and PNP, which are bipolar transistor types.

### Gate control and channel current

In a junction FET style explanation, reverse bias at the gate narrows the channel. More reverse bias reduces channel current. Less reverse bias opens the channel more and allows current to increase. Other FET families use insulated gates and different details, but the gate-control idea is still central.

The source of a FET corresponds roughly to the emitter of a bipolar transistor. The drain corresponds roughly to the collector. The gate corresponds to the base as the control terminal, while remembering that gate current is normally much smaller.

### In the real world: high-impedance sensing

Suppose a receiver accessory samples a tuned circuit without wanting to disturb it. A FET input stage can be a good choice because its gate takes very little current. The tuned circuit sees a light load, while the FET output can drive the next stage more comfortably.

This is why the phrase high impedance is so closely associated with FET input circuits.

### Misconception: a FET gate is a low-resistance input

- Mistaken idea: the gate behaves like a low-value resistor to the source.
- Correction: at the Basic level, a FET gate is treated as high impedance and draws little steady current in normal operation.

## Triode vacuum tubes

A triode is a vacuum tube with a cathode, one control grid, and a plate. The cathode emits electrons inside an evacuated envelope. The plate, operated at a high positive voltage compared with the cathode, attracts electrons. The grid sits between them and controls the electron stream.

The output current path in a triode is between cathode and plate. The control element is the grid. A small change at the grid can control a larger plate current, so a triode can amplify signals.

Vacuum tubes are larger, run hotter, and usually require higher voltages than semiconductor transistors. They still appear in some RF power amplifiers and specialist equipment because a suitable tube can handle high RF power and high voltage. That does not make tubes automatically better; it means the device family has strengths in particular jobs.

### In the real world: why tube amplifiers need caution

A tube RF amplifier may keep high voltage on capacitors after power is turned off. That stored energy can be dangerous. Service instructions, bleeder resistors, and safe discharge procedures matter.

For Basic study, the key point is simpler: cathode, grid, and plate identify a triode, and the grid is the control element.

### Tube and FET similarity

A FET often feels more like a tube than a bipolar transistor does because both use an electric field at a control terminal to influence a current path. A triode grid controls electron flow through a vacuum; a FET gate controls conduction through a semiconductor channel.

The materials are completely different, but the control analogy helps with exam-level recognition.

## Try it

- An NPN symbol in a driver circuit has its emitter arrow pointing away from the base. Use the arrow to confirm the part family and polarity before replacing it.
- A sensor node must watch a tuned circuit without drawing much current from it. Choose a FET input stage and explain that the gate is the light-loading control terminal.
- A circuit drives a transistor fully on and fully off to operate a relay. Name the role: electronic switch.
- A high-power RF stage uses a hot glass device whose grid voltage changes the current drawn by the plate. Explain which element is doing the controlling and why high voltage caution matters.
- A circuit was biased for an N-channel FET, but the parts drawer has only a P-channel device. Do not assume it is a drop-in substitute; the channel type and bias polarity matter.

## Radio connection

A modern transceiver may contain many bipolar transistors and FETs in oscillators, mixers, RF amplifiers, audio stages, switching circuits, and control lines. A separate high-power amplifier may contain large RF power transistors or, in some designs, vacuum tubes.

When reading a block diagram or schematic, terminal names give fast clues. Base suggests bipolar transistor control. Gate suggests FET control. Grid and plate suggest a tube. Once you know the family, you can reason about polarity, bias, input loading, and heat.

## Common mistakes

- Swapping NPN and PNP parts without checking circuit polarity.
- Calling every three-terminal semiconductor a bipolar transistor. FETs also have three terminals but use gate, source, and drain names.
- Assuming a FET gate behaves like a low-resistance input. In normal Basic-level operation it is treated as high impedance.
- Forgetting that source and drain are the channel ends, while the gate controls the channel.
- Thinking saturation is always a fault. In switching service, saturation can be an intended on state.
- Forgetting that tube circuits can contain dangerous high voltages even after power is removed.

## Illustration brief

Alt text: Three side-by-side simplified symbols for an NPN transistor, an N-channel FET, and a triode tube, with their control terminals highlighted.

Description: Draw three ink-brush component sketches. Label the bipolar transistor terminals collector, base, and emitter, with a small arrow on the emitter. Label the FET terminals drain, gate, and source, showing the gate near a channel. Label the triode tube cathode, grid, and plate inside a glass envelope. Use a different wash or circle around base, gate, and grid to show the control terminals.

## Summary

- Bipolar transistors use collector, base, and emitter terminals.
- NPN and PNP devices require opposite circuit polarities.
- A bipolar transistor can amplify in its active region or switch between cut-off and saturation.
- A transistor can switch a relay or fan when ratings and protection parts are chosen correctly.
- A FET uses gate, source, and drain terminals; the gate controls channel conduction.
- FET gates are treated as high-impedance inputs in normal operation.
- In FET-to-bipolar comparisons, source is like emitter and drain is like collector.
- A triode tube has a cathode, one grid, and a plate inside a vacuum envelope.
- Tubes can amplify and may be chosen where high RF power or voltage handling is useful.
