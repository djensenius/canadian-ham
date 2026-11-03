#!/usr/bin/env bash
# Dry run of the Xcode Cloud custom build scripts in apps/apple/ci_scripts.
# Simulates Xcode Cloud CI_* environments locally without building, archiving,
# signing with real identities, or installing anything: Homebrew is a stub or
# hidden by a sandbox. Needs macOS (codesign, xmllint, sandbox-exec) and Node 26.
# Run with: node --run test:xcode-cloud-scripts (or pnpm test:xcode-cloud-scripts)
set -u

script_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(CDPATH='' cd -- "$script_dir/.." && pwd)
ci_dir="$repo_root/apps/apple/ci_scripts"
schemes_dir="$repo_root/apps/apple/CanadianHam.xcodeproj/xcshareddata/xcschemes"
guard_scripts="check:apple-network test:apple-network check:apple-icloud-gate test:apple-icloud-gate"
tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/xcode-cloud-ci-scripts-test.XXXXXX") || exit 2
tmp_root=$(CDPATH='' cd -- "$tmp_root" && pwd -P)
failures=0
passes=0

cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

die() {
  printf 'xcode-cloud-ci-scripts-test: %s\n' "$1" >&2
  exit 2
}

[[ "$(uname -s)" == "Darwin" ]] || die "needs macOS (codesign, xmllint)"
real_node=$(node -p process.execPath 2>/dev/null) || die "needs node on PATH"
[[ "$("$real_node" -p 'process.versions.node.split(".")[0]')" == "26" ]] \
  || die "needs Node 26 on PATH (the version the ci_scripts and GitHub CI pin)"
floors_file="$ci_dir/build-number-floors"
pbxproj_file="$repo_root/apps/apple/CanadianHam.xcodeproj/project.pbxproj"
# Highest entry in the real floors file: above every platform and version.
real_max_floor=$(awk '$1 !~ /^#/ && NF == 3 { print $3 }' "$floors_file" | sort -n | tail -n 1)
[[ "$real_max_floor" =~ ^[0-9]+$ ]] || die "cannot read a floor from $floors_file"
above_real_floors=$((real_max_floor + 1))
# Fixtures pin MARKETING_VERSION and the floors (the Fastlane 1.0.0 uploads) so
# the cases do not change when the real project or floors file does.
ios_floor=202610271751
mac_floor=202610271753
tv_floor=202610271756
vision_floor=202610271757
above_floor=$((vision_floor + 1))

# PATH with Node 26 and system tools only, so no real Homebrew is reachable
# through PATH. CANADIAN_HAM_CI_BREW always points at a stub as well.
node_bin="$tmp_root/node-bin"
mkdir -p "$node_bin"
ln -s "$real_node" "$node_bin/node"
system_path="/usr/bin:/bin:/usr/sbin:/sbin"
base_path="$node_bin:$system_path"

# Stub Homebrew. CH_TEST_BREW_MODE: fail (prefix and install fail), install
# (install links Node 26 into the fake prefix) or wrong (installs a Node 20).
stub_brew="$tmp_root/stub-brew/brew"
stub_prefix="$tmp_root/stub-brew/node-prefix"
mkdir -p "$(dirname "$stub_brew")"
cat >"$stub_brew" <<SH
#!/bin/bash
printf 'stub-brew %s\n' "\$*" >&2
case "\$1" in
  --prefix)
    [[ -x "$stub_prefix/bin/node" ]] || exit 1
    printf '%s\n' "$stub_prefix"
    ;;
  install)
    case "\${CH_TEST_BREW_MODE:-fail}" in
      install)
        mkdir -p "$stub_prefix/bin"
        ln -sf "$real_node" "$stub_prefix/bin/node"
        ;;
      wrong)
        mkdir -p "$stub_prefix/bin"
        printf '#!/bin/bash\necho v20.0.0\n' >"$stub_prefix/bin/node"
        chmod +x "$stub_prefix/bin/node"
        ;;
      *) exit 1 ;;
    esac
    ;;
  *) exit 1 ;;
esac
SH
chmod +x "$stub_brew"

# Fixture repository: real shared schemes, the real project file with
# MARKETING_VERSION set to VERSION (default 1.0.0), the fixture floors and
# package.json guard stubs.
# make_fixture NAME [failing-guard] [missing-guard] [VERSION]
make_fixture() {
  local name=$1 failing=${2:-} missing=${3:-} version=${4:-1.0.0} root script command comma=""
  root="$tmp_root/$name"
  mkdir -p "$root/apps/apple/CanadianHam.xcodeproj/xcshareddata" "$root/apps/apple/ci_scripts"
  cp -R "$schemes_dir" "$root/apps/apple/CanadianHam.xcodeproj/xcshareddata/"
  sed -E "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = $version;/" "$pbxproj_file" \
    >"$root/apps/apple/CanadianHam.xcodeproj/project.pbxproj"
  grep -q "MARKETING_VERSION = $version;" "$root/apps/apple/CanadianHam.xcodeproj/project.pbxproj" \
    || die "could not set MARKETING_VERSION $version in the $name fixture"
  printf '# fixture floors\nios 1.0.0 %s\nmacos 1.0.0 %s\n\ntvos 1.0.0 %s\nvisionos 1.0.0 %s\n' \
    "$ios_floor" "$mac_floor" "$tv_floor" "$vision_floor" >"$root/apps/apple/ci_scripts/build-number-floors"
  {
    printf '{\n  "private": true,\n  "scripts": {\n'
    for script in $guard_scripts; do
      [[ "$script" == "$missing" ]] && continue
      command="echo fixture-guard $script"
      [[ "$script" == "$failing" ]] && command="$command failing; exit 1"
      printf '%s    "%s": "%s"' "$comma" "$script" "$command"
      comma=$',\n'
    done
    printf '\n  }\n}\n'
  } >"$root/package.json"
  printf '%s\n' "$root"
}

