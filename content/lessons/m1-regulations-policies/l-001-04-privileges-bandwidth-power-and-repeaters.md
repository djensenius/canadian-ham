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

### Worked example: station label versus operating authority

A transceiver memory is labelled "high-power HF," but the operator at the controls has only the privileges that apply to that operator and call sign. The label is useful for station organization; it does not decide whether the operator may use the frequency, emission, or power setting.

## The below-30-MHz gate

The bank and exam-facts record establish a specific extra gate for amateur frequencies below 30 MHz. In addition to passing the Basic written examination, an operator must have a Basic mark of 80% or more, or pass an Advanced or Morse code examination, before using those frequencies.

Basic qualification by itself supports all amateur bands above 30 MHz. The bank also establishes that radio-controlled models may be operated on all amateur bands above 30 MHz.

The repeater facts below add a narrow, bank-tested exception to the simple boundary: holders of only a Basic Qualification may use repeaters whose output is 29.500 MHz and above, with the bank naming 29.500 MHz to 29.700 MHz as the lowest output segment. Treat that as a repeater-output rule, not as a general permission for every below-30-MHz contact.

## Reference facts: HF band ranges named in the bank

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

An operator with Basic only wants a plan for a weekend contact and is choosing between a VHF simplex channel and an HF voice frequency. The first planning question is not antenna length or microphone gain. It is whether the operator has the required below-30-MHz authorization for the HF option; otherwise, the plan must stay with an above-30-MHz amateur path or another privilege the bank specifically permits.

## Bandwidth limits and band edges

Bandwidth limits control how much spectrum one transmission occupies.

### Reference facts: bandwidth limits

| Frequency range or band | Maximum bandwidth fact from the bank |
|---|---|
| 50 MHz to 54 MHz and 144 MHz to 148 MHz | 30 kHz |
| 28 MHz to 29.7 MHz | 20 kHz |
| Amateur bands between 7 MHz and 25 MHz, except the special narrow band named below | 6 kHz |
| 10.100 MHz to 10.150 MHz | less than 6 kHz; single sideband is prohibited |

### Reference facts: mode-fit cues from the bank

The B-001 bandwidth questions rely on mode-width cues that the wider question bank also teaches:

| Mode or signal | Bank-supported cue for this lesson |
|---|---|
| CW / Morse radiotelegraphy | Narrower than SSB voice and FM voice; CW fits narrow-band examples in B-001-016. |
| FT8 | Narrow digital bandwidth; the bank says many FT8 contacts fit in the space needed for one SSB transmission. |
| SSB voice | Usual bandwidth is between 2 kHz and 3 kHz; the 10.100 MHz to 10.150 MHz band is a special case where SSB is prohibited. |
| FM voice | A 5 kHz-deviation FM signal occupies between 10 kHz and 20 kHz, and the bank says FM below 28 MHz would exceed regulatory bandwidth limits. |
| Slow-scan television (SSTV) | The bank treats SSTV on 14.23 MHz as not prohibited in the B-001 mode-choice item. |
| Fast-scan television (ATV) | The bank treats fast-scan ATV as too wide for 145 MHz and for 14.23 MHz, but not as prohibited by the same item on 440 MHz. |

### Band-edge and mode planning

When transmitting near a band edge, leave enough room for the whole signal shape. Do not place only the carrier or display frequency inside the edge and let sidebands or occupied data energy spill outside.

The bank gives examples of mode-and-frequency combinations that do and do not fit their limits. The lesson principle is broader: check both the frequency and the occupied bandwidth before transmitting.

### Worked example: upper-edge arithmetic

A 2.4 kHz-wide SSB signal is being planned near the top of the 20-metre range. If the operator's displayed frequency would put part of that occupied signal above 14.350 MHz, the contact needs a lower setting or a different plan. The displayed number is not enough; the full occupied signal has to fit.

## Power quantities and limits

Use the minimum legal power necessary to communicate. After you choose a power that also satisfies RF-exposure and radiated-power constraints, check the RF output point of the transmitter or external amplifier rather than a later point in the antenna system.

