# App Store privacy label and web privacy evidence

Prepared for Backlog `task-1.2` on 2026-10-02 UTC, before the release commit and before the ISED permission dependency is complete. This is a pre-release evidence snapshot; re-run the checks on the release commit before checking AC #3.

For release-day execution, use the consolidated [release checklist](release-checklist.md#privacy) alongside this privacy-label evidence.

## Scope

- Apple application targets under `apps/apple`: `CanadianHam` (iOS/iPadOS/macOS), `CanadianHamTV`, `CanadianHamVision`, and the embedded independent `CanadianHamWatch` (watchOS).
- Web privacy summary shown in `apps/web` Settings.
- Evidence sources required by `task-1.2`: `apps/apple/CanadianHam/Resources/PrivacyInfo.xcprivacy`, `pnpm check:apple-network`, `pnpm test:apple-network`, `pnpm build:web`, `pnpm --filter @canadian-ham/web audit:urls`, and [`docs/privacy.md`](../privacy.md).

Test bundles are not App Store-distributed application targets. The original snapshot below covers three application targets; the TASK-14.6 addendum covers the fourth, `CanadianHamWatch`, and its separate watch privacy manifest.

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

Recommended answer: **Data Not Collected**, including the independent watchOS payload.

Supporting rationale from [`docs/privacy.md`](../privacy.md): the Apple app has no accounts, no telemetry, no advertising, no third-party tracking, no automatic crash or diagnostic upload, no remote progress sync, no iCloud sync in v1, no networking code, and no third-party SDKs. On iOS, iPadOS and macOS, local study progress remains in local app storage unless the user explicitly exports it. On tvOS and visionOS, practice sessions are kept only while the app is open; nothing is saved or sent. On watchOS, practice, Morse and language/output settings are session-only in memory; no scores/preferences, identifiers, recordings or progress are stored or transmitted. The watch uses no HealthKit, microphone, WatchConnectivity, push, iCloud or background network session.

| App Privacy data category / type | Answer | Supporting evidence |
|---|---|---|
| Contact Info: name, email address, phone number, physical address, other user contact info | Not collected | `docs/privacy.md` says no accounts and no transmitted progress; `NSPrivacyCollectedDataTypes` is empty; `pnpm check:apple-network` passed. |
| Health and Fitness: health, fitness | Not collected | The app is an amateur-radio study app; `docs/privacy.md` allowed persistent local data is limited to study progress, mock exam attempts, practice history, preferences, and user-initiated import/export JSON on iOS, iPadOS and macOS. tvOS and visionOS keep only in-memory practice sessions while the app is open. `NSPrivacyCollectedDataTypes` is empty. |
| Financial Info: payment info, credit info, other financial info | Not collected | No payments, purchases, subscriptions, or account flows are implemented; `NSPrivacyCollectedDataTypes` is empty. |
| Location: precise location, coarse location | Not collected | No location capability or network-dependent capability is documented or detected; `pnpm check:apple-network` passed. |
| Sensitive Info | Not collected | No sensitive-information feature exists; `docs/privacy.md` permits only local study progress/preferences and user-initiated JSON import/export on persistent platforms, plus in-memory tvOS/visionOS practice sessions while the app is open. |
| Contacts | Not collected | No contacts capability is documented or detected; `NSPrivacyCollectedDataTypes` is empty. |
| User Content: emails or text messages, photos or videos, audio data, gameplay content, customer support, other user content | Not collected | The app has no account/customer-support upload flow and no media/user-content upload flow. On iOS, iPadOS and macOS, user-initiated progress export remains a local JSON file unless the user takes it elsewhere outside the app. tvOS and visionOS do not export progress. |
| Browsing History | Not collected | The Apple app has no browser or web view and makes no network requests; `pnpm check:apple-network` scans for browser/network symbols and passed. Its only clickable external URL is the RBR-4 citation link on the shared answer-explanation panel (`ExplanationPanelView` in `apps/apple/CanadianHam/Views/LearnViews.swift`, shown after answering in lesson quizzes, practice sessions and review, and mock-exam review via `PracticeFeedback`), which opens in the system browser only when tapped; the app itself sends nothing and records nothing about the tap. The About screens also display the RBR-4 URL and the active ISED question-bank source URL as non-clickable text for citation/source transparency. |
| Search History | Not collected | No server-side search exists; app content is bundled and offline; `NSPrivacyCollectedDataTypes` is empty. |
| Identifiers: user ID, device ID | Not collected | No accounts, analytics, ads, tracking, third-party SDKs, or networking code; `NSPrivacyCollectedDataTypes` is empty and `pnpm check:apple-network` passed. |
| Purchases: purchase history | Not collected | No purchase or subscription feature exists; `NSPrivacyCollectedDataTypes` is empty. |
| Usage Data: product interaction, advertising data, other usage data | Not collected | Local study progress is not transmitted; tvOS and visionOS practice sessions are in-memory only and are not saved or sent. Docs disallow analytics, telemetry, advertising identifiers, and remote progress sync; `pnpm check:apple-network` passed. |
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
| Third-party SDKs or partner code in the Apple app | No third-party runtime SDK collection; no remote third-party SDKs linked | `docs/privacy.md` forbids third-party SDKs in v1. `pnpm check:apple-network` passed and checks for remote Swift package references in `apps/apple/project.yml`, the generated Xcode project, Swift package manifests, and `Package.resolved`. Current Apple dependencies in `apps/apple/project.yml` are local packages `../../packages/engine-swift`, `../../packages/content-swift`, `../../packages/morse-swift` and `../../packages/calculator-swift`. `CanadianHam` links all four; `CanadianHamTV`, `CanadianHamVision` and `CanadianHamWatch` link `engine-swift`, `content-swift` and `morse-swift`. |
| Apple frameworks/services collection | None by this app | `docs/privacy.md` forbids iCloud sync and network-dependent entitlements in v1. The quoted Apple wording from `docs/proposals/icloud-sync.md` says app developers disclose data they collect from Apple frameworks/services; this app currently collects none. |

### Privacy manifest and required-reason APIs

| Area | Answer | Supporting evidence |
|---|---|---|
| Privacy manifest included | Yes, each application target bundles exactly one manifest of its own (TASK-85) | `CanadianHam` (iOS/iPadOS/macOS): `apps/apple/CanadianHam/Resources/PrivacyInfo.xcprivacy`. `CanadianHamTV`: `apps/apple/Platforms/tvOS/Resources/PrivacyInfo.xcprivacy`. `CanadianHamVision`: `apps/apple/Platforms/visionOS/Resources/PrivacyInfo.xcprivacy`. `CanadianHamWatch`: `apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy`. Until TASK-85, TV and Vision shared the `CanadianHam` manifest; see the [TASK-85 review](#required-reason-api-review-task-85-2026-11-03). |
| Tracking domains in privacy manifest | None | `NSPrivacyTrackingDomains = []`. |
| Collected data types in privacy manifest | None | `NSPrivacyCollectedDataTypes = []`. |
| Required-reason API categories in privacy manifest | Declared per target (TASK-85) | `CanadianHam`: User defaults `CA92.1` and System boot time `35F9.1`. `CanadianHamTV` and `CanadianHamVision`: User defaults `CA92.1`. `CanadianHamWatch`: System boot time `35F9.1`. No target uses the File timestamp, Disk space or Active keyboards categories. `pnpm check:apple-required-reasons` enforces this mapping; rationale and evidence are in the [TASK-85 review](#required-reason-api-review-task-85-2026-11-03). The earlier "none declared" answer and its statement that no `@AppStorage`/`UserDefaults` use existed are superseded. |

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

## TASK-14.1 watchOS skeleton addendum (2026-10-25, historical)

This records the skeleton stage; the completed feature payload and signed-export
evidence are covered by TASK-14.6 below.

`CanadianHamWatch` is an independently usable watchOS 27 app embedded in the iOS
container only. Its watch-specific source tree is `apps/apple/Platforms/watchOS`;
its own `Resources/PrivacyInfo.xcprivacy` declares no tracking, tracking domains,
collected data types or required-reason API types. The skeleton contains only
three navigable placeholders, no stored state or bundled question bank yet.
It links the three local engine/content/Morse packages, not phone app services,
WatchConnectivity, remote packages or SDKs. App Privacy remains **Data Not Collected**.

The watch reuses `CanadianHam/Resources/Localizable.xcstrings` so existing Practice,
Morse, Coming soon and app-name translations have one source of truth; Alphabet
adds one EN/FR catalogue key. Watch bundle metadata has its own EN/fr/fr-CA
`InfoPlist.xcstrings`; the localization check verifies both catalogues remain
unchanged. No phone source membership is implied by sharing the UI resource.
The watch has its own privacy manifest to keep membership explicit.

`check-apple-no-network.sh` recursively scans all watch app/test sources and privacy
resources as well as package sources. Watch paths never receive the optional
CloudKit symbol exemption. Its fixtures prove gated watch CloudKit and
WatchConnectivity are rejected. `check-apple-icloud-gate.mjs` checks watch app/test
build settings in **all** configurations, including DebugCloudKit, requiring empty
entitlements and a non-inherited empty `OTHER_SWIFT_FLAGS` override. The watch
therefore does not inherit the project's optional `ICLOUD_SYNC` gate. Regression
fixtures cover inherited flags, cloud flags, push background modes and non-empty
entitlement paths. No release signing, upload or distribution is performed here;
TASK-14.6 owns that validation and the final icon.

## TASK-14.6 watchOS release payload (2026-10-25)

**App Privacy: Data Not Collected; no tracking.** The independently usable watch
app is delivered inside the existing iOS TestFlight container, not as a new ASC
platform. Quick Basic practice, local Morse haptic/optional generated-tone output,
alphabet reference and EN/FR session Settings are offline. Practice and settings
state lives only in memory; relaunch resets it. No phone session, account,
WatchConnectivity, network request, sync, microphone/recording, HealthKit,
analytics/diagnostic uploader, external runtime SDK, push or App Groups is used.
Apple's own TestFlight delivery/diagnostics are not app-authored data collection.

`apps/apple/project.yml` includes the watch-specific source/resource tree and
its own `Platforms/watchOS/Resources/PrivacyInfo.xcprivacy`. The **exported signed
watch bundle** includes that manifest with:

```text
NSPrivacyTracking = false
NSPrivacyTrackingDomains = []
NSPrivacyCollectedDataTypes = []
NSPrivacyAccessedAPITypes = []
```

The [TASK-14.6 inspection and per-test evidence](../testing/task-14.6-watch-release.md)
records the actual IPA path/build, manifest, entitlements, linked frameworks,
Basic-only resource inventory and network/iCloud guard outputs. The manifest is
also hash-compared with its source; the signed watch has no iCloud, push,
`aps-environment` or App Groups entitlement. Only the Basic bank plus original
explanations are included as study data (no lessons/hints/Advanced/figures or
official exam sheet). Locally generating a tone uses audio output only, not audio
capture or transmission.

The same App Privacy answers above apply to the watch, including **Not collected**
for Health/Fitness, Identifiers, User Content/audio, Usage Data and Diagnostics.
This is signed local export evidence, not a claim of ASC processing, a submitted
privacy-label update or a physical-watch test. The owner must confirm the current
App Privacy wording when the approved internal build is processed and run the
[physical offline/VoiceOver/haptic checks](testflight.md#owner-physical-watch-checklist-required-not-replaced-by-simulator-tests).
TASK-14.6 AC4 remains unchecked until that post-merge gate is recorded; external
testing/public links/App Store submission remain forbidden before TASK-1.7.

## Current preference and manifest inventory (2026-10-28)

Audited source revision: **`a69c27400b88302c9f8ce393ea98ae01b73cfd25`**.
This TASK-81 source/configuration review supplements, rather than replaces, the
historical snapshots above. In particular, the original statement that no
`@AppStorage` / `UserDefaults` use was found is not current evidence: there is
now explicit `UserDefaults` use. No release build, signed-artifact inspection,
network guard, web build/URL audit or device test was rerun for this docs-only
addendum. TASK-1.2's release-commit validation remains required; TASK-1.5's
checklist is not release approval.

### Preference sources reviewed

A recursive source search across `apps/apple` and `packages` for `UserDefaults`,
`NSUserDefaults`, `standardUserDefaults`, `CFPreferences`, `@AppStorage` and
`@SceneStorage` found direct preference-API references in
`MorseTrainerSettings.swift`, `ProgressStore.swift`, `NativeSettingsView.swift`,
`StudyViews.swift`, and the corresponding `ProgressStoreTests.swift` /
`MorseTrainerTests.swift`. No matches for the other searched API spellings were
found. The following inventory also checks their call sites, shared
`ApplePreferences.swift`, the SwiftData preference models, and platform root
state. This is a bounded preference-source/configuration inventory, **not** a
comprehensive audit of all Apple required-reason API categories, transitive
framework behavior or final shipped artifacts.

| Source | Current local preference behavior | Application coverage at this revision |
|---|---|---|
| `CanadianHam/Morse/MorseTrainerSettings.swift` (lines 161–176) | `load(defaults: .standard)` reads JSON data under `canadian-ham.morse-trainer-settings.v1`, decodes/normalizes it or returns defaults; `save` encodes normalized settings and writes data; `reset` removes the key. Stored fields are tone Hz, character/effective WPM, timing profile, volume and output mode. | Compiled by `CanadianHam` (iOS/iPadOS/macOS), `CanadianHamTV` and `CanadianHamVision`, not the watch. |
| Morse call sites: `MorseTrainerView.swift`, `AppSettingsModel.swift`, `RootView.swift`, `NativeSettingsView.swift`, `StudyViews.swift` | The iOS/macOS app loads settings, the trainer saves normalized changes, import saves imported Morse preferences, and reset removes them. The two Settings view files' explicit `UserDefaults` parameters feed that same Morse save path. | `CanadianHam` only. |
| `Platforms/tvOS/CanadianHamTVApp.swift`, `Platforms/visionOS/CanadianHamVisionApp.swift` | Both initialize in-memory Morse state with `MorseTrainerSettings.load()`, thus reading defaults. No Morse save/reset call was found in these platform sources; settings edits and practice remain session state. Read access still belongs in the required-reason review. | `CanadianHamTV`, `CanadianHamVision`, respectively. |
| `CanadianHam/Services/ProgressStore.swift`: language and bank selection | Reads/writes/removes `AppleLanguages`, records `CanadianHam.preferences.appleLanguagesLastApplied`, reads/writes `CanadianHam.preferences.legacyEnglishLanguageDefaultMigrationComplete`, and reads/writes/removes `CanadianHam.activeBankId` for load/update/import/reset/rollback and launch reset. Language-domain reads use `persistentDomain(forName:)`; language application is conditioned on iOS/macOS. | `CanadianHam` (iOS/iPadOS/macOS); ProgressStore is not in the TV, Vision or Watch app targets. |
| `ProgressStore.swift`: `ICloudSyncSettings` helpers and service initialization/reset | Defaults helpers read/write/remove `CanadianHam.iCloudSyncOptIn`, create/read a local UUID under `CanadianHam.iCloudSyncLocalDeviceIdentifier`, and read/set/remove `CanadianHam.iCloudSyncPendingProgressZoneDeletion`. These helper definitions are not wholly inside `#if ICLOUD_SYNC`; normal service initialization reads opt-in and obtains the local device identifier, and local reset clears opt-in. Do not omit these local accesses merely because remote sync is gated. | `CanadianHam`. CloudKit import/monitoring and remote database selection are gated by `ICLOUD_SYNC`, enabled only in the non-default `DebugCloudKit` configuration, not v1 Debug/Release. This is not authorization for v1 sync. |
| `Platforms/Shared/ApplePreferences.swift`, `CanadianHam/Models/ProgressModels.swift`, `ProgressStore.swift` | `ApplePreferences` is a Codable value, not a defaults wrapper. Practice mode, exam timer, language and theme are persisted through local SwiftData `PreferencesEntity` rows; active-bank selection uses defaults as above. The lesson-split migration marker `CanadianHam.progress.task46_10LessonSplitMigrationComplete` is a keyed SwiftData preferences row, **not** a defaults key. | Shared preference value compiled by `CanadianHam`, TV and Vision; SwiftData models/store belong to `CanadianHam`. |
| `Platforms/watchOS/WatchHomeView.swift`, `WatchSettingsView.swift`, `WatchMorseDrill.swift` (`WatchMorseSettings`), `WatchMorseView.swift` | Watch language and Morse/output preferences are in-memory state, reset by relaunch. The watch does not compile the phone's Morse settings/defaults or ProgressStore sources. | `CanadianHamWatch`; its linked local package sources had no matches in the preference-API search above. |
| `CanadianHamTests/ProgressStoreTests.swift`, `MorseTrainerTests.swift` | Defaults suites and round-trip/import/reset assertions support tests, not evidence that shipped manifests are sufficient. | Test bundles are not distributed application targets; no tests were executed for this addendum. |

### Observed manifests and target membership

Both source manifests parsed with `plutil -p` and currently declare:

```text
NSPrivacyTracking = false
NSPrivacyTrackingDomains = []
NSPrivacyCollectedDataTypes = []
NSPrivacyAccessedAPITypes = []
```

`apps/apple/project.yml` and the generated
`apps/apple/CanadianHam.xcodeproj/project.pbxproj` agree on these application
resource memberships and preference-source memberships:

| Application target | Manifest source and generated Resources entry | Preference source coverage |
|---|---|---|
| `CanadianHam` (iOS/iPadOS/macOS) | `CanadianHam/Resources/PrivacyInfo.xcprivacy`, included through the `CanadianHam` tree; `DA8494DE030F9968C7D5505E` in Resources phase `70820DEF5BA3FD3C91F0105E` | Morse settings, ProgressStore, SwiftData models and Settings import/reset views |
| `CanadianHamTV` | Same shared manifest, explicitly listed; `7A69A327192A249A5B2FF3AD` in `970FB2C9E711726AD828A219` | Shared Morse settings and platform load call, no ProgressStore |
| `CanadianHamVision` | Same shared manifest, explicitly listed; `71824E1D425D494043EA0781` in `43D39217D2081D1C20A0889C` | Shared Morse settings and platform load call, no ProgressStore |
| `CanadianHamWatch` | `Platforms/watchOS/Resources/PrivacyInfo.xcprivacy`, through the watch tree; `32900841E36F7C998DB6960F` in `E9EC76AE96F86E7F7A62BF9C` | Watch-specific in-memory settings, not shared Morse settings/ProgressStore |

These are source/project observations, not a fresh inspection of bundled or
signed release manifests. The older watch export evidence remains historical.

### Required-reason review: completed by TASK-85

This subsection first recorded the required-reason review as **OPEN**. The
inventory above found defaults access, but both source manifests declared an
empty `NSPrivacyAccessedAPITypes`. TASK-81 selected no reason codes and changed
no code or manifests. TASK-85 has now completed the review for every
required-reason category, every shipped target and every linked local package.
It updated the manifests and added an automated check; see
[Required-reason API review (TASK-85, 2026-11-03)](#required-reason-api-review-task-85-2026-11-03).
The preference inventory above remains a record of its audited revision.

The existing ISED permission, device/offline/accessibility, privacy wording and
release-candidate gates remain in force. Neither addendum completes TASK-1.2,
reopens or re-completes TASK-1.5, or authorizes distribution.

## Required-reason API review (TASK-85, 2026-11-03)

Reviewed source revision: TASK-85 base
**`bf7759402715ad00b241ca6ac31a145f8841b777`** plus the TASK-85 manifest and
`apps/apple/project.yml` changes. On the release commit, re-run
`pnpm check:apple-required-reasons` and inspect the built manifests. This review
does not approve a release.

### Apple sources

Fetched from developer.apple.com on 2026-11-03 UTC:

- [Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [`NSPrivacyAccessedAPIType`](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)
- [`NSPrivacyAccessedAPITypeReasons`](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons)
- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)

Apple's requirement, quoted:

- > Describe the reasons your app or third-party SDK on iOS, iPadOS, tvOS, visionOS, or watchOS uses these APIs, and check that your app or third-party SDK only uses the APIs for the expected reasons.
- > Starting May 1, 2024, apps that don’t describe their use of required reason API in their privacy manifest file aren’t accepted by App Store Connect.
- > If you use the API in your app’s code, then you need to report the API in your app’s privacy manifest file.

macOS is not on that platform list. The `CanadianHam` target builds iOS,
iPadOS and macOS from one multiplatform target, so the macOS bundle carries
the same manifest. Its boot-time entry describes iOS-only code and is
informational on macOS.

### Categories, listed APIs and approved reasons

| Category (`NSPrivacyAccessedAPIType`) | APIs Apple lists | Reasons an app may declare | Used by a shipped target? |
|---|---|---|---|
| File timestamp (`NSPrivacyAccessedAPICategoryFileTimestamp`) | `creationDate`, `modificationDate`, `fileModificationDate`, `contentModificationDateKey`, `creationDateKey`, `getattrlist`, `getattrlistbulk`, `fgetattrlist`, `stat`, `fstat`, `fstatat`, `lstat`, `getattrlistat` | `DDA9.1`, `C617.1`, `3B52.1` (`0A2A.1` is for third-party SDKs only) | No |
| System boot time (`NSPrivacyAccessedAPICategorySystemBootTime`) | `systemUptime`, `mach_absolute_time()` | `35F9.1`, `8FFB.1`, `3D61.1` | Yes: `CanadianHam`, `CanadianHamWatch` |
| Disk space (`NSPrivacyAccessedAPICategoryDiskSpace`) | `volumeAvailableCapacityKey`, `volumeAvailableCapacityForImportantUsageKey`, `volumeAvailableCapacityForOpportunisticUsageKey`, `volumeTotalCapacityKey`, `systemFreeSize`, `systemSize`, `statfs`, `statvfs`, `fstatfs`, `fstatvfs`, `getattrlist`, `fgetattrlist`, `getattrlistat` | `85F4.1`, `E174.1`, `7D9E.1`, `B728.1` | No |
| Active keyboards (`NSPrivacyAccessedAPICategoryActiveKeyboards`) | `activeInputModes` | `3EC4.1`, `54BD.1` | No |
| User defaults (`NSPrivacyAccessedAPICategoryUserDefaults`) | `UserDefaults` | `CA92.1`, `1C8F.1`, `AC6B.1` (`C56D.1` is for third-party SDKs only) | Yes: `CanadianHam`, `CanadianHamTV`, `CanadianHamVision` |

Apple's wording for the reasons in the two used categories:

- User defaults
  - **`CA92.1` (declared):** “Declare this reason to access user defaults to read and write information that is only accessible to the app itself. This reason does not permit reading information that was written by other apps or the system, or writing information that can be accessed by other apps.”
  - `1C8F.1`: “Declare this reason to access user defaults to read and write information that is only accessible to the apps, app extensions, and App Clips that are members of the same App Group as the app itself. This reason does not permit reading information that was written by apps, app extensions, or App Clips outside the same App Group or by the system. Your app is not responsible if the system provides information from the global domain because a key is not present in your requested domain while your app is attempting to read information that apps, app extensions, or App Clips in your app’s App Group write. This reason also does not permit writing information that can be accessed by apps, app extensions, or App Clips outside the same App Group.”
  - `AC6B.1`: “Declare this reason to access user defaults to read the com.apple.configuration.managed key to retrieve the managed app configuration set by MDM, or to set the com.apple.feedback.managed key to store feedback information to be queried over MDM, as described in the Apple Mobile Device Management Protocol Reference documentation.”
  - `C56D.1` (third-party SDKs only): “Declare this reason if your third-party SDK is providing a wrapper function around user defaults API(s) for the app to use, and you only access the user defaults APIs when the app calls your wrapper function. This reason may only be declared by third-party SDKs. …”
- System boot time
  - **`35F9.1` (declared):** “Declare this reason to access the system boot time in order to measure the amount of time that has elapsed between events that occurred within the app or to perform calculations to enable timers. Information accessed for this reason, or any derived information, may not be sent off-device. There is an exception for information about the amount of time that has elapsed between events that occurred within the app, which may be sent off-device.”
  - `8FFB.1`: “Declare this reason to access the system boot time to calculate absolute timestamps for events that occurred within your app, such as events related to the UIKit or AVFAudio frameworks. Absolute timestamps for events that occurred within your app may be sent off-device. System boot time accessed for this reason, or any other information derived from system boot time, may not be sent off-device.”
  - `3D61.1`: “Declare this reason to include system boot time information in an optional bug report that the person using the device chooses to submit. The system boot time information must be prominently displayed to the person as part of the report. …”

The first sentence of each reason in the unused categories, for reference:

- File timestamp:
  - `DDA9.1` “Declare this reason to display file timestamps to the person using the device.”
  - `C617.1` “Declare this reason to access the timestamps, size, or other metadata of files inside the app container, app group container, or the app’s CloudKit container.”
  - `3B52.1` “Declare this reason to access the timestamps, size, or other metadata of files or directories that the user specifically granted access to, such as using a document picker view controller.”
- Disk space:
  - `85F4.1` “Declare this reason to display disk space information to the person using the device.”
  - `E174.1` “Declare this reason to check whether there is sufficient disk space to write files, or to check whether the disk space is low so that the app can delete files when the disk space is low.”
  - `7D9E.1` “Declare this reason to include disk space information in an optional bug report that the person using the device chooses to submit.”
  - `B728.1` “Declare this reason if your app is a health research app, and you access this API category to detect and inform research participants about low disk space impacting the research data collection.”
- Active keyboards:
  - `3EC4.1` “Declare this reason if your app is a custom keyboard app, and you access this API category to determine the keyboards that are active on the device.”
  - `54BD.1` “Declare this reason to access active keyboard information to present the correct customized user interface to the person using the device.”

### Per-target usage and declarations

Target membership comes from the `sources` and `excludes` of each target in
`apps/apple/project.yml`, plus the `Sources` of every local Swift package the
target links. Test bundles are not distributed and were excluded. Use inside
Apple's own frameworks is Apple's to declare. The searches covered every
spelling in the table above, plus `NSUserDefaults`, `@AppStorage`,
`@SceneStorage`, `CFPreferences*`, `persistentDomain`, `mach_absolute_time`,
`clock_gettime`/`CLOCK_UPTIME*`/`CLOCK_MONOTONIC*`, `kern.boottime`,
`attributesOfItem`, `NSFile*Date`, `statfs`/`statvfs` and `activeInputModes`.

| Shipped target (platforms) | Linked local packages | Required-reason API use (Release-relevant call sites) | Manifest | Declared |
|---|---|---|---|---|
| `CanadianHam` (iOS, iPadOS, macOS) | `engine-swift`, `content-swift`, `morse-swift`, `calculator-swift` | **User defaults:** `Services/ProgressStore.swift` covers several groups of keys. The `ICloudSyncSettings` keys hold the opt-in flag, a local device UUID and a pending-deletion flag; they are compiled outside `ICLOUD_SYNC` and stay on the device in v1. It also reads and writes `AppleLanguages` and its last-applied marker, the active bank ID, and the legacy language migration marker. `Morse/MorseTrainerSettings.swift` has `load`, `save` and `reset`. `Views/NativeSettingsView.swift:342` and `Views/StudyViews.swift:2183` pass a `UserDefaults` parameter into the Morse save path. **System boot time:** `Views/StudyViews.swift:758` (`#if os(iOS)`) stamps hinge-peek samples with `systemUptime`; `scheduleHingePeekDwellRecheck` then sleeps for `deadline - lastSampleTimestamp`, which is a timer. `Support/DuoPostureProvider.swift:296` stamps hinge samples when the SDK has the hinge API. Lines 361, 414, 419 and 432 measure debug-playback elapsed time inside `#if DEBUG`. | `CanadianHam/Resources/PrivacyInfo.xcprivacy` | User defaults `CA92.1`; System boot time `35F9.1` |
| `CanadianHamTV` (tvOS) | `engine-swift`, `content-swift`, `morse-swift` | **User defaults only:** compiles the shared `MorseTrainerSettings.swift`, and `CanadianHamTVApp.swift:159` calls `MorseTrainerSettings.load()`. This is a read only; save and reset are never called. There is no boot-time, file-timestamp, disk-space or keyboard API. | `Platforms/tvOS/Resources/PrivacyInfo.xcprivacy` (new) | User defaults `CA92.1` |
| `CanadianHamVision` (visionOS) | `engine-swift`, `content-swift`, `morse-swift` | **User defaults only:** compiles the shared `MorseTrainerSettings.swift`, and `CanadianHamVisionApp.swift:72` calls `MorseTrainerSettings.load()`, again read only. There are no other categories. | `Platforms/visionOS/Resources/PrivacyInfo.xcprivacy` (new) | User defaults `CA92.1` |
| `CanadianHamWatch` (watchOS) | `engine-swift`, `content-swift`, `morse-swift` | **System boot time only:** `Platforms/watchOS/WatchMorsePlayback.swift:34` makes `WatchMorseLiveScheduler.now` return `ProcessInfo.processInfo.systemUptime`. It enforces minimum haptic spacing from `lastHapticAt` and computes scheduling delays (lines 90, 102, 145, 147). There is no user defaults access, because watch settings live only in memory. | `Platforms/watchOS/Resources/PrivacyInfo.xcprivacy` | System boot time `35F9.1` |

No required-reason API appears in the `Sources` of any linked package.
`content-swift` uses `.isRegularFileKey`, and `MorseSendingPracticeView` uses
`ContinuousClock`; neither is a listed API. All four manifests keep
`NSPrivacyTracking = false`, `NSPrivacyTrackingDomains = []` and
`NSPrivacyCollectedDataTypes = []`.

`CanadianHamTV` and `CanadianHamVision` used to list
`CanadianHam/Resources/PrivacyInfo.xcprivacy` explicitly as a resource. With
the iOS-only boot-time declaration in that manifest, they would have declared
a category they never use. TASK-85 therefore removes those two explicit
entries from `apps/apple/project.yml`. Each target now bundles its own manifest
through its `Platforms/<platform>` source tree. The check fails if any shipped
target bundles anything other than exactly one manifest.

### Why these reasons

- **User defaults → `CA92.1`.** Every defaults access uses
  `UserDefaults.standard`, which is the app's own domain. The only exception
  is a private `UserDefaults(suiteName:)` created by
  `ProgressStoreService.inMemoryForTests`, a test-only factory. The app has no
  App Group (so `1C8F.1` does not apply) and no MDM keys (so `AC6B.1` does not
  apply). No defaults data is shared with other apps.
- **`AppleLanguages` (needs care under `CA92.1`).** On iOS and macOS,
  `ProgressStoreService.applyInterfaceLanguagePreference` sets or removes
  `AppleLanguages` in the app's own standard domain. It does this when the
  person picks English, French or System in the app's Settings, so that the
  app's interface follows that choice. That write is visible only to this app.
  - To read the value back, `persistentAppleLanguages` calls
    `defaults.persistentDomain(forName: Bundle.main.bundleIdentifier)`. That
    reads only this app's persistent domain. It deliberately skips the normal
    defaults search list, so the device-wide `AppleLanguages` from the global
    domain is never read.
  - `adoptExternalInterfaceLanguageSelectionIfNeeded`, added in TASK-37 to
    preserve system app-language overrides, uses that read to adopt a per-app
    language. The person can choose a language for this app in iOS Settings or
    in macOS System Settings, and the OS stores that choice in the app's own
    domain. The legacy French migration also checks this value
    (`persistentAppleLanguages(...) == nil`).
  - This value is user-chosen configuration of this app, stored in this app's
    domain and readable only by this app, comparable to Settings.bundle
    preferences. It is not system or other-app information, and it reveals
    nothing beyond the language the app is already displaying. No other
    approved reason fits.
  - **Residual risk:** Apple's text does not say whether the per-app language
    entry that Settings writes counts as information “written by … the
    system”. If App Review disagrees, there are two remedies. One is to drop
    the external-selection adoption and the legacy French `nil` check, so the
    app only writes `AppleLanguages` and reads its own keys. The other is to
    request a new reason through Apple's
    [privacy manifest reason request form](https://developer.apple.com/contact/request/privacy-manifest-reason/).
    TASK-85 changes no app code.
  - **Decision (coordinator, 2026-11-02):** keep `CA92.1`. The app reads
    only its own app-domain `AppleLanguages` key, which its language picker
    also writes. The two remedies above stay as fallbacks if App Review
    objects. **The owner must explicitly sign off this decision before App
    Store submission** (tracked on TASK-1.7).
- **System boot time → `35F9.1`.** Both uses measure time elapsed between
  events inside the app or drive timers. On iOS, hinge-peek dwell rechecks
  schedule a timer from sample timestamps. On watchOS, haptic spacing and
  delays are computed from the scheduler's `now`. Neither value is ever sent
  off the device: the app has no networking code, as `pnpm check:apple-network`
  confirms. No absolute timestamps are derived (`8FFB.1`), and there is no bug
  report (`3D61.1`).

### Automated check

`pnpm check:apple-required-reasons`
([`scripts/check-apple-required-reasons.mjs`](../../scripts/check-apple-required-reasons.mjs))
works as follows:

- **Scope.** It parses `apps/apple/project.yml` and resolves each target's
  compiled Swift files and bundled `PrivacyInfo.xcprivacy`, honouring
  `sources`, `excludes`, `buildPhase` and folder references. Linked local
  packages contribute their `Sources/**`. Test bundles count only for
  coverage.
- **Scanning.** It blanks Swift comments and scans the code for the spellings
  of each category. String and regex literals are kept, following the Swift 6
  lexer for extended `#/.../#` and bare `/.../` regex literals, so a `/*` or
  `//` inside a literal does not hide later code. The patterns run over the
  whole file rather than line by line, so a spelling split across lines
  still counts; each usage is reported on the line where its API name
  starts. API names are matched with or without a module qualifier
  (`Foundation.UserDefaults`, `Darwin.mach_absolute_time`), and `AppStorage`
  counts in any form, including `@SwiftUI.AppStorage`. C functions such as
  `fstat`, `lstat`, `statfs` and `getattrlist` count as references as well
  as calls (for example `let read = Darwin.fstat`). Bare `stat` is also a
  common Swift name, so it counts only as a call (including `stat` with the
  `(` on the next line), a C-module-qualified name (`Darwin.stat`, also with
  `.stat` on the next line) or the whole right-hand side of an assignment.
- **What fails.** The check fails in any of these cases:
  - a shipped target uses a category its own manifest does not declare;
  - a manifest declares a category its target does not use;
  - a reason is unknown, belongs to another category, is SDK-only, is empty
    or is duplicated;
  - a category is unknown or duplicated;
  - a target bundles anything other than exactly one manifest;
  - a manifest does not set `NSPrivacyTracking` to `false`, or does not have
    empty `NSPrivacyTrackingDomains` and `NSPrivacyCollectedDataTypes` arrays;
  - a shipped target or linked package contains C, Objective-C, C++ or
    assembly sources or headers, because only Swift is scanned;
  - a Swift file under `apps/apple` is compiled by no target;
  - comment stripping could hide code: an unterminated block comment or
    extended regex literal, or a comment marker straight after `\` (an
    escaped slash in a regex literal the checker could not delimit).
- **Unsupported constructs.** It also fails on XcodeGen keys it does not
  model, on remote, binary or dynamic packages, and on unknown target types.
- **Self-test.** `pnpm test:apple-required-reasons` runs the fixtures. They
  include comment-only mentions, a string containing `//` followed by real
  code, excluded and test-only files, unlinked packages and package tests,
  `getattrlist` counting for both File timestamp and Disk space, C-function
  references, module-qualified spellings in every category including
  `@SwiftUI.AppStorage`, spellings split across lines, `stat`-named Swift
  identifiers that must not count, regex literals containing comment
  markers, and the fail-closed cases above.
- **Limitations.** The check does not evaluate `#if` (an API compiled out on
  some platforms still counts for the target). It also scans inside string
  and regex literals, so it errs towards declaring a category. An
  unqualified bare `stat` used as a value anywhere other than the whole
  right-hand side of an assignment is not detected: for example passed as
  an argument (`apply(stat)`), returned (`return stat`), placed in a
  collection (`[stat]`) or used as an operand (`x ?? stat`). This avoids
  matching Swift variables named `stat`. Binary inspection (below) is the
  cross-check.

### Evidence

Run from the TASK-85 worktree on 2026-11-03 UTC:

| Command | Result |
|---|---|
| `plutil -lint` on the four manifests | All `OK`. |
| `rg` over non-test `*.swift` in `apps/apple` and `packages` for every spelling listed above | Matches in only six files: `MorseTrainerSettings.swift` (3 lines), `ProgressStore.swift` (27), `NativeSettingsView.swift` (1), `StudyViews.swift` (2), `DuoPostureProvider.swift` (5) and `WatchMorsePlayback.swift` (1). There are no matches in package `Sources`. |
| `pnpm test:apple-required-reasons` | `required-reasons-test: passed self-test fixtures.` |
| `pnpm check:apple-required-reasons` (with the `project.yml` change, on the branch since `b7877c4d`) | Passed. `CanadianHam`: 53 Swift files, `SystemBootTime [35F9.1], UserDefaults [CA92.1]`. `CanadianHamWatch`: 31, `SystemBootTime [35F9.1]`. `CanadianHamTV`: 33, `UserDefaults [CA92.1]`. `CanadianHamVision`: 32, `UserDefaults [CA92.1]`. |
| `pnpm check:apple-network`, `pnpm check:apple-icloud-gate` | Passed. |
| Release builds through `xbuild` (`-configuration Release`, generic simulator destinations, plus generic macOS, `CODE_SIGNING_ALLOWED=NO`), then `plutil -p` on each bundled `PrivacyInfo.xcprivacy` | All builds succeeded. Each bundle has exactly one manifest, byte-identical (`cmp`) to its source. iOS `CanadianHam.app` and macOS `CanadianHam.app/Contents/Resources` declare User defaults `CA92.1` and System boot time `35F9.1`. The embedded `CanadianHam.app/Watch/CanadianHamWatch.app` declares System boot time `35F9.1`. `CanadianHamTV.app` and `CanadianHamVision.app`, built from a regenerated project with the `project.yml` change, declare User defaults `CA92.1` only. |
| `strings -a` / `nm -u` on the Release binaries, which include the statically linked package code | iOS app: `systemUptime`, `standardUserDefaults`, `persistentDomainForName`. Watch: `systemUptime` only. macOS: `standardUserDefaults` and `persistentDomainForName`, but no `systemUptime`, because those call sites are iOS-only. TV and Vision: `standardUserDefaults` only. No binary imports `stat`, `lstat`, `fstat`, `fstatat`, `statfs`, `statvfs`, `getattrlist` or `mach_absolute_time`, and none references the file-timestamp, disk-space or `activeInputModes` selectors. |

These are unsigned local build products, not signed TestFlight or App Store
artifacts. Repeat the bundle inspection on the release archive.
