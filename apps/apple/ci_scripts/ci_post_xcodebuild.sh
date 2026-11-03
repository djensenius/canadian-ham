#!/bin/bash
# Xcode Cloud post-xcodebuild script: runs after every xcodebuild command.
# After a successful archive, checks that no app in the archive (including the
# embedded watch app) is signed with iCloud, CloudKit or push entitlements or
# bundles the internal-only official reference sheet. See
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
if [[ "${CI_XCODEBUILD_EXIT_CODE:-}" != "0" ]]; then
  ch_log "archive failed (exit ${CI_XCODEBUILD_EXIT_CODE:-unset}); nothing to check"
  exit 0
fi
[[ -n "${CI_ARCHIVE_PATH:-}" ]] || ch_fail "CI_ARCHIVE_PATH is not set after a successful archive"
ch_check_archive_contents "$CI_ARCHIVE_PATH"
