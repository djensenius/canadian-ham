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
  coverage. Like XcodeGen, the walk includes hidden files and directories.
  It skips nothing silently: `.DS_Store` files, resource catalogues
  (`.xcassets`, `.icon`, `.xcstrings`) and excluded paths are all walked,
  and every file in them is checked for prebuilt code, symbolic links and
  special files (FIFOs, sockets, devices). Excludes and catalogues only
  decide whether a file counts as compiled Swift, as a non-Swift source or
  as the target's manifest. SwiftPM ignores hidden files and applies
  `exclude:`, so package walks may scan more than SwiftPM compiles, which is
  the safe direction. Folder
  references (`type: folder`) and `buildPhase: none` entries compile nothing
  and never supply the target's manifest, even if they hold Swift files or a
  nested `PrivacyInfo.xcprivacy`. Their paths must still exist unless
  `optional`, and their whole contents are scanned for prebuilt code and
  symbolic links, including inside asset catalogues and ignoring `excludes`,
  because Xcode copies a folder reference as it is. In the real tree these
  are the `content/lessons`, `quizzes`, `explanations`, `hints`,
  `reference-sheet` and `generated/basic-2025-07-15` folders (Markdown and
  JSON only) and the UI tests' `ContrastMeasurement` PNGs; there are no
  `buildPhase: none` entries.
- **Pruning points.** Every place the checker skips, filters or narrows a
  path, and why the prebuilt-code and link checks still see everything Xcode
  or SwiftPM would copy or compile for a shipped target:

  | Point | Behaviour | Why it is safe |
  |---|---|---|
  | `.DS_Store` | Scanned like any file (no longer skipped). | A real Finder file starts with `00000001 Bud1` and passes; Xcode does not copy it. |
  | `excludes` | Walked; excluded files count only for the prebuilt-code, link and special-file checks. Only `*`, `?` and `**` (as a whole path component) are modelled. Wildcards never match a leading dot, as in glob(3) without `GLOB_PERIOD`. Character classes, braces, escapes and `**` inside a name fail. Globs are matched with exact letter case. | Excluded files are neither compiled nor copied. Matching less than XcodeGen only scans more, and binaries are found even when a glob differs. If XcodeGen ignores case on a case-insensitive volume, it excludes more than the checker, which again only scans more. |
  | Resource catalogues (`.xcassets`, `.icon`, `.xcstrings`), in targets and packages | Walked; contents count only for the prebuilt-code, link and special-file checks. | `actool` and the string catalogue compiler process them; Swift inside is never compiled and a nested manifest is not at the bundle root. |
  | Extension filters (file-type allowlist) | Every visited file gets the prebuilt-code check first. Then, outside folder references, `buildPhase: none` entries, excluded paths and catalogues, each file of a shipped target must be `.swift`, `.DS_Store` or one of the inert data types `.json`, `.strings`, `.xcstrings`, `.entitlements` and `.xcprivacy`, in every build phase, inside wrappers such as `.bundle` and `.lproj`, and inside directories added as `type: file`. Any other file fails as unscanned, including files with no extension and an extension in another letter case (`.SWIFT`). `.swift` counts as compiled Swift only in the sources or default phase, and `PrivacyInfo.xcprivacy` counts as the manifest only under the rule below. Outside catalogues, a linked package's `Sources` may hold only Swift. | The data types are exactly the types the real targets hold there, and none can call these APIs or make Xcode generate code. A new type (lex, yacc, MIG, Metal, Core Data, Core ML, Intents, Interface Builder, `.plist` and so on) fails until a maintainer confirms Xcode neither compiles it nor generates code from it and adds it to `SOURCE_DATA_EXTENSIONS`. Folder references, `buildPhase: none` entries and excluded files are neither compiled nor processed, and catalogues are processed only by `actool` or the string catalogue compiler. |
  | `buildPhase` | `sources` and the default compile Swift. `resources` copies files to the bundle root. `headers` and `copyFiles` compile nothing and never supply the manifest. `none` and `type: folder` are references (above). Other phases fail. | XcodeGen's phases are exactly these; unknown ones fail closed. |
  | `type` | `file`, `group` and `folder` are modelled; anything else, such as `syncedFolder`, fails. A directory added as `type: file` is copied as one folder, so a manifest inside it is not the bundle's manifest. Its Swift still counts, which can only over-declare. | Unknown types fail closed. |
  | Bundle manifest rule | Only a manifest copied flat to the bundle root counts: from the default or resources phase, not excluded, not in a catalogue, and not below a directory whose name has an extension (`.lproj`, `.bundle` or another wrapper). | Manifests elsewhere are copied into subfolders, which Apple does not read as the app's manifest. Zero manifests fail the check. |
  | `optional` | A missing optional path is skipped; an existing one is fully scanned. A missing non-optional path fails in every build phase, as in XcodeGen's own spec validation. Every `sources` and package path must match the names on disk in letter case. | A missing path has nothing to copy or compile. Failing on a missing resources path means a resource that exists only on the release machine cannot hide prebuilt code from CI. The case check makes a wrong-case path fail on macOS and Linux alike, instead of being compiled on macOS and skipped as missing on Linux CI. |
  | Unmapped-file walk prunes `*.xcodeproj`, `DerivedData` and `build` | Only for finding Swift files under `apps/apple` that no target compiles; Swift in catalogues is not counted there either. | Target walks never prune, so a target entry inside one of those paths is still fully scanned. |
  | Test targets | Not checked for categories, file types, prebuilt code or build settings. Their sources are still walked for coverage, so links, special files and unsupported entries fail there too. | Test bundles are not shipped. |
  | Target `target:` and `sdk:` dependencies | Embedded app targets are checked as their own targets. A `target:` must be defined in `project.yml`, and a shipped target may depend only on shipped targets. An `sdk:` must be a bare `.framework` or `.tbd` name from the SDK. Any other dependency type or key, a dependency naming more than one kind or a non-string, a cross-project or undefined target, and an `sdk:` path fail. | Apple's own SDK code is not declared by the app, and test bundles never ship. |
  | Package root other than `Sources` | Not scanned. `Package.swift` must fit the strict grammar above, and its labels, members and strings must be on the Package.swift allowlist below, which rejects custom `path:` or `sources:`, binary, executable, plugin, macro and system-library targets, unsafe and other settings, package dependencies and every path string. `Package@swift-*.swift` manifests and the other SwiftPM source roots (`Source`, `src`, `srcs`) fail. | Only `Sources/<target>` is compiled or bundled when those are absent. |
  | Package `exclude:` and `resources:` | Not on the Package.swift allowlist, so they fail. All of `Sources` is scanned regardless. | Over-scans, and no path string can reach outside `Sources`. |
- **Native-code formats.** Prebuilt code is found by magic bytes where the
  format has them and by name otherwise:

  | Format | Detection |
  |---|---|
  | Mach-O, 32- and 64-bit, both byte orders (executables, dylibs, bundles, `.o`) | Magic `feedface`, `cefaedfe`, `feedfacf`, `cffaedfe`. |
  | Universal (fat), 32- and 64-bit, both byte orders | Magic `cafebabe`, `bebafeca`, `cafebabf`, `bfbafeca`. |
  | `ar` and thin archives (`.a`) | Magic `!<arch>\n` and `!<thin>\n`, and the `.a` extension. |
  | LLVM bitcode and the bitcode wrapper | Magic `BC\xC0\xDE` and `0x0B17C0DE` (bytes `de c0 17 0b`). |
  | Binary Swift modules | Magic `e29ca80e`, and the `.swiftmodule` extension on a file or directory. |
  | Text-based stubs and module interfaces | The `.tbd` and `.swiftinterface` extensions. |
  | Code bundles | The `.framework`, `.xcframework`, `.app`, `.appex` and `.xpc` directory names. |
  | Libraries and objects without magic | The `.dylib`, `.so`, `.o` and `.a` extensions. |
  | Module maps (`.modulemap`, `module.map`), API notes, prefix headers (`.pch`), LLVM IR (`.ll`), C-family and assembly sources | Fail as unscanned files under the file-type allowlist, like every type outside it. |
  | `.bundle`, `.plugin`, `.kext` and similar | Not by name, because `Settings.bundle` and resource bundles are data. An executable inside is Mach-O and is caught by magic. |
  | Left out: ELF | dyld cannot load it on Apple platforms (a `.so` name still fails). |
  | Left out: WebAssembly | Not native: it needs a runtime the app would have to ship (as Swift or a framework, both checked) and can call only host imports. |
  | Left out of magic detection: scripts and JavaScript | Interpreted; any bridge to these APIs is Swift, which is scanned. In a target's sources they also fail the file-type allowlist; only folder references and excluded paths may hold them. |
  | Left out: zip, tar and other containers | Code inside could run only after extraction and a run-time `dlopen`, which code signing blocks; this is the run-time limitation below. |
  | Left out of magic detection: `.metal` and `.metallib` | GPU code, which cannot call system APIs. In a target's sources they also fail the file-type allowlist. |
  | Left out: precompiled modules and headers (`.pcm`, `.gch`) | Usable only through compiler flags, which fail the check. |
  | False positives (safe) | Java class files share `cafebabe`, and a `.dSYM`'s DWARF file is Mach-O, so both fail. |
