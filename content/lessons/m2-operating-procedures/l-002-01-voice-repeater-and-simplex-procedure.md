---
type: lesson
id: L-002-01
moduleId: M2
categoryIds:
  - B-002
title:
  en: "Voice, repeater, and simplex procedure"
  fr: null
covers:
  - B-002-001
  - B-002-002
  - B-002-003
  - B-002-004
objectives:
  - "Make concise voice contacts on repeaters and simplex channels."
  - "Use phonetics for clear identification."
  - "Listen first and use only the power needed."
prerequisites:
  - L-003-05
  - L-006-02
estimatedMinutes: 45
quizIds:
  - QZ-L-002-01-A
status: draft
---
# Voice, repeater, and simplex procedure

Two handheld operators can hear a hilltop repeater even when buildings block their direct path. Later, they move closer together and can speak directly. Good operating means choosing the path they need while leaving room for everyone else.

The same habits work on both paths: listen, identify clearly, keep the message brief, and pause for replies.

## Learning objectives

By the end of this lesson, you can:

- make a directed call, answer CQ, and join a repeater conversation;
- explain repeater access tones, offsets, coordination, and time-out timers;
- spell identification with standard phonetics;
- decide when a direct simplex contact can replace a repeater contact; and
- share frequencies through careful testing, spacing, and power control.

## Choose a relay or a direct path

A repeater receives your signal and retransmits it from a better site. Its antenna height helps extend the range of portable and mobile stations. It listens on its input frequency while transmitting on a different output frequency. That separation keeps its strong transmitter from blocking its own receiver.

Your radio listens to the repeater output and transmits on the repeater input. The difference is called the offset. For two-metre FM repeaters, the standard offset is 600 kHz. Match the output channel, offset direction, input channel, and access tone before calling.

CTCSS means continuous tone-coded squelch system. It sends a low-frequency, sub-audible tone alongside your speech. The repeater opens its receiver audio when the expected tone is present. The tone controls access; it does not make a conversation private.

Frequency coordination recommends VHF and UHF repeater channels that reduce conflicts with nearby systems. A quiet-sounding frequency is not enough evidence that it is a suitable new channel.

### Worked example: setting a negative offset

For an illustrative setup, a repeater transmits on 146.940 MHz and uses a negative offset. This is a calculation example, not a local channel recommendation.

- Given: output = 146.940 MHz; offset = 600 kHz = 0.600 MHz, negative.
- Find: the handheld's transmit frequency.
- Formula: radio transmit frequency = repeater output - offset magnitude.
- Substitute: transmit frequency = 146.940 MHz - 0.600 MHz.
- Answer: transmit on 146.340 MHz and receive on 146.940 MHz.
- Sanity check: a negative offset puts the input below the output.

### Faded practice: program a positive offset

An illustrative repeater output is 145.230 MHz with a positive 600 kHz offset. This is arithmetic practice, not a channel recommendation.

- Given: output = 145.230 MHz; positive offset = 600 kHz = ___ MHz.
- Find: the radio's transmit frequency.
- Formula: transmit frequency = output + offset magnitude.
- Complete: transmit frequency = 145.230 MHz + ___ MHz = ___ MHz.
- Sanity check: should the transmit setting be above or below the output?

Pause and fill the gaps before checking below.

### Check your work: positive offset

600 kHz = 0.600 MHz. The transmit setting is 145.830 MHz, above the output. The radio still receives on the repeater output.

### Use simplex for a direct path

Simplex is the direct alternative: both stations use a single frequency for sending and receiving. While on a repeater, listen for the other station on its input channel. If you hear that station clearly, a direct path may work. Both operators should check reliable copy before moving to a suitable simplex channel.

A repeater input can sound quiet because you cannot hear distant users. Avoid local repeater channels when choosing simplex; move if your direct contact is using one. For local work that VHF or UHF can handle, use those bands and leave HF less crowded for longer paths.

::figure voice-repeater-simplex
Alt text: A portable radio reaches another portable through a hilltop repeater, then both move to a direct simplex path.
Text equivalent:
- The input arrow runs from portable A to the hilltop repeater and is labelled CTCSS + offset.
- The output arrow runs from the repeater to portable B.
- A separate direct arrow between the portables is labelled simplex.
::

## Leave room on the repeater

Listen before your first transmission and pause between later transmissions. Those gaps let another operator join or ask for help. Short turns, often called overs, keep the shared repeater available for emergency traffic too.

A time-out timer cuts off a transmission that lasts too long. It can protect against a stuck microphone, but waiting for the timer is not a good way to pace a conversation.

To join an ordinary conversation, give your call sign in a gap and let the speakers acknowledge you. For distress, give your call sign and describe the situation in the break. The next lesson on priority traffic develops that procedure.

### Worked example: joining without talking over someone

A club member hears two stations discussing an antenna. The member has a short question.

1. Listen until a transmission ends, then allow a clear gap.
2. Send your call sign, for example “VA3PQR”.
3. Wait for an invitation rather than launching into the question.
4. Ask briefly, then release the microphone so others can reply.

### Use plain language for location

When asking where someone is, use ordinary words. Plain language is clearer than 10-codes on a shared amateur channel.

## Make the call sign easy to copy

