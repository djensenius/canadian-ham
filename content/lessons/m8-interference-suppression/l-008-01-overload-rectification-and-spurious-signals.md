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

Interference work starts with diagnosis, not blame. A clean amateur signal can still upset a nearby receiver or audio device. A different case may point to a real transmitter problem that must be fixed before operating again.

The skill is to separate those cases calmly. This lesson covers strong-signal overload, audio rectification in household equipment, unwanted signals from transmitting equipment, and common first cures.

Common-mode current is unwanted RF flowing the same way on cable conductors, or on the outside of a coax shield. Differential current is the intended out-and-back current inside a circuit or cable pair.

## Learning objectives

By the end of this lesson, you can:

- identify clues that point to front-end overload or desensitization;
- explain why strong RF can become audible in ordinary audio equipment;
- choose first-line cures such as receiver filtering, ferrite chokes, lead shortening, and common-mode chokes;
- distinguish intermodulation, spurious emissions, parasitic oscillation, and key clicks; and
- use a neighbourly troubleshooting process that records evidence without escalating the situation.

## Troubleshooting mindset

Begin by asking what changed, where the interference is heard, and whether it follows your transmissions. Do not assume that every complaint proves a transmitter defect. Also do not assume the other device is automatically at fault.

Useful observations include:

- whether the problem occurs on every amateur band or only near certain frequencies;
- whether the affected device's volume control changes the interference level;
- whether the unwanted sound is distorted speech, clicking, a steady buzz, or normal audio from another station;
- whether reducing transmitter power changes the problem smoothly;
- whether moving, shortening, or adding ferrite to leads changes the symptom; and
- whether the same symptom is present when you transmit into a dummy load at low power.

A dummy-load test is helpful because it removes the antenna's radiated field from the test. Use safe power and short transmissions. Do not make tests that create new interference.

### In the real world: chargers, LED bulbs, and solar inverters

Not every noise source is an amateur transmitter. Switch-mode phone chargers, LED bulbs, computer supplies, and solar inverters can make RF noise when their internal switching circuits or wiring radiate energy.

A practical first step is to change one thing at a time. Unplug the charger, turn off the lamp, or shut down the inverter if it is safe and permitted. If the noise vanishes, you have found a likely source to filter, replace, repair, or move.

## Receiver overload and desensitization

A receiver front end is the input section that first selects and amplifies signals before later stages do more filtering and detection. It is designed for weak signals. A very strong nearby signal can drive it outside its normal range even when that signal is not on the tuned frequency.

When the front end is overloaded, several things can happen:

- the desired signal seems to disappear because the receiver is desensitized;
- many tuned frequencies may show overload symptoms, especially when a strong off-channel signal is present;
- two strong signals mix and produce a new signal on the frequency of interest; or
- changing the amateur transmitting band does not change the nature of the interference very much.

Desensitization means the receiver becomes less sensitive because a strong signal uses up the front end's headroom, or margin before overload. Intermodulation means signals mix in a non-linear stage and create new sum-and-difference products. The non-linear stage can be inside the receiver, or it can be an external junction such as corroded metalwork, a poor connection, or equipment near a transmitter site.

A small handheld receiver can behave differently after it is connected to a rooftop or mast antenna. The better antenna may deliver several strong off-channel signals to a broad front end, so the receiver creates a false mix on the channel you wanted to hear.

Simple intermodulation checks use sums and differences. Two signals at frequencies f1 and f2 can create products such as f1 + f2, |f1 - f2|, 2 x f1 - f2, or 2 x f2 - f1. For example, a 104.3 MHz FM broadcast signal and an 18.1 MHz HF signal can mix to 104.3 - 18.1 = 86.2 MHz, inside a VHF receiver's tuning range. The arithmetic suggests what to test; it does not prove which device is non-linear.

### Worked example: overload clue

A club sets up two temporary stations at opposite ends of a park shelter. One station is receiving a weak beacon on a small VHF receiver. Each time the other station transmits nearby on a different VHF channel, the beacon disappears under a rushing sound.

