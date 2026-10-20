---
type: lesson
id: L-002-02
moduleId: M2
categoryIds:
  - B-002
title:
  en: "Morse, RST, and Q signals"
  fr: null
covers:
  - B-002-005
  - B-002-006
  - B-002-007
objectives:
  - "Use common Morse calling abbreviations in routine contacts."
  - "Decode RST reports for voice and Morse contacts."
  - "Recognize common Q signals used in amateur procedure."
prerequisites:
  - L-002-01
  - L-005-04
estimatedMinutes: 40
quizIds:
  - QZ-L-002-02-A
status: draft
---
# Morse, RST, and Q signals

You call a station in Morse and receive an answer too fast to copy. Sending faster will not solve that problem. A useful contact needs a shared pace, clear identification, and an honest report of what each operator hears.

Morse code sends characters as short and long elements, often called dots and dashes. CW, or continuous-wave operation, commonly carries those characters by keying an RF carrier on and off.

## Learning objectives

By the end of this lesson, you can:

- call and answer in Morse at a pace you can receive;
- use short procedural groups without mixing up their jobs;
- separate readability, strength, and tone in a reception report;
- estimate power changes from a calibrated S-meter under stable conditions; and
- choose Q signals that make an operating step clearer.

## Build a contact from small pieces

Listen first, just as you would on voice. Send QRL? and listen for a response before starting a Morse contact. That group asks whether the frequency is occupied. A pause matters: sending the question without listening defeats its purpose.

CQ invites any station to answer. DE identifies the source of the message; think of it as the divider before the sender's call sign. A routine Morse call and reply use different repetition patterns:

| Purpose | Opening | Sender identification |
|---|---|---|
| General call | Repeat CQ three times, then DE. | Repeat your own call three times. |
| Reply to that call | Repeat the caller's identification twice, then DE. | Repeat your own call twice. |

Send only as fast as you can reliably receive. The answering operator may match your calling speed. Repeated identification helps with fading, but endlessly repeating a call wastes listening time.

### Worked example: follow the direction of a reply

VE2LMN has just called CQ. VA3PQR answers. These are illustrative call signs for a practice exchange.

1. VA3PQR sends VE2LMN twice so the intended listener is clear.
2. VA3PQR sends DE to mark who the reply is from.
3. VA3PQR sends VA3PQR twice, then leaves time for an answer.

The destination-before-source order matches a directed voice call. The Morse reply repeats each call because individual characters can disappear in noise.

## Use short groups for clear jobs

Short groups save keying time. Learn the job of each group rather than treating them as interchangeable ways to end a transmission.

| Group | Operating job |
|---|---|
| CQ | Invite anyone listening to make contact. |
| DE | Mark the source: the sender's call follows it. |
| K | Hand the channel over for a reply from any station. |
| R | Confirm that the message was received completely. |
| DX | Refer to a distant station or contact. |
| 73 | Close with good wishes. |
| QSK | Full break-in: the receiver works in the gaps between keyed elements. |

Full break-in lets you hear incoming signals between your own dots and dashes. It is a station capability, not permission to cover someone else's transmission.

A CW signal is narrow, but it still needs room. Allow 150 Hz to 500 Hz separation from a CW contact already in progress. Voice spacing is much wider because voice carries a wider range of frequencies.

## Report what reaches your receiver

A signal report describes reception at your station, not the other operator's equipment rating. Readability asks whether you can understand the message. Strength describes received signal level. Tone describes the quality of the keyed note in Morse.

The letters RST fix the order: readability, signal strength, then tone. Voice reports normally use only R and S. A loud signal can still be hard to understand, so strength alone does not tell the whole story.

| Part | Digit | What the digit describes |
|---|---:|---|
| Readability | 1 | No usable copy. |
| Readability | 3 | Copy takes considerable effort. |
| Readability | 4 | Quite readable. |
| Readability | 5 | Perfectly readable. |
| Strength | 1 | Just perceptible. |
| Strength | 3 | Weak. |
| Strength | 5 | Fair strength. |
| Strength | 7 | Moderately strong. |
| Strength | 9 | Extremely strong. |
| Tone | 9 | A clean, steady note: perfect tone. |

### Worked example: keep the three observations separate

A Morse signal takes some effort to read but is quite readable. Its strength is moderately strong and its note is clean. Reading the table by part gives R = 4, S = 7, T = 9, so the report is 479.

For a voice signal with the same readability and strength, leave off the tone digit. Voice does not get a Morse-tone score merely because the speaker sounds pleasant.

An S9 report with an added decibel value means the meter indicates that many decibels above S9. The added value describes strength, not an extension to the readability scale.

On a repeater, describe the relayed station's audio and intelligibility as you hear them from the repeater. You cannot infer every detail of its signal into the repeater from that output alone.

### In the real world: useful reports beat flattering reports

If words disappear in fading, say so. If the relay is strong but the speaker is quiet, describe the audio problem. Automatic perfect reports hide the evidence that another operator needs to improve copy.

::figure morse-rst-contact-flow
Alt text: A Morse contact flow showing a busy-frequency check, CQ, DE, call signs, a signal report, and sign-off.
Text equivalent:
- The timeline labels are QRL?, CQ, DE, calls, RST, and 73.
- The side panel has three gauges labelled R, S, and T, with a meter label.
::

