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

Modern amateur stations have many controls, but most of them serve a small number of goals: make the transmitted signal readable, manage noise at the receiver, and move information reliably. This lesson links front-panel controls to the signal-quality ideas from Lesson 5 and then introduces digital voice, sound-card modes, and packet relay concepts.

## Learning objectives

By the end of this lesson, you can:

- use an electronic keyer to produce consistent Morse timing;
- set microphone gain, VOX, and speech processing for clean voice;
- choose receiver noise tools for the noise problem you actually have;
- explain analog and digital information in plain language; and
- describe packet networks, digipeaters, ARQ, and narrow digital modes at a block level.

## Keyers, microphones, and VOX

A straight key depends entirely on the operator's hand for timing. An electronic keyer still needs operator skill, but it automatically controls the length and spacing of dits and dahs after the paddle is moved. That helps produce readable characters at steady speed.

A microphone is also a station control, not just an accessory. Before using a different microphone, adjust microphone gain and check the transmitted audio. A dynamic microphone uses a coil and magnet principle similar to a small loudspeaker in reverse. Crystal microphones use a piezoelectric element; condenser and electret microphones are capacitor-style elements that may need bias voltage and different gain. Swapping microphone types without checking levels can overdrive the transmitter.

VOX, or voice-operated transmit switching, keys the transmitter when speech is detected. It is convenient for hands-free operating, but it must be adjusted so room noise does not trigger the transmitter and so syllables are not clipped at the start. Some radios also provide anti-VOX or anti-trip settings that keep speaker audio or room noise from holding the transmitter on. Do not confuse VOX with oscillator terms: a VFO is a variable frequency oscillator, a VXO is a variable crystal oscillator, and a VCO is a voltage-controlled oscillator.

A transceiver's transmit/receive switching lets one antenna serve both jobs. In receive, the antenna is connected to the receiver input; in transmit, it is connected to the transmitter output while the receiver is protected from transmit power.

### Worked example: setting up a new hand microphone

A borrowed microphone sounds louder than the desk microphone it replaces.

- Reduce microphone gain before the first transmission.
- Transmit into a dummy load or on a clear test frequency as appropriate.
- Watch the ALC or deviation indication for the mode in use.
- Make a brief on-air audio check with a nearby station.

The safe habit is to start low and increase only as needed.

## Speech processing and average power

Speech processing changes the audio so quiet parts are lifted and loud peaks are controlled. On SSB, proper processing can make speech easier to understand in noise because average talk power rises while peak envelope power stays within limits. Too much processing makes a signal sound compressed, harsh, and wider than necessary.

Do not confuse average power with peak envelope power. A processor can raise average RF output without increasing the allowed peak. If the transmitter is already at its clean peak limit, processing must be adjusted carefully.

## Receiver noise controls

Noise tools are most useful when matched to the kind of noise present.

| Noise problem | Useful control | Why it helps |
|---|---|---|
| Repeated sharp pulses from an ignition-like source | Noise blanker | It detects brief high-amplitude pulses and mutes or gates them. |
| General hiss mixed with speech | DSP noise reduction | It analyzes changing signal and noise patterns and reduces some noise components. |
| A steady nearby signal | Filter bandwidth or tuning | It narrows the audio or RF passband; a blanker is not meant for this job. |

Noise controls can also damage readability when overused. If DSP settings make speech watery or blanker settings distort strong signals, reduce the control and use filtering or antenna changes instead.

## Analog, digital, and digital voice

Analog information varies smoothly. A microphone voltage rising and falling with speech is an analog signal. Digital information is represented by agreed discrete values, such as bits, symbols, or code words. Once voice, pictures, or text are converted into digital data, a radio system can send those values using an appropriate modulation method.

Digital voice is not magic analog voice with a different label. A vocoder samples and encodes speech, the transmitter sends digital symbols, and the receiver reconstructs audio from the decoded data. If the link becomes too weak, digital voice may sound broken or disappear instead of fading smoothly like analog FM.

