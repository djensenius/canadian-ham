---
type: lesson
id: L-008-01
moduleId: M8
categoryIds:
  - B-008
title:
  en: "Overload, rectification, and spurious signals"
  fr: null
covers:
  - B-008-001
  - B-008-002
  - B-008-003
objectives:
  - "Distinguish receiver overload from transmitter faults."
  - "Explain audio rectification in nearby equipment."
  - "Recognize intermodulation and spurious emission symptoms."
prerequisites: []
estimatedMinutes: 45
quizIds:
  - QZ-L-008-01-A
status: draft
---
# Overload, rectification, and spurious signals

Interference work starts with diagnosis, not blame. A signal can be perfectly legal and clean at the amateur station yet still upset a nearby receiver or audio device. A different case may point to a real transmitter problem that must be fixed before operating again. The skill is to separate those cases calmly.

This lesson covers three families of problems: strong-signal overload in receivers, audio rectification in household equipment, and unwanted signals produced by transmitting equipment or non-linear circuits.

## Learning objectives

By the end of this lesson, you can:

- identify clues that point to front-end overload or desensitization;
- explain why strong RF can become audible in ordinary audio equipment;
- choose first-line cures such as receiver filtering, ferrite chokes, lead shortening, and common-mode chokes;
- distinguish intermodulation, spurious emissions, parasitic oscillation, and key clicks; and
- use a neighbourly troubleshooting process that records evidence without escalating the situation.

## Troubleshooting mindset

Begin by asking what changed, where the interference is heard, and whether it follows your transmissions. Do not assume that every complaint proves a transmitter defect. Also do not assume the other device is automatically at fault. Treat the report as data.

Useful observations include:

- whether the problem occurs on every amateur band or only near certain frequencies;
- whether the affected device's volume control changes the interference level;
- whether the unwanted sound is distorted speech, clicking, a steady buzz, or normal audio from another station;
- whether reducing transmitter power changes the problem smoothly;
- whether moving, shortening, or adding ferrite to leads changes the symptom; and
- whether the same symptom is present when you transmit into a dummy load at low power.

A dummy-load test is especially helpful because it removes the antenna's radiated field from the test. Use only safe power and short transmissions, and avoid making tests that create new interference.

## Receiver overload and desensitization

A receiver front end is the input section before the later tuned and detector stages. It is designed for weak signals. A very strong nearby signal can drive it outside its normal range even when the nearby signal is not on the tuned frequency.

When the front end is overloaded, several things can happen:

- the desired signal seems to disappear because the receiver is desensitized;
- many parts of the dial appear to have the same interfering signal;
- two strong signals mix and produce a new signal on the frequency of interest; or
- changing the amateur transmitting band does not change the nature of the interference very much.

Desensitization means the receiver becomes less sensitive because a strong signal is using up the front end's headroom. Intermodulation means signals mix in a non-linear stage and create new sum-and-difference products. Both can be receiver-side effects.

### Worked example: overload clue

A club sets up two temporary stations at opposite ends of a park shelter. One station is receiving a weak beacon on a small VHF receiver. Each time the other station transmits nearby on a different VHF channel, the beacon disappears under a rushing sound.

The first station should not immediately accuse the transmitter of generating harmonics. The symptom follows a strong nearby signal and affects a weak desired signal. A practical first step is to add separation, reduce unnecessary gain, and try a suitable receive filter or attenuator at the affected receiver.

### Worked example: intermod clue

A handheld receiver connected to a roof antenna hears a paging-like buzz only at home. Two strong commercial transmitters are visible from the street. Disconnecting the roof antenna and using the rubber antenna makes the buzz vanish.

That points toward receiver intermodulation or overload. The cure is often a filter or attenuation at the receiver input, not a repair to the amateur transmitter.

## Filters at the affected receiver

A filter must be placed where the unwanted energy enters the device. If a television or broadcast receiver is being overloaded by HF energy, a filter at that receiver input may keep the low-frequency RF out while allowing the wanted VHF or UHF signal to pass. If a VHF receiver is upset by nearby services outside the desired band, a band-pass filter for the desired range may help.

