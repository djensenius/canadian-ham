---
type: lesson
id: L-003-07
moduleId: M3
categoryIds:
  - B-003
title:
  en: "Batteries, DC supplies, and ripple"
  fr: null
covers:
  - B-003-016
  - B-003-017
objectives:
  - "Identify common station battery characteristics."
  - "Select supply current capacity for transceivers."
  - "Explain how poor filtering can affect transmitted signals."
prerequisites:
  - L-003-06
estimatedMinutes: 35
quizIds:
  - QZ-L-003-07-A
status: draft
---
# Batteries, DC supplies, and ripple

A station power system has two jobs. It must deliver the right voltage and current during normal operation. It must also fail safely when something goes wrong.

A transceiver may use low-voltage DC, but that does not make the wiring harmless. Batteries and DC supplies can deliver enough current to melt insulation or start a fire if wiring is not protected.

## Learning objectives

By the end of this lesson, you can:

- identify batteries as DC sources with positive and negative terminals;
- compare rechargeable battery types for station use;
- predict how series and parallel battery connections affect voltage and capacity;
- choose a DC supply by current capability as well as voltage; and
- explain why ripple, voltage drop, and poor filtering can affect transmitted signals.

## Battery basics

A battery is a source of electromotive force. One terminal is positive and the other is negative, so polarity matters. A rechargeable battery is often called a storage battery because charging puts energy back into it.

Common station batteries include lead-acid, nickel-metal hydride, or NiMH, and lithium-based packs. A standard automobile starter battery is nominally 12 V. It can still deliver very high fault current.

NiMH cells are often chosen when rechargeability matters. That does not mean they have higher voltage. A NiMH cell is typically about 1.2 V nominal, lower than a fresh alkaline cell of the same size.

Lithium-based packs can provide high capacity for their mass. They require the charger, protection, and handling specified for that chemistry. Never short-circuit a battery. Even a low-voltage battery can supply very high current into a short.

A battery is not an ideal voltage source. It has internal resistance, so its terminal voltage drops under load. The drop becomes larger with high current, cold temperature, discharged state, small wiring, or an old battery.

### In the real world: four cells for a portable accessory

A small accessory can use four 1.5 V cells in series.

- Given: four cells; each cell = 1.5 V; cell capacity = 2.0 Ah.
- Find: pack voltage and capacity.
- Formula: series voltages add; ampere-hour capacity stays that of one matched string.
- Substitute: voltage = 1.5 V + 1.5 V + 1.5 V + 1.5 V.
- Answer: voltage = 6.0 V at 2.0 Ah; energy = 6.0 V x 2.0 Ah = 12 Wh.
- Sanity check: series wiring raises voltage, not ampere-hour capacity.

Use only battery holders and chargers meant for the cell type.

### Worked example: voltage sag on transmit

A portable radio receives normally from a battery pack, but the display dims when transmitting.

- The transmitter draws much more current than the receiver.
- Internal resistance and lead resistance cause a larger voltage drop at higher current.
- First check battery charge state, connector condition, wire size, and current rating.

Turning up RF power would increase current draw and can make the symptom worse.

## Capacity, series, and parallel connections

Battery capacity is commonly described in ampere-hours. It is a planning number, not a guarantee that every load gets the same runtime. If the load current exceeds the rating conditions, the battery may discharge faster than the simple label suggests.

Series connection adds voltage. Ampere-hour capacity stays that of one matched string. Parallel connection keeps voltage the same and adds ampere-hour capacity, but only for properly matched and protected batteries.

Text formulas:

- Series: `V_total = V1 + V2 + ...`; ampere-hour capacity stays that of one matched string.
- Parallel: voltage stays the same; `Ah_total = Ah1 + Ah2 + ...` for safely matched parallel batteries.

### Worked example: approved parallel battery packs

Two matched 6 V, 10 Ah packs are connected in parallel with an approved combiner.

- Given: two matched packs; each pack = 6 V at 10 Ah.
- Find: combined voltage and capacity.
- Formula: parallel voltage stays the same; capacities add.
- Substitute: capacity = 10 Ah + 10 Ah.
- Answer: result = 6 V at 20 Ah; energy = 6 V x 20 Ah = 120 Wh.
- Sanity check: parallel wiring raises capacity, not voltage.

Only connect batteries in ways approved for their chemistry and protection system. Do not improvise lithium charging or paralleling.

## Station DC supplies

Many amateur transceivers are designed for nominal low-voltage DC from a regulated supply. Current capability is one of the most important supply ratings. The supply must handle transmit current without dropping below the radio's voltage requirement.

Canadian homes commonly provide nominal 120 V and 240 V AC power. A station DC supply converts mains AC to the DC voltage required by the radio.

A linear supply is usually heavier and less efficient than a switching supply. It may produce less RF noise. A switching supply is usually smaller, lighter, and more efficient. It can create RF noise if poorly designed, faulty, or installed without attention to filtering and layout.

A simple supply often has a transformer, rectifier, and filter capacitor. Poor filtering or regulation can let residual AC ripple into the transmitter. In CW, varying voltage can contribute to chirp. In voice, ripple can appear as low-frequency hum on the transmitted signal.

### In the real world: charger labels and radio supplies

A charger may say 9.0 V at 3.0 A. That is a 27 W charger, because P = I x E = 3.0 A x 9.0 V = 27 W.

A typical mobile transceiver needs a different kind of supply. If the manual lists 13.8 V DC and 19 A transmit current, the whole-radio supply draw is:

- Given: E = 13.8 V; I = 19 A.
- Find: DC input power to the whole radio.
- Formula: P = I x E.
- Substitute: P = 19 A x 13.8 V.
- Answer: P = 262.2 W.
- Sanity check: this is whole-radio supply draw. It is not the Canadian Basic DC-input limit, which applies to the transmitter final RF stage that supplies RF energy to the antenna.