Noise can make B, D, E, G, P, and V sound alike. Standard International Telecommunication Union, or ITU, phonetic words give each letter a distinct spoken label. They help with identification and with repairing a missed part of a call sign.

| Letter | ITU word | Letter | ITU word |
|---|---|---|---|
| A | Alfa | N | November |
| B | Bravo | O | Oscar |
| C | Charlie | P | Papa |
| D | Delta | Q | Quebec |
| E | Echo | R | Romeo |
| F | Foxtrot | S | Sierra |
| G | Golf | T | Tango |
| H | Hotel | U | Uniform |
| I | India | V | Victor |
| J | Juliett | W | Whiskey |
| K | Kilo | X | X-ray |
| L | Lima | Y | Yankee |
| M | Mike | Z | Zulu |

Practise your own call sign first. Then practise letters you tend to confuse. Use the fixed words rather than inventing a new spelling system when someone is struggling to copy.

## Tell listeners who you want

A directed call names a particular station. Put that destination first, then “this is”, then your own identification. On a repeater, a brief call or a short announcement that you are listening usually does the job.

CQ is an open invitation rather than a call to one person. Repetition gives a listener time to notice the invitation and copy the sender. Keep these voice patterns distinct:

| Purpose | Opening | Identification |
|---|---|---|
| Invite any station | Repeat CQ three times. | Add “this is”; repeat your own call three times. |
| Reply to a CQ | Give the caller's identification once. | Add “this is” and your own call. |
| Call a known station | Name the intended listener. | Add “this is” and your own call. |

### In the real world: directing a reply

VA3PQR hears VE2LMN calling CQ. VA3PQR replies, “VE2LMN, this is VA3PQR.” The destination comes first, so other listeners know who should answer. This same order works for a directed repeater call.

## Give a voice signal enough space

Single-sideband voice, or SSB, occupies a few kilohertz, not just the displayed dial frequency. Allow about 3 kHz from an SSB contact already under way.

A tuner adjustment radiates a test signal too. Before joining an HF SSB net, keep that brief test in clear spectrum 3 kHz to 5 kHz away. Listen before testing so the adjustment does not cover another contact. Return to the net ready to wait for net control.

Sideband choice is also a shared convention. As a practical rule for ordinary amateur HF voice, operators generally use lower sideband below 10 MHz and upper sideband from 10 MHz upward. This is not a universal rule for every mode or service. It explains the usual choices: lower sideband at 3 755 kHz and upper sideband on twenty metres, around 14 MHz.

For lengthy tests, replace the antenna with a suitable dummy load. It absorbs RF as heat instead of sending repeated test signals over the air. Use a load rated for the test power and duration.

## Share the frequency, not just the microphone

A band plan voluntarily groups compatible modes and activities within a band. Following it reduces avoidable interference, but a schedule does not reserve a frequency.

If a net's usual channel is busy, net control should politely ask whether the current users can move. If they cannot, the net finds a clear channel. If you are already talking when a scheduled net is about to start, accommodate it by moving where possible.

Changing propagation can bring new interference into an ongoing contact. Agree on another clear frequency rather than trying to overpower the other stations. If your signal is much stronger than needed, reduce power while checking that the other operator can still copy reliably. Lower power saves battery energy and reduces unnecessary RF exposure and interference potential.

## Try it

Pause here. Work through each prompt before reading the feedback below.

1. An illustrative two-metre repeater output is 147.180 MHz with a positive standard offset. Find the radio's transmit frequency.

:::answer
The offset is 0.600 MHz. Adding gives 147.780 MHz. Positive means your radio transmits above the output, unlike the worked example.
:::

2. You hear your friend clearly on a repeater input. What still needs checking before you move the conversation off the repeater?

:::answer
Your friend must also hear you directly. Choose a proper simplex channel, not a repeater input, and confirm reliable copy both ways.
:::

3. A nearby station says your voice is strong but distorted. Recall the signal-quality lesson: should your first move be more RF power or an audio-setting check?

:::answer
Check microphone technique, gain, and deviation. Strength and clean audio are different; more power does not cure distorted speech.
:::

## Radio connection

Every setting serves a listening task. Offset and tone let you reach the relay; phonetics let people copy your identity. Pauses, sensible spacing, clean tests, and modest power leave that path useful for the next operator.

## Common mistakes

- Programming only the displayed receive frequency: check input, offset direction, and tone too.
- Treating a quiet receiver as proof that a channel is unused: check local channel plans and listen first.
- Holding the microphone until the timer cuts in: use short overs and deliberate pauses instead.
- Leaving a nearby conversation on the repeater after direct copy works: choose a proper simplex channel.
- Assuming a net owns its scheduled channel: cooperate with existing users and be ready to move.

## Illustration brief

Alt text: A portable radio reaches another portable through a hilltop repeater, then both move to a direct simplex path.

Description: Draw two handheld operators on opposite sides of a town. Show a first path from operator A up to a hilltop repeater and down to operator B, with separate arrows labelled input and output. Beside it, show a second direct arrow labelled simplex after the operators confirm they can hear each other. Add small callouts for pause, CTCSS tone, offset, and clear channel.

## Summary

Choose the simplest reliable path, then make it easy for others to share. A repeater adds reach; simplex frees the relay when both stations can copy directly. Clear calls, standard phonetics, pauses, careful tests, and appropriate spacing make either path useful without unnecessary interference.
