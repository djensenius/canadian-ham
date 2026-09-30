#!/usr/bin/env bash
set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
default_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
repo_root=${APPLE_NO_NETWORK_ROOT:-$default_root}
cd "$repo_root" || exit 2

shopt -s nullglob

allowed_citation_url="https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service"
issue_count=0

report_issue() {
  printf 'apple-no-network: %s\n' "$1" >&2
  issue_count=$((issue_count + 1))
}

print_grep_matches() {
  local label=$1
  shift
  local had_match=0
  local line
  while IFS= read -r line; do
    if [[ $had_match -eq 0 ]]; then
      report_issue "$label"
      had_match=1
    fi
    printf '  %s\n' "$line" >&2
  done < <(grep -nE "$@" 2>/dev/null)
}

swift_files=()
if [[ -d apps/apple ]]; then
  while IFS= read -r file; do
    swift_files+=("$file")
  done < <(find apps/apple -type f -name '*.swift' -print | sort)
fi
for package_dir in packages/*-swift; do
  [[ -d "$package_dir" ]] || continue
  if [[ -d "$package_dir/Sources" ]]; then
    while IFS= read -r file; do
      swift_files+=("$file")
    done < <(find "$package_dir/Sources" -type f -name '*.swift' -print | sort)
  fi
  [[ -f "$package_dir/Package.swift" ]] && swift_files+=("$package_dir/Package.swift")
done

plist_files=()
if [[ -d apps/apple ]]; then
  while IFS= read -r file; do
    plist_files+=("$file")
  done < <(find apps/apple -type f \( -name '*.entitlements' -o -name '*.plist' -o -name '*.xcprivacy' \) -print | sort)
fi

config_files=()
for file in apps/apple/project.yml apps/apple/CanadianHam.xcodeproj/project.pbxproj; do
  [[ -f "$file" ]] && config_files+=("$file")
done

package_manifest_files=()
for package_dir in packages/*-swift; do
  [[ -d "$package_dir" ]] || continue
  [[ -f "$package_dir/Package.swift" ]] && package_manifest_files+=("$package_dir/Package.swift")
done

package_resolved_files=()
if [[ -d apps/apple ]]; then
  while IFS= read -r file; do
    package_resolved_files+=("$file")
  done < <(find apps/apple -type f -name 'Package.resolved' -print | sort)
fi
for package_dir in packages/*-swift; do
  [[ -d "$package_dir" ]] || continue
  while IFS= read -r file; do
    package_resolved_files+=("$file")
  done < <(find "$package_dir" -type f -name 'Package.resolved' -print | sort)
done
[[ -f Package.resolved ]] && package_resolved_files+=("Package.resolved")

if [[ ${#swift_files[@]} -eq 0 ]]; then
  report_issue "no Swift files found under apps/apple or packages/*-swift/Sources"
fi

if [[ ${#swift_files[@]} -gt 0 ]]; then
  source_identifier_pattern='(^|[^[:alnum:]_])(NSUbiquitous[[:alnum:]_]*|URLSession[[:alnum:]_]*|NSURLSession[[:alnum:]_]*|NSURLConnection[[:alnum:]_]*|URLRequest[[:alnum:]_]*|NSURLRequest[[:alnum:]_]*|NW[A-Z][[:alnum:]_]*|CK[A-Z][[:alnum:]_]*|CFSocket[[:alnum:]_]*|CFStream[[:alnum:]_]*|CFHTTP[[:alnum:]_]*|CFNetwork[[:alnum:]_]*|WKWebView[[:alnum:]_]*|SFSafariViewController[[:alnum:]_]*|ASWebAuthenticationSession[[:alnum:]_]*|CloudKit[[:alnum:]_]*|NSPersistentCloudKitContainer[[:alnum:]_]*|Firebase[[:alnum:]_]*|FirebaseAnalytics[[:alnum:]_]*|Crashlytics[[:alnum:]_]*|GoogleAnalytics[[:alnum:]_]*|GoogleTagManager[[:alnum:]_]*|Sentry[[:alnum:]_]*|Segment[[:alnum:]_]*|Mixpanel[[:alnum:]_]*|Amplitude[[:alnum:]_]*|PostHog[[:alnum:]_]*|Datadog[[:alnum:]_]*|AppCenter[[:alnum:]_]*|AdMob[[:alnum:]_]*|AppsFlyer[[:alnum:]_]*|Adjust[[:alnum:]_]*|Braze[[:alnum:]_]*|Snowplow[[:alnum:]_]*|TelemetryDeck[[:alnum:]_]*|Bugsnag[[:alnum:]_]*|NewRelic[[:alnum:]_]*|[[:alnum:]_]*(WebSocket|Socket)[[:alnum:]_]*)([^[:alnum:]_]|$)'
  source_import_pattern='^[[:space:]]*import[[:space:]]+(Network|CloudKit|WebKit|SafariServices|CFNetwork|AuthenticationServices|Firebase[[:alnum:]_]*|[[:alnum:]_]*Analytics[[:alnum:]_]*)([^[:alnum:]_]|$)'
  lowercase_socket_pattern='(^|[^[:alnum:]_])socket[[:space:]]*\('
  source_api_pattern="$source_import_pattern|$source_identifier_pattern|$lowercase_socket_pattern"
  print_grep_matches "forbidden networking, browser, iCloud, socket, or analytics SDK symbol in Swift source" "$source_api_pattern" "${swift_files[@]}"

  url_pattern='https?://[^[:space:]"<>)]+|mailto:[^[:space:]"<>)]+|tel:[^[:space:]"<>)]+|sms:[^[:space:]"<>)]+|[A-Za-z][A-Za-z0-9+.-]*://[^[:space:]"<>)]+'
  while IFS= read -r match_line; do
    file=${match_line%%:*}
    rest=${match_line#*:}
    line_number=${rest%%:*}
    text=${rest#*:}
    while [[ $text =~ $url_pattern ]]; do
      url=${BASH_REMATCH[0]}
      while [[ $url == *[.,\;\]\}] ]]; do
        url=${url%?}
      done
      if [[ "$url" != "$allowed_citation_url" ]]; then
        report_issue "unexpected URL literal in Swift source: $file:$line_number: $url"
      fi
      text=${text#*"${BASH_REMATCH[0]}"}
    done
  done < <(grep -nE "$url_pattern" "${swift_files[@]}" 2>/dev/null)
fi

if [[ ${#plist_files[@]} -gt 0 ]]; then
  for file in "${plist_files[@]}"; do
    if ! plutil -lint "$file" >/dev/null; then
      report_issue "plist lint failed for $file"
    fi
  done

  entitlement_pattern='com\.apple\.security\.network\.(client|server)|com\.apple\.developer\.(icloud|ubiquity|aps-environment)|com\.apple\.developer\.icloud|NSUbiquitous|NSPersistentCloudKitContainer|CloudKit|NSLocalNetworkUsageDescription|NSBonjourServices|NSAppTransportSecurity|NSAllowsArbitraryLoads|NSAllowsLocalNetworking|WKAppBoundDomains'
  print_grep_matches "forbidden network client/server, iCloud, local-network, or transport-security entitlement/Info key" "$entitlement_pattern" "${plist_files[@]}"
fi

if [[ ${#config_files[@]} -gt 0 ]]; then
  config_entitlement_pattern='com\.apple\.security\.network\.(client|server)|com\.apple\.developer\.(icloud|ubiquity|aps-environment)|CODE_SIGN_ENTITLEMENTS.*(iCloud|CloudKit)|INFOPLIST_KEY_(NSLocalNetworkUsageDescription|NSBonjourServices|NSAppTransportSecurity|NSAllowsArbitraryLoads|NSAllowsLocalNetworking|WKAppBoundDomains)'
  print_grep_matches "forbidden network/iCloud entitlement or Info.plist key in Apple project configuration" "$config_entitlement_pattern" "${config_files[@]}"

  project_remote_package_pattern='XCRemoteSwiftPackageReference|repositoryURL'
  print_grep_matches "remote Swift package reference in Apple Xcode project" "$project_remote_package_pattern" "${config_files[@]}"
fi

if [[ -f apps/apple/project.yml ]]; then
  project_package_pattern='^[[:space:]]*(url|github|branch|from|exactVersion|revision):[[:space:]]+'
  print_grep_matches "non-local Swift package dependency in apps/apple/project.yml" "$project_package_pattern" apps/apple/project.yml
fi

if [[ ${#package_manifest_files[@]} -gt 0 ]]; then
  manifest_dependency_pattern='\.package[[:space:]]*\([[:space:]]*url:|^[[:space:]]*url:[[:space:]]*"(https?|git|ssh)://|github\.com'
  print_grep_matches "non-local Swift package dependency in packages/*-swift/Package.swift" "$manifest_dependency_pattern" "${package_manifest_files[@]}"
fi

if [[ ${#package_resolved_files[@]} -gt 0 ]]; then
  resolved_remote_pattern='https?://|git@|ssh://|github\.com|gitlab\.com|bitbucket\.org|repositoryURL'
  print_grep_matches "Package.resolved contains remote package pins; Apple builds must use local packages only" "$resolved_remote_pattern" "${package_resolved_files[@]}"
fi

if [[ $issue_count -ne 0 ]]; then
  printf 'apple-no-network: failed with %d issue(s).\n' "$issue_count" >&2
  exit 1
fi

printf 'apple-no-network: passed (%d Swift files, %d plist/privacy files, %d project config files).\n' "${#swift_files[@]}" "${#plist_files[@]}" "${#config_files[@]}"
