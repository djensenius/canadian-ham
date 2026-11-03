#!/usr/bin/env bash
# Dry run of the Xcode Cloud custom build scripts in apps/apple/ci_scripts.
# Simulates Xcode Cloud CI_* environments locally without building, archiving,
# signing with real identities, or installing anything: Homebrew is always a
# stub. Needs macOS (codesign, xmllint) and Node 26 on PATH.
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
floor=$(tr -d '[:space:]' <"$ci_dir/build-number-floor")
above_floor=$((floor + 1))

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

# Fixture repository: real shared schemes plus package.json guard stubs.
# make_fixture NAME [failing-guard] [missing-guard]
make_fixture() {
  local name=$1 failing=${2:-} missing=${3:-} root script command comma=""
  root="$tmp_root/$name"
  mkdir -p "$root/apps/apple/CanadianHam.xcodeproj/xcshareddata"
  cp -R "$schemes_dir" "$root/apps/apple/CanadianHam.xcodeproj/xcshareddata/"
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

# Fake archive with ad-hoc signed iOS-style app bundles.
# make_app DIR NAME [ENTITLEMENT_KEY]
make_app() {
  local dir=$1 name=$2 key=${3:-} app entitlements
  app="$dir/$name.app"
  mkdir -p "$app"
  cp /usr/bin/true "$app/$name"
  cat >"$app/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>CFBundleExecutable</key><string>$name</string><key>CFBundleIdentifier</key><string>test.canadianham.$name</string><key>CFBundlePackageType</key><string>APPL</string></dict></plist>
PLIST
  if [[ -n "$key" ]]; then
    entitlements="$dir/$name.entitlements"
    cat >"$entitlements" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>$key</key><string>production</string></dict></plist>
PLIST
    codesign -f -s - --entitlements "$entitlements" "$app" >/dev/null 2>&1 || die "cannot ad-hoc sign $app"
    rm -f "$entitlements"
  fi
}

sign_app() {
  codesign -f -s - "$1" >/dev/null 2>&1 || die "cannot ad-hoc sign $1"
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
# Runs one ci_scripts entry point with a clean environment plus the given
# variables, and checks its exit status and output.
run_case() {
  local name=$1 expect=$2 present=$3 absent=$4 script=$5 output flat status ok=1
  shift 5
  output=$(cd "$ci_dir" && env -i HOME="$HOME" TMPDIR="$tmp_root" PATH="$base_path" \
    CANADIAN_HAM_CI_BREW="$stub_brew" "$@" "$ci_dir/$script" 2>&1)
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

printf '== Real repository and real guards\n'
run_case "post-clone runs the real guards" pass "guards passed" "" ci_post_clone.sh \
  CI_XCODEBUILD_ACTION=archive
run_case "pre-xcodebuild iOS archive with real schemes and guards" pass "CanadianHam \(ios\) uses Release.*guards passed" "" \
  ci_pre_xcodebuild.sh "${ios_archive[@]}"

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
run_case "CONFIGURATION=DebugCloudKit is rejected" fail "sheet: CONFIGURATION$" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" CONFIGURATION=DebugCloudKit
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
run_case "ICLOUD_SYNC compiler flag is rejected" fail "sheet: OTHER_SWIFT_FLAGS$" "-DICLOUD_SYNC|fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" \
  OTHER_SWIFT_FLAGS='-Onone -DICLOUD_SYNC'
run_case "ICLOUD_SYNC variable name is rejected" fail "sheet: ICLOUD_SYNC$" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" ICLOUD_SYNC=1
run_case "CloudKit entitlements override is rejected" fail "sheet: CODE_SIGN_ENTITLEMENTS$" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" \
  CODE_SIGN_ENTITLEMENTS=CanadianHam/Resources/CanadianHam.iOS.CloudKit.entitlements
run_case "official reference sheet flag is rejected" fail "sheet: SWIFT_ACTIVE_COMPILATION_CONDITIONS$" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" "${ios_archive[@]}" \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS=OFFICIAL_REFERENCE_SHEET

printf '== Build number continuity\n'
run_case "build number equal to the Fastlane floor is rejected" fail "is not above the last Fastlane build $floor" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive \
  CI_XCODE_SCHEME=CanadianHam CI_PRODUCT_PLATFORM=iOS CI_BUILD_NUMBER="$floor"
run_case "default Xcode Cloud build number 1 is rejected" fail "CI_BUILD_NUMBER 1 is not above" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive \
  CI_XCODE_SCHEME=CanadianHam CI_PRODUCT_PLATFORM=iOS CI_BUILD_NUMBER=1
run_case "non-integer build number is rejected" fail "is not a positive integer" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive \
  CI_XCODE_SCHEME=CanadianHam CI_PRODUCT_PLATFORM=iOS CI_BUILD_NUMBER=1.2
run_case "missing build number is rejected" fail "is not a positive integer" "fixture-guard" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=archive \
  CI_XCODE_SCHEME=CanadianHam CI_PRODUCT_PLATFORM=iOS

printf '== Non-archive actions\n'
run_case "build action runs the guards without archive checks" pass "$all_guards" "uses Release" \
  ci_pre_xcodebuild.sh CI_PRIMARY_REPOSITORY_PATH="$clean" CI_XCODEBUILD_ACTION=build \
  CI_XCODE_SCHEME=CanadianHamWatch CI_PRODUCT_PLATFORM=watchOS CI_BUILD_NUMBER=1
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

printf '== Node discovery (stub Homebrew only)\n'
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
run_case "clean archive with embedded watch app passes" pass "checked 2 app bundle" "" ci_post_xcodebuild.sh \
  CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE=0 CI_ARCHIVE_PATH="$clean_archive"
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
run_case "non-archive action has no archive checks" pass "no archive checks for test-without-building" "" \
  ci_post_xcodebuild.sh CI_XCODEBUILD_ACTION=test-without-building CI_XCODEBUILD_EXIT_CODE=0

printf 'xcode-cloud-ci-scripts-test: %s passed, %s failed\n' "$passes" "$failures"
((failures == 0))
