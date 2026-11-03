#!/usr/bin/env node
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

// No Xcode/macOS dependency: all host commands and xbuild are fake executables.
const runner = fileURLToPath(new URL("./run-figure-plan-quiet.sh", import.meta.url));
const root = mkdtempSync(path.join(tmpdir(), "figure-quiet-test-"));
const executable = (file, text) => writeFileSync(file, `#!/usr/bin/env bash\nset -euo pipefail\n${text}\n`, { mode: 0o755 });
let count = 0;
try {
  function run({ loads = ["1 2 3"], args = [], code = 0 } = {}) {
    const dir = path.join(root, String(++count));
    const bin = path.join(dir, "bin");
    mkdirSync(bin, { recursive: true });
    writeFileSync(path.join(dir, "loads"), `${loads.join("\n")}\n`);
    executable(path.join(bin, "sysctl"), '[[ $* == "-n hw.ncpu" ]]\nprintf "4\\n"');
    executable(path.join(bin, "load"), `
state="$FAKE_DIR/state"
n=0
[[ ! -e $state ]] || n=$(cat "$state")
n=$((n + 1))
printf '%s' "$n" > "$state"
line=$(sed -n "\${n}p" "$FAKE_DIR/loads")
[[ -n $line ]] || line=$(tail -n 1 "$FAKE_DIR/loads")
printf '%s\\n' "$line"`);
    executable(path.join(bin, "sleep"), 'printf "%s\\n" "$*" >> "$FAKE_DIR/sleeps"\n/bin/sleep 0.02');
    executable(path.join(bin, "xbuild"), `
printf '%s\\n' "$@" > "$FAKE_DIR/args"
printf '%s\\n' "$DEVELOPER_DIR" > "$FAKE_DIR/developer-dir"
# Finish only after the runner's background sampler has written a periodic sample
# (header + launch sample + at least one periodic sample), so the test doesn't depend
# on relative sleep timings on a slow host. Give up after about 20 s.
for _ in $(seq 1 2000); do
  [[ -f "$FAKE_OUT/load.log" && $(wc -l < "$FAKE_OUT/load.log") -ge 3 ]] && break
  /bin/sleep 0.01
done
printf "Test Case '-[CanadianHamUITests Example]' passed (0.123 seconds).\\n"
printf "Test case 'Example.other()' failed on 'iPhone 17 Pro' (0.456 seconds).\\n"
exit "$FAKE_EXIT"`);
    const out = path.join(dir, "artifacts with spaces");
    const result = spawnSync("/bin/bash", [runner, "--out", out, ...args], {
      env: { ...process.env, PATH: `${bin}:${process.env.PATH}`, FAKE_DIR: dir, FAKE_OUT: out,
        FAKE_EXIT: String(code), FIGURE_QUIET_LOAD_SOURCE: path.join(bin, "load") },
      encoding: "utf8", timeout: 60000,
    });
    if (result.error) {
      assert.fail(`runner did not finish (${result.error.message}); output so far:\n${result.stdout ?? ""}${result.stderr ?? ""}`);
    }
    return { ...result, dir, out, output: result.stdout + result.stderr };
  }

  const passed = run({ loads: ["1 7 3", "50 6 3", "2 2 3", "99 4 5"],
    args: ["-only-testing:Some/Test", "-test-iterations", "5", "--", "VALUE=a b"] });
  assert.equal(passed.status, 0, passed.output);
  assert.match(passed.output, /load\(1\/5\/15m\)=1\/7\/3/);
  assert.match(passed.output, /xcodebuild exit code: 0/);
  assert.match(passed.output, /max 99\.00/);
  assert.match(passed.output, /Max load seen \(1\/5\/15m\): 99\.00 \/ 4\.00 \/ 5\.00/);
  assert.match(passed.output, /Example.*passed/);
  assert.match(passed.output, /Example.other.*failed/);
  assert.match(readFileSync(path.join(passed.dir, "sleeps"), "utf8"), /^60\n/);
  assert.equal(readFileSync(path.join(passed.dir, "developer-dir"), "utf8").trim(), "/Applications/Xcode.app/Contents/Developer");
  assert.deepEqual(readFileSync(path.join(passed.dir, "args"), "utf8").trimEnd().split("\n"), [
    "-project", "apps/apple/CanadianHam.xcodeproj", "-scheme", "CanadianHam",
    "-testPlan", "CanadianHamLessonFigures", "-destination", "platform=iOS Simulator,name=iPhone 17 Pro",
    "-parallel-testing-enabled", "NO", "-resultBundlePath", `${passed.out}/figures.xcresult`,
    "-only-testing:Some/Test", "-test-iterations", "5", "VALUE=a b", "test", "CODE_SIGNING_ALLOWED=NO",
  ]);
  const samples = readFileSync(path.join(passed.out, "load.log"), "utf8").trim().split("\n").slice(1)
    .map(line => Number(line.split("\t")[1])).sort((a, b) => a - b);
  assert.ok(samples.length >= 3, "periodic and final load samples must be collected");
  const middle = Math.floor(samples.length / 2);
  const median = samples.length % 2 ? samples[middle] : (samples[middle - 1] + samples[middle]) / 2;
  assert.ok(passed.output.includes(`median ${median.toFixed(2)}`), passed.output);

  const failed = run({ code: 65 });
  assert.equal(failed.status, 65, failed.output);
  assert.match(failed.output, /xcodebuild exit code: 65/);
  assert.equal(readFileSync(path.join(failed.out, "xbuild.exit"), "utf8"), "65\n");

  const timeout = run({ loads: ["1 7 3"], args: ["--wait-timeout", "0"] });
  assert.equal(timeout.status, 1, timeout.output);
  assert.match(timeout.output, /timed out.*xbuild was NOT run/);
  assert.throws(() => readFileSync(path.join(timeout.dir, "args")), { code: "ENOENT" });

  const configured = run({ loads: ["9 8 7"], args: ["--max-load-factor", "2", "--wait-timeout", "08"] });
  assert.equal(configured.status, 0, configured.output);
  assert.match(configured.output, /threshold\(5m\)=8/);

  const invalid = run({ args: ["--max-load-factor", "bad"] });
  assert.equal(invalid.status, 1, invalid.output);
  assert.match(invalid.output, /load factor must be a positive number/);

  const malformed = run({ loads: ["not a load"] });
  assert.equal(malformed.status, 1, malformed.output);
  assert.match(malformed.output, /cannot read valid load averages; refusing to run/);
  assert.throws(() => readFileSync(path.join(malformed.dir, "args")), { code: "ENOENT" });
  console.log("Quiet figure runner: 6 integration scenarios passed (no Xcode dependency).");
} finally {
  rmSync(root, { recursive: true, force: true });
}
