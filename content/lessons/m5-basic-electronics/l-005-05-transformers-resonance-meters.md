---
type: lesson
id: L-005-05
moduleId: M5
categoryIds:
  - B-005
title:
  en: "Transformers, resonance, and meters"
  fr: null
covers:
  - B-005-011
  - B-005-012
  - B-005-013
objectives:
  - "Calculate ideal transformer voltage, current, and power relationships."
  - "Explain resonance in series and parallel tuned circuits."
  - "Choose and connect meters for voltage, current, resistance, and RF power checks."
prerequisites:
  - L-005-04
estimatedMinutes: 40
quizIds:
  - QZ-L-005-05-A
status: draft
---
# Transformers, resonance, and meters

This lesson brings the first electronics module into radio practice. Transformers transfer energy by changing magnetic fields. Tuned circuits use inductors and capacitors to select frequencies. Meters let you measure what is happening instead of guessing.

The calculations here use ideal transformer assumptions when the question says to neglect losses or assume 100% efficiency. Real transformers waste some energy as heat, so practical equipment needs margin.

## Learning objectives

By the end of this lesson, you can:

- use ideal power relationships in transformers;
- use turns ratio to calculate transformer voltage ratio;
- explain magnetic coupling and induction in plain language;
- describe resonance in series and parallel tuned circuits;
- connect voltmeters and ammeters correctly; and
- name common instruments used in radio servicing.

## Transformers and magnetic fields

A transformer has windings coupled by a changing magnetic field. AC in the primary winding creates a changing magnetic field. That changing field induces voltage in the secondary winding.

A stronger current in a conductor produces a stronger magnetic field around it. A permanent magnet is different: it keeps its own field without any current. Permanent magnets are usually made from hard magnetic materials such as steel. Induced voltage is strongest during the fastest current change, not while current is simply sitting at a steady value.

Coupling between wires is strongest when they are close and parallel. Transformer cores and winding arrangements are designed to make coupling useful, but energy transfer is not perfect. Warm iron laminations show that some energy is being lost as heat.

### In the real world: wall-wart transformer

An older wall-wart supply may use a small transformer before rectifiers and filters. A 120 V AC primary and a 15 V AC secondary is an 8:1 voltage step-down.

If the secondary supplies 15 V at 1.6 A to a purely resistive load, the output is 24 W. The calculation is 15 V x 1.6 A = 24 W. Real rectifier-and-filter loads are not purely resistive, so transformer labels often use VA. VA means apparent power.

An ideal transformer delivering 24 W from a 120 V primary would draw I = P / E = 24 W / 120 V = 0.20 A. A real small transformer supply draws more input current than the ideal calculation because some power becomes heat.

## Transformer power calculations

For ideal transformer questions, input power and output power are treated as equal:

Primary power = secondary power

Power is still P = I x E.

### Worked example: primary current

A transformer primary is 240 V and supplies 360 W to a bench supply, neglecting losses.

- Given: E = 240 V; P = 360 W.
- Find: primary current I.
- Formula: I = P / E.
- Substitute: I = 360 W / 240 V.
- Answer: I = 1.5 A.
- Sanity check: 240 V at a few amperes can supply several hundred watts.

### Worked example: secondary current

A transformer has a 240 V primary drawing 0.3 A and a 36 V secondary, with no losses.

- Given: primary E = 240 V; primary I = 0.3 A; secondary E = 36 V.
- Find: secondary current I.
- Formula: P = I x E; secondary I = P / secondary E.
- Substitute: primary P = 0.3 A x 240 V = 72 W; secondary I = 72 W / 36 V.
- Answer: secondary I = 2 A.
- Sanity check: the lower-voltage side can supply more current when power is conserved.

### Worked example: turns ratio and voltage

A transformer primary has 800 turns and the secondary has 120 turns. The primary is connected to 240 V.

- Given: primary turns = 800; secondary turns = 120; primary E = 240 V.
- Find: secondary voltage.
- Formula: secondary E = primary E x secondary turns / primary turns.
- Substitute: secondary E = 240 V x 120 / 800.
- Answer: secondary E = 36 V.
- Sanity check: the secondary has fewer turns, so the voltage steps down.

### Worked example: current in a step-up transformer

A 1:4 primary-to-secondary turns ratio steps secondary voltage up to 4 times the primary voltage. The secondary current is 75 mA.

- Given: primary-to-secondary voltage ratio = 1:4, so secondary-to-primary voltage ratio = 4; secondary I = 75 mA.
- Find: ideal primary current.
- Formula: primary current = secondary current x secondary-to-primary voltage ratio.
- Substitute: primary current = 75 mA x 4.
- Answer: primary current = 300 mA.
- Sanity check: current changes in the opposite direction to voltage when power is conserved.

## Resonance and tuned circuits

A tuned circuit uses an inductor and a capacitor. Resonance occurs when inductive reactance and capacitive reactance are equal in size and opposite in sign. At that frequency, the circuit has a special response.

A parallel tuned circuit has high impedance at resonance. A series tuned circuit has low impedance at resonance. In a series RLC circuit tuned to the source frequency, current reaches a maximum.

