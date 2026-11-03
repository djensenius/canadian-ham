# Privacy and no-data design

The privacy goal is simple: the Apple app collects no data, and the web app has no accounts, no analytics and no server-side progress storage, and makes no third-party requests itself (citation links open another site only when the user follows them).

This document supports [requirements.md](requirements.md) and [architecture.md](architecture.md). Licensing and attribution rules are in [content-licensing.md](content-licensing.md).

## Privacy principles

- No accounts.
- No telemetry.
- No advertising.
- No third-party tracking.
- No automatic crash or diagnostic upload.
- No remote progress sync in v1 release builds.
- No iCloud sync in v1 release builds.
- No networking code in v1 Apple release builds.
- Web progress remains in browser storage unless the user explicitly exports it.
- On iOS, iPadOS and macOS, Apple progress remains in local app storage unless the user explicitly exports it.
- On tvOS and visionOS, practice sessions are kept only while the app is open; nothing is saved or sent.

## Apple no-data design

The Apple app is a fully offline SwiftUI multiplatform app for iOS, iPadOS, macOS, visionOS, and tvOS. The iOS, iPadOS and macOS app persists local progress and supports user-initiated export/import/reset. The tvOS and visionOS apps keep practice sessions in memory only while the app is open; they do not save progress and do not export it.

Allowed local data on platforms that implement persistence, currently iOS, iPadOS and macOS:

- Question progress.
- Lesson progress.
- Mock exam attempts.
- Practice session history.
- Local preferences such as selected language and theme.
- User-initiated imported progress JSON.
- User-initiated exported progress JSON.
- Apple exports include a random per-install device ID, stored locally in app preferences, so per-device progress counters can converge; it is not a hardware or vendor identifier and leaves the device only in user-initiated exports or the user's private CloudKit database in gated sync builds.

Allowed in-memory state on tvOS and visionOS:

- Current practice session state while the app is open.
- Current UI choices needed by the open session.

Disallowed data flows:

- Sending progress to any server in v1 release builds.
- Sending diagnostics to any server.
- iCloud sync in v1 release builds.
- Push notifications in v1 release builds.
- Remote config.
- Analytics events.
- Advertising identifiers.
- Third-party SDK collection.

Post-v1 gated exception:

- Optional iCloud progress sync may be built only behind the non-default `DebugCloudKit` Apple build configuration after v1. That configuration defines `ICLOUD_SYNC`; default `Debug`/`Release`, CI and v1 release builds leave the gate disabled and must carry no iCloud capability, no Push Notifications capability, no remote-notification background mode and no Settings iCloud toggle.
- When the gate is explicitly enabled after v1, the approved network-dependent scope is limited to CloudKit private-database progress sync for learning progress, the Push Notifications capability that CloudKit uses for silent sync notifications, and the remote-notification background mode needed for SwiftData/Core Data CloudKit updates. The feature must remain user opt-in and off by default, with preferences kept in a local-only `.none` configuration. The private container ID is `iCloud.org.davidjensenius.CanadianHam`.
- The approved exception does not permit analytics, diagnostics upload, remote config, advertising, third-party SDK collection, or developer-operated progress servers.

Implementation rules:

- When a platform persists progress, store it in SwiftData local stores.
- Bundle all content needed for runtime use.
- Do not add networking code for v1 app features.
- Do not add entitlements for network-dependent capabilities unless this privacy review's off-by-default iCloud build gate or a later privacy review approves the exact scope.
- Keep v1 release builds free of iCloud, Push Notifications, and remote-notification background-mode capabilities.
- Do not add third-party SDKs in v1.
- Build and test with `xbuild`, never direct `xcodebuild`.

## Web no-data design