The first station should not immediately accuse the transmitter of generating harmonics. The symptom follows a strong nearby signal and affects a weak desired signal. Add separation, reduce unnecessary gain, and try a suitable receive filter at the affected receiver. Use attenuation only as a fallback, because it weakens the wanted signal too.

### Worked example: intermod clue

At a sailing-club event, a VHF receiver monitors a weak safety channel on 156.8 MHz. It hears a false tone only when two nearby service transmitters are active. One transmitter is at 151.4 MHz, and the other is at 154.1 MHz.

- Given: f1 = 151.4 MHz; f2 = 154.1 MHz; monitored frequency = 156.8 MHz.
- Find: whether a third-order product could land on the monitored frequency.
- Formula: product = 2 x f2 - f1.
- Substitute: product = 2 x 154.1 - 151.4.
- Answer: product = 156.8 MHz.
- Sanity check: the number matches the false signal, so receiver intermodulation is plausible.

The cure is often more separation, less unnecessary gain, or a suitable filter at the receiver input. An RF attenuator can be a fallback test, but it also reduces the wanted signal. This is not a repair to the monitored channel or to every nearby transmitter.

## Filters at the affected receiver

A filter must be placed where unwanted energy enters the device. If an FM or television receiver is overloaded by HF energy, a high-pass filter at that receiver input may keep the lower-frequency RF out while allowing the wanted VHF or UHF signal to pass. If a VHF receiver is upset by nearby services outside the desired band, a band-pass filter for the desired range may help. The next lesson gives the full filter vocabulary.

An attenuator can also reduce overload, but it reduces wanted signals too. Treat the suitable input filter as the first cure when the unwanted frequency can be separated from the wanted one. A narrow intermediate-frequency filter may improve selectivity after the front end, but it cannot fix a front end that is already being driven non-linear. Put the cure before the overloaded stage.

## Audio rectification

Audio rectification happens when RF is picked up by wiring and detected by a non-linear junction in equipment that was never meant to be a radio. Oxidized connectors, semiconductor input circuits, powered-speaker amplifiers, telephone accessories, intercoms, and computer speakers can all behave like crude detectors when enough RF is present.

The clues are different from ordinary receiver tuning:

- the sound may be present even when the device is not tuned to a radio station;
- a broadcast receiver or audio device may seem to hear the amateur transmission across the entire dial because RF is detected after it enters;
- the volume control may not change the interference because detection occurs after or outside the normal volume-control path;
- SSB may sound like muffled or distorted speech; and
- CW may sound like clicks, buzzes, or on-and-off hum because the carrier is keyed.

If clean amateur transmissions are being detected by a telephone set or accessory, use an external telephone RFI filter at the phone end of the line. Keep the cure reversible unless a qualified person has permission to work inside equipment.

### In the real world: powered-speaker pickup

A temporary classroom station uses a compact end-fed antenna outside a window. During voice transmissions, powered computer speakers on the table produce raspy syllables. The symptom is strongest when a spare 3 m audio extension is plugged in. It nearly disappears when that extension is removed.

Good first steps are to keep the audio lead short, route it away from the antenna lead, and add ferrite turns close to the powered-speaker input. Shorter leads usually make poorer pickup antennas. If a common-mode choke at the feedline entry point changes the symptom, the station's RF-current path was part of the coupling.

### Misconception: every speaker complaint means dirty transmit audio

- Mistaken idea: if a speaker makes distorted words, the transmitter must be overmodulated.
- Correction: overmodulation is real when a transmitter is driven beyond its clean modulation range, but it is not the first diagnosis for audio rectification. The speaker lead or amplifier input may be detecting RF. Test lead length, ferrites, routing, and dummy-load operation before blaming modulation.

## Ferrite chokes and bypass capacitors

In this lesson, a ferrite choke means the whole cable passes through or around ferrite. The ferrite adds high RF impedance to common-mode current. Part of that impedance is inductive reactance, and part is resistive loss that turns the unwanted RF into a little heat. The wanted audio, DC, or data current usually flows out and back as a differential current, so the ferrite leaves it mostly unchanged.

