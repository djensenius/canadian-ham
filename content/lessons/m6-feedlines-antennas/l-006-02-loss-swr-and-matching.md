---
type: lesson
id: L-006-02
moduleId: M6
categoryIds:
  - B-006
title:
  en: "Loss, SWR, and matching"
  fr: null
covers:
  - B-006-004
  - B-006-005
  - B-006-006
objectives:
  - "Identify causes of feedline loss."
  - "Interpret SWR readings without treating them as a complete efficiency measure."
  - "Explain what a tuner or matching network changes."
prerequisites:
  - L-006-01
estimatedMinutes: 45
quizIds:
  - QZ-L-006-02-A
status: draft
---
# Loss, SWR, and matching

A feedline is never perfect. Some RF energy becomes heat before it reaches the antenna. A mismatch can also reflect energy back toward the transmitter.

The goal is not to chase magic numbers. The goal is to understand what the readings mean and place matching where it reduces real loss.

## Learning objectives

By the end of this lesson, you can:

- explain why feedline loss increases with length and frequency;
- recognize how cable type affects radiated power;
- interpret an SWR meter without treating it as an antenna-efficiency meter;
- explain why line loss can hide a mismatch at the station end; and
- describe what tuners, transformers, and matching networks do.

## Feedline loss

Feedline loss is commonly stated in decibels per unit length, such as dB per 100 m or dB per 30 m. A longer run has more total loss because the signal travels through more lossy conductor and dielectric.

Higher frequencies usually have more loss in the same cable. At RF, current is concentrated near conductor surfaces; this is called skin effect. Dielectric losses also rise with frequency. Small coax that is fine for a short HF jumper may waste a lot of power on a long UHF run.

RG-58 is thin, flexible coax with higher loss in demanding runs. RG-213 is thicker and usually lower-loss, so more transmitter power can reach the antenna on the same route. Larger or lower-loss coax costs more and is less flexible. Balanced open-wire line can have very low loss when installed well.

### Worked example: doubling cable length

A coax has 0.7 dB loss over a 14 m run at a chosen frequency. The same cable and frequency are used over 28 m.

- Given: 14 m loss = 0.7 dB; new length = 28 m.
- Find: approximate new loss.
- Formula: for the same cable and frequency, dB loss scales with length.
- Substitute: 28 m is 2 x 14 m, so loss is 2 x 0.7 dB.
- Answer: loss is about 1.4 dB.
- Sanity check: the characteristic impedance did not change; only attenuation increased.

### Faded practice: finish a cable-loss estimate

Compare lengths of the same cable at the same frequency and match.

- Given: loss = 0.9 dB over 15 m; new length = 45 m.
- Find: new dB loss.
- Formula: new loss = old loss x new length / old length.
- Complete: new loss = 0.9 x (45 / ___) = ___ dB.
- Sanity check: Did you scale dB loss rather than characteristic impedance?

Fill the gaps before checking below.

### Check your work: finish a cable-loss estimate

The length factor is 3, so loss = 2.7 dB. Cable geometry and dielectric still set Z0.

### In the real world: trimming excess cable

A temporary antenna is 11 m from the operating table, but the station uses a 33 m coil of small coax because it was already assembled.

Replacing it with a 12 m run removes 21 m of unnecessary cable. Coiling the spare cable neatly does not remove its attenuation.

### Faded practice: finish an excess-cable comparison

A portable station can replace an unnecessarily long coax run.

- Given: installed length = 38 m; needed length = 19 m; same cable and frequency.
- Find: length removed and remaining fraction of dB loss.
- Formula: removed length = installed - needed; remaining loss fraction = needed / installed.
- Complete: removed length = 38 - ___ = ___ m; remaining loss fraction = 19 / ___ = ___.
- Sanity check: Does halving cable length halve its dB attenuation under these assumptions?

Fill the gaps before checking below.

### Check your work: finish an excess-cable comparison

Remove 19 m. The remaining dB loss is half the original value. This does not mean half the watts are lost; dB is a ratio scale.

## SWR in plain language

