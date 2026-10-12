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

A radio usually does not connect straight to the antenna element. RF energy travels from the transceiver, through a feedline, to the antenna feed point. On receive, the same line carries very small RF signals back to the receiver.

A feedline should guide RF energy instead of becoming an unwanted radiator. The best feedline depends on impedance, balance, loss, weather, nearby metal, and connectors.

## Learning objectives

By the end of this lesson, you can:

- describe what a transmission line does in an amateur station;
- explain characteristic impedance without confusing it with DC resistance;
- compare coaxial cable, twin-lead or window line, and open-wire line;
- explain why a balun is used between balanced and unbalanced parts; and
- choose practical feedline and connectors for common station layouts.

## What a feedline does

A feedline carries RF energy between station blocks. The station end may be a transmitter, receiver, tuner, or meter. The antenna end is the feed point.

A transmission line has characteristic impedance, often written as Z0. This is not the resistance you would read with an ordinary DC ohmmeter. Z0 comes from the line's shape and insulation: conductor spacing, conductor diameter, and dielectric material.

When the load at the far end suits the line, energy is absorbed with minimal reflection. When the load does not suit the line, some energy is reflected back toward the source.

### In the real world: cutting coax does not change Z0

A roll of fifty-ohm coax is cut into a 12 m piece and an 8 m piece. Both pieces are still fifty-ohm coax.

Cutting length did not change the centre conductor, dielectric, or shield spacing. The shorter piece may have less total loss, but it is not a different impedance line.

## Coaxial cable

Coaxial cable, usually called coax, has a centre conductor, insulation around that conductor, and a surrounding shield. The shield helps keep RF energy inside the cable and helps keep external noise out.

Most modern amateur transceivers use fifty-ohm coaxial connections. TV and cable-television systems in homes often use seventy-five-ohm coax. That contrast is useful background, but amateur transmitters, dummy loads, and standing wave ratio, or SWR, meters commonly expect fifty ohms.

Coax is unbalanced because one side is normally the shield and is often connected to equipment ground. That makes coax convenient near equipment, through walls, near masts, and near metal supports. It is also practical when the route must tolerate moisture, ice, or casual contact with building materials.

### In the real world: TV coax and radio coax

A house may already have seventy-five-ohm TV coax in the walls. A mobile radio, HF transceiver, or dummy load will usually expect fifty ohms.

For a receive-only experiment, many cable types may pass a signal. For transmitting, choose the impedance and power rating the radio system needs. Do not assume every cable with a coax connector is the right feedline.

### Common connector names

| Connector | Common beginner encounter | Practical note |
|---|---|---|
| PL-259 / UHF | Many HF transceivers and larger coax jumpers | Familiar and rugged, but weatherproofing is still your job. |
| BNC | Test gear and low-power portable equipment | Quick connect and disconnect; often used for instruments. |
| SMA | Many handheld radios | Small threads; avoid cross-threading and sideways strain. |
| Type N | Outdoor VHF/UHF and higher-quality coax runs | Designed with better weather resistance and RF performance. |

## Balanced lines: twin-lead, window line, and open-wire line

Balanced feedline uses two conductors with equal and opposite RF currents. Twin-lead and window line hold the conductors in plastic insulation. Open-wire line keeps the conductors separated by insulating spreaders and mostly air.

Balanced line can have very low loss when it is installed in open air and kept away from metal. Nearby metal, wet branches, gutters, tower legs, or a long run against a fence can disturb the fields around the line. A balanced line normally wants clear space.

Open-wire line often handles mismatch with less heating than small coax. That does not mean every station should use it. It means a station with space, supports, and a suitable tuner can benefit from it.

## Balanced and unbalanced parts

A centre-fed dipole is a balanced antenna. A coax cable is unbalanced. A balun, short for balanced-to-unbalanced, helps connect those two worlds. A balun can also reduce unwanted current on the outside of the coax shield.

### Worked example: feeding a simple dipole

A backyard dipole is fed by fifty-ohm coax. The dipole legs should carry equal and opposite RF currents. The coax shield, however, is part of an unbalanced line.

A balun at the antenna feed point helps the coax feed the dipole symmetrically. It belongs where the balanced antenna meets the unbalanced feedline.

## Choosing a feedline for the route

Start with the route, not a catalogue page.

- If the line must pass near metal siding, along a mast, or through a wall, coax is usually the forgiving choice.
- If the line can be kept in clear air from the antenna to a tuner with a balanced output, open-wire line can be efficient.
- If the route will ice over or rub against objects, coax is mechanically easier to protect.
- If VHF or UHF loss matters, choose a larger or lower-loss coax rather than the smallest convenient cable.
- Keep connectors clean and tight so small contact resistance does not become heat, noise, or intermittent operation.

## Try it

1. A fifty-ohm coax jumper is shortened from 9 m to 5 m. What happens to its characteristic impedance? It remains fifty ohms because the cable geometry and dielectric did not change.
2. A window-line run is draped along a steel railing. What should you change? Move it away from the metal or choose coax for that section.
3. A handheld antenna connector feels stiff. What is the safe next action? Stop and realign the SMA threads instead of forcing them.
4. A dipole is fed with coax and the shack microphone tingles during transmit. What feed-point device may be missing? A balun or common-mode choke is a likely troubleshooting step.
5. A wet garden route must lie close to soil for part of the run. Which feedline type is practical there? Coax is the practical choice for that route.

## Radio connection

Feedline choices show up as station behaviour. A clean coax run can make a mobile VHF station dependable. Carefully installed open-wire line can keep HF losses low on several bands. A poor route can waste power, bring RF into the operating position, or make tuning change with the weather.

When you troubleshoot, think in blocks: transmitter, jumper, meter, tuner, main feedline, balun or choke, antenna feed point, and antenna.

## Common mistakes

- Treating characteristic impedance as if it were measured with a DC ohmmeter.
- Assuming a shorter feedline and a different feedline impedance are the same idea.
- Running balanced line tight against metal and expecting it to behave as though it were in open air.
- Putting a balun at the radio end when the balanced-to-unbalanced change happens at the antenna feed point.
- Forgetting that connector condition is part of RF performance.

::figure feedline-types-balun
Alt text: Three feedline cross-sections showing coax, window line, and open-wire line, with arrows from transceiver to antenna.
Text equivalent:
- Coax has a centre conductor and shield; it is shielded and unbalanced.
- Window line has two parallel conductors held in plastic; it is balanced.
- Open-wire line has two separated wires on spreaders; it is balanced in open air.
- A balun belongs at the dipole feed point where the balanced antenna meets unbalanced coax.
::

## Illustration brief

Alt text: Three feedline cross-sections showing coax, window line, and open-wire line, with arrows from transceiver to antenna.

Description: Draw a simple ink-brush station chain. At left, a transceiver connects to three labelled feedline sketches: coax with centre conductor and shield, window line with two flat embedded wires, and open-wire line with two wires separated by small spreaders. At right, show a dipole with a small balun symbol at the feed point. Use callouts for "shielded and unbalanced," "balanced in plastic," and "balanced in open air."

## Summary

- A feedline guides RF energy between the radio and the antenna.
- Characteristic impedance depends on construction and dielectric, not ordinary DC resistance.
- Coax is shielded, unbalanced, and practical near equipment and metal.
- Amateur transmitters commonly use fifty-ohm coax; home TV systems often use seventy-five-ohm coax.
- Twin-lead, window line, and open-wire line are balanced lines that need clear routing.
- A balun connects balanced and unbalanced parts and can help control common-mode current.
