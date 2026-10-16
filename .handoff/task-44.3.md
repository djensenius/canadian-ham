# task-44.3 review-fix handoff

Branch: `task-44.3-apple-exam-tools`
Current HEAD: `b216df053ca76172cd3093e9c2f94b86c27301eb` (`docs: update task 44.3 handoff`). Pushed to `origin/task-44.3-apple-exam-tools`.
Review source: `/Users/david/.cache/canadian-ham-reviews/r443-4.md`.

## Current state

Committed before this handoff:
- H1/H2 resolved by restoring the shared practice occluded-contrast helper identity and removing the broader ExamTools copy.
- M3/M4 behavior fixes, UI coverage updates, deterministic Localizable rebuild, docs cleanup, and previous iPad geometry/focus attempts.
- `9cf849a61b8983a2b48ecf9087d4141933024600` fixed iPad inspector hardware-keyboard autofocus with an iOS regular-width UIKit key responder on the presenter background. Compact iPhone keeps the existing SwiftUI `onKeyPress` path. No test/audit weakening was added.
- `b216df053ca76172cd3093e9c2f94b86c27301eb` updated this handoff after the autofocus fix.

Validation completed since takeover:
- Rerun2 completed:
  - `iphone-exam-tools-class`: passed, 15 tests / 2 skipped / 0 failures. Log: `/tmp/task-44.3-r443-4-rerun2-20261015-192947/iphone-exam-tools-class.log`.
  - `ipad-exam-tools-class`: failed only `testCalculatorAutoFocusesHardwareKeyboardOnOpen`; all other iPad ExamTools tests passed. Log: `/tmp/task-44.3-r443-4-rerun2-20261015-192947/ipad-exam-tools-class.log`.
  - `macos-units`: passed. Log: `/tmp/task-44.3-r443-4-rerun2-20261015-192947/macos-units.log`.
  - `apple-text-sources`: passed. Log: `/tmp/task-44.3-r443-4-rerun2-20261015-192947/apple-text-sources.log`.
  - `test-guard`: failed with expected guarded findings because the PR body marker was not supplied in that chain. Log: `/tmp/task-44.3-r443-4-rerun2-20261015-192947/test-guard.log`.
- Targeted autofocus validation after the fix:
  - iPad autofocus passed: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testCalculatorAutoFocusesHardwareKeyboardOnOpen -resultBundlePath /tmp/task-44.3-ipad-autofocus-parent-responder.xcresult test CODE_SIGNING_ALLOWED=NO`.
  - iPhone autofocus passed: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testCalculatorAutoFocusesHardwareKeyboardOnOpen -resultBundlePath /tmp/task-44.3-iphone-autofocus-fix.xcresult test CODE_SIGNING_ALLOWED=NO`.
- Full iPad class validation after the fix passed: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests -resultBundlePath /tmp/task-44.3-ipad-exam-tools-after-key-fix.xcresult test CODE_SIGNING_ALLOWED=NO`, 15 tests / 2 skipped / 0 failures. Log: `/tmp/task-44.3-ipad-exam-tools-after-key-fix.log`.

## Build lock / queued work

- The Apple build lock is currently held by the merge-batch iOS full suite, not this worker:
  - `xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -resultBundlePath /tmp/train1015-ios.xcresult test CODE_SIGNING_ALLOWED=NO`
  - Observed PIDs at handoff: `93816`, `93824`, `95434`.
  - Log observed via tail only: `/tmp/train1015-ios.log`.
- No task-44.3 nohup chain is intentionally left queued by this worker.
- `pnpm check:apple-l10n` was attempted while the merge-batch suite held the lock. It passed the text-source gate prechecks, then timed out waiting for `xbuild`; rerun it once the lock is free.
- A temporary `origin/main` sidebar worktree created for a capture attempt timed out while waiting for the lock and was removed. The committed evidence PNGs were restored afterward.

## Evidence screenshot state

- H3 is still open. The committed `docs/evidence/task-44.3/sidebar-headers-before.png` and `docs/evidence/task-44.3/sidebar-headers-after.png` are not accepted as the final comparison: the before image shows the sidebar, while the after image does not show the sidebar headers. Recapture both on the same iPad simulator/orientation/appearance/screen with the sidebar visible in both.
- I experimented with a temporary UI-test capture on the branch and verified via accessibility frames (without opening images) that `Study`, `Practice categories`, and `Tools` can all be present in a forced-regular iPad capture at extra-small content size. That temporary test code and generated PNG were reverted; nothing from that experiment is committed.
- Per coordinator steering: avoid opening images. Read each final sidebar PNG once only to confirm the sidebar headers are visible; otherwise use tail/grep for logs.

## Important constraints still in force

- Do not add deleted/skipped/weakened/filtered tests or audits beyond the approved exceptions.
- Shared helpers must stay byte-identical to `origin/main`.
- No `accessibilityHidden(true)` on visible text, no hard-coded colours, no appearance switching inside tests, and no layout-only-to-pass-tests changes.
- Edit `.xcstrings` only via a Python round-trip in main's order.
- Use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild`; never call `xcodebuild` directly and never kill other builds.

## Remaining work

1. Wait for the merge-batch full suites to release the build lock. Do not poll aggressively; use tail/grep only if needed.
2. H3 sidebar evidence: recapture `docs/evidence/task-44.3/sidebar-headers-before.png` from `origin/main` and `docs/evidence/task-44.3/sidebar-headers-after.png` from this branch, same iPad simulator/orientation/appearance/screen, with the sidebar visible in both and headers `Study`, `Practice categories`, and `Tools` comparable. Use a temporary detached main worktree and remove it afterwards. Confirm the final two PNGs once.
3. Low 6: compare the same iPhone flow on `origin/main` vs this branch for the empty band under the back button. If absent on main, fix the regression; if present on main, record screenshots/evidence without opening unnecessary images.
4. Keep only intentional final evidence; revert incidental PNG churn.
5. Final validation still needed after remaining changes:
   - `pnpm check:apple-l10n`
   - `node scripts/check-apple-text-sources.ts`
   - `TEST_GUARD_PR_BODY=$'Test-guard-approved: owner decision 2026-10-14\n' node scripts/check-test-guard.mjs --base origin/main --head HEAD`
   - Confirm shared helpers byte-identical to `origin/main`.
6. Update Backlog task-44.3 notes/final summary/status via the backlog CLI and write `/tmp/pr-44.3-body.md` with the marker, per-test results, and merge-batch note covering all four platforms because the string catalogue changed.
