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

A station power system has two jobs: deliver the right voltage and current during normal operation, and fail safely when something goes wrong. A transceiver may look like low-voltage equipment, but batteries and DC supplies can deliver enough current to melt insulation or start a fire if wiring is not protected.

This lesson connects battery behaviour, power-supply selection, wiring voltage drop, fusing, and ripple to the signal quality topics you just studied.

## Learning objectives

By the end of this lesson, you can:

- identify batteries as DC sources with positive and negative terminals;
- compare rechargeable battery types for station use;
- predict how series and parallel battery connections affect voltage and capacity;
- choose a DC supply by current capability as well as voltage; and
- explain why ripple, voltage drop, and poor filtering can affect transmitted signals.

## Battery basics

A battery is a source of electromotive force. One terminal is marked positive and the other is marked negative, so polarity matters when connecting radios, chargers, and accessories. A rechargeable battery is often called a storage battery because electrical energy can be put back into it during charging.

Common station batteries include lead-acid, nickel-metal hydride (NiMH), and lithium-based packs. A standard automobile starter battery is nominally 12 V, but its low voltage does not make it harmless because it can deliver very high fault current. NiMH cells are often preferred over ordinary alkaline cells when rechargeability matters; that does not mean they have higher voltage. A NiMH cell is typically about 1.2 V nominal, lower than a fresh alkaline cell of the same size, and used cells still require proper recycling or disposal. Lithium-based packs are popular for portable operation because they can provide high capacity for their mass, but they require the charger, protection, and handling specified for that chemistry. Never short-circuit a battery. Even a low-voltage battery can supply very high current into a short.

A battery is not an ideal voltage source. It has internal resistance, so its terminal voltage drops when current is drawn. The drop becomes more obvious with high current, cold temperature, discharged state, small wiring, or a tired battery.

### Worked example: voltage sag on transmit

A portable radio receives normally from a battery pack, but the display dims when transmitting.

- The transmitter draws much more current than the receiver.
- Internal resistance and lead resistance cause a voltage drop at higher current.
- The first checks are battery charge state, connector condition, wire size, and whether the battery is rated for that current.

Turning up RF power would increase current draw and can make the symptom worse.

## Capacity, series, and parallel connections

Battery capacity is commonly described in ampere-hours. It is a planning number, not a promise that every load receives the same runtime. If the load current exceeds the rating conditions, the battery discharges faster than the simple label calculation suggests.

Series connection adds voltage while capacity in ampere-hours stays that of one matched string. Parallel connection keeps the voltage the same while adding ampere-hour capacity, assuming properly matched and safely protected batteries.

Text formulas:

- Series: `V_total = V1 + V2 + ...`; ampere-hour capacity stays that of one matched string.
- Parallel: voltage stays the same; `Ah_total = Ah1 + Ah2 + ...` for safely matched parallel batteries.

### Worked example: original battery bank

Two matched 11.1 V, 9 Ah packs are used for a temporary receiver project.

- In series, the result is 22.2 V at 9 Ah.
- In parallel, the result is 11.1 V at 18 Ah.

Only connect batteries in ways approved for their chemistry and protection system. Do not improvise lithium charging or paralleling arrangements.

## Station DC supplies

Many amateur transceivers are designed for a nominal low-voltage DC input from a regulated supply. When selecting a supply, the output current capability is one of the most important specifications. The supply must handle the transmitter's peak current demand without the voltage sagging below the radio's requirement. Canadian homes are commonly supplied with nominal 120 V and 240 V AC power; a station DC supply converts mains AC to the DC voltage required by the radio.

A linear supply is usually heavier and less efficient than a switching supply, but it may produce less RF noise. A switching supply is usually smaller, lighter, and more efficient, but it carries a higher RF-noise risk if it is poorly designed, faulty, or installed without attention to filtering and layout. Either type can work well if it is properly rated, installed, and quiet in your station.

A simple supply often has a transformer, rectifier, and filter capacitor. If the filtering or regulation is poor, residual AC ripple can get into the transmitter. In CW, varying voltage can contribute to chirp. In voice, ripple can show up as low-frequency hum on the transmitted signal.