- **Manifest parsing.** Manifests are read with a strict XML property list
  parser that keeps plist value types, so each key must have its documented
  type:
  - `NSPrivacyTracking` must be the boolean `<false/>`;
  - `NSPrivacyTrackingDomains` and `NSPrivacyCollectedDataTypes` must be
    empty `<array>`s;
  - `NSPrivacyAccessedAPITypes` must be an `<array>` of `<dict>`s;
  - each category and each reason must be a `<string>`, and the reasons must
    sit in an `<array>`.

  Privacy manifests use no other value types, so `<integer>`, `<real>`,
  `<date>` and `<data>` are rejected rather than read as strings. Only the
  four documented top-level keys and the two keys of each accessed-API entry
  are allowed. String and key text keeps its whitespace and is compared
  exactly, as Apple compares it. The five predefined XML entities and numeric
  character references are decoded, as Apple's parser decodes them.
  Comments between elements, a byte-order mark, a missing XML declaration,
  the older `Apple Computer` DOCTYPE, and `<false></false>` or
  `<array></array>` forms are accepted, because Apple reads them the same
  way.
- **project.yml and Package.swift parsing.** XcodeGen reads `project.yml`
  with Yams (libyaml, with YAML 1.1 types) and then replaces `${NAME}` with
  environment variables. The checker reads a strict subset and fails on
  anything Yams or XcodeGen could read differently:
  - **Modelled exactly:** one document of block mappings and sequences
    indented with spaces; comments after a space; plain, single-quoted
    (`''`) and double-quoted scalars on one line, where double quotes decode
    only `\\` and `\"`; one-line flow sequences of scalars, including quoted
    items that contain commas; the empty flow mapping `{}`; CRLF line ends
    and a leading byte order mark; and `|` or `>` block scalars (optionally
    with `-` or `+`) as a `script` value. Keys are read as Yams reads them:
    a quoted key may hold `: `, and a key starting with `-` and no space
    (`-KEY:`) is a plain key, not a sequence item.
  - **Types:** plain values keep their YAML 1.1 types. `yes`, `no`, `on`,
    `off`, `true` and `false` are booleans; `~` and `null` are null; numbers
    include octal `017`, hex, binary and sexagesimal `1:30`. Wherever the
    checker needs a string (a sources `path`, `type` or exclude, a
    `platform`, a dependency or package path), any other type fails.
    `optional` counts only as the boolean `true`, so a quoted `"true"` is
    not optional. Mappings have no prototype, so `__proto__`, `constructor`
    and `toString` are ordinary keys.
  - **Fail closed:**
    - double-quoted escapes other than `\\` and `\"` (such as `\u005f`);
    - tabs, and characters outside printable ASCII, including a lone CR,
      NEL, line and paragraph separators, and a byte order mark after the
      start of the file;
    - document markers (`---`, `...`) and directives (`%YAML`, `%TAG`);
    - anchors, aliases, tags, merge keys (`<<`), value keys (`=`), complex
      keys (`? `) and duplicate keys;
    - multi-line plain or quoted scalars and continuation lines;
    - flow collections that are multi-line or nested, have empty items or
      trailing commas, or hold `[`, `]`, `{`, `}`, `#` or `:` in a plain
      item; flow mappings other than `{}`;
    - a plain scalar that starts with an indicator or contains `: `;
    - block scalar indentation indicators, and block scalars outside
      `script`;
    - plain keys that YAML 1.1 reads as null, a boolean or a number (such as
      `NO:`), and timestamp values;
    - `${...}` in any key, or in a value other than `script`;
    - `$` in a sources path or exclude (XcodeGen's `$platform` and
      similar), and a `platform` list (multi-platform targets);
    - a dependency that does not name exactly one of `target`, `package`
      or `sdk` as a string;
    - a package entry with keys other than `path`, `group` and
      `excludeFromProject`.
  - **Package.swift:** after comments are removed, each linked manifest
    must be `import PackageDescription` and one `let package = Package(...)`
    built only from argument labels, simple string literals, array
    literals, and `.member` or `.member(...)` values. These fail: raw
    strings (`#"..."#`), escapes and `\u{...}`, interpolation, multi-line
    `"""` strings, `#if`, variables, helper functions, type-qualified
    members (`Target.target`), `.map`, closures, operators, extra imports
    and further statements. Comments inside calls, backtick-escaped names
    and trailing commas are accepted. On top of the grammar, the manifest's
    argument labels, `.member` names and string literals must be on the
    Package.swift allowlist, which holds exactly what the four real
    manifests use: the labels `name`, `platforms`, `products`, `targets`,
    `dependencies`, `swiftSettings` and `swiftLanguageModes`; the members
    `.iOS`, `.macOS`, `.tvOS`, `.visionOS`, `.watchOS`, `.v27`, `.library`,
    `.target`, `.testTarget`, `.swiftLanguageMode` and `.v6`; and strings
    that are plain names (a letter or `_`, then letters, digits, `_` and
    `-`). Everything else fails with its `Package.swift:<line>`, including
    `path:`, `sources:`, `resources:`, `exclude:`, `linkerSettings:`,
    `cSettings:`, `.define`, `.unsafeFlags`, `.executableTarget`,
    `.binaryTarget`, `.plugin`, `.macro`, `.systemLibrary`, product and
    package dependencies, dynamic library products (`type:`) and any string
    with a `/`, `.` or space. When a real manifest gains a label, member
    or string form, the maintainer confirms that it cannot add code or link
    inputs, then extends the allowlist. The checker reads only
    `Package.swift` and `Sources`, so a version-specific
    `Package@swift-*.swift` manifest (which SwiftPM prefers) and the other
    SwiftPM source roots (`Source`, `src`, `srcs`, or `Sources` in another
    case) also fail.
