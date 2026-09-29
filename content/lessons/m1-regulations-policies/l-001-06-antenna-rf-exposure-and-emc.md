---
type: lesson
id: L-001-06
moduleId: M1
categoryIds:
  - B-001
title:
  en: "Antenna consultation, Safety Code 6, and EMC"
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
# Antenna consultation, exposure limits, and EMC

Antenna projects are visible, RF fields are invisible, and interference complaints can become emotional. The exam groups these topics together because a responsible station owner has to think beyond the radio room: neighbours, land-use authorities, people near antennas, and affected electronic equipment all matter.

This lesson states only the regulatory facts established by the official answers. Use it to pass the exam and to build careful habits, then consult current ISED and Health Canada material before a real installation or RF exposure evaluation.

## Learning objectives

By the end of this lesson, you can:

- explain why antenna installations may require consultation instead of unilateral action;
- distinguish ISED authority from municipal process details;
- describe the purpose of RF exposure limits without inventing a simple safe-wattage shortcut;
- name the RF exposure factors that the official bank identifies; and
- apply the EMCAB-2 idea that field strength at the affected premises matters when judging an interference complaint.

## Antenna structures involve public process

An antenna structure is not just another accessory on the bench. The official answers establish that ISED antenna-siting procedures apply, that community concerns should be handled responsibly, and that consultation with the land-use authority may be required before installations that could raise community concerns.

For antenna systems, including supports and towers, the named federal decision authority is the Minister of Innovation, Science and Industry. A municipality or local land-use authority may have a public consultation process, and when it has one, that local process determines how consultation should take place. If there is no local approval process, the ISED default process is the path identified by the official bank.

### Worked example: choosing the process path

A station owner wants to replace a small temporary support with a more visible permanent support. Before buying hardware, she creates two folders. Folder A is for local land-use information. Folder B is for ISED default-process material in case the local authority has no process. She also keeps a record of written notices and responses.

The important reasoning is the order: first find whether an applicable local process or exclusion exists, then follow the correct path. The answer is not "build first and explain later."

## Exclusions and concerns

The official answers do not give one universal antenna height that always avoids consultation. Instead, they point to exclusions defined by ISED and to exclusions in a municipal process. In the municipality case, either applicable exclusion path can be enough. That means a responsible operator checks the applicable process rather than memorizing a single number or turning the OR into an AND.

For ISED's public consultation process, the bank identifies written notice, addressing relevant concerns, and giving the public an opportunity to respond regarding measures for reasonable and relevant concerns. In the default-process item, written concerns that are both timely and relevant are the ones identified by the official bank. The bank also distinguishes those process elements from public meetings, which are not identified as a required element in the official answer set.

### Reference facts

| Topic | Official fact to preserve |
|---|---|
| Municipal antenna-process exclusions | Public consultation might not be required when the system is excluded by the municipal process OR by the provisions of Client Procedures Circular CPC-2-0-03. |
| ISED default-process concerns | The proponent must address reasonable and relevant concerns provided in writing within the 30-day public comment period. |
| RF exposure guideline name | Safety Code 6 is the Health Canada guideline that gives RF exposure limits for the human body. |
| RF exposure exemptions | No transmitter type is exempt from RF exposure regulation in the official answer set. |
| Greatest RF-energy risk range | The 48 MHz to 300 MHz range is identified with the strongest RF-energy absorption by the human body. |
| Low-frequency adverse effect | Below 10 MHz, nerve stimulation is the other established adverse effect named by the bank. |
| EMCAB-2 cause criterion | The cause decision uses field strength at the affected premises compared with ISED's specified immunity criterion. |

Use this table only as an exam-fact anchor. It is not a substitute for checking current official procedures before a real project.

If a proponent and a non-public stakeholder cannot agree, the official answer places the final decision with ISED. That does not make courtesy optional; it identifies who resolves the deadlock described by the bank.

## RF exposure basics

Health Canada is the organization named by the official bank for guidelines on maximum RF energy near the human body. The exposure code named in the reference table gives limits for people exposed to RF energy. It does not list amateur frequency allocations, set transmitter power for interference control, or set antenna heights for aircraft safety.

A conservative station habit is to avoid searching for a single magic output power. The official answers say the maximum safe antenna power for a hand-held VHF or UHF radio is not specified, and that no transmitter type is exempt from the RF exposure rules. Even portable and low-power equipment should be treated seriously.

## What changes exposure

For exam purposes, the identified factors are antenna gain, distance, transmitter power, and frequency. The official answers also identify controlled and uncontrolled environments as the two basic exposure situations, with lower limits for the general public in uncontrolled areas than for controlled areas.

The frequency range from 48 MHz to 300 MHz is identified as the range of greatest RF-energy risk because the human body absorbs RF energy most strongly there. Separately, below 10 MHz, nerve stimulation is the other established adverse effect named by the bank. Keep those as conservative exam facts; do not extend them into medical advice.

