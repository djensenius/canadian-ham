# TASK-73: 2× iPad contrast investigation — blocked

**No measurement change is shipped.** The requested iPad fixture remains
unmeasurable. Two diagnostic prototypes recovered its expected ratio but
false-passed adversarial fixtures. Following the supervisor's explicit stopping
rule, only this evidence and task notes are retained; the temporary failing
regression and copied PNG were removed. No test was skipped or weakened.
TASK-73 stays In Progress with all four acceptance criteria unchecked.

## Input and baseline

- Source: `/tmp/t73-fixtures/ipad-given-line-light-2x.png`, an unaltered element
  screenshot from the TASK-46.5 iPad light audit.
- Label: “Given: initial report = S9 plus 19 dB; transmitter power falls from
  48 W to 24 W.”
- Size: **1194 × 40 native pixels**, 2× scale.
- SHA-256: `907f46b4181a2a3459cd05a0530fab1591ea6f3533d4708aa2d8ab62a19492b8`.
- Helper inspected: `apps/apple/CanadianHamUITests/UITestContrastMeasurement.swift`,
  unchanged from this task's starting implementation on main. Its macOS-safe
  `contrastMeasurementCGImage(from:)` bridge was not changed.

The fixture was temporarily copied into `Resources/ContrastMeasurement/` and
`testExportedIPadGivenLineLightAt2xPasses` temporarily called the existing
`assertExportedElementPasses` helper. This established an actual **red iPhone
17 Pro** proof against the unchanged measurement function:

```sh
nohup bash /tmp/task-73-before.sh > /tmp/task-73-before.log 2>&1 < /dev/null &
# Script exports DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer and runs:
xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -testPlan CanadianHamDefault \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CanadianHamUITests/UITestContrastMeasurementTests/testExportedIPadGivenLineLightAt2xPasses \
  -resultBundlePath /tmp/task-73-before.xcresult \
  test CODE_SIGNING_ALLOWED=NO
```

Polled with grep; the run waited for the shared lock, and no builds were killed.
**1 failed / 0 passed / 0 skipped**, exit **65**, test **0.978 s**. Failure:
`XCTUnwrap failed: expected non-nil value of type "Double"`. The post-test
`simctl` cleanup lookup warning is separate from that recorded assertion.
Log/result: `/tmp/task-73-before.{log,xcresult}`. Temporary red test source is
preserved locally at `/tmp/task-73-red-test-source.swift`, not shipped.

## Which rule returns nil

A host-only instrumented copy of the unchanged algorithm logs every component,
bounds, boundary/support counts, cluster means and blend classifications:
`/tmp/task-73-diagnostics.swift` and `/tmp/task-73-diagnostics.log`.

The dominant background is key **32765**, **35,344 pixels**, mean RGB
**(255,248,234)**. The only retained core is key **3170**, **3,417 pixels**,
RGB **(31,26,20)**, contrast **16.336427704401043:1** against that background.
There are no significant excluded blends and no low-contrast retained-colour
contacts.

Exactly one component fails: **295**, the lower horizontal stroke of `=`, at
inclusive native coordinates **(296,26)–(311,26)**. It has **16 pixels**, all
boundary pixels, of which only **4** have valid background support; **0** border
another retained foreground. The 50% boundary-support check correctly returns
nil on that evidence. The upper `=` stroke, at **(296,17)–(311,17)**, has
**16/16** supported boundary pixels and passes. The component floor is not the
cause.

Adjacent bins explain why support is missing. The radius-two colour-line tests
use *every pixel of a bin*, including pixels elsewhere in the image:

| Bin | Pixels | Mean RGB (rounded) | Projection fraction | RGB residual distance | Global spatial veto |
| --- | ---: | --- | ---: | ---: | --- |
| 8422 | 183 | (65.760,60.448,53.093) | 0.844994 | 0.094638 | 1 pixel elsewhere lacks background within radius 2 |
| 14796 | 35 | (117.486,112.000,102.971) | 0.612954 | 0.267497 | 1 pixel elsewhere lacks core within radius 2 |
| 7398 | 114 | (61.947,56.807,49.702) | 0.861434 | 0.113048 | 7 pixels lack background within radius 2 |
| 25333 | 41 | (192.829,186.244,174.415) | 0.278043 | 0.142534 | None; 32 pixels are background-connected |

The lower stroke's outside four-neighbours are bins 8422 and 14796 (16 contacts
each), plus one contact each with 7398 and 25333. Thus unrelated pixels veto
the two main edge colours for the entire bin. Increasing a pixel floor or
lowering the 50% share would conceal the problem rather than establish safety.

## Approved prototype and bounded final attempt

The supervisor approved a **support-only per-pixel** experiment:

1. Keep significant-blend exclusion globally strict, all coverage/colour
   thresholds, four-connectivity, the four-pixel component floor, retained-core
   contact checks, 50% boundary share and minimum-ratio semantics unchanged.
