#!/usr/bin/env bash
set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
audit_script="$script_dir/check-apple-no-network.sh"
rbr4_url="https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service"
tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/apple-network-audit-test.XXXXXX") || exit 2
failures=0

cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

fail() {
  printf 'apple-no-network-test: FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

make_fake_grep_error_path() {
  local name=$1
  local fake_bin="$tmp_root/$name-bin"
  local real_grep
  real_grep=$(command -v grep) || return 1
  mkdir -p "$fake_bin"
  cat > "$fake_bin/grep" <<SH
#!/usr/bin/env bash
for arg in "\$@"; do
  case "\$arg" in
    *'https?://'*)
      printf 'grep: synthetic URL scan failure\n' >&2
      exit 2
      ;;
  esac
done
exec "$real_grep" "\$@"
SH
  chmod +x "$fake_bin/grep"
  printf '%s:%s\n' "$fake_bin" "$PATH"
}

make_path_without_plutil() {
  local name=$1
  local fake_bin="$tmp_root/$name-bin"
  local tool
  local tool_path
  mkdir -p "$fake_bin"
  for tool in dirname find grep sort; do
    tool_path=$(command -v "$tool") || return 1
    ln -s "$tool_path" "$fake_bin/$tool"
  done
  printf '%s\n' "$fake_bin"
}

make_fixture() {
  local name=$1
  local root="$tmp_root/$name"
  mkdir -p "$root/apps/apple"
  cat > "$root/apps/apple/Clean.swift" <<'SWIFT'
import SwiftUI

struct CleanOfflineView {
    let title = "Offline only"
}
SWIFT
  printf '%s\n' "$root"
}

run_audit() {
  local root=$1
  shift
  env APPLE_NO_NETWORK_ROOT="$root" "$@" "$BASH" "$audit_script" 2>&1
}

assert_passes() {
  local name=$1
  local root=$2
  local output
  output=$(run_audit "$root")
  local status=$?
  if [[ $status -ne 0 ]]; then
    fail "$name expected pass but exited $status: $output"
    return
  fi
  case "$output" in
    *"apple-no-network: passed ("*) ;;
    *) fail "$name pass output did not include summary: $output" ;;
  esac
}

assert_fails_with_labels() {
  local name=$1
  local root=$2
  shift 2
  local output
  output=$(run_audit "$root")
  local status=$?
  if [[ $status -eq 0 ]]; then
    fail "$name expected failure but passed: $output"
    return
  fi
  local expected_label
  for expected_label in "$@"; do
    case "$output" in
      *"apple-no-network: $expected_label"*) ;;
      *) fail "$name output missed expected rule label '$expected_label': $output" ;;
    esac
  done
}

assert_swift_sample_fails_with_label() {
  local name=$1
  local sample=$2
  local label=$3
  local root
  root=$(make_fixture "$name")
  printf '%s\n' "$sample" > "$root/apps/apple/${name}.swift"
  assert_fails_with_labels "$name" "$root" "$label"
}

assert_lesson_sample_fails_with_label() {
  local name=$1
  local sample=$2
  local root
  root=$(make_fixture "$name")
  mkdir -p "$root/content/lessons/m-001"
  cat > "$root/content/lessons/m-001/${name}.md" <<MD
---
type: lesson
id: $name
covers: []
---

$sample
MD
  assert_fails_with_labels "$name" "$root" \
    "unexpected content link/contact in bundled lesson Markdown"
}

clean_root=$(make_fixture clean)
cat > "$clean_root/apps/apple/AllowedCitation.swift" <<SWIFT
let rbr4CitationURL = "$rbr4_url"
SWIFT
mkdir -p "$clean_root/content/lessons/m-001" "$clean_root/content/explanations/b-001"
cat > "$clean_root/content/lessons/m-001/allowed.md" <<MD
---
type: lesson
id: allowed
covers: []
---

The RBR-4 citation link is allowed: [RBR-4]($rbr4_url) and <$rbr4_url>.
MD
cat > "$clean_root/content/explanations/b-001/allowed.json" <<JSON
{
  "citations": [
    { "type": "rbr-4", "url": "$rbr4_url" }
  ]
}
JSON
assert_passes "clean fixture" "$clean_root"

