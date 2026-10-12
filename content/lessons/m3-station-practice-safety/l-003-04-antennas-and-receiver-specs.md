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

A station is more than boxes and cables. The antenna decides where RF energy is sent or received. The receiver decides how well weak and crowded signals can be used.

This lesson links a simple Yagi's physical parts with receiver terms. You will use bandwidth, sensitivity, selectivity, dynamic range, automatic gain control, IF frequency, filters, and waterfall displays.

## Learning objectives

By the end of this lesson, you can:

- identify the boom, driven element, reflector, and director in a three-element Yagi;
- compare CW, SSB voice, and FM voice bandwidths;
- read sensitivity, selectivity, dynamic range, and AGC statements in plain language;
- calculate high-side local oscillator frequency and image frequency in original examples; and
- choose receiver filter widths for SSB and CW operating situations.

## The basic Yagi

A basic Yagi has radiating elements mounted along a support boom:

```text
reflector ---- driven element ---- director
        all mounted along the boom
```

The boom is the mechanical support. The driven element is where the feedline attaches. The reflector is the longer radiating element behind the driven element. The director is the shorter radiating element toward the main forward direction.

The parasitic elements are not directly fed. Their length and placement shape the pattern.

### Worked example: identifying parts from a sketch

A sketch shows three horizontal rods on a boom. The centre rod has the coax attached. The rear rod is 5.4 m long, the centre rod is 5.1 m long, and the forward rod is 4.8 m long.

- The boom is the support that holds all three rods.
- The 5.1 m rod with coax is the driven element.
- The 5.4 m rod is the reflector because it is the longest radiating element.
- The 4.8 m rod is the director because it is the shortest radiating element.

## Bandwidth and emission width

Bandwidth means occupied frequency range. For these lessons, CW is narrowest, SSB voice is wider, and FM voice is wider still. Wider signals are not automatically bad, but they use more spectrum and need a matching receiver bandwidth.

A receiver bandwidth that is too narrow can remove part of the information you want. A bandwidth that is too wide lets in extra noise and nearby interference.

## Receiver performance terms

Sensitivity describes how small an RF input signal can be while still producing a specified signal-to-noise result. It is a weak-signal measurement for the receiver input.

Selectivity describes how well the receiver separates the desired signal from nearby signals. IF filters usually provide most of this ability. For CW, a narrow audio band-pass filter about 100 Hz wide, centred on your tone, works well. With an 800 Hz tone, 100 Hz total width means about 50 Hz below and 50 Hz above the tone, so the passband is roughly 750 Hz to 850 Hz.

Dynamic range describes how well the receiver handles strong and weak signals at the same time. A receiver with poor dynamic range may overload, block, or make unwanted mixing products.

Automatic gain control, or AGC, reduces audio volume swings when signal strength changes. It does not replace filtering, and it does not make the receiver infinitely sensitive.

A waterfall display, or spectrogram, shows signals across the tuned spectrum as time scrolls. Brightness or colour shows amplitude, or relative signal strength.

### In the real world: filter choice on a busy display

A receiver has 300 Hz, 600 Hz, 2.7 kHz, and 8 kHz filters. The waterfall shows a CW signal with another signal 500 Hz away.

- Given: wanted mode = CW; nearby spacing = 500 Hz; available filters = 300 Hz, 600 Hz, 2.7 kHz, 8 kHz.
- Find: the best first filter choice for rejecting the nearby signal.
- Rule of thumb: choose the narrowest filter that still passes the wanted signal comfortably.
- Compare: 300 Hz gives stronger rejection; 600 Hz may tune more comfortably but has wider skirts. Filter skirts are the sloped edges where rejection increases outside the passband.
- Answer: try the 300 Hz filter first.
- Sanity check: the nearby signal may still leak through real filter skirts, but the narrower filter is the better first test.

For SSB voice, 2.7 kHz is the better match in this filter set.

## Local oscillator and image basics

A superheterodyne receiver converts the desired signal to an intermediate frequency. If the local oscillator is above the desired signal, use:

```text
local oscillator frequency = signal frequency + IF
```

An image is another frequency that can mix with the same local oscillator to produce the same IF. With high-side injection, the image is above the desired signal by twice the IF.

```text
image frequency = signal frequency + 2 x IF
```

### Worked example: local oscillator and image

A receiver is tuned to 7.120 MHz. It uses a 455 kHz IF and runs the local oscillator above the signal.

```text
IF = 455 kHz = 0.455 MHz
local oscillator = 7.120 MHz + 0.455 MHz = 7.575 MHz
image = 7.120 MHz + 2 x 0.455 MHz = 8.030 MHz
```

The image is not the station you intended to hear. Front-end filtering helps reject it before the mixer.

## Tuning accuracy for narrow modes

SSB needs accurate tuning because the receiver must recreate audio from a signal with no full carrier. A small tuning error shifts the recovered speech frequencies. Voices become high, low, or distorted.

AM carries its own carrier for envelope detection, so modest tuning error is usually less critical than with SSB voice. FM receivers recover audio from frequency deviation inside the receiver passband. CW also needs careful tuning, but a small tuning offset mainly changes the pitch of the received tone.

## Try it

1. A three-element Yagi is rebuilt on a nonconductive boom, but the element lengths and feed point stay the same. Why have the RF roles not moved to the boom? The radiating elements and feed point set the RF roles; the boom holds them in position.
2. Match these receiver filters to likely uses: 400 Hz, 2.8 kHz, and 7 kHz. Use 400 Hz for narrow CW, 2.8 kHz for SSB voice, and 7 kHz for a wider signal.
3. A receiver uses a 10.7 MHz IF and tunes a 52.0 MHz signal with the oscillator above the signal. What is the oscillator frequency? Add the IF: 52.0 MHz + 10.7 MHz = 62.7 MHz.
4. With the same 52.0 MHz signal and 10.7 MHz IF, where is the high-side image? The image is signal + 2 x IF = 52.0 MHz + 21.4 MHz = 73.4 MHz.

## Radio connection

Turning a Yagi changes the direction where the antenna is most sensitive. Narrowing a receiver filter changes which part of the spectrum reaches the detector and audio chain. Both choices improve selectivity, but one works in space and the other works in frequency.

## Common mistakes

- Calling the boom a radiating element because it is long and visible.
- Swapping director and reflector lengths. The reflector is longer; the director is shorter.
- Treating sensitivity, selectivity, and dynamic range as the same specification.
- Choosing the widest receiver filter because it sounds louder; wider also admits more noise and adjacent signals.
- Forgetting to convert 455 kHz to 0.455 MHz before adding it to an MHz frequency.

## Illustration brief

Alt text: A labelled Yagi antenna appears beside a receiver display and filter choices, with an image-frequency marker shown above the desired signal.

Description: Draw a three-element Yagi from above. Label the boom, longer reflector, driven element with feedline, and shorter director. Beside it, draw a small waterfall display with a frequency scale and brighter streaks for stronger signals. Add a number-line example showing desired signal, local oscillator, and image separated by the IF spacing.

## Summary

- In a three-element Yagi, the boom supports, the driven element connects to the feedline, the reflector is longer, and the director is shorter.
- CW is narrower than SSB voice, and SSB voice is narrower than FM voice.
- Sensitivity is about weak signals; selectivity is about rejecting nearby signals; dynamic range is about handling very different signal strengths.
- AGC reduces volume swings caused by signal-strength changes.
- With high-side injection, local oscillator frequency equals signal frequency plus IF, and the image is two IFs above the desired signal.
- Filter width should match the mode and the interference problem.