- **project.yml allowlist.** After parsing, `project.yml` is checked
  against an allowlist (`PROJECT_SHAPE` and `TARGET_SHAPE` in the checker)
  rather than a list of known-bad keys. The allowlist holds exactly the keys
  the real file uses (plus the `sdk:` dependency, explained below), on every target including test targets, and gives
  each one a value shape (string, list or mapping) where the checker relies
  on it. Any other key fails with its `apps/apple/project.yml:<line>`. These
  are the allowed keys:

  | Where | Key | Why it is allowed |
  |---|---|---|
  | Top level | `name` | The project name. |
  | Top level | `options` | Only the five keys below. |
  | Top level | `configs` | Configuration names and their `debug` or `release` presets; their build settings are checked under `settings`. |
  | Top level | `packages` | Each linked package is resolved as described above: a local `path`, with only `group` and `excludeFromProject` beside it, and its `Package.swift` and `Sources` checked. |
  | Top level, target | `settings` | Only `base` and `configs` (a mapping of configuration names to build settings). In the project and every shipped target, each build setting must be on the build-setting allowlist below and match its value rule. |
  | Top level | `targets` | Each target against the target keys below. |
  | Top level | `schemes` | Only `build.targets` (which targets each action builds) and `test` with `gatherCoverageData`, `testPlans` (`path`, `defaultPlan`) and `targets` (a list of names). These choose what to build and test; products still come from the targets. |
  | `options` | `bundleIdPrefix`, `deploymentTarget`, `developmentLanguage`, `knownRegions`, `createIntermediateGroups` | Identifiers, minimum OS versions, the development region, localisations and navigator groups. None adds a file or a build phase. |
  | Target | `type` | Must be `application` (the only shipped type the real file uses) or a test type. Other types fail, including app extensions, watch app wrappers (`application.watchapp2`), on-demand-install apps and frameworks, because the checker does not model how they are embedded or what they link. |
  | Target | `platform`, `supportedDestinations`, `deploymentTarget` | One platform name (lists and `$platform` fail), the destinations that build the same sources, and the minimum OS version. |
  | Target | `sources` | Every entry is modelled: its keys, `type`, `buildPhase`, `excludes` and `optional`, as above. |
  | Target | `dependencies` | Each entry may hold only the dependency keys below. |
  | Target | `postBuildScripts` | Each entry may hold only `name`, `script` (an inline string), `basedOnDependencyAnalysis`, `inputFiles` and `outputFiles`. XcodeGen adds these phases last, after the compile, link, copy and embed phases but before code signing, so a script could still replace the executable or copy a dylib into the app. Their inline text is reviewed by hand, with binary inspection as the cross-check (a limitation below); script files (`path`) and other shells fail. |
  | Dependency | `target` | Must name a target defined in `project.yml`; cross-project `Project/Target` names fail. A shipped target may depend only on shipped targets. An embedded app is checked as its own target. |
  | Dependency | `package` | A local package whose `Sources` are scanned. |
  | Dependency | `sdk` | Must be a bare `.framework` or `.tbd` name, which XcodeGen looks up in the SDK (Apple's own code). A path or any other file fails. The real file has no `sdk:` dependency. The key stays on the allowlist because this exact model can only link Apple's SDK code, whose required-reason use the app does not declare. |
  | Dependency | `product`, `embed`, `destinationFilters` | Pick a library product of a scanned package, copy a target's product (checked as its own target), and narrow the platforms that link the dependency. |

  Some keys are rejected because they are not on the allowlist. Each of
  these has a fixture:
  - top-level `include`, `projectReferences`, `targetTemplates`,
    `schemeTemplates`, `aggregateTargets`, `fileGroups`, `localPackages`,
    `configFiles`, `settingGroups`, `attributes` and `breakpoints`;
  - `options.preGenCommand` and `options.postGenCommand`;
  - target `templates`, `preBuildScripts`, `postCompileScripts`,
    `configFiles`, `scheme`, `buildToolPlugins`, `buildRules`, `info`,
    `entitlements`, `legacy` and `attributes`;
  - dependency `link`, `weak`, `codeSign`, `copy` and `root`;
  - settings `groups` and flat (unstructured) settings;
  - scheme pre- and post-actions, `run`, `profile`, `analyze` and
    `archive` actions, and build options.

  The repository has no `.xcconfig` files, so `configFiles` fails closed
  rather than being scanned. Pre-build and post-compile scripts fail,
  because they run before or between the compile phases and could generate
  or rewrite sources. **Maintenance:** when the real `project.yml` gains a
  key, this check fails at that line. The maintainer then confirms that the
  key cannot add code, link inputs or bundled files, or models it in the
  checker with fixtures. They then add it to the allowlist, with a comment,
  and to this table.
- **Build-setting allowlist.** Build settings in the project's `settings`
  and in every shipped target's `settings` (in `base` and in every entry of
  `configs`) are checked against `BUILD_SETTINGS`, an exact-name allowlist.
  It holds exactly the 37 setting names the real file sets at those levels,
  with no prefix families, so `SWIFT_VERSION` does not admit `SWIFT_EXEC` or
  `SWIFT_INCLUDE_PATHS`. A conditional key, `NAME` followed by one or more
  `[sdk=...]` or `[arch=...]` conditions, is matched on `NAME` and gets the
  same value rule. Any other key spelling, such as `[config=Debug]` or a
  space before the condition, fails. Every other setting fails with its
  `apps/apple/project.yml:<line>`, including linker, compiler, search-path,
  header, tool-path and plugin settings: `OTHER_LDFLAGS`, `WARNING_LDFLAGS`,
  `PRELINK_LIBS`, `LD`, `LDPLUSPLUS`, `SWIFT_EXEC`, `SWIFT_INCLUDE_PATHS`,
  `SWIFT_PLUGIN_SERVER_PATH`, `HEADER_SEARCH_PATHS`,
  `FRAMEWORK_SEARCH_PATHS`, `LIBRARY_SEARCH_PATHS`, `OTHER_CFLAGS`,
  `GCC_PREPROCESSOR_DEFINITIONS`, `SWIFT_OBJC_BRIDGING_HEADER`,
  `GCC_PREFIX_HEADER`, `EXCLUDED_SOURCE_FILE_NAMES`, an unknown setting and
  the unmodelled `SWIFT` and `INFOPLIST_KEY_NSAppTransportSecurity`, each
  with a fixture. Values may not refer to other settings (`$(...)` or `${...}`),
  except `$(inherited)` where the rule below allows it. Every value is
  checked against its rule:

  | Setting | Value rule | Why it is allowed |
  |---|---|---|
  | `CURRENT_PROJECT_VERSION`, `MARKETING_VERSION` | A number, or up to three dot-separated integers. | Build and version numbers written to Info.plist. |
  | `DEVELOPMENT_TEAM` | Ten upper-case letters or digits. | Signing team ID. |
  | `CODE_SIGN_STYLE` | `Automatic` or `Manual`. | How signing identities are chosen. |
  | `CODE_SIGN_ENTITLEMENTS` | `""`, or a relative path to an existing regular `.entitlements` file under `apps/apple`: no `..`, `$`, `~`, hidden or absolute paths, no symbolic link on the way, and the exact letter case on disk. | Entitlements grant capabilities and are not code. `pnpm check:apple-icloud-gate` checks their content. |
  | `PRODUCT_BUNDLE_IDENTIFIER`, `INFOPLIST_KEY_WKCompanionAppBundleIdentifier` | A reverse-DNS bundle identifier. | Identifiers. |
  | `PRODUCT_NAME` | Letters, digits, `_` and `-`. | Product, executable and module name. |
  | `SWIFT_VERSION` | A version number. | Swift language mode. |
  | `SWIFT_STRICT_CONCURRENCY` | `minimal`, `targeted` or `complete`. | Concurrency diagnostics only. |
  | `IPHONEOS_DEPLOYMENT_TARGET`, `MACOSX_DEPLOYMENT_TARGET`, `TVOS_DEPLOYMENT_TARGET`, `XROS_DEPLOYMENT_TARGET` | A version number. | Minimum OS versions. |
  | `TARGETED_DEVICE_FAMILY` | Device family numbers 1 to 7, comma-separated, or one integer. | Which devices the build runs on. |
  | `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD`, `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD` | `YES`, `NO` or a YAML boolean. | Whether the iOS build runs unchanged on a Mac or Apple Vision Pro. |
  | `SWIFT_ACTIVE_COMPILATION_CONDITIONS` | `$(inherited)` and condition names, as a string or a list of strings. | Conditions only select `#if` branches, and every branch is scanned. |
  | `OTHER_SWIFT_FLAGS` | A string or a list of strings holding only `$(inherited)` and `-DNAME` conditions (a split `-D NAME` fails with a hint to write `-DNAME`). | Same as compilation conditions. Any other flag could add a search path, plugin or linker input. |
  | `ENABLE_USER_SCRIPT_SANDBOXING`, `SWIFT_EMIT_LOC_STRINGS`, `LOCALIZATION_PREFERS_STRING_CATALOGS` | `YES`, `NO` or a YAML boolean. | Build-process switches that add no inputs: script sandboxing, string extraction and the export format. |
  | `ASSETCATALOG_COMPILER_APPICON_NAME`, `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`, `INFOPLIST_KEY_CFBundleIconName` | An asset name: letters, digits, spaces and `&._-`. | Which icon and accent colour the asset catalogue compiler uses. |
  | `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS` | `YES`, `NO` or a YAML boolean. | Whether alternate icons are compiled too. |
  | `GENERATE_INFOPLIST_FILE` | `YES`, `NO` or a YAML boolean. | Generates Info.plist from the `INFOPLIST_KEY_` settings. |
  | `INFOPLIST_FILE` | A relative path to an existing regular `.plist` file under `apps/apple`, with the same path rules as entitlements (never `""`). | Info.plist is data. |
  | `INFOPLIST_KEY_CFBundleDisplayName` | Letters, digits, spaces and `&._-`. | Home-screen name. |
  | `INFOPLIST_KEY_LSApplicationCategoryType` | A `public.app-category.*` type. | App Store category. |
  | `INFOPLIST_KEY_UIBackgroundModes` | Non-empty, space-separated lower-case mode names. | Data. `pnpm check:apple-icloud-gate` checks that `remote-notification` appears only in `DebugCloudKit`. |
  | `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad`, `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` | Non-empty, space-separated `UIInterfaceOrientation` names. | Supported orientations. |
  | `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption`, `INFOPLIST_KEY_UILaunchScreen_Generation`, `INFOPLIST_KEY_WKApplication`, `INFOPLIST_KEY_WKRunsIndependentlyOfCompanionApp` | `YES`, `NO` or a YAML boolean. | Info.plist flags: export compliance, the generated launch screen and watch app flags. |

  Test-target settings are not checked, because test bundles never ship.
  `BUNDLE_LOADER` and `TEST_HOST` appear only on `CanadianHamTests`, so they
  are not on the allowlist. **Maintenance:** when the real `project.yml`
  gains a setting at the project or shipped-target level, this check fails
  at that line. The maintainer then confirms that the setting cannot add
  code or link inputs (or models its value with a rule and fixtures), and
  adds it to `BUILD_SETTINGS`, with a comment, and to this table.
