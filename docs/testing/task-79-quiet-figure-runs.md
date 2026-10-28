# TASK-79: quiet-start figure-plan runs

Owner decision 2026-10-28: leave the eager lesson reader and every existing test,
full audit, assertion, handler and exception unchanged. The lazy-reader experiment
is closed; [its evidence](task-79-lazy-lessons.md) is historical, not this change.
There is no audit retry, filter, new exception or timeout increase.

## Runner and reproducibility

Run the figure plan only with `scripts/run-figure-plan-quiet.sh`. The coordinator
starts no other Apple lanes during its wait or execution. The script waits for
five-minute host load <= `1.5 * sysctl -n hw.ncpu` (15 on this ten-logical-CPU
host), checks every 60 seconds, and refuses to launch after its 7200-second wait
timeout. `--max-load-factor`, `--wait-timeout` (seconds) and `--out` configure
those settings. Other arguments are passed unchanged to `xbuild`.

It runs the `CanadianHamLessonFigures` plan on one iPhone 17 Pro simulator,
serial testing, through the unchanged shared `xbuild` wrapper and its build lock.
Each completed test output directory contains `command.txt`, `xbuild.log`, `xbuild.exit`,
`figures.xcresult`, `load.log` and `summary.txt`. Runtime samples contain UTC and
1/5/15-minute loads every 60 seconds, plus launch/completion samples. Max/median
use the **one-minute** samples; separate maxima retain all three load windows.
They include build, any lock wait, simulator startup, tests and wrapper cleanup,
not just the audit calls. Per-iteration durations below are whole test methods,
not audit-call times. `-test-iterations` repeats every selected test a fixed number
of times; it is not an until-success retry.

Fast, Xcode-independent integration coverage runs with
`pnpm test:figure-plan-quiet` (also part of `pnpm test`). Six fake-command scenarios
cover high-to-low waiting and the threshold boundary, exact arguments including
spaces and selections, sampling/median/max reporting, exit 65 propagation,
timeout without launch, configurable factor/timeout, and invalid loads/options.
The runner is exercised with `/bin/bash` (macOS Bash 3.2 here).

## Recorded runs — 2026-10-28

Implementation: `d91f7210d621bfd610231b9e8bf781c54f762bf0` (no app or Apple test
source changes). The requested M7 5/5 and Ohm's-law dark/light 3/3 each
have passed, with no `Code=-56`. A coordinator-authorized separate quiet-start
light visit also passed 1/1 after external contention ended (details below).
All twelve executed test visits passed; none was skipped.
Artifacts are retained locally under
`/var/tmp/canadian-ham-task-79-quiet-20261028/`; sibling `*-console.log` files also
retain the quiet-host wait and final report. No full Apple suites or other
platforms were run: this task changes only the host runner and documentation,
and explicitly validates the three selected iOS figure methods.

### Module 7 dark sample

```sh
scripts/run-figure-plan-quiet.sh \
  --out /var/tmp/canadian-ham-task-79-quiet-20261028/m7 \
  -only-testing:CanadianHamUITests/CanadianHamLessonFiguresUITests/testModule7LessonFigureDarkSample \
  -test-iterations 5
```

- Quiet-host wait: 0 seconds. Launch load (1/5/15m): **3.20 / 4.84 / 6.43**.
- xbuild interval: **15:12:50–15:32:17 UTC**, **1167 seconds**, exit **0**;
  finalized result bundle `m7/figures.xcresult`, `TEST SUCCEEDED`.
- Runtime one-minute load: **max 202.83, median 62.08**, 21 samples.
- Runtime maxima (1/5/15m): **202.83 / 109.40 / 63.39**.
- **5/5 passed**, no skips, no `Code=-56` in the console log.

| Iteration | Result | Whole-method seconds |
| --- | --- | ---: |
| 1 | Pass | 234.184 |
| 2 | Pass | 217.936 |
| 3 | Pass | 203.028 |
| 4 | Pass | 211.930 |
| 5 | Pass | 222.692 |

### Ohm's-law dark/light — original fixed three visits each

```sh
scripts/run-figure-plan-quiet.sh \
  --out /var/tmp/canadian-ham-task-79-quiet-20261028/ohms \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testOhmsLawLessonFiguresAndAccessibilityLight \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testOhmsLawLessonFiguresAndAccessibilityDark \
  -test-iterations 3
```

- Quiet-host wait: **240 seconds** (15:35:25–15:39:25 UTC). The script
  correctly held off at five-minute loads 27.01, 22.46, 19.07 and 16.13.
- Launch load (1/5/15m): **3.09 / 13.76 / 33.23**.
- xbuild interval: **15:39:25–17:53:46 UTC**, **8061 seconds**, exit **0**;
  finalized result bundle `ohms/figures.xcresult`, `TEST SUCCEEDED`.
- Runtime one-minute load: **max 439.77, median 58.00**, 136 samples.
- Runtime maxima (1/5/15m): **439.77 / 285.96 / 198.88**.
- **Dark 3/3, light 3/3 passed**, no skips, no `Code=-56` in the console log.
  The finalized `xcresulttool` device summary independently reports six passed
  runs, zero failures and zero skips (two unique methods).

