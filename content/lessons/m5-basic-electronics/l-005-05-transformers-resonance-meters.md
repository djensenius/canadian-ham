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

A stronger current in a conductor produces a stronger magnetic field around it. Induced voltage is strongest during the fastest current change, not while current is simply sitting at a steady value.

Coupling between wires is strongest when they are close and parallel. Transformer cores and winding arrangements are designed to make coupling useful, but energy transfer is not perfect. Warm iron laminations show that some energy is being lost as heat.

## Transformer power calculations

For ideal transformer questions, input power and output power are treated as equal:

Primary power = secondary power

Power is still P = I x E.

### Worked example: primary current

A transformer primary is 240 V and supplies 360 W to a bench supply, neglecting losses.

- I = P / E.
- I = 360 W / 240 V.
- I = 1.5 A.

The primary current is 1.5 A.

### Worked example: secondary current

A transformer has a 240 V primary drawing 0.3 A and a 36 V secondary, with no losses.

- Primary power P = I x E = 0.3 x 240 = 72 W.
- Secondary current I = P / E = 72 / 36 = 2 A.

The lower-voltage side can supply more current when power is conserved.

### Worked example: turns ratio and voltage

A transformer primary has 800 turns and the secondary has 120 turns. The secondary has 0.15 times as many turns as the primary.

- Turns ratio secondary/primary = 120 / 800 = 0.15.
- Secondary voltage = 240 V x 0.15 = 36 V.

A step-down transformer decreases voltage and increases current in the ideal case.

### Worked example: current in a step-up transformer

A 1:4 primary-to-secondary turns ratio steps voltage up by 4. If the secondary current is 75 mA, ideal primary current is 4 times larger:

- Primary current = 75 mA x 4 = 300 mA.

The current changes in the opposite direction to the voltage ratio when power is conserved.

## Resonance and tuned circuits

A tuned circuit uses an inductor and a capacitor. Resonance occurs when inductive reactance and capacitive reactance are equal in size and opposite in sign. At that frequency, the circuit has a special response.

A parallel tuned circuit has high impedance at resonance. A series tuned circuit has low impedance at resonance. In a series RLC circuit tuned to the source frequency, current reaches a maximum.

The resonant frequency is the single centre frequency where the condition is exact. The useful range around it is called bandwidth.

Receivers use resonant circuits to select desired signal frequencies and reject others. Adding a resistor to a simple coil-and-air-capacitor tuned circuit can change sharpness and losses, but it does not change the inductance or capacitance values that set the ideal resonant frequency.

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

## Try it

1. A transformer primary consumes 54 W. If the ideal secondary voltage is 18 V, I = P / E = 54 / 18 = 3 A.
2. A parallel resonant circuit at resonance has high impedance.
3. A series resonant circuit at resonance has low impedance and maximum current.
4. To measure voltage across a resistor, connect the voltmeter in parallel with that resistor.
5. To measure current drawn from a supply, place an ammeter in series with the current path.

## Radio connection

Transformers appear in power supplies, audio stages, and impedance-matching networks. Tuned circuits appear in receivers, filters, oscillators, and antenna matching. Meters are how you check a station safely: a multimeter for DC work, an ammeter for current, a voltmeter for voltage, and an RF wattmeter for transmitter output.

Good operators measure before guessing. A wrong meter connection can blow a meter fuse or disturb the circuit, so knowing series versus parallel connections is a practical safety skill.

## Common mistakes

- Forgetting that ideal transformer current changes opposite to voltage.
- Using turns ratio backward. Compare secondary turns to primary turns when finding secondary voltage from primary voltage.
- Thinking resonance always means high impedance. Parallel resonance is high impedance; series resonance is low impedance.
- Calling bandwidth the same thing as the single resonant frequency.
- Connecting a voltmeter in series or an ammeter in parallel.
- Assuming real transformers are perfect. Warm laminations and other heating show losses.

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
