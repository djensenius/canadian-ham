---
type: lesson
id: L-008-01
moduleId: M8
categoryIds:
  - B-008
title:
  en: "Receiver and device interference, with filters"
  fr: null
covers:
  - B-008-001
  - B-008-002
  - B-008-005
objectives:
  - "Identify clues that point to receiver overload, desensitization, intermodulation, or audio rectification."
  - "Choose first-line receiver-side and device-side cures such as input filters, ferrite chokes, lead shortening, and common-mode chokes."
  - "Select low-pass, high-pass, band-pass, band-reject, and notch filter roles."
prerequisites:
  - L-003-01
  - L-003-05
  - L-004-01
  - L-005-05
estimatedMinutes: 45
quizIds:
  - QZ-L-008-01-A
status: draft
---
# Receiver and device interference, with filters

Interference work starts with diagnosis, not blame. A clean amateur signal can still upset a nearby receiver or audio device. The first skill is to decide whether the symptom points to an overloaded receiver, audio rectification in another device, or a noise path that needs filtering.

Common-mode current is unwanted RF flowing the same way on cable conductors, or on the outside of a coax shield. Differential-mode current flows out on one conductor and back on the other, in opposite directions. The wanted signal travels this way, but unwanted noise can travel this way too.

This lesson handles receiver-side and device-side problems. The next lesson handles transmitter-side faults that must be fixed before operating again.

## Learning objectives

By the end of this lesson, you can:

- identify clues that point to front-end overload or desensitization;
- explain why strong RF can become audible in ordinary audio equipment;
- choose first-line cures such as receiver filtering, ferrite chokes, lead shortening, and common-mode chokes;
- choose filter families by what they pass and what they reject; and
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

A filter must be placed where unwanted energy enters the device. If an FM or television receiver is overloaded by HF energy, a high-pass filter at that receiver input may keep the lower-frequency RF out while allowing the wanted VHF or UHF signal to pass. If a VHF receiver is upset by nearby services outside the desired band, a band-pass filter for the desired range may help.

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
- Correction: overmodulation is a real transmitter fault when a transmitter is driven beyond its clean modulation range. It is not the first diagnosis for audio rectification. The speaker lead or amplifier input may be detecting RF. Test lead length, ferrites, routing, and dummy-load operation before blaming modulation.

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

## Filter vocabulary

A filter is described by what it passes and what it attenuates.

| Filter type | Main action | Common interference use |
|---|---|---|
| Low-pass | Passes lower frequencies and attenuates higher frequencies | Keep higher-frequency RF noise out of equipment or reduce higher-frequency energy before a receiver input |
| High-pass | Passes higher frequencies and attenuates lower frequencies | Keep HF energy out of a VHF/UHF television or receiver input |
| Band-pass | Passes a selected range and attenuates frequencies above and below it | Protect a receiver at a multi-station event by admitting only its assigned band |
| Band-reject | Attenuates a range and passes frequencies outside that range | Remove a strong service or broadcast band while receiving on nearby lower and higher ranges |
| Notch | Attenuates one narrow frequency and passes most others | Reduce a single strong carrier close to the desired signal |

::figure filter-response-sketches
Alt text: Frequency-response sketches for low-pass, high-pass, band-pass, band-reject, and notch filters.
Text equivalent:
- Low-pass sketch: pass is on the left side of the graph and attenuation is on the right.
- High-pass sketch: attenuation is on the left side and pass is on the right.
- Band-pass sketch: pass is a raised middle band, with attenuation on both sides.
- Band-reject sketch: pass is on both sides, with a wide middle band attenuated.
- Notch sketch: pass is on both sides, with one narrow tone attenuated.
::

The cut-off frequency is the boundary region where a low-pass or high-pass filter changes from mostly passing to mostly attenuating. Real filters do not switch instantly; they transition over a range.

### Memory trick: pass names say what gets through

- Helps remember: low-pass, high-pass, and band-pass names describe the wanted frequencies that pass.
- Trick: read the name as a sentence: low-pass passes lows, high-pass passes highs, band-pass passes a band.
- Limit: the name does not tell you the cut-off frequency, power rating, impedance, or where to install it.

## Low-pass filters

A low-pass filter passes frequencies below its cut-off and attenuates frequencies above it. In an AC line filter for station equipment, the wanted power frequency is very low, so the filter should pass the power frequency while attenuating RF noise.

### Worked example: low-pass choice

A workshop receiver is meant to monitor a 4.2 MHz propagation beacon, but it sits beside a test rack with a 24 MHz clock oscillator. When the rack is on, the receiver front end overloads even though the wanted beacon is far lower in frequency.

A low-pass filter ahead of the receiver with a cut-off above 4.2 MHz and well below 24 MHz can pass the beacon while reducing the clock energy. Choose the cut-off so the desired signals are passed and the unwanted higher-frequency energy is reduced.

### In the real world: noisy LED lamp

A desk receiver hears a buzz whenever a nearby LED lamp is on. The buzz is strongest below 10 MHz and drops when the lamp is unplugged.

A ferrite on the lamp lead may reduce common-mode RF on the cord. A mains-rated AC line filter is a low-pass filter in this job: it passes power-line frequency and attenuates RF noise. If used, it belongs in the noisy lamp's power path or at the affected equipment's power input, according to the filter design. If the lamp itself is poorly designed or failing, replacing it may be safer and more effective than adding parts around it.

## High-pass filters

A high-pass filter passes frequencies above its cut-off and attenuates frequencies below it. If an HF station overloads a receiver meant for much higher frequencies, a high-pass filter at that receiver input may be the right first cure. It rejects lower-frequency amateur energy before the receiver front end is driven non-linear.