An attenuator can also reduce overload, but it reduces wanted signals too. A narrow intermediate-frequency filter may improve selectivity after the front end, but it cannot fix a front end that is already being driven non-linear. Put the cure before the stage that is being overloaded.

## Audio rectification

Audio rectification happens when RF is picked up by wiring and detected by a non-linear junction in equipment that was never meant to be a radio. Oxidized connectors, semiconductor input circuits, powered-speaker amplifiers, telephone accessories, intercoms, and computer speakers can all behave like crude detectors when enough RF is present.

The clues are different from ordinary receiver tuning:

- the sound may be present even when the device is not tuned to a radio station;
- the volume control may not change the interference because detection occurs after or outside the normal volume control path;
- SSB may sound like muffled or distorted speech; and
- CW may sound like clicks, buzzes, or on-and-off hum because the carrier is keyed.

### Ferrite chokes

A ferrite choke adds impedance to RF current on a lead while leaving the intended audio, power, or control signal mostly unchanged. Several turns through a suitable ferrite core increase the choking effect. Put the ferrite close to the affected device so the lead cannot act as an antenna after the choke.

Ferrites are common cures for speaker leads, intercom wiring, telephone cords, computer audio cables, and power leads that bring RF into a box. Shortening excessive lead length also helps because a shorter wire is usually a less efficient pickup antenna.

### Bypass capacitors

A bypass capacitor gives unwanted RF a low-impedance path to the equipment chassis or circuit common while blocking direct current. In interference suppression, a small capacitor is often placed at an input or across a noisy contact so RF is shunted before it reaches a sensitive stage.

Use parts and installation methods appropriate to the circuit voltage, safety requirements, and equipment design. Do not modify someone else's equipment internally unless you are qualified and have permission. Many practical cures are external plug-in filters, snap-on ferrites, cable routing changes, and station-side common-mode control.

### Worked example: powered-speaker pickup

A station uses a balanced antenna tuner and a short indoor lead to a small loop. During voice transmissions, a set of computer speakers across the room produces garbled speech even with the speaker volume turned down. The speaker cable is a long coil behind the desk.

Good first steps are to uncoil and shorten the speaker lead, add ferrite turns near the powered speaker input, and check the station feedline for common-mode current. If the problem changes when a common-mode choke is added at the station feed point, the station's RF-current path was part of the coupling.

## Common-mode current and station cures

Common-mode current is RF flowing in the same direction on the outside of a coax shield or on both conductors of a cable together. It can make feedlines, microphone leads, power leads, and speaker cables act as unwanted antennas.

A common-mode choke on the transmission line can reduce RF on the outside of the feedline. This is especially useful with unbalanced or off-centre-fed antennas where the feedline can become part of the radiating system. Good station bonding, a sensible feedline route, and keeping audio and control cables away from the antenna field also reduce pickup.

## Spurious emissions

A spurious emission is unwanted radio energy outside the intended signal. It may come from poor shielding, faulty stages, unwanted mixing, overdriven circuits, or oscillation inside equipment. Unlike receiver overload, this is a transmitter or transmitter-accessory problem and must be corrected.

A clean transmitter has filtering, shielding, and stages adjusted so the wanted signal dominates and unwanted outputs are suppressed. Operating a piece of equipment with covers or shields removed can change grounding and shielding enough to let unwanted energy radiate.

## Key clicks and waveform shape

In Morse transmission, the carrier should rise and fall smoothly enough that the signal occupies a reasonable bandwidth. If the carrier turns on and off too abruptly, the sharp edges contain extra side energy. Distant receivers hear this as clicks near the signal.

Key clicks are not fixed by sending slower with the same harsh waveform. The transmitter's keying waveform, keying filter, and later RF stages need attention. The idea is to shape the rise and decay times, not to hide the problem.

### Worked example: sharp keying

A home-built CW transmitter sounds strong at the station monitor, but a friend several kilometres away reports clicking above and below the signal. The sidetone in the shack sounds normal.

The monitor tone only proves that the operator can hear keying locally. The reported wide clicking points to a transmitter waveform problem. Inspect the keying-shape network, amplifier biasing during keying, and any stages that are being driven abruptly.

## Parasitic oscillation