Ferrite chokes are standard cures when RF rides into equipment on speaker leads, intercom wiring, telephone cords, computer audio cables, and power leads. Shortening extra lead length also helps, because a shorter wire is a poorer pickup antenna.

That limit matters. A snap-on ferrite is not a cure for every noisy charger, LED driver, or solar inverter. If the unwanted energy is differential noise inside the power leads, a proper line filter, better supply, repair, or equipment replacement may be needed.

Several turns through a suitable ferrite core increase the choking effect. Put the ferrite close to the affected device so the lead cannot act as an antenna after the choke.

A bypass capacitor gives unwanted RF a low-impedance path to the equipment chassis or circuit common, the shared return point for that circuit, while blocking direct current. In interference suppression, a small capacitor is often placed at an input or across a noisy contact so RF is shunted before it reaches a sensitive stage.

Use parts and installation methods appropriate to the voltage, safety rules, and equipment design. Do not modify someone else's equipment internally unless you are qualified and have permission. Many practical cures are external plug-in filters, snap-on ferrites, cable routing changes, and station-side common-mode control.

## Common-mode current and station cures

Common-mode current can make feedlines, microphone leads, power leads, and speaker cables act as unwanted antennas. A common-mode choke on the transmission line can reduce RF on the outside of the feedline. This is especially useful with unbalanced or off-centre-fed antennas where the feedline can become part of the radiating system.

Good station bonding, a sensible feedline route, and keeping audio and control cables away from the antenna field also reduce pickup.

## Spurious emissions

Out-of-band emission is unwanted energy just outside the necessary bandwidth that comes from the modulation process, such as splatter or key clicks. Spurious emissions are other unwanted transmitter outputs outside the necessary bandwidth. They can appear near or far from the signal, and include harmonics, parasitic oscillations, and mixing products.

A spurious emission may come from poor shielding, faulty stages, unwanted mixing, overdriven circuits, or oscillation inside equipment. Unlike receiver overload, this is a transmitter or transmitter-accessory problem and must be corrected.

A clean transmitter has filtering, shielding, and stages adjusted so the wanted signal dominates and unwanted outputs are suppressed. Operating equipment with covers or shields removed can change grounding and shielding enough to let unwanted energy radiate.

## Key clicks and waveform shape

In Morse transmission, the carrier should rise and fall smoothly enough that the signal occupies a reasonable bandwidth. If the carrier turns on and off too abruptly, the sharp edges contain extra side energy. Distant receivers hear this as clicks near the signal.

There are two related clues. Local RF interference from key clicks can come from the making and breaking of the key circuit itself. Key clicks heard at a distant receiver usually point to rise and decay times of the transmitted carrier that are too sharp.

Key clicks are not fixed by sending slower with the same harsh waveform. The transmitter's keying waveform, keying filter, and later RF stages need attention. The goal is to shape the rise and decay times, not to hide the problem.

### Worked example: sharp keying

A home-built CW transmitter sounds strong at the station monitor, but a friend several kilometres away reports clicking above and below the signal. The sidetone in the shack sounds normal.

The monitor tone only proves that the operator can hear keying locally. The wide clicking report points to a transmitter waveform problem. Inspect the keying-shape network, amplifier bias during keying, and any stages that are being driven abruptly.

## Parasitic oscillation

A parasitic problem occurs when a stage starts generating extra RF on its own instead of doing only its intended job. The usual trigger is unintended positive feedback through stray capacitance, lead inductance, layout, or poor neutralization. Neutralization means cancelling unwanted feedback in an amplifier stage. The extra frequency may sit above or below the intended operating frequency and does not have to be an exact harmonic.

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