2. For bins below **2%**, allow individual support pixels only when they pass
   the same colour projection **0 < fraction ≤ 0.9**, RGB residual **≤ 8**, and
   have actual retained core **and** actual background within the radius.
3. Flood only valid support pixels, with each edge constrained to the **same
   supporting retained-core key**. Invalid pixels cannot bridge. Support-only
   pixels never enter the ratio or become retained cores.
4. Prototype a scale-derived radius: **ceil((2/3 pt) × pixels-per-point)**,
   capped at the existing **2 native pixels**. Rounding down to 1 pixel at 2×
   remained nil; the bounded outward conversion restored the iPad ratio without
   ever increasing the old two-pixel maximum. No scale API was shipped.

Host prototype: `/tmp/task-73-prototype.swift`; extracted image-only run:
`/tmp/task-73-prototype-ceil-host.swift`. It restores the iPad's
**16.336427704401043:1**, keeping all three existing 3× screenshots unchanged:
light feedback **8.344323837747055**, dark feedback **11.403364958858397**,
Try-it paragraph **16.336427704401043**.

But the full host harness found **three unsafe passes**. Work stopped and the
supervisor authorized exactly **one bounded attempt**: prohibit **all
significant-bin pixels** from being support or bridge pixels, including
previously globally validated significant blends, while changing nothing else.
That restriction also fails on the same three cases:

| Adversarial test | Required | Initial prototype | Bounded final attempt |
| --- | --- | ---: | ---: |
| Existing `testSubthresholdAntialiasedPanelEdgeCannotSupportInsetDarkStrokes` | nil | 15.9942758247219 | 15.9942758247219 |
| Existing `testDifferentCoreBlendsCannotBridgeInsetDarkStrokesToBackground` | nil | 14.426790204267782 | 14.426790204267782 |
| New `testSparseValidPanelEdgeSupportCannotRescueInsetStrokeAt2x` | nil | 15.9942758247219 | 15.9942758247219 |

The respective #404040 panel bins are already **subthreshold**: **92 pixels
(0.92%)**, **60 pixels (0.60%)**, and **121 pixels (1.21%)** after overdraw in
100×100 images. Banning significant bins therefore cannot exclude them. The
per-pixel rule admits some panel pixels as colour-line blends, unlike the
original whole-bin veto. The results prove that this support rule does **not**
establish the intended spatial safety. No additional refinement was attempted.

The new sparse-edge fixture is 50×50 pt at 2×: a native 7×20 #404040 panel
at (30,31), a native 1×16 near-black core at (33,32), a separate 16×40
near-black block at (5,10), and three intended blend pixels at x=32…34,y=31.
Those three edge pixels alone would support only **2/16** boundary pixels.
The observed high ratio shows that the prototype instead admits other panel
pixels; the required fail-safe proof is not met.

## Host harness coverage and evidence

The harness runs **all 31 existing test methods**, the iPad passing assertion,
and **five** new 2× proofs (inset panel, chained blend, partial overlap/attack 6,
mixed bold/grey, sparse-edge panel): **37 methods total, 34 pass / 3 fail**.
The first three new adversarial images draw the original geometries in a
100×100 pt context at 2× (200×200 pixels); mixed 15 pt bold text uses 400×96
pixels. Their nil-or-<4.5 assertions fail safe. The sparse-edge test fails as
reported above. Existing 3× screenshots and all other existing assertions pass.

This is a **host diagnostic harness**, not XCTest or live-audit integration:
it uses the same CoreGraphics/CoreText drawing and measurement bodies, with
assertion collectors replacing XCTest assertions and attachments removed.
`swift` itself exits 0; the explicit **`HOST_FAILURES=3`** output is the failed
validation result. No claim of a passing test suite is made.

```sh
swift /tmp/task-73-host-tests.swift > /tmp/task-73-host-tests.log 2>&1
swift /tmp/task-73-bounded-host-tests.swift > /tmp/task-73-bounded-host-tests.log 2>&1
grep -A1 -B1 '^FAIL' /tmp/task-73-bounded-host-tests.log
grep '^HOST_FAILURES' /tmp/task-73-bounded-host-tests.log
```

Final harness SHA-256:
`f59ceeb695320b8bed3d37d35f93fb202d83e4f844169ccb6f02d1dbc3ef9bf3`.
All prototype/harness files are local evidence under `/tmp`, not compiled app or
test source. The requested full iPhone measurement class and documented macOS
unit command were **not run**: the supervisor instructed stopping with notes
and evidence only if this bounded attempt false-passed an adversarial case.
No unsafe helper, failing/skipped regression, resource, app change, target
membership change, or new audit exception is shipped. No XcodeGen is needed.
The original helper's known limitations and narrow TASK-71 scope are unchanged.

**Next step:** independent review of these diagnostics and a separately approved,
stricter support model. Do not adopt the per-pixel prototype merely because it
recovers the real screenshot's ratio.