source_symbol_label="forbidden networking, browser, iCloud, socket, or analytics SDK symbol in Swift source"
assert_swift_sample_fails_with_label "symbol-nsubiquitous" "let iCloudStore = NSUbiquitousKeyValueStore.default" "$source_symbol_label"
assert_swift_sample_fails_with_label "symbol-urlsession" "let urlSessionTask: URLSessionDataTask? = nil" "$source_symbol_label"
assert_swift_sample_fails_with_label "symbol-nsurlsession" "let nsUrlSessionTask: NSURLSessionTask? = nil" "$source_symbol_label"
assert_swift_sample_fails_with_label "symbol-nsurlconnection" "let urlConnection: NSURLConnection? = nil" "$source_symbol_label"
assert_swift_sample_fails_with_label "symbol-nw" "let networkMonitor: NWPathMonitor? = nil" "$source_symbol_label"
assert_swift_sample_fails_with_label "symbol-ck" "let cloudRecord: CKRecord? = nil" "$source_symbol_label"
assert_swift_sample_fails_with_label "symbol-cfsocket" "let coreFoundationSocket: CFSocket? = nil" "$source_symbol_label"
assert_swift_sample_fails_with_label "symbol-cfstream" "let s = CFStreamCreateBoundPair" "$source_symbol_label"
assert_swift_sample_fails_with_label "symbol-cfhttp" "let coreFoundationHTTP: CFHTTPMessage? = nil" "$source_symbol_label"
assert_swift_sample_fails_with_label "symbol-firebase" "let firebaseApp = FirebaseApp.self" "$source_symbol_label"
assert_swift_sample_fails_with_label "symbol-socket" "let appSocket = StudySocketClient()" "$source_symbol_label"
assert_swift_sample_fails_with_label "symbol-websocket" "let webSocket = LessonWebSocketBridge()" "$source_symbol_label"
assert_swift_sample_fails_with_label "symbol-lowercase-socket" "let handle = socket(0, 0, 0)" "$source_symbol_label"

nested_source_root=$(make_fixture nested-swift-source)
mkdir -p "$nested_source_root/packages/sample-swift/Sources/Feature/Nested"
cat > "$nested_source_root/packages/sample-swift/Sources/Feature/Nested/Forbidden.swift" <<'SWIFT'
let connection = NWConnection.self
SWIFT
assert_fails_with_labels "nested Swift source traversal" "$nested_source_root" \
  "$source_symbol_label"

assert_swift_sample_fails_with_label "import-network" "import Network" "$source_symbol_label"
assert_swift_sample_fails_with_label "import-cloudkit" "import CloudKit" "$source_symbol_label"
assert_swift_sample_fails_with_label "import-webkit" "import WebKit" "$source_symbol_label"
assert_swift_sample_fails_with_label "import-safariservices" "import SafariServices" "$source_symbol_label"
assert_swift_sample_fails_with_label "import-cfnetwork" "import CFNetwork" "$source_symbol_label"
assert_swift_sample_fails_with_label "import-authservices" "import AuthenticationServices" "$source_symbol_label"
assert_swift_sample_fails_with_label "import-firebase" "import FirebaseCore" "$source_symbol_label"
assert_swift_sample_fails_with_label "import-analytics" "import StudyAnalytics" "$source_symbol_label"
assert_swift_sample_fails_with_label "import-attributed" "@preconcurrency import WebKit" "$source_symbol_label"
assert_swift_sample_fails_with_label "import-implementation-only" "@_implementationOnly import Network" "$source_symbol_label"
assert_swift_sample_fails_with_label "import-kind" "import enum WebKit.WKNavigationType" "$source_symbol_label"

url_label="unexpected URL literal in Swift source"
assert_swift_sample_fails_with_label "url-mailto" "let supportEmail = \"mailto:help@example.test\"" "$url_label"
assert_swift_sample_fails_with_label "url-tel" "let supportPhone = \"tel:+18005550100\"" "$url_label"
assert_swift_sample_fails_with_label "url-sms" "let supportSms = \"sms:+18005550100\"" "$url_label"
assert_swift_sample_fails_with_label "url-custom-scheme" "let customDeepLink = \"canadianham://practice\"" "$url_label"

grep_error_root=$(make_fixture grep-error)
grep_error_path=$(make_fake_grep_error_path grep-error)
grep_error_output=$(run_audit "$grep_error_root" "PATH=$grep_error_path")
grep_error_status=$?
if [[ $grep_error_status -eq 0 ]]; then
  fail "grep-error expected failure but passed: $grep_error_output"
fi
case "$grep_error_output" in
  *"apple-no-network: grep failed while checking Swift URL literals"*) ;;
  *) fail "grep-error output missed Swift URL grep failure label: $grep_error_output" ;;
