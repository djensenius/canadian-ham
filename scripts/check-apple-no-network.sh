#!/usr/bin/env bash
set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
default_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
repo_root=${APPLE_NO_NETWORK_ROOT:-$default_root}
cd "$repo_root" || exit 2

shopt -s nullglob

# Keep this exact RBR-4 URL in sync with OFFICIAL_SOURCE_CITATION_URLS
# in apps/web/scripts/audit-dist-urls.ts.
allowed_citation_url="https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service"
# Bundled lessons/explanations are copied into the Apple app. Their external
# content references are allowed only when they are the exact RBR-4 URL above or
# satisfy check-explanations' citation rule: absolute https URLs on
# ised-isde.canada.ca or www.ised-isde.canada.ca, with no credentials.
allowed_ised_citation_pattern='^https://(ised-isde\.canada\.ca|www\.ised-isde\.canada\.ca)(/|[?#]|$)'
issue_count=0

report_issue() {
  printf 'apple-no-network: %s\n' "$1" >&2
  issue_count=$((issue_count + 1))
}

print_grep_matches() {
  local label=$1
  shift
  local output
  local status
  output=$(grep -nE -- "$@" 2>&1)
  status=$?
  if [[ $status -eq 1 ]]; then
    return
  fi
  if [[ $status -gt 1 ]]; then
    report_issue "grep failed while checking $label"
  else
    report_issue "$label"
  fi
  local line
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    printf '  %s\n' "$line" >&2
  done <<< "$output"
}

normalize_detected_content_reference() {
  local token=$1
  if [[ $token == \<*\> ]]; then
    token=${token#<}
    token=${token%>}
  fi
  while [[ $token == *[.,\;\]\}] ]]; do
    token=${token%?}
  done
  printf '%s\n' "$token"
}

is_allowed_content_citation_url() {
  local url=$1
  [[ "$url" == "$allowed_citation_url" ]] && return 0
  [[ $url =~ $allowed_ised_citation_pattern ]]
}

