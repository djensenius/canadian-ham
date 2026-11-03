#!/bin/bash
# Xcode Cloud pre-xcodebuild script: runs before every xcodebuild command.
# Archives must use an allow-listed shared scheme whose Archive action builds
# Release (never DebugCloudKit), with no iCloud or official-sheet overrides and
# a build number above the Fastlane uploads in build-number-floors for its
# platform and marketing version. Every action that builds from source reruns
# the Apple network and iCloud guards. See
# docs/release/distribution.md and
# https://developer.apple.com/documentation/xcode/environment-variable-reference
set -euo pipefail

CH_CI_SCRIPTS_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR
source "$CH_CI_SCRIPTS_DIR/canadian-ham-ci.sh"

ch_init
[[ -n "$CH_ACTION" ]] || ch_fail "CI_XCODEBUILD_ACTION is not set"
if ! ch_action_builds_source; then
  ch_log "$CH_ACTION has no source; guards ran on the build runner"
  exit 0
fi
ch_source_available || ch_fail "repository source not found at $CH_REPO_ROOT"

if [[ "$CH_ACTION" == "archive" ]]; then
  ch_check_archive_scheme
  ch_check_archive_environment
  ch_check_build_number
fi
ch_run_guards