esac

assert_lesson_sample_fails_with_label "lesson-disallowed-url" "The allowed RBR-4 link remains acceptable: <$rbr4_url>. This disallowed URL must fail: https://example.test/resource."
assert_lesson_sample_fails_with_label "lesson-uppercase-https" "An uppercase scheme must fail: HTTPS://example.test/resource."
assert_lesson_sample_fails_with_label "lesson-email" "Contact instructor@example.test for help."
assert_lesson_sample_fails_with_label "lesson-www" "Visit www.example.test/path for details."
assert_lesson_sample_fails_with_label "lesson-uppercase-www" "Visit WWW.example.test/path for details."

explanation_root=$(make_fixture explanation-url)
mkdir -p "$explanation_root/content/explanations/b-001"
cat > "$explanation_root/content/explanations/b-001/disallowed.json" <<'JSON'
{
  "body": {
    "en": "A disallowed URL appears here: https://example.test/explanation",
    "fr": null
  }
}
JSON
assert_fails_with_labels "explanation URL references" "$explanation_root" \
  "unexpected URL in bundled explanation JSON"

plist_root=$(make_fixture plist-entitlements)
cat > "$plist_root/apps/apple/App.entitlements" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.network.client</key>
  <true/>
</dict>
</plist>
PLIST
assert_fails_with_labels "forbidden plist entitlement" "$plist_root" \
  "forbidden network client/server, iCloud, local-network, or transport-security entitlement/Info key"

plutil_missing_root=$(make_fixture plutil-missing)
cat > "$plutil_missing_root/apps/apple/Clean.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>OfflineOnly</key>
  <true/>
</dict>
</plist>
PLIST
plutil_missing_path=$(make_path_without_plutil plutil-missing)
plutil_missing_output=$(run_audit "$plutil_missing_root" "PATH=$plutil_missing_path")
plutil_missing_status=$?
if [[ $plutil_missing_status -ne 0 ]]; then
  fail "plutil-missing expected pass but exited $plutil_missing_status: $plutil_missing_output"
fi
case "$plutil_missing_output" in
  *"apple-no-network: skipping plist format lint because plutil is not available on this platform"*) ;;
  *) fail "plutil-missing output missed skip message: $plutil_missing_output" ;;
esac

config_root=$(make_fixture project-config)
cat > "$config_root/apps/apple/project.yml" <<'YAML'
settings:
  INFOPLIST_KEY_NSLocalNetworkUsageDescription: Uses local network
packages:
  RemotePackage:
    url: https://example.test/remote.git
YAML
mkdir -p "$config_root/apps/apple/CanadianHam.xcodeproj"
cat > "$config_root/apps/apple/CanadianHam.xcodeproj/project.pbxproj" <<'PBX'
/* Begin XCRemoteSwiftPackageReference section */
  repositoryURL = "https://example.test/remote.git";
/* End XCRemoteSwiftPackageReference section */
PBX
assert_fails_with_labels "forbidden project config" "$config_root" \
  "forbidden network/iCloud entitlement or Info.plist key in Apple project configuration" \
  "remote Swift package reference in Apple Xcode project" \
  "non-local Swift package dependency in apps/apple/project.yml"

manifest_root=$(make_fixture package-manifest)
mkdir -p "$manifest_root/packages/sample-swift"
cat > "$manifest_root/packages/sample-swift/Package.swift" <<'SWIFT'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sample",
    dependencies: [
        .package(url: "https://example.test/remote.git", from: "1.0.0")
    ]
)
SWIFT
assert_fails_with_labels "remote package manifest" "$manifest_root" \
  "non-local Swift package dependency in packages/*-swift/Package.swift"

resolved_root=$(make_fixture package-resolved)
cat > "$resolved_root/apps/apple/Package.resolved" <<'JSON'
{
  "pins" : [
    {
      "identity" : "remote",
      "location" : "https://example.test/remote.git",
      "state" : { "revision" : "abc" },
      "repositoryURL" : "https://example.test/remote.git"
    }
  ],
  "version" : 2
}
JSON
assert_fails_with_labels "remote package resolved" "$resolved_root" \
  "Package.resolved contains remote package pins; Apple builds must use local packages only"

if [[ $failures -ne 0 ]]; then
  printf 'apple-no-network-test: failed with %d failure(s).\n' "$failures" >&2
  exit 1
fi

printf 'apple-no-network-test: passed self-test fixtures.\n'
