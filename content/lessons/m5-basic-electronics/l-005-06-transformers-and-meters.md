---
type: lesson
id: L-005-06
moduleId: M5
categoryIds:
  - B-005
title:
  en: "Transformers and meters"
  fr: null
covers:
  - B-005-011
  - B-005-013
objectives:
  - "Calculate ideal transformer voltage, current, and power relationships."
  - "Explain magnetic coupling, induction, and transformer impedance change in plain language."
  - "Choose and connect meters for voltage, current, resistance, and RF power checks."
prerequisites:
  - L-005-05
estimatedMinutes: 35
quizIds:
  - QZ-L-005-06-A
status: draft
---
# Transformers and meters

This lesson brings the first electronics module into radio practice. Transformers transfer energy by changing magnetic fields. Meters let you measure what is happening instead of guessing.

The calculations here use ideal transformer assumptions when the question says to neglect losses or assume 100 % efficiency. Real transformers waste some energy as heat, so practical equipment needs margin.

## Learning objectives

By the end of this lesson, you can:

- use ideal power relationships in transformers;
- use turns ratio to calculate transformer voltage ratio;
- explain magnetic coupling and induction in plain language;
- describe why a transformer can change impedance;
- connect voltmeters and ammeters correctly; and
- name common instruments used in radio servicing.

## Transformers and magnetic fields

A transformer has windings coupled by a changing magnetic field. AC in the primary winding creates a changing magnetic field. That changing field induces voltage in the secondary winding.

A stronger current in a conductor produces a stronger magnetic field around it. A permanent magnet is different: it keeps its own field without any current. Permanent magnets are made from ferromagnetic materials that hold magnetism, such as hardened steel. Copper, aluminum, and brass are not useful permanent-magnet materials. Induced voltage is strongest during the fastest current change, not while current is simply sitting at a steady value.

Coupling between wires is strongest when they are close and parallel. Transformer cores and winding arrangements are designed to make coupling useful, but energy transfer is not perfect. Warm iron laminations show that some energy is being lost as heat.

A transformer can also change the impedance seen by a circuit. Each winding has its own voltage and current relationship. Because impedance is E / I for AC, changing the voltage and current ratio changes the impedance presented to the connected circuit.

### In the real world: wall-wart transformer

An older wall-wart supply may use a small transformer before rectifiers and filters. A 120 V AC primary and a 15 V AC secondary is an 8:1 voltage step-down.

If the secondary supplies 15 V at 1.6 A to a purely resistive load, the output is 24 W. The calculation is 15 V x 1.6 A = 24 W. Real rectifier-and-filter loads are not purely resistive, so transformer labels often use VA. VA means apparent power.

An ideal transformer delivering 24 W from a 120 V primary would draw I = P / E = 24 W / 120 V = 0.20 A. A real small transformer supply draws more input current than the ideal calculation because some power becomes heat.

### Faded practice: finish a wall-wart estimate

Use an ideal transformer and a purely resistive AC load.

- Given: primary E = 120 V; secondary E = 18 V RMS; secondary I = 1.4 A RMS.
- Find: secondary power and ideal primary current.
- Formula: P = I x E; primary I = P / primary E.
- Complete: P = 1.4 x ___ = ___ W; primary I = ___ / 120 = ___ A.
- Sanity check: Should the higher-voltage side carry less current?

Fill the gaps before checking below.

### Check your work: finish a wall-wart estimate

Output power = 25.2 W. Ideal primary current = 0.21 A. Real losses raise input power; reactive or rectifier loads need more care than this simple model.

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

### Faded practice: finish turns and current together

An ideal step-down transformer supplies a resistive load.

- Given: primary E = 180 V RMS; primary turns = 750; secondary turns = 125; secondary I = 0.8 A RMS.
- Find: secondary voltage and primary current.
- Formula: secondary E = primary E x secondary turns / primary turns; P = I x E; primary I = P / primary E.
- Complete: secondary E = 180 x ___ / 750 = ___ V; output P = 0.8 x ___ = ___ W; primary I = ___ / 180 ≈ ___ A.
- Sanity check: Did voltage step down and current step up from primary to secondary?

Fill the gaps before checking below.

### Check your work: finish turns and current together