## Connect meter steps to power ratios

An S-unit is a marked step on a receiver's strength meter. For the Basic model, assume a calibrated meter with 6 dB per S-unit. A rise of that size means about two power doublings: 3 dB + 3 dB, or 2 x 2. A fall reverses both doublings, leaving a quarter of the power.

This model needs a steady path, unchanged antennas, and comparable receiver settings. Real S-meters may not follow the calibration closely. A change in fading or antenna direction can move the meter without any transmitter-power change.

### Worked example: predicting a rise

An illustrative station raises its transmitter power while all other conditions stay steady. Assume the calibrated meter model above.

- Given: old power = 18 W; new power = 72 W.
- Find: approximate S-meter change at the receiving station.
- Formula: power ratio = new power / old power; each calibrated step needs about a fourfold ratio.
- Substitute: power ratio = 72 / 18 = 4.
- Answer: about one S-unit upward on the calibrated meter.
- Sanity check: doubling to 36 W and doubling again to 72 W accounts for both power doublings.

### Worked example: predicting a fall

Now suppose another station cuts power from 60 W to 15 W under the same model.

- Given: old power = 60 W; new power = 15 W.
- Find: approximate S-meter change.
- Formula: power ratio = new power / old power.
- Substitute: power ratio = 15 / 60 = 0.25.
- Answer: about one S-unit downward, or a 6 dB fall.
- Sanity check: halving to 30 W and halving again to 15 W reverses the two doublings.

## Choose Q signals by the task

Q signals are compact three-letter groups. A question mark can turn a statement into a request for information. For example, QRL? checks whether a frequency is busy; QRL can state that a station is busy.

| Task | Q signal | Meaning in use |
|---|---|---|
| Check the channel | QRL? | Ask whether the frequency is occupied. |
| Check readiness | QRV? | Ask if the other operator is ready. |
| Check for traffic | QRU? | Ask if there is anything to pass to you. |
| Identify a caller | QRZ? | Ask the station calling you to identify itself. |
| Adjust the pace | QRS | Ask for slower sending. |
| End sending | QRT | Stop transmitting. |
| Move the contact | QSY | Move to another frequency. |
| Describe fading | QSB | The received level is rising and falling. |
| Confirm a message | QSL? | Ask for acknowledgement of receipt. |
| Describe interference | QRM | Other signals are interfering. |
| Describe static | QRN | Natural noise is troubling reception. |
| Describe copy | QRK | Refer to readability. |
| Reduce power | QRP | Reduce transmitter power; also used for low-power operation. |
| Arrange a later call | QRX | Pause; the sender will call again later. |
| Give a location | QTH | Introduce the station's location. |

### Memory trick: interference or natural noise

- Helps remember: the difference between QRM and QRN.
- Trick: M can suggest man-made signals; N can suggest natural noise.
- Limit: this cue does not decode every Q signal. Learn the operating job of each group separately.

On voice, use plain language when it is clearer. Abbreviations help only when both operators understand them.

## Try it

Try these without looking back. Finish the power example before reading the feedback.

1. Under the calibrated, stable-path model, a transmitter drops from 48 W to 12 W. Fill in the two halvings: 48 W -> ___ W -> 12 W. Predict the meter change.
2. You need slower Morse, then the signal fades before you copy the next word. Which group requests a slower pace, and which describes the fading?
3. A relayed voice signal is very strong, but several words are lost in rough audio. Why should the report separate readability from strength?

### Check your thinking

1. The missing power is 24 W. The power becomes a quarter of its starting value, so expect roughly one S-unit downward. A changing path would make that prediction unreliable.
2. Use QRS for the pace and QSB for fading. One asks the operator to change something; the other describes reception.
3. The repeater output can be strong while speech remains hard to understand. Report both observations; do not add a Morse-tone digit to a voice report.

## Radio connection

Morse procedure is a listening loop, not a list of codes to recite. Check the channel, call at a usable pace, identify the stations, and report what arrived. A compact group is useful when it helps the next operator decide what to do.

## Common mistakes

- Calling faster than you can copy: the reply may arrive at that same pace.
- Treating K and R as the same handover: K invites a reply; R confirms receipt.
- Giving a strong signal full readability automatically: judge whether you can understand it.
- Treating an S-unit as a single power doubling: the calibrated model needs two doublings.
- Blaming every meter change on power: fading, antennas, and receiver settings also matter.
- Using Q signals on voice when plain words would avoid confusion.

## Illustration brief

Alt text: A Morse contact flow showing a busy-frequency check, CQ, DE, call signs, a signal report, and sign-off.

Description: Draw a small timeline with dots and dashes above labels: QRL? and listen, CQ CQ CQ, DE, caller call sign, answer, RST, and 73. Add a side panel with three meter-style gauges labelled readability, strength, and tone. Use a note that S-unit power shortcuts depend on the stated meter calibration and stable path conditions.

## Summary

A successful contact matches pace and procedure to what the other operator can copy. Calling groups tell listeners who should answer; RS and RST separate the quality of reception into useful parts. Q signals shorten specific tasks, while calibrated meter steps offer only a conditional estimate of power change.