| Method | Iteration | Result | Whole-method seconds |
| --- | --- | --- | ---: |
| Dark | 1 | Pass | 1311.638 |
| Dark | 2 | Pass | 1318.751 |
| Dark | 3 | Pass | 1323.950 |
| Light — contended invocation | 1 | Pass | 1422.550 |
| Light — contended invocation | 2 | Pass | 1411.309 |
| Light — contended invocation | 3 | Pass | 1227.882 |

**External contention during the light visits:** at **17:02:13 UTC**, load was
**385.06 / 238.43 / 164.99**. An external **FluxKlang xcodebuild PID 12927**
was running directly, bypassing the shared `xbuild` lock, on another simulator
(`7F7F138F-5D28-45B2-886E-294B8BEEB17A`). Our xcodebuild PID was 58010.
Snapshot: `/var/tmp/canadian-ham-task-79-quiet-20261028/ohms/host-snapshot-1702.txt`.
At **17:29:05 UTC**, another direct FluxKlang invocation (**PID 81955**) was
present, load **264.28 / 199.92 / 168.54**; snapshot in the same directory,
`host-snapshot-1729.txt`. These are observations at those instants, not proof
that either external PID ran throughout every light iteration.

The coordinator explicitly directed continuing the unchanged fixed-iteration
invocation, labelling the original light results **contended**, and then making
**one separate gated light visit** if time/load permitted. No external process
was stopped or modified. Passing with this contention is useful robustness
evidence; it is **not quiet-runtime evidence** or a causal comparison.

### Separate quiet-start light control — one visit

```sh
scripts/run-figure-plan-quiet.sh \
  --out /var/tmp/canadian-ham-task-79-quiet-20261028/ohms-light-quiet-one-default \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testOhmsLawLessonFiguresAndAccessibilityLight
```

- Quiet-host wait: **0 seconds**, launch load **2.84 / 10.68 / 50.73**.
- xbuild interval: **18:01:35–18:22:13 UTC**, **1238 seconds**, exit **0**.
- **1/1 passed, 1193.450 seconds**, no skips or `Code=-56`; finalized bundle
  `ohms-light-quiet-one-default/figures.xcresult`. The independent `xcresulttool`
  summary reports one passed, zero failed, zero skipped.
- Runtime one-minute load: **max 172.72, median 38.86**, 22 samples.
- Runtime maxima (1/5/15m): **172.72 / 71.27 / 70.00**.
- The 18:04:55 UTC snapshot showed only this xcodebuild (PID 98484), with CPU
  dominated by simulator poster extensions, not another build; the completion
  snapshot showed no xcodebuild/lockf. Files in this run's output directory:
  `host-snapshot-first-check.txt` and `host-snapshot-completion.txt`.
  These point-in-time checks are not a continuous process census. This is a
  gate-qualified **quiet-start control**, not a claim of low runtime load.

**Preflight error retained, not counted as a test visit:** the first attempt at
this extra control explicitly passed `-test-iterations 1`. Xcode rejects that
option unless the count is greater than one: exit **64**, **one-second** xbuild
wall time, **zero tests/audits executed**, no result bundle. It had waited
**300 seconds** (17:54:39–17:59:39 UTC), then launched at **3.43 / 14.61 / 57.75**;
the two endpoint samples gave one-minute max/median **3.43 / 3.43** (maxima
1/5/15m **3.43 / 14.61 / 57.75**). All artifacts remain in
`/var/tmp/canadian-ham-task-79-quiet-20261028/ohms-light-quiet-one/` and its sibling
console log. Omitting that option correctly executes one default visit, as in
the command above. This CLI correction did not retry a failed audit: no audit
ran in the rejected invocation, and only one additional light visit executed.

### Important runtime-load limitation

All three test invocations had **quiet starts, not low-load executions**.
Within two minutes of M7 launch, one-minute load reached 202.83. At 15:15 UTC
the process snapshot showed only this task's xcodebuild, no waiting `lockf`, and
CPU dominated by `launchd_sim`
and iOS 27 simulator wallpaper/poster extensions (several near 100% CPU).
No other lane's processes were stopped or changed. M7 load declined later, but
its last one-minute sample was still 39.83. These observations cannot establish that
host contention caused the historical timeout, nor guarantee that quiet-start
runs can never time out. The runner exposes post-launch load rather than hiding
it or retrying failed audits. The gate is not an in-run load cap or an atomic
reservation of the build lock: other projects can bypass the shared wrapper or
start later. AGENTS.md now calls out this limitation and the max-load report.

## Non-Apple checks

- `bash -n scripts/run-figure-plan-quiet.sh`: passed.
- `shellcheck scripts/run-figure-plan-quiet.sh`: passed.
- `node scripts/test-run-figure-plan-quiet.mjs`: all six scenarios passed.
- `pnpm test`: passed, including the runner scenarios, reference/permission gates,
  content-tools and Morse/calculator/web tests (web: 283 tests in 18 files).
  Existing jsdom canvas warnings did not fail the suite.
- Apple text-source check and self-test: passed (Node printed its existing
  module-type warning).
- Test-guard self-test and branch diff against `origin/main`: passed, no guarded
  changes. No app, UI-test, test-plan, shared audit/positioning-helper or shared
  `~/.local/bin/xbuild` edits.
