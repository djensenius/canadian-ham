#!/usr/bin/env bash
set -euo pipefail

# T-207 note: one command for checking that both engines satisfy fixtures/engine.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$repo_root"
node --test packages/engine-ts/test/

cd "$repo_root/packages/engine-swift"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamEngine -destination 'platform=macOS' test