The exposure code is expressed in quantities such as electric field strength, magnetic field strength, induced currents, contact currents, and specific absorption rate. It is not simply a table of power fed into antennas. That is why transmitter power alone cannot answer every exposure question.

### Worked example: making a conservative station adjustment

A VHF antenna on a temporary mast is moved from beside a picnic table to a higher support farther from the seating area, while the operator keeps the same transmitter and antenna. The station owner has not calculated a formal compliance boundary from that fact alone, but the change is in the safer direction for bystanders because distance is one of the exposure factors named by the official bank.

The careful conclusion is limited: increasing separation helps reduce concern, but it does not replace a proper RF exposure evaluation when one is required.

## EMCAB-2 and interference complaints

EMCAB-2 deals with electromagnetic compatibility complaints using field strength at the affected premises and equipment category. If your emissions are below ISED's specified immunity criteria at the neighbour's premises, the official answer treats the affected equipment's lack of immunity as the cause. If the field strength is above the specified criterion, the official answer treats your transmission as the cause.

Notice what is not enough by itself. Transmitting within your power privileges does not settle the EMCAB-2 cause question. The fact that the problem starts and stops with your transmissions is useful troubleshooting information, but the exam criterion is the measured or assessed field strength relative to the specified immunity criterion.

Equipment category also matters. The bank identifies home-entertainment devices that are not strictly radio apparatus as associated equipment, and it uses a separate radio-sensitive equipment category for another affected-device item. Use those labels as exam facts and then work cooperatively in real troubleshooting.

## Try it

1. A visible support project has no local approval process, and a non-public stakeholder still disagrees after discussion. What decision path should the file show? Do not build first; use the ISED default consultation path for the missing local process, and recognize ISED as the final decision maker for that unresolved stakeholder dispute.
2. A municipality's process excludes an installation, but a checklist says the CPC exclusion must also match and asks for a universal maximum height. What should be corrected? Do not turn the exclusion rule into an AND test, and do not invent a fixed height; the relevant question is whether the applicable local or ISED exclusion covers the system.
3. An RF-exposure worksheet for people near an antenna records only transmitter output and leaves distance, gain, frequency, and exposure quantities blank. What two checks are missing? The review needs the exposure factors and the Health Canada exposure-code quantities identified by the bank, not just watts from the transmitter.
4. A public demonstration includes a station in the range tied to strongest body absorption beside visitors and another station in the low-frequency nerve-stimulation case near an equipment table. What conservative note belongs on the plan? Treat the public area as the stricter exposure situation, remember the body-absorption range, and keep the nerve-stimulation fact separate from the energy-absorption fact.
5. A complaint file has one affected item in the home-entertainment associated-equipment category and another item in the radio-sensitive category. The log records only that both problems start during transmissions. What is still needed before assigning cause? Match each item to the proper equipment category and compare the field strength at the affected premises with the ISED immunity criterion.

## Radio connection

These rules connect directly to station design. A tidy antenna installation is easier to discuss with neighbours. A station layout that keeps people away from radiating elements is easier to operate responsibly. A clean transmitter, good feedline, and proper filtering help, but an EMCAB-2 question still turns on the field-strength criterion and equipment category described in the official answers.

Good operators also document. Keep dates, contact names, notices, equipment settings used during a complaint investigation, and changes made to the station. Documentation does not replace the rule, but it helps everyone understand what was checked and why.

## Common mistakes

- Assuming an amateur antenna project is exempt from consultation just because it is non-commercial.
- Memorizing a single antenna height as a universal no-consultation limit.
- Treating transmitter power as the only RF exposure quantity.
- Assuming hand-held or low-power transmitters are automatically outside the RF exposure rules.
- Deciding an EMCAB-2 complaint from on/off symptoms instead of the field-strength criterion at the affected premises.
- Confusing associated equipment with radio-sensitive equipment.

## Illustration brief

Alt text: A station owner reviewing antenna, RF exposure, and interference checklists before transmitting.

Description: Draw three panels. Panel one shows a house, a mast, a neighbour, and a folder labelled "consultation path." Panel two shows a person standing outside a marked antenna area with callouts for power, gain, distance, and frequency. Panel three shows a transmitter, a field-strength meter symbol at a neighbour's premises, and two labelled devices: home entertainment gear and an affected control device. Keep all text original and avoid official question wording.

## Summary

- Antenna installation and modification can involve ISED procedures, local land-use processes, exclusions, and responsible handling of community concerns.
- The Minister of Innovation, Science and Industry is the authority named for antenna installations, while a local process can determine how consultation takes place.
- Health Canada is named for RF exposure guidelines, and the official bank ties the named exposure code to limits for human exposure.
- The official exposure factors include antenna gain, distance, transmitter power, and frequency; no transmitter type is treated as exempt in the bank.
- The exposure rules are about exposure quantities, not merely watts into an antenna.
- EMCAB-2 cause decisions use field strength at the affected premises relative to ISED immunity criteria, plus the relevant equipment category.
