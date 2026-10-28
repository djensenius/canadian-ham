#!/usr/bin/env bash
# Run the unchanged figure audits only after the host's five-minute load settles.
set -euo pipefail

usage() {
  cat <<'HELP'
Usage: scripts/run-figure-plan-quiet.sh [options] [xbuild arguments...]
  --max-load-factor N  Maximum five-minute load / logical CPUs (default: 1.5)
  --wait-timeout N     Maximum quiet-host wait in seconds (default: 7200)
  --out DIR           Artifact directory (default: $TMPDIR/canadian-ham-figures-<timestamp>)
  --help              Show this help
Other arguments are passed unchanged to xbuild (use -- to end runner options).
No other Apple lanes may be launched while this runner is active.
For tests only, FIGURE_QUIET_LOAD_SOURCE may name an executable that prints
three numeric load averages (1, 5 and 15 minutes), instead of sysctl vm.loadavg.
HELP
}

fail() { printf 'figure-plan-quiet: %s\n' "$*" >&2; exit 1; }

factor=1.5
wait_timeout=7200
out="${TMPDIR:-/tmp}/canadian-ham-figures-$(date -u +%Y%m%dT%H%M%SZ)"
pass=()
while (($#)); do
  case "$1" in
    --max-load-factor|--wait-timeout|--out)
      (($# >= 2)) || fail "$1 requires a value"
      case "$1" in
        --max-load-factor) factor=$2 ;;
        --wait-timeout) wait_timeout=$2 ;;
        --out) out=$2 ;;
      esac
      shift 2 ;;
    --help|-h) usage; exit 0 ;;
    --) shift; pass+=("$@"); break ;;
    *) pass+=("$1"); shift ;;
  esac
done
if [[ ! $factor =~ ^[0-9]+([.][0-9]+)?$ ]] ||
  ! awk -v n="$factor" 'BEGIN { exit !(n > 0) }'; then
  fail 'load factor must be a positive number'
