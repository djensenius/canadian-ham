---
type: lesson
id: L-001-04
moduleId: M1
categoryIds:
  - B-001
title:
  en: "Privileges, bandwidth, power, and repeaters"
  fr: null
covers:
  - B-001-015
  - B-001-016
  - B-001-017
  - B-001-018
  - B-001-019
objectives:
  - "Match operator qualifications to frequency and station privileges."
  - "Respect bandwidth and power limits by band and mode."
  - "Recognize repeater, automatic, stability, and modulation-quality requirements."
prerequisites:
  - L-001-03
estimatedMinutes: 45
quizIds:
  - QZ-L-001-04-A
status: draft
---
# Privileges, bandwidth, power, and repeaters

Privileges are the practical edge of the certificate. They answer questions such as who may control the station, which bands are available, how wide the signal may be, how much power may be used, and what signal-quality controls the station must have.

This lesson stays inside the official question-bank facts and the project exam-facts notes for RBR-4 power values. Where a number appears, treat it as a memory target from those sources, not as a place to invent nearby alternatives.

## Learning objectives

By the end of this lesson, you can:

- explain why station privileges do not expand just because another operator or station has extra qualifications;
- identify the extra gate for amateur frequencies below 30 MHz;
- recognize the HF band ranges named in the bank;
- choose bandwidth limits and avoid band-edge overflow;
- apply Basic and Advanced power limits using the correct power quantity; and
- describe repeater, automatic-transmission, frequency-stability, and modulation-quality requirements.

## Control operator and station privileges

The controlling qualification matters. Extra certificates do not rub off from the person beside you, from the owner of the equipment, or from the label on the amplifier. Before transmitting, ask which certificate and call sign are actually governing this operation.

The beginner-safe rule is simple: operate inside the privileges that apply to the current control situation. If that check feels unclear, stop and sort out the control operator and call sign before RF leaves the station.

### Worked example: club station handoff

A club has a station with an amplifier and several antennas. A Basic-only operator takes the microphone while an Advanced operator sits nearby. The safe privilege check is still the Basic operator's certificate and the call sign being used. The station's hardware does not upgrade the operator.

## The below-30-MHz gate

The bank and exam-facts record establish a specific extra gate for amateur frequencies below 30 MHz. In addition to passing the Basic written examination, an operator must have a Basic mark of 80% or more, or pass an Advanced or Morse code examination, before using those frequencies.

Basic qualification by itself supports all amateur bands above 30 MHz. The bank also establishes that radio-controlled models may be operated on all amateur bands above 30 MHz.

## HF band ranges named in the bank

The official bank asks for several Canadian HF band ranges. Learn them as ranges, not as vague band names:

| Band name | Range established by the bank |
|---|---|
| 160 metres | 1.8 MHz to 2.0 MHz |
| 80 metres | 3.5 MHz to 4.0 MHz |
| 40 metres | 7.0 MHz to 7.3 MHz |
| 20 metres | 14.000 MHz to 14.350 MHz |
| 15 metres | 21.000 MHz to 21.450 MHz |
| 10 metres | 28.000 MHz to 29.700 MHz |

### Worked example: privilege before band choice

An operator with Basic only wants to join a voice net below the VHF range. The first planning question is not antenna length or microphone gain. It is whether the operator has the required below-30-MHz authorization. If not, choose an above-30-MHz amateur path that fits the operator's certificate.

## Bandwidth limits and band edges

Bandwidth limits control how much spectrum one transmission occupies.

### Bandwidth fact table

| Frequency range or band | Maximum bandwidth fact from the bank |
|---|---|
| 50 MHz to 54 MHz and 144 MHz to 148 MHz | 30 kHz |
| 28 MHz to 29.7 MHz | 20 kHz |
| Amateur bands between 7 MHz and 25 MHz, except the special narrow band named below | 6 kHz |
| 10.100 MHz to 10.150 MHz | less than 6 kHz; single sideband is prohibited |

### Band-edge and mode planning

When transmitting near a band edge, leave enough room for the whole signal shape. Do not place only the carrier or display frequency inside the edge and let sidebands or occupied data energy spill outside.

The bank gives examples of mode-and-frequency combinations that do not fit their limits. The lesson principle is broader: check both the frequency and the occupied bandwidth before transmitting.

### Worked example: planning a digital signal near an edge

A narrow data signal is planned near a band boundary. The operator leaves guard space so the whole occupied signal remains inside the band, then verifies the emission setting before transmitting. Moving closer to the edge might look tidy on the frequency display, but the occupied signal, not just the displayed number, must fit.

## Power quantities and limits

Use the minimum legal power necessary to communicate. After you choose a power that also satisfies RF-exposure and radiated-power constraints, check the RF output point of the transmitter or external amplifier rather than a later point in the antenna system.

### Power limit fact table

