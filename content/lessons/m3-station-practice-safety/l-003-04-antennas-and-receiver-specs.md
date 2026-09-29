---
type: lesson
id: L-003-04
moduleId: M3
categoryIds:
  - B-003
title:
  en: "Yagi parts and receiver specifications"
  fr: null
covers:
  - B-003-009
  - B-003-010
objectives:
  - "Identify boom, driven element, reflector, and director in a simple Yagi."
  - "Rank emission bandwidths from narrow to wide."
  - "Interpret common receiver specifications and waterfall displays."
prerequisites:
  - L-003-03
estimatedMinutes: 45
quizIds:
  - QZ-L-003-04-A
status: draft
---
# Yagi parts and receiver specifications

A station is not only boxes and cables. The antenna decides where RF energy is received or sent, and the receiver specifications decide how well weak and crowded signals can be used. This lesson links a simple Yagi's physical parts with practical receiver terms: bandwidth, sensitivity, selectivity, dynamic range, AGC, IF frequency, filters, and waterfall displays.

## Learning objectives

By the end of this lesson, you can:

- identify the boom, driven element, reflector, and director in a three-element Yagi;
- compare CW, SSB voice, and FM voice bandwidths;
- read sensitivity, selectivity, dynamic range, and AGC statements in plain language;
- calculate high-side local oscillator frequency and image frequency in original examples; and
- choose receiver filter widths for SSB and CW operating situations.

## The basic Yagi

A basic Yagi has one support member and a set of radiating elements arranged along it:

```text
reflector ---- driven element ---- director
        all mounted along the boom
```

The boom is the mechanical support. It is not the radiating element named by the feedline. The driven element is the place where the feedline attaches. The reflector is the longer radiating element behind the driven element. The director is the shorter radiating element toward the main forward direction.

This matches the antenna ideas from Module 6: the parasitic elements are not directly fed, but their length and placement shape the pattern.

### Worked example: identifying parts from a sketch

A sketch shows three horizontal rods on a boom. The centre rod has the coax attached. The rear rod is 5.4 m long, the centre rod is 5.1 m long, and the forward rod is 4.8 m long.

- The boom is the support that holds all three rods.
- The 5.1 m rod with coax is the driven element.
- The 5.4 m rod is the reflector because it is the longest radiating element.
- The 4.8 m rod is the director because it is the shortest radiating element.

## Bandwidth and emission width

Bandwidth means occupied frequency range. As a practical comparison for these lessons, CW is narrowest, SSB voice is wider, and FM voice is wider still. Wider signals are not automatically bad, but they occupy more spectrum and need appropriate receiver bandwidth.

A receiver bandwidth that is too narrow can remove part of the information you are trying to hear. A bandwidth that is much wider than needed lets in extra noise and nearby interference.

## Receiver performance terms

Sensitivity describes how small an RF input signal can be while still producing a specified signal-to-noise result. It is a weak-signal performance measurement for the RF input path, not a count of parts or a statement about how loud the speaker can play.

Selectivity describes how well the receiver separates the desired signal from nearby signals. IF filters usually provide most of this ability. For example, a 2.6 kHz filter is a common SSB voice choice, while a very narrow filter such as 350 Hz can help CW during interference.

Dynamic range describes how well the receiver handles strong and weak signals at the same time without overload, blocking, or unwanted mixing products. It is the third major performance idea to keep beside sensitivity and selectivity.

Automatic gain control, or AGC, reduces the change in audio volume when signal strength changes a lot. It does not replace filtering, and it does not make the receiver infinitely sensitive.

A waterfall display, or spectrogram, lets the operator see where signals sit across the tuned spectrum and how strong they appear by brightness or colour as time scrolls.

### Worked example: filter choice

A receiver has 300 Hz, 600 Hz, 2.7 kHz, and 8 kHz filters. For SSB voice, 2.7 kHz is the best match in this group because it is wide enough for speech but not as open as the 8 kHz filter.