# Fake archive with ad-hoc signed iOS-style app and app extension bundles.
# make_bundle DIR NAME app|appex [ENTITLEMENT_KEY]: signed with the entitlement
# when one is given, otherwise left for sign_app.
make_bundle() {
  local dir=$1 name=$2 extension=$3 key=${4:-} bundle entitlements package_type=APPL
  [[ "$extension" == "appex" ]] && package_type='XPC!'
  bundle="$dir/$name.$extension"
  mkdir -p "$bundle"
  cp /usr/bin/true "$bundle/$name"
  cat >"$bundle/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>CFBundleExecutable</key><string>$name</string><key>CFBundleIdentifier</key><string>test.canadianham.$name</string><key>CFBundlePackageType</key><string>$package_type</string></dict></plist>
PLIST
  if [[ -n "$key" ]]; then
    entitlements="$dir/$name.entitlements"
    cat >"$entitlements" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>$key</key><string>production</string></dict></plist>
PLIST
    codesign -f -s - --entitlements "$entitlements" "$bundle" >/dev/null 2>&1 || die "cannot ad-hoc sign $bundle"
    rm -f "$entitlements"
  fi
}

# make_app DIR NAME [ENTITLEMENT_KEY]
make_app() {
  make_bundle "$1" "$2" app "${3:-}"
}

sign_app() {
  codesign -f -s - "$1" >/dev/null 2>&1 || die "cannot ad-hoc sign $1"
}

# add_extensions ARCHIVE [PLUGIN_ENTITLEMENT_KEY]: adds a PlugIns and an
# Extensions app extension to CanadianHam.app and re-signs the app.
add_extensions() {
  local app="$1/Products/Applications/CanadianHam.app" key=${2:-}
  mkdir -p "$app/PlugIns" "$app/Extensions"
  make_bundle "$app/PlugIns" CanadianHamWidget appex "$key"
  [[ -n "$key" ]] || sign_app "$app/PlugIns/CanadianHamWidget.appex"
  make_bundle "$app/Extensions" CanadianHamIntents appex
  sign_app "$app/Extensions/CanadianHamIntents.appex"
  sign_app "$app"
}

# make_archive NAME WATCH_ENTITLEMENT_KEY [official]
make_archive() {
  local name=$1 watch_key=${2:-} official=${3:-} archive apps
  archive="$tmp_root/$name.xcarchive"
  apps="$archive/Products/Applications"
  mkdir -p "$apps/CanadianHam.app/Watch"
  make_app "$apps/CanadianHam.app/Watch" CanadianHamWatch "$watch_key"
  [[ -n "$watch_key" ]] || sign_app "$apps/CanadianHam.app/Watch/CanadianHamWatch.app"
  make_app "$apps" CanadianHam
  if [[ "$official" == "official" ]]; then
    mkdir -p "$apps/CanadianHam.app/official-basic-exam"
    printf 'fixture\n' >"$apps/CanadianHam.app/official-basic-exam/sheet.txt"
  fi
  sign_app "$apps/CanadianHam.app"
  printf '%s\n' "$archive"
}

