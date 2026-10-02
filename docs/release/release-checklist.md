# Release-day checklist

Use this checklist on the release-candidate commit. It consolidates the release gates and manual checks that remain documented in [content licensing](../content-licensing.md), [privacy](../privacy.md), [accessibility](../accessibility.md), [Apple offline smoke test](../apple-offline-smoke-test.md), [App Store privacy-label evidence](privacy-label-evidence.md), and the source/content verification steps in [content update process](../content-update-process.md).

Record the commit SHA, date, tester, and pass/fail notes for every checked item. Do not make the repository public, deploy the web app publicly, submit to TestFlight/App Store, or otherwise distribute artifacts until every blocking gate below is satisfied.

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

## Accessibility

- [ ] Follow the [`docs/accessibility.md` manual release checklist](../accessibility.md#manual-release-checklist): keyboard-only web, macOS Full Keyboard Access, VoiceOver iOS/iPadOS/macOS, mock-exam results VoiceOver, tvOS focus, visionOS readability, 200% zoom/320 px reflow, largest Dynamic Type, Reduced Motion, colour independence, and privacy/network regression review.
- [ ] Run the automated accessibility suites on the release candidate: `pnpm --filter @canadian-ham/web test` (axe coverage) and the iOS, macOS, tvOS and visionOS test commands in [`AGENTS.md`](../../AGENTS.md#apple-builds) (through `xbuild` only; the iOS, tvOS and visionOS UI suites include the accessibility audits).
- [ ] Complete and record `task-29` tvOS VoiceOver checks in [`docs/accessibility.md`](../accessibility.md): each focusable About card title/body reads correctly and English legal text in the French UI is spoken with an English voice.
- [ ] Confirm no UI change introduced remote fonts, remote assets, telemetry, analytics, or third-party runtime SDKs while satisfying accessibility requirements.

## Offline Apple

- [ ] Run the platform `xbuild` commands from [`AGENTS.md`](../../AGENTS.md) for iOS, macOS, tvOS, and visionOS on the release-candidate commit; never call `xcodebuild` directly.
- [ ] Run [`docs/apple-offline-smoke-test.md`](../apple-offline-smoke-test.md) after the relevant `xbuild` command and after `pnpm check:apple-network` passes.
- [ ] For each Apple platform under test (iPhone, iPad, Mac, Apple TV, Apple Vision Pro), record device/runtime, build commit, network-off method, launch baseline, practice, mock exam, Learn, lesson quiz, export/import, reset, and any unexpected prompts or missing features.
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
- [ ] Confirm Apple application targets include the shared `PrivacyInfo.xcprivacy` and no target links third-party runtime SDKs, using the `plutil -p` and `git grep` checks in [`docs/release/privacy-label-evidence.md`](privacy-label-evidence.md).
- [ ] Confirm app metadata, screenshots, About/settings text, release notes, attribution, and disclaimer match the recorded ISED permission scope and do not claim affiliation, sponsorship, or endorsement.
- [ ] Archive the completed Apple offline smoke-test notes and `xbuild` command results with the release evidence before submission.

## Public repo

- [ ] Do not make `djensenius/canadian-ham` public until `task-1.7` is approved and all dependencies are Done.
- [ ] Re-run the [`docs/content-licensing.md` public-release gate](../content-licensing.md#public-release-gate): verify repository history and release artifacts contain no ISED material outside the recorded permission scope.
- [ ] Confirm no reference PDFs are shipped in web or Apple app artifacts, and no out-of-scope official source artifacts are included in public release history unless the recorded permission allows them.
- [ ] Confirm the owner has approved public visibility after reviewing the release-candidate evidence from `task-1.6`.
- [ ] If permission is refused or narrower than needed, follow the contingency in [`docs/content-licensing.md`](../content-licensing.md#public-release-gate) instead of making this repository public.
