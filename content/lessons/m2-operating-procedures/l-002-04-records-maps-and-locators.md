---
type: lesson
id: L-002-04
moduleId: M2
categoryIds:
  - B-002
title:
  en: "Records, maps, and locators"
  fr: null
covers:
  - B-002-009
objectives:
  - "Explain QSL confirmations and useful logbook habits."
  - "Use UTC, bearings, and azimuthal maps in contact planning."
  - "Recognize Maidenhead grid locators and long-path direction."
prerequisites:
  - L-002-01
  - L-007-01
estimatedMinutes: 35
quizIds:
  - QZ-L-002-04-A
status: draft
---
# Records, maps, and locators

Two operators can log the same contact under different local dates. One may be finishing an evening while the other has started a new day. A shared time standard and clear location notes let them match the contact later.

Maps answer another operating question: where should a directional antenna point? Records and maps turn a brief exchange into information you can use again.

## Learning objectives

By the end of this lesson, you can:

- explain how QSL cards and web logs confirm contacts;
- choose useful log details without treating a log as a Canadian regulatory requirement;
- recognize a Maidenhead locator as compact location information;
- use a station-centred azimuthal map and an opposite long-path bearing; and
- convert UTC to local time while keeping the date correct.

## Make a contact easy to match

A QSL card confirms that two amateur stations completed a contact. Entries in web-based logging systems can provide a confirming role too. Matching details let the operators distinguish that contact from another one on the same band.

Canadian amateur station logs are optional, not a regulatory requirement. They are still useful for awards, memories, matching confirmations, and checking later interference enquiries.

Record enough information to identify what happened: UTC date and time, the other call sign, band or frequency, mode, signal report, location, and useful station notes. A power or antenna change can matter when you compare results later.

### In the real world: a log narrows an interference enquiry

A neighbour reports a burst of interference at 0215 UTC. Your log shows the band and mode used at that time, with a note about an antenna change.

That record gives the investigation a starting point. It does not prove that your station caused the problem. Compare the reported time with your actual activity before drawing conclusions.

## Use a compact location label

A Maidenhead locator divides geography into labelled areas, often called grid squares. Its four- or six-character code gives operators a compact, shared way to describe location. VHF contests use these labels to exchange locations quickly.

A locator identifies a geographic area; it is not a signal report or a compass bearing. It gives contest and weak-signal operators location information that is quick to send. At VHF and UHF, location matters because terrain and line-of-sight paths can change over short distances.

## Take bearings from your own station

An azimuthal map is drawn around a chosen centre. When your station is that centre, lines radiating outward show bearings from you to other places. A map centred elsewhere does not give your station's bearings directly.

For a distant contact, the shorter great-circle route is called short path. Long path goes the other way around the globe. Its initial heading is the reciprocal: 180 degrees away from the short-path heading.

If short path gives poor reception, try the opposite direction. Propagation may favour that longer route at the time. The map gives a direction to try, not a promise that either path will work.

### Worked example: aim the other way

Suppose a station-centred map gives a short-path bearing of 65 degrees for a distant contact.

- Given: short-path heading = 65 degrees.
- Find: long-path heading.
- Formula: use the opposite bearing; add 180 degrees, subtracting a full 360-degree turn if needed.
- Substitute: long-path heading = 65 + 180 degrees.
- Answer: long-path heading = 245 degrees.
- Sanity check: the new heading is half a turn from the original, not a small trim of the antenna.

### Faded practice: wrap a bearing around north

Your station-centred map gives a short-path heading of 248 degrees.

- Given: short-path heading = 248 degrees.
- Find: the opposite long-path heading.
- Formula: add 180 degrees, then subtract 360 degrees if the result reaches a full turn.
- Complete: 248 + 180 = ___; ___ - 360 = ___ degrees.
- Sanity check: are the original and new headings half a turn apart?

Work through the wrap before checking.

### Check your work: bearing wrap

248 + 180 = 428; 428 - 360 = 68 degrees. Try 68 degrees for long path. This changes the direction to test, not the available propagation.

### Memory trick: the other way around

- Helps remember: long-path direction relative to short path.
- Trick: reverse the heading by half a circle.
- Limit: opposite headings describe geometry. They do not guarantee a usable radio path.

::figure records-maps-locators
Alt text: A station log beside an azimuthal map centred on the operator, with a grid locator label.
Text equivalent:
- The log column initials mean UTC, call sign, band, mode, report, and grid.
- The azimuthal map shows a short arrow and the opposite long arrow through the centre.
- The clock is labelled UTC and the map has a grid label.
::

