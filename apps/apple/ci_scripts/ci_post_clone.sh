#!/bin/bash
# Xcode Cloud post-clone script: runs right after Xcode Cloud clones the repo.
# Installs or locates Node and runs the Apple network and iCloud guards so a
# workflow fails before it resolves packages or builds. See
# docs/release/distribution.md and
# https://developer.apple.com/documentation/xcode/writing-custom-build-scripts
set -euo pipefail

CH_CI_SCRIPTS_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR
source "$CH_CI_SCRIPTS_DIR/canadian-ham-ci.sh"

ch_init
if ! ch_source_available; then
  if ! ch_action_builds_source; then
    ch_log "no source on this test-without-building runner; guards ran on the build runner"
    exit 0
  fi
  ch_fail "repository source not found at $CH_REPO_ROOT"
fi
ch_run_guards