### In the real world: radio current is not RF output power

A transceiver manual may list 13.8 V DC input and 19 A transmit current. The whole-radio DC supply draw at that current is:

- Given: E = 13.8 V; I = 19 A.
- Find: DC input power to the whole radio.
- Formula: P = I x E.
- Substitute: P = 19 A x 13.8 V.
- Answer: P = 262.2 W.
- Sanity check: this is supply draw for the radio as equipment, not the regulatory DC input limit at the final RF stage.

Use the manufacturer's fuse rating and cable instructions. Do not derive a universal fuse size from advertised RF output power.

### Worked example: choosing current headroom

A transceiver manual lists a transmit current draw of 19 A on high power. Two supplies are available: one rated 18 A continuous and one rated 28 A continuous at the required voltage.

- The 18 A unit is below the listed transmit current, so it is not the right choice.
- The 28 A unit has headroom for transmit peaks and normal accessory loads.
- The voltage still must match the radio's requirement, and the supply must be fused and wired correctly.

### Memory trick: P over I E

- Helps remember: P = I x E, I = P / E, and E = P / I.
- Trick: put P above I and E. Cover the unknown.
- Limit: this simple aid fits DC station-supply examples. AC circuits with reactance need more care.

## DC wiring, voltage drop, and fuses

Current through a wire causes voltage drop. Long leads and small wire increase the drop. Heavy-gauge wire reduces it, which is why mobile transceivers often need substantial DC leads directly to the battery or a properly rated distribution point.

Fuses protect wiring, not just the radio. A fuse near the source protects the length of wire that follows it. In a vehicle installation, the positive lead from the battery should be fused near the battery so a damaged wire cannot carry uncontrolled fault current through the vehicle.

A fuse is not shock protection for the operator. It opens for excessive current in the circuit it protects. Keep separate habits for personal safety: de-energize equipment, avoid live mains work unless qualified, and keep RF conductors away from people.

### Worked example: checking wire drop

A mobile radio draws 17 A on transmit. The battery connection is 2.4 m away one way, and the chosen cable data says the wire drops 0.06 V per metre at that current.

- Current travels out and back, so use the round-trip length: `2 x 2.4 m = 4.8 m`.
- Total drop estimate = `4.8 m x 0.06 V per metre`.
- Total drop estimate = `0.288 V`.
- That is below a 0.4 V design limit for this original installation example.

The exact table depends on wire size and current, so calculate with the data for the wire you intend to use and include both the positive and negative lead lengths.

## Try it

1. A radio needs at least 11.8 V at its input during transmit. The field battery is 12.4 V under the planned transmit load, and the round-trip lead resistance is 0.035 Ω; transmit current is 8 A. Will the radio see enough voltage? The lead drop is `8 A x 0.035 Ω = 0.28 V`, so the radio sees about 12.12 V and clears the 11.8 V minimum by about 0.32 V.
2. A four-cell AA holder is changed from fresh alkaline cells to NiMH cells. What voltage change should you expect before checking the radio manual? The nominal pack voltage falls from about 6.0 V to about 4.8 V, so rechargeability does not imply higher voltage.
3. Two matched 10.8 V, 7 Ah packs are placed in series for an approved equipment test. What is the result? Voltage adds to 21.6 V, while capacity remains 7 Ah.
4. The same two packs are placed in parallel using a manufacturer-approved combiner. What is the result? Voltage remains 10.8 V, while capacity adds to 14 Ah.
5. A 2.0 m one-way DC run uses cable data of 0.04 V per metre at the planned current. Is the round-trip drop below a 0.20 V target? The round-trip length is 4.0 m, so the drop is 0.16 V and is below the target.

## Radio connection

Power problems often masquerade as radio problems. Chirp, hum, resets on transmit, and distorted audio can all start with voltage sag, ripple, undersized wire, or a supply operating beyond its current rating. Before blaming propagation or antennas, check the DC path from source to radio.

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
- Ripple, undersized wire, and missing source fuses can create signal-quality and fire hazards.
