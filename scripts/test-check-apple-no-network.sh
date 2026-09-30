#!/usr/bin/env bash
set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
audit_script="$script_dir/check-apple-no-network.sh"
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
  APPLE_NO_NETWORK_ROOT="$root" "$BASH" "$audit_script" 2>&1
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

assert_fails_with() {
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
  local expected
  for expected in "$@"; do
    case "$output" in
      *"$expected"*) ;;
      *) fail "$name output missed expected text '$expected': $output" ;;
    esac
  done
}

clean_root=$(make_fixture clean)
cat > "$clean_root/apps/apple/AllowedCitation.swift" <<'SWIFT'
let rbr4CitationURL = "https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service"
SWIFT
assert_passes "clean fixture" "$clean_root"

prefix_root=$(make_fixture prefix-families)
cat > "$prefix_root/apps/apple/ForbiddenPrefixes.swift" <<'SWIFT'
let iCloudStore = NSUbiquitousKeyValueStore.default
let urlSessionTask: URLSessionDataTask? = nil
let nsUrlSessionTask: NSURLSessionTask? = nil
let urlConnection: NSURLConnection? = nil
let networkMonitor: NWPathMonitor? = nil
let cloudRecord: CKRecord? = nil
let coreFoundationSocket: CFSocket? = nil
let coreFoundationStream = CFStreamCreatePairWithSocketToHost
let coreFoundationHTTP: CFHTTPMessage? = nil
let firebaseApp = FirebaseApp.self
let appSocket = StudySocketClient()
let webSocket = LessonWebSocketBridge()
let posixSocket = socket(0, 0, 0)
SWIFT
assert_fails_with "prefix-family symbols" "$prefix_root" \
  "NSUbiquitousKeyValueStore" \
  "URLSessionDataTask" \
  "NSURLSessionTask" \
  "NSURLConnection" \
  "NWPathMonitor" \
  "CKRecord" \
  "CFSocket" \
  "CFStreamCreatePairWithSocketToHost" \
  "CFHTTPMessage" \
  "FirebaseApp" \
  "StudySocketClient" \
  "LessonWebSocketBridge" \
  "socket(0"

import_root=$(make_fixture forbidden-imports)
cat > "$import_root/apps/apple/ForbiddenImports.swift" <<'SWIFT'
import Network
import CloudKit
import WebKit
import SafariServices
import CFNetwork
import AuthenticationServices
import FirebaseCore
import FirebaseAnalytics
import StudyAnalytics
SWIFT
assert_fails_with "forbidden imports" "$import_root" \
  "import Network" \
  "import CloudKit" \
  "import WebKit" \
  "import SafariServices" \
  "import CFNetwork" \
  "import AuthenticationServices" \
  "import FirebaseCore" \
  "import FirebaseAnalytics" \
  "import StudyAnalytics"

url_root=$(make_fixture url-schemes)
cat > "$url_root/apps/apple/URLSchemes.swift" <<'SWIFT'
let allowed = "https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service"
let supportEmail = "mailto:help@example.test"
let supportPhone = "tel:+18005550100"
let supportSms = "sms:+18005550100"
let customDeepLink = "canadianham://practice"
SWIFT
assert_fails_with "non-http URL schemes" "$url_root" \
  "mailto:help@example.test" \
  "tel:+18005550100" \
  "sms:+18005550100" \
  "canadianham://practice"

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
assert_fails_with "forbidden plist entitlement" "$plist_root" \
  "com.apple.security.network.client"

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
assert_fails_with "forbidden project config" "$config_root" \
  "INFOPLIST_KEY_NSLocalNetworkUsageDescription" \
  "XCRemoteSwiftPackageReference" \
  "repositoryURL" \
  "url: https://example.test/remote.git"

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
assert_fails_with "remote package manifest" "$manifest_root" \
  ".package(url:" \
  "https://example.test/remote.git"

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
assert_fails_with "remote package resolved" "$resolved_root" \
  "Package.resolved contains remote package pins" \
  "repositoryURL"

if [[ $failures -ne 0 ]]; then
  printf 'apple-no-network-test: failed with %d failure(s).\n' "$failures" >&2
  exit 1
fi

printf 'apple-no-network-test: passed self-test fixtures.\n'