fi
[[ $wait_timeout =~ ^[0-9]+$ ]] || fail 'wait timeout must be a non-negative integer (seconds)'
# Force base 10, including values such as 08.
wait_timeout=$((10#$wait_timeout))
[[ -n $out ]] || fail 'output directory must not be empty'
mkdir -p "$out"
out=$(cd "$out" && pwd)
for artifact in figures.xcresult xbuild.log load.log summary.txt xbuild.exit load-error.txt command.txt; do
  [[ ! -e $out/$artifact ]] || fail "artifact already exists: $out/$artifact (choose a new --out)"
done
cd "$(dirname "${BASH_SOURCE[0]}")/.."
command -v xbuild >/dev/null || fail 'xbuild is required on PATH'
cores=$(sysctl -n hw.ncpu)
[[ $cores =~ ^[1-9][0-9]*$ ]] || fail "invalid logical CPU count: $cores"
threshold=$(awk -v factor="$factor" -v cores="$cores" 'BEGIN { printf "%.12g", factor * cores }')

read_load() {
  local raw extra
  if [[ -n ${FIGURE_QUIET_LOAD_SOURCE:-} ]]; then
    raw=$("$FIGURE_QUIET_LOAD_SOURCE") || return 1
  else
    raw=$(sysctl -n vm.loadavg) || return 1
  fi
  raw=${raw//\{/}
  raw=${raw//\}/}
  read -r load1 load5 load15 extra <<< "$raw"
  [[ -z $extra && $load1 =~ ^[0-9]+([.][0-9]+)?$ &&
    $load5 =~ ^[0-9]+([.][0-9]+)?$ && $load15 =~ ^[0-9]+([.][0-9]+)?$ ]]
}

printf 'Artifacts: %s\nWaiting for five-minute load <= %s (%s x %s CPUs); timeout %ss.\n' \
  "$out" "$threshold" "$factor" "$cores" "$wait_timeout"
wait_started=$SECONDS
while :; do
  read_load || fail 'cannot read valid load averages; refusing to run'
  elapsed=$((SECONDS - wait_started))
  printf '%s wait=%ss load(1/5/15m)=%s/%s/%s threshold(5m)=%s\n' \
    "$(date -u +%FT%TZ)" "$elapsed" "$load1" "$load5" "$load15" "$threshold"
  if awk -v current="$load5" -v threshold="$threshold" 'BEGIN { exit !(current <= threshold) }'; then
    break
  fi
  ((elapsed < wait_timeout)) || fail "timed out after ${elapsed}s waiting for a quiet host; xbuild was NOT run"
  remaining=$((wait_timeout - elapsed))
  delay=60
  ((remaining >= delay)) || delay=$remaining
  sleep "$delay"
done

printf 'utc\tload1\tload5\tload15\n' > "$out/load.log"
sample() {
  read_load || return 1
  printf '%s\t%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "$load1" "$load5" "$load15" >> "$out/load.log"
}
# Fail closed if load collection breaks before launch.
sample || fail 'cannot sample load; xbuild was NOT run'
args=(-project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam
  -testPlan CanadianHamLessonFigures
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
  -parallel-testing-enabled NO -resultBundlePath "$out/figures.xcresult"
  ${pass[@]+"${pass[@]}"} test CODE_SIGNING_ALLOWED=NO)
printf 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild ' > "$out/command.txt"
printf '%q ' "${args[@]}" >> "$out/command.txt"
printf '\n' >> "$out/command.txt"

sampler_pid=
build_pid=
cleanup() {
  if [[ -n $sampler_pid ]]; then
    kill "$sampler_pid" 2>/dev/null || true
    wait "$sampler_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
started=$(date +%s)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild "${args[@]}" > "$out/xbuild.log" 2>&1 &
build_pid=$!
(
  sleep_pid=
  trap '[[ -z $sleep_pid ]] || kill "$sleep_pid" 2>/dev/null || true' EXIT
  trap 'exit 0' TERM INT
  while :; do
    sleep 60 &
    sleep_pid=$!
    wait "$sleep_pid"
    sleep_pid=
    sample || { printf 'Load sampling failed\n' > "$out/load-error.txt"; exit 1; }
  done
) &
sampler_pid=$!
printf 'xbuild PID %s; output: %s/xbuild.log\n' "$build_pid" "$out"
rc=0
wait "$build_pid" || rc=$?
finished=$(date +%s)
cleanup
sampler_pid=
sample || printf 'Final load sample failed\n' > "$out/load-error.txt"
printf '%s\n' "$rc" > "$out/xbuild.exit"
{
  printf 'xcodebuild exit code: %s\nElapsed xbuild wall time (including lock/build/cleanup): %ss\n' "$rc" "$((finished - started))"
  awk 'NR > 1 { print $2 }' "$out/load.log" | LC_ALL=C sort -n | awk '
    { values[NR] = $1 }
    END {
      if (!NR) { print "No load samples"; exit 1 }
      median = NR % 2 ? values[(NR + 1) / 2] : (values[NR / 2] + values[NR / 2 + 1]) / 2
      printf "Run load (1m): max %.2f, median %.2f (%d samples)\n", values[NR], median, NR
    }'
  awk 'NR > 1 {
    if ($2 > max1) max1 = $2; if ($3 > max5) max5 = $3; if ($4 > max15) max15 = $4
  } END { printf "Max load seen (1/5/15m): %.2f / %.2f / %.2f\n", max1, max5, max15 }' "$out/load.log"
  printf 'Test case pass/fail lines:\n'
  grep -E "Test [Cc]ase .* (passed|failed)|Test case .* (passed|failed)" "$out/xbuild.log" || true
  if [[ -e $out/load-error.txt ]]; then
    cat "$out/load-error.txt"
  fi
  printf 'Artifacts: %s\n' "$out"
} | tee "$out/summary.txt"
[[ ! -e $out/load-error.txt || $rc != 0 ]] || rc=1
exit "$rc"