1. A doorbell intercom is quiet when its 18 m button cable is unplugged and noisy again when the cable is reconnected. Explain why shortening that run or adding ferrite near the intercom box is a sensible first test. The long cable can pick up RF and deliver it to a non-linear input, so reducing RF current at the affected device tests the pickup path directly.
2. A sensitive receiver loses weak signals whenever a nearby test transmitter runs 100 W, but the symptom is much less severe at 10 W. What does that power-change trend suggest? A smooth improvement as the strong signal is reduced supports overload or desensitization rather than a fixed-frequency transmitter defect.
3. Two strong site transmitters at 151.2 MHz and 153.8 MHz are present when a scanner hears a false signal at 156.4 MHz. Compute a possible third-order product and name a practical first test. 2 x 153.8 - 151.2 = 156.4 MHz, so try a suitable front-end filter ahead of the scanner first. Modest attenuation is only a fallback because it weakens wanted signals too.
4. A CW exciter change reduces the RF-envelope rise time from about 6 ms to less than 1 ms, and a monitor several kilohertz away hears ticks. Why is simply sending slower not a cure? The problem is the abrupt edge of each keyed carrier element, so the keying-shape network and following RF stages need correction before on-air use.
5. A doorbell intercom lead passes close to a transmitting antenna. A ferrite clipped at the station desk changes nothing, but moving the same ferrite to the intercom end helps. Explain why location matters. The lead section after a choke can still pick up RF, so the choke usually belongs close to the affected device or entry point.

## Symptom triage table

| Symptom | Likely cause to test first | First cure to try |
|---|---|---|
| Weak receiver loses signals near a strong off-channel transmitter | Front-end overload or desensitization | More separation or a suitable input filter |
| False signal appears only when two strong signals are present | Intermodulation in a non-linear junction or receiver front end | Find the mixing source and add a suitable receiver filter |
| Speaker, telephone, or intercom hears your audio without being tuned | Audio rectification in the affected device or lead | Shorten leads and add ferrites or a plug-in RFI filter at the device |
| Extra transmitted signals appear outside the necessary bandwidth and are not modulation splatter | Spurious emissions from transmitting equipment | Stop using that setup until filtering, shielding, drive, or repair fixes it |

## Radio connection

Interference suppression uses circuit ideas from earlier modules. Inductors become chokes, capacitors become RF bypass paths, filters pass one range while rejecting another, and a non-linear device can mix or detect signals.

The practical difference is that the circuit may be inside a neighbour's speaker, a television input, your receiver front end, your solar-inverter wiring, or your transmitter power amplifier.

## Common mistakes

- Assuming that interference in a neighbour's device always proves your transmitter is dirty.
- Assuming that a clean transmitter means no station-side changes can help.
- Placing a filter after the receiver stage that is already overloaded.
- Treating ferrite chokes as decoration instead of placing them close to the affected equipment.
- Expecting a common-mode ferrite choke to fix every differential noise problem inside a power lead.
- Making speaker and accessory leads longer when they are already acting as antennas.
- Ignoring key clicks because the local sidetone sounds normal.
- Continuing to transmit after credible evidence of spurious emissions from your station.
- Arguing with a neighbour before collecting repeatable observations.

## Illustration brief

Alt text: A troubleshooting map that separates receiver overload, audio rectification, and transmitter spurious emissions.

Description: Draw three columns. The first column shows a receiver input with a large off-channel arrow crowding a small wanted arrow, labelled "front-end overload." The second shows a speaker lead acting as an antenna feeding a small diode symbol, labelled "audio rectification." The third shows a transmitter with one wanted output arrow and smaller unwanted arrows, labelled "spurious outputs." Use simple line art and text labels rather than colour-only coding.

## Summary

- Strong signals can overload or desensitize a receiver even when the transmitter is not faulty.
- Chargers, LED bulbs, computer supplies, and solar inverters can be everyday RF-noise sources.
- Intermodulation occurs when signals mix in a non-linear stage and create new frequency components.
- Audio rectification turns RF pickup into audible sound in equipment that was not intended to receive radio.
- Ferrite chokes in this lesson are common-mode cures; they do not fix every differential noise path.
- Lead shortening, bypass capacitors, receiver filters, and common-mode chokes are common suppression tools.
- Spurious emissions, key clicks, and parasitic oscillations point to transmitter or equipment problems that must be corrected.
- Calm logs, scheduled tests, and reversible fixes make neighbour troubleshooting more effective.
