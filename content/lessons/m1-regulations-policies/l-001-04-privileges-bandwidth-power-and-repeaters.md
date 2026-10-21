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
  - L-003-05
  - L-005-02
  - L-006-04
estimatedMinutes: 45
quizIds:
  - QZ-L-001-04-A
status: draft
---
# Privileges, bandwidth, power, and repeaters

A radio may offer more bands, modes and power than you may use. Check the people first, then the whole signal: where it sits, how wide it is, how power is measured, and whether it stays clean.

The qualification-by-privilege matrix continues the station-work matrix in L-001-02. Honours and Morse add below-30-MHz access; Advanced adds that access and higher general power limits. No qualification removes special-band or exposure limits.

## Learning objectives

By the end of this lesson, you can:

- apply the qualifications of both the operator and the call sign in use;
- distinguish frequency access from power and station-work privileges;
- keep the whole emission inside the band and bandwidth limit;
- compare power using the correct quantity and measurement point; and
- check repeater use, frequency stability and voice signal quality.

## Reference facts: Qualification-by-privilege matrix for access and power

Whoever has fewer qualifications sets the operating limit. This applies whether a more-qualified visitor uses your call sign or you control a more-qualified owner's station.

The matrix shows general power ceilings, not a target for every contact. Use the least legal power that makes communication possible. Special-band, RF exposure and radiated-power limits still apply.

| Qualifications held | Direct transmitting access | General power limits | Why |
|---|---|---|---|
| Basic only | Amateur bands above 30 MHz. | 250 W DC input to the final RF stage; 560 W SSB PEP; 190 W carrier for non-SSB emissions. | Frequency access and power are separate checks. |
| Basic with Honours | Also below 30 MHz, through a Basic mark of at least 80%. | Same Basic limits. | Honours opens frequency access, not Advanced power. |
| Basic plus Morse | Also below 30 MHz. | Same Basic limits. | Morse opens frequency access, not Advanced power. |
| Basic plus Advanced | Also below 30 MHz. | 1 000 W DC input to the final RF stage; 2 250 W SSB PEP. | Advanced adds higher general power ceilings. |

Honours and Morse retain the Basic power ceilings on their newly available bands too. For station construction, installation and remote settings, use the companion matrix in L-001-02.

| Other access check | Rule | Why |
|---|---|---|
| Model control | Certificate holders may use amateur bands above 30 MHz for radio-controlled models. | Model control has a stated frequency scope. |
| Basic-only repeater use | A repeater's lowest allowed output is 29.500 MHz; the lowest output segment is 29.500 MHz to 29.700 MHz. | Repeater output is not your own transmitting frequency. |

Basic-only operators still transmit into the repeater on an amateur frequency above 30 MHz. A cross-band system can retransmit that signal below the boundary. Hearing or using its output does not grant direct below-30-MHz transmitting access.

## Reference facts: Band edges contain the whole signal

A band name is a wavelength label, not an exact way to calculate its legal edges. Learn the ranges, then leave room for the full emission inside them.

| Band name | Frequency range | Why |
|---|---|---|
| 160 m | 1.8 MHz to 2.0 MHz. | Use the stated edges, not a wavelength estimate. |
| 80 m | 3.5 MHz to 4.0 MHz. | This lower edge starts the doubling pattern below. |
| 40 m | 7.0 MHz to 7.3 MHz. | The lower edge doubles from 80 m. |
| 20 m | 14.000 MHz to 14.350 MHz. | The lower edge doubles again. |
| 15 m | 21.000 MHz to 21.450 MHz. | The lower edge is 3 x 7 MHz. |
| 10 m | 28.000 MHz to 29.700 MHz. | The lower edge doubles from 20 m. |

The lower-edge pattern helps recall; it does not give the upper edges. A dial may display the carrier or suppressed-carrier frequency. The entire occupied signal must fit inside the amateur band, not just the dial frequency.

## Reference facts: Mode width must fit the band

Bandwidth is the frequency space a signal occupies. Choose a mode narrow enough for the band, then place the whole signal inside the band edges.

| Band or mode | Rule or width cue | Why |
|---|---|---|
| 6 m, 50 MHz to 54 MHz; 2 m, 144 MHz to 148 MHz | Maximum bandwidth is 30 kHz. | These limits still exclude very wide modes. |
| 10 m, 28 MHz to 29.7 MHz | Maximum bandwidth is 20 kHz. | Access to the band does not permit any width. |
| Amateur bands between 7 MHz and 25 MHz | Maximum bandwidth is 6 kHz, except 30 m. | Keep the narrow-band exception separate. |
| 30 m, 10.100 MHz to 10.150 MHz | RBR-4 sets a 1 kHz limit; SSB is prohibited. | An SSB voice signal cannot fit this limit. |
| Morse / CW radiotelegraphy | Narrower than SSB voice or FM voice. | Simple keying needs less frequency space. |
| FT8 | A narrow digital mode; many contacts fit in the space of an SSB transmission. | Digital modes need not occupy a voice-sized channel. |
| SSB voice | Usually occupies 2 kHz to 3 kHz. | Compare the actual width with the band's limit. |
| FM voice with 5 kHz deviation | Occupies about 10 kHz to 20 kHz; this exceeds bandwidth limits below 28 MHz. | FM needs room on both sides of its carrier. |
| Fast-scan amateur television (ATV) | Too wide for the 2 m limit and the 20 m limit. | Moving its centre frequency inside the band does not make it fit. |

