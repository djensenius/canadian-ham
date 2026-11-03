# shellcheck shell=bash
# Shared helpers for the Xcode Cloud custom build scripts in this directory.
# ci_post_clone.sh, ci_pre_xcodebuild.sh and ci_post_xcodebuild.sh source this
# file; it is not a build script itself (Apple asks helpers not to use ci_).
#
# Apple references:
#   https://developer.apple.com/documentation/xcode/writing-custom-build-scripts
#   https://developer.apple.com/documentation/xcode/environment-variable-reference
#   https://developer.apple.com/documentation/xcode/making-dependencies-available-to-xcode-cloud
#
# Runbook: docs/release/distribution.md. Keep this compatible with macOS
# /bin/bash 3.2: no associative arrays, no ${var,,}, no empty "${array[@]}".

# Node major used by the GitHub CI workflow (.github/workflows/ci.yml,
# node-version: 26). The guards use only Node built-ins, so no `pnpm install` is
# needed: `node --run <name>` runs the same package.json script as `pnpm <name>`.
CH_REQUIRED_NODE_MAJOR=26
CH_NODE_FORMULA="node@${CH_REQUIRED_NODE_MAJOR}"

# package.json guard scripts run before every action that builds from source.
# The test:* self-tests prove each guard still rejects its leak fixtures.
CH_GUARD_SCRIPTS="check:apple-network test:apple-network check:apple-icloud-gate test:apple-icloud-gate"

# Shared schemes Xcode Cloud may archive. The watch app ships inside the iOS
# archive of CanadianHam; CanadianHamWatch is never archived on its own.
CH_ARCHIVE_SCHEMES="CanadianHam CanadianHamTV CanadianHamVision"
CH_PROJECT_RELATIVE_PATH="apps/apple/CanadianHam.xcodeproj"

ch_log() {
  printf 'canadian-ham-ci: %s\n' "$*"
}

# Fails the Xcode Cloud action. Never call this inside $(...): it would only
# leave the subshell.
ch_fail() {
  printf 'canadian-ham-ci: error: %s\n' "$*" >&2
  exit 1
}

ch_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# Xcode Cloud clones the repository to CI_PRIMARY_REPOSITORY_PATH; local dry
# runs fall back to the repository that contains this directory.
ch_init() {
  if [[ -n "${CI_PRIMARY_REPOSITORY_PATH:-}" ]]; then
    CH_REPO_ROOT=$CI_PRIMARY_REPOSITORY_PATH
  else
    CH_REPO_ROOT=$(cd "$CH_CI_SCRIPTS_DIR/../../.." && pwd)
  fi
  CH_ACTION=${CI_XCODEBUILD_ACTION:-}
  ch_log "action=${CH_ACTION:-unset} scheme=${CI_XCODE_SCHEME:-unset} platform=${CI_PRODUCT_PLATFORM:-unset} build=${CI_BUILD_NUMBER:-unset} workflow=${CI_WORKFLOW:-unset}"
}

ch_source_available() {
  [[ -f "$CH_REPO_ROOT/package.json" && -d "$CH_REPO_ROOT/apps/apple" ]]
}

# test-without-building runs on a machine without the source code; every
# other action builds from source and must run the guards.
ch_action_builds_source() {
  case "$CH_ACTION" in
    test-without-building) return 1 ;;
    *) return 0 ;;
  esac
}

