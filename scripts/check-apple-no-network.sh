#!/usr/bin/env bash
set -u

script_dir=${BASH_SOURCE[0]%/*}
if [[ "$script_dir" == "${BASH_SOURCE[0]}" ]]; then
  script_dir=.
fi
repo_root=$script_dir/..
cd "$repo_root" || exit 2

shopt -s globstar nullglob

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
for file in apps/apple/**/*.swift packages/*-swift/Sources/**/*.swift packages/*-swift/Package.swift; do
  [[ -f "$file" ]] && swift_files+=("$file")
done

plist_files=()
for file in apps/apple/**/*.entitlements apps/apple/**/*.plist apps/apple/**/*.xcprivacy; do
  [[ -f "$file" ]] && plist_files+=("$file")
done

config_files=()
for file in apps/apple/project.yml apps/apple/CanadianHam.xcodeproj/project.pbxproj; do
  [[ -f "$file" ]] && config_files+=("$file")
done

package_manifest_files=()
for file in packages/*-swift/Package.swift; do
  [[ -f "$file" ]] && package_manifest_files+=("$file")
done

package_resolved_files=()
for file in apps/apple/**/Package.resolved packages/*-swift/**/Package.resolved Package.resolved; do
  [[ -f "$file" ]] && package_resolved_files+=("$file")
done

if [[ ${#swift_files[@]} -eq 0 ]]; then
  report_issue "no Swift files found under apps/apple or packages/*-swift/Sources"
fi

if [[ ${#swift_files[@]} -gt 0 ]]; then
  source_api_pattern='(^|[^[:alnum:]_])(URLSession|NSURLSession|URLSessionConfiguration|URLRequest|NSURLRequest|NWConnection|NWListener|NWPathMonitor|NWBrowser|NWEndpoint|NWParameters|CFNetwork|WKWebView|SFSafariViewController|ASWebAuthenticationSession|CloudKit|NSPersistentCloudKitContainer|CKContainer|CKDatabase|CKRecord|NSUbiquitous|Firebase|FirebaseAnalytics|Crashlytics|GoogleAnalytics|GoogleTagManager|Sentry|Segment|Mixpanel|Amplitude|PostHog|Datadog|AppCenter|AdMob|AppsFlyer|Adjust|Braze|Snowplow|TelemetryDeck|Bugsnag|NewRelic|Socket)([^[:alnum:]_]|$)|^[[:space:]]*import[[:space:]]+Network([^[:alnum:]_]|$)'
  print_grep_matches "forbidden networking, browser, iCloud, socket, or analytics SDK symbol in Swift source" "$source_api_pattern" "${swift_files[@]}"

  url_pattern='https?://[^[:space:]"<>)]+'
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

for file in "${plist_files[@]}"; do
  if ! plutil -lint "$file" >/dev/null; then
    report_issue "plist lint failed for $file"
  fi
done

if [[ ${#plist_files[@]} -gt 0 ]]; then
  entitlement_pattern='com\.apple\.security\.network\.(client|server)|com\.apple\.developer\.(icloud|ubiquity|aps-environment)|com\.apple\.developer\.icloud|NSUbiquitous|NSPersistentCloudKitContainer|CloudKit|NSLocalNetworkUsageDescription|NSBonjourServices|NSAppTransportSecurity|NSAllowsArbitraryLoads|NSAllowsLocalNetworking|WKAppBoundDomains'
  print_grep_matches "forbidden network client/server, iCloud, local-network, or transport-security entitlement/Info key" "$entitlement_pattern" "${plist_files[@]}"
fi

if [[ ${#config_files[@]} -gt 0 ]]; then
  config_entitlement_pattern='com\.apple\.security\.network\.(client|server)|com\.apple\.developer\.(icloud|ubiquity|aps-environment)|CODE_SIGN_ENTITLEMENTS.*(iCloud|CloudKit)|INFOPLIST_KEY_(NSLocalNetworkUsageDescription|NSBonjourServices|NSAppTransportSecurity|NSAllowsArbitraryLoads|NSAllowsLocalNetworking|WKAppBoundDomains)'
  print_grep_matches "forbidden network/iCloud entitlement or Info.plist key in Apple project configuration" "$config_entitlement_pattern" "${config_files[@]}"

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