The web app is a fully static site. Static hosting still means the host may see client IP addresses and user-agent data in ordinary HTTP request logs for app assets; the project does not add application-level tracking or server-side progress storage. The prepared GitHub Pages deployment notes and release-time retention confirmation are in [release/web-deploy.md](release/web-deploy.md#host-logging-and-retention).

Allowed local data:

- IndexedDB question progress and attempts.
- localStorage preferences if small and appropriate.
- Service worker caches for app shell and content.
- User-initiated imported progress JSON.
- User-initiated exported progress JSON.

Disallowed data flows:

- Accounts or login.
- Server-side progress storage.
- Analytics.
- Ads.
- Third-party fonts or scripts.
- Third-party API requests.
- Error reporting services.
- Remote config.

Implementation rules:

- Self-host fonts and static assets.
- Serve content from same-origin static assets.
- Avoid embedding third-party iframes, scripts, or pixels.
- Use Content Security Policy compatible with a static app and no third-party connections; some static hosts may require a `<meta http-equiv="Content-Security-Policy">` tag if response headers are not configurable.
- Choose hosting and log settings that minimize retained request logs where possible, such as disabling optional access logs or setting the shortest available retention.
- Export/import/reset are explicit settings actions.

## Forbidden dependency list

Do not add these dependency categories in v1:

- Analytics SDKs.
- Advertising SDKs.
- Attribution or install tracking SDKs.
- Crash-reporting SDKs that upload automatically.
- Remote config SDKs.
- A/B testing SDKs.
- Session replay SDKs.
- Social login SDKs.
- Backend-as-a-service SDKs.
- Cloud database SDKs.
- Push notification providers.
- Third-party web font CDNs.
- Tag managers.
- Any package whose purpose is telemetry, fingerprinting, tracking, or behavioural analytics.

Examples of dependency names to scrutinize or reject if proposed:

- Firebase Analytics, Crashlytics, Remote Config, Firestore, Realtime Database.
- Google Analytics, Google Tag Manager.
- Sentry or similar crash-reporting services unless a future explicit privacy review changes the no-data rule.
- App Center.
- Amplitude, Mixpanel, Segment, PostHog Cloud, Datadog RUM.
- Facebook/Meta SDKs.
- AdMob or other ad SDKs.

Development-only test tools may be considered if they do not ship in app bundles and do not transmit project data during normal validation.

## App Store Data Not Collected rationale

The Apple app should qualify for App Store privacy label "Data Not Collected" because:

- It does not collect contact information.
- It does not collect identifiers.
- It does not collect usage data.
- It does not collect diagnostics.
- It does not collect user content.
- v1 release builds do not transmit locally stored progress.
- It does not include analytics, ads, tracking, or third-party SDKs.
- v1 release builds work fully offline.

For a future build with the iCloud sync gate enabled, the "Data Not Collected" conclusion rests on Apple's definition of collection and the private CloudKit database access model. Apple's [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) define "Collect" as transmitting data off device in a way that allows the developer or third-party partners to access it for longer than necessary to service the request in real time, and state that developers are not responsible for disclosing data collected by Apple. Apple's [`CKContainer.privateCloudDatabase`](https://developer.apple.com/documentation/cloudkit/ckcontainer/privateclouddatabase) documentation states that only the user can access their private database by default, that the user owns its content, and that private-database data is not visible in the developer portal. On that basis, progress stored only in the user's private CloudKit database is not developer collection, provided the project does not export, retain, correlate, or otherwise collect CloudKit operational logs or telemetry.

CloudKit Console log policy for any gate-enabled build, based on Apple's [CloudKit Logs](https://developer.apple.com/icloud/logs/) documentation:

- Do not export CloudKit Console logs or telemetry.
- Do not retain CloudKit Console logs outside Apple's console.
- Do not correlate CloudKit Console anonymous user IDs, platforms, OS versions, operation types, or timestamps with any other data.
- Use CloudKit Console only for transient operational debugging required to service the app, and re-check App Store Connect privacy answers before any release that enables the gate.

Evidence to keep for review:

- Dependency list showing no third-party SDKs.
- Source search showing no networking APIs used by app features.
- Entitlement review showing no iCloud sync and no push notification capability for v1 release builds; for any post-v1 gate-enabled build, entitlement review showing the CloudKit/Push/remote-notification scope is limited to the approved iCloud sync gate.
- Airplane-mode smoke test results.
- iOS, iPadOS and macOS Settings screenshots showing export/import/reset are user-initiated, and tvOS/visionOS About screenshots showing sessions are in-memory only.

Release evidence for the current App Store privacy-label answers and web privacy summary is tracked in [release/privacy-label-evidence.md](release/privacy-label-evidence.md). If any future feature transmits data, the privacy label must be revisited before release.

## Network policy

### Apple

Policy: no network use by app features in v1 release builds.

Verification targets:

- No app networking module.
- No remote URLs in runtime configuration except non-clickable attribution or source text (including the About screens' RBR-4 and active ISED question-bank source URLs), and the single RBR-4 citation link on the answer-explanation panel (`ExplanationPanelView`), which opens in the system browser only when tapped (the app makes no request itself). The panel appears after answering in lesson quizzes, practice sessions and review, and mock-exam review.
- No code paths using URL loading for remote resources.
- No app entitlements for iCloud sync or push notifications in v1 release builds. Any post-v1 gate-enabled build must limit network-dependent entitlements to CloudKit private-database sync, CloudKit's Push Notifications capability, and the remote-notification background mode.
- Runtime smoke tests in airplane mode cover first launch, lesson reading, practice, mock exam, progress persistence, export, import, and reset on iOS, iPadOS and macOS; tvOS and visionOS smoke tests cover first launch and practice with in-memory sessions only.

The project may still contain source URLs in documentation and source manifests for attribution and verification. Those URLs are not runtime network dependencies.

### Web

Policy: same-origin static asset requests only. The app sends no progress or identifiers, but the static host can still observe asset requests and may record IP addresses in standard request logs.

Official-source citation URLs, such as ISED/Government of Canada source pages in explanations, are rendered only as user-activated external links. The web app does not fetch, preload, or cache those citation URLs automatically; following a citation navigates the user to ISED in a new tab, where that external site receives the navigation request.

Verification targets:

- No third-party requests in browser developer tools during app load and normal flows.
- Service worker caches only same-origin app shell, content JSON, Markdown, and app assets; reference PDFs are not shipped in the web app or PWA cache.
- Fonts are self-hosted.
- Content Security Policy blocks unexpected `connect-src`, `script-src`, `img-src`, and `font-src` third-party origins; if host response headers are unavailable, document and test the fallback CSP `<meta>` tag.
- Hosting configuration disables optional access logs or uses the shortest retention available where the host provides such a project-level control. GitHub Pages does not expose a project-level access-log setting for this repository; any unavoidable host logs are treated as hosting operations data, not application analytics, and retention remains to confirm before release.

## Verification checklist

For release-day execution, use the consolidated [release checklist](release/release-checklist.md#privacy) alongside this privacy verification checklist.

Run before release and when dependencies change:

1. Review dependencies for forbidden categories.
2. Search source for network and telemetry terms.
3. Confirm Apple entitlements do not include iCloud sync or push notifications.
4. Confirm no Apple target links third-party SDKs.
5. Build and test Apple app with `xbuild`.
6. Launch Apple app in airplane mode. On iOS, iPadOS and macOS, complete a lesson, practice quiz, mock exam, export, import, and reset; on tvOS and visionOS, complete the available offline practice flow and confirm no progress is saved or exported.
7. Build static web app.
8. Load web app with browser dev tools open and confirm no third-party requests.
9. Put web app offline after PWA cache readiness and complete a lesson, practice quiz, mock exam, export, import, and reset.
10. Confirm App Store privacy answers still match actual behaviour.

Suggested source searches once code exists:

```text
URLSession
NSURLSession
Network.framework
WKWebView remote loads
http://
https://
analytics
telemetry
crash
firebase
sentry
segment
mixpanel
amplitude
posthog
admob
tracking
```

These strings can appear in docs or tests. Findings in runtime app code require review.

## User controls

Settings on platforms with persistent local progress must include:

- Export progress JSON.
- Import progress JSON.
- Reset all data.
- Display active bank version and source date.
- Display privacy summary: no accounts, no analytics, local progress only.

The tvOS and visionOS About screens must instead state that practice sessions are kept only while the app is open and nothing is saved or sent.

Reset semantics:

- Deletes lesson progress, practice history, mock exam attempts, question progress, and local preferences unless the user chooses a narrower reset in a future feature.
- Does not delete bundled content because bundled content is app/site data, not user progress.
- On macOS, deleting the app bundle may leave the app container behind; users should use Reset all data when they want reliable local progress deletion. On iOS and iPadOS, deleting the app normally removes app-local progress.

## Open privacy questions

- Confirm whether any development crash logs from TestFlight distribution affect privacy messaging before public release.
- Confirm minimum App Store privacy questionnaire wording after the first Apple target exists.
- Before enabling the off-by-default iCloud sync build gate for a release, re-check the App Store privacy questionnaire and verify the CloudKit Console no-export/no-retention policy is still followed.
