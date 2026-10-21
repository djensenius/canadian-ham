---
type: lesson
id: L-001-06
moduleId: M1
categoryIds:
  - B-001
title:
  en: "Antenna consultation, RF exposure, and EMC"
  fr: null
covers:
  - B-001-023
  - B-001-024
  - B-001-025
objectives:
  - "Identify antenna-siting consultation responsibilities."
  - "Explain the purpose of RF exposure limits."
  - "Use EMCAB-2 criteria when assessing interference complaints."
prerequisites:
  - L-001-05
  - L-003-08
  - L-006-04
  - L-008-01
estimatedMinutes: 40
quizIds:
  - QZ-L-001-06-A
status: draft
---
# Antenna consultation, RF exposure, and EMC

One antenna project needs three separate checks: follow the siting process, protect people from excessive RF exposure, and assess interference at affected equipment. Passing one check does not settle the other two.

For a real installation, use current ISED and Health Canada guidance. These reference facts explain the responsibilities and distinctions you need to study.

## Learning objectives

By the end of this lesson, you can:

- find the applicable antenna-consultation process or exclusion;
- describe the default notice, concern and response steps;
- distinguish exposure limits from transmitter power;
- explain controlled and uncontrolled environments; and
- compare interference field strength with the criterion for the affected equipment.

## Reference facts: Follow the applicable consultation process

The local land-use authority may have its own consultation process. CPC-2-0-03 is ISED's antenna-siting procedure. Check both the applicable process and exclusions before deciding what consultation is required.

| Siting check | Rule | Why |
|---|---|---|
| Installing or changing an antenna structure | Consultation duties may apply. | A structure's size alone does not settle the duty. |
| Federal authority | Antenna installations, masts and towers fall under the authority of the Minister of Innovation, Science and Industry. | Local consultation sits within the federal framework. |
| ISED exclusion | An applicable ISED exclusion can remove the need to contact the land-use authority about public consultation requirements. | Check the exclusion before choosing a process. |
| Local process exists | The municipality or land-use authority determines how public consultation takes place. | Start with the process for the installation's location. |
| Exclusions where a local process exists | An exclusion in that process or in CPC-2-0-03 can remove the public-consultation duty. | Either source can provide an applicable exclusion. |
| No local approval process | Use ISED's default public-consultation process. | Absence of a local process is not permission to omit consultation. |
| Default process steps | Give written notice, address relevant questions and concerns, and allow public responses to the measures taken. | Consultation includes listening and responding. |
| Default public comment period | Address reasonable, relevant concerns submitted in writing within 30 days. | Timing, relevance and written form belong together. |
| Height without public consultation | Use the tallest structure exempted by the land-use authority or ISED. | There is no single height answer for every site. |
| Unresolved disagreement with a non-public stakeholder | ISED makes the final decision. | The proponent cannot settle this simply by proceeding. |

## Reference facts: Protect people by assessing exposure

Health Canada's Safety Code 6 sets human RF exposure limits. A transmitter's rated output is only one input to the assessment; gain, distance and frequency also affect exposure.

A controlled environment has assessed RF fields and people who understand the potential exposure and can control or reduce it. An uncontrolled environment includes the general public, who may not have that knowledge or control.

| Exposure check | Rule | Why |
|---|---|---|
| Publisher and purpose | Health Canada publishes Safety Code 6 to limit human exposure to RF energy. | Use the human-exposure framework, not a transmitter rating. |
| 48 MHz to 300 MHz | The bank identifies this as the greatest-risk range, with the lowest exposure limits because body absorption is strongest. | Frequency changes how strongly the body absorbs RF. |
| Below 10 MHz | Nerve stimulation is another established adverse effect, apart from absorption. | Heating is not the only effect addressed. |
| Controlled and uncontrolled settings | The code covers both; uncontrolled settings have lower public limits. | Public exposure needs protection without relying on trained control. |
| Hand-held radios and other transmitters | Every transmitter type is included; hand-held transmitters are not exempt. | Small size does not remove the exposure duty. |
| A hand-held VHF/UHF radio | There is no single specified maximum safe power fed to its antenna. | Power alone cannot describe a person's exposure. |
| Limit quantities | Limits use quantities such as fields, currents and specific absorption rate. | These describe exposure of people, not just watts at a connector. |
| Assessment inputs | Account for antenna gain, distance, transmitter power and frequency. | The antenna and the person's location affect the result. |