- **Path letter case.** Every `sources` path and package path is compared
  with the names on disk, one component at a time, and fails if it differs
  only in letter case. macOS volumes usually ignore case and Linux CI does
  not. Without this check, a wrong-case `optional` path would be found and
  compiled by Xcode on macOS but skipped as missing on Linux, and a
  non-optional one would pass on macOS and fail on Linux. A missing optional
  path still passes on both.
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
  A backtick-escaped identifier is lexed as one token, so a raw identifier
  containing `//` does not start a comment. After lexing, each escaped plain
  identifier is rewritten as the bare name, keeping offsets and line numbers.
  So ``FileAttributeKey.`creationDate` ``, `` `UserDefaults`.standard ``,
  `` `stat`(path, &buf) `` and ``.`systemFreeSize` `` match like their plain
  spellings in every category. A string literal that holds exactly
  `"creationDate"`, `"modificationDate"`, `"stat"`, `"systemFreeSize"` or
  `"systemSize"` counts. The other listed names, such as `"systemUptime"`,
  `"fstat"` and `"NSURLVolumeTotalCapacityKey"`, count anywhere in a string.
  This covers key-value coding, selectors, `@_silgen_name` and
  `URLResourceKey(rawValue:)`.
- **Lexing (PR #1064 round 8).** Swift sources are read as swiftc reads
  them, checked against swiftc 6.4.2 (`xcrun swiftc -typecheck` and
  compiled probes):
  - The file must be valid UTF-8, as swiftc requires even inside comments.
    A leading byte order mark is skipped.
  - CR, LF and CRLF each end one line, so a `//` comment ends at a lone CR
    and diagnostics count lines as Swift does. Swift does not end a line,
    or a `//` comment, at VT, FF, NEL, U+2028 or U+2029. Those, NUL, DEL and
    the other C0 controls (everything except tab, LF and CR) fail closed
    anywhere in the file; write them as `\u{...}` escapes in a string.
  - Outside comments, string literals and regex literals only printable
    ASCII is accepted, including inside backticks. Swift does not normalise
    identifiers: an NFD spelling, a KELVIN SIGN `K` or a zero-width
    character makes a different identifier, so such code cannot name an
    API, but failing closed keeps the lexer's whitespace and operator rules
    exact. The real tree has no non-ASCII code.
  - String literals are also decoded and matched a second time. The decoded
    escapes are `\0`, `\\`, `\t`, `\n`, `\r`, `\"`, `\'` and `\u{...}` with
    1 to 8 hex digits (a Unicode scalar, not a surrogate), after the escape
    delimiter of the literal (`\` plus as many `#` as a raw string has, so
    in `#"...\u{55}..."#` the escape stays literal and `\#u{55}` is
    decoded). A `\` before a line break in a `"""` literal joins the lines.
    Any other escape fails closed, as swiftc rejects it.
  - Multi-line literals drop the first and last line break and the leading
    blanks of each line, which may strip more than Swift does but never
    less.
  - An interpolation that holds only string literals, `+`, parentheses and
    whitespace is inlined (`"system\("Uptime")"`). Any other interpolation
    becomes a boundary no name can span.
  - String literals joined by `+` are matched as one string
    (`"system" + "Uptime"`), and the exact-name rule applies to the whole
    chain (`"creation" + "Date"`). From each literal's opening quote the
    join looks back over whitespace, parentheses and comments to one `+`,
    then on to the closing quote of an earlier literal. Anything else ends
    the chain, so a cast (`("system" as String) + "Uptime"`) or an
    initialiser or other call around the literal after the `+`
    (`"system" + String("Uptime")`) is a name computed at run time (see
    Limitations). Because the look-back skips a closing `)`, a call around
    the literal before the `+` is joined: `f("system") + "Uptime"` and
    `String("system") + "Uptime"` are matched as `systemUptime`. For names
    matched anywhere in a string this can only add matches. For the
    exact-name rule it can hide one case: a call whose last argument is
    written with escapes and is followed by `+` and a literal
    (`k("st\u{61}t") + "x"` is read as `"statx"`). The plain spelling
    `k("stat") + "x"` is still matched by the raw scan. A decoded NUL ends
    the string for the exact-name rule, as C strings do
    (`dlsym(handle, "stat\0")`).
  - The three characters whose canonical decomposition is ASCII (U+212A
    KELVIN SIGN, U+037E and U+1FEF) count as `K`, `;` and `` ` `` inside
    strings, because Swift's `String` `==` treats them as equal.
  - Decoded matches are added to the raw matches and reported on the line
    of their first character.
- **What fails.** The check fails in any of these cases:
  - a shipped target uses a category its own manifest does not declare;
  - a manifest declares a category its target does not use;
  - a reason is unknown, belongs to another category, is SDK-only, is empty
    or is duplicated;
  - a category is unknown or duplicated;
  - a target bundles anything other than exactly one manifest;
  - a manifest does not set `NSPrivacyTracking` to `false`, or does not have
    empty `NSPrivacyTrackingDomains` and `NSPrivacyCollectedDataTypes` arrays;
  - a manifest value has the wrong plist type, or the manifest has an
    unknown top-level or entry key, a duplicate key, a key with no value, an
    unknown entity, or anything outside the XML subset above: a binary,
    JSON, OpenStep or non-UTF-8 plist, a CDATA section, a comment inside a
    key or string, a processing instruction other than the XML declaration,
    an attribute on a value element, another DOCTYPE, a missing `<plist>`
    root, or content after `</plist>`;
  - a shipped target or linked package contains a file type outside the
    file-type allowlist (pruning table above), such as C, Objective-C, C++
    or assembly sources or headers, module maps, API notes, Metal, lex,
    yacc or MIG files, Core Data models or a `.plist` in the sources,
    because only Swift is scanned and only the listed data types are known
    to be inert;
  - a shipped target's sources, including its folder references,
    `buildPhase: none` entries, excluded paths and resource catalogues, or a
    linked package's `Sources` (including its catalogues) contain prebuilt
    code in any format in the native-code table above;
  - a symbolic link appears under a scanned directory (including a folder
    reference, an excluded path or a catalogue), or is a `project.yml`
    sources path, a package directory or its `Sources`, or any directory
    between the repository root and one of those (the checker does not
    follow links);
  - a scanned path or entry path is a special file (a FIFO, socket or
    device), which cannot be scanned;
  - a sources path in any build phase does not exist and is not marked
    `optional`;
  - a Swift file under `apps/apple` is compiled by no target;
  - comment stripping could hide code: an unterminated block comment or
    extended regex literal, or a comment marker straight after `\` (an
    escaped slash in a regex literal the checker could not delimit);
  - a Swift file or `Package.swift` is not valid UTF-8, holds a control
    character other than tab, LF and CR, or a NEL, U+2028 or U+2029, has
    non-ASCII outside comments, string literals and regex literals, or uses
    a string escape the lexing step above does not decode.
- **Unsupported constructs.** It also fails on XcodeGen constructs that can
  add code it does not scan:
  - sources keys it does not model, including per-file `compilerFlags`;
  - source `type`s other than `file`, `group` and `folder` (such as
    `syncedFolder`), `buildPhase`s other than `sources`, `resources`,
    `headers`, `none` and a `copyFiles` mapping, and exclude globs with
    character classes, braces, escapes or `**` inside a name;
  - any `project.yml` key outside the allowlist above, reported with its
    file and line, and an allowlisted key whose value has the wrong shape;
  - a `target:` dependency on a target that `project.yml` does not define
    (including cross-project `Project/Target` names), a shipped target
    depending on a test target, and an `sdk:` dependency that is not a bare
    `.framework` or `.tbd` name;
  - a `sources` or package path that differs only in letter case from the
    names on disk, and a `sources` or package path outside the modelled
    form: leading `../` components, then non-empty names other than `.`
    and `..` (absolute, `~`, empty, trailing-slash, `.` and later `..`
    components fail);
  - any project or shipped-target build setting outside the build-setting
    allowlist above, or with a value outside its rule. That covers bridging
    or prefix headers, header, library, framework and Swift include search
    paths, module map files, linker and libtool flags, compiler and tool
    paths, and plugin paths;
  - `OTHER_SWIFT_FLAGS` other than `$(inherited)` and `-D` conditions. A
    condition split from its name (`-D FOO`) is rejected with a message to
    use the `-DFOO` form.

  It also fails on remote, binary or dynamic packages, on any Package.swift
  label, member or string outside its allowlist (above), and on target
  types other than `application` and the test types. YAML and Swift syntax
  outside the parsers' subsets fails as described under the parsing step
  above.
- **Self-test.** `pnpm test:apple-required-reasons` runs the fixtures. They
  include comment-only mentions, a string containing `//` followed by real
  code, excluded and test-only files, unlinked packages and package tests,
  `getattrlist` counting for both File timestamp and Disk space, C-function
  references, module-qualified spellings in every category including
  `@SwiftUI.AppStorage`, spellings split across lines, `stat`-named Swift
  identifiers that must not count, and regex literals containing comment
  markers. Further fixtures cover backtick-escaped names in every category
  (with division after an escaped name), key paths, type aliases, string-based
  access, hidden files and directories, symbolic links, folder references
  holding plain data (which pass) or prebuilt code (which fails), the plist
  type and syntax cases in the table below, and the fail-closed cases above.
  Round 6 fixtures cover every magic value and name in the native-code
  table; Mach-O, universal-binary and symbolic-link payloads inside target
  and package asset catalogues, excluded paths and a disguised `.DS_Store`;
  catalogue Swift, headers and nested manifests (with `.lproj` and
  `.bundle` manifests and a real `.DS_Store`) that pass; manifests that
  are not the bundle manifest (copyFiles, a `type: file` directory,
  `.lproj` and `.bundle`); hidden files that exclude wildcards do not
  match; unsupported globs, types and build phases; FIFOs inside a walk and
  as an entry path; and `..` in Package.swift. Round 7 fixtures cover each
  YAML and Package.swift case in the parsing step: an escaped build-setting
  key, quoted keys that are still caught, a `__proto__` target and a
  `toString` package, every fail-closed YAML construct, YAML 1.1 types where
  strings are needed, multi-kind dependencies, `$platform` and platform
  lists, and every rejected Package.swift construct. Pass fixtures cover
  the modelled YAML (with and without a byte order mark and CRLF), quoted
  commas in a flow sequence and a Package.swift with comments, backticks and
  trailing commas. Round 7b fixtures reject each key listed under the
  allowlist at its file and line, including `__proto__`, `constructor` and
  `toString`. They also reject non-string, non-list and non-mapping values;
  undefined, cross-project and shipped-to-test target dependencies; `sdk:`
  paths and non-SDK files; and wrong-case sources and package paths. Pass
  fixtures use every allowlisted key, a test target that depends on a test
  target, and a missing optional path. Round 7c fixtures reject each
  build setting named in the build-setting allowlist step, in `base`,
  project and target `configs` and conditional variants, plus unmodelled
  condition forms, a bad value for every value rule (including
  `$(...)` references and a conditional `OTHER_SWIFT_FLAGS` with a forbidden
  flag), and entitlements or Info.plist paths that are missing, a directory,
  a symbolic link, behind a linked directory or in the wrong case. Further
  fixtures reject each Package.swift label, member and string form outside
  its allowlist, file types outside the file-type allowlist (lex, yacc, MIG,
  Metal, C++, Interface Builder, Core ML, Intents, Core Data, a file without
  an extension, `.SWIFT`, a `.plist` in sources, a script in a resources
  phase and a file inside a `type: file` bundle), unmodelled target types,
  spec paths outside the modelled form and missing resources and headers
  paths. Pass fixtures use every allowlisted build setting, unchecked
  test-target settings, a real-style Package.swift, and the inert data
  types beside excluded files and folder references. Round 8 fixtures cover
  the lexing step: CR-only, CRLF and mixed line endings (including a
  CR-only Package.swift), a leading byte order mark, each control and
  line-separator character, invalid UTF-8, non-ASCII code (a zero-width
  character, an NFD name, a KELVIN SIGN, NBSP, a stray byte order mark and
  backticks), `\u{...}` escapes in plain and raw strings, a literal KELVIN
  SIGN in a key, literal interpolations, `+` joins, multi-line continuations
  (with `##` delimiters and trailing blanks), exact names built by escapes,
  joins, `\0`, multi-line literals and interpolations, every unsupported
  escape, and selector, key-path, `#if` and `#sourceLocation` forms. Pass
  fixtures cover non-ASCII comments, strings and regex literals, raw
  strings that keep `\u{55}` literal, non-literal interpolations, and
  blanks that Swift keeps before an exact name (in a single-line literal,
  escaped, or after an interpolation).
- **Bypass classes.** Each syntactic way a source could reach a listed API
  without the checker seeing it is covered or recorded here:

  | Class | Status |
  |---|---|
  | Comments, strings and regex literals hiding code | Covered by fixtures: comment-aware lexer, literals scanned; ambiguous cases fail. |
  | Module qualification, attribute forms, line breaks between tokens | Covered by fixtures: whole-file matching with optional qualifiers. |
  | Function references instead of calls (`Darwin.fstat`, `= statfs`) | Covered by fixtures. Bare `stat` as a value is a limitation (below). |
  | Backtick-escaped identifiers | Covered by fixtures: normalised after lexing. |
  | Key paths (`\URLResourceValues.creationDate`, `\.volumeAvailableCapacity`) | Covered by a fixture: the key path still names the member. |
  | `typealias` or `let` aliases of a type or instance | Covered by a fixture: the alias declaration names the type, and members such as `.systemUptime` are matched by name. |
  | String-based access with a literal name (KVC, `NSSelectorFromString`, `@_silgen_name`, `URLResourceKey(rawValue:)`) | Covered by a fixture: string literals are scanned. |
  | String-based access with a name built at run time (`let p = "NSUser"; p + "Defaults"`, `+=`, `joined()`, `String(format:)`, an interpolation of a variable or call, computed KVC keys, `dlsym`, `perform` with a computed selector) | Limitation: the value depends on code the scanner does not evaluate. Binary inspection is the cross-check. None exists in the tree. Joins of literals only are detected (see the Swift lexing rows below). |
  | Wholesale attribute reads that never name a listed key (iterating `attributesOfItem(atPath:)` or `attributesOfFileSystem(forPath:)` results, `resourceValues` with keys from a variable) | Limitation: `attributesOfItem(atPath:)` is not itself on Apple's list, so only the listed keys read from its result count. Review by hand. None exists in the tree. |
  | `#if` branches | Not a bypass: `#if` is not evaluated, so every branch is scanned and counts (over-declaration). |
  | C, Objective-C, C++, assembly, module maps, API notes | Fail closed. |
  | Prebuilt code (frameworks, libraries, Mach-O files) in sources or package `Sources` | Fail closed. |
  | Native-code formats other than thin Mach-O (universal 64-bit, archives, bitcode, Swift modules and interfaces, text stubs, app and XPC bundles) | Fail closed with fixtures for every magic value and name in the native-code table. Formats left out are listed there with the reason. |
  | Prebuilt code or links inside resource catalogues (`.xcassets`, `.icon`, `.xcstrings`) in a target or package | Fail closed with fixtures: catalogues are traversed, but their Swift files, headers and nested manifests are not counted. |
  | Prebuilt code or links inside excluded paths, or hidden files an exclude glob would miss | Fail closed with fixtures: excluded paths are still scanned for binaries and links, and wildcards never match a leading dot, so a glob that differs from XcodeGen's can only scan more. Glob syntax the checker does not model fails. |
  | A nested `PrivacyInfo.xcprivacy` standing in for the bundle manifest | Fail closed with fixtures: only a manifest copied flat to the bundle root counts. |
  | Special files (FIFOs, sockets, devices) | Fail closed with fixtures. |
  | Prebuilt code in folder references or `buildPhase: none` entries, which are copied or listed but not compiled | Fail closed with fixtures: the whole folder is scanned, including asset catalogues; a folder of plain data passes, and its Swift files and nested manifest are not counted. |
  | Privacy manifest values of the wrong plist type (`<data>`, `<date>`, `<integer>` or `<real>` codes, a `<dict>` or `<array>` where a string is expected, a `<string>` where a boolean or array is expected) | Fail closed with fixtures: value types are kept and checked. |
  | Privacy manifest XML that Apple's parser could read differently (duplicate keys, where Apple keeps the last; a `__proto__` key; entities; comments, CDATA or processing instructions; attributes; other DOCTYPEs; binary, JSON or OpenStep plists; a missing root or trailing content) | Fail closed with fixtures. Equivalent forms that Apple reads the same way (comments between elements, character references, open-and-close empty elements) are accepted, also with a fixture. |
  | Hidden files and directories | Covered by a fixture: scanned, as XcodeGen compiles them. |
  | Symbolic links | Fail closed with fixtures, both inside walked directories and on scan entry paths and their parent directories. No links exist under the scanned roots. |
  | Files compiled but outside the walk | Fail closed for unmodelled XcodeGen and Package.swift constructs. Verified against the committed project and SwiftPM; see the walk verification row under Evidence. |
  | Pre-build scripts, build rules, plugins, macros, scheme pre-actions and xcconfig files | Fail closed with fixtures. |
  | Compiler, linker, search-path, tool-path and plugin build settings (`OTHER_LDFLAGS`, `WARNING_LDFLAGS`, `PRELINK_LIBS`, `LD`, `SWIFT_EXEC`, `SWIFT_INCLUDE_PATHS`, `SWIFT_PLUGIN_SERVER_PATH`, header, framework and library search paths, `OTHER_CFLAGS`, `GCC_PREPROCESSOR_DEFINITIONS`, bridging and prefix headers, and any setting not yet seen) | Fail closed with fixtures: project and shipped-target settings, in `base`, every `configs` entry and every `[sdk=...]` or `[arch=...]` variant, must be on the exact-name build-setting allowlist and match its value rule. Path-valued entries must name an existing regular file of the expected type under `apps/apple`. Test-target settings are not checked. |
  | File types Xcode could compile or generate code from (lex, yacc, MIG, Metal, Core Data, Core ML, Intents, Interface Builder, `.plist` in sources, files without an extension) | Fail closed with fixtures: shipped-target and package sources hold only Swift and the listed inert data types, in every build phase. |
  | Package.swift labels, members and strings that add code or inputs (`path:`, `sources:`, `resources:`, `exclude:`, `cSettings:`, `linkerSettings:`, `.define`, `.unsafeFlags`, executable, binary, plugin, macro and system-library targets, dynamic products, product and package dependencies, path strings) | Fail closed with fixtures: an allowlist of exactly what the four real manifests use. |
  | Target types other than `application` (app extensions, `application.watchapp2`, on-demand-install apps, frameworks) | Fail closed with fixtures. |
  | `sources` and package paths outside the modelled form (absolute, `~`, `.`, mid-path `..`, empty or trailing-slash components) | Fail closed with fixtures. |
  | Post-build scripts (`postBuildScripts`) | Limitation: allowed. They run after compiling and linking but before code signing, so a script could replace the executable or copy a dylib into the app. Today they only copy JSON and the reference sheet and delete README files. Their inline text is reviewed by hand; binary inspection is the cross-check. |
  | Xcode Cloud `ci_scripts` (`ci_post_clone.sh`, `ci_pre_xcodebuild.sh`) | Limitation: they run before compiling but are outside `project.yml`. Today they only install Node outside the repository and run guards and archive checks, writing no source files. Review by hand. |
  | Generated or resource code (`.plist`, `.strings`, `.xcstrings`, asset catalogues, JSON) | Not a bypass: data only, cannot call these APIs. Catalogues are still scanned for prebuilt code and links. No `.metal`, `.xib`, `.storyboard`, `.xcdatamodeld`, `.intentdefinition`, `.mlmodel` or `.js` files exist, and the file-type allowlist now rejects them in shipped sources. Their code generators cannot emit these APIs either. |
  | Interface Builder bindings (macOS `NSUserDefaultsController`) | Fail closed: `.xib` and `.storyboard` files are outside the file-type allowlist, and none exists. Adding one needs a manual review before it is allowlisted. |
  | Clocks not on Apple's list (`ContinuousClock`, `DispatchTime`, `CACurrentMediaTime`) | Out of scope: Apple does not list them, so no declaration is needed. |
  | SDK macros and Apple framework internals | Out of scope: Apple's own use is not declared by the app. Package macro targets fail closed. |
  | **project.yml and Package.swift parsing** | |
  | YAML that Yams reads differently from a simple parser (escapes such as `"OTHER\u005fLDFLAGS"`, anchors, aliases, tags, merge and complex keys, document markers, directives, multi-line scalars, multi-line or nested flow collections, flow mappings, block scalar indentation indicators, tabs, non-ASCII, a lone CR) | Fail closed with fixtures. Modelled forms (`''`, `\\` and `\"`, quoted commas, `#` inside quotes, quoted keys holding `: `, keys starting with `-`, `{}`, `script` blocks, a leading byte order mark, CRLF) pass with fixtures. |
  | YAML 1.1 implicit types (`yes`, `no`, `on`, `off`, `~`, octal, sexagesimal, timestamps) | Covered by fixtures: values keep their types, so anything that needs a string fails; non-string plain keys and timestamp values fail. |
  | Prototype and duplicate keys in `project.yml` | Covered by fixtures: mappings have no prototype and lookups use own keys; duplicate keys fail. |
  | XcodeGen `include`, `${VAR}` and `$platform` expansion, multi-platform targets | Fail closed with fixtures. `${...}` is allowed only in `script` values, which run after compiling and linking (see post-build scripts above). |
  | Dependencies naming two kinds, or a kind that is not a string | Fail closed with fixtures. |
  | Package entries with remote keys beside `path` | Fail closed with a fixture. |
  | Package.swift syntax that could build, rename or hide targets (raw strings, escapes, interpolation, multi-line strings, `#if`, variables, helper functions, type-qualified members, `.map`, operators, extra imports or statements) | Fail closed with fixtures. Comments inside calls, backtick-escaped names and trailing commas pass with a fixture. |
  | Package manifests and source roots the checker does not read (`Package@swift-*.swift`, `Source`, `src`, `srcs`) | Fail closed with a fixture. |
  | `project.yml` keys the checker does not model (`include`, `projectReferences`, `options.preGenCommand` and `postGenCommand`, target and scheme templates, `aggregateTargets`, `fileGroups`, `localPackages`, top-level and target `configFiles` (xcconfig), `settingGroups` and settings `groups`, scheme actions, target `scheme`, `buildToolPlugins`, `buildRules`, pre-build and post-compile scripts, script files, dependency `link`, `weak` and `root`) | Fail closed with fixtures. The allowlist reports each key with its file and line. Allowlisted keys with the wrong value shape also fail, and a pass fixture uses every allowlisted key. |
  | Cross-project, undefined or test-target `target:` dependencies of shipped targets, and `sdk:` paths | Fail closed with fixtures. A test target depending on a test target passes. |
  | Letter case of `sources` and package paths (macOS volumes usually ignore it; Linux CI does not) | Fail closed with fixtures on both. A missing optional path still passes. |
  | **Swift lexing and literal matching (round 8)** | |
  | Line endings: CR-only and CRLF files (a `//` comment ending at a lone CR), mixed endings | Covered by fixtures: CR and CRLF become LF before lexing, as Swift ends a line at each, and file:line counts match Swift's. Package.swift is read the same way. |
  | Characters Swift does not treat as line ends (VT, FF, NEL, U+2028, U+2029), NUL, DEL and other controls | Fail closed with fixtures for each, anywhere in the file. Swift runs a `//` comment on past the five separators and treats NUL as whitespace, while editors may show a line break, so the code a reviewer reads and the code Swift compiles could differ. The real tree has none. |
  | Byte order mark and encoding | A leading byte order mark is skipped, as swiftc does (fixtures for pass and fail). A byte order mark elsewhere in code and invalid UTF-8 fail closed with fixtures. |
  | Identifiers that look like an API name but are not (NFC and NFD forms, KELVIN SIGN, zero-width characters, NBSP, in plain code or backticks) | Fail closed with fixtures: only printable ASCII is read outside comments, strings and regex literals. Swift does not normalise identifiers, so these never name the API; failing keeps the lexer exact. The real tree has none. |
  | String escapes (`\u{...}` with 1 to 8 hex digits, `\0 \\ \t \n \r \" \'`) | Decoded, with fixtures: decoded literals are matched as well as the raw text. Escapes Swift rejects or the checker does not model fail closed with fixtures. |
  | Raw strings with any number of `#` | Decoded, with fixtures: only `\` plus the literal's own `#` count is an escape; `#"\u{55}"#` stays literal and passes. |
  | Multi-line literals and `\` line continuations, with or without trailing blanks | Decoded, with fixtures: continuations join lines, and each line's leading blanks are dropped (an escaped `\t` is kept). |
  | Interpolation of literals (`"system\("Uptime")"`, nested) and `+` joins of literals, across lines, parentheses and comments | Decoded, with fixtures: inlined or joined before matching. A non-literal interpolation is a boundary; names built from it are the run-time limitation above. |
  | Exact-name strings built by escapes, joins, interpolation, multi-line literals, or a C string ending in `\0` | Decoded, with fixtures: the decoded chain is quoted, and a decoded NUL ends the quoted string. |
  | Canonically equivalent characters inside strings (`"\u{212A}"` or a literal KELVIN SIGN for `K`) | Decoded, with fixtures: the three characters that decompose to ASCII are read as that ASCII, since Swift's `String` `==` treats them as equal. Other look-alikes are different strings in Swift too. |
  | Selector and key forms (`#selector`, `Selector(("..."))`, `NSSelectorFromString`, `#keyPath`, `\.systemUptime`, `\ProcessInfo.systemUptime`, `value(forKey:)`, `value(forKeyPath:)`) | Covered by fixtures: they name the member or hold it in a string, including escaped raw strings. Key paths and `#keyPath` were already covered. |
  | Lexer states that could hide code (nested block comments, `#if`, `#sourceLocation`, regex literals such as `/a//`, backticks) | Covered by fixtures: nested comments, regex literals and backticks were already modelled (ambiguous forms fail closed), `#if` branches are all scanned, and `#sourceLocation` changes no lexing. |
- **Limitations.** The check does not evaluate `#if` (an API compiled out on
  some platforms still counts for the target). It also scans inside string
  and regex literals, so it errs towards declaring a category. An
  unqualified bare `stat` used as a value anywhere other than the whole
  right-hand side of an assignment is not detected: for example passed as
  an argument (`apply(stat)`), returned (`return stat`), placed in a
  collection (`[stat]`) or used as an operand (`x ?? stat`). This avoids
  matching Swift variables named `stat`. A Codable or dictionary key with a
  listed name (`case creationDate = "creationDate"`, `["stat": 1]`) is
  flagged even when no API is called; rename the key or justify an exception.
  API names built at run time, wholesale attribute reads and post-build
  scripts are also not detected (see the table above). String literals
  joined only by `+`, or inlined through literal-only interpolations, are
  decoded and matched, but a name built from a variable or a call's result,
  a cast (`("system" as String) + "Uptime"`), an initialiser or other call
  around the literal after the `+` (`"system" + String("Uptime")`), `+=`,
  `joined()`, `String(format:)` or a non-literal interpolation is not,
  because its value is computed at run time. The join's look-back skips a
  closing `)`, so a call around the literal before the `+` is joined
  (`f("system") + "Uptime"` is matched). That can only add matches, except
  that an exact name written with escapes as a call's last argument and
  followed by `+` and a literal (`k("st\u{61}t") + "x"`) is read as part of
  the joined string and not matched; the plain spelling is still matched.
  Binary inspection (below) is the cross-check. Decoding drops every
  leading blank of each line in a multi-line literal, more than Swift's
  indentation stripping, which can only add matches. The Swift lexer is
  narrower than swiftc: a file with non-ASCII code, a control character
  (even one swiftc accepts, such as NUL, VT or FF in a comment), NEL, U+2028
  or U+2029 fails even when swiftc compiles it; rewrite the character as a
  `\u{...}` escape in a string or remove it. The manifest parser
  is deliberately narrower than Apple's: it rejects plists Apple would
  accept (binary, JSON or OpenStep plists, CDATA, attributes, a missing
  `<plist>` root, trailing content, duplicate keys), so such a manifest fails
  the check even when Apple would read it correctly. Rewrite it in the plain
  XML form Xcode writes. A Swift file inside a folder reference under
  `apps/apple` is not compiled but still fails the unmapped-file check; keep
  such data outside `apps/apple` or give it another extension. A directory
  whose name has an extension but which XcodeGen treats as a group (for
  example `Platforms/tvOS.v2`) is treated as a wrapper, so a manifest below
  it is not counted and the check fails with zero manifests; rename the
  directory. Native formats left out of the prebuilt-code check are listed
  in the native-code table with the reason. The `project.yml` parser and
  the Package.swift grammar are also narrower than Yams and Swift: valid
  YAML outside the subset (non-ASCII text, anchors, multi-line strings) and
  valid manifests that use any other Swift fail, even when XcodeGen or
  SwiftPM would read them as intended; rewrite them in the subset or extend
  the checker. Plain booleans and numbers that the checker never needs as
  strings are kept rather than rejected, such as `YES` and `NO` settings,
  `CURRENT_PROJECT_VERSION: 1` and `SWIFT_VERSION: 6.0`. The text of
  `script` blocks is not inspected (see post-build scripts above): they run
  after compiling and linking but before signing, so their inline text is
  reviewed by hand, with binary inspection as the cross-check. The
  `project.yml` allowlist, the build-setting allowlist, the Package.swift
  allowlist, the file-type allowlist and the shipped target types hold only
  what the real files use, so a new key, setting, manifest form, data type
  or target type fails even when it is harmless; confirm it is inert and
  add it (see each allowlist). Test-target settings and file types are not
  checked, because test bundles never ship. For `INFOPLIST_FILE` and
  `CODE_SIGN_ENTITLEMENTS` the checker checks only the path and file type,
  not the contents, so it would not catch an Info.plist that sets
  `LSEnvironment` with `DYLD_*` variables, or entitlements that disable
  library validation. Either still needs a library to load, and a library
  bundled in the app is prebuilt code that the checker rejects (a post-build
  script that copies one in is the script limitation above). The hardened
  runtime would ignore `DYLD_*` variables, but `project.yml` does not set
  `ENABLE_HARDENED_RUNTIME`, so the checks do not rely on it.
  `pnpm check:apple-icloud-gate` allows only the approved keys in the two
  CloudKit entitlements files and checks the CloudKit Info.plist's
  background modes, but it checks the default macOS entitlements only for
  iCloud, push and background-mode keys. Other entitlement and Info.plist
  content is reviewed by hand. The checker reads `project.yml`,
  each linked `Package.swift` and the files in the working tree, not the
  committed `CanadianHam.xcodeproj`; the walk verification under Evidence
  shows that the two agree today. On CI the working tree is a clean
  checkout, so an ignored or untracked file that exists only on the machine
  that builds the release (for example in a resources folder) is not seen;
  build releases from a clean checkout. Exclude globs are matched with
  exact letter case, which can only scan more than XcodeGen.

### Evidence

Run from the TASK-85 worktree on 2026-11-03 UTC:

| Command | Result |
|---|---|
| `plutil -lint` on the four manifests | All `OK`. |
| `rg` over non-test `*.swift` in `apps/apple` and `packages` for every spelling listed above | Matches in only six files: `MorseTrainerSettings.swift` (3 lines), `ProgressStore.swift` (27), `NativeSettingsView.swift` (1), `StudyViews.swift` (2), `DuoPostureProvider.swift` (5) and `WatchMorsePlayback.swift` (1). There are no matches in package `Sources`. |
| `pnpm test:apple-required-reasons` | `required-reasons-test: passed self-test fixtures.` |
| `pnpm check:apple-required-reasons` (with the `project.yml` change, on the branch since `b7877c4d`) | Passed. `CanadianHam`: 53 Swift files, `SystemBootTime [35F9.1], UserDefaults [CA92.1]`. `CanadianHamWatch`: 31, `SystemBootTime [35F9.1]`. `CanadianHamTV`: 33, `UserDefaults [CA92.1]`. `CanadianHamVision`: 32, `UserDefaults [CA92.1]`. |
| `pnpm check:apple-network`, `pnpm check:apple-icloud-gate` | Passed. |
| Walk verification (PR #1064 round 4): the checker's per-target Swift lists compared with the `PBXSourcesBuildPhase` files in the committed `CanadianHam.xcodeproj` (`plutil -convert json`), and each package's `Sources` walk compared with `swift package describe --type json` | Identical. `CanadianHam` 32 app files, `CanadianHamWatch` 11, `CanadianHamTV` 13, `CanadianHamVision` 12, with no non-Swift sources and no build rules. Each package has one library target and one test target and no dependencies; non-test sources are `calculator-swift` 1, `content-swift` 8, `engine-swift` 10 and `morse-swift` 2. The project links only those four package products, and its shell script phases all run after the Sources phase. No symbolic links or hidden entries exist under the scanned roots. |
| Folder references (PR #1064 round 5): the six shipped `content/` folder references scanned for prebuilt code and links, with the strict manifest parser applied to the four manifests | 2,059 files (2,010 JSON, 49 Markdown), no prebuilt code, no symbolic links or hidden entries, no `buildPhase: none` entries. The four manifests parse unchanged, and the checker output is byte-identical to the previous round. |
| Pruning sweep (PR #1064 round 6): `project.yml` sources, excludes, types and build phases, and package `Sources`, re-read against the pruning-point table; resource catalogues under the scanned roots counted with `find` | Every exclude is a literal path (`CanadianHam` excludes `Resources/AppIcon.icon`, both asset catalogues and the CloudKit `Info.plist`), every type and build phase is modelled, and no package declares `resources:`, `exclude:` or `..`. The eight catalogues (`CanadianHam` `Assets`, `FigureAssets`, `AppIcon.icon` and `Localizable.xcstrings`; the watchOS `Assets` and `InfoPlist.xcstrings`; the tvOS and visionOS `Assets`) hold 141 files, now also scanned through the ordinary walks, with no prebuilt code, links, hidden or special files. Package `Sources` hold no catalogues. Each manifest sits at `<target>/Resources/PrivacyInfo.xcprivacy` with no extension-named directory on its path. The `--verbose` checker output is byte-identical to round 5 and the run takes about 0.4 s. |
| YAML and Package.swift sweep (PR #1064 round 7): the real `project.yml` parsed with the round 6 and round 7 parsers and the trees compared; the four `Package.swift` files read with the new grammar; each new check mutation-tested against the self-test | Same structure. The only differences are value types and `script` text, none of which the checker reads: 99 `YES`, `NO`, `true` and `false` values are now booleans, `CURRENT_PROJECT_VERSION: 1` and `SWIFT_VERSION: 6.0` are numbers, and the nine `script` blocks lose their indentation. `${...}` appears only in `script` values, there are no tabs, non-ASCII characters, anchors, multi-line scalars or nested flow collections, and every dependency names one kind. All four manifests fit the grammar. The `--verbose` output is byte-identical to round 6 and the run takes about 0.4–0.5 s. All 72 mutations of the new checks fail the self-test. Two more survive only because another layer already covers them: own-key package lookup and the empty defaults for `packages` and `targets`, both made safe by mappings without a prototype. |
| `project.yml` allowlist and path case (PR #1064 round 7b): the real file's keys listed with the checker's parser and compared with the allowlist; the allowlist, dependency and case checks run on the real tree; each new check mutation-tested against the self-test | The real file uses exactly the allowlisted keys. At the top level these are `name`, `options` (the five listed keys), `configs`, `packages`, `settings`, `targets` and `schemes`. Targets use `type`, `platform`, `supportedDestinations`, `deploymentTarget`, `sources`, `dependencies`, `settings` and `postBuildScripts`. Dependencies use `target`, `package`, `product`, `embed` and `destinationFilters`; settings use `base` and `configs`; schemes use `build.targets` and `test` with `gatherCoverageData`, `testPlans` and `targets`. The only `target:` dependency of a shipped target is `CanadianHam` on `CanadianHamWatch` (an application); test targets depend on app targets. There are no `sdk:` dependencies or `.xcconfig` files, and every sources and package path matches its on-disk case. The `--verbose` output is byte-identical to round 7 and the run takes about 0.4–0.5 s. All 41 mutations of the new checks fail the self-test: the allowlist lookup, the value-shape checks, key lines, widened and narrowed allowlist entries, the dependency and `sdk:` rules, and the case comparison, including a case check skipped for `optional` paths. |
| Build-setting, Package.swift and file-type allowlists (PR #1064 round 7c): the real file's project and shipped-target settings listed with the checker's parser; each allowlist entry, Package.swift label and member, and data type dropped one at a time and the checker rerun on the real tree; each new check mutation-tested against the self-test | The project and the four shipped targets set 79 build settings with 37 distinct names, exactly the build-setting allowlist. Dropping any one entry fails the real tree, so none is unused. Every value matches its rule; the only path-valued settings are `CODE_SIGN_ENTITLEMENTS` (five values: three existing `.entitlements` files and two `""`) and the `DebugCloudKit` iOS `INFOPLIST_FILE` of `CanadianHam`. `BUNDLE_LOADER` and `TEST_HOST` appear only on `CanadianHamTests`. Dropping any Package.swift label or member fails all four real manifests at its first use, and dropping any of the five data types fails the real tree (`.json` for the copied `content/subsection-titles.json`, `.strings` for the `InfoPlist.strings` tables, `.xcstrings` for `Localizable.xcstrings`, `.entitlements` and `.xcprivacy`). The only shipped target type is `application`, and every sources and package path fits the modelled form. The `--verbose` output is byte-identical to round 7b and the run takes about 0.4 s. All 89 mutations of the new checks fail the self-test, and a no-op control mutation passes. The mutations cover key parsing, base and configs walks, each value rule, the path-file checks, widened and narrowed allowlists, each Package.swift set and string rule, each data type, the phase, wrapper, package and folder handling of the file-type check, the target types, each spec-path rule and the missing-path rule. |
| Swift lexing sweep (PR #1064 round 8): swiftc 6.4.2 (`xcrun swiftc -typecheck`, and compiled probes printing literal values) run on scratch files for each line terminator, control character, byte order mark position, invalid UTF-8, identifier normalisation and string escape form; the round 8 lexer run over all 110 tracked Swift files; each new check mutation-tested against the self-test | swiftc ends lines and `//` comments at CR, LF and CRLF only; VT, FF, NEL, U+2028 and U+2029 do not end a comment, U+2028 in code is an error, and NUL and NBSP are warnings read as whitespace. It skips a leading byte order mark, rejects invalid UTF-8 even in comments, and does not normalise identifiers (NFD `café` and a KELVIN SIGN make different names), while `String` `==` treats U+212A, U+037E and U+1FEF as their ASCII equivalents. Compiled probes confirm that `"system\u{55}ptime"`, `#"system\#u{55}ptime"#`, `"system\("Uptime")"` and a `"""` `\` continuation (also with trailing blanks and `##` delimiters) all equal `systemUptime`, that raw `#"\u{55}"#` stays literal and that `\u{}`, nine hex digits, surrogates and a single-line `\` before a line break are errors. All 110 tracked Swift files lex without errors: none has CR line endings, a byte order mark, a control character or non-ASCII code (38 have non-ASCII comments or strings); 8 use `\u{...}`, 6 multi-line literals, 72 interpolation and 2 `+` between string literals. Decoded matching adds no usage, so the `--verbose` output is byte-identical to round 7c and the run takes about 0.4 s. Of 39 mutations of the new checks, 38 fail the self-test after two fixtures were tightened (a nine-digit `\u{000000055}`, and an escaped `\t` before an exact name), and a no-op control passes. The survivor only adds a second message for a NEL, U+2028 or U+2029 in code, which already fails. The mutations cover CR and CRLF normalisation, the byte order mark skip, each control range, the ASCII-code rule (also in backticks), fatal UTF-8 decoding, the scalar, surrogate, digit-count and simple-escape rules, continuations, indentation stripping, the first and last line breaks, literal-only interpolation, the boundary marker, `+` joins, the quote wrapper, ASCII equivalents, the NUL boundary, decoded matching and offsets, and diagnostic line numbers. |
| Release builds through `xbuild` (`-configuration Release`, generic simulator destinations, plus generic macOS, `CODE_SIGNING_ALLOWED=NO`), then `plutil -p` on each bundled `PrivacyInfo.xcprivacy` | All builds succeeded. Each bundle has exactly one manifest, byte-identical (`cmp`) to its source. iOS `CanadianHam.app` and macOS `CanadianHam.app/Contents/Resources` declare User defaults `CA92.1` and System boot time `35F9.1`. The embedded `CanadianHam.app/Watch/CanadianHamWatch.app` declares System boot time `35F9.1`. `CanadianHamTV.app` and `CanadianHamVision.app`, built from a regenerated project with the `project.yml` change, declare User defaults `CA92.1` only. |
| `strings -a` / `nm -u` on the Release binaries, which include the statically linked package code | iOS app: `systemUptime`, `standardUserDefaults`, `persistentDomainForName`. Watch: `systemUptime` only. macOS: `standardUserDefaults` and `persistentDomainForName`, but no `systemUptime`, because those call sites are iOS-only. TV and Vision: `standardUserDefaults` only. No binary imports `stat`, `lstat`, `fstat`, `fstatat`, `statfs`, `statvfs`, `getattrlist` or `mach_absolute_time`, and none references the file-timestamp, disk-space or `activeInputModes` selectors. |

These are unsigned local build products, not signed TestFlight or App Store
artifacts. Repeat the bundle inspection on the release archive.
