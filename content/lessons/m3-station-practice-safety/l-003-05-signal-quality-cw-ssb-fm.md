---
type: lesson
id: L-003-05
moduleId: M3
categoryIds:
  - B-003
title:
  en: "Signal quality for CW, SSB, and FM"
  fr: null
covers:
  - B-003-011
  - B-003-012
  - B-003-013
objectives:
  - "Recognize CW chirp and how stable supply or oscillator design helps."
  - "Adjust SSB drive, processing, and microphone gain for clean audio."
  - "Explain FM deviation, squelch noise, and repeater audio levels."
prerequisites:
  - L-003-04
estimatedMinutes: 45
quizIds:
  - QZ-L-003-05-A
status: draft
---
# Signal quality for CW, SSB, and FM

A transmitter can be legal and still be hard to copy. It can also spread unwanted energy into nearby channels. Signal quality means setting the station for readability without clicks, drift, splatter, or distorted audio.

This lesson covers three common cases: keyed continuous wave, or CW; single-sideband voice, or SSB; and frequency-modulated voice, or FM. The modes differ, but the habit is the same. Keep the radio stable, set levels conservatively, and ask for clear reports after equipment changes.

## Learning objectives

By the end of this lesson, you can:

- describe chirp, key clicks, and oscillator drift in a CW signal;
- explain why amplitude modulation has a carrier and sidebands;
- account for RF amplifier efficiency as useful output plus heat;
- set SSB microphone gain and speech processing without overdriving the transmitter;
- use peak envelope power as the useful power idea for modulated voice; and
- match FM deviation, bandwidth, and microphone technique to the channel being used.

## Clean CW: stable carrier, shaped keying

CW usually sends Morse by turning an RF carrier on and off. A clean keyed signal has a steady frequency. Its keying edges are shaped so they are not too abrupt.

Chirp is a small frequency movement each time the transmitter is keyed. The far-end operator hears the note slide instead of starting cleanly. Chirp can point to supply voltage sag, oscillator pulling, or loose mechanical construction.

Key clicks are different. They sound like sharp ticks around the signal. They come from keying edges that are too abrupt. A key-click filter or proper shaping slows the edge enough to reduce splatter without making the Morse unreadable.

A variable-frequency oscillator lets a CW transmitter tune anywhere across a range, instead of being limited to the few frequencies of the crystals on hand. That is useful only if the oscillator is electrically and mechanically stable, so the carrier doesn't drift over time. Keep VFOs away from heat, loose hardware, and changing supply conditions.

### In the real world: diagnosing two CW reports

During a club practice net, one report says, "Your note slides at the start of each element." Another says, "I hear ticks above and below your signal."

- The sliding note points to chirp. Check supply regulation, oscillator loading, and mechanical stability.
- The ticks point to key clicks. Check keying edge shape or click filtering.
- A harmonic low-pass filter is still useful, but it will not stop an unstable oscillator from moving.

## AM envelope and sidebands

Amplitude modulation changes the RF envelope to carry information. A clean AM voice signal includes the carrier plus upper and lower sidebands. The occupied bandwidth is about twice the highest audio frequency being transmitted.

Text formula: AM bandwidth ≈ 2 x highest audio frequency.

If the transmitter passes wider audio, the sidebands extend farther from the carrier. If the transmitter is distorted, unwanted products can spread farther.

A final amplifier also has a power budget. DC input power that is not converted into RF output becomes mostly heat in the final stage. Efficiency is useful RF output divided by DC input. Real stages are less than 100% efficient, so they need heat sinking and conservative operation.

### Worked example: AM bandwidth estimate

An original bench demonstration limits audio to 2.4 kHz before feeding an AM exciter.

- Given: highest audio frequency = 2.4 kHz.
- Find: approximate AM bandwidth.
- Formula: AM bandwidth ≈ 2 x highest audio frequency.
- Substitute: bandwidth ≈ 2 x 2.4 kHz.
- Answer: bandwidth ≈ 4.8 kHz.
- Sanity check: AM has upper and lower sidebands, so the bandwidth is about twice the audio limit.

That estimate assumes a clean signal. Distortion or overdrive can make the occupied bandwidth worse.

## SSB: linear amplification and level control

Single sideband removes the carrier and one sideband. Most useful output is in the remaining sideband. Typical amateur SSB voice is about 2 kHz to 3 kHz wide and needs a linear RF power amplifier.

A non-linear amplifier does not follow the voice envelope faithfully. Speech becomes distorted, and unwanted products appear beside the signal.

A balanced modulator is an earlier block in many SSB transmitters. It suppresses the carrier and passes two sidebands. Suppressing the carrier lets more output power go into the sidebands that carry information. A later filter or phasing stage selects one sideband. Carrier suppression alone does not halve the bandwidth; one sideband must also be removed.

Peak envelope power, or PEP, is RF output power at the highest point of the voice envelope, averaged over the RF cycle at that instant. The practical meaning is simple. SSB power rises on voice peaks, so the crest of the envelope matters.

Automatic level control, or ALC, is a transmitter control system that limits drive on peaks. The ALC meter may move on syllables, but it should not be hammered to the end of its scale. ALC is not a receiver noise control.

Speech processing can raise average talk power while keeping peaks under control. Too much processing makes audio harsh and wider than needed.

### In the real world: setting SSB audio without splatter

A learner installs a new headset and checks the transmitter into a dummy load before calling CQ.

