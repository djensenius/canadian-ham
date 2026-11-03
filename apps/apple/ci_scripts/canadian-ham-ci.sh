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
# Marketing versions must be exactly x.y.z (three numbers, no leading zeros
# except a lone 0) in both the project and build-number-floors, so a floors
# entry can never silently miss the version it means (1.0 vs 1.0.0).
CH_VERSION_PATTERN='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
CH_VERSION_FORMAT="x.y.z (three numbers without leading zeros, such as 1.0.0)"

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
  # HOMEBREW_NO_AUTO_UPDATE is deliberately not set: on an image whose cached
  # formula data predates node@26, skipping the update would make the install
  # (and so the build) fail. The update only refreshes formula metadata; the
  # result is still checked to be Node $CH_REQUIRED_NODE_MAJOR below.
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

# Sets CH_PLATFORM_KEY (ios, macos, tvos or visionos) from Xcode Cloud's
# CI_PRODUCT_PLATFORM. iOS covers iPadOS and the embedded watch app. Apple
# documents iOS, macOS, tvOS and watchOS values; visionOS is accepted as
# visionOS or xrOS. Anything else, or no value, fails the archive.
ch_platform_key() {
  local platform
  platform=$(ch_lower "${CI_PRODUCT_PLATFORM:-}")
  case "$platform" in
    ios | macos | tvos | visionos) CH_PLATFORM_KEY=$platform ;;
    xros) CH_PLATFORM_KEY=visionos ;;
    watchos) ch_fail "archive the watch app through the iOS CanadianHam archive, not a watchOS archive" ;;
    *) ch_fail "unsupported archive platform '${CI_PRODUCT_PLATFORM:-}'" ;;
  esac
}

# Archives may only use an allow-listed shared scheme for its platform whose
# Archive action builds Release, never DebugCloudKit or another configuration.
ch_check_archive_scheme() {
  local scheme=${CI_XCODE_SCHEME:-} expected project scheme_file configuration
  [[ -n "$scheme" ]] || ch_fail "CI_XCODE_SCHEME is not set for an archive action"
  case " $CH_ARCHIVE_SCHEMES " in
    *" $scheme "*) ;;
    *) ch_fail "Xcode Cloud may archive only $CH_ARCHIVE_SCHEMES, not '$scheme'" ;;
  esac
  ch_platform_key
  case "$CH_PLATFORM_KEY" in
    ios | macos) expected=CanadianHam ;;
    tvos) expected=CanadianHamTV ;;
    visionos) expected=CanadianHamVision ;;
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
  ch_log "archive scheme $scheme ($CH_PLATFORM_KEY) uses Release"
}

# xcodebuild can read build settings from the environment, so workflow
# variables must not smuggle in the iCloud gate or the internal-only official
# reference sheet. Xcode Cloud also exports branch, tag, pull request and
# workflow names (CI_BRANCH, CI_TAG, CI_PULL_REQUEST_*, CI_WORKFLOW), so a
# branch named after DebugCloudKit stops the archive too. The error names each
# variable and the marker it contains, never the value (values may be secrets).
ch_check_archive_environment() {
  local name value marker found=""
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    value=$(printenv "$name" || true)
    marker=""
    case "$name=$value" in
      *ICLOUD_SYNC*) marker=ICLOUD_SYNC ;;
      *DebugCloudKit*) marker=DebugCloudKit ;;
      *CloudKit.entitlements*) marker=CloudKit.entitlements ;;
      *CloudKit.Info.plist*) marker=CloudKit.Info.plist ;;
      *OFFICIAL_REFERENCE_SHEET*) marker=OFFICIAL_REFERENCE_SHEET ;;
    esac
    [[ -z "$marker" ]] || found="$found $name ($marker)"
  done <<NAMES
$(compgen -e)
NAMES
  if [[ -n "$found" ]]; then
    ch_fail "environment variables mention iCloud or the official reference sheet in their name or value (values not printed):$found. Remove the workflow variable, or rename the branch, tag or pull request that contains the marker."
  fi
  if [[ -n "${CONFIGURATION:-}" && "$CONFIGURATION" != "Release" ]]; then
    ch_fail "CONFIGURATION=$CONFIGURATION; Xcode Cloud archives must use Release"
  fi
}

# Sets CH_MARKETING_VERSION from the checked-in Xcode project, which is what
# Xcode Cloud builds: every MARKETING_VERSION assignment must be a plain
# `MARKETING_VERSION = x.y.z;` line and all must agree. Conditional
# (`MARKETING_VERSION[sdk=...]`), missing, conflicting or non-x.y.z values fail.
ch_read_marketing_version() {
  local pbxproj="$CH_REPO_ROOT/$CH_PROJECT_RELATIVE_PATH/project.pbxproj" line value version=""
  local assignment='^[[:space:]]*MARKETING_VERSION = "?([^";]*)"?;[[:space:]]*$'
  [[ -f "$pbxproj" ]] || ch_fail "cannot read the marketing version: missing $pbxproj"
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    [[ "$line" =~ $assignment ]] \
      || ch_fail "unsupported MARKETING_VERSION setting in $pbxproj: $line"
    value=${BASH_REMATCH[1]}
    [[ -z "$version" || "$version" == "$value" ]] \
      || ch_fail "conflicting MARKETING_VERSION values in $pbxproj: $version and $value"
    version=$value
  done <<LINES
$(grep 'MARKETING_VERSION' "$pbxproj" || true)
LINES
  [[ -n "$version" ]] || ch_fail "no MARKETING_VERSION in $pbxproj"
  [[ "$version" =~ $CH_VERSION_PATTERN ]] \
    || ch_fail "MARKETING_VERSION '$version' is not $CH_VERSION_FORMAT"
  CH_MARKETING_VERSION=$version
}

