# TASK-73: rounded-control measurement

Owner-delegated decision 2026-10-22, coordinator: extend the TASK-71 measured
path narrowly for rounded **buttons**, not general multi-background elements.
The earlier [2× thin-stroke investigation](task-73-contrast-2x-blocked.md) remains
**unresolved**. Its unsafe per-pixel prototypes are not part of this change.

## Fixture and smallest-inset sweep

Unaltered element screenshot supplied for this task:

- Source: `/tmp/t73-fixtures/iphone-hide-answer-button-light-3x.png`.
- Fully visible secondary button, label **Hide answer 1**, iPhone 17 Pro, 3×.
- Size: **452 × 151 native pixels**; dark text on a beige pill with cream page
  corners. The two substantial background tones produce a low full-image ratio.
- Bundled resource:
  `apps/apple/CanadianHamUITests/Resources/ContrastMeasurement/iphone-hide-answer-button-light-3x.png`.
- SHA-256: `1d17fa526497f384ce5de88375dbe24eb7cf0aa239437c4ff60982cd4e768c2a`.

The supervisor refined the initially proposed 16 pt horizontal cap: test caps
**4, 6, 8, 12, 16 pt**, always with **2 pt vertical inset**, and choose the
**smallest** passing cap. Host-only measurements used the unchanged base
algorithm, native CGImage crops, no resampling:

| Horizontal cap | Native crop (x, y, width, height) | Ratio |
| --- | --- | ---: |
| Full image | 0, 0, 452, 151 | 1.1993729121750754 |
| 4 pt | 12, 6, 428, 139 | 1.1994004247924492 |
| **6 pt (selected)** | **18, 6, 416, 139** | **13.620392055674973** |
| 8 pt | 24, 6, 404, 139 | 13.620385825726265 |
| 12 pt | 36, 6, 380, 139 | 13.620313173154122 |
| 16 pt | 48, 6, 356, 139 | 13.620293214245946 |

Sweep command: `swift /tmp/task-73-control-inset-sweep.swift`, log
`/tmp/task-73-control-inset-sweep.log`. This is diagnostic evidence, not XCTest.
The bundled fixture has a separate XCTest regression for the selected 6 pt cap.

## Implementation and constraints

`measuredControlTextContrast(in:scale:isButton:)` first runs
`measuredTextContrast(in:)` over the entire image. A non-button always returns
that unchanged result. A passing (≥4.5) full image also returns unchanged,
without a crop. Only a button with a nil or below-4.5 full image may retry:

- Horizontal native-pixel inset: `ceil(min(image.height / 2, 6 × scale))`.
- Vertical native-pixel inset: `ceil(2 × scale)`.
- Scale must be finite and positive; the crop must have positive dimensions.
- The retry runs **the exact same base algorithm** on a native crop. Background
  dominance, significant coverage, minimum-ratio semantics, retained-core/blend
  rules, radius-two checks and component-boundary validation are unchanged.
- Return only the crop's result, including nil if it cannot be measured. No
  search for a more flattering crop, threshold change or image resampling.

The shared `auditVerifyingMeasuredContrast` passes the actual
`element.elementType == .button` flag and pixels per point computed as
`image.width / element.frame.width`. It retains the fully-visible/below-bars
gate, full default accessibility audit, contrast-only handling and keepAlways
label/frame/ratio-or-unmeasurable logging. Owner decision 2026-10-22 approves
this guarded wrapper modification; the future PR needs the standalone marker:

```text
Test-guard-approved: owner decision 2026-10-22
```

Local TASK-46.5/TASK-46.6.1 composite helpers must use the **same** function,
with real element type and screenshot scale, in their measured paths. Their
integration is separate; no existing live audit call site is changed here and
the TASK-71 exception's approved scope is not widened.

## Known crop limits and adversarial proofs

This is a heuristic over retained image pixels, **not a contrast proof for the
entire button**. Text entirely within the horizontal 6 pt end strips or the
vertical 2 pt strips is excluded. A 6 pt cap is smaller than a typical 15 pt
wide glyph (the regression's M), reducing but not eliminating this risk: narrow
letters, punctuation, truncated labels, icons or very small text can fit there.
No semantic text recognition or control-padding safety guarantee is claimed.

`testRoundedButtonTextEntirelyWithinEndInsetsIsNotMeasured` deliberately shows
the false-pass limit: two low-contrast #9A9A9A glyph-width strokes, 4 × 30 pt,
lie wholly at x=1…5 and 145…149 in a 150 × 50 pt pill, with high-contrast text
in the middle. The full image fails; the cropped retry passes because those
strokes are gone. This test documents exclusion, not safety.

Fail-safe proofs retain actual 15 pt bold #9A9A9A text:

- Low-contrast **Hide answer 1** on beige at both 2× and 3× must be nil or <4.5.
- Low-contrast M glyphs near both ends, starting at x=6 and x=108, remain in
  the crop beside high-contrast middle text and must be nil or <4.5.
- Low-contrast middle text beside high-contrast text must also be nil or <4.5.

Other new proofs cover non-button fixture equality, nil non-button results,
passing full-image preservation, invalid scales and empty crops. All 31
pre-existing test methods and all three pre-existing PNG fixtures are retained;
`measuredTextContrast(in:)` itself is byte-identical to the starting revision.
Its existing sub-2% foreground, tiny-component, quantization, multi-background
and thin-stroke limits remain documented in the TASK-71 and blocked 2× notes.
The narrow approved audit scope, logged evidence and independent token-level
contrast checks remain essential mitigations.
