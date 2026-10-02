# App Store privacy label and web privacy evidence

Prepared for Backlog `task-1.2` on 2026-10-02 UTC, before the release commit and before the ISED permission dependency is complete. This is a pre-release evidence snapshot; re-run the checks on the release commit before checking AC #3.

## Scope

- Apple application targets under `apps/apple`: `CanadianHam` (iOS/iPadOS/macOS), `CanadianHamTV`, and `CanadianHamVision`.
- Web privacy summary shown in `apps/web` Settings.
- Evidence sources required by `task-1.2`: `apps/apple/CanadianHam/Resources/PrivacyInfo.xcprivacy`, `pnpm check:apple-network`, `pnpm test:apple-network`, `pnpm build:web`, `pnpm --filter @canadian-ham/web audit:urls`, and [`docs/privacy.md`](../privacy.md).

Test bundles are not App Store-distributed application targets. The privacy manifest membership evidence below is therefore for the three App Store-delivered application targets.

## Apple wording sources and wording status

No web access was used while preparing this document. Exact App Store Connect screen wording must be confirmed during the release upload flow. The only Apple App Privacy wording quoted here is wording already recorded in [`docs/proposals/icloud-sync.md`](../proposals/icloud-sync.md):

- App Privacy Details on the App Store: <https://developer.apple.com/app-store/app-privacy-details/>
  - > “Collect” refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time.
  - > “Third-party partners” refers to analytics tools, advertising networks, third-party SDKs, or other external vendors whose code you’ve added to your app.
  - > You use Apple frameworks or services, such as MapKit, CloudKit, or App Analytics. If you collect data about your app from Apple frameworks or services, you should indicate what data you collect and how you use it. You are not responsible for disclosing data collected by Apple.
- Privacy manifests / required reason APIs documentation URLs to confirm during release:
  - <https://developer.apple.com/documentation/bundleresources/privacy_manifest_files>
  - <https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api>

## Snapshot and command evidence

Commands were run from the repository root at Git commit `788b49f95f8387525da42bacb4b7c81d2cbb4331` with a clean working tree. Final release validation must be re-run on the release commit.

| Evidence | Result |
|---|---|
| `plutil -p apps/apple/CanadianHam/Resources/PrivacyInfo.xcprivacy` | Parsed successfully. `NSPrivacyTracking => false`; `NSPrivacyTrackingDomains => []`; `NSPrivacyCollectedDataTypes => []`; `NSPrivacyAccessedAPITypes => []`. |
| `git grep -n "PrivacyInfo.xcprivacy" apps/apple/project.yml apps/apple/CanadianHam.xcodeproj/project.pbxproj` | Generated project contains three `PrivacyInfo.xcprivacy in Resources` build files. `project.yml` explicitly adds the file to `CanadianHamTV` and `CanadianHamVision`; the generated project also adds it to `CanadianHam` through the `CanadianHam` source tree. |
| `pnpm check:apple-network` | Passed. Output: `apple-no-network: passed (41 Swift files, 2 plist/privacy files, 2 project config files).` |
| `pnpm test:apple-network` | Passed. Output: `apple-no-network-test: passed self-test fixtures.` |
| `pnpm --filter @canadian-ham/web test` | Passed as supporting evidence for the web copy change. Output: `Test Files 10 passed (10); Tests 81 passed (81)`. jsdom printed expected `HTMLCanvasElement.getContext()` not-implemented warnings. |
| `pnpm build:web` | Passed. Vite built `apps/web/dist` successfully; emitted a non-fatal chunk-size warning for large bundles. |
| `pnpm --filter @canadian-ham/web audit:urls` | Passed. Output: `dist URL audit passed.` |

## Privacy manifest and target membership

`apps/apple/CanadianHam/Resources/PrivacyInfo.xcprivacy` currently says the app does not track, declares no tracking domains, declares no collected data types, and declares no accessed required-reason API types:

```text
NSPrivacyTracking = false
NSPrivacyTrackingDomains = []
NSPrivacyCollectedDataTypes = []
NSPrivacyAccessedAPITypes = []
```

Application target membership evidence:

| Application target | Evidence |
|---|---|
| `CanadianHam` | `apps/apple/project.yml` includes the `CanadianHam` source tree for the app target, excluding only `Resources/Assets.xcassets`; the generated Xcode project maps target `CanadianHam` to resources build phase `70820DEF5BA3FD3C91F0105E`, which includes `DA8494DE030F9968C7D5505E /* PrivacyInfo.xcprivacy in Resources */`. |
| `CanadianHamTV` | `apps/apple/project.yml` lines around the `CanadianHamTV` target explicitly include `CanadianHam/Resources/PrivacyInfo.xcprivacy` as a resources file; the generated Xcode project maps target `CanadianHamTV` to resources build phase `970FB2C9E711726AD828A219`, which includes `7A69A327192A249A5B2FF3AD /* PrivacyInfo.xcprivacy in Resources */`. |
| `CanadianHamVision` | `apps/apple/project.yml` lines around the `CanadianHamVision` target explicitly include `CanadianHam/Resources/PrivacyInfo.xcprivacy` as a resources file; the generated Xcode project maps target `CanadianHamVision` to resources build phase `43D39217D2081D1C20A0889C`, which includes `71824E1D425D494043EA0781 /* PrivacyInfo.xcprivacy in Resources */`. |

## App Store Connect App Privacy answers

The wording in this table is a working checklist of the current App Store Connect App Privacy areas. Confirm exact prompt text in App Store Connect on the release commit.

### Data collection gate and data type questions

Recommended answer: **Data Not Collected**.

Supporting rationale from [`docs/privacy.md`](../privacy.md): the Apple app has no accounts, no telemetry, no advertising, no third-party tracking, no automatic crash or diagnostic upload, no remote progress sync, no iCloud sync in v1, no networking code, and no third-party SDKs. Local study progress remains in local app storage unless the user explicitly exports it.

| App Privacy data category / type | Answer | Supporting evidence |
|---|---|---|
| Contact Info: name, email address, phone number, physical address, other user contact info | Not collected | `docs/privacy.md` says no accounts and no transmitted progress; `NSPrivacyCollectedDataTypes` is empty; `pnpm check:apple-network` passed. |
| Health and Fitness: health, fitness | Not collected | The app is an amateur-radio study app; `docs/privacy.md` allowed local data is limited to study progress, mock exam attempts, practice history, preferences, and user-initiated import/export JSON; `NSPrivacyCollectedDataTypes` is empty. |
| Financial Info: payment info, credit info, other financial info | Not collected | No payments, purchases, subscriptions, or account flows are implemented; `NSPrivacyCollectedDataTypes` is empty. |
| Location: precise location, coarse location | Not collected | No location capability or network-dependent capability is documented or detected; `pnpm check:apple-network` passed. |
| Sensitive Info | Not collected | No sensitive-information feature exists; `docs/privacy.md` permits only local study progress/preferences and user-initiated JSON import/export. |
| Contacts | Not collected | No contacts capability is documented or detected; `NSPrivacyCollectedDataTypes` is empty. |
| User Content: emails or text messages, photos or videos, audio data, gameplay content, customer support, other user content | Not collected | The app has no account/customer-support upload flow and no media/user-content upload flow; user-initiated progress export remains a local JSON file unless the user takes it elsewhere outside the app. |
| Browsing History | Not collected | The Apple app has no browser or web view and makes no network requests; `pnpm check:apple-network` scans for browser/network symbols and passed. Its only external URL is the RBR-4 citation link on the shared answer-explanation panel (`ExplanationPanelView` in `apps/apple/CanadianHam/Views/LearnViews.swift`, shown after answering in lesson quizzes, practice sessions and review, and mock-exam review via `PracticeFeedback`), which opens in the system browser only when tapped; the app itself sends nothing and records nothing about the tap. |
| Search History | Not collected | No server-side search exists; app content is bundled and offline; `NSPrivacyCollectedDataTypes` is empty. |
| Identifiers: user ID, device ID | Not collected | No accounts, analytics, ads, tracking, third-party SDKs, or networking code; `NSPrivacyCollectedDataTypes` is empty and `pnpm check:apple-network` passed. |
| Purchases: purchase history | Not collected | No purchase or subscription feature exists; `NSPrivacyCollectedDataTypes` is empty. |
| Usage Data: product interaction, advertising data, other usage data | Not collected | Local study progress is not transmitted; docs disallow analytics, telemetry, advertising identifiers, and remote progress sync; `pnpm check:apple-network` passed. |
| Diagnostics: crash data, performance data, other diagnostic data | Not collected | `docs/privacy.md` disallows automatic crash or diagnostic upload; no crash-reporting SDK is present; `pnpm check:apple-network` passed. |
| Body: hands, head (visionOS) | Not collected | The visionOS target uses no ARKit, hand-tracking or head-tracking APIs and declares no such data in `PrivacyInfo.xcprivacy`; confirm this category list in App Store Connect at submission. |
| Surroundings: environment scanning (visionOS) | Not collected | No ARKit scene reconstruction, world sensing or environment-scanning code exists in any target; confirm this category list in App Store Connect at submission. |
| Other Data | Not collected | No other collected data is declared; `NSPrivacyCollectedDataTypes` is empty. |