# Xcode Cloud stamps CI_BUILD_NUMBER into every build it distributes. App
# Store Connect needs it above every build already uploaded for the same
# platform and marketing version; Mac build numbers must also keep increasing
# across versions (https://developer.apple.com/documentation/xcode/setting-the-next-build-number-for-xcode-cloud-builds).
# build-number-floors records the highest Fastlane upload per platform and
# version, so:
#   macos: the number must exceed every macOS floor, whatever the version;
#   ios, tvos, visionos: it must exceed the floor for the version being built,
#     and a version with no Fastlane uploads may start from small numbers.
ch_check_build_number() {
  local number=${CI_BUILD_NUMBER:-} floors_file="$CH_REPO_ROOT/apps/apple/ci_scripts/build-number-floors"
  local entry_platform entry_version entry_build extra seen=" " entries=0 floor="" floor_version=""
  [[ "$number" =~ ^[1-9][0-9]{0,17}$ ]] \
    || ch_fail "CI_BUILD_NUMBER '$number' is not a positive integer"
  ch_platform_key
  ch_read_marketing_version
  [[ -f "$floors_file" ]] || ch_fail "missing $floors_file"
  while read -r entry_platform entry_version entry_build extra || [[ -n "$entry_platform" ]]; do
    [[ -z "$entry_platform" || "$entry_platform" == \#* ]] && continue
    [[ -n "$entry_build" && -z "$extra" ]] \
      || ch_fail "$floors_file: expected '<platform> <version> <build>', got '$entry_platform $entry_version $entry_build $extra'"
    case "$entry_platform" in
      ios | macos | tvos | visionos) ;;
      *) ch_fail "$floors_file: unknown platform '$entry_platform'" ;;
    esac
    [[ "$entry_version" =~ $CH_VERSION_PATTERN ]] \
      || ch_fail "$floors_file: invalid version '$entry_version'; use $CH_VERSION_FORMAT"
    [[ "$entry_build" =~ ^[1-9][0-9]{0,17}$ ]] \
      || ch_fail "$floors_file: invalid build number '$entry_build'"
    case "$seen" in
      *" $entry_platform@$entry_version "*) ch_fail "$floors_file: duplicate entry for $entry_platform $entry_version" ;;
    esac
    seen="$seen$entry_platform@$entry_version "
    entries=$((entries + 1))
    [[ "$entry_platform" == "$CH_PLATFORM_KEY" ]] || continue
    if [[ "$CH_PLATFORM_KEY" == "macos" ]]; then
      if [[ -z "$floor" ]] || ((entry_build > floor)); then
        floor=$entry_build
        floor_version=$entry_version
      fi
    elif [[ "$entry_version" == "$CH_MARKETING_VERSION" ]]; then
      floor=$entry_build
      floor_version=$entry_version
    fi
  done <"$floors_file"
  ((entries > 0)) || ch_fail "$floors_file has no entries"
  if [[ -z "$floor" ]]; then
    ch_log "no Fastlane uploads recorded for $CH_PLATFORM_KEY $CH_MARKETING_VERSION; build number $number may start a new sequence"
    return 0
  fi
  if ((number <= floor)); then
    if [[ "$CH_PLATFORM_KEY" == "macos" ]]; then
      ch_fail "CI_BUILD_NUMBER $number is not above the last macOS upload $floor (version $floor_version); Mac build numbers must keep increasing across versions. See docs/release/distribution.md#build-numbers"
    fi
    ch_fail "CI_BUILD_NUMBER $number is not above the last $CH_PLATFORM_KEY $CH_MARKETING_VERSION upload $floor; raise App Store Connect > Xcode Cloud > Settings > Build Number > Next Build Number, or build a new marketing version. See docs/release/distribution.md#build-numbers"
  fi
  ch_log "build number $number is above the $CH_PLATFORM_KEY floor $floor (version $floor_version); building version $CH_MARKETING_VERSION"
}

# Signed entitlements of every app and app extension in an archive (including
# the embedded watch app and anything in PlugIns or Extensions) must not
# include iCloud, CloudKit or push, and no bundle may contain the official sheet.
ch_check_archive_contents() {
  local archive=$1 bundles bundle entitlements count=0
  [[ -d "$archive/Products" ]] || ch_fail "archive has no Products directory: $archive"
  bundles=$(find "$archive/Products" -type d \( -name '*.app' -o -name '*.appex' \) -print | sort)
  [[ -n "$bundles" ]] || ch_fail "no .app bundles found in $archive"
  while IFS= read -r bundle; do
    [[ -n "$bundle" ]] || continue
    count=$((count + 1))
    if ! entitlements=$(codesign -d --entitlements - --xml "$bundle" 2>/dev/null); then
      ch_fail "cannot read signed entitlements of $bundle"
    fi
    if grep -E -q 'com\.apple\.developer\.(icloud|ubiquity)|aps-environment|CloudKit' <<<"$entitlements"; then
      ch_fail "$bundle is signed with iCloud, CloudKit or push entitlements"
    fi
    if [[ -n "$(find "$bundle" -path '*official-basic-exam*' -print -quit)" ]]; then
      ch_fail "$bundle bundles the internal-only official reference sheet"
    fi
  done <<BUNDLES
$bundles
BUNDLES
  ch_log "checked $count app and extension bundle(s): no iCloud, CloudKit, push or official-sheet content"
}
