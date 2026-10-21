---
type: lesson
id: L-005-05
moduleId: M5
categoryIds:
  - B-005
title:
  en: "Capacitors, inductors, reactance, and resonance"
  fr: null
covers:
  - B-005-009
  - B-005-010
  - B-005-012
objectives:
  - "Combine equal inductors and capacitors in series or parallel."
  - "Explain the construction factors for coils and capacitors."
  - "Predict how inductive and capacitive reactance change with frequency."
  - "Explain resonance in series and parallel tuned circuits."
prerequisites:
  - L-005-04
estimatedMinutes: 40
quizIds:
  - QZ-L-005-05-A
status: draft
---
# Capacitors, inductors, reactance, and resonance

Capacitors and inductors store energy for a short time. A capacitor stores energy in an electric field. An inductor stores energy in a magnetic field.

With DC, those parts can look simple after the first moment of change. With AC and RF, their opposition depends on frequency. That frequency-dependent opposition is reactance. Reactance leads naturally to resonance, where an inductor and capacitor respond strongly at one frequency.

## Learning objectives

By the end of this lesson, you can:

- combine equal capacitors and inductors in simple series or parallel circuits;
- explain the construction factors for coils and capacitors;
- predict how inductors and capacitors behave as AC frequency changes;
- describe impedance as the AC ratio of E to I; and
- explain resonance in series and parallel tuned circuits.

## Inductors and capacitors in combinations

An inductor stores energy in a magnetic field. A capacitor stores energy in an electric field.

The reference sheet gives these relationships:

| Component | Series total | Parallel total |
|---|---|---|
| Inductors | Lt = L1 + L2 + ... + Ln | 1 / Lt = 1 / L1 + 1 / L2 + ... + 1 / Ln |
| Capacitors | 1 / Ct = 1 / C1 + 1 / C2 + ... + 1 / Cn | Ct = C1 + C2 + ... + Cn |

Notice that capacitors are opposite to resistors for series and parallel totals. Inductors follow the resistor pattern in the simple ideal cases shown here.

### Worked example: equal parts

Equal parts often make the pattern easier to see.

- Given: two 7 mH inductors in series; two 18 mH inductors in parallel; two 33 µF capacitors in series; two 47 µF capacitors in parallel.
- Find: each total value.
- Formula: equal inductors add in series and halve in parallel; equal capacitors halve in series and add in parallel.
- Substitute: 7 + 7; 18 / 2; 33 / 2; 47 + 47.
- Answer: 14 mH, 9 mH, 16.5 µF, and 94 µF.
- Sanity check: the capacitor series answer is smaller than either capacitor, while the capacitor parallel answer is larger.

### Faded practice: finish equal reactive parts

Use the ideal combination rules, with negligible magnetic coupling between coils.

- Given: three 15 mH inductors in series; a separate pair of 22 µF capacitors in series.
- Find: total inductance and total capacitance.
- Formula: series inductors add; equal series capacitors use Ct = C / count.
- Complete: Lt = 15 + ___ + ___ = ___ mH; Ct = 22 / ___ = ___ µF.
- Sanity check: Did the coil total rise while the capacitor total fell?

Fill the gaps before checking below.

### Check your work: finish equal reactive parts

Lt = 45 mH and Ct = 11 µF. These rules describe the ideal parts, not frequency-independent reactance.

## What sets inductance and capacitance?

For an air-core coil, inductance depends mainly on the coil's size, its winding count, and its shape. Changing the diameter, length, or turn count changes the magnetic field. That changes the inductance.

For a simple air-spaced capacitor, capacitance depends on plate area and spacing. Larger facing plate area gives more capacitance. More spacing gives less capacitance. Replacing the air gap with a suitable dielectric material, such as a plastic film, also changes the capacitance and raises it.

Polarized electrolytic capacitors need correct polarity. Never apply reverse voltage to a polarized electrolytic capacitor.

### In the real world: power-supply filter capacitor

A filter capacitor in a power supply charges near the voltage peaks after a diode or rectifier has made the current one-way. Between peaks, it gives energy back to the load. That reduces ripple, which is unwanted rise and fall on the DC output.

This does not make a capacitor a battery. A capacitor stores energy in an electric field and charges or discharges quickly. A battery stores energy chemically and is meant to supply energy for longer.

## Reactance and impedance

Reactance is opposition to AC caused by capacitance or inductance. Unlike ordinary resistance, reactance changes with frequency.

Inductive reactance increases as frequency increases. An inductor opposes change in current, so faster AC changes meet more opposition. This is why an RF choke can block radio-frequency current while letting lower-frequency or DC current pass more easily.

Capacitive reactance decreases as frequency increases. This is why a bypass capacitor can provide an easy path for unwanted RF. At audio frequencies, the same capacitor can have high reactance, so it has little effect on the wanted audio when chosen correctly.

