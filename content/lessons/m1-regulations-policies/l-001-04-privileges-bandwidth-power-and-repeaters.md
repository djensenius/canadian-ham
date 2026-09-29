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

Privileges set the operating edge of the certificate. They answer who may control the station, which frequencies are available, how wide the signal may be, how much power may be used, and which station-quality requirements apply. This lesson uses reference tables for the official facts and prose to explain how those facts connect.

## Learning objectives

By the end of this lesson, you can:

- explain why privileges stay tied to the operator and call sign governing the transmission;
- identify the extra gate for amateur frequencies below 30 MHz;
- use the band, bandwidth, mode, power, repeater, frequency-stability, and modulation facts in the reference tables; and
- keep DC input, carrier power, PEP, ERP, and EIRP separate.

## Reference facts: Operator privileges and below-30-MHz access

| Topic | Fact established for this lesson |
|---|---|
| Another operator with additional qualifications controls your station under your call sign | Only the privileges allowed by your qualifications. |
| You control another station whose owner has more certificate qualifications | Only the privileges allowed by your qualifications. |
| Frequencies below 30 MHz | In addition to Basic, the operator needs 80% on Basic, or Advanced, or Morse code. |
| Radio-controlled models | Certificate holders may operate them on all amateur bands above 30 MHz. |
| Basic-only repeater use | Holders with only Basic may use repeaters with output at 29.500 MHz and above. |
| Lowest Basic-only repeater output segment | 29.500 MHz to 29.700 MHz. |

## Reference facts: HF band ranges

| Band name | Range established for this lesson |
|---|---|
| 160 metres | 1.8 MHz to 2.0 MHz. |
| 80 metres | 3.5 MHz to 4.0 MHz. |
| 40 metres | 7.0 MHz to 7.3 MHz. |
| 20 metres | 14.000 MHz to 14.350 MHz. |
| 15 metres | 21.000 MHz to 21.450 MHz. |
| 10 metres | 28.000 MHz to 29.700 MHz. |

## Reference facts: Bandwidth and mode-fit cues

| Frequency range, band, or mode | Fact established for this lesson |
|---|---|
| 50 MHz to 54 MHz and 144 MHz to 148 MHz | 30 kHz maximum bandwidth. |
| 28 MHz to 29.7 MHz | 20 kHz maximum bandwidth. |
| Amateur bands between 7 MHz and 25 MHz, except the special narrow band | 6 kHz maximum bandwidth. |
| 10.100 MHz to 10.150 MHz | Less than 6 kHz maximum bandwidth. |
| 10.100 MHz to 10.150 MHz | Single sideband is prohibited. |
| Transmitting near band edges | The entire occupied bandwidth must remain within the amateur band. |
| CW / Morse radiotelegraphy | Narrower than SSB voice and FM voice in the mode-width ordering. |
| FT8 | A narrow digital mode, with many FT8 contacts fitting in the space needed for one SSB transmission. |
| SSB voice | Usual SSB bandwidth is between 2 kHz and 3 kHz. |
| FM voice | 5 kHz-deviation FM occupies between 10 kHz and 20 kHz; FM below 28 MHz exceeds regulatory bandwidth limits. |
| Slow-scan television on 14.23 MHz | Fits the B-001 mode-choice item. |
| Fast-scan television on 145 MHz | Prohibited combination in the B-001 mode-choice item. |
| Fast-scan television on 14.23 MHz | Prohibited combination in the B-001 mode-choice item. |

## Reference facts: Power quantities and limits

| Qualification context or power topic | Fact established for this lesson |
|---|---|
| General operating power | Use the minimum legal power necessary to communicate. |
| Power verification after RF exposure and radiated-power limits are determined | Verify at the output of the transmitter or external amplifier. |
| Basic, DC input to the final RF stage | 250 W. |
| Basic, single-sideband peak envelope power | 560 W PEP. |
| Basic and Morse, SSB on 3750 kHz | 560 W PEP. |
| Basic with Honours, SSB on 7055 kHz | 560 W PEP. |
| Basic-only non-SSB emissions for an operator without Advanced | 190 W carrier power. |
| Advanced, DC input to the final RF stage | 1000 W. |
| Advanced, single-sideband peak envelope power | 2250 W PEP. |
| Advanced on 60 metres | 100 W ERP expressed as PEP. |
| 630 metres and 2200 metres | Antenna gain must be taken into account because limits are expressed as EIRP. |

