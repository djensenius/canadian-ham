#!/usr/bin/env bash
# Lints every tracked *.sh under scripts/ and apps/apple/ci_scripts/ with
# `bash -n` and `shellcheck -x`, run from the repository root so source
# directives resolve as they do locally. Fails closed when shellcheck or git is
# unavailable, no scripts are found, or any script fails either check.
# Run with: pnpm check:shell (GitHub CI runs it on ubuntu-latest).
set -euo pipefail

repo_root=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

die() {
  printf 'check-shell-scripts: %s\n' "$1" >&2
  exit 2
}

command -v shellcheck >/dev/null 2>&1 \
  || die "shellcheck is not installed (brew install shellcheck, or apt-get install shellcheck)"
shellcheck_version=$(shellcheck --version | awk '$1 == "version:" { print $2 }')
[[ -n "$shellcheck_version" ]] || die "cannot read the shellcheck version"

list_file=$(mktemp "${TMPDIR:-/tmp}/check-shell-scripts.XXXXXX") || die "cannot create a temporary file"
cleanup() {
  rm -f "$list_file"
}
trap cleanup EXIT

git ls-files -z -- 'scripts/*.sh' 'apps/apple/ci_scripts/*.sh' >"$list_file" \
  || die "git ls-files failed; run this from a git checkout"

files=()
while IFS= read -r -d '' file; do
  files+=("$file")
done <"$list_file"
[[ ${#files[@]} -gt 0 ]] || die "no tracked *.sh files found under scripts/ or apps/apple/ci_scripts/"

bash_version=$(bash -c 'printf "%s" "$BASH_VERSION"') || die "cannot run bash"
printf 'check-shell-scripts: ShellCheck %s, bash %s\n' "$shellcheck_version" "$bash_version"

failures=0
for file in "${files[@]}"; do
  file_ok=1
  if ! bash -n "$file"; then
    printf 'FAIL bash -n %s\n' "$file" >&2
    file_ok=0
  fi
  if ! shellcheck -x "$file"; then
    printf 'FAIL shellcheck -x %s\n' "$file" >&2
    file_ok=0
  fi
  if [[ $file_ok -eq 1 ]]; then
    printf 'ok   %s\n' "$file"
  else
    failures=$((failures + 1))
  fi
done

if [[ $failures -gt 0 ]]; then
  printf 'check-shell-scripts: %d of %d files failed\n' "$failures" "${#files[@]}" >&2
  exit 1
fi
printf 'check-shell-scripts: passed (%d files)\n' "${#files[@]}"