## Reference facts: Power needs a quantity and a measurement point

DC input feeds the final RF stage before conversion to radio-frequency power. Carrier power measures steady RF output. Peak envelope power (PEP) measures RF power at the crest of the modulation envelope; the matrix uses it for SSB limits.

Effective radiated power (ERP) includes antenna-system gain relative to a reference dipole. Equivalent isotropically radiated power (EIRP) uses an ideal antenna that radiates equally in every direction as its reference.

| Power check | Rule | Why |
|---|---|---|
| DC input limit | Measure input to the transmitter's final RF amplifier stage. | Whole-radio supply draw includes other circuits. |
| Output limit | Verify at the transmitter or external amplifier output connector, before a tuner. | Loss farther along the station does not move this measurement point. |
| RF exposure and radiated-power checks | After finding the maximum transmitter power that meets them, verify that power at the transmitter or amplifier output. | The output setting must match the evaluated station system. |
| Advanced on 60 m | Maximum ERP is 100 W, expressed as PEP. | This limit includes antenna-system gain. |
| 630 m and 2 200 m | Account for antenna gain in their EIRP limits. | Radiated power is not just the radio's display value. |

### In the real world: supply draw is not final-stage input

A radio manual may list 20 A from a 13.8 V supply. Whole-radio draw would then be P = I x E = 20 A x 13.8 V = 276 W. That includes circuits besides the final RF stage; it is not by itself the regulatory DC-input measurement.

Likewise, a front panel showing 100 W RF output is not showing DC input to the final stage. Check the quantity and measurement point before comparing a number with a ceiling. For ERP or EIRP, include antenna-system gain as well.

## Reference facts: Automatic signals still need clean control

A repeater automatically retransmits signals received from other stations. Automation does not remove signal-quality duties: the frequency must be known and stable, and voice peaks must stay within clean modulation limits.

| Station check | Rule | Why |
|---|---|---|
| Unmodulated carrier | Below 30 MHz, send it only for short tests. | A test allowance is not routine unmodulated-carrier operation. |
| Frequency stability | Below 148 MHz, stability must match crystal control. A quartz crystal provides a steady frequency reference. | Drift can move a signal from its intended frequency. |
| Frequency measurement | Every amateur station must reliably measure frequency, whatever the mode. | A displayed setting must correspond to the transmitted signal. |
| Overmodulation | Provide a way to prevent or indicate it for SSB and voice operation. | Excess drive distorts speech and can spread energy into nearby channels. |
| Voice modulation | Maximum modulation is 100%. | Full modulation is the limit, not permission to drive beyond it. |

::figure privileges-station-checklist
Alt text: Station checklist with operator qualification, band, bandwidth, power, repeater, and modulation-quality boxes.
Text equivalent:
- The station chain is cert, radio, amp, and antenna.
- The checklist boxes are band, width, Pout, and voice, with checkmarks labelled qual, repeater, and modulation.
- The band-edge sketches are labelled inside and spills.
::

## How these rules fit together

Check people, place, width, power and quality in that order. The qualification matrix cannot tell you whether a wide mode fits, and a narrow mode cannot supply missing band access.

At a band edge, allow space for the whole signal. For power, name the quantity before reading the meter. For a repeated signal, distinguish your input frequency from the repeater's output. Finish by checking frequency stability, measurement and voice drive.

The M1 numbers board in L-001-01 collects the main values. Use the tables here for their conditions, especially special-band limits and the difference between Basic and Advanced.

## Radio connection

Put the same checklist beside the station controls: operator and call sign, band, full signal width, power quantity, identification, and automatic or repeater operation. Check it again after adding an amplifier or changing mode.

## Illustration brief

Alt text: Station checklist with operator qualification, band, bandwidth, power, repeater, and modulation-quality boxes.

Description: Draw a horizontal station chain from operator certificate to transceiver, amplifier, tuner, feedline, and antenna. Above the chain, show checkboxes labelled "qualification," "frequency range," "occupied bandwidth," "power at transmitter/amplifier output," "repeater output," and "voice modulation." Add an inset comparing a narrow signal safely inside a band edge with a wider signal spilling past the edge.


## Summary

Qualifications open particular privileges, not every setting on a radio. Keep the whole signal within its band and width limit. Compare power at the correct point, then check that the transmitted signal stays stable and clean.
