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
estimatedMinutes: 40
quizIds:
  - QZ-L-001-06-A
status: draft
---
# Antenna consultation, RF exposure, and EMC

Antenna projects are visible, RF fields are invisible, and interference complaints can become emotional. A responsible station owner considers neighbours, land-use authorities, people near antennas, and affected electronic equipment.

This lesson states verified reference facts. Use it for the exam and for careful habits. For a real installation or RF exposure evaluation, consult current ISED and Health Canada material.

## Learning objectives

By the end of this lesson, you can:

- identify who decides antenna-siting consultation questions;
- describe the ISED default consultation steps and local-process exclusions;
- explain why the RF exposure code uses different limits by frequency and setting;
- name the RF exposure factors and quantities in the reference tables; and
- apply EMCAB-2 field-strength and equipment-category facts for interference complaints.

## Reference facts: Antenna siting and public consultation

| Topic | Fact established for this lesson |
|---|---|
| Installation or modification of an antenna structure | Consultation duties can apply to antenna structures. |
| Antenna installations, including masts and towers | Authority rests with the Minister of Innovation, Science and Industry. |
| ISED-defined exclusion criterion | An exclusion can remove the requirement to contact land-use authorities to determine public consultation requirements. |
| No local land-use approval process | Follow ISED's default public consultation process. |
| ISED default-process elements | Provide written notice, address relevant questions, comments, and concerns, and give the public an opportunity to respond to the measures taken. |
| ISED default-process concerns | Address reasonable and relevant concerns provided in writing within the 30-day public comment period. |
| Municipality with a consultation process | Exclusion by the municipal process OR by CPC-2-0-03 can remove the public-consultation requirement. |
| Proponent and non-public stakeholder fail to agree | ISED makes the final decision. |
| Tallest structure without public consultation | The tallest exempted by the land-use authority or ISED. |
| Local process exists | The municipality or local land-use authority determines how public consultation should take place. |

## Reference facts: Safety Code 6 and RF exposure

| Topic | Fact established for this lesson |
|---|---|
| Organization publishing guidelines for maximum RF energy near the human body | Health Canada. |
| Purpose of Safety Code 6 | Gives RF exposure limits for the human body. |
| Greatest RF-energy risk range | 48 MHz to 300 MHz. |
| Reason for the lowest exposure limit in that range | The human body absorbs RF energy the most in this range. |
| Maximum safe power output to the antenna of a hand-held VHF or UHF radio | No specified value. |
| Basic exposure situations | Controlled and uncontrolled environments; uncontrolled areas include the general public and have lower public limits. |
| Other established adverse effect below 10 MHz | Nerve stimulation. |
| Hand-held transmitters | Included in Safety Code 6 requirements. |
| Transmitter exemptions | No transmitters are exempt. |
| Exposure quantities | Safety Code 6 uses exposure quantities such as fields, currents, and absorption rate. |
| Exposure factors | Antenna gain, distance, transmitter power, and frequency. |

## Reference facts: EMCAB-2 interference criteria

| Topic | Fact established for this lesson |
|---|---|
| Stereo-system complaint | Lack of immunity is the cause when field strength at the neighbour's premises is below ISED's specified immunity criteria. |
| Television-receiver complaint | The amateur transmission is the cause when field strength at the neighbour's premises is above ISED's specified immunity criteria. |
| Home-entertainment devices outside the strict radio-apparatus category | Associated equipment, such as audio or video recorders, playback devices, and amplifiers used with radio apparatus. |
| Garage door opener affected by transmissions | Radio-sensitive equipment, meaning other non-radio electronic equipment whose function can be affected by radio emissions. |

## How these rules fit together

Antenna-siting rows describe process. The station owner first finds the applicable local process or exclusion for the specific installation. CPC-2-0-03 is ISED's antenna-siting procedure, and an exclusion can come from that procedure or from the local process. If there is no local approval process, the ISED default process is the relevant path.

Use the timeliness and relevance criteria in the table when responding to written concerns in the default process. The tallest structure that avoids public consultation is the tallest one exempted by the land-use authority or ISED, so check the applicable exemption instead of using one universal height. If a proponent and a non-public stakeholder do not agree, ISED makes the final decision.

The exposure rows describe human RF exposure. A controlled environment is one where RF fields are assessed and people can be aware of the exposure, such as trained operators or workers. An uncontrolled environment covers everyone else, including the general public, so its limits are lower.

The VHF range named in the table matters because a human body is roughly resonant there. At 80 MHz, one half-wavelength is about 1.9 m, which is close to adult body length, so whole-body absorption can be stronger. At the low-frequency range named in the table, RF current can stimulate nerves, so the exposure code also treats nerve stimulation as an established effect.

Transmitter power matters as one factor among gain, distance, and frequency. Hand-held transmitters are still included, and no transmitter category is exempt from the RF exposure check.

Electromagnetic compatibility means equipment keeps working in its radio environment. Electromagnetic Compatibility Advisory Bulletin 2 (EMCAB-2) rows describe interference cause decisions for affected equipment. The important comparison is field strength at the affected premises against ISED's specified immunity criterion, along with the equipment category.

The Radiocommunication Act definition of radio-sensitive equipment excludes radio apparatus. EMCAB-2 therefore separates broadcast receivers and associated home-entertainment equipment from other non-radio electronic equipment, such as the garage-door example.

## Radio connection

### In the real world: three folders for one station change

A useful installation file has three parts. One part tracks the antenna consultation path. One records RF exposure inputs such as power, gain, distance, and frequency. One records interference contacts, field-strength information if available, and equipment categories.

Tie that file to the hardware. Note the mast or tower location, feedline route, antenna height, places where people can stand, and any station changes made during an interference investigation.

Those notes do not replace the rules. They help the station owner show what was checked, who was contacted, what changed, and why.

These rules connect directly to station design. A tidy antenna installation is easier to discuss with neighbours. A station layout that keeps people away from radiating elements is easier to operate responsibly. A clean transmitter, good feedline, and proper filtering help the technical side of that responsibility.

## Summary

- Antenna installation and modification can involve ISED procedures, local land-use processes, exclusions, and responsible handling of community concerns.
- The ISED default process uses written notice, written concern handling, and a public reply opportunity.
- Safety Code 6 uses lower limits where body absorption is stronger or where the public is in an uncontrolled environment.
- Exposure checks combine antenna gain, distance, transmitter power, frequency, and all transmitter types, including hand-held radios.
- Safety Code 6 limits are expressed as fields, currents, and specific absorption rate; transmitter power is an exposure factor.
- EMCAB-2 cause decisions use field strength at the affected premises relative to ISED immunity criteria, plus the relevant equipment category.

## Illustration brief

Alt text: A station owner reviewing antenna, RF exposure, and interference checklists before transmitting.

Description: Draw three panels. Panel one shows a house, a mast, a neighbour, and a folder labelled "consultation path." Panel two shows a person standing outside a marked antenna area with callouts for power, gain, distance, and frequency. Panel three shows a transmitter, a field-strength meter symbol at a neighbour's premises, and two labelled devices: home entertainment gear and an affected control device. Keep all text original.
