---
type: lesson
id: L-003-08
moduleId: M3
categoryIds:
  - B-003
title:
  en: "Access, grounding, lightning, and RF safety"
  fr: null
covers:
  - B-003-018
  - B-003-019
  - B-003-020
  - B-003-021
objectives:
  - "Prevent unauthorized station use at home and mobile."
  - "Apply grounding, bonding, fusing, and shock-protection practices."
  - "Protect equipment from lightning and cable surges."
  - "Recognize extra precautions for UHF and microwave work."
prerequisites:
  - L-003-07
estimatedMinutes: 45
quizIds:
  - QZ-L-003-08-A
status: draft
---
# Access, grounding, lightning, and RF safety

A radio station has electrical energy, RF energy, and physical hazards in one place. Good safety practice is not a single part you buy; it is a system of access control, grounding, bonding, fusing, lightning planning, tower precautions, and RF exposure awareness.

This lesson is study guidance, not installation engineering advice. For real station wiring, towers, lightning protection, and exposure assessment, follow Canadian electrical requirements, manufacturer instructions, qualified trade practice, and Health Canada Safety Code 6 concepts for limiting RF exposure.

## Learning objectives

By the end of this lesson, you can:

- prevent unauthorized use of home and mobile stations;
- recognize electrical shock and short-circuit hazards;
- explain single-point grounding, bonding, chassis grounding, and fuse ratings;
- choose conservative lightning and antenna-work safety practices; and
- reduce RF exposure around indoor, handheld, UHF, microwave, and high-gain antennas.

## Station access and electrical shock

Station control begins with preventing unauthorized operation. At home, a key-operated switch or another positive power-control method is much stronger than a warning sign. In a vehicle, removing the microphone or control head can be more effective than simply turning the radio off because the radio is no longer ready to transmit.

Electrical shock risk depends on the path through the body, current, voltage, time, and conditions such as wet skin. Very small currents through the chest can be fatal. Do not troubleshoot live mains-operated supplies unless you are qualified and equipped to do so. Before opening equipment, turn it off, unplug it, and understand that capacitors may still hold charge.

If someone is in contact with high voltage, do not become the second victim. De-energize the source if you can do so safely, call emergency help, and provide first aid only when it is safe and within your training.

### Worked example: making a home station unavailable

A family workstation shares a room with a transceiver. The operator wants a simple way to prevent accidental transmitting when visitors use the desk.

- Turn off the radio and disable the main station power path with a positive control.
- Store the microphone or key where visitors cannot casually connect it.
- Do not rely on a paper warning sign as the only barrier.

The goal is to remove the ability to transmit, not merely to ask people not to touch it.

## Grounding and bonding

Grounding and bonding are related but not identical. Grounding connects equipment to earth or to the electrical safety grounding system as required. Bonding connects metal parts together so dangerous voltage differences are reduced. In a station, chassis ground terminals should meet at a single-point ground or bonding panel rather than wandering through long daisy chains.

All ground electrodes on a property should be bonded together with heavy conductors according to established practice. Separate unbonded electrodes can rise to different voltages during a fault or lightning event, creating a dangerous path through station equipment.

RF grounding has an extra complication: a long wire that looks like a ground at DC can have high impedance at radio frequencies. A third-floor wire running down a building may not cure RF burns at the operating desk. The real fix may involve antenna balance, common-mode choking, a better bonding layout, or moving the antenna system.

### Worked example: single-point station bonding

A small station has a transceiver, tuner, power supply, and coax entry panel.

- Bond each chassis to one station ground bar with short, direct conductors.
- Bond the entry panel to the same grounding system used for the building electrodes.
- Keep RF return currents off microphone cables and computer leads by using feedline chokes where needed.

A neat star-like bond is easier to inspect than a chain that depends on every device-to-device jumper.

## Fuses, chassis safety, and stored charge

Fuses have current and voltage ratings. The current rating controls when the fuse opens. The voltage rating says what voltage the fuse can interrupt safely without sustaining an arc. Replacing a specified fuse with a higher current rating defeats the protection and can turn a fault into equipment damage or fire.

The green conductor in a three-wire AC cord bonds the equipment chassis to protective earth. If a fault connects the hot conductor to the chassis, the safety ground provides a low-impedance fault path so protection can operate and the chassis is less likely to remain energized.

Power-supply filter capacitors can retain charge after the unit is unplugged. Use the manufacturer procedure or a properly insulated discharge tool with an inline resistor. Do not use a screwdriver as a casual shorting tool; it can arc, damage parts, or injure the person holding it.

### Worked example: opening an offline supply

A qualified repair mentor supervises a student inspecting an unplugged supply.

- Confirm the power cord is unplugged and the unit cannot be accidentally energized.
- Open the cabinet only after the safe work area is prepared.
- Discharge filter capacitors with an insulated resistor tool and verify with a meter.
- Keep one hand away from the chassis area while measuring, when measurement is necessary and safe.

The first action inside is to make stored energy safe, not to start replacing parts.