Secondary E = 30 V, P = 24 W, and primary I ≈ 0.133 A. Equal ideal power, rather than equal current, connects the windings.

## Meters and how to connect them

A meter should disturb the circuit as little as practical.

| Quantity | Instrument | Usual connection | Ideal meter behaviour |
|---|---|---|---|
| Voltage or potential difference | Voltmeter | In parallel with the component or circuit | High resistance |
| Current | Ammeter | In series with the circuit | Low resistance |
| Voltage, current, resistance | Multimeter | Depends on selected mode | Follow the selected function |
| RF transmitter output power | RF wattmeter | In the feedline between the transmitter and load or antenna | Matched to the RF system |
| Final power amplifier current | Ammeter | In series with the final amplifier DC current path | Low resistance |

::figure transformer-resonance-meters
Alt text: Two-panel figure showing transformer windings on a core and ammeter and voltmeter placement around a load.
Text equivalent:
- Transformer panel: separate P and S coil windings sit on a shared two-bar core.
- Meter panel: a battery source is in the left branch, an A meter is in series on the top wire, the zigzag load is in the right branch, and a V meter is wired across the load.
::

A voltmeter is placed across the part being measured. It should look like a high resistance so very little extra current flows through the meter.

An ammeter is placed in series so the circuit current flows through it. It should look like a low resistance so it does not create a large extra voltage drop.

Accuracy tells how close a meter reading is to the actual value being measured. Precision describes how closely repeated readings agree with each other. Resolution is the smallest displayed step. A meter can show many digits and still be inaccurate if it is not calibrated.

### Memory trick: V across, A along

- Helps remember: voltmeter and ammeter connections.
- Trick: measure voltage across a part; put an ammeter along the current path.
- Limit: this is a connection memory aid. Always check the meter mode, lead jacks, and range before touching a live circuit.

### In the real world: meter fuse check

Most digital multimeters have a fuse in the current input. If you put the meter across a battery while it is set for current, the meter can create a near short circuit. That can blow the meter fuse.

Before measuring current, move the lead to the current jack, choose the current range, and open the circuit so the meter can go in series.

## Try it

Try these before reading the feedback below.

1. An ideal transformer takes 54 W at its primary. Find secondary current at 18 V.
2. How do you connect a voltmeter to measure a resistor's voltage?
3. How do you connect an ammeter to measure supply current?
4. How would you describe repeated readings close together but offset from the true value?
5. Why can a transformer change impedance?

### Try-it feedback

1. I = P / E = 54 / 18 = 3 A.
2. Connect it in parallel across the resistor.
3. Open the path and insert the ammeter in series, with the correct range and lead jacks.
4. They are precise but inaccurate.
5. It changes the AC voltage and current ratio. Impedance is E / I for AC.

## Radio connection

Transformers appear in power supplies, audio stages, and impedance-matching networks. Meters help you check a station safely. Use a multimeter for DC work, an ammeter for current, a voltmeter for voltage, and an RF wattmeter for transmitter output.

Good operators measure before guessing. A wrong meter connection can blow a meter fuse or disturb the circuit, so knowing series versus parallel connections is a practical safety skill.

## Common mistakes

- Forgetting that ideal transformer current changes opposite to voltage.
- Using turns ratio backward. Compare secondary turns to primary turns when finding secondary voltage from primary voltage.
- Connecting a voltmeter in series or an ammeter in parallel.
- Assuming real transformers are perfect. Warm laminations and other heating show losses.
- Mixing up accuracy, precision, and resolution.

## Illustration brief

Alt text: Two-panel figure showing transformer windings on a core and ammeter and voltmeter placement around a load.

Description: Draw an original two-panel ink-brush figure. The left panel shows separate coils labelled P and S on a shared two-bar core. The right panel shows a battery, a load, an ammeter labelled A in series, and a voltmeter labelled V across the load. Use labels and line patterns rather than colour alone.

## Summary

- Transformers use changing magnetic fields to transfer energy between windings.
- In ideal transformer problems, input power equals output power.
- Voltage follows turns ratio; current changes in the opposite direction when power is conserved.
- A transformer can change the impedance presented to a circuit.
- Voltmeters connect in parallel and should appear as high resistance.
- Ammeters connect in series and should appear as low resistance.
- RF wattmeters directly measure transmitter output power.
