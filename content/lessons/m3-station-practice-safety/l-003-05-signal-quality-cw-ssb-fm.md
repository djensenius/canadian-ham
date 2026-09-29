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

A transmitter can be legal and still be a poor neighbour if its signal is hard to copy or spreads beyond the intended channel. Signal quality is the practical habit of using enough drive for readability, but not so much that the radio creates clicks, drift, splatter, or distorted audio.

This lesson focuses on three everyday cases: keyed continuous wave (CW), single-sideband voice (SSB), and frequency-modulated voice (FM). The details differ, but the operating idea is the same: keep the radio stable, set levels conservatively, and ask for on-air reports when you change equipment.

## Learning objectives

By the end of this lesson, you can:

- describe chirp, key clicks, and oscillator drift in a CW signal;
- explain why amplitude modulation has a carrier and sidebands;
- account for RF amplifier efficiency as useful output plus heat;
- set SSB microphone gain and speech processing without overdriving the transmitter;
- use peak envelope power as the useful power idea for modulated voice; and
- match FM deviation, bandwidth, and microphone technique to the channel being used.

## Clean CW: stable carrier, shaped keying

CW usually sends Morse by turning an RF carrier on and off. A clean keyed signal has a steady frequency and keying edges that are not unnecessarily abrupt.

Chirp is a small frequency movement each time the transmitter is keyed. The operator at the far end hears the note slide instead of starting cleanly. Chirp often points to something changing inside the transmitter when the load changes, such as supply voltage sag or oscillator pulling. Good regulation, solid oscillator construction, and sound keying design help the carrier stay put.

Key clicks are different. They sound like sharp ticks around the signal and are caused by keying edges that are too abrupt. A key-click filter or proper shaping slows the edge enough to reduce splatter without making the Morse unreadable. A low-pass filter is valuable for harmonics, but it is not the same cure as keying-shape control.

A variable-frequency oscillator lets a CW transmitter tune across a range rather than being limited to a few crystal frequencies. That flexibility is useful only if the oscillator is electrically and mechanically stable, so keep VFOs away from heat, loose hardware, and changing supply conditions.

### Worked example: diagnosing two CW reports

During a club practice net, one report says, "Your note slides for an instant at the start of each element." Another says, "I hear ticks a little above and below your signal."

- The sliding note points to chirp, so first suspect supply regulation, oscillator loading, or mechanical stability.
- The ticks point to key clicks, so first suspect keying edge shape or missing click filtering.
- The remedies are not interchangeable: a harmonic low-pass filter will not make an unstable oscillator stop moving.

## AM envelope and sidebands

Amplitude modulation changes the RF envelope to carry information. When voice audio modulates a carrier, the transmitted energy includes the carrier plus two sidebands. The occupied bandwidth is approximately twice the highest audio frequency that is being transmitted.

Text formula: AM bandwidth ≈ 2 × highest audio frequency.

This is a useful way to estimate whether a signal is using more spectrum than expected. If the transmitter passes wider audio, the sidebands extend farther from the carrier. If the transmitter is distorted, the unwanted products can spread even farther.

A transmitter final amplifier also has a power budget. DC input power that is not converted into RF output appears mostly as heat in the final stage. Efficiency is useful RF output divided by DC input, so a 100-percent efficient stage would have no internal heat loss; real stages are less than that and need heat sinking and conservative operation.

### Worked example: AM bandwidth estimate

An original bench demonstration limits the audio tone range to 2.4 kHz before feeding an AM exciter.

- AM has upper and lower sidebands.
- Each sideband extends about 2.4 kHz from the carrier.
- Approximate occupied bandwidth is 2 x 2.4 kHz = 4.8 kHz.

That is an estimate for a clean signal. Distortion or overdrive can make the real occupied bandwidth worse.

## SSB: linear amplification and level control

Single sideband removes the carrier and one sideband, so most of the useful output is in the remaining sideband. Typical amateur SSB voice fits between about 2 kHz and 3 kHz and depends on a linear RF power amplifier. A non-linear amplifier does not follow the voice envelope faithfully, so speech becomes distorted and unwanted products appear beside the signal.

A balanced modulator is an earlier block in many SSB transmitters. It suppresses the carrier and passes the two sidebands, producing double-sideband suppressed-carrier output. A later filter or phasing stage selects one sideband. Suppressing the carrier lets more output power go into information-bearing sidebands, but carrier suppression alone does not halve the bandwidth until one sideband is removed.

Peak envelope power, or PEP, names the RF output power at the highest point of the voice envelope, averaged over the RF cycle at that instant. The practical meaning is simple: SSB power rises on voice peaks, so the top of the envelope is the important limit.

Microphone gain should be set so speech peaks stay within the radio manufacturer's ALC guidance. The ALC meter may move on peaks, but it should not be hammered to the end of its scale. ALC limits input peaks to help prevent overdrive; it is not a receiver noise control. Speech processing can improve intelligibility by raising average talk power while keeping peaks under control, but too much processing makes audio harsh and wider than necessary.