## Lightning, towers, and antenna contact

Lightning protection is a system: bonding, grounding, surge protectors, cable routing, and disconnection plans all work together. A coax surge protector belongs outside near the grounding entry point, not behind the radio as the first line of defence. When the station is not in use, grounding or disconnecting antenna and rotator cables helps reduce damage risk. For severe storms, disconnecting equipment from power and antenna cables is the most conservative protection.

No amateur installation can be made lightning-proof. Plan so a surge has a low-impedance path outside the operating position, and do not operate or service antennas during storms.

Antenna work adds fall and falling-object hazards. Use approved fall-arrest equipment for tower work, and wear a hard hat when assisting below. Horizontal wires, open-wire feedline, ground-mounted verticals, and antenna feed points must be located or guarded so people cannot touch energized RF conductors during transmitting.

### Worked example: feedline entry plan

A backyard station brings coax and rotator cable through a wall.

- Put the entry panel outside or at the wall penetration where conductors enter.
- Bond the panel and surge protectors to the building grounding system.
- Route cables so a surge is not invited through the operating desk first.
- Disconnect radios from cables and mains power when the station is shut down for storm season or travel.

The protector location matters because the surge should be diverted before it reaches indoor equipment.

## RF exposure and nearby people

RF energy can heat body tissue when exposure is high enough. Eyes deserve particular care because they dissipate heat poorly compared with many other tissues. At UHF and microwave frequencies, antennas and amplifier openings can put significant RF energy close to people, so keep antennas away from eyes and make sure amplifiers cannot be energized while shielding is removed.

Power density falls rapidly with distance in free space, so separation is a powerful safety tool. Keep handheld antennas away from your head and from other people while transmitting. Put UHF transmitting antennas where people cannot approach them during operation. Locate indoor antennas as far as practical from occupied living spaces, and mount directional high-gain antennas so their main beam is not aimed into nearby occupied structures.

Health Canada Safety Code 6 is the general Canadian framework for RF exposure limits. This lesson does not invent numeric limits or replace a proper exposure evaluation. When in doubt, reduce power, increase distance, shorten transmission time, use lower-gain antennas near people, or move the antenna outdoors and higher.

### Worked example: indoor antenna decision

An apartment operator tests a compact indoor antenna for low-power contacts.

- Place the antenna away from the chair, bed, and common walking paths.
- Use the lowest power that reliably completes the contact.
- Do not let visitors or pets approach the antenna while transmitting.
- Reconsider the setup if a higher-gain antenna or amplifier is added.

Indoor antennas can work, but the safety margin comes from distance, lower power, and controlled access.

## Try it

1. A vehicle radio is parked at a community event. What simple step reduces unauthorized use? Remove or secure the microphone or control head so the transmitter is not ready to use.
2. A long station "ground" wire still allows RF burns on transmit. What does that suggest? The wire may have high RF impedance, so common-mode current and antenna balance should be checked.
3. Why should a replacement fuse keep the specified ratings? A larger current rating may not open during a fault, and an inadequate voltage rating may not interrupt safely.
4. Where should a coax surge protector be placed for best lightning practice? At the outside entry point, as close to the grounding system as practical.
5. How do you reduce RF exposure from a handheld radio? Hold the antenna separated from your head and from bystanders, and use only the power needed.

## Radio connection

Safety choices affect station performance too. Good bonding can reduce hum and RF feedback. Correct fusing protects mobile wiring. Proper antenna placement keeps people away from RF conductors and often improves the signal by moving the antenna into a clearer location. A station that is safe to inspect is easier to maintain and less likely to cause interference.

## Common mistakes

- Relying on signs instead of removing power or controls.
- Touching a person who may still be energized by high voltage.
- Creating separate unbonded ground rods for different station parts.
- Using a bigger fuse to stop nuisance blowing without finding the fault.
- Putting a lightning protector at the radio end of a cable run as the only protection.
- Treating handheld and indoor antennas as harmless because they are convenient.

## Illustration brief

Alt text: A station safety layout shows locked power control, single-point bonding, outside surge protection, and RF separation from people.

Description: Draw an original room-and-wall cross-section. Inside, show a transceiver, supply, and tuner bonded to one ground bar. At the wall, show an outside coax entry panel with surge protectors bonded to the building grounding system. Add a locked power switch at the station desk, a disconnected microphone icon, a storm-disconnect note, and people standing outside a shaded RF keep-clear area around an antenna.

## Summary

- Prevent unauthorized transmitting by controlling power and removable controls, not merely by posting warnings.
- Turn off and unplug mains equipment before fault checks, and respect stored charge in capacitors.
- Bond station equipment and grounding electrodes to reduce dangerous voltage differences.
- Use correct fuse ratings, chassis safety grounding, and source-side mobile fusing.
- Lightning protection combines outside entry protection, bonding, grounding, cable handling, and conservative disconnection.
- RF exposure safety depends on distance, power, antenna gain, operating time, and keeping people away from energized antennas.