Because the answer is **Data Not Collected**, no App Store privacy label purposes are selected for analytics, advertising, third-party advertising, developer advertising or marketing, product personalization, app functionality, or other purposes. Confirm the exact follow-up flow in App Store Connect before release.

### Tracking

| App Store Connect area | Answer | Supporting evidence |
|---|---|---|
| Tracking / data used to track users across apps and websites owned by other companies | No tracking | `NSPrivacyTracking = false`; `NSPrivacyTrackingDomains = []`; `docs/privacy.md` says no third-party tracking, no advertising, no analytics, and no third-party SDK collection; `pnpm check:apple-network` passed. |

### Third-party SDKs and partners

| App Store Connect area | Answer | Supporting evidence |
|---|---|---|
| Third-party SDKs or partner code in the Apple app | No third-party runtime SDK collection; no remote third-party SDKs linked | `docs/privacy.md` forbids third-party SDKs in v1. `pnpm check:apple-network` passed and checks for remote Swift package references in `apps/apple/project.yml`, the generated Xcode project, Swift package manifests, and `Package.resolved`. Current Apple dependencies in `apps/apple/project.yml` are local packages `../../packages/engine-swift` and `../../packages/content-swift`. |
| Apple frameworks/services collection | None by this app | `docs/privacy.md` forbids iCloud sync and network-dependent entitlements in v1. The quoted Apple wording from `docs/proposals/icloud-sync.md` says app developers disclose data they collect from Apple frameworks/services; this app currently collects none. |

### Privacy manifest and required-reason APIs

| Area | Answer | Supporting evidence |
|---|---|---|
| Privacy manifest included | Yes, one shared manifest is bundled in each App Store-delivered application target | `PrivacyInfo.xcprivacy` exists at `apps/apple/CanadianHam/Resources/PrivacyInfo.xcprivacy`; target membership is documented above for `CanadianHam`, `CanadianHamTV`, and `CanadianHamVision`. |
| Tracking domains in privacy manifest | None | `NSPrivacyTrackingDomains = []`. |
| Collected data types in privacy manifest | None | `NSPrivacyCollectedDataTypes = []`. |
| Required-reason API categories in privacy manifest | None declared currently | `NSPrivacyAccessedAPITypes = []`. Confirm against the current Apple required-reason API list during release; this snapshot found no `@AppStorage`/`UserDefaults` use in Apple Swift sources, and the no-network check passed. |

## Web privacy summary evidence

[`docs/privacy.md`](../privacy.md) says the web app has no accounts, no analytics and no server-side progress storage, and makes no third-party requests itself (citation links open another site only when the user follows them). It also notes that static hosting may still expose client IP addresses and user-agent data to ordinary HTTP request logs for app assets.

The web Settings privacy copy now mirrors that summary:

| Locale | Settings copy in `apps/web/src/lib/i18n.ts` |
|---|---|
| English | “No accounts, analytics, telemetry, ads, or server-side progress storage are used, and the app sends no requests to third parties; citation links open another site only when you choose them. Progress stays in IndexedDB on this device unless you export it; the static host may still log ordinary asset requests.” |
| French | “L’application n’utilise aucun compte, aucune analytique, aucune télémétrie, aucune publicité ni aucun stockage côté serveur de la progression, et n’envoie aucune requête à des tiers; les liens de référence n’ouvrent un autre site que si vous les choisissez. La progression reste dans IndexedDB sur cet appareil, sauf si vous l’exportez; l’hébergeur statique peut tout de même journaliser les requêtes ordinaires de fichiers.” |

French copy follows [`docs/french-style.md`](../french-style.md): the only colon-sensitive nearby Settings copy continues to use a no-break space before `:`, and this privacy copy does not introduce a colon.

Build and URL-audit evidence:

```text
pnpm build:web
vite v8.3.1 building client environment for production...
✓ built in 267ms
[plugin builtin:vite-reporter] (!) Some chunks are larger than 500 kB after minification. ...

pnpm --filter @canadian-ham/web audit:urls
dist URL audit passed.
```

The non-fatal chunk-size warning does not affect the privacy assertion; the URL audit passed after scanning the built `dist` output for unexpected `http://` and `https://` URLs.

## Release-commit follow-up required

AC #3 is intentionally not complete in this pre-release task state. On the release commit, re-run and record fresh outputs for:

```sh
pnpm check:apple-network
pnpm test:apple-network
pnpm build:web
pnpm --filter @canadian-ham/web audit:urls
```

Also confirm the exact App Store Connect wording and any changes to Apple's privacy manifest / required-reason API requirements before submitting the privacy label.