SWR means standing wave ratio. It compares forward and reflected RF voltage waves on a transmission line. An SWR near 1:1 means the line and load are closely matched at the measurement point. An SWR below about 1.5:1 is often a fairly good match for ordinary station work. A higher reading means more energy is being reflected because the load impedance does not match the line's characteristic impedance.

A standing wave forms when the forward wave and reflected wave add and cancel at fixed places along the line. That leaves voltage and current peaks and dips along the cable. Current peaks raise conductor heating, and voltage peaks raise dielectric heating, so high SWR increases line loss. Low-loss open-wire line can tolerate high SWR better than small coax because its basic loss is lower.

A low SWR reading is useful, but it is not a complete proof that the antenna system is efficient. A lossy feedline can weaken the reflected wave before it returns to the meter. The station-end meter may look better than the antenna-end mismatch really is.

### In the real world: reflected-power estimates

Reflection coefficient is the reflected voltage wave compared with the forward voltage wave. Use reflection coefficient = (SWR - 1) / (SWR + 1). Reflected power fraction is the reflection coefficient multiplied by itself.

| SWR | Reflection coefficient | Reflected power estimate |
|---|---:|---:|
| 1.5:1 | (1.5 - 1) / (1.5 + 1) = 0.2 | 0.2 x 0.2 = 0.04, or 4 % |
| 2:1 | (2 - 1) / (2 + 1) = 0.333 | 0.333 x 0.333 = 0.111, or about 11 % |
| 3:1 | (3 - 1) / (3 + 1) = 0.5 | 0.5 x 0.5 = 0.25, or 25 % |

These estimates apply at the point where the SWR is measured. Reflected power is not simply "lost." Some may be lost as heat in the feedline, and the transmitter-end network or protection circuit affects what happens next.

### Faded practice: finish a reflected-power estimate

Use the measurement-point formulas from the table.

- Given: SWR = 2.5:1.
- Find: reflection coefficient and reflected-power percentage.
- Formula: coefficient = (SWR - 1) / (SWR + 1); reflected fraction = coefficient x coefficient.
- Complete: coefficient = (2.5 - 1) / (2.5 + 1) = 1.5 / ___ ≈ ___; reflected fraction ≈ 0.429 x 0.429 ≈ ___, or ___ %.
- Sanity check: Did you square the voltage ratio before expressing a power percentage?

Fill the gaps before checking below.

### Check your work: finish a reflected-power estimate

The coefficient is about 0.429 and the reflected fraction is about 0.184, or 18.4 %. This is not a claim that all that power is lost; its fate depends on the line and transmitter-end network.

### In the real world: line loss masks trouble

Station A and Station B both show low SWR at the transmitter. Station A uses a short, low-loss feedline. Station B uses a long old run that is warm after transmitting.

The same meter reading does not mean the antennas perform the same. In the lossy system, less reflected energy returns to the meter, and less forward energy reaches the antenna.

## Faults that change readings

Erratic SWR readings often point to intermittent connections. Check loose connectors, water in a joint, cracked solder, or a broken conductor that moves in the wind.

A very high reading can come from an open circuit, a short circuit, the wrong antenna, or a badly mismatched antenna. An antenna analyzer is useful because it checks a range of frequencies at low power.

## Matching networks and tuners

An antenna tuner does not tune the air. It transforms impedance so the transceiver sees a load it can safely drive. Many solid-state transmitters reduce output when the load at the radio is too far from the expected range. A tuner can help the transmitter deliver power into a mismatched antenna system.

A tuner near the transceiver protects the radio, but it does not remove loss in a feedline carrying high SWR. A tuner or matching transformer near the antenna feed point can reduce mismatch on the main feedline and reduce feedline loss.

::figure swr-loss-matching
Alt text: A station chain showing forward and reflected waves, plus a second sketch with the tuner at the antenna feed point.
Text equivalent:
- Top sketch: the rig, SWR meter, station-end ATU, lossy line, and antenna are in one chain.
- A forward wave arrow travels from the station toward the antenna.
- A reflected wave starts thick near the antenna and becomes thinner after the lossy line.
- Bottom sketch: the rig feeds a long main line to a tuner placed at the antenna feed point.
::