ch_node_major() {
  local version
  version=$("$1" --version 2>/dev/null) || return 1
  version=${version#v}
  printf '%s\n' "${version%%.*}"
}

ch_find_brew() {
  local candidate
  # Test hook for the local dry run; Xcode Cloud workflows never set it.
  if [[ -n "${CANADIAN_HAM_CI_BREW:-}" ]]; then
    printf '%s\n' "$CANADIAN_HAM_CI_BREW"
    return 0
  fi
  if candidate=$(command -v brew 2>/dev/null); then
    printf '%s\n' "$candidate"
    return 0
  fi
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

ch_use_brew_node() {
  local brew=$1 prefix major
  prefix=$("$brew" --prefix "$CH_NODE_FORMULA" 2>/dev/null) || return 1
  [[ -x "$prefix/bin/node" ]] || return 1
  major=$(ch_node_major "$prefix/bin/node") || return 1
  [[ "$major" == "$CH_REQUIRED_NODE_MAJOR" ]] || return 1
  PATH="$prefix/bin:$PATH"
  export PATH
  ch_log "using Homebrew $CH_NODE_FORMULA: $("$prefix/bin/node" --version)"
}

# Uses Node $CH_REQUIRED_NODE_MAJOR from PATH, else from Homebrew, installing
# the pinned formula if needed. Any other outcome fails the build.
ch_ensure_node() {
  local candidate major brew
  if candidate=$(command -v node 2>/dev/null) && major=$(ch_node_major "$candidate") \
    && [[ "$major" == "$CH_REQUIRED_NODE_MAJOR" ]]; then
    ch_log "using $candidate: $("$candidate" --version)"
    return 0
  fi
  if ! brew=$(ch_find_brew); then
    ch_fail "Node $CH_REQUIRED_NODE_MAJOR is not on PATH and Homebrew is unavailable; cannot run the Apple guards"
  fi
  if ch_use_brew_node "$brew"; then
    return 0
  fi
  ch_log "installing $CH_NODE_FORMULA with $brew"
  if ! HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_NO_INSTALL_CLEANUP=1 \
    "$brew" install "$CH_NODE_FORMULA"; then
    ch_fail "brew install $CH_NODE_FORMULA failed; cannot run the Apple guards"
  fi
  if ! ch_use_brew_node "$brew"; then
    ch_fail "Homebrew $CH_NODE_FORMULA did not provide Node $CH_REQUIRED_NODE_MAJOR; cannot run the Apple guards"
  fi
}

# Runs the Apple network and iCloud guards exactly as package.json defines
# them. A missing script, a failing guard or a failing self-test stops the build.
ch_run_guards() {
  local script
  ch_ensure_node
  cd "$CH_REPO_ROOT" || ch_fail "cannot enter $CH_REPO_ROOT"
  for script in $CH_GUARD_SCRIPTS; do
    ch_log "running package.json script $script"
    if ! node --run "$script"; then
      ch_fail "Apple guard $script failed; refusing to build"
    fi
  done
  ch_log "Apple network and iCloud guards passed"
}

ch_project_path() {
  if [[ -n "${CI_PROJECT_FILE_PATH:-}" ]]; then
    printf '%s\n' "${CI_PROJECT_FILE_PATH%/}"
  else
    printf '%s\n' "$CH_REPO_ROOT/$CH_PROJECT_RELATIVE_PATH"
  fi
}

# Archives may only use an allow-listed shared scheme for its platform whose
# Archive action builds Release, never DebugCloudKit or another configuration.
ch_check_archive_scheme() {
  local scheme=${CI_XCODE_SCHEME:-} platform expected project scheme_file configuration
  [[ -n "$scheme" ]] || ch_fail "CI_XCODE_SCHEME is not set for an archive action"
  case " $CH_ARCHIVE_SCHEMES " in
    *" $scheme "*) ;;
    *) ch_fail "Xcode Cloud may archive only $CH_ARCHIVE_SCHEMES, not '$scheme'" ;;
  esac
  platform=$(ch_lower "${CI_PRODUCT_PLATFORM:-}")
  case "$platform" in
    ios | macos) expected=CanadianHam ;;
    tvos) expected=CanadianHamTV ;;
    visionos | xros) expected=CanadianHamVision ;;
    watchos) ch_fail "archive the watch app through the iOS CanadianHam archive, not a watchOS archive" ;;
    *) ch_fail "unsupported archive platform '${CI_PRODUCT_PLATFORM:-}'" ;;
  esac
  [[ "$scheme" == "$expected" ]] \
    || ch_fail "platform ${CI_PRODUCT_PLATFORM} must archive scheme $expected, not $scheme"

  project=$(ch_project_path)
  case "$project" in
    *"/$CH_PROJECT_RELATIVE_PATH" | "$CH_PROJECT_RELATIVE_PATH") ;;
    *) ch_fail "unexpected project $project; Xcode Cloud must use $CH_PROJECT_RELATIVE_PATH" ;;
  esac
  scheme_file="$CH_REPO_ROOT/$CH_PROJECT_RELATIVE_PATH/xcshareddata/xcschemes/$scheme.xcscheme"
  [[ -f "$scheme_file" ]] || ch_fail "shared scheme not found: $scheme_file"
  if ! configuration=$(xmllint --xpath 'string(/Scheme/ArchiveAction/@buildConfiguration)' "$scheme_file" 2>/dev/null); then
    ch_fail "cannot read the Archive build configuration from $scheme_file"
  fi
  [[ "$configuration" == "Release" ]] \
    || ch_fail "scheme $scheme archives '$configuration'; Xcode Cloud archives must use Release, never DebugCloudKit"
  ch_log "archive scheme $scheme ($platform) uses Release"
}