A human body is roughly resonant in the VHF range. At 80 MHz, a half-wavelength is about 1.9 m, near an adult's body length. That helps explain stronger whole-body absorption; it is not a complete exposure model.

## Reference facts: Investigate interference at the affected equipment

Electromagnetic compatibility (EMC) means equipment keeps working in its radio environment. Electromagnetic Compatibility Advisory Bulletin 2 (EMCAB-2) compares the field at the affected premises with ISED's immunity criterion for that equipment. Immunity means the equipment's ability to keep working in that field.

| Complaint or equipment | Rule | Why |
|---|---|---|
| Stereo malfunction, field below the criterion at the neighbour's premises | EMCAB-2 attributes the problem to the stereo's lack of immunity. | Compare the field where the affected device is located. |
| Television malfunction, field above the criterion at the neighbour's premises | EMCAB-2 attributes the problem to the amateur transmission. | Being within a power ceiling does not by itself settle this comparison. |
| Home-entertainment equipment used with radio apparatus | Recorders, playback devices and amplifiers are associated equipment. | They support the radio system without being radio apparatus themselves. |
| A garage door opener | Use the radio-sensitive equipment category: other non-radio electronics whose operation can be affected by radio emissions. | Choose the category before choosing its field-strength criterion. |

The Radiocommunication Act's radio-sensitive equipment definition excludes radio apparatus. Keep the EMCAB-2 categories for broadcast receivers, associated equipment and other non-radio electronics separate when selecting a criterion.

::figure antenna-rf-emc-checklists
Alt text: A station owner reviewing antenna, RF exposure, and interference checklists before transmitting.
Text equivalent:
- Consultation panel: house, separate mast, nearby person, and folder.
- RF exposure panel: antenna, keep-clear circle, person outside, and labels transmitter power, antenna gain, distance, frequency, and clear.
- EMC check panel: transmitter, signal path, meter, home, and neighbouring-device interference check.
::

## How these rules fit together

Consultation is a process check. Exposure is a people check. EMC is an equipment check. An exclusion from consultation does not exclude an exposure assessment, and a safe exposure result does not diagnose an interference complaint.

For consultation, identify the local process or ISED default and any applicable exclusion. For exposure, consider both the station system and where people can be. For interference, identify the device category and compare field strength at the affected premises with the matching criterion.

The M1 numbers board in L-001-01 keeps the public comment period separate from address reporting. It also lists the absorption range; the exposure table here supplies its meaning and conditions.

## Radio connection

### In the real world: three records for one change

Keep a consultation record, an exposure assessment and an interference record. Note the mast position, antenna height, feedline route and places people can reach. Record relevant contacts, measurement information and changes made during an investigation.

These records help show what you checked and why. They do not replace consultation, exposure limits or the technical work needed to keep a clean signal.

## Illustration brief

Alt text: A station owner reviewing antenna, RF exposure, and interference checklists before transmitting.

Description: Draw three panels. Panel one shows a house, a mast, a neighbour, and a folder labelled "consultation path." Panel two shows a person standing outside a marked antenna area with callouts for power, gain, distance, and frequency. Panel three shows a transmitter, a field-strength meter symbol at a neighbour's premises, and two labelled devices: home entertainment gear and an affected control device. Keep all text original.


## Summary

Check process, people and equipment separately. Use the applicable consultation path, assess exposure rather than guessing from transmitter power, and investigate interference at the affected device. A responsible installation needs all three checks.
