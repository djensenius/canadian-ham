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
| Third-party SDKs or partner code in the Apple app | No third-party runtime SDK collection; no remote third-party SDKs linked | `docs/privacy.md` forbids third-party SDKs in v1. `pnpm check:apple-network` passed and checks for remote Swift package references in `apps/apple/project.yml`, the generated Xcode project, Swift package manifests, and `Package.resolved`. Current Apple dependencies in `apps/apple/project.yml` are local packages `../../packages/engine-swift` and `../../packages/content-swift`. |
| Apple frameworks/services collection | None by this app | `docs/privacy.md` forbids iCloud sync and network-dependent entitlements in v1. The quoted Apple wording from `docs/proposals/icloud-sync.md` says app developers disclose data they collect from Apple frameworks/services; this app currently collects none. |

### Privacy manifest and required-reason APIs

| Area | Answer | Supporting evidence |
|---|---|---|
| Privacy manifest included | Yes, a manifest is bundled in every application target | `apps/apple/CanadianHam/Resources/PrivacyInfo.xcprivacy` is shared by `CanadianHam`, `CanadianHamTV` and `CanadianHamVision`. `CanadianHamWatch` has its own equivalent `apps/apple/Platforms/watchOS/Resources/PrivacyInfo.xcprivacy`; see the TASK-14.6 export inspection below. |
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

### Required-reason review: OPEN

**Applicability, approved reasons and shipped-target coverage are unresolved.**
The observed empty `NSPrivacyAccessedAPITypes` arrays alongside current defaults
access require review against Apple's current required-reason API documentation
(linked above). This inventory neither proves a violation nor grants compliance
clearance. It supplies no invented Apple reason codes. **Data Not Collected** and
no-network results address different questions; neither establishes that a
required-reason declaration is unnecessary or sufficient.

Before submission, the release owner must:

- Review all applicable required-reason API categories on the actual release
  revision, not just the preference spellings searched here, including linked
  packages/framework use and each shipped platform.
- Determine the applicable categories and Apple's currently approved reasons
  from actual behavior (including reads and ungated local helper calls), record
  the rationale, and reconcile that decision with shared versus watch-specific
  manifest coverage. No reason has been selected or approved by this addendum.
- If that review calls for code/manifest changes, track and implement a separate
  remediation with validation; **none are made by TASK-81**. Inspect the final
  bundled manifests for each shipped target and retain release-commit evidence
  before closing this review.

The existing ISED permission, device/offline/accessibility, privacy wording and
release-candidate gates remain in force. This addendum does not complete
TASK-1.2, reopen or re-complete TASK-1.5, or authorize distribution.