scan_text_files_for_content_references() {
  local label=$1
  local pattern=$2
  shift 2
  local file
  local line
  local line_number
  local text
  local raw_reference
  local reference
  for file in "$@"; do
    line_number=0
    while IFS= read -r line || [[ -n $line ]]; do
      line_number=$((line_number + 1))
      text=$line
      while [[ $text =~ $pattern ]]; do
        raw_reference=${BASH_REMATCH[0]}
        reference=$(normalize_detected_content_reference "$raw_reference")
        if ! is_allowed_content_citation_url "$reference"; then
          report_issue "$label: $file:$line_number: $reference"
        fi
        text=${text#*"$raw_reference"}
      done
    done < "$file"
  done
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

lesson_markdown_files=()
if [[ -d content/lessons ]]; then
  while IFS= read -r file; do
    lesson_markdown_files+=("$file")
  done < <(find content/lessons -type f -name '*.md' -print | sort)
fi

explanation_json_files=()
if [[ -d content/explanations ]]; then
  while IFS= read -r file; do
    explanation_json_files+=("$file")
  done < <(find content/explanations -type f -name '*.json' -print | sort)
fi

if [[ ${#swift_files[@]} -eq 0 ]]; then
  report_issue "no Swift files found under apps/apple or packages/*-swift/Sources"
fi

network_swift_files=("${swift_files[@]}")
if [[ ${#swift_files[@]} -gt 0 ]]; then
  sanitized_swift_dir=$(mktemp -d)
  trap 'rm -rf "$sanitized_swift_dir"' EXIT
  network_swift_files=()
  for file in "${swift_files[@]}"; do
    sanitized_file="$sanitized_swift_dir/$file"
    mkdir -p "$(dirname "$sanitized_file")"
    awk '
      function is_exact_icloud_if(line) { return line ~ /^[[:space:]]*#if[[:space:]]+ICLOUD_SYNC[[:space:]]*(\/\/.*)?$/ }
      # Inside an exact "#if ICLOUD_SYNC" branch, only the approved CloudKit APIs are exempt:
      # drop "import CloudKit" and CK*/CloudKit* identifiers, and keep scanning everything else.
      skipping == 0 && is_exact_icloud_if($0) { skipping = 1; depth = 1; print ""; next }
      skipping == 1 {
        if ($0 ~ /^[[:space:]]*#if([[:space:]]|$)/) { depth++; print ""; next }
        if (depth == 1 && $0 ~ /^[[:space:]]*#(else|elseif)([[:space:]]|$)/) { skipping = 0; depth = 0; print ""; next }
        if ($0 ~ /^[[:space:]]*#endif([[:space:]]|$)/) { depth--; if (depth == 0) { skipping = 0 }; print ""; next }
        if ($0 ~ /^[[:space:]]*import[[:space:]]+CloudKit[[:space:]]*(\/\/.*)?$/) { print ""; next }
        line = $0
        gsub(/CK[A-Z][A-Za-z0-9_]*/, "", line)
        gsub(/[A-Za-z0-9_]*CloudKit[A-Za-z0-9_]*/, "", line)
        print line
        next
      }
      { print }
    ' "$file" > "$sanitized_file"
    network_swift_files+=("$sanitized_file")
  done
fi

if [[ ${#network_swift_files[@]} -gt 0 ]]; then
  source_identifier_pattern='(^|[^[:alnum:]_])(NSUbiquitous[[:alnum:]_]*|URLSession[[:alnum:]_]*|NSURLSession[[:alnum:]_]*|NSURLConnection[[:alnum:]_]*|URLRequest[[:alnum:]_]*|NSURLRequest[[:alnum:]_]*|NW[A-Z][[:alnum:]_]*|CK[A-Z][[:alnum:]_]*|CFSocket[[:alnum:]_]*|CFStream[[:alnum:]_]*|CFHTTP[[:alnum:]_]*|CFNetwork[[:alnum:]_]*|WKWebView[[:alnum:]_]*|SFSafariViewController[[:alnum:]_]*|ASWebAuthenticationSession[[:alnum:]_]*|CloudKit[[:alnum:]_]*|NSPersistentCloudKitContainer[[:alnum:]_]*|Firebase[[:alnum:]_]*|FirebaseAnalytics[[:alnum:]_]*|Crashlytics[[:alnum:]_]*|GoogleAnalytics[[:alnum:]_]*|GoogleTagManager[[:alnum:]_]*|Sentry[[:alnum:]_]*|Segment[[:alnum:]_]*|Mixpanel[[:alnum:]_]*|Amplitude[[:alnum:]_]*|PostHog[[:alnum:]_]*|Datadog[[:alnum:]_]*|AppCenter[[:alnum:]_]*|AdMob[[:alnum:]_]*|AppsFlyer[[:alnum:]_]*|Adjust[[:alnum:]_]*|Braze[[:alnum:]_]*|Snowplow[[:alnum:]_]*|TelemetryDeck[[:alnum:]_]*|Bugsnag[[:alnum:]_]*|NewRelic[[:alnum:]_]*|[[:alnum:]_]*(WebSocket|Socket)[[:alnum:]_]*)([^[:alnum:]_]|$)'
  source_import_pattern='^[[:space:]]*(@[A-Za-z_][A-Za-z0-9_]*(\([^)]*\))?[[:space:]]+)*import[[:space:]]+((struct|class|enum|protocol|typealias|func|var|let)[[:space:]]+)?(Network|CloudKit|WebKit|SafariServices|CFNetwork|AuthenticationServices|Firebase[[:alnum:]_]*|[[:alnum:]_]*Analytics[[:alnum:]_]*)(\.|[^[:alnum:]_]|$)'
  lowercase_socket_pattern='(^|[^[:alnum:]_])socket[[:space:]]*\('
  source_api_pattern="$source_import_pattern|$source_identifier_pattern|$lowercase_socket_pattern"
  print_grep_matches "forbidden networking, browser, iCloud, socket, or analytics SDK symbol in Swift source" "$source_api_pattern" "${network_swift_files[@]}"

  url_pattern='https?://[^[:space:]"<>)]+|mailto:[^[:space:]"<>)]+|tel:[^[:space:]"<>)]+|sms:[^[:space:]"<>)]+|[A-Za-z][A-Za-z0-9+.-]*://[^[:space:]"<>)]+'
  swift_url_matches=$(grep -nE "$url_pattern" "${network_swift_files[@]}" 2>&1)
  swift_url_grep_status=$?
  if [[ $swift_url_grep_status -gt 1 ]]; then
    report_issue "grep failed while checking Swift URL literals"
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      printf '  %s\n' "$line" >&2
    done <<< "$swift_url_matches"
  elif [[ $swift_url_grep_status -eq 0 ]]; then
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
    done <<< "$swift_url_matches"
  fi
fi

if [[ ${#plist_files[@]} -gt 0 ]]; then
  if command -v plutil >/dev/null 2>&1; then
    for file in "${plist_files[@]}"; do
      if ! plutil -lint "$file" >/dev/null; then
        report_issue "plist lint failed for $file"
      fi
    done
  else
    printf 'apple-no-network: skipping plist format lint because plutil is not available on this platform; still scanning plist/privacy text for forbidden network keys.\n' >&2
  fi

  network_plist_files=()
  for file in "${plist_files[@]}"; do
    [[ "$file" == *CloudKit.entitlements ]] && continue
    # The one approved gated Info.plist (used only by DebugCloudKit) may declare remote notifications.
    [[ "$file" == *apps/apple/CanadianHam/Resources/CanadianHam.iOS.CloudKit.Info.plist ]] && continue
    network_plist_files+=("$file")
  done
  if [[ ${#network_plist_files[@]} -gt 0 ]]; then
    entitlement_pattern='com\.apple\.security\.network\.(client|server)|com\.apple\.developer\.(icloud|ubiquity|aps-environment)|com\.apple\.developer\.icloud|NSUbiquitous|NSPersistentCloudKitContainer|CloudKit|UIBackgroundModes|remote-notification|NSLocalNetworkUsageDescription|NSBonjourServices|NSAppTransportSecurity|NSAllowsArbitraryLoads|NSAllowsLocalNetworking|WKAppBoundDomains'
    print_grep_matches "forbidden network client/server, iCloud, local-network, or transport-security entitlement/Info key" "$entitlement_pattern" "${network_plist_files[@]}"
  fi
fi

if [[ ${#config_files[@]} -gt 0 ]]; then
  config_entitlement_pattern='com\.apple\.security\.network\.(client|server)|com\.apple\.developer\.(icloud|ubiquity|aps-environment)|CODE_SIGN_ENTITLEMENTS.*(iCloud|CloudKit)|INFOPLIST_KEY_(UIBackgroundModes|NSLocalNetworkUsageDescription|NSBonjourServices|NSAppTransportSecurity|NSAllowsArbitraryLoads|NSAllowsLocalNetworking|WKAppBoundDomains)'
  for file in "${config_files[@]}"; do
    if [[ "$file" == *.pbxproj ]]; then
      while IFS= read -r match_line; do
        [[ -n "$match_line" ]] || continue
        report_issue "forbidden network/iCloud entitlement or Info.plist key in default Apple project configuration: $match_line"
      done < <(awk -v pattern="$config_entitlement_pattern" '
        /^[[:space:]]*[A-F0-9]+ \/\* (Debug|Release|DebugCloudKit) \*\/ = \{/ {
          config = $0
          sub(/^.*\/\* /, "", config)
          sub(/ \*\/.*$/, "", config)
        }
        config != "" && $0 ~ /^[[:space:]]*name = / {
          config = ""
        }
        config != "DebugCloudKit" && $0 ~ pattern { printf "%s:%d:%s\n", FILENAME, FNR, $0 }
      ' "$file")
    else
      while IFS= read -r match_line; do
        [[ -n "$match_line" ]] || continue
        report_issue "forbidden network/iCloud entitlement or Info.plist key in default Apple project configuration: $match_line"
      done < <(awk -v pattern="$config_entitlement_pattern" '
        function indent_of(line) { match(line, /[^ ]/); return RSTART == 0 ? 0 : RSTART - 1 }
        /^[[:space:]]*DebugCloudKit:[[:space:]]*$/ { in_gate = 1; gate_indent = indent_of($0); next }
        in_gate && NF > 0 && indent_of($0) <= gate_indent { in_gate = 0 }
        !in_gate && $0 ~ pattern { printf "%s:%d:%s\n", FILENAME, FNR, $0 }
      ' "$file")
    fi
  done

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

if [[ ${#lesson_markdown_files[@]} -gt 0 ]]; then
  lesson_reference_pattern='[Hh][Tt][Tt][Pp][Ss]?://[^[:space:]"<>)]+|<[A-Za-z][A-Za-z0-9+.-]*:[^[:space:]<>]+>|<[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}>|[Ww][Ww][Ww]\.[^[:space:]"<>)]+|mailto:[^[:space:]"<>)]+|tel:[^[:space:]"<>)]+|sms:[^[:space:]"<>)]+|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
  scan_text_files_for_content_references "unexpected content link/contact in bundled lesson Markdown" "$lesson_reference_pattern" "${lesson_markdown_files[@]}"
fi

if [[ ${#explanation_json_files[@]} -gt 0 ]]; then
  explanation_url_pattern='https?://[^[:space:]"<>)]+|[A-Za-z][A-Za-z0-9+.-]*://[^[:space:]"<>)]+|www\.[^[:space:]"<>)]+|mailto:[^[:space:]"<>)]+|tel:[^[:space:]"<>)]+|sms:[^[:space:]"<>)]+'
  scan_text_files_for_content_references "unexpected URL in bundled explanation JSON" "$explanation_url_pattern" "${explanation_json_files[@]}"
fi

if [[ $issue_count -ne 0 ]]; then
  printf 'apple-no-network: failed with %d issue(s).\n' "$issue_count" >&2
  exit 1
fi

printf 'apple-no-network: passed (%d Swift files, %d plist/privacy files, %d project config files).\n' "${#swift_files[@]}" "${#plist_files[@]}" "${#config_files[@]}"