| Qualification context | Limit established for this lesson |
|---|---|
| Basic, DC input to the final RF stage | 250 W |
| Basic, single-sideband peak envelope power | 560 W PEP |
| Basic, emissions other than SSB when the operator does not hold Advanced | 190 W carrier power |
| Advanced, DC input to the final RF stage | 1000 W |
| Advanced, single-sideband peak envelope power | 2250 W PEP |
| Advanced on 60 metres | 100 W ERP expressed as PEP |
| 630 metres and 2200 metres | account for antenna gain because limits are expressed as EIRP |

The important study habit is to keep the power quantity attached to the rule. DC input, carrier power, PEP, ERP, and EIRP are not interchangeable labels.

### Worked example: choosing the measurement point

A station has a transceiver, then an external amplifier, then a tuner. For the regulatory transmitter-power check taught here, the operator reads the RF power before the tuner and feedline can change the number with losses or matching effects.

## Repeaters and automatic transmissions

A repeater station listens to one station and retransmits what it hears for other stations. The bank establishes that holders of only a Basic Qualification may use repeaters with output at 29.500 MHz and above, with the lowest named output segment being 29.500 MHz to 29.700 MHz.

An unmodulated carrier is a narrow testing tool, not a way to reserve a channel. The bank limits that kind of carrier to brief tests below the 30 MHz boundary.

## Frequency stability and modulation quality

Canadian regulations require amateur frequency stability equivalent to crystal control below 148 MHz. The bank also establishes a measurement capability that applies regardless of emission mode: all amateur stations must be able to reliably measure frequency.

For voice quality, the station must have means to prevent or indicate overmodulation for SSB, and amateur voice communications have a maximum modulation percentage of 100%. Treat overmodulation as both a technical problem and a compliance problem because it can spread energy and make speech less readable.

### Worked example: SSB audio check

An operator receives reports that an SSB signal sounds harsh during voice peaks. The next step is not to add more drive. The operator checks the audio-drive setting and overmodulation indication so the signal stays within the required quality limit.

## Try it

1. A Basic-only operator is invited to use an Advanced operator's station under the Basic operator's call sign. Which privilege set applies? The Basic operator's own privileges apply; the station and helper do not add certificate qualifications.
2. A new operator passed Basic but did not reach the honours mark and has not passed Advanced or Morse. What should the operator do before planning contacts below the 30 MHz boundary? Choose above-30-MHz operation for now, or earn one of the required qualifications first.
3. A signal display is set just inside a band edge, but the occupied signal extends beyond the edge. Is that acceptable? No. The entire occupied bandwidth must stay inside the amateur band.
4. An SSB station with Basic privileges is adjusted from 480 W PEP to 575 W PEP. What changed? It moved from within the Basic SSB PEP limit to above that limit, so the operator must reduce power.
5. A repeater automatically retransmits other stations and has an output just above 29.5 MHz. Why is that output detail important for a Basic-only operator? The bank names 29.500 MHz, and the 29.500 MHz to 29.700 MHz segment, as the low end of repeaters that Basic-only holders may use.

## Radio connection

Privilege checks happen before RF leaves the antenna. Put them in the same mental checklist as SWR, power supply voltage, and microphone level: operator qualification, frequency, bandwidth, power quantity, identification, and whether the station is automatic or repeated.

On modern radios, the display frequency can hide the real regulatory issue. Sidebands, occupied digital bandwidth, amplifier output, and repeater output frequency all matter. If the number that matters is not the one shown on the main dial, find the correct measurement before transmitting.

## Common mistakes

- Borrowing another operator's qualifications because that operator is nearby.
- Treating a station's installed equipment as permission to use all of it.
- Remembering a band name while forgetting the exact range established by the bank.
- Keeping only the displayed carrier frequency inside a band edge and ignoring occupied bandwidth.
- Mixing DC input, carrier power, ERP, EIRP, and PEP as though they were the same measurement.
- Raising microphone gain to solve an SSB problem that is really overmodulation.

## Illustration brief

Alt text: Station checklist with operator qualification, band, bandwidth, power, repeater, and modulation-quality boxes.

Description: Draw a horizontal station chain from operator certificate to transceiver, amplifier, tuner, feedline, and antenna. Above the chain, show checkboxes labelled "qualification," "frequency range," "occupied bandwidth," "power at transmitter/amplifier output," "repeater output," and "voice modulation." Add a small inset comparing a narrow signal safely inside a band edge with a wider signal spilling past the edge.

## Summary

- Operating privileges stay tied to the relevant operator and call sign qualifications.
- Frequencies below 30 MHz require the additional Basic-with-Honours, Advanced, or Morse gate; Basic alone covers amateur bands above that boundary.
- Learn the bank's named HF band ranges and bandwidth limits as exact study facts.
- Near a band edge, the entire occupied bandwidth must remain inside the amateur band.
- Use the minimum legal power needed, and apply the correct Basic or Advanced power quantity.
- Repeaters automatically retransmit; Basic-only holders may use repeaters starting at the bank's named low output segment.
- Frequency stability, frequency measurement, and voice overmodulation controls are part of compliant station operation.
