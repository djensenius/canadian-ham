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
  - L-006-04
estimatedMinutes: 45
quizIds:
  - QZ-L-003-08-A
status: draft
---
# Access, grounding, lightning, and RF safety

A radio station has electrical energy, RF energy, and physical hazards in one place. Good safety practice is not a single part you buy. It is a system of access control, grounding, bonding, fusing, lightning planning, tower precautions, and RF exposure awareness.

This lesson is study guidance, not installation engineering advice. For real station wiring, towers, lightning protection, and exposure assessment, follow Canadian electrical requirements, manufacturer instructions, qualified trade practice, and Health Canada Safety Code 6 concepts for limiting RF exposure.

## Learning objectives

By the end of this lesson, you can:

- prevent unauthorized use of home and mobile stations;
- recognize electrical shock and short-circuit hazards;
- explain single-point grounding, bonding, chassis grounding, and fuse ratings;
- choose conservative lightning and antenna-work safety practices; and
- reduce RF exposure around indoor, handheld, UHF, microwave, and high-gain antennas.

## Station access and electrical shock

Station control begins with preventing unauthorized operation. At home, a key-operated switch or another positive power-control method is stronger than a warning sign. In a vehicle, removing the microphone or control head can be more effective than turning the radio off.

Electrical shock risk depends on current path, current amount, voltage, time, and conditions such as wet skin. Currents on the order of 20 mA can be fatal when the path includes the chest, because the heart can be driven into ventricular fibrillation. Voltages around 30 V and above are usually treated as hazardous to humans, especially in wet or conductive conditions.

Do not troubleshoot live mains-operated supplies unless you are qualified and equipped. Before opening equipment, turn it off and unplug it. Capacitors may still hold charge. High-voltage supplies may include cabinet interlock switches that remove power when a cover opens. Never defeat an interlock, and never assume it discharged stored energy.

If someone is in contact with high voltage, do not become the second victim. De-energize the source if you can do so safely. Call emergency help. Provide first aid only when it is safe and within your training.

### In the real world: making a home station unavailable

A family workstation shares a room with a transceiver. The operator wants to prevent accidental transmitting when visitors use the desk.

- Turn off the radio and disable the main station power path with a positive control.
- Store the microphone or key where visitors cannot casually connect it.
- Do not rely on a paper warning sign as the only barrier.

The goal is to remove the ability to transmit, not merely to ask people not to touch it.

### In the real world: code and local authority

CSA C22.1, the Canadian Electrical Code, is a national model code. It becomes enforceable when a province or territory adopts an edition, often with local amendments.

The authority having jurisdiction is the local body or official that enforces the adopted electrical code. For station wiring, follow your provincial or territorial electrical code and that authority's requirements. A study lesson is not a substitute for a qualified electrician or inspector.

## Grounding and bonding

Grounding and bonding are related but not identical. Grounding connects equipment to earth or to the electrical safety grounding system as required. Bonding connects metal parts together so dangerous voltage differences are reduced.

In a station, all equipment should be included in the grounding and bonding plan. Chassis ground terminals should meet at a single-point ground or bonding panel. Avoid long daisy chains that depend on every device-to-device jumper.

All ground electrodes on a property should be bonded together with heavy copper grounding conductors according to established practice and local code. Separate unbonded electrodes can rise to different voltages during a fault or lightning event. That can create a dangerous path through station equipment.

A driven earth electrode is often copper-clad steel. The steel provides strength for driving. The copper surface provides corrosion-resistant conductive contact with soil. A bonding connection needs clean metal-to-metal contact, proper clamps or hardware, short conductors, and a continuity check.

RF grounding has an extra complication. A long wire that looks like a ground at DC can have high impedance at radio frequencies. A third-floor wire down a building may not cure RF burns at the desk. The fix may involve antenna balance, common-mode choking, a better bonding layout, or moving the antenna.

::figure grounding-lightning-rf-safety
Alt text: A left-to-right station safety layout shows indoor equipment bonded to a bar, a single-point entry, a surge arrestor, a ground rod bonded to the building grounding electrode system, and an outside antenna mast.
Text equivalent:
- Radio, tuner, and supply boxes bond down to a labelled bonding bar.
- Coax runs to a box labelled single entry, then to a surge box and the antenna mast.
- The surge box bonds to the bonding bar and to a labelled ground rod outside, and that rod bonds to the building grounding electrode system.
::



### In the real world: single-point station bonding

A small station has a transceiver, tuner, power supply, and coax entry panel.

- Bond each chassis to one station ground bar with short, direct conductors.
- Bond the coax entry panel to the same grounding system used for the building electrodes.
- Keep RF return currents off microphone and computer leads with feedline chokes where needed.
- Inspect the bond path for paint, corrosion, loose screws, or long loops.