Impedance is the combined effect of resistance and reactance in an AC circuit. Impedance, often written Z, is E / I for AC: AC voltage divided by AC current.

### In the real world: ferrite choke on a noisy lead

A ferrite choke around a cable acts like an inductor for unwanted RF current. At radio frequencies it can add high reactance. At DC or low audio frequencies, it has much less effect on the intended power or audio path.

That is why snap-on ferrites are common on computer leads, charger leads, and station accessory cables. They are not magic noise erasers, but they can make an unwanted RF path harder to use.

### Misconception: reactance is fixed like a resistor value

- Mistaken idea: a stated reactance stays the same at every frequency.
- Correction: inductive reactance rises with frequency, while capacitive reactance falls with frequency.

## Resonance and tuned circuits

A tuned circuit uses an inductor and a capacitor. Resonance occurs when inductive reactance and capacitive reactance are equal in size and opposite in sign. At that frequency, their opposite effects cancel in a series path or circulate energy in a parallel path.

A series tuned circuit has low impedance at resonance because the L and C reactances cancel, leaving mainly resistance. Current reaches a maximum in a series RLC circuit tuned to the source frequency.

A parallel tuned circuit has high impedance at resonance. Energy swaps between the inductor's magnetic field and the capacitor's electric field, so the circuit draws little current from the source.

::figure parallel-lc-resonance
Alt text: Parallel LC tuned circuit with an inductor and capacitor between shared rails, labelled high Z at resonance.
Text equivalent:
- The inductor L and capacitor C form separate branches between the same top and bottom rails.
- Z means impedance. This parallel circuit has high impedance at resonance and draws little current from the source.
- The high-impedance label applies to parallel resonance. A series tuned circuit has low impedance at resonance.
::

The resonant frequency is the single centre frequency where the condition is exact. More inductance or more capacitance lowers that frequency. The useful range around it is called bandwidth.

Receivers use resonant circuits to select desired signal frequencies and reject others. Adding a resistor to a simple coil-and-air-capacitor tuned circuit can change sharpness and losses.

The resistor does not change the inductance or capacitance values that set the ideal resonant frequency.

### In the real world: tuning a receiver front end

A receiver front end uses tuned circuits so the desired signal passes more easily than nearby unwanted signals. Turning a tuning capacitor changes capacitance. That changes the resonant frequency of the coil-and-capacitor circuit.

This is the same idea as choosing one conversation from a crowded room. The circuit cannot make a weak signal strong by itself, but it can favour one frequency before later amplifier stages.

### Misconception: resonance always means high impedance

- Mistaken idea: any resonant circuit has high impedance.
- Correction: a parallel resonant circuit has high impedance at resonance. A series resonant circuit has low impedance at resonance.

## Try it

Try these before reading the feedback below.

1. As frequency rises, how does inductive reactance change?

:::answer
Inductive reactance increases.
:::

2. As frequency rises, how does capacitive reactance change?

:::answer
Capacitive reactance decreases.
:::

3. What happens to total capacitance when equal capacitors are placed in parallel?

:::answer
Total capacitance increases.
:::

4. Which tuned-circuit arrangement has low impedance at resonance?

:::answer
A series tuned circuit has low impedance at resonance.
:::

5. Which L or C change lowers the resonant frequency of a tuned circuit?

:::answer
More inductance or more capacitance lowers resonant frequency.
:::

## Radio connection

Chokes and bypass capacitors help keep RF out of places it should not go. Inductors and capacitors also form tuned circuits in receivers, transmitters, filters, oscillators, and antenna matching networks.

Reactance depends on frequency, so the same part may act differently at audio, HF, VHF, and DC. That is why a part choice must match the job and the frequency range.

## Common mistakes

- Treating inductors and capacitors as if their reactance stayed constant with frequency.
- Mixing up capacitor series and parallel rules.
- Ignoring electrolytic capacitor polarity.
- Calling bandwidth the same thing as the single resonant frequency.
- Assuming every resonant circuit has high impedance.

## Illustration brief

Alt text: Parallel LC tuned circuit with an inductor and capacitor between shared rails, labelled high Z at resonance.

Description: Draw an original ink-brush parallel LC circuit. Put the inductor labelled L and capacitor labelled C in separate branches between shared top and bottom rails. Label it "parallel LC" and "high Z at resonance." The text equivalent explains that Z means impedance and distinguishes parallel from series resonance. Use labels and line patterns rather than colour alone.

## Summary

- Inductors add in series; capacitors add in parallel.
- Capacitance depends on plate area, spacing, and dielectric material; inductance depends on coil size, turns, and shape.
- Inductive reactance increases with frequency; capacitive reactance decreases with frequency.
- Impedance combines resistance and reactance in AC circuits.
- Resonance occurs when inductive and capacitive reactance are equal and opposite.
- Series resonance gives low impedance; parallel resonance gives high impedance.