## Keep one clock for the contact

UTC means Coordinated Universal Time. Amateur schedules, logs, and contact confirmations use it to describe the same moment across time zones. The reference meridian runs through Greenwich in the United Kingdom.

A zone described as UTC minus an offset is behind UTC. Subtract that offset to find local time from UTC. If the subtraction crosses midnight, the local date is the previous day. Keep the UTC date attached to UTC time in the log, even when you also write a local-time reminder.

Use the offset that applies on the contact date, including any seasonal clock change. The examples below give an offset explicitly; they are not year-round rules for a named Canadian city.

### Worked example: a schedule in local evening time

A club lists a net at 2245 UTC. Your local time for that date is UTC minus 5 hours.

- Given: UTC = 2245; local offset = minus 5 h.
- Find: local net time.
- Formula: local time = UTC - offset magnitude for this UTC-minus zone.
- Substitute: local time = 2245 - 0500.
- Answer: 1745 on the same date, or 5:45 PM.
- Sanity check: the local clock is behind UTC, so it must read earlier.

### Worked example: crossing into the previous local date

A contact occurs at 0210 UTC on 12 April. The stated local offset is still UTC minus 5 hours.

- Given: UTC date = 12 April; UTC time = 0210; offset = minus 5 h.
- Find: local date and time.
- Formula: subtract the offset, carrying the date back when crossing midnight.
- Substitute: 0210 - 0500 = 2110 on the previous local date.
- Answer: 11 April at 2110, or 9:10 PM locally.
- Sanity check: adding the offset back reaches 0210 on 12 April. The log still records the contact's UTC date as 12 April.

### Faded practice: carry the local date back

An event is at 0325 UTC on 18 June. The stated local offset is UTC minus 4 hours.

- Given: UTC = 0325 on 18 June; offset = minus 4 h.
- Find: local time and date.
- Formula: subtract the offset magnitude; carry the date back if needed.
- Complete: 0325 - 0400 = ___ on ___ June.
- Sanity check: add 4 hours to your local answer. Does it reach the original UTC time and date?

Keep the date beside your answer before checking.

### Check your work: local date

The local reminder is 2325 on 17 June, or 11:25 PM. Adding 4 hours reaches 0325 on 18 June. The UTC log entry keeps 18 June.

### Check time and frequency against a standard

Standard time and frequency stations CHU, WWV, and WWVH provide accurate reference signals. Operators can use them to check time or frequency, supporting careful logging and receiver checks.

## Try it

Work these out before reading the feedback. Keep dates beside your times.

1. An event is at 0145 UTC on 20 May. Your stated zone is UTC minus 5 hours. Find the local date and time, including an AM/PM version.

:::answer
The local reminder is 2045 on 19 May, or 8:45 PM. Keep 20 May and 0145 together in the UTC log entry.
:::

2. A map shows a short-path heading of 235 degrees. Find the long-path heading.

:::answer
235 + 180 = 415; 415 - 360 = 55 degrees. The headings point opposite ways.
:::

3. Your contact partner's local date differs from yours. Which record fields should you compare before assuming you logged different contacts?

:::answer
Compare UTC date and time along with call signs, band or frequency, and mode. Local dates alone can differ for the same moment.
:::

## Radio connection

A location label, a bearing, and a time each answer a different question. Together they help you aim an antenna, recognize a contact, and compare conditions later. Clear records also give interference investigations facts rather than guesses.

## Common mistakes

- Treating an optional log as pointless: it still supports confirmations, awards, and investigations.
- Reading a grid locator as an antenna heading: use location information with the right map.
- Taking your bearing from a map centred on another station: use your own centre.
- Adding the offset when converting from UTC to a UTC-minus zone: that zone is behind, so subtract.
- Changing the clock but forgetting the date: check whether the conversion crossed midnight.
- Treating long path as guaranteed: it is another direction to test under current conditions.

## Illustration brief

Alt text: A station log beside an azimuthal map centred on the operator, with a grid locator label.

Description: Draw a notebook page with columns for UTC, call sign, band, mode, report, and grid. Beside it, show a circular azimuthal map centred on the operator's home, with one arrow labelled short path and an opposite arrow labelled long path, 180 degrees apart. Add a small clock labelled UTC and Greenwich.

## Summary

Useful records describe the same contact consistently: who, where, when, and how. UTC removes time-zone ambiguity, while locators and station-centred maps connect location to direction. A log and a map do not prove a cause or guarantee a path, but both give the next operating decision a firmer starting point.
