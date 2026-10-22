---
type: lesson
id: L-003-06
moduleId: M3
categoryIds:
  - B-003
title:
  en: "Controls, digital voice, and packet relays"
  fr: null
covers:
  - B-003-014
  - B-003-015
objectives:
  - "Set keyers and microphones for readable signals."
  - "Explain the difference between analog and digital information."
  - "Describe digipeaters and digital radio systems at a block level."
prerequisites:
  - L-003-05
estimatedMinutes: 35
quizIds:
  - QZ-L-003-06-A
status: draft
---
# Controls, digital voice, and packet relays

Modern amateur stations have many controls. Most serve a few simple goals. Make the transmitted signal readable. Manage receiver noise. Move information reliably.

This lesson links controls to signal quality. It then introduces digital voice, sound-card modes, and packet relay concepts.

## Learning objectives

By the end of this lesson, you can:

- use an electronic keyer to produce consistent Morse timing;
- set microphone gain, VOX, and speech processing for clean voice;
- choose receiver noise tools for the noise problem you actually have;
- explain analog and digital information in plain language; and
- describe packet networks, digipeaters, ARQ, and narrow digital modes at a block level.

## Keyers, microphones, and VOX

A straight key depends on the operator's hand for timing. An electronic keyer still needs operator skill, but it automatically controls dit and dah length after the paddle is moved. That helps make readable characters at a steady speed.

::figure controls-digital-voice-packet
Alt text: A station control map links keyer timing, microphone gain, VOX, receiver noise tools, and a packet digipeater block.
Text equivalent:
- Paddle feeds keyer and TX key; microphone feeds gain and spch.
- VOX controls the transmit path, and the radio box is labelled noise tools.
- Packet frames go from station A to digipeater to station B.
::



A microphone is also a station control. Before using a different microphone, adjust microphone gain and check the transmitted audio. A dynamic microphone uses a coil and magnet principle, like a small loudspeaker working in reverse. Crystal microphones use a piezoelectric element. Condenser and electret microphones are capacitor-style elements that may need bias voltage and different gain.

### In the real world: setting up a new hand microphone

A borrowed microphone sounds louder than the desk microphone it replaces.

- Reduce microphone gain before the first transmission.
- Transmit into a dummy load or on a clear test frequency as appropriate.
- Watch the ALC or deviation indication for the mode in use.
- Make a brief on-air audio check with a nearby station.

The safe habit is to start low and increase only as needed.

VOX means voice-operated transmit switching. It keys the transmitter when speech is detected. VOX is convenient, but it must be adjusted so room noise does not trigger transmit and speech starts are not clipped.

VOX sensitivity controls how easily sound triggers transmit. VOX delay or hang time controls how long transmit remains on after speech stops. Some radios also provide anti-VOX or anti-trip settings to keep received speaker audio from triggering transmit.

Do not confuse VOX with oscillator terms. A VFO is a variable frequency oscillator. A VXO is a variable crystal oscillator. A VCO is a voltage-controlled oscillator.

### In the real world: headset, fan, and VOX

A headset microphone works well in a quiet room. Beside a cooling fan, VOX keys the radio before the operator speaks. Lower VOX sensitivity or move the microphone so the fan does not trigger transmit.

If the first syllable is clipped, the transmit trigger is late. Increase sensitivity, adjust attack if the radio has that control, or speak a short lead-in word before important text. Do not solve a clipped first syllable by adding hang time; hang time affects the end of the transmission.

The aim is clean switching that does not surprise other operators.

## Transmit/receive switching and speech processing

A transceiver's transmit/receive switching lets one antenna serve both jobs. In receive, the antenna connects to the receiver input. In transmit, it connects to the transmitter output while the receiver is protected from transmit power.

Speech processing changes audio so quiet parts are lifted and loud peaks are controlled. On SSB, careful processing can improve readability in noise. Too much processing makes a signal compressed, harsh, and wider than needed.

Do not confuse average power with peak envelope power. A processor can raise average RF output without raising the allowed peak. If the transmitter is already at its clean peak limit, reduce processing or drive.

## Receiver noise controls

Noise tools work best when they match the noise problem.

Digital signal processing, or DSP, uses digital calculations to filter or reduce noise. DSP can help, but strong settings can also make speech sound watery.

| Noise problem | Useful control | Why it helps |
|---|---|---|
| Repeated sharp pulses from an ignition-like source | Noise blanker | It detects brief high-amplitude pulses and mutes or gates them. |
| General hiss mixed with speech | DSP noise reduction | It reduces some noise components after analyzing signal and noise patterns. |
| A steady nearby signal | Filter bandwidth or tuning | It narrows the passband; a blanker is not meant for this job. |

If a noise control makes speech harder to understand, reduce it. Then try filtering, tuning, antenna changes, or fixing the noise source.

## Analog, digital, and digital voice

Analog information varies smoothly. A microphone voltage rising and falling with speech is an analog signal. Digital information uses agreed discrete values, such as bits, symbols, or code words.

Digital voice is not analog FM with a new label. A vocoder samples and encodes speech. The transmitter sends digital symbols. The receiver decodes those symbols and rebuilds audio. If the link becomes too weak, digital voice may sound broken or disappear instead of fading smoothly.

Narrow digital modes can share spectrum efficiently. An FT8 transmission is roughly 50 Hz wide, so many FT8 contacts can fit in the space of one SSB voice signal. FT8 can decode signals at a very low signal-to-noise ratio, well below what you could copy by ear. RTTY is wider than very narrow weak-signal modes. A typical mark-space shift plus keying sidebands takes a few hundred hertz of real spectrum, so practical centre-to-centre spacing is about 250 Hz to 500 Hz rather than a single tone width.