- Start with microphone gain lower than before.
- Speak at a normal distance and watch the ALC indication on syllable peaks.
- Increase gain only until peaks reach the manufacturer's recommended range.
- Add speech processing lightly.
- Ask a nearby station for a clean-audio and bandwidth report.

The goal is not the loudest meter reading. The goal is clear speech inside the intended bandwidth.

### Worked example: sideband frequency direction

In an original lower-sideband practice example, the suppressed carrier setting is 5 360 kHz and a single audio tone is 700 Hz.

- Given: carrier setting = 5 360 kHz; audio tone = 700 Hz = 0.700 kHz.
- Find: lower-sideband RF tone.
- Formula: LSB RF = carrier setting - audio tone.
- Substitute: LSB RF = 5 360 kHz - 0.700 kHz.
- Answer: LSB RF = 5 359.300 kHz.
- Sanity check: lower sideband energy appears below the carrier setting.

For upper sideband, the same tone would appear above the carrier setting.

## FM: deviation, squelch, and capture effect

FM carries audio by changing the carrier frequency around its assigned channel. The amount of swing from the centre frequency is deviation. Louder audio produces more deviation until the transmitter limiter or audio stages run out of clean range.

If the microphone fails, there is no modulating audio. The transmitter sends an unmodulated carrier.

Phase modulation is closely related to FM because changing phase over time changes instantaneous frequency. Both are angle-modulation methods. AM is different because it changes carrier amplitude.

For repeaters and local channels, transmitter deviation should match the system. Too little deviation sounds quiet. Too much sounds loud, rough, or distorted, and can occupy too much spectrum. Speaking too close to the microphone can cause overdeviation even when the RF frequency is correct.

Text formula: FM bandwidth by Carson's rule ≈ 2 x (peak deviation + highest audio frequency).

For example, 2.5 kHz deviation with 3 kHz audio estimates to about 2 x (2.5 + 3) = 11 kHz. A typical FM voice signal is somewhere between about 11 kHz and 16 kHz wide, so plan for a channel many kilohertz wide. Higher deviation produces a wider channel by the same formula. Canadian occupied-bandwidth limits below 28 MHz leave only a few kilohertz for voice operation, so wide FM voice does not fit that plan.

FM is popular for local VHF and UHF voice because it gives a good signal-to-noise ratio even when the received signal is fairly weak. An FM receiver often has high gain before the discriminator. With no usable signal present, that gain makes speaker noise loud unless squelch mutes it. When multiple FM signals are present, the receiver tends to demodulate the strongest one. This is the capture effect.

### Worked example: repeater audio report

A repeater operator reports, "Your signal is full quieting, but your words are thin and quiet." The RF path is adequate, so increasing RF power is not the first fix.

Check deviation, microphone gain, and microphone distance. If the next report says "loud and rough," back off the audio level.

## Try it

1. An AM bench exciter is limited to 2.8 kHz highest audio before it reaches the modulator. What occupied bandwidth should you plan for? Estimate 2 x 2.8 kHz = 5.6 kHz.
2. Why does a clean AM voice signal need spectrum on both sides of the carrier? The changing envelope creates upper and lower sidebands, and both carry audio information.
3. An upper-sideband exciter is set to 14 250 kHz and fed a 1.2 kHz tone. Where is the RF? USB RF = 14 250 kHz + 1.200 kHz = 14 251.200 kHz.
4. A lower-sideband exciter is set to 3 925 kHz and fed a 600 Hz tone. Where is the RF tone? 600 Hz is 0.600 kHz, so LSB RF = 3 925 kHz - 0.600 kHz = 3 924.400 kHz.
5. Before joining an FM net with a borrowed hand microphone, why make a short local audio check? A different microphone can change deviation and audio level even when the RF path is fine.

## Radio connection

Clean-signal practice prevents interference. A few minutes spent setting CW keying, SSB ALC, or FM deviation can protect adjacent users from noise you may not hear in your own speaker. When you change microphones, interfaces, power supplies, or audio settings, test carefully and ask for a specific report.

## Common mistakes

- Treating chirp and key clicks as the same fault.
- Assuming more microphone gain always improves readability.
- Running speech processing so hard that the signal becomes wide and harsh.
- Reading PEP as average DC input power rather than RF envelope peak power.
- Using RF power to fix an FM audio-level problem.
- Forgetting that a quiet FM receiver between signals is usually the squelch doing its job.

## Illustration brief

Alt text: Three small panels compare a clean CW carrier, an overdriven SSB voice envelope, and an FM carrier swinging too far from centre.

Description: Draw an original three-panel teaching graphic. Panel one shows a CW carrier turning on smoothly and staying at one frequency, with a separate jagged edge labelled "click risk." Panel two shows an SSB envelope whose peaks stay below an ALC limit line, beside a clipped envelope marked "splatter." Panel three shows an FM centre line with modest deviation arrows and larger arrows labelled "overdeviation."

## Summary

- Chirp is frequency movement during keying; key clicks come from abrupt keying edges.
- AM changes envelope amplitude and produces a carrier plus two sidebands; AM bandwidth is about 2 x highest audio frequency.
- Final-amplifier DC input power that is not delivered as RF output becomes heat.
- SSB needs linear amplification and conservative microphone gain.
- PEP describes power at the crest of a modulated RF envelope, and ALC helps keep peaks inside the clean range.
- FM audio level is controlled by deviation and microphone technique; too little sounds quiet, while too much sounds distorted and wide.
- Carson's rule estimates FM bandwidth as about 2 x (peak deviation + highest audio frequency).