A star-like bond is easier to inspect than a chain of jumpers.

### In the real world: painted metal is not a bond

A station ground bar shows high resistance to a radio chassis. The strap is tight, but it is clamped over painted metal.

A bond needs clean conductive contact, not just mechanical pressure. Clean the contact area to bare metal, use proper hardware, keep the bond short, and recheck continuity. A shiny strap can still fail if the contact surface is insulated.

## Fuses, chassis safety, and stored charge

Fuses have current and voltage ratings. The current rating controls when the fuse opens. The voltage rating says what voltage the fuse can interrupt safely without sustaining an arc. A higher-current replacement defeats protection and can turn a fault into equipment damage or fire.

The green conductor in a three-wire AC cord bonds the equipment chassis to protective earth. If a fault connects the hot conductor to the chassis, the safety ground provides a low-impedance fault path so protection can operate, and the chassis doesn't stay energized where someone could touch it.

Power-supply filter capacitors can retain charge after the unit is unplugged. Use the manufacturer's procedure or a properly insulated discharge tool with an inline resistor. Do not use a screwdriver as a casual shorting tool. It can arc, damage parts, or injure the person holding it.

### Misconception: a fuse protects people from every shock

- Mistaken idea: if equipment has a fuse, the operator is protected from electric shock.
- Correction: a fuse protects wiring and equipment from excessive current. Shock safety also needs grounding, bonding, de-energizing before work, proper enclosures, and safe work practices.

### In the real world: opening an offline supply

A qualified repair mentor supervises a student inspecting an unplugged supply.

- Confirm the power cord is unplugged and the unit cannot be accidentally energized.
- Prepare the safe work area before opening the cabinet.
- Discharge filter capacitors with an insulated resistor tool and verify with a meter.
- Use the one-hand rule for necessary measurements so accidental contact is less likely to put current across the chest.

The first action inside is to make stored energy safe.

## Lightning, towers, and antenna contact

Lightning protection is a system. Bonding, grounding, surge protectors, cable routing, and disconnection plans all work together. A coax surge protector belongs outside near the grounding entry point, not behind the radio as the first line of defence.

When the station is not in use, grounding or disconnecting antenna and rotator cables helps reduce damage risk. For severe storms, disconnecting equipment from power and antenna cables is the most conservative protection.

No amateur installation can be made lightning-proof. Plan so a surge has a low-impedance path outside the operating position. Do not operate or service antennas during storms.

Antenna work adds fall and falling-object hazards. Before any antenna repair, shut the transmitter down and separate the feedline from the station equipment. Grounding the antenna structure does not remove an RF source if the transmitter remains connected.

Use approved fall-arrest equipment for tower work. Wear a hard hat when assisting below. Horizontal wires, open-wire feedline, ground-mounted verticals, and antenna feed points must be located or guarded so people cannot touch energized RF conductors during transmitting. Touching an energized antenna or feed point can cause RF burns.

### In the real world: feedline entry plan

A backyard station brings coax and rotator cable through a wall.

- Put the entry panel outside or at the wall penetration where conductors enter.
- Bond the panel and surge protectors to the building grounding system.
- Route cables so a surge is not invited through the operating desk first.
- Disconnect radios from cables and mains power when the station is shut down for storm season or travel.

The protector location matters because the surge should be diverted before it reaches indoor equipment.

## RF exposure and nearby people

RF energy can heat body tissue when exposure is high enough. Eyes deserve care because they shed heat poorly compared with many other tissues. At UHF and microwave frequencies, keep antennas away from eyes while RF is applied. Before removing shielding from a UHF power amplifier, disable and secure the power path so it cannot start accidentally.

Power density falls rapidly with distance in free space. In a simple free-space point-source model, RF field strength falls in proportion to `1/d`. Power density falls in proportion to `1/d^2`. Doubling distance can greatly reduce exposure before you even consider duty cycle or antenna pattern.

### Worked example: compare power density at a distance

Use only the simple free-space point-source model here, not a real installation assessment. Compare a point at 3 m with a point at 6 m while source power stays fixed.

- Given: old distance = 3 m; new distance = 6 m.
- Find: new power density as a fraction of the old value.
- Formula: density ratio = (old distance / new distance) x (old distance / new distance).
- Substitute: ratio = (3 / 6) x (3 / 6).
- Answer: ratio = 0.25, or one quarter of the original power density.
- Sanity check: doubling distance spreads power over four times the area in this model.

Nearby antennas, reflections, and real patterns can depart from this simple model. Do not use the ratio alone to approve an occupied location.

### Faded practice: square the distance ratio

In that same model, compare points 4 m and 12 m from an unchanged source.