# xcodebuild can read build settings from the environment, so workflow
# variables must not smuggle in the iCloud gate or the internal-only official
# reference sheet. Only variable names are printed; values may be secrets.
ch_check_archive_environment() {
  local name value names=""
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    value=$(printenv "$name" || true)
    case "$name=$value" in
      *ICLOUD_SYNC* | *DebugCloudKit* | *CloudKit.entitlements* | *CloudKit.Info.plist* | *OFFICIAL_REFERENCE_SHEET*)
        names="$names $name"
        ;;
    esac
  done <<NAMES
$(compgen -e)
NAMES
  [[ -z "$names" ]] || ch_fail "environment variables enable iCloud or the official reference sheet:$names"
  if [[ -n "${CONFIGURATION:-}" && "$CONFIGURATION" != "Release" ]]; then
    ch_fail "CONFIGURATION=$CONFIGURATION; Xcode Cloud archives must use Release"
  fi
}

# Xcode Cloud stamps CI_BUILD_NUMBER into uploaded builds. It must stay above
# every build Fastlane already uploaded (12-digit %Y%m%d%H%M timestamps).
ch_check_build_number() {
  local number=${CI_BUILD_NUMBER:-} floor_file="$CH_CI_SCRIPTS_DIR/build-number-floor" floor
  [[ "$number" =~ ^[1-9][0-9]{0,17}$ ]] \
    || ch_fail "CI_BUILD_NUMBER '$number' is not a positive integer"
  [[ -f "$floor_file" ]] || ch_fail "missing $floor_file"
  floor=$(tr -d '[:space:]' <"$floor_file")
  [[ "$floor" =~ ^[1-9][0-9]{11}$ ]] || ch_fail "$floor_file must hold one 12-digit build number"
  if ((number <= floor)); then
    ch_fail "CI_BUILD_NUMBER $number is not above the last Fastlane build $floor; set App Store Connect > Xcode Cloud > Settings > Build Number > Next Build Number above it (docs/release/distribution.md)"
  fi
  ch_log "build number $number is above the Fastlane floor $floor"
}

# Signed entitlements of every app in an archive must not include iCloud,
# CloudKit or push, and no app may bundle the official sheet.
ch_check_archive_contents() {
  local archive=$1 apps app entitlements count=0
  [[ -d "$archive/Products" ]] || ch_fail "archive has no Products directory: $archive"
  apps=$(find "$archive/Products" -type d -name '*.app' -print | sort)
  [[ -n "$apps" ]] || ch_fail "no .app bundles found in $archive"
  while IFS= read -r app; do
    [[ -n "$app" ]] || continue
    count=$((count + 1))
    if ! entitlements=$(codesign -d --entitlements - --xml "$app" 2>/dev/null); then
      ch_fail "cannot read signed entitlements of $app"
    fi
    if grep -E -q 'com\.apple\.developer\.(icloud|ubiquity)|aps-environment|CloudKit' <<<"$entitlements"; then
      ch_fail "$app is signed with iCloud, CloudKit or push entitlements"
    fi
    if [[ -n "$(find "$app" -path '*official-basic-exam*' -print -quit)" ]]; then
      ch_fail "$app bundles the internal-only official reference sheet"
    fi
  done <<APPS
$apps
APPS
  ch_log "checked $count app bundle(s): no iCloud, CloudKit, push or official-sheet content"
}