# run_case NAME pass|fail PRESENT_REGEX ABSENT_REGEX SCRIPT [VAR=value ...]
# Runs one ci_scripts entry point (or a test wrapper given by absolute path)
# with a clean environment plus the given variables, and checks its exit
# status and output.
run_case() {
  local name=$1 expect=$2 present=$3 absent=$4 script=$5 output flat status ok=1
  shift 5
  [[ "$script" == /* ]] || script="$ci_dir/$script"
  output=$(cd "$ci_dir" && env -i HOME="$HOME" TMPDIR="$tmp_root" PATH="$base_path" \
    CANADIAN_HAM_CI_BREW="$stub_brew" "$@" "$script" 2>&1)
  status=$?
  flat=${output//$'\n'/ | }
  if [[ "$expect" == "pass" && $status -ne 0 ]] || [[ "$expect" == "fail" && $status -eq 0 ]]; then
    ok=0
  fi
  if [[ -n "$present" ]] && ! grep -E -q -- "$present" <<<"$flat"; then
    ok=0
  fi
  if [[ -n "$absent" ]] && grep -E -q -- "$absent" <<<"$flat"; then
    ok=0
  fi
  if ((ok)); then
    passes=$((passes + 1))
    printf 'PASS %s (exit %s)\n' "$name" "$status"
  else
    failures=$((failures + 1))
    printf 'FAIL %s: expected %s, exit %s; wanted /%s/, unwanted /%s/\n%s\n' \
      "$name" "$expect" "$status" "$present" "$absent" "$output" >&2
  fi
}

clean=$(make_fixture clean)
failing=$(make_fixture failing check:apple-icloud-gate)
missing=$(make_fixture missing "" test:apple-network)
cloudkit=$(make_fixture cloudkit)
perl -0pi -e 's/(<ArchiveAction\s+buildConfiguration\s*=\s*")Release"/${1}DebugCloudKit"/' \
  "$cloudkit/apps/apple/CanadianHam.xcodeproj/xcshareddata/xcschemes/CanadianHam.xcscheme"
[[ "$(xmllint --xpath 'string(/Scheme/ArchiveAction/@buildConfiguration)' \
  "$cloudkit/apps/apple/CanadianHam.xcodeproj/xcshareddata/xcschemes/CanadianHam.xcscheme")" == "DebugCloudKit" ]] \
  || die "could not build the DebugCloudKit scheme fixture"
empty="$tmp_root/no-source"
mkdir -p "$empty"
all_guards='fixture-guard check:apple-network.*fixture-guard test:apple-network.*fixture-guard check:apple-icloud-gate.*fixture-guard test:apple-icloud-gate'
ios_archive=(CI_XCODEBUILD_ACTION=archive CI_XCODE_SCHEME=CanadianHam CI_PRODUCT_PLATFORM=iOS CI_BUILD_NUMBER="$above_floor")

# Marketing version and floors file variants.
next_version=$(make_fixture next-version "" "" 1.0.1)
fixture_pbxproj=apps/apple/CanadianHam.xcodeproj/project.pbxproj
fixture_floors=apps/apple/ci_scripts/build-number-floors
no_project=$(make_fixture no-project)
rm -f "$no_project/$fixture_pbxproj"
no_version=$(make_fixture no-version)
sed -i '' '/MARKETING_VERSION/d' "$no_version/$fixture_pbxproj"
conflicting_version=$(make_fixture conflicting-version)
perl -0pi -e 's/MARKETING_VERSION = 1\.0\.0;/MARKETING_VERSION = 1.0.2;/' "$conflicting_version/$fixture_pbxproj"
sdk_version=$(make_fixture sdk-version)
perl -0pi -e 's/\n(\s*)MARKETING_VERSION = 1\.0\.0;/\n$1"MARKETING_VERSION[sdk=macosx*]" = 1.0.0;\n$1MARKETING_VERSION = 1.0.0;/' \
  "$sdk_version/$fixture_pbxproj"
text_version=$(make_fixture text-version "" "" 1.0.0-beta)
two_part_version=$(make_fixture two-part-version "" "" 1.0)
leading_zero_version=$(make_fixture leading-zero-version "" "" 1.01.0)
if ! grep -q 'MARKETING_VERSION = 1.0.2;' "$conflicting_version/$fixture_pbxproj" \
  || ! grep -q 'MARKETING_VERSION = 1.0.0;' "$conflicting_version/$fixture_pbxproj" \
  || ! grep -q 'MARKETING_VERSION\[sdk=macosx\*\]' "$sdk_version/$fixture_pbxproj"; then
  die "could not build the MARKETING_VERSION fixtures"
fi
mac_later=$(make_fixture mac-later)
printf 'macos 1.0.1 202611010000\n' >>"$mac_later/$fixture_floors"
no_floors=$(make_fixture no-floors)
rm -f "$no_floors/$fixture_floors"
empty_floors=$(make_fixture empty-floors)
printf '# no entries\n\n' >"$empty_floors/$fixture_floors"
floors_with() {
  local root
  root=$(make_fixture "$1")
  printf '%s\n' "$2" >>"$root/$fixture_floors"
  printf '%s\n' "$root"
}
watch_floor=$(floors_with watch-floor 'watchos 1.0.0 202610271751')
short_floor=$(floors_with short-floor 'ios 1.0.1')
long_floor=$(floors_with long-floor 'ios 1.0.1 5 extra')
duplicate_floor=$(floors_with duplicate-floor 'ios 1.0.0 1')
zero_floor=$(floors_with zero-floor 'tvos 1.0.1 0123')
version_floor=$(floors_with version-floor 'tvos 1.0.0.0 5')
two_part_floor=$(floors_with two-part-floor 'ios 1.0 202611010000')
leading_zero_floor=$(floors_with leading-zero-floor 'tvos 1.0.00 5')
# floors_without NAME PLATFORM [VERSION]: fixture floors with every PLATFORM
# line removed, at MARKETING_VERSION VERSION (default 1.0.0).
floors_without() {
  local root
  root=$(make_fixture "$1" "" "" "${3:-1.0.0}")
  sed -i '' "/^$2 /d" "$root/$fixture_floors"
  ! grep -q "^$2 " "$root/$fixture_floors" || die "could not remove $2 from the $1 floors fixture"
  grep -q '^[a-z]' "$root/$fixture_floors" || die "the $1 floors fixture has no other entries"
  printf '%s\n' "$root"
}
no_mac_floor=$(floors_without no-mac-floor macos)
no_mac_floor_next=$(floors_without no-mac-floor-next macos 1.0.1)
no_ios_floor_next=$(floors_without no-ios-floor-next ios 1.0.1)
no_tv_floor=$(floors_without no-tv-floor tvos)
no_vision_floor_next=$(floors_without no-vision-floor-next visionos 1.0.1)
# Missing, zero-byte, comment-only and unreadable floors files at a new
# marketing version, where iOS, tvOS and visionOS would otherwise accept 1.
no_floors_next=$(make_fixture no-floors-next "" "" 1.0.1)
rm -f "$no_floors_next/$fixture_floors"
zero_byte_floors=$(make_fixture zero-byte-floors "" "" 1.0.1)
: >"$zero_byte_floors/$fixture_floors"
comment_floors_next=$(make_fixture comment-floors-next "" "" 1.0.1)
printf '# no entries\n\n' >"$comment_floors_next/$fixture_floors"
unreadable_floors=$(make_fixture unreadable-floors "" "" 1.0.1)
chmod 000 "$unreadable_floors/$fixture_floors"

# Calls ch_check_build_number on its own, after only ch_init, to show it fails
# closed even if the scheme check did not run first.
build_number_only="$tmp_root/build-number-only.sh"
cat >"$build_number_only" <<SH
#!/bin/bash
set -euo pipefail
CH_CI_SCRIPTS_DIR="$ci_dir"
source "$ci_dir/canadian-ham-ci.sh"
ch_init
ch_check_build_number
SH
chmod +x "$build_number_only"

printf '== Real repository and real guards\n'
run_case "post-clone runs the real guards" pass "guards passed" "" ci_post_clone.sh \
  CI_XCODEBUILD_ACTION=archive
run_case "pre-xcodebuild iOS archive with real schemes, floors and guards" pass \
  "CanadianHam \(ios\) uses Release.*build number $above_real_floors .*guards passed" "" \
  ci_pre_xcodebuild.sh CI_XCODEBUILD_ACTION=archive CI_XCODE_SCHEME=CanadianHam \
  CI_PRODUCT_PLATFORM=iOS CI_BUILD_NUMBER="$above_real_floors"
run_case "real floors reject macOS build number 1" fail "CI_BUILD_NUMBER 1 is not above the last macOS upload" \
  "guards passed" ci_pre_xcodebuild.sh CI_XCODEBUILD_ACTION=archive CI_XCODE_SCHEME=CanadianHam \
  CI_PRODUCT_PLATFORM=macOS CI_BUILD_NUMBER=1

printf '== Archive scheme, platform and configuration\n'
run_case "macOS archive of CanadianHam" pass "$all_guards" "" ci_pre_xcodebuild.sh \
  CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive CI_XCODE_SCHEME=CanadianHam \
  CI_PRODUCT_PLATFORM=macOS CI_BUILD_NUMBER="$above_floor" \
  CI_PROJECT_FILE_PATH="$clean/apps/apple/CanadianHam.xcodeproj"
run_case "tvOS archive of CanadianHamTV" pass "CanadianHamTV \(tvos\) uses Release" "" ci_pre_xcodebuild.sh \
  CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive CI_XCODE_SCHEME=CanadianHamTV \
  CI_PRODUCT_PLATFORM=tvOS CI_BUILD_NUMBER="$above_floor"
run_case "visionOS archive of CanadianHamVision" pass "CanadianHamVision \(visionos\) uses Release" "" ci_pre_xcodebuild.sh \
  CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive CI_XCODE_SCHEME=CanadianHamVision \
  CI_PRODUCT_PLATFORM=visionOS CI_BUILD_NUMBER="$above_floor"
run_case "xrOS platform name maps to CanadianHamVision" pass "uses Release" "" ci_pre_xcodebuild.sh \
  CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive CI_XCODE_SCHEME=CanadianHamVision \
  CI_PRODUCT_PLATFORM=xrOS CI_BUILD_NUMBER="$above_floor"
run_case "DebugCloudKit archive configuration is rejected" fail "never DebugCloudKit" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$cloudkit" "${ios_archive[@]}"
run_case "non-Release CONFIGURATION is rejected" fail "CONFIGURATION=Debug; Xcode Cloud archives must use Release" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" CONFIGURATION=Debug
run_case "standalone watch scheme archive is rejected" fail "not 'CanadianHamWatch'" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive \
  CI_XCODE_SCHEME=CanadianHamWatch CI_PRODUCT_PLATFORM=watchOS CI_BUILD_NUMBER="$above_floor"
run_case "watchOS platform archive is rejected" fail "through the iOS CanadianHam archive" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive \
  CI_XCODE_SCHEME=CanadianHam CI_PRODUCT_PLATFORM=watchOS CI_BUILD_NUMBER="$above_floor"
run_case "platform and scheme mismatch is rejected" fail "must archive scheme CanadianHamTV" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive \
  CI_XCODE_SCHEME=CanadianHam CI_PRODUCT_PLATFORM=tvOS CI_BUILD_NUMBER="$above_floor"
run_case "missing platform is rejected" fail "unsupported archive platform" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive \
  CI_XCODE_SCHEME=CanadianHam CI_BUILD_NUMBER="$above_floor"
run_case "missing scheme is rejected" fail "CI_XCODE_SCHEME is not set" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive \
  CI_PRODUCT_PLATFORM=iOS CI_BUILD_NUMBER="$above_floor"
run_case "other project file is rejected" fail "unexpected project" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" \
  CI_PROJECT_FILE_PATH="$clean/apps/apple/Other.xcodeproj"
run_case "missing action is rejected" fail "CI_XCODEBUILD_ACTION is not set" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean"

printf '== iCloud and official-sheet overrides in the environment\n'
run_case "ICLOUD_SYNC compiler flag is rejected by name" fail "OTHER_SWIFT_FLAGS \(ICLOUD_SYNC\)" "-DICLOUD_SYNC|-Onone|fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" \
  OTHER_SWIFT_FLAGS='-Onone -DICLOUD_SYNC'
run_case "ICLOUD_SYNC variable name is rejected" fail "values not printed\): ICLOUD_SYNC \(ICLOUD_SYNC\)\." "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" ICLOUD_SYNC=1
run_case "CloudKit entitlements override is rejected" fail "CODE_SIGN_ENTITLEMENTS \(CloudKit.entitlements\)" "Resources/|fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" \
  CODE_SIGN_ENTITLEMENTS=CanadianHam/Resources/CanadianHam.iOS.CloudKit.entitlements
run_case "official reference sheet flag is rejected" fail "SWIFT_ACTIVE_COMPILATION_CONDITIONS \(OFFICIAL_REFERENCE_SHEET\)" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS=OFFICIAL_REFERENCE_SHEET
run_case "CONFIGURATION=DebugCloudKit is rejected" fail "CONFIGURATION \(DebugCloudKit\)" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" CONFIGURATION=DebugCloudKit
run_case "branch name with DebugCloudKit is named, value not printed" fail \
  "CI_BRANCH \(DebugCloudKit\)\. Remove the workflow variable, or rename the branch, tag or pull request" \
  "feature/|fixture-guard" ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" \
  CI_BRANCH=feature/DebugCloudKit-x
run_case "pull request branch with ICLOUD_SYNC is named" fail "CI_PULL_REQUEST_SOURCE_BRANCH \(ICLOUD_SYNC\)" \
  "try-|fixture-guard" ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" \
  CI_PULL_REQUEST_SOURCE_BRANCH=try-ICLOUD_SYNC
run_case "tag with the official sheet flag is named" fail "CI_TAG \(OFFICIAL_REFERENCE_SHEET\)" \
  "v9-|fixture-guard" ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" \
  CI_TAG=v9-OFFICIAL_REFERENCE_SHEET

printf '== Build number continuity (fixture floors at 1.0.0: ios %s, macos %s, tvos %s, visionos %s)\n' \
  "$ios_floor" "$mac_floor" "$tv_floor" "$vision_floor"
at_100=(CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive)
at_101=(CI_PRIMARY_REPOSITORY_PATH="$next_version" CI_XCODEBUILD_ACTION=archive)
ios=(CI_XCODE_SCHEME=CanadianHam CI_PRODUCT_PLATFORM=iOS)
mac=(CI_XCODE_SCHEME=CanadianHam CI_PRODUCT_PLATFORM=macOS)
tv=(CI_XCODE_SCHEME=CanadianHamTV CI_PRODUCT_PLATFORM=tvOS)
vision=(CI_XCODE_SCHEME=CanadianHamVision CI_PRODUCT_PLATFORM=visionOS)
mac_rule="not above the last macOS upload $mac_floor \(version 1\.0\.0\); Mac build numbers must keep increasing across versions"
run_case "macOS build number equal to the macOS floor is rejected" fail "CI_BUILD_NUMBER $mac_floor is $mac_rule" "fixture-guard" \
  ci_pre_xcodebuild.sh "${at_100[@]}" "${mac[@]}" CI_BUILD_NUMBER="$mac_floor"
run_case "macOS below its floor but above the iOS floor is rejected" fail "$mac_rule" "fixture-guard" \
  ci_pre_xcodebuild.sh "${at_100[@]}" "${mac[@]}" CI_BUILD_NUMBER="$((ios_floor + 1))"
run_case "macOS above its floor passes" pass \
  "build number $((mac_floor + 1)) is above the macos floor $mac_floor \(version 1\.0\.0\); building version 1\.0\.0.*$all_guards" "" \
  ci_pre_xcodebuild.sh "${at_100[@]}" "${mac[@]}" CI_BUILD_NUMBER="$((mac_floor + 1))"
run_case "macOS small build number at a new marketing version is rejected" fail "CI_BUILD_NUMBER 1 is $mac_rule" "fixture-guard" \
  ci_pre_xcodebuild.sh "${at_101[@]}" "${mac[@]}" CI_BUILD_NUMBER=1
run_case "macOS above its floor at a new marketing version passes" pass \
  "above the macos floor $mac_floor \(version 1\.0\.0\); building version 1\.0\.1.*$all_guards" "" \
  ci_pre_xcodebuild.sh "${at_101[@]}" "${mac[@]}" CI_BUILD_NUMBER="$((mac_floor + 1))"
run_case "macOS floor is the highest macOS upload of any version" fail \
  "not above the last macOS upload 202611010000 \(version 1\.0\.1\)" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$mac_later" CI_XCODEBUILD_ACTION=archive "${mac[@]}" \
  CI_BUILD_NUMBER="$((mac_floor + 1))"
run_case "iOS small build number at 1.0.0 is rejected" fail \
  "CI_BUILD_NUMBER 1 is not above the last ios 1\.0\.0 upload $ios_floor; raise App Store Connect > Xcode Cloud > Settings > Build Number > Next Build Number, or build a new marketing version" \
  "fixture-guard" ci_pre_xcodebuild.sh "${at_100[@]}" "${ios[@]}" CI_BUILD_NUMBER=1
run_case "iOS build number equal to its floor is rejected" fail "not above the last ios 1\.0\.0 upload $ios_floor" "fixture-guard" \
  ci_pre_xcodebuild.sh "${at_100[@]}" "${ios[@]}" CI_BUILD_NUMBER="$ios_floor"
run_case "iOS above its own floor passes" pass "above the ios floor $ios_floor \(version 1\.0\.0\).*$all_guards" "" \
  ci_pre_xcodebuild.sh "${at_100[@]}" "${ios[@]}" CI_BUILD_NUMBER="$((ios_floor + 1))"
run_case "tvOS build number equal to its floor at 1.0.0 is rejected" fail "not above the last tvos 1\.0\.0 upload $tv_floor" "fixture-guard" \
  ci_pre_xcodebuild.sh "${at_100[@]}" "${tv[@]}" CI_BUILD_NUMBER="$tv_floor"
run_case "tvOS small build number at 1.0.0 is rejected" fail "CI_BUILD_NUMBER 2 is not above the last tvos 1\.0\.0 upload" "fixture-guard" \
  ci_pre_xcodebuild.sh "${at_100[@]}" "${tv[@]}" CI_BUILD_NUMBER=2
run_case "visionOS build number equal to its floor at 1.0.0 is rejected" fail "not above the last visionos 1\.0\.0 upload $vision_floor" \
  "fixture-guard" ci_pre_xcodebuild.sh "${at_100[@]}" "${vision[@]}" CI_BUILD_NUMBER="$vision_floor"
run_case "visionOS small build number at 1.0.0 is rejected" fail "CI_BUILD_NUMBER 3 is not above the last visionos 1\.0\.0 upload" \
  "fixture-guard" ci_pre_xcodebuild.sh "${at_100[@]}" CI_XCODE_SCHEME=CanadianHamVision CI_PRODUCT_PLATFORM=xrOS CI_BUILD_NUMBER=3
run_case "visionOS above its floor passes" pass "above the visionos floor $vision_floor" "" \
  ci_pre_xcodebuild.sh "${at_100[@]}" "${vision[@]}" CI_BUILD_NUMBER="$above_floor"
run_case "iOS small build number at a new marketing version passes" pass \
  "no Fastlane uploads recorded for ios 1\.0\.1; build number 1 may start a new sequence.*$all_guards" "" \
  ci_pre_xcodebuild.sh "${at_101[@]}" "${ios[@]}" CI_BUILD_NUMBER=1
run_case "tvOS small build number at a new marketing version passes" pass \
  "no Fastlane uploads recorded for tvos 1\.0\.1; build number 2 may start.*$all_guards" "" \
  ci_pre_xcodebuild.sh "${at_101[@]}" "${tv[@]}" CI_BUILD_NUMBER=2
run_case "visionOS small build number at a new marketing version passes" pass \
  "no Fastlane uploads recorded for visionos 1\.0\.1; build number 3 may start.*$all_guards" "" \
  ci_pre_xcodebuild.sh "${at_101[@]}" "${vision[@]}" CI_BUILD_NUMBER=3
run_case "xrOS small build number at a new marketing version passes" pass "no Fastlane uploads recorded for visionos 1\.0\.1" "" \
  ci_pre_xcodebuild.sh "${at_101[@]}" CI_XCODE_SCHEME=CanadianHamVision CI_PRODUCT_PLATFORM=xrOS CI_BUILD_NUMBER=4
run_case "non-integer build number is rejected" fail "is not a positive integer" "fixture-guard" \
  ci_pre_xcodebuild.sh "${at_100[@]}" "${ios[@]}" CI_BUILD_NUMBER=1.2
run_case "zero build number is rejected" fail "CI_BUILD_NUMBER '0' is not a positive integer" "fixture-guard" \
  ci_pre_xcodebuild.sh "${at_100[@]}" "${ios[@]}" CI_BUILD_NUMBER=0
run_case "missing build number is rejected" fail "is not a positive integer" "fixture-guard" \
  ci_pre_xcodebuild.sh "${at_100[@]}" "${ios[@]}"
run_case "build-number check alone: missing platform fails closed" fail "unsupported archive platform ''" "" \
  "$build_number_only" CI_PRIMARY_REPOSITORY_PATH="$next_version" CI_BUILD_NUMBER=1
run_case "build-number check alone: unknown platform fails closed" fail "unsupported archive platform 'android'" "" \
  "$build_number_only" CI_PRIMARY_REPOSITORY_PATH="$next_version" CI_PRODUCT_PLATFORM=android CI_BUILD_NUMBER=1
run_case "build-number check alone: watchOS fails closed" fail "through the iOS CanadianHam archive" "" \
  "$build_number_only" CI_PRIMARY_REPOSITORY_PATH="$next_version" CI_PRODUCT_PLATFORM=watchOS CI_BUILD_NUMBER=1
run_case "build-number check alone: new version passes" pass "no Fastlane uploads recorded for tvos 1\.0\.1" "" \
  "$build_number_only" CI_PRIMARY_REPOSITORY_PATH="$next_version" CI_PRODUCT_PLATFORM=tvOS CI_BUILD_NUMBER=1
run_case "missing project file fails closed" fail "cannot read the marketing version: missing .*project\.pbxproj" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$no_project" "${ios_archive[@]}"
run_case "missing MARKETING_VERSION fails closed" fail "no MARKETING_VERSION in" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$no_version" "${ios_archive[@]}"
run_case "conflicting MARKETING_VERSION values fail closed" fail "conflicting MARKETING_VERSION values in .*: 1\.0\.(0 and 1\.0\.2|2 and 1\.0\.0)" \
  "fixture-guard" ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$conflicting_version" "${ios_archive[@]}"
run_case "SDK-conditional MARKETING_VERSION fails closed" fail "unsupported MARKETING_VERSION setting" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$sdk_version" "${ios_archive[@]}"
run_case "non-numeric MARKETING_VERSION fails closed" fail "MARKETING_VERSION '1\.0\.0-beta' is not x\.y\.z" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$text_version" "${ios_archive[@]}"
run_case "two-part MARKETING_VERSION fails closed" fail \
  "MARKETING_VERSION '1\.0' is not x\.y\.z \(three numbers without leading zeros, such as 1\.0\.0\)" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$two_part_version" "${ios_archive[@]}"
run_case "two-part MARKETING_VERSION fails closed even without floors for it" fail "MARKETING_VERSION '1\.0' is not x\.y\.z" \
  "fixture-guard|no Fastlane uploads" ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$two_part_version" \
  CI_XCODEBUILD_ACTION=archive CI_XCODE_SCHEME=CanadianHamTV CI_PRODUCT_PLATFORM=tvOS CI_BUILD_NUMBER=1
run_case "leading-zero MARKETING_VERSION fails closed" fail "MARKETING_VERSION '1\.01\.0' is not x\.y\.z" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$leading_zero_version" "${ios_archive[@]}"
run_case "missing floors file fails closed" fail "missing .*/build-number-floors" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$no_floors" "${ios_archive[@]}"
run_case "floors file without entries fails closed" fail "build-number-floors has no entries" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$empty_floors" CI_XCODEBUILD_ACTION=archive "${ios[@]}" CI_BUILD_NUMBER=1
run_case "unknown floors platform fails closed" fail "unknown platform 'watchos'" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$watch_floor" "${ios_archive[@]}"
run_case "floors line without a build number fails closed" fail "expected '<platform> <version> <build>'" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$short_floor" "${ios_archive[@]}"
run_case "floors line with an extra field fails closed" fail "expected '<platform> <version> <build>'" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$long_floor" "${ios_archive[@]}"
run_case "duplicate floors entry fails closed" fail "duplicate entry for ios 1\.0\.0" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$duplicate_floor" "${ios_archive[@]}"
run_case "invalid floors build number fails closed" fail "invalid build number '0123'" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$zero_floor" "${ios_archive[@]}"
run_case "invalid floors version fails closed" fail "invalid version '1\.0\.0\.0'" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$version_floor" "${ios_archive[@]}"
run_case "two-part floors version fails closed instead of missing 1.0.0" fail \
  "invalid version '1\.0'; use x\.y\.z \(three numbers without leading zeros" "fixture-guard|is above the ios floor" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$two_part_floor" "${ios_archive[@]}"
run_case "leading-zero floors version fails closed" fail "invalid version '1\.0\.00'" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$leading_zero_floor" "${ios_archive[@]}"
no_platform_entry() { printf 'has no %s entry; every platform already has App Store Connect uploads' "$1"; }
run_case "macOS without a macos floor fails closed at build number 1" fail "$(no_platform_entry macos)" \
  "fixture-guard|new sequence" ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$no_mac_floor" \
  CI_XCODEBUILD_ACTION=archive "${mac[@]}" CI_BUILD_NUMBER=1
run_case "macOS without a macos floor fails closed above every other floor" fail "$(no_platform_entry macos)" \
  "fixture-guard|is above the" ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$no_mac_floor" \
  CI_XCODEBUILD_ACTION=archive "${mac[@]}" CI_BUILD_NUMBER="$above_floor"
run_case "macOS without a macos floor fails closed at a new marketing version" fail "$(no_platform_entry macos)" \
  "fixture-guard|new sequence" ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$no_mac_floor_next" \
  CI_XCODEBUILD_ACTION=archive "${mac[@]}" CI_BUILD_NUMBER=1
run_case "build-number check alone: macOS without a macos floor fails closed" fail "$(no_platform_entry macos)" \
  "new sequence" "$build_number_only" CI_PRIMARY_REPOSITORY_PATH="$no_mac_floor_next" CI_PRODUCT_PLATFORM=macOS \
  CI_BUILD_NUMBER=1
run_case "iOS above its floor still passes when only macos is missing" pass "above the ios floor $ios_floor.*$all_guards" "" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$no_mac_floor" CI_XCODEBUILD_ACTION=archive "${ios[@]}" \
  CI_BUILD_NUMBER="$((ios_floor + 1))"
run_case "iOS without an ios floor fails closed at a new marketing version" fail "$(no_platform_entry ios)" \
  "fixture-guard|new sequence" ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$no_ios_floor_next" \
  CI_XCODEBUILD_ACTION=archive "${ios[@]}" CI_BUILD_NUMBER=1
run_case "tvOS without a tvos floor fails closed above every other floor" fail "$(no_platform_entry tvos)" \
  "fixture-guard|is above the" ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$no_tv_floor" \
  CI_XCODEBUILD_ACTION=archive "${tv[@]}" CI_BUILD_NUMBER="$above_floor"
run_case "xrOS without a visionos floor fails closed at a new marketing version" fail "$(no_platform_entry visionos)" \
  "fixture-guard|new sequence" ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$no_vision_floor_next" \
  CI_XCODEBUILD_ACTION=archive CI_XCODE_SCHEME=CanadianHamVision CI_PRODUCT_PLATFORM=xrOS CI_BUILD_NUMBER=1
for platform_case in "macOS:CanadianHam" "iOS:CanadianHam" "tvOS:CanadianHamTV" "visionOS:CanadianHamVision"; do
  platform_args=(CI_XCODEBUILD_ACTION=archive CI_XCODE_SCHEME="${platform_case#*:}"
    CI_PRODUCT_PLATFORM="${platform_case%%:*}" CI_BUILD_NUMBER=1)
  run_case "${platform_case%%:*}: missing floors file fails closed at a new marketing version" fail \
    "missing .*/build-number-floors" "fixture-guard|new sequence" ci_pre_xcodebuild.sh \
    CI_PRIMARY_REPOSITORY_PATH="$no_floors_next" "${platform_args[@]}"
  run_case "${platform_case%%:*}: zero-byte floors file fails closed at a new marketing version" fail \
    "build-number-floors has no entries" "fixture-guard|new sequence" ci_pre_xcodebuild.sh \
    CI_PRIMARY_REPOSITORY_PATH="$zero_byte_floors" "${platform_args[@]}"
  run_case "${platform_case%%:*}: comment-only floors file fails closed at a new marketing version" fail \
    "build-number-floors has no entries" "fixture-guard|new sequence" ci_pre_xcodebuild.sh \
    CI_PRIMARY_REPOSITORY_PATH="$comment_floors_next" "${platform_args[@]}"
  if [[ -r "$unreadable_floors/$fixture_floors" ]]; then
    # Root can read a mode 000 file, so this case can't be simulated.
    failures=$((failures + 1))
    printf 'FAIL %s: unreadable floors file is still readable; run the harness as a non-root user\n' \
      "${platform_case%%:*}" >&2
  else
    run_case "${platform_case%%:*}: unreadable floors file fails closed at a new marketing version" fail \
      "cannot read .*/build-number-floors" "fixture-guard|new sequence" ci_pre_xcodebuild.sh \
      CI_PRIMARY_REPOSITORY_PATH="$unreadable_floors" "${platform_args[@]}"
  fi
done

printf '== Non-archive actions\n'
run_case "build action runs the guards without archive checks" pass "$all_guards" "uses Release" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=build \
  CI_XCODE_SCHEME=CanadianHamWatch CI_PRODUCT_PLATFORM=watchOS CI_BUILD_NUMBER=1
run_case "analyze action runs the guards without archive checks" pass "$all_guards" "uses Release|build number" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=analyze \
  CI_XCODE_SCHEME=CanadianHam CI_PRODUCT_PLATFORM=iOS CI_BUILD_NUMBER=1
run_case "analyze post-clone runs the guards" pass "$all_guards" "" ci_post_clone.sh \
  CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=analyze
run_case "analyze with a failing guard fails" fail "Apple guard check:apple-icloud-gate failed" "guards passed" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$failing" CI_XCODEBUILD_ACTION=analyze
run_case "build-for-testing runs the guards" pass "$all_guards" "" ci_pre_xcodebuild.sh \
  CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=build-for-testing CI_BUILD_NUMBER=2
run_case "test-without-building pre-xcodebuild skips without source" pass "has no source" "fixture-guard|stub-brew" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$empty" CI_XCODEBUILD_ACTION=test-without-building
run_case "test-without-building post-clone skips without source" pass "no source on this test-without-building runner" "stub-brew" \
  ci_post_clone.sh CI_PRIMARY_REPOSITORY_PATH="$empty" CI_XCODEBUILD_ACTION=test-without-building
run_case "post-clone without source fails" fail "repository source not found" "" \
  ci_post_clone.sh CI_PRIMARY_REPOSITORY_PATH="$empty" CI_XCODEBUILD_ACTION=build
run_case "pre-xcodebuild build without source fails" fail "repository source not found" "" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$empty" CI_XCODEBUILD_ACTION=build

printf '== Guard failures\n'
run_case "failing guard stops post-clone" fail "Apple guard check:apple-icloud-gate failed" "test:apple-icloud-gate" \
  ci_post_clone.sh CI_PRIMARY_REPOSITORY_PATH="$failing" CI_XCODEBUILD_ACTION=archive
run_case "failing guard stops an archive" fail "Apple guard check:apple-icloud-gate failed" "guards passed" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$failing" "${ios_archive[@]}"
run_case "missing guard script fails closed" fail "Apple guard test:apple-network failed" "guards passed" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$missing" CI_XCODEBUILD_ACTION=build

printf '== Node discovery (stub or sandbox-hidden Homebrew only)\n'
run_case "missing Node with failing Homebrew fails closed" fail "brew install node@26 failed" "fixture-guard" \
  ci_post_clone.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=build \
  PATH="$system_path" CH_TEST_BREW_MODE=fail
run_case "unreachable Homebrew fails closed" fail "brew install node@26 failed" "fixture-guard" \
  ci_post_clone.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=build \
  PATH="$system_path" CANADIAN_HAM_CI_BREW="$tmp_root/no-such-brew"
rm -rf "$stub_prefix"
run_case "wrong Homebrew Node major fails closed" fail "did not provide Node 26" "fixture-guard" \
  ci_post_clone.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=build \
  PATH="$system_path" CH_TEST_BREW_MODE=wrong
rm -rf "$stub_prefix"
run_case "missing Node is installed with Homebrew node@26" pass "stub-brew install node@26.*using Homebrew node@26.*$all_guards" "" \
  ci_post_clone.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=build \
  PATH="$system_path" CH_TEST_BREW_MODE=install
run_case "installed Homebrew node@26 is reused" pass "using Homebrew node@26" "stub-brew install" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=build \
  PATH="$system_path" CH_TEST_BREW_MODE=fail
rm -rf "$stub_prefix"
wrong_bin="$tmp_root/wrong-node-bin"
mkdir -p "$wrong_bin"
printf '#!/bin/bash\necho v24.1.0\n' >"$wrong_bin/node"
chmod +x "$wrong_bin/node"
run_case "wrong Node major on PATH is not used" fail "brew install node@26 failed" "fixture-guard" \
  ci_post_clone.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=build \
  PATH="$wrong_bin:$system_path" CH_TEST_BREW_MODE=fail

# The real "Homebrew is unavailable" branch, with the test hook disabled: a
# sandbox hides the Homebrew prefixes. It runs only after proving the same
# sandbox hides every brew the script could find, so it can never reach a real
# `brew install`; otherwise it is skipped.
sandbox_profile='(version 1)(allow default)(deny file-read* (subpath "/opt/homebrew") (subpath "/usr/local"))(deny process-exec (subpath "/opt/homebrew") (subpath "/usr/local"))'
no_brew_post_clone="$tmp_root/no-brew-post-clone.sh"
cat >"$no_brew_post_clone" <<SH
#!/bin/bash
exec /usr/bin/sandbox-exec -p '$sandbox_profile' "$ci_dir/ci_post_clone.sh"
SH
chmod +x "$no_brew_post_clone"
if [[ -x /usr/bin/sandbox-exec ]] && env -i PATH="$system_path" /usr/bin/sandbox-exec -p "$sandbox_profile" /bin/bash -c \
  '! command -v brew >/dev/null 2>&1 && [[ ! -e /opt/homebrew/bin/brew && ! -e /usr/local/bin/brew ]]'; then
  run_case "no Node and no Homebrew fails closed (sandboxed, no test hook)" fail \
    "Node 26 is not on PATH and Homebrew is unavailable" "stub-brew|fixture-guard|installing" \
    "$no_brew_post_clone" CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=build \
    PATH="$system_path" CANADIAN_HAM_CI_BREW=
else
  printf 'SKIP no Node and no Homebrew fails closed: sandbox-exec cannot hide Homebrew here\n'
fi

printf '== Post-xcodebuild archive checks\n'
clean_archive=$(make_archive clean-archive "")
push_archive=$(make_archive push-archive aps-environment)
icloud_archive=$(make_archive icloud-archive com.apple.developer.icloud-container-environment)
official_archive=$(make_archive official-archive "" official)
unsigned_archive="$tmp_root/unsigned.xcarchive"
mkdir -p "$unsigned_archive/Products/Applications"
make_app "$unsigned_archive/Products/Applications" CanadianHam
codesign --remove-signature "$unsigned_archive/Products/Applications/CanadianHam.app/CanadianHam" \
  || die "cannot strip the copied executable signature"
empty_archive="$tmp_root/empty.xcarchive"
mkdir -p "$empty_archive/Products/Applications"
extension_archive=$(make_archive extension-archive "")
add_extensions "$extension_archive"
push_extension_archive=$(make_archive push-extension-archive "")
add_extensions "$push_extension_archive" aps-environment
run_case "clean archive with embedded watch app passes" pass "checked 2 app and extension bundle" "" ci_post_xcodebuild.sh \
  CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE=0 CI_ARCHIVE_PATH="$clean_archive"
run_case "clean app extensions in PlugIns and Extensions are checked" pass "checked 4 app and extension bundle" "" \
  ci_post_xcodebuild.sh CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE=0 CI_ARCHIVE_PATH="$extension_archive"
run_case "push entitlement in a PlugIns app extension fails" fail "PlugIns/CanadianHamWidget\.appex is signed with iCloud, CloudKit or push" "" \
  ci_post_xcodebuild.sh CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE=0 CI_ARCHIVE_PATH="$push_extension_archive"
run_case "push entitlement in the watch app fails" fail "CanadianHamWatch.app is signed with iCloud, CloudKit or push" "" \
  ci_post_xcodebuild.sh CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE=0 CI_ARCHIVE_PATH="$push_archive"
run_case "iCloud entitlement fails" fail "is signed with iCloud, CloudKit or push" "" ci_post_xcodebuild.sh \
  CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE=0 CI_ARCHIVE_PATH="$icloud_archive"
run_case "bundled official reference sheet fails" fail "bundles the internal-only official reference sheet" "" \
  ci_post_xcodebuild.sh CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE=0 CI_ARCHIVE_PATH="$official_archive"
run_case "unsigned app fails closed" fail "cannot read signed entitlements" "" ci_post_xcodebuild.sh \
  CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE=0 CI_ARCHIVE_PATH="$unsigned_archive"
run_case "archive without apps fails closed" fail "no .app bundles found" "" ci_post_xcodebuild.sh \
  CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE=0 CI_ARCHIVE_PATH="$empty_archive"
run_case "successful archive without CI_ARCHIVE_PATH fails" fail "CI_ARCHIVE_PATH is not set" "" \
  ci_post_xcodebuild.sh CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE=0
run_case "failed archive is left to Xcode Cloud" pass "archive failed \(exit 65\)" "" ci_post_xcodebuild.sh \
  CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE=65
run_case "unset exit code still checks the archive" pass \
  "CI_XCODEBUILD_EXIT_CODE is not set; checking the archive anyway.*checked 2 app and extension bundle" "" \
  ci_post_xcodebuild.sh CI_XCODEBUILD_ACTION=archive CI_ARCHIVE_PATH="$clean_archive"
run_case "unset exit code still rejects a push entitlement" fail "CanadianHamWatch\.app is signed with iCloud, CloudKit or push" "" \
  ci_post_xcodebuild.sh CI_XCODEBUILD_ACTION=archive CI_ARCHIVE_PATH="$push_archive"
run_case "empty exit code still rejects a push entitlement" fail "CanadianHamWatch\.app is signed with iCloud, CloudKit or push" "" \
  ci_post_xcodebuild.sh CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE= CI_ARCHIVE_PATH="$push_archive"
run_case "unset exit code without CI_ARCHIVE_PATH fails" fail "CI_ARCHIVE_PATH is not set" "" \
  ci_post_xcodebuild.sh CI_XCODEBUILD_ACTION=archive
run_case "non-integer exit code fails closed" fail "CI_XCODEBUILD_EXIT_CODE 'failed' is not an exit code" "" \
  ci_post_xcodebuild.sh CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE=failed CI_ARCHIVE_PATH="$push_archive"
run_case "non-archive action has no archive checks" pass "no archive checks for test-without-building" "" \
  ci_post_xcodebuild.sh CI_XCODEBUILD_ACTION=test-without-building CI_XCODEBUILD_EXIT_CODE=0
run_case "analyze action has no archive checks" pass "no archive checks for analyze" "" \
  ci_post_xcodebuild.sh CI_XCODEBUILD_ACTION=analyze CI_XCODEBUILD_EXIT_CODE=0

printf 'xcode-cloud-ci-scripts-test: %s passed, %s failed\n' "$passes" "$failures"
((failures == 0))