Narrow digital modes are one reason digital operation can share spectrum efficiently. An FT8 transmission is roughly 50 Hz wide; a 2.4 kHz to 3 kHz SSB voice channel is dozens of those slices before guard spacing and tuning accuracy are considered. FT8 is also designed with synchronized, structured exchanges that can decode at very low signal-to-noise ratios. RTTY is wider than the very narrow weak-signal modes: a common signal uses about 170 Hz shift plus filtering and sidebands, so practical centre-to-centre spacing is a few hundred hertz rather than just a tone-width.

### Worked example: choosing a mode for a weak path

A portable station wants to exchange short grid and signal information through a noisy HF path. A narrow weak-signal mode is a better first choice than wide SSB audio because it uses a small slice of spectrum and decoding can work at low signal-to-noise ratio. If the task is a conversation, SSB or digital voice may fit better. Match the mode to the information, not just to habit.

## Packet, digipeaters, and reliability

Packet radio sends data in framed chunks. A packet network connects stations so messages can move beyond one direct path. A digipeater receives digital packets and retransmits those marked to be forwarded. That is different from a voice repeater that demodulates and retransmits analog FM audio.

Some digital protocols use automatic repeat request, or ARQ. The receiver can detect a missing or damaged frame and request a repeat, so retransmission provides error correction. Instead of letting a corrupted frame pass silently, the link either obtains a clean copy within its retry limit or stops and reports the problem. That failure-visible behaviour is one reason packet-style systems are useful when message accuracy matters.

Sound-card digital modes use audio from a computer or interface to drive the transmitter. Excessive audio has the same bad result as excessive SSB microphone gain: splatter and out-of-channel emissions. Keep compression off unless a mode's instructions require otherwise, set the audio so the transmitter is not being overdriven, and ask a nearby station for a clean-signal report rather than only a decode report.

### Worked example: sound-card audio check

A digital-mode waterfall shows extra bright traces beside the intended signal after a station raises computer audio.

- Lower the computer output or interface drive.
- Confirm the radio's ALC is not heavily limiting.
- Ask a nearby receiving station whether the signal is clean, not merely decodable.
- Restore only enough drive to make reliable contacts.

A decoded message does not prove the transmitted signal was spectrally clean.

## Try it

1. You double your keyer speed before you can space characters steadily. Why might copy get worse even though the keyer makes uniform elements? The keyer controls dit and dah lengths, but the operator still has to leave readable character and word spacing.
2. Your VOX holds the transmitter on for several seconds after each sentence in a quiet room. Which control area should you revisit? VOX release timing or anti-trip behaviour, because hands-free switching should return to receive when speech ends.
3. A mobile receiver hears sharp clicking bursts from a nearby motor. Is DSP noise reduction or a noise blanker the better first experiment? Try the noise blanker first because the problem is short impulse noise.
4. Why can a digital radio system send pictures as well as typed text? Pictures can be converted into digital values and sent as data symbols.
5. During a club packet exercise, a station receives duplicate frames through a digipeater after one path is delayed. Why should the software use sequence or frame checks instead of displaying every copy? Packet systems need to recognize which data is valid and current before presenting a message to the operator.

## Radio connection

Front-panel settings are part of station etiquette. A well-adjusted keyer, microphone gain control, speech processor, VOX circuit, and sound-card level help other amateurs copy you without fighting avoidable noise. Receiver controls matter too: using the right noise tool can make a contact easier without blaming the other station for a problem at your end.

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

- Electronic keyers regulate Morse element timing; operators still control spacing and good sending habits.
- Microphone gain, VOX, T/R switching, and speech processing should be adjusted for clarity without overdrive.
- Noise blankers suit short impulse noise; DSP noise reduction suits some background noise; filters suit nearby signals.
- Digital information uses discrete agreed values, so voice, text, and images can all become data.
- FT8 is narrow and weak-signal oriented; RTTY needs enough centre-to-centre spacing to avoid overlap.
- Digipeaters forward selected digital packets, and ARQ improves reliability by requesting repeats when needed.