A 262.2 W supply calculation does not mean the radio exceeds the Basic power limit. Follow the radio manual for supply current and fuse ratings.

### Worked example: choosing current headroom

A transceiver manual lists a transmit current draw of 19 A on high power. Two supplies are available: 18 A continuous and 28 A continuous at the required voltage.

- The 18 A unit is below the listed transmit current, so it is not the right choice.
- The 28 A unit has headroom for transmit peaks and normal accessory loads.
- The voltage still must match the radio's requirement.
- The supply and wiring must be fused correctly.

### Memory trick: P over I E

- Helps remember: P = I x E, I = P / E, and E = P / I.
- Trick: put P above I and E. Cover the unknown.
- Limit: this simple aid fits DC station-supply examples. AC circuits with reactance need more care.

## DC wiring, voltage drop, and fuses

Current through a wire causes voltage drop. Long leads and small wire increase the drop. Heavy-gauge wire reduces it. In American wire gauge numbering, a higher gauge number means a thinner wire. For a voltage-drop limit, choose the thinnest wire that still meets the limit; a heavier wire may work but may not be the minimum needed.

Fuses protect wiring and equipment from excessive current and heating. A fuse near the source protects the length of wire that follows it. In a vehicle installation, fuse the positive lead near the battery so a damaged wire cannot carry uncontrolled fault current through the vehicle.

A fuse is not shock protection for the operator. Use separate personal-safety habits: de-energize equipment, avoid live mains work unless qualified, and keep RF conductors away from people.

### In the real world: source fuse for a field battery

A field station uses a battery box feeding a radio through 2.5 m of positive lead and 2.5 m of negative lead. The radio manual specifies a 15 A fuse in the DC lead.

The battery is the high-current source. Put the specified 15 A fuse near the battery end of the positive lead, then run the protected lead to the radio. A fuse only at the radio end would leave the long battery lead less protected.

Use the fuse value and cable supplied or specified by the manufacturer unless a qualified design says otherwise.

### Worked example: checking wire drop

A mobile radio draws 17 A on transmit. The battery connection is 2.4 m away one way. Cable data says the wire drops 0.06 V per metre at that current.

- Given: one-way length = 2.4 m; round trip = 2 x 2.4 m = 4.8 m; drop = 0.06 V per metre.
- Find: total voltage drop.
- Formula: total drop = round-trip length x drop per metre.
- Substitute: total drop = 4.8 m x 0.06 V per metre.
- Answer: total drop = 0.288 V.
- Sanity check: that is below a 0.4 V design limit for this original example.

Use cable data for the actual wire and current, and include both positive and negative lead lengths. If a table lists several gauges that meet the drop limit, the minimum acceptable gauge is the thinnest one that still passes, not the heaviest cable in the table.

## Try it

1. A radio needs at least 11.8 V at its input during transmit. The field battery is 12.4 V under load. The round-trip lead resistance is 0.035 ohms, and transmit current is 8 A. Will the radio see enough voltage? The lead drop is 8 A x 0.035 ohms = 0.28 V, so the radio sees about 12.12 V.
2. A four-cell AA holder changes from fresh alkaline cells to NiMH cells. What voltage change should you expect before checking the manual? Nominal voltage falls from about 6.0 V to about 4.8 V.
3. Two matched 10.8 V, 7 Ah packs are placed in series for an approved equipment test. What is the result? Voltage adds to 21.6 V, while capacity remains 7 Ah.
4. The same two packs are placed in parallel using a manufacturer-approved combiner. What is the result? Voltage remains 10.8 V, while capacity adds to 14 Ah.
5. A 2.0 m one-way DC run uses cable data of 0.04 V per metre at the planned current. Is the round-trip drop below a 0.20 V target? Round-trip length is 4.0 m, so the drop is 0.16 V.

## Radio connection

Power problems often look like radio problems. Chirp, hum, resets on transmit, and distorted audio can start with voltage sag, ripple, undersized wire, or an overloaded supply. Before blaming propagation or antennas, check the DC path from source to radio.

## Common mistakes

- Treating low voltage as automatically harmless.
- Connecting lithium packs without the correct protection and charging method.
- Reading ampere-hours as if runtime were guaranteed at any current.
- Choosing a supply by voltage alone and ignoring current capacity.
- Assuming a small switching supply is quiet just because it powers the radio.
- Placing the only fuse at the radio end of a long battery lead.
- Treating the radio's RF output power as a fuse-size calculation.

## Illustration brief

Alt text: A battery, fuse, heavy DC leads, regulated supply, and ripple waveform show how station power reaches a transceiver.

Description: Draw an original station-power sketch. Show a battery or DC supply feeding a fuse close to the source, then heavy positive and negative leads to a transceiver. Add a small inset of a smooth DC line labelled "good regulation" and a wavy line labelled "ripple can cause hum or chirp." Include separate mini-icons for series and parallel battery connections.

## Summary

- Batteries provide DC EMF and have polarity; rechargeable batteries are storage batteries.
- Internal resistance causes terminal voltage to drop under load.
- Series battery connections add voltage; parallel connections add ampere-hour capacity when safely matched.
- Select station power supplies by voltage, current capability, noise behaviour, and safe installation.
- Charger power labels use P = I x E, but radio supplies must meet the radio manual's voltage, current, and fuse requirements.
- Ripple, undersized wire, and missing source fuses can create signal-quality and fire hazards.
- In wire-gauge numbering, higher numbers mean thinner wire; choose the thinnest gauge that still meets the voltage-drop limit.