For crowded CW, the 300 Hz filter is the better choice because it narrows the passband around the tone and rejects nearby signals. If the operator wants easier tuning, the 600 Hz filter may be more comfortable, but the narrowest choice gives the strongest interference rejection in this set.

## Local oscillator and image basics

A superheterodyne receiver converts the desired signal to an intermediate frequency. If the local oscillator is above the desired signal, use:

```text
local oscillator frequency = signal frequency + IF
```

An image is another frequency that can also mix with the same local oscillator to produce the same IF. With high-side injection, the image is above the local oscillator by the IF, so it is above the desired signal by twice the IF.

```text
image frequency = signal frequency + 2 x IF
```

### Worked example: local oscillator and image

A receiver is tuned to 7.120 MHz, uses a 455 kHz IF, and runs the local oscillator above the signal.

```text
IF = 455 kHz = 0.455 MHz
local oscillator = 7.120 MHz + 0.455 MHz = 7.575 MHz
image = 7.120 MHz + 2 x 0.455 MHz = 8.030 MHz
```

The image is not the station you intended to hear. Front-end filtering helps reject it before the mixer.

## Tuning accuracy for narrow modes

SSB needs accurate tuning because there is no full carrier for the receiver to lock onto in the simple voice-recovery sense. A small tuning error shifts the recovered speech frequencies, so voices become high, low, or distorted instead of merely louder or softer. CW also uses narrow filters and careful tuning, but a small tuning offset mainly changes the pitch of the received tone; the operator can often retune for a comfortable note.

## Try it

Question: In a small Yagi, which part does the coax feed, and which part mainly supports the elements?

Worked answer: The coax feeds the driven element. The boom mainly provides mechanical support.

Question: Put these receiver filters with likely uses: 400 Hz, 2.8 kHz, and 7 kHz.

Worked answer: 400 Hz fits narrow CW work, 2.8 kHz fits SSB voice, and 7 kHz is wider than needed for those two examples.

Question: A receiver uses a 10.7 MHz IF and tunes a 52.0 MHz signal with the oscillator above the signal. What is the oscillator frequency?

Worked answer: Add the IF: 52.0 MHz + 10.7 MHz = 62.7 MHz.

Question: With the same 52.0 MHz signal and 10.7 MHz IF, where is the high-side image?

Worked answer: The image is signal + 2 x IF = 52.0 MHz + 21.4 MHz = 73.4 MHz.

## Radio connection

When you turn a Yagi, you change the direction where the antenna is most sensitive. When you narrow a receiver filter, you change which part of the spectrum reaches the detector and audio chain. Both are selectivity tools: one works in space, and the other works in frequency.

## Common mistakes

- Calling the boom a radiating element because it is long and visible.
- Swapping director and reflector lengths. The reflector is longer; the director is shorter.
- Treating sensitivity, selectivity, and dynamic range as the same specification.
- Choosing the widest receiver filter because it sounds louder; wider also admits more noise and adjacent signals.
- Forgetting to convert 455 kHz to 0.455 MHz before adding it to an MHz operating frequency.

## Illustration brief

Alt text: A labelled Yagi antenna appears beside a receiver display and filter choices, with an image-frequency marker shown above the desired signal.

Description: Draw a three-element Yagi from above. Label the boom, longer reflector, driven element with feedline, and shorter director. Beside it, draw a small waterfall display with a frequency scale and brighter streaks for stronger signals. Add a number-line example showing desired signal, local oscillator, and image separated by the IF spacing.

## Summary

- In a three-element Yagi, the boom supports, the driven element connects to the feedline, the reflector is longer, and the director is shorter.
- CW is narrower than SSB voice, and SSB voice is narrower than FM voice.
- Sensitivity is about weak-signal input for a stated signal-to-noise result; selectivity is about rejecting nearby signals; dynamic range is about handling very different signal strengths.
- AGC reduces volume swings caused by signal-strength changes.
- With high-side injection, local oscillator frequency equals signal frequency plus IF, and the image is two IFs above the desired signal.
- Filter width should match the mode: narrow for CW interference, a few kilohertz for SSB voice.