## Reference facts: Repeaters, automatic transmissions, stability, and modulation quality

| Topic | Fact established for this lesson |
|---|---|
| Repeater station | Automatically retransmits the signals of other stations. |
| Unmodulated carrier | May be transmitted only for brief tests on frequencies below 30 MHz. |
| Frequency stability | Equivalent to crystal control below 148 MHz. |
| Overmodulation indication or prevention | Required for SSB in the emission-mode item and for the voice signal-quality problem item. |
| Voice modulation maximum | 100%. |
| Frequency measurement | All amateur stations must be capable of reliably measuring frequency, regardless of emission mode. |

## How these rules fit together

Privilege rows are about the current control situation. A station can contain equipment for many bands and powers, and another person can have more qualifications, but the transmission still has to stay inside the privileges attached to the operator and call sign governing that operation.

The below-30-MHz gate and the repeater exception must be learned together. Basic by itself covers amateur bands above 30 MHz. Below 30 MHz normally needs the additional Basic-with-Honours, Advanced, or Morse path, while the repeater rows give a specific Basic-only repeater-output allowance beginning at 29.500 MHz. Keep that repeater allowance tied to repeater output.

Bandwidth, mode, and band-edge rows all describe occupied spectrum. Near an edge, compare the entire occupied signal to the band boundary. The mode rows are cues for the combination items and should stay within the supported width facts listed above.

Power rows attach a number to a measurement point and quantity. DC input describes electrical power going into the final RF stage before RF conversion. Carrier power describes steady RF output for non-SSB emissions, while PEP captures the crest of an SSB voice envelope. ERP and EIRP move outward to radiated power by including antenna-system gain, with EIRP using an isotropic reference. Output-point checks are made before feedline or tuner effects, while ERP and EIRP account for radiated-system effects.

The minimum-power rule and numeric ceilings work together with RF-exposure and radiated-power limits. Choose the measurement quantity first, then compare it at the correct point in the station.

Repeater and signal-quality rows explain station behaviour after the frequency and power checks. Automatic retransmission defines a repeater. Brief unmodulated-carrier tests are narrow, and voice operation still needs frequency stability, reliable frequency measurement, and overmodulation control.

## Radio connection

Privilege checks happen before RF leaves the antenna. Put them in the same mental checklist as SWR, power supply voltage, and microphone level: operator qualification, frequency, occupied bandwidth, power quantity, identification, and whether the station is automatic or repeated.

On modern radios, the display frequency can hide the regulatory issue. Sidebands, occupied digital bandwidth, amplifier output, and repeater output frequency can all be the relevant value.

## Summary

- Operating privileges stay tied to the relevant operator and call sign qualifications.
- Frequencies below 30 MHz require the additional Basic-with-Honours, Advanced, or Morse gate, except for the specific Basic-only repeater-output allowance in the reference table.
- Link frequency ranges, bandwidth limits, and mode-fit cues before transmitting.
- Near a band edge, the entire occupied bandwidth must remain inside the amateur band.
- Use the minimum legal power needed and apply the correct power quantity.
- Repeaters automatically retransmit; frequency stability, frequency measurement, and voice overmodulation controls are part of compliant operation.

## Illustration brief

Alt text: Station checklist with operator qualification, band, bandwidth, power, repeater, and modulation-quality boxes.

Description: Draw a horizontal station chain from operator certificate to transceiver, amplifier, tuner, feedline, and antenna. Above the chain, show checkboxes labelled "qualification," "frequency range," "occupied bandwidth," "power at transmitter/amplifier output," "repeater output," and "voice modulation." Add an inset comparing a narrow signal safely inside a band edge with a wider signal spilling past the edge.