Do not put a high-pass filter in the HF transmitter line if the goal is to transmit HF. That would attenuate the wanted signal. Filter placement must match the symptom.

## Band-pass, band-reject, and notch filters

A band-pass filter admits a planned range and rejects energy outside that range. It is useful when several stations operate close together, such as a club exercise where each receiver should hear only its assigned band.

A band-reject filter, sometimes called a band-stop filter, rejects a wider range while passing frequencies below and above it. Use it when one strong band is the problem and you still need to hear on both sides of that range.

A notch filter is narrower. It is aimed at a single interfering frequency or a very small slice of spectrum. It can be effective against one steady carrier close to the desired signal, but it will not remove a whole band of strong signals.

### Worked example: choosing the range

A station wants to monitor 5.4 MHz and 7.8 MHz, but a very strong utility transmitter around 6.6 MHz overloads the receiver. A band-reject filter centred on the utility transmitter range is a better fit than a simple low-pass or high-pass filter, because the station wants to keep receiving on both sides of the unwanted signal.

If the problem were one narrow carrier at 6.61 MHz, a notch might be enough. If the problem were many transmitters across a wider allocation, a band-reject filter would be more realistic.

## Filter impedance and placement

A filter is part of the RF system. Its impedance should match the line or equipment where it is inserted. A serious mismatch can create reflections, loss, or misleading measurements. In common amateur coax systems, that often means using a filter designed for the same nominal impedance as the feedline and radio.

Placement matters as much as type:

- receiver overload filters belong before the receiver stage that overloads;
- ferrite chokes for common-mode cable pickup belong close to the affected device or at the point where common-mode current begins;
- AC line filters belong in the power lead of the equipment that needs noise reduction; and
- transmitter harmonic filters belong in the transmitter output path before the antenna system radiates the unwanted energy.

### In the real world: solar-inverter noise path

A station hears a rough buzz across several HF bands when a nearby solar inverter starts. The noise may leave on DC panel leads, AC power wiring, control cables, or the inverter case and bonding path.

The cure depends on the path. Common-mode ferrites on a cable can reduce RF current on that cable. A mains-rated filter belongs in the power path it is designed for. Internal repair or replacement belongs to qualified service people because inverter wiring can be hazardous.

## Symptom triage table

| Symptom | Likely cause to test first | First cure to try |
|---|---|---|
| Weak receiver loses signals near a strong off-channel transmitter | Front-end overload or desensitization | More separation or a suitable input filter |
| False signal appears only when two strong signals are present | Intermodulation in a non-linear junction or receiver front end | Find the mixing source and add a suitable receiver filter |
| Speaker, telephone, or intercom hears your audio without being tuned | Audio rectification in the affected device or lead | Shorten leads and add ferrites or a plug-in RFI filter at the device |
| One narrow steady carrier is close to the desired signal | A single-frequency interferer near the receiver passband | Consider a notch filter before the affected receiver stage |

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
4. A calibration receiver needs to hear a weak signal at 10.140 MHz, but one stable birdie sits 700 Hz away. Is a broad band-reject filter always the best first choice? No. A notch filter may be better for one narrow frequency because it removes less nearby spectrum.
5. A doorbell intercom lead passes close to a transmitting antenna. A ferrite clipped at the station desk changes nothing, but moving the same ferrite to the intercom end helps. Explain why location matters. The lead section after a choke can still pick up RF, so the choke usually belongs close to the affected device or entry point.

## Radio connection

Interference suppression uses circuit ideas from earlier modules. Inductors become chokes, capacitors become RF bypass paths, filters pass one range while rejecting another, and a non-linear device can mix or detect signals.

The practical difference is that the circuit may be inside a neighbour's speaker, a television input, your receiver front end, your solar-inverter wiring, or your station's own cable routing.

## Common mistakes

- Assuming that interference in a neighbour's device always proves your transmitter is dirty.
- Assuming that a clean transmitter means no station-side changes can help.
- Placing a filter after the receiver stage that is already overloaded.
- Treating ferrite chokes as decoration instead of placing them close to the affected equipment.
- Expecting a common-mode ferrite choke to fix every differential noise problem inside a power lead.
- Making speaker and accessory leads longer when they are already acting as antennas.
- Using a notch filter when an entire band of strong signals must be reduced.
- Ignoring filter impedance and creating a mismatch where the filter is inserted.
- Arguing with a neighbour before collecting repeatable observations.

## Illustration brief

Alt text: Frequency-response sketches for low-pass, high-pass, band-pass, band-reject, and notch filters.

Description: Draw five small graphs with frequency increasing left to right and response increasing upward. Show low-pass high on the left and low on the right, high-pass low on the left and high on the right, band-pass high only in the middle, band-reject low over a middle band, and notch as one narrow dip. Label pass and attenuate regions with text, not colour-only coding.

## Summary

- Strong signals can overload or desensitize a receiver even when the transmitter is not faulty.
- Intermodulation occurs when signals mix in a non-linear stage and create new frequency components.
- Audio rectification turns RF pickup into audible sound in equipment that was not intended to receive radio.
- Ferrite chokes in this lesson are common-mode cures; they do not fix every differential noise path.
- Low-pass, high-pass, band-pass, band-reject, and notch filters are named for what they pass or attenuate.
- A filter should match the system impedance and be placed before the stage or path where the unwanted energy causes trouble.
- Calm logs, scheduled tests, and reversible fixes make neighbour troubleshooting more effective.