The resonant frequency is the single centre frequency where the condition is exact. The useful range around it is called bandwidth.

Receivers use resonant circuits to select desired signal frequencies and reject others. Adding a resistor to a simple coil-and-air-capacitor tuned circuit can change sharpness and losses.

The resistor does not change the inductance or capacitance values that set the ideal resonant frequency.

### In the real world: tuning a receiver front end

A receiver front end uses tuned circuits so the desired signal passes more easily than nearby unwanted signals. Turning a tuning capacitor changes capacitance. That changes the resonant frequency of the coil-and-capacitor circuit.

This is the same idea as choosing one conversation from a crowded room. The circuit cannot make a weak signal strong by itself, but it can favour one frequency before later amplifier stages.

### Misconception: resonance always means high impedance

- Mistaken idea: any resonant circuit has high impedance.
- Correction: a parallel resonant circuit has high impedance at resonance. A series resonant circuit has low impedance at resonance.

## Meters and how to connect them

A meter should disturb the circuit as little as practical.

| Quantity | Instrument | Usual connection | Ideal meter behaviour |
|---|---|---|---|
| Voltage or potential difference | Voltmeter | In parallel with the component or circuit | High resistance |
| Current | Ammeter | In series with the circuit | Low resistance |
| Voltage, current, resistance | Multimeter | Depends on selected mode | Follow the selected function |
| RF transmitter output power | RF wattmeter | In the RF line as designed | Matched to the RF system |
| Final power amplifier current | Ammeter | In the appropriate current path | Low resistance |

A voltmeter is placed across the part being measured. It should look like a high resistance so very little extra current flows through the meter.

An ammeter is placed in series so the circuit current flows through it. It should look like a low resistance so it does not create a large extra voltage drop.

Accuracy tells how close a meter reading is to the actual value being measured.

### Memory trick: V across, A along

- Helps remember: voltmeter and ammeter connections.
- Trick: measure voltage across a part; put an ammeter along the current path.
- Limit: this is a connection memory aid. Always check the meter mode, lead jacks, and range before touching a live circuit.

### In the real world: meter fuse check

Most digital multimeters have a fuse in the current input. If you put the meter across a battery while it is set for current, the meter can create a near short circuit. That can blow the meter fuse.

Before measuring current, move the lead to the current jack, choose the current range, and open the circuit so the meter can go in series.

## Try it

1. A transformer primary consumes 54 W. If the ideal secondary voltage is 18 V, I = P / E = 54 / 18 = 3 A.
2. A parallel resonant circuit at resonance has high impedance.
3. A series resonant circuit at resonance has low impedance and maximum current.
4. To measure voltage across a resistor, connect the voltmeter in parallel with that resistor.
5. To measure current drawn from a supply, place an ammeter in series with the current path.

## Radio connection

Transformers appear in power supplies, audio stages, and impedance-matching networks. Tuned circuits appear in receivers, filters, oscillators, and antenna matching.

Meters help you check a station safely. Use a multimeter for DC work, an ammeter for current, a voltmeter for voltage, and an RF wattmeter for transmitter output.

Good operators measure before guessing. A wrong meter connection can blow a meter fuse or disturb the circuit, so knowing series versus parallel connections is a practical safety skill.

## Common mistakes

- Forgetting that ideal transformer current changes opposite to voltage.
- Using turns ratio backward. Compare secondary turns to primary turns when finding secondary voltage from primary voltage.
- Calling bandwidth the same thing as the single resonant frequency.
- Connecting a voltmeter in series or an ammeter in parallel.
- Assuming real transformers are perfect. Warm laminations and other heating show losses.

::figure transformer-resonance-meters
Alt text: Three small sketches: a transformer with primary and secondary coils, a parallel LC tuned circuit, and correct meter placements.
Text equivalent:
- Transformer: AC in the primary changes magnetic flux and induces voltage in the secondary.
- Parallel LC tuned circuit: the inductor and capacitor are in parallel and the impedance is high at resonance.
- Meter placement: the ammeter is in series with the load, and the voltmeter is across the load.
::

## Illustration brief

Alt text: Three small sketches: a transformer with primary and secondary coils, a parallel LC tuned circuit, and correct meter placements.

Description: Draw an original multi-panel ink-brush figure. The left panel shows paired coils on a core with arrows for changing magnetic flux. The centre panel shows an inductor and capacitor in parallel labelled "parallel tuned circuit: high impedance at resonance." The right panel shows a voltmeter across a load and an ammeter in series with the load. Use labels and line patterns rather than colour alone.

## Summary

- Transformers use changing magnetic fields to transfer energy between windings.
- In ideal transformer problems, input power equals output power.
- Voltage follows turns ratio; current changes in the opposite direction when power is conserved.
- Resonance occurs when inductive and capacitive reactance are equal and opposite.
- Parallel resonance gives high impedance; series resonance gives low impedance and maximum current.
- Voltmeters connect in parallel and should appear as high resistance.
- Ammeters connect in series and should appear as low resistance.
- RF wattmeters directly measure transmitter output power.