### Reference facts: power limits

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

### Worked example: switching modes changes the power quantity

A station log shows one entry for SSB peak-envelope power and another for a non-SSB carrier-power setting. The operator cannot reuse the SSB PEP number as though it were the carrier-power limit for a different emission. The rule being applied decides which power quantity is being checked.

## Repeaters and automatic transmissions

A repeater station listens to one station and automatically retransmits what it hears for other stations. The bank establishes that holders of only a Basic Qualification may use repeaters with output at 29.500 MHz and above, with the lowest named output segment being 29.500 MHz to 29.700 MHz.

### Reference facts: station-type cues

| Station type named in the bank | Cue used in this lesson |
|---|---|
| Repeater station | Automatically retransmits signals from other stations. |
| Beacon station | The bank elsewhere identifies a beacon station as a type that may transmit one-way communications; that is different from retransmitting other stations. |
| Remote-control station | The name points to station control from a control point; it is not the station type the bank defines by automatic retransmission. |
| Satellite control station | The name points to controlling satellite functions; it is not the general automatic-retransmission station in the B-001-018 item. |

An unmodulated carrier is a narrow testing tool, not a way to reserve a channel. The bank limits that kind of carrier to brief tests below the 30 MHz boundary.

## Frequency stability and modulation quality

Canadian regulations require amateur frequency stability equivalent to crystal control below 148 MHz. The bank also establishes a measurement capability that applies regardless of emission mode: all amateur stations must be able to reliably measure frequency.

For voice quality, the station must have means to prevent or indicate overmodulation for SSB, and amateur voice communications have a maximum modulation percentage of 100%. Treat overmodulation as both a technical problem and a compliance problem because it can spread energy and make speech less readable.

### Worked example: clean audio before more drive

An SSB signal report says the speech peaks sound distorted. The next step is not to add more microphone gain just because the contact is weak. The operator checks the overmodulation indication or prevention method and keeps voice modulation within the required limit.

## Try it

1. A Basic-only operator with no honours is choosing between a 52 MHz simplex contact, a 14.2 MHz simplex contact, and a repeater whose output is 29.62 MHz. Which choices need more qualification, and which one uses the repeater exception? The 52 MHz contact fits Basic by itself, the 14.2 MHz simplex contact needs the below-30-MHz gate, and the 29.62 MHz repeater output can fit the Basic-only repeater rule.
2. A voice-width signal is being placed near the upper edge of one HF band from the reference table by an operator who knows the displayed frequency is inside the band. What must the frequency plan prove before transmitting? The plan must combine that table edge with the band-edge rule: the entire occupied signal, not only the display frequency, must remain inside the band.
3. A mid-HF mode choice comes down to ordinary SSB, FT8, or fast-scan ATV. How do the mode-width and HF bandwidth facts decide the plan? SSB and FT8 are narrow enough for the HF context taught here, while fast-scan ATV is treated by the bank as too wide for that HF-width group.
4. An SSB station with Basic privileges is adjusted from 480 W PEP to 575 W PEP after the operator remembers to use minimum legal power. What changed? The setting moved from within the Basic SSB PEP limit to above that limit, and the minimum-power principle points in the same direction: reduce power rather than keep the higher setting.
5. A net wants to hold a below-30-MHz channel by transmitting an unmodulated carrier until the meeting starts, and the frequency is close to other activity. Which two checks reject the plan? An unmodulated carrier is only for brief tests below 30 MHz, and any test transmission must avoid interfering with amateur or other services.

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
- Basic-only repeater use has the bank's specific 29.500 MHz-and-above output exception; do not turn it into a general below-30-MHz privilege.
- Learn the bank's named HF band ranges, bandwidth limits, and mode-width cues as exact study facts.
- Near a band edge, the entire occupied bandwidth must remain inside the amateur band.
- Use the minimum legal power needed, and apply the correct Basic or Advanced power quantity.
- Repeaters automatically retransmit; frequency stability, frequency measurement, and voice overmodulation controls are part of compliant station operation.
