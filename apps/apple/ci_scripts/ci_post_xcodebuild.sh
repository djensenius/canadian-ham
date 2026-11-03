#!/bin/bash
# Xcode Cloud post-xcodebuild script: runs after every xcodebuild command.
# After an archive that did not fail, checks that no app or app extension in the
# archive (including the embedded watch app) is signed with iCloud, CloudKit or
# push entitlements or bundles the internal-only official reference sheet. See
# docs/release/distribution.md and
# https://developer.apple.com/documentation/xcode/writing-custom-build-scripts
set -euo pipefail

CH_CI_SCRIPTS_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR
source "$CH_CI_SCRIPTS_DIR/canadian-ham-ci.sh"

ch_init
if [[ "$CH_ACTION" != "archive" ]]; then
  ch_log "no archive checks for ${CH_ACTION:-unset}"
  exit 0
fi
# Skip only a failed archive (Xcode Cloud reports a non-zero exit code). An
# unset or empty exit code still scans the archive; anything else fails.
exit_code=${CI_XCODEBUILD_EXIT_CODE:-}
if [[ -n "$exit_code" && "$exit_code" != "0" ]]; then
  [[ "$exit_code" =~ ^[0-9]+$ ]] || ch_fail "CI_XCODEBUILD_EXIT_CODE '$exit_code' is not an exit code"
  ch_log "archive failed (exit $exit_code); nothing to check"
  exit 0
fi
[[ -n "$exit_code" ]] || ch_log "CI_XCODEBUILD_EXIT_CODE is not set; checking the archive anyway"
[[ -n "${CI_ARCHIVE_PATH:-}" ]] || ch_fail "CI_ARCHIVE_PATH is not set after an archive action"
ch_check_archive_contents "$CI_ARCHIVE_PATH"
