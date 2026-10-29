# Release-day checklist

Use this checklist on the release-candidate commit. It consolidates the release gates and manual checks that remain documented in [content licensing](../content-licensing.md), [privacy](../privacy.md), [accessibility](../accessibility.md), [Apple offline smoke test](../apple-offline-smoke-test.md), [App Store privacy-label evidence](privacy-label-evidence.md), and the source/content verification steps in [content update process](../content-update-process.md).

Record the commit SHA, date, tester, and pass/fail notes for every checked item. Do not make the repository public, deploy the web app publicly, submit to external TestFlight/App Store, or otherwise distribute artifacts until every blocking gate below is satisfied. The existing TASK-1.10 exception permits only internal App Store Connect team-member TestFlight after review/merge approval, following the [TestFlight runbook](testflight.md); it does not permit external groups or public links.

## Gates

- [ ] Confirm the repository is still private before release work starts; public exposure remains blocked by [`docs/content-licensing.md` public-release gate](../content-licensing.md#public-release-gate).
- [ ] Complete `task-1.1`: record the ISED written permission reference number, date, and exact scope in [`docs/content-licensing.md`](../content-licensing.md), including explicit permission to bundle verbatim EN/FR question text as web and Apple app data.
- [ ] Confirm the permission scope covers every release artifact: generated question JSON, bundled Apple resources, web static assets/PWA cache, and any release notes or About text that mention ISED material.
- [ ] Complete `task-1.2`: update [`docs/release/privacy-label-evidence.md`](privacy-label-evidence.md) with fresh release-commit evidence and check its release-commit follow-up commands.
- [ ] Complete `task-1.3`: add static web deploy/CSP/host-log documentation in [`docs/release/web-deploy.md`](web-deploy.md) and the post-deploy offline smoke test in [`docs/release/web-offline-smoke-test.md`](web-offline-smoke-test.md).
- [ ] Complete `task-1.4`: replace all draft/pending About-page attribution with the exact wording approved by the recorded ISED permission, and resolve or document legal-review/French-translation status.
- [ ] Complete `task-1.5`: keep this consolidated checklist current with the release evidence.
- [ ] Complete `task-1.6`: run the release-candidate pass on one commit and record CI, Apple `xbuild`, consolidated checklist, and accepted-failure evidence.
- [ ] Confirm `task-1.7` remains blocked until `task-1.1` and `task-1.6` are Done and the owner explicitly approves making the repository public.
- [ ] Complete `task-29`: run and record the tvOS VoiceOver About-card checks in [`docs/accessibility.md`](../accessibility.md), including English-language reading of English legal text in the French UI.

## Content

- [ ] Follow the [`docs/content-licensing.md` release checklist](../content-licensing.md#release-checklist): permission reference/date/scope recorded, reference PDFs absent from artifacts, attribution and disclaimer present, source URLs/checksums recorded, ISED text traceable, original lessons/explanations separate, no RAC/Coax text copied, French question text from ISED, and open licensing questions resolved or blocking.
- [ ] Verify the active Basic 2025 source artifacts against the committed checksum file: `cd content/sources/ised/basic-2025-07-15 && shasum -a 256 -c SHA256SUMS`; confirm `questions/amat_basic_quest_delim.txt` is `34c7cd7967addfde648c566d0ecf25bf3d1e071c603b5101cfecc7bd0cbc284f`.
- [ ] Run `pnpm import:check` to verify the generated active bank still matches the official source import.
- [ ] Run `pnpm check:schemas` to validate shared schema expectations.
- [ ] Run `pnpm --filter @canadian-ham/content-tools check:explanations`.
- [ ] Run `pnpm --filter @canadian-ham/content-tools check:quizzes`.
- [ ] Run `pnpm --filter @canadian-ham/content-tools check:coverage` (the `check-lesson-coverage.ts` checker).
- [ ] Run `pnpm --filter @canadian-ham/content-tools check:lesson-originality:all` (the `check-lesson-originality --all` checker).
- [ ] If the release includes a bank update, follow [`docs/content-update-process.md`](../content-update-process.md) and run `pnpm --silent diff:banks -- content/generated/basic-2025-07-15 content/generated/<new-bank-id> > /tmp/basic-bank-diff.md` plus the JSON parse check described there; if there is no bank update, record this item as not applicable with the active bank ID.
- [ ] Confirm generated data and app-visible bank version are from the same active bank before building web or Apple artifacts.
- [ ] Run the repository-wide checks on the release commit: `pnpm typecheck`, `pnpm test` (includes `pnpm --filter @canadian-ham/content-tools test`), and `pnpm check:links`.

## Privacy

- [ ] Follow [`docs/privacy.md` verification checklist](../privacy.md#verification-checklist): dependency review, network/telemetry source search, Apple entitlement review, third-party SDK review, Apple build/test, Apple airplane-mode runtime checks, static web build, browser developer-tools request review, offline web runtime check, and App Store privacy-answer confirmation.
- [ ] Run `pnpm check:apple-network` and record the output in [`docs/release/privacy-label-evidence.md`](privacy-label-evidence.md).
- [ ] Run `pnpm test:apple-network` and record the output in [`docs/release/privacy-label-evidence.md`](privacy-label-evidence.md).
- [ ] Run `pnpm build:web` for the release commit.
- [ ] Run `pnpm --filter @canadian-ham/web audit:urls` against the release build output and record whether only allowed same-origin/static URLs are present.
- [ ] Confirm the web privacy summary and Apple privacy label evidence still match [`docs/privacy.md`](../privacy.md): no accounts, analytics, telemetry, ads, tracking, server-side progress storage, iCloud sync, push notifications, automatic diagnostics upload, third-party SDK collection, or Apple-app networking.
- [ ] Confirm App Store Connect privacy answers are still **Data Not Collected** using [`docs/release/privacy-label-evidence.md`](privacy-label-evidence.md); if Apple wording or required-reason API requirements changed, update the evidence before submission.
- [ ] Resolve the **OPEN** required-reason API applicability, approved-reason and target-coverage review in the [2026-10-28 inventory](privacy-label-evidence.md#current-preference-and-manifest-inventory-2026-10-28). Reconcile current preference API use with each shipped target's manifest on the release commit; no-network checks and **Data Not Collected** answers do not establish required-reason compliance.

## Accessibility

- [ ] Follow the [`docs/accessibility.md` manual release checklist](../accessibility.md#manual-release-checklist): keyboard-only web, macOS Full Keyboard Access, VoiceOver iOS/iPadOS/macOS, mock-exam results VoiceOver, tvOS focus, visionOS readability, 200% zoom/320 px reflow, largest Dynamic Type, Reduced Motion, colour independence, and privacy/network regression review.
- [ ] Run the automated accessibility suites on the release candidate: `pnpm --filter @canadian-ham/web test` (axe coverage) and the iOS, macOS, tvOS, visionOS and watchOS test commands in [`AGENTS.md`](../../AGENTS.md#apple-builds) (through `xbuild` only; the iOS, tvOS, visionOS and watchOS UI suites include the accessibility audits).
- [ ] Run the separate **`CanadianHamLessonFigures`** plan on the same release-candidate commit, **only** via `scripts/run-figure-plan-quiet.sh` from the repository root. `CanadianHamDefault` excludes `CanadianHamLessonFiguresUITests` and `CanadianHamPracticeUITests.testOhmsLawLessonFiguresAndAccessibilityLight` / `testOhmsLawLessonFiguresAndAccessibilityDark`; a default-plan pass does not cover them. Run the full figure plan for the RC, without narrowing selections. The coordinator must start **no other Apple lanes during either the quiet-host wait or the run**; finish existing lanes before starting the runner. Retain its command, `figures.xcresult`, `xbuild.log`, `load.log`, `summary.txt` and exit status; review maximum load for contention from other projects that bypass `xbuild`. A wait timeout or missing run is not a pass.
- [ ] Run the separate **`CanadianHamTitleSweeps`** plan on the same release-candidate commit: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -testPlan CanadianHamTitleSweeps -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test CODE_SIGNING_ALLOWED=NO`. This covers all four excluded `CanadianHamPracticeUITests.testCategoryTitles…` sweeps: English/French at default/largest accessibility sizes. Schedule it outside the figure runner's wait/run; a default-plan pass does not cover it.
- [ ] Archive **per-test** results for every Apple platform suite and both separate plans in the task notes and RC evidence/PR body: test identifier, pass/fail/skip and failure details, command/plan, commit, device/runtime, and result-bundle/log location. Reconcile results against the selected tests (including every figure-class method, both Ohm's law audits and all four title sweeps), not just an overall success line. Record skipped platforms/tests and why, plus any explicitly approved accepted failures; a rehearsal, simulator-only result or unapproved skip does not close the manual/device, ISED or RC release gates.
- [ ] Complete and record `task-29` tvOS VoiceOver checks in [`docs/accessibility.md`](../accessibility.md): each focusable About card title/body reads correctly and English legal text in the French UI is spoken with an English voice.
- [ ] Confirm no UI change introduced remote fonts, remote assets, telemetry, analytics, or third-party runtime SDKs while satisfying accessibility requirements.

## Offline Apple

- [ ] Run the platform `xbuild` commands from [`AGENTS.md`](../../AGENTS.md) for iOS, macOS, tvOS, visionOS and watchOS on the release-candidate commit; never call `xcodebuild` directly.
- [ ] Run [`docs/apple-offline-smoke-test.md`](../apple-offline-smoke-test.md) after the relevant `xbuild` command and after `pnpm check:apple-network` passes.
- [ ] For each Apple platform under test (iPhone, iPad, Mac, Apple TV, Apple Vision Pro), record device/runtime, build commit, network-off method, launch baseline, practice, mock exam, Learn, lesson quiz, export/import, reset, and any unexpected prompts or missing features.
- [ ] On macOS, manually verify the native Settings Data tab can export progress to a user-selected file and import it back while running under the app sandbox.
- [ ] Confirm bundled question-bank, lessons, quizzes, explanations, progress screens, export/import, and reset work without network access; approved platform-specific gaps must be tracked before release.
- [ ] Confirm no prompts appear for network access, local-network discovery, push notifications, analytics consent, account login, or iCloud sync.

## Offline web

- [ ] Complete `task-1.3` before public deployment, including [`docs/release/web-deploy.md`](web-deploy.md) and [`docs/release/web-offline-smoke-test.md`](web-offline-smoke-test.md).
- [ ] Before deployment, confirm `task-1.1` permission is recorded and [`docs/content-licensing.md` public-release gate](../content-licensing.md#public-release-gate) is satisfied; `task-1.3` AC #4 forbids deployment before then.
- [ ] Follow [`docs/release/web-deploy.md`](web-deploy.md) from `task-1.3` to verify static hosting configuration, CSP that blocks third-party origins, and host log-retention documentation.
- [ ] Follow [`docs/release/web-offline-smoke-test.md`](web-offline-smoke-test.md) from `task-1.3` after deployment: load the app, install/open PWA if applicable, go offline, practise, complete a mock exam, export/import progress, reset, and confirm no third-party requests.
- [ ] Record deployment URL, commit SHA, CSP evidence, host log-retention setting, browser/devtools request evidence, service-worker/cache readiness, and smoke-test pass/fail notes.

## Store submission

- [ ] Do not submit to TestFlight external testing or App Store until [`docs/content-licensing.md` public-release gate](../content-licensing.md#public-release-gate), `task-1.1`, `task-1.2`, `task-1.4`, and `task-1.6` are complete.
- [ ] Use [`docs/release/privacy-label-evidence.md`](privacy-label-evidence.md) to fill App Store Connect privacy answers and confirm **Data Not Collected** is still accurate on the release commit.
- [ ] Confirm Apple application targets include `PrivacyInfo.xcprivacy` (shared by the original targets; watch-specific for `CanadianHamWatch`) and no target links third-party runtime SDKs, using the `plutil -p` and `git grep` checks in [`docs/release/privacy-label-evidence.md`](privacy-label-evidence.md).
- [ ] Confirm app metadata, screenshots, About/settings text, release notes, attribution, and disclaimer match the recorded ISED permission scope and do not claim affiliation, sponsorship, or endorsement.
- [ ] Archive the completed Apple offline smoke-test notes and `xbuild` command results with the release evidence before submission.

## Public repo

- [ ] Do not make `djensenius/canadian-ham` public until `task-1.7` is approved and all dependencies are Done.
- [ ] Re-run the [`docs/content-licensing.md` public-release gate](../content-licensing.md#public-release-gate): verify repository history and release artifacts contain no ISED material outside the recorded permission scope.
- [ ] Confirm no reference PDFs are shipped in web or Apple app artifacts, and no out-of-scope official source artifacts are included in public release history unless the recorded permission allows them.
- [ ] Confirm the owner has approved public visibility after reviewing the release-candidate evidence from `task-1.6`.
- [ ] If permission is refused or narrower than needed, follow the contingency in [`docs/content-licensing.md`](../content-licensing.md#public-release-gate) instead of making this repository public.

## Official reference sheet build gate (TASK-44.4)

- [ ] Written ISED permission explicitly covers the sheet before public distribution; the gate in [content licensing](../content-licensing.md#public-release-gate) still applies even with the fallback.
- [ ] Public Apple Release build has no `OFFICIAL_REFERENCE_SHEET` compilation condition / `-DOFFICIAL_REFERENCE_SHEET` flag and no `official-basic-exam/` in its resources. Internal fastlane `beta` lanes opt in under decision 2A; do **not** reuse that override in a public/App Store lane.
- [ ] Public web build runs `pnpm build:web` without `OFFICIAL_REFERENCE_SHEET=YES` and passes its automatic output exclusion check: every file is compared with the official page/transcript SHA-256 values in `content/reference/official-basic-exam/README.md`, including renamed assets and decoded base64 image data URLs. Filename and distinctive transcript-text checks also apply. Inspect the service-worker precache for official-sheet references; the original study sheet remains available. See the [gate limitations](../content-licensing.md#official-sheet-implementation-gate-task-444) for re-encoded images and obfuscated/assembled data URLs.
- [ ] `pnpm test:official-reference-sheet` passes, including renamed/inline web leak fixtures, clean original-study-sheet output, and stale-resource removal on an off Apple build. See [internal TestFlight](testflight.md) for the internal-only exception.

## Independent watch payload (TASK-14.6)

Internal team-member TestFlight is the only approved delivery exception before
TASK-1.7; this checklist does not authorize an upload, external group, public link
or App Store submission. See the [watch beta/install runbook](testflight.md#watchos-beta-entry-path-and-installation)
and [TASK-14.6 evidence](../testing/task-14.6-watch-release.md). Record processed
build/commit/device/tester and failures, not just checkmarks.

- [ ] After review/merge approval, archive/export via **`fastlane ios beta`**
  through xbuild and the dedicated build keychain, never a separate watch ASC
  platform or login keychain. Use `export_only:true` for inspection without upload;
  never wrap fastlane in `lockf`. Verify `testFlightInternalTestingOnly` remains on.
- [ ] Inspect `Payload/CanadianHam.app/Watch/CanadianHamWatch.app`: child bundle ID
  `org.davidjensenius.CanadianHam.watchkitapp`, companion ID matching the iOS
  container, independent-operation flag, matching timestamp `CFBundleVersion` and
  marketing version, valid distribution signatures/profiles, and AppIcon in
  `Assets.car` without missing-icon/actool warnings. Review circular small sizes.
- [ ] Confirm the watch privacy manifest declares no collection/tracking and App
  Privacy remains **Data Not Collected**. Inspect signed entitlements/frameworks
  for no iCloud/push/aps-environment/App Groups, WatchConnectivity, network or
  telemetry SDKs; run network/iCloud guards and their fixtures.
- [ ] Compare bundled watch study resources against the full Basic bank plus 984
  explanations; no lessons, quizzes, hints, Advanced, figures or official exam
  reference sheet (even in an opted-in internal iOS beta). The watch alphabet
  reference is local app content, not the official sheet. macOS export has no
  embedded watch payload.
- [ ] Run the full `CanadianHamWatch` scheme on Series 12 42mm/watchOS 27 via the
  [runbook command](testflight.md#watchos-beta-entry-path-and-installation), record
  per-test results and full EN/FR accessibility audits; retain smallest-watch
  evidence and manual listening gates from TASK-14.5.
- [ ] Record the approved **processed internal** iOS/watch TestFlight build and
  physical install from TestFlight on iPhone or Watch → Available Apps. With the
  phone app not running and phone out of range, disable watch radios/enable
  Airplane Mode and verify practice, Morse, alphabet reference and EN/FR. No
  account/network/pairing-in-app prompt is allowed.
- [ ] Complete the [owner physical-watch checklist](testflight.md#owner-physical-watch-checklist-required-not-replaced-by-simulator-tests):
  long French text/large text/VoiceOver and English fallback, live language and
  relaunch reset, memory/first-touch/launch feel (resident decoded bank; failed
  loads cache until relaunch), output cancellation and all three TASK-14.3 haptic
  styles at 1/1.5/2 WPM, including touch-only recognition and Silent Mode sounds.
  Simulator passes cannot establish tactile fidelity or heard VoiceOver. Keep
  TASK-14.6 AC4, TASK-14.3 AC2 and TASK-14.5's owner gate unchecked until recorded.