### Worked example: setting SSB audio without splatter

A learner installs a new headset and checks the transmitter into a dummy load before calling CQ.

- Start with the microphone gain lower than before.
- Speak at a normal distance and watch the ALC indicator on syllable peaks.
- Increase gain only until peaks reach the recommended range, then stop.
- Add speech processing lightly and ask a nearby station for an audio-width report.

The goal is not the loudest possible meter reading. The goal is clear speech that stays inside the intended bandwidth.

### Worked example: sideband frequency direction

In an original lower-sideband practice example, the suppressed carrier setting is 5 360 kHz and a single audio tone is 700 Hz.

- Lower sideband means the RF energy appears below the carrier setting.
- 700 Hz is 0.700 kHz.
- Transmitted RF is 5 360 kHz - 0.700 kHz = 5 359.300 kHz.

For upper sideband, the same tone would appear above the carrier setting instead.

## FM: deviation, squelch, and capture effect

FM carries audio by changing the carrier frequency around its assigned channel. The amount of swing from the centre frequency is deviation. Louder audio produces more deviation until the transmitter's limiter or audio stages run out of clean range. If the microphone fails, there is no modulating audio, so the transmitter sends an unmodulated carrier.

Phase modulation is closely related to FM because changing phase over time changes instantaneous frequency. Both are angle-modulation methods, unlike AM where the carrier amplitude changes.

For repeaters and local channels, the transmitter deviation should match the system. Too little deviation sounds quiet at the far end. Too much deviation sounds loud, rough, or distorted, and can occupy more spectrum than the channel expects. A normal voice-deviation FM signal occupies a channel much wider than the deviation number alone, so plan for a many-kilohertz channel rather than a narrow sliver.

Text formula: FM bandwidth by Carson's rule ≈ 2 × (peak deviation + highest audio frequency).

For example, 2.5 kHz deviation with 3 kHz audio estimates to about 2 × (2.5 + 3) = 11 kHz. Higher deviation produces a still wider channel by the same formula. Canadian occupied-bandwidth limits below 28 MHz leave only a few kilohertz for voice operation, so an FM voice signal estimated at about 11 to 16 kHz does not fit that plan; reserve wide FM for band segments where a many-kilohertz channel is allowed. Speaking very close to the microphone can cause overdeviation even if the frequency is exactly right.

An FM receiver often has high gain before the discriminator. With no usable signal present, that gain makes the speaker noise loud unless squelch mutes it. FM is popular for local VHF/UHF work because, above threshold, it can provide good signal-to-noise performance at modest received signal levels. When multiple FM signals are present, the receiver tends to demodulate the strongest one; this is the capture effect.

### Worked example: repeater audio report

A repeater operator reports, "Your signal is full quieting, but your words are thin and quiet." The RF path is adequate, so increasing RF power is not the first fix. Check the transmitter's deviation setting, microphone gain, and microphone distance. If the report changes to "loud and rough," back off the audio level.

## Try it

1. An AM bench exciter is limited to 2.8 kHz highest audio before it reaches the modulator. What occupied bandwidth should you plan for? AM has two sidebands, so estimate 2 x 2.8 kHz = 5.6 kHz.
2. Why does a clean AM voice signal need spectrum on both sides of the carrier? The changing envelope creates upper and lower sidebands, and both carry the audio information.
3. A double-sideband suppressed-carrier stage is feeding a later SSB filter. What still has to happen before only one sideband is transmitted? The later filter or phasing stage must select one sideband; suppressing the carrier alone still leaves both sidebands.
4. A lower-sideband exciter is set to 3 925 kHz and is fed a 600 Hz tone in a bench test. Where is the RF tone? 600 Hz is 0.600 kHz, so the lower-sideband RF is 3 925 - 0.600 = 3 924.400 kHz.
5. Before joining an FM net with a borrowed hand microphone, why make a short local audio check at normal speaking distance? A different microphone can change deviation and audio level even when the RF path is fine, so set the audio before assuming more power is needed.

## Radio connection

Clean-signal practice is interference prevention. A few minutes spent setting CW keying, SSB ALC, or FM deviation can protect adjacent users from noise you never hear in your own speaker. When you change microphones, interfaces, power supplies, or audio settings, use a dummy load for initial checks and then ask for a specific signal-quality report.

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
- AM changes envelope amplitude and produces a carrier plus two sidebands; AM bandwidth ≈ 2 × highest audio frequency.
- Final-amplifier DC input power that is not delivered as RF output becomes heat.
- SSB needs linear amplification and conservative microphone gain so voice peaks do not overdrive the transmitter.
- PEP describes power at the crest of a modulated RF envelope, and ALC helps keep peaks inside the clean range.
- FM audio level is controlled by deviation and microphone technique; too little sounds quiet, while too much sounds distorted and wide.
- Carson's rule estimates FM bandwidth as about 2 × (peak deviation + highest audio frequency), so voice FM needs a many-kilohertz channel.
