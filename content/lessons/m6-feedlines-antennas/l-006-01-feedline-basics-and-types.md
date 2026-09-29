---
type: lesson
id: L-006-01
moduleId: M6
categoryIds:
  - B-006
title:
  en: "Feedline basics and types"
  fr: null
covers:
  - B-006-001
  - B-006-002
  - B-006-003
objectives:
  - "Explain the job of a feedline between radio and antenna."
  - "Compare coaxial, twin-lead, and open-wire construction."
  - "Choose feedline based on surroundings and common-mode concerns."
prerequisites: []
estimatedMinutes: 35
quizIds:
  - QZ-L-006-01-A
status: draft
---
# Feedline basics and types

A radio does not usually connect straight to an antenna element. The energy must travel from the transceiver, through a feedline, to the antenna feed point. The feedline is part of the antenna system, so its construction and routing affect how much power reaches the radiating element and how predictable the station is.

For a beginner, the big idea is simple: a feedline should guide RF energy instead of becoming an unwanted radiator. The best choice depends on impedance, balance, loss, weather, nearby metal, and the connectors your equipment uses.

## Learning objectives

By the end of this lesson, you can:

- describe what a transmission line does in an amateur station;
- explain characteristic impedance without confusing it with DC resistance;
- compare coaxial cable, twin-lead or window line, and open-wire line;
- explain why a balun is used between balanced and unbalanced parts; and
- choose practical feedline and connectors for common station layouts.

## What a feedline does

A feedline carries RF energy between station blocks: usually the transmitter or tuner at the shack end and the antenna at the far end. In receiving, the same path carries tiny RF voltages from the antenna back to the receiver.

The line has a characteristic impedance, often written as Z0. This is not just the ohms you would read with an ordinary DC ohmmeter. Z0 comes from the line's geometry and insulation: conductor spacing, conductor diameter, and dielectric material. If the load at the far end suits the line, energy is absorbed with minimal reflection.

### Worked example: line length and Z0

Suppose a roll of fifty-ohm coax is cut into a 12 m piece for a portable station and an 8 m piece for a home station. Both pieces are still fifty-ohm coax because cutting the cable did not change the relationship between the centre conductor, dielectric, and shield.

The shorter piece may have less total loss, but its characteristic impedance is still the same kind of line.

## Coaxial cable

Coaxial cable, usually called coax, has a centre conductor, insulation around that conductor, and a surrounding shield. The shield helps keep RF energy inside the cable and helps keep external noise out. Most modern amateur transceivers are designed around fifty-ohm coaxial connections.

Coax is unbalanced because one side is normally the shield and is often connected to equipment ground. That makes it convenient near equipment, through walls, near masts, and near some metal supports. It is also the usual feedline when the route must tolerate moisture, ice, or casual contact with building materials.

Common connector names matter because you will see them on real radios:

| Connector | Common beginner encounter | Practical note |
|---|---|---|
| PL-259 / UHF | Many HF transceivers and larger coax jumpers | Familiar and rugged, but weatherproofing is still your job. |
| BNC | Test gear and low-power portable equipment | Quick connect and disconnect; often used for instruments. |
| SMA | Many handheld radios | Small threads; avoid cross-threading and sideways strain. |
| Type N | Outdoor VHF/UHF and higher-quality coax runs | Designed with better weather resistance and RF performance. |

## Balanced lines: twin-lead, window line, and open-wire line

Balanced feedline uses two conductors with equal and opposite RF currents. Twin-lead and window line hold the conductors in plastic insulation. Open-wire line keeps the conductors separated by insulating spreaders and mostly air.

Balanced line can be very low loss, especially when installed in open air and kept away from metal. The tradeoff is that nearby metal, wet branches, gutters, tower legs, or a long run against a fence can disturb the fields around the line. A balanced line normally wants to run clear of conductive objects.

Open-wire line often handles mismatch with less heating than small coax. That does not mean every station should use it. It means that an installation with space, supports, and a suitable tuner can benefit from it.

## Balanced and unbalanced parts

A centre-fed dipole is a balanced antenna. A coax cable is unbalanced. A balun, short for balanced-to-unbalanced, helps connect those worlds. A balun can also reduce unwanted current on the outside of the coax shield, which helps keep the feedline from becoming part of the antenna.

### Worked example: feeding a simple dipole

Imagine a backyard dipole fed by fifty-ohm coax. The coax shield would like to be the equipment-ground side of an unbalanced line. The dipole legs, however, should carry equal and opposite RF currents. A balun at the antenna feed point helps the coax feed the dipole symmetrically.

## Choosing a feedline for the route

A good feedline choice starts with the route, not with a catalogue page.

- If the line must pass near metal siding, along a mast, or through a wall, coax is usually the forgiving choice.
- If the line can be kept in clear air from the antenna to a tuner with a balanced output, open-wire line can be very efficient.
- If the route will ice over or rub against objects, coax is mechanically easier to protect.
- If VHF or UHF loss matters, choose a larger or lower-loss coax rather than the smallest convenient cable.
- Keep connectors clean and tight so small contact resistance does not become heat, noise, or intermittent operation.

## Try it

1. A fifty-ohm coax jumper is shortened from 9 m to 5 m. Its total loss changes, but its characteristic impedance remains fifty ohms.
2. A window-line run is draped along a steel railing. Move it away from the metal or choose coax for that section.
3. A handheld antenna connector feels stiff. Stop and realign the SMA threads instead of forcing it.
4. A dipole is fed with coax and the shack microphone tingles during transmit. A feed-point balun or common-mode choke is a likely troubleshooting step.
5. A wet garden route must lie close to soil for part of the run. Coax is the practical feedline for that section.

## Radio connection

Feedline decisions show up as everyday station behaviour. A clean coax run can make a mobile VHF station simple and dependable. A carefully installed open-wire line can keep HF losses low on several bands. A poorly chosen or poorly routed line can waste transmitter power, bring RF into the operating position, or make tuning settings change when the weather changes.

When you troubleshoot, think in blocks: transmitter, short jumper, meter, tuner, main feedline, balun or choke, antenna feed point, and antenna. A fault in any block can look like an antenna problem until you isolate it.

## Common mistakes

- Treating characteristic impedance as if it were measured with a DC ohmmeter.
- Assuming a shorter feedline and a different feedline impedance are the same idea.
- Running balanced line tight against metal and expecting it to behave as though it were in open air.
- Putting a balun at the radio end when the balanced-to-unbalanced change actually happens at the antenna feed point.
- Forgetting that connector condition is part of RF performance.

## Illustration brief

Alt text: Three feedline cross-sections showing coax, window line, and open-wire line, with arrows from transceiver to antenna.

Description: Draw a simple ink-brush station chain. At left, a transceiver connects to three labelled feedline sketches: coax with centre conductor and shield, window line with two flat embedded wires, and open-wire line with two wires separated by small spreaders. At right, show a dipole with a small balun symbol at the feed point. Use callouts for "shielded and unbalanced," "balanced in plastic," and "balanced in open air."

## Summary

- A feedline guides RF energy between the radio and the antenna.
- Characteristic impedance depends on the line's construction and dielectric, not on ordinary DC resistance.
- Coax is shielded, unbalanced, and practical near equipment and metal.
- Twin-lead, window line, and open-wire line are balanced lines that need clear routing.
- A balun connects balanced and unbalanced parts and can help control common-mode current.
- Connectors, moisture, ice, and nearby metal are part of the feedline choice.
