# task-44.3 review-fix handoff

Branch: `task-44.3-apple-exam-tools`
Base at takeover: `bed24842423e2e77dca14de115f5e15ac125062e`.
Review source: `/Users/david/.cache/canadian-ham-reviews/r443-4.md`.

## Current state

Already committed before takeover:
- H1/H2 resolved by restoring the shared practice occluded-contrast helper identity and removing the broader ExamTools copy.
- M3/M4 behavior fixes, UI coverage updates, deterministic Localizable rebuild, docs cleanup, and previous iPad geometry/focus attempts.
- Current committed sidebar PNGs are still not acceptable for H3: `docs/evidence/task-44.3/sidebar-headers-before.png` shows the sidebar, but `docs/evidence/task-44.3/sidebar-headers-after.png` does not show the sidebar headers. Recapture both later; per coordinator steering, read each final sidebar PNG only once to confirm the headers are visible.

Progress in this worktree since takeover:
- Rerun2 completed. Results:
  - `iphone-exam-tools-class`: passed, 15 tests / 2 skipped / 0 failures. Log: `/tmp/task-44.3-r443-4-rerun2-20261015-192947/iphone-exam-tools-class.log`.
  - `ipad-exam-tools-class`: failed only `testCalculatorAutoFocusesHardwareKeyboardOnOpen`; all other iPad ExamTools tests passed. Log: `/tmp/task-44.3-r443-4-rerun2-20261015-192947/ipad-exam-tools-class.log`.
  - `macos-units`: passed. Log: `/tmp/task-44.3-r443-4-rerun2-20261015-192947/macos-units.log`.
  - `apple-text-sources`: passed. Log: `/tmp/task-44.3-r443-4-rerun2-20261015-192947/apple-text-sources.log`.
  - `test-guard`: failed with expected guarded findings because the PR body marker was not supplied in that chain. Log: `/tmp/task-44.3-r443-4-rerun2-20261015-192947/test-guard.log`.
- Fixed the iPad inspector hardware-keyboard autofocus path by adding an iOS regular-width UIKit key responder attached to the presenter background. Compact iPhone still uses the existing SwiftUI `onKeyPress` path; no test/audit weakening was added.
- Targeted validation after the fix:
  - iPad autofocus: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testCalculatorAutoFocusesHardwareKeyboardOnOpen -resultBundlePath /tmp/task-44.3-ipad-autofocus-parent-responder.xcresult test CODE_SIGNING_ALLOWED=NO` passed.
  - iPhone autofocus: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testCalculatorAutoFocusesHardwareKeyboardOnOpen -resultBundlePath /tmp/task-44.3-iphone-autofocus-fix.xcresult test CODE_SIGNING_ALLOWED=NO` passed.
- Reverted incidental calculator evidence PNG churn from the class screenshot runs; only source changes remain for this progress commit.

## Important constraints still in force

- Do not add deleted/skipped/weakened/filtered tests or audits beyond the approved exceptions.
- Shared helpers must stay byte-identical to `origin/main`.
- No `accessibilityHidden(true)` on visible text, no hard-coded colours, no appearance switching inside tests, and no layout-only-to-pass-tests changes.
- Edit `.xcstrings` only via a Python round-trip in main's order.
- Use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild`; never call `xcodebuild` directly and never kill other builds.
- Coordinator steering: avoid opening more images. Read each final sidebar PNG once only to confirm the sidebar headers are visible; otherwise use tail/grep for logs.

## Remaining work

1. Commit and push the current iPad autofocus fix plus this handoff update.
2. Rerun only the previously failing iPad validation at the appropriate scope. Minimum expected rerun: full iPad `CanadianHamExamToolsUITests` class on `iPad Pro 13-inch (M5)` because the previous class run failed there.
3. H3 sidebar evidence: recapture `docs/evidence/task-44.3/sidebar-headers-before.png` from `origin/main` and `docs/evidence/task-44.3/sidebar-headers-after.png` from this branch, same iPad simulator/orientation/appearance/screen, with the sidebar visible in both and headers `Study`, `Practice categories`, and `Tools` comparable. Use a temporary detached main worktree and remove it afterwards. Confirm the final two PNGs once.
4. Low 6: compare the same iPhone flow on `origin/main` vs this branch for the empty band under the back button. If absent on main, fix the regression; if present on main, record screenshots/evidence without opening unnecessary images.
5. Keep only intentional final evidence; revert incidental PNG churn.
6. Final validation still needed after remaining changes:
   - `pnpm check:apple-l10n`
   - `node scripts/check-apple-text-sources.ts`
   - `TEST_GUARD_PR_BODY=$'Test-guard-approved: owner decision 2026-10-14\n' node scripts/check-test-guard.mjs --base origin/main --head HEAD`
   - Confirm shared helpers byte-identical to `origin/main`.
7. Update Backlog task-44.3 notes/final summary/status via the backlog CLI and write `/tmp/pr-44.3-body.md` with the marker, per-test results, and merge-batch note covering all four platforms because the string catalogue changed.