A parasitic problem occurs when a stage starts generating extra RF on its own instead of doing only its intended job. The usual trigger is unintended positive feedback through stray capacitance, lead inductance, layout, or poor neutralization. The extra frequency may sit above or below the intended operating frequency and does not have to be an exact harmonic.

Symptoms can include unstable output, unusual current, reports of interference away from the operating frequency, or trouble that appears only with a particular load or power level. Because parasitics can damage equipment and radiate unwanted energy, stop transmitting until the cause is found.

## Neighbourly troubleshooting etiquette

Most interference problems are solved faster when people feel heard. The technical work is important, but so is the conversation.

A good approach is:

1. Thank the person for reporting the symptom.
2. Ask for dates, times, affected devices, and what they heard or saw.
3. Offer short, scheduled tests rather than surprise transmissions.
4. Keep your tests brief and log power, band, antenna, and results.
5. Start with reversible, low-risk fixes such as ferrites, lead routing, and receiver filters.
6. Avoid opening or modifying another person's equipment unless it is your equipment, you are qualified, and permission is clear.
7. If your station is producing spurious emissions, stop using that setup until it is repaired.

## Try it

1. Question: A neighbour's powered speakers produce distorted voice even when their volume control is set low. What does that clue suggest? Answer: It suggests RF is being detected outside the normal audio path, so audio rectification and RF pickup on leads should be investigated.
2. Question: A weak desired VHF signal vanishes only when a nearby transmitter keys up, but the nearby transmitter is not on the desired frequency. What receiver-side problem fits? Answer: Front-end overload or desensitization fits because the strong signal is reducing receiver sensitivity.
3. Question: Two strong local signals create a third unwanted signal in a handheld receiver with a large outside antenna. What cure is worth trying at the receiver input? Answer: A suitable filter or attenuation before the overloaded stage can reduce the strong off-channel energy.
4. Question: A CW signal is reported to click on nearby frequencies. Should the operator simply send more slowly? Answer: No. The keying waveform and transmitter stages should be checked because abrupt rise and fall times create broad key clicks.
5. Question: An off-centre-fed antenna makes shack audio equipment noisy on transmit. What station-side part may help on the feedline? Answer: A common-mode choke can reduce RF current flowing on the outside of the feedline.

## Radio connection

Interference suppression uses the same circuit ideas from earlier modules. Inductors become chokes, capacitors become RF bypass paths, filters pass one range while rejecting another, and a non-linear device can mix or detect signals. The practical difference is that the circuit may be inside a neighbour's speaker, a television input, your receiver front end, or your transmitter power amplifier.

## Common mistakes

- Assuming that interference in a neighbour's device always proves your transmitter is dirty.
- Assuming that a clean transmitter means no station-side changes can help.
- Placing a filter after the receiver stage that is already overloaded.
- Treating ferrite chokes as decoration instead of placing them close to the affected equipment.
- Making speaker and accessory leads longer when they are already acting as antennas.
- Ignoring key clicks because the local sidetone sounds normal.
- Continuing to transmit after credible evidence of spurious emissions from your station.
- Arguing with a neighbour before collecting repeatable observations.

## Illustration brief

Alt text: A troubleshooting map that separates receiver overload, audio rectification, and transmitter spurious emissions.

Description: Draw three columns. The first column shows a receiver input with a large off-channel arrow crowding a small wanted arrow, labelled "front-end overload." The second shows a speaker lead acting as an antenna feeding a small diode symbol, labelled "audio rectification." The third shows a transmitter with one wanted output arrow and smaller unwanted arrows, labelled "spurious outputs." Use simple line art and text labels rather than colour-only coding.

## Summary

- Strong signals can overload or desensitize a receiver even when the transmitter is not faulty.
- Intermodulation occurs when signals mix in a non-linear stage and create new frequency components.
- Audio rectification turns RF pickup into audible sound in equipment that was not intended to receive radio.
- Ferrite chokes, lead shortening, bypass capacitors, receiver filters, and common-mode chokes are common suppression tools.
- Spurious emissions, key clicks, and parasitic oscillations point to transmitter or equipment problems that must be corrected.
- Calm logs, scheduled tests, and reversible fixes make neighbour troubleshooting more effective.