### In the real world: choosing a weak-path mode

A portable station wants to exchange short grid and signal reports through a noisy HF path. A grid is a short locator code for a geographic area. A narrow weak-signal mode is a better first choice than wide SSB audio because it uses a small slice of spectrum and decodes at low signal-to-noise ratios.

If the task is a conversation, SSB or digital voice may fit better. Match the mode to the information.

### Worked example: plan a narrow-mode slice

A display shows a 1.8 kHz slice. Reserve 150 Hz total for unused guard space, then estimate how many 50 Hz traces could fit.

- Given: slice = 1.8 kHz = 1 800 Hz; guard space = 150 Hz total; trace width = 50 Hz.
- Find: a simple upper planning count.
- Formula: count = (slice width - total guard space) / trace width.
- Substitute: count = (1 800 - 150) / 50.
- Answer: count = 33 traces before practical spacing limits.
- Sanity check: there is room for fewer traces than 1 800 / 50 because some width was reserved.

This arithmetic is not an operating channel plan. Real filters, drift, and courtesy require useful spacing.

### Faded practice: reserve space before dividing

A different display slice is 2.2 kHz wide. Reserve 100 Hz total for guard space, with 50 Hz traces.

- Given: slice = 2.2 kHz = ___ Hz; total guard space = 100 Hz; trace width = 50 Hz.
- Find: a simple upper planning count.
- Formula: count = (slice width - total guard space) / trace width.
- Complete: usable width = 2 200 - 100 = ___ Hz; count = ___ / 50 = ___.
- Sanity check: subtract the total guard allowance once, not once per edge.

Fill the gaps before checking below.

### Check your work: reserve space before dividing

The slice is 2 200 Hz. After the guard allowance, 2 100 Hz remains. Dividing by 50 gives 42 traces before extra practical spacing.

## Packet, digipeaters, and reliability

Packet radio sends data in framed chunks. A digipeater receives digital packets and retransmits packets marked for forwarding. That is different from a voice repeater that retransmits analog FM audio. Linked together, packet stations and digipeaters form a network that can carry messages well beyond one direct radio path.

Some digital protocols use automatic repeat request, or ARQ. The receiver can detect a missing or damaged frame and request a repeat. That retransmission process provides error correction. Instead of showing corrupted data silently, the link gets a clean copy within its retry limit or reports failure. That reliable delivery, or clear notice of failure, is why packet messaging can be useful in emergency communications.

Sound-card digital modes use audio from a computer or interface to drive the transmitter. Excessive audio has the same bad result as excessive SSB microphone gain. It can make splatter and out-of-channel emissions.

### In the real world: sound-card audio check

A digital-mode waterfall shows extra bright traces beside the intended signal after a station raises computer audio.

- Lower the computer output or interface drive.
- Confirm the radio's ALC is not heavily limiting.
- Ask a nearby receiving station whether the signal is clean, not merely decodable.
- Restore only enough drive to make reliable contacts.

A decoded message does not prove the transmitted signal was clean.

## Try it

1. You double your keyer speed before you can space characters steadily. Why might copy get worse? The keyer controls dit and dah lengths, but the operator still controls character and word spacing.
2. Your VOX holds the transmitter on for several seconds after each sentence in a quiet room. Which control area should you revisit? VOX delay or hang time.
3. Your VOX misses the first syllable. Which control area should you revisit first? VOX trigger sensitivity or attack, because the transmitter is starting late.
4. A mobile receiver hears sharp clicking bursts from a nearby motor. Is DSP noise reduction or a noise blanker the better first experiment? Try the noise blanker first because the problem is short impulse noise.
5. Why can a digital radio system send pictures as well as typed text? Pictures can be converted into digital values and sent as data symbols.

## Radio connection

Front-panel settings are part of station etiquette. A well-adjusted keyer, microphone gain control, speech processor, VOX circuit, and sound-card level help other amateurs copy you. Receiver controls matter too. The right noise tool can make a contact easier without blaming the other station.

## Common mistakes

- Assuming a keyer replaces learning readable Morse rhythm.
- Swapping microphones without checking gain and mode settings.
- Confusing VOX with VFO, VXO, or VCO oscillator functions.
- Using speech processing as a substitute for speaking clearly.
- Expecting a noise blanker to remove every kind of noise.
- Treating digital modes as immune to overdrive.
- Confusing a digipeater with an internet gateway or an analog voice repeater.

## Illustration brief

Alt text: A station control map links keyer timing, microphone gain, VOX, receiver noise tools, and a packet digipeater block.

Description: Draw an original block diagram. On the left, show a paddle feeding an electronic keyer and a microphone feeding gain, VOX, and speech processing controls. In the centre, show a transceiver with separate receiver noise-control blocks. On the right, show a packet station sending frames through a digipeater to a second station. Use labels only; do not copy any manufacturer display.

## Summary

- Electronic keyers regulate Morse element timing; operators still control spacing.
- Microphone gain, VOX, T/R switching, and speech processing should be adjusted for clarity without overdrive.
- A clipped first syllable is a VOX trigger problem, not a hang-time problem.
- Noise blankers suit short impulse noise; DSP noise reduction suits some background noise; filters suit nearby signals.
- Digital information uses discrete agreed values, so voice, text, and images can all become data.
- Narrow weak-signal modes such as FT8 can decode at a very low signal-to-noise ratio, while RTTY contacts need wider centre-to-centre spacing.
- Digipeaters forward selected digital packets, and ARQ improves reliability by requesting repeats when needed.