- Given: old distance = 4 m; new distance = 12 m.
- Find: new power density relative to the old point.
- Formula: density ratio = (old / new) x (old / new).
- Complete: ratio = (4 / 12) x (4 / 12) = ___ x ___ = ___.
- Sanity check: should tripling distance give one third or one ninth of the power density?

Fill the gaps before checking below.

### Check your work: square the distance ratio

The distance fraction is one third. Squaring it gives one ninth, about 0.111 of the original density. Field strength and power density use different distance relationships; this remains a simplified model.

### Keep people outside the RF hazard area

A low standing wave ratio, or SWR, is an equipment-match indication. It is not permission for people to stand close to an energized antenna. Keep handheld antennas away from your head and from other people while transmitting. Put UHF transmitting antennas where people cannot approach them during operation. Locate indoor antennas as far as practical from occupied living spaces. Better still, move the antenna outdoors and mount it as high as practical, out of reach. Mount directional high-gain antennas higher than nearby occupied structures so the main beam is not aimed through people in those structures.

Health Canada Safety Code 6 is the general Canadian framework for RF exposure limits. It covers controlled and uncontrolled exposure situations. No transmitter class is automatically outside RF exposure regulation. This lesson does not invent numeric limits or replace a proper exposure evaluation.

### In the real world: indoor antenna decision

An apartment operator tests a compact indoor antenna for low-power contacts.

- Place the antenna away from the chair, bed, and common walking paths.
- Use the lowest power that reliably completes the contact.
- Do not let visitors or pets approach the antenna while transmitting.
- Recheck the plan if a higher-gain antenna or amplifier is added.

Indoor antennas can work, but the safety margin comes from distance, lower power, and controlled access.

## Try it

1. A supply cover is opened and a cabinet interlock removes input power. What unsafe assumption must you avoid?

:::answer
Do not assume the unit is harmless; filter capacitors can still hold charge.
:::

2. A temporary control circuit measures 48 V in a damp work area. How should it be treated?

:::answer
Treat it as hazardous because it is above the usual 30 V shock threshold, and wet conditions can lower body resistance.
:::

3. A station bonding strap is clamped over painted, corroded metal. What should be corrected?

:::answer
Clean the contact area to bare metal, use proper bonding hardware, keep the bond short, and recheck continuity.
:::

4. A club schedules roof-antenna maintenance for the same afternoon that thunderstorms are forecast nearby. What conservative change should the team make?

:::answer
Postpone the work, shut the transmitter down, separate the feedline from station equipment before any repair, and keep antennas disconnected or grounded during storm conditions.
:::

5. An indoor antenna test is upgraded from a low-power whip to a directional antenna. What parts of the RF-safety plan should change?

:::answer
Recheck power, distance, access control, and beam direction.
:::

## Radio connection

Safety choices affect station performance too. Good bonding can reduce hum and RF feedback. Correct fusing protects mobile wiring. Proper antenna placement keeps people away from RF conductors and often improves signals by moving the antenna into a clearer location.

## Common mistakes

- Relying on signs instead of removing power or controls.
- Touching a person who may still be energized by high voltage.
- Creating separate unbonded ground rods for different station parts.
- Using a bigger fuse to stop nuisance blowing without finding the fault.
- Putting a lightning protector at the radio end of a cable run as the only protection.
- Starting antenna repair while the transmitter can still energize the feedline.
- Treating handheld and indoor antennas as harmless because they are convenient.
- Treating an SWR match as an RF exposure assessment.

## Illustration brief

Alt text: A left-to-right station safety layout shows indoor equipment bonded to a bar, a single-point entry, a surge arrestor, a ground rod bonded to the building grounding electrode system, and an outside antenna mast.

Description: Draw an original left-to-right station bonding sketch. Indoors, show the radio, tuner, and supply bonded to one labelled station bonding bar. At the wall, show the coax passing through a labelled single-point entry to a surge arrestor. Bond the entry and surge arrestor to the station bonding bar and to one outside ground rod, then bond that rod to the building grounding electrode system. Outside, show the coax continuing to an antenna on a mast.

## Summary

- Prevent unauthorized transmitting by controlling power and removable controls.
- Turn off and unplug mains equipment before fault checks, and respect stored charge in capacitors.
- Bond and ground station equipment and grounding electrodes to reduce dangerous voltage differences.
- Use correct fuse ratings, chassis safety grounding, and source-side mobile fusing.
- Before antenna repair, shut the transmitter down and separate the feedline from station equipment.
- Lightning protection combines outside entry protection, bonding, grounding, cable handling, and conservative disconnection.
- RF exposure safety depends on distance, power, antenna gain, operating time, and keeping people away from energized antennas.
- Safety Code 6 guides RF exposure evaluation when one is needed.
