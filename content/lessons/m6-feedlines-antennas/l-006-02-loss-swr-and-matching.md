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

A feedline is never perfect. Some RF energy becomes heat before it reaches the antenna, and any mismatch can send some energy back toward the transmitter. The goal is not to chase magic numbers. The goal is to understand what the readings mean and put the matching where it reduces real loss.

## Learning objectives

By the end of this lesson, you can:

- explain why feedline loss increases with length and frequency;
- recognize how cable type affects radiated power;
- interpret an SWR meter without treating it as an antenna-efficiency meter;
- explain why line loss can hide a mismatch at the station end; and
- describe what tuners, transformers, and matching networks do.

## Feedline loss

Feedline loss is commonly stated in decibels per unit length, such as dB per 100 m or dB per 30 m. A longer run has more total loss because the signal spends more distance in lossy conductors and dielectric. Higher frequencies usually have more loss in the same cable because RF current is concentrated near conductor surfaces and dielectric losses rise.

Small coax that works acceptably for a short HF jumper may waste a lot of power on UHF. Larger or lower-loss coax has less attenuation, but it costs more and is less flexible. Balanced open-wire line can have very low loss when it is installed well.

### Worked example: doubling cable length

A certain coax has 0.7 dB of loss over a 14 m run at a chosen frequency. If the same cable and frequency are used over 28 m, the loss is about 1.4 dB. The length doubled, so the loss in dB doubled.

This does not mean the characteristic impedance changed. It means more distance caused more attenuation.

### Worked example: trimming excess cable

A temporary antenna is only 11 m from the operating table, but a 33 m coil of small coax is being used because it was already assembled. Replacing it with a 12 m run removes most of the unnecessary loss. Coiling the spare cable neatly does not make the extra attenuation disappear.

## SWR in plain language

SWR stands for standing wave ratio. It compares the forward and reflected RF voltage waves on a transmission line. An SWR near 1:1 means the line and load are closely matched at the measurement point. A higher reading means more energy is being reflected because the load impedance is not the same as the line's characteristic impedance.

A low reading is useful, but it is not a complete proof that the antenna system is efficient. A lossy feedline can attenuate the reflected wave before it returns to the meter. The station-end meter can therefore look better than the antenna-end mismatch really is.

### Worked example: line loss masks trouble

Station A and Station B show similarly low SWR at the transmitter. Station A uses a short, low-loss feedline. Station B uses a long, old run that is warm after transmitting. The same meter reading does not mean the antennas are performing the same. In the lossy system, less reflected energy returns to the meter, and less forward energy reaches the antenna.

## Faults that change readings

Erratic SWR readings often point to intermittent connections: loose connectors, water in a joint, cracked solder, or a broken conductor that moves in the wind. A very high reading can come from an open circuit, a short circuit, the wrong antenna, or a badly mismatched antenna.

An antenna analyzer is useful because it can sweep or sample a range of frequencies at low power. It helps you find where the antenna system is closest to resonance and whether adjusting element length moves the dip in the expected direction.

## Matching networks and tuners

An antenna tuner does not tune the air. It transforms impedance so the transceiver sees a load it can safely drive. Many solid-state transmitters reduce power when the load at the radio is too far from the expected range. A tuner can help the transmitter deliver power into a mismatched antenna system.

A tuner near the transceiver protects the radio, but it does not remove loss in a feedline that is carrying high SWR. A tuner or matching transformer near the antenna feed point can reduce the mismatch on the main feedline and therefore reduce feedline loss.

Matching can be done with inductors, capacitors, transmission-line sections, or transformers. If source and load are purely resistive, maximum power transfer happens when their impedances are equal. When the load is not equal, the matching network changes the impedance presented to the source.

### Worked example: impedance ratio

A folded antenna feed point is near 240 ohms and the station uses 60-ohm test cable in a workshop experiment. The transformation ratio needed is:

- ratio = load impedance / line impedance;
- ratio = 240 / 60;
- ratio = 4.

A 4:1 impedance transformer would be the first idea to investigate for that simplified resistive case.

## Try it

1. A 22 m feedline run is replaced with an 11 m run of the same coax at the same frequency. What happens to dB loss? It is cut roughly in half because loss in dB accumulates with length.
2. A meter reading jumps when the feedline is moved. What should you inspect before trimming the antenna? Check connectors and conductor continuity, because intermittent feedline faults can imitate antenna changes.
3. A tuner at the desk gives the transmitter a comfortable load, but the feedline is still hot. Where might matching help more? Matching closer to the antenna can reduce high-SWR loss on the main feedline.
4. A short VHF jumper uses thin coax. Why might the same cable be poor as a long roof run? At VHF and UHF, thin coax loss rises with frequency and becomes important over longer distances.
5. A low SWR reading appears at the radio. What other evidence should you consider? Cable type, cable length, and antenna behaviour still matter because a lossy line can hide reflected power.

## Radio connection

Modern transceivers protect their output stages. If the load looks unsafe, the radio may reduce power automatically. That is not a failure; it is protection. Your job is to find whether the issue is the antenna, the feedline, a connector, a missing matching device, or simply trying to use an antenna far from the frequency range where it works well.

## Common mistakes

- Believing that an SWR meter directly measures antenna gain or radiation pattern.
- Thinking a tuner at the radio removes all feedline loss.
- Leaving a long coil of unused small coax in the system and blaming the antenna for weak signals.
- Ignoring intermittent connectors because the antenna looked fine yesterday.
- Assuming that high SWR stops all radiation; usually it reduces transfer and increases losses, but some power may still radiate.

## Illustration brief

Alt text: A station-end SWR meter, tuner, long feedline, and antenna, with reflected-wave arrows fading as they return through a lossy line.

Description: Draw the transceiver, SWR meter, tuner, feedline, and antenna as separate ink-brush blocks. Show a forward arrow moving to the antenna and a reflected arrow returning. Make the reflected arrow smaller after passing through a labelled "lossy line" section. Add a second small diagram with a tuner at the antenna feed point to show lower mismatch on the main feedline.

## Summary

- Feedline loss grows with length and usually with frequency.
- Loss is expressed in decibels per unit length and depends on cable type and installation.
- SWR compares forward and reflected waves at the measurement point.
- Low station-end SWR can be misleading when the feedline is lossy.
- Tuners and transformers transform impedance; they do not make feedline loss vanish.
- Matching near the antenna feed point can reduce loss in the main feedline.
