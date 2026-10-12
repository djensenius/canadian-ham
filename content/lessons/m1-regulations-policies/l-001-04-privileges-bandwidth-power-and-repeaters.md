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

Privileges set the operating edge of the certificate. They answer who may control the station, which frequencies are available, how wide the signal may be, how much power may be used, and which station-quality requirements apply.

This lesson uses reference tables for official facts and prose for relationships. Pay special attention to measurement words.

Peak envelope power (PEP) describes the crest of a modulated RF envelope; the power table uses it for SSB limits. Effective radiated power (ERP) includes antenna-system gain compared with a reference dipole. Equivalent isotropically radiated power (EIRP) uses an ideal isotropic radiator as the reference.

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
| Basic-only repeater use | Holders with only Basic may use repeaters whose output is at 29.500 MHz and above; this row does not open ordinary below-30-MHz transmitting. |
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
| Fast-scan television on 145 MHz | Prohibited because ATV exceeds the 30 kHz limit for 144 MHz to 148 MHz. |
| Fast-scan television on 14.23 MHz | Prohibited because ATV exceeds the 6 kHz limit for amateur bands between 7 MHz and 25 MHz. |

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
| Advanced, DC input to the final RF stage | 1 000 W. |
| Advanced, single-sideband peak envelope power | 2 250 W PEP. |
| Advanced on 60 metres | 100 W ERP expressed as PEP. |
| 630 metres and 2200 metres | Antenna gain must be taken into account because limits are expressed as EIRP. |

## Reference facts: Repeaters, automatic transmissions, stability, and modulation quality

| Topic | Fact established for this lesson |
|---|---|
| Repeater station | Automatically retransmits the signals of other stations. |
| Unmodulated carrier | May be transmitted only for brief tests on frequencies below 30 MHz. |
| Frequency stability | Equivalent to crystal control below 148 MHz; with crystal control, a quartz crystal sets the frequency so it drifts very little. |
| Overmodulation indication or prevention | Required for SSB and for voice-transmission quality control; overmodulation means driving the audio past the clean limit so the signal distorts and can splatter. |
| Voice modulation maximum | 100%, meaning full modulation without going past the clean voice limit. |
| Frequency measurement | All amateur stations must be capable of reliably measuring frequency, regardless of emission mode. |

## How these rules fit together

Privilege rows describe the current control situation. A station can contain equipment for many bands and powers. Whoever has fewer qualifications sets the limit, whether the more-qualified person owns the equipment or controls it under another call sign.

Learn the below-30-MHz gate with the repeater-output row. Basic by itself covers amateur bands above 30 MHz. Below 30 MHz normally needs the additional Basic-with-Honours, Advanced, or Morse path. The 29.500 MHz repeater fact is an output-frequency rule for using a repeater; your own transmissions stay above 30 MHz unless you have the below-30-MHz gate.

Bandwidth, mode, and band-edge rows all describe occupied spectrum. Near an edge, compare the whole signal to the band boundary. A dial display may show the carrier or suppressed carrier; the emitted signal still has width. For the HF band edges, the lower edges form a useful pattern: 3.5, 7, 14, and 28 MHz double, and 21 MHz is 3 x 7 MHz.

The special narrow segment named in the bandwidth table has a tighter limit than the surrounding HF bands. That is why SSB voice is not allowed there.

Power rows attach a number to a measurement point and quantity. DC input is electrical power going into the final RF stage before RF conversion. Carrier power is steady RF output for non-SSB emissions. PEP captures the crest of an SSB voice envelope. ERP and EIRP move outward to radiated power by including antenna-system gain.

The minimum-power rule and numeric ceilings work together with RF-exposure and radiated-power limits. Choose the measurement quantity first, then compare it at the correct point in the station. The Advanced-on-special-band row is different because its limit is ERP expressed as PEP, so antenna gain is part of the comparison.

Repeater and signal-quality rows explain station behaviour after the frequency and power checks. Automatic retransmission defines a repeater. The unmodulated-carrier rule is a narrow test allowance for the range named by the table, not permission to hold a frequency or carry an ordinary contact. Voice operation still needs frequency stability, reliable frequency measurement, and overmodulation control.

### Memory trick: Basic power stays Basic

- Helps remember: Basic, Basic with Honours, and Basic plus Morse share the Basic power limits unless the operator also has Advanced.
- Trick: Honours and Morse open below-30-MHz access; they do not turn the power row into the Advanced row.
- Limit: special bands and radiated-power limits still use the exact quantities in the table.

## Radio connection

### In the real world: the power number on the radio is not the rule by itself

A transceiver display might show RF output, while the radio manual may list maximum whole-radio DC current. If the manual says the radio can draw 20 A from a 13.8 V supply, the whole-radio supply draw is P = I x E = 20 A x 13.8 V = 276 W.

That 276 W is not the same as the Basic 250 W DC-input limit. The regulatory DC-input limit is measured at the final RF stage, not at the power cord for the entire radio. A 100 W front-panel RF-output setting also is not the same measurement quantity as DC input to the final RF stage. Transmitter output limits, such as carrier power and PEP, are measured at the transmitter or amplifier output connector, not after a tuner. ERP and EIRP limits are different: they describe radiated power, so they include antenna-system gain.

A practical station checklist is qualification, frequency range, occupied bandwidth, power quantity, identification, and whether the station is automatic or repeated. On modern radios, sidebands, digital bandwidth, amplifier output, and repeater output frequency can all be the value that matters.

## Summary

- Operating privileges stay tied to the relevant operator and call sign qualifications.
- Frequencies below 30 MHz require the additional Basic-with-Honours, Advanced, or Morse gate; the Basic-only repeater fact is about repeater output frequency, not ordinary below-30-MHz transmitting by the Basic-only operator.
- Link frequency ranges, bandwidth limits, and mode-fit cues before transmitting.
- Near a band edge, the entire occupied bandwidth must remain inside the amateur band.
- Use the minimum legal power needed and apply the correct power quantity.
- Repeaters automatically retransmit; frequency stability, frequency measurement, and voice overmodulation controls are part of compliant operation.

## Illustration brief

Alt text: Station checklist with operator qualification, band, bandwidth, power, repeater, and modulation-quality boxes.

Description: Draw a horizontal station chain from operator certificate to transceiver, amplifier, tuner, feedline, and antenna. Above the chain, show checkboxes labelled "qualification," "frequency range," "occupied bandwidth," "power at transmitter/amplifier output," "repeater output," and "voice modulation." Add an inset comparing a narrow signal safely inside a band edge with a wider signal spilling past the edge.