Matching can be done with inductors, capacitors, transmission-line sections, or transformers. A transformer ratio is set mainly by its turns, not by a narrow tuned LC resonance, so a well-designed RF transformer can cover a broad frequency range. If source and load are purely resistive, maximum power transfer happens when their impedances are equal. Once the antenna is correctly matched to the line, changing feedline length does not improve the match.

### Misconception: the tuner changes antenna length

- Mistaken idea: an antenna tuner at the radio makes the antenna physically resonant on the new frequency.
- Correction: the tuner changes the impedance seen by the transmitter. It does not change wire length, feedline loss, or the antenna's radiation pattern.

### Worked example: impedance ratio

A folded-dipole feed point is near 300 ohms in a simplified receive experiment. The station wants to connect it to 75 ohm line.

- Given: load impedance = 300 ohms; line impedance = 75 ohms.
- Find: simplified impedance transformation ratio.
- Formula: ratio = load impedance / line impedance.
- Substitute: ratio = 300 / 75.
- Answer: ratio = 4.
- Sanity check: a 4:1 impedance transformer is the first idea to investigate for this simplified resistive case.

### Faded practice: finish an impedance ratio

Use a simplified purely resistive load and line.

- Given: load = 450 ohms; line Z0 = 75 ohms.
- Find: impedance transformation ratio.
- Formula: impedance ratio = load / line Z0.
- Complete: ratio = 450 / ___ = ___, written ___:1.
- Sanity check: Is this an impedance ratio rather than a turns ratio?

Fill the gaps before checking below.

### Check your work: finish an impedance ratio

450 / 75 = 6, so the impedance ratio is 6:1. Transformer turns ratios follow a different relationship; practical matching still depends on design and frequency.

## Try it

Try these before reading the feedback below.

1. What happens to dB loss when a 22 m feedline is replaced with 11 m of the same cable at the same frequency?
2. An SWR reading jumps when the feedline moves. What should you inspect first?
3. A desk tuner gives a comfortable transmitter load but the line is hot. Where might matching help more?
4. Why can thin coax be fine for a short jumper but poor for a long roof run at VHF or UHF?
5. What evidence beyond low station-end SWR helps assess the system?

### Try-it feedback

1. It is roughly halved because dB loss accumulates with length.
2. Check connectors and conductor continuity before trimming the antenna.
3. Matching closer to the antenna can reduce high-SWR loss on the main feedline.
4. Loss rises with length and usually with frequency, making a long run much more demanding.
5. Consider cable type, length, heat, analyzer results, and on-air performance.

## Radio connection

Modern transceivers protect their output stages. If the load looks unsafe, the radio may reduce power automatically. That is protection, not failure. Your job is to find whether the issue is the antenna, feedline, connector, matching device, or operating frequency.

## Common mistakes

- Believing that an SWR meter directly measures antenna gain or radiation pattern.
- Thinking a tuner at the radio changes the physical antenna or removes all feedline loss.
- Leaving a long coil of unused small coax in the system and blaming the antenna for weak signals.
- Ignoring intermittent connectors because the antenna looked fine yesterday.
- Assuming high SWR stops all radiation; usually it reduces transfer and increases losses, but some power may still radiate.

## Illustration brief

Alt text: A station-end SWR meter, tuner, long feedline, and antenna, with reflected-wave arrows fading as they return through a lossy line.

Description: Draw the transceiver, SWR meter, tuner, feedline, and antenna as separate ink-brush blocks. Show a forward arrow moving to the antenna and a reflected arrow returning. Make the reflected arrow smaller after passing through a labelled "lossy line" section. Add a second small diagram with a tuner at the antenna feed point to show lower mismatch on the main feedline.

## Summary

- Feedline loss grows with length and usually with frequency.
- RG-58 is thin and higher-loss; RG-213 is thicker and usually lower-loss.
- Loss is expressed in decibels per unit length and depends on cable type and installation.
- SWR compares forward and reflected waves at the measurement point, and standing waves create voltage and current peaks along a mismatched line.
- A better match reflects less power, but low station-end SWR can be misleading when the feedline is lossy.
- Tuners and transformers transform impedance; they do not make feedline loss vanish.
- Matching near the antenna feed point can reduce loss in the main feedline.
