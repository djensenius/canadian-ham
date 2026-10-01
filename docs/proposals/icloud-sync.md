# Research: Optional iCloud Sync as a Privacy-Review Item (T-705 / Backlog task-13) — Source-Checked

**Original brief date:** 2026-09-30 · **Source check date:** 2026-10-01
**Status:** Evaluation and recommendation for after v1, source-checked and corrected
**Checked against:** Apple Developer documentation (DocC JSON for the current docs, © 2026), the Apple Developer App Store privacy pages, Apple Support, WWDC session pages, ISED RIC-3, and the repo files (`apps/apple/CanadianHam/Models/ProgressModels.swift`, `apps/apple/project.yml`, `docs/requirements.md`, `docs/privacy.md`, `tasks/PLAN.md`, `AGENTS.md`).
**Status meanings:** **Verified** = an official source (or the repo) supports the claim as worded. **Corrected** = the claim was wrong or overstated; the correct fact and its source are given. **Unverified** = no authoritative support was found; the searches are listed.

---

## Verification summary

| # | Claim (original brief) | Status | Source |
|---|---|---|---|
| 1 | Apple defines "collect" as sending data off the device so you or partners can access it longer than needed to handle the request in real time | **Verified** (word for word) | developer.apple.com/app-store/app-privacy-details/ |
| 2 | The App Privacy page's guidance on Apple frameworks and services (MapKit, CloudKit, App Analytics) | **Verified** (word for word), but it is *not* an exemption: it says to disclose data **you** collect from Apple services | same |
| 3 | Data kept only in the user's private CloudKit database keeps "Data Not Collected" | **Verified as inference**. Apple has no explicit statement; wording corrected from "explicitly distinguishes" | app-privacy-details; developer.apple.com/documentation/cloudkit/ckcontainer/privateclouddatabase |
| 4 | Private DB records are "end-to-end encrypted or protected" | **Corrected**: under standard data protection Apple holds the keys; only CloudKit encrypted fields and assets are end-to-end, and only with Advanced Data Protection on. SwiftData `@Attribute(.allowsCloudEncryption)` can mark fields for CloudKit encryption on iOS/iPadOS 17+, macOS 14+, tvOS 17+ and visionOS 1+ | support.apple.com/en-us/102651; developer.apple.com/documentation/swiftdata/schema/attribute/option/allowscloudencryption |
| 5 | Developer has "zero access" | **Corrected**: no access to record data, but CloudKit Logs show per-user anonymous IDs, platform, OS and operations, and can be exported | developer.apple.com/icloud/logs/ |
| 6 | All three v1 entities use `@Attribute(.unique)` | **Verified** (repo) | `apps/apple/CanadianHam/Models/ProgressModels.swift` |
| 7 | SwiftData quote: "…CloudKit is unable to enforce the Unique property option" | **Verified** (word for word) | developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices |
| 8 | CloudKit forbids non-optional relationships, "directly conflicting with v1 models" | **Corrected**: the rule is real, but the v1 models have no relationships. Only unique constraints and defaults conflict | SwiftData sync article; repo |
| 9 | With `.unique`, `ModelContainer` init "throws a fatal runtime exception" | **Corrected**: the store fails to load and an error is thrown (NSCocoaErrorDomain 134060). It is only fatal if app code calls `fatalError` | Framework error text quoted in a secondary blog; Apple Developer Forums thread 735349 |
| 10 | Every property must be optional or have a default value | **Verified, secondary source only**: it is framework error text, not in the current Apple docs | alexanderlogan.co.uk/blog/wwdc23/08-cloudkit-swift-data; developer.apple.com/forums/thread/735349 |
| 11 | CloudKit schema is additive-only after it is promoted to Production | **Verified**; "records cannot be deleted" corrected to "record types/fields cannot be deleted, renamed or modified" | SwiftData sync article; Core Data "Creating a Core Data Model for CloudKit"; WWDC22 10120 |
| 12 | SwiftData syncs through `NSPersistentCloudKitContainer`; schema is set up with `initializeCloudKitSchema()` in DEBUG | **Verified** | SwiftData sync article |
| 13 | CKDatabase availability: iOS 10.0+, macOS 10.12+, tvOS 10.0+, visionOS 1.0+ | **Corrected**: iOS/iPadOS 8.0+, macOS 10.10+, Mac Catalyst 13.1+, tvOS (available, no version listed), visionOS 1.0+ | developer.apple.com/documentation/cloudkit/ckdatabase |
| 14 | SwiftData + CloudKit is supported on all five platforms | **Verified at the API level**. **Corrected at the project level**: the tvOS and visionOS targets don't compile `ProgressModels.swift` or `ProgressStore.swift` | SwiftData, `ModelConfiguration.CloudKitDatabase` and `NSPersistentCloudKitContainer` docs; `apps/apple/project.yml` |
| 15 | Needed: container-identifiers entitlement, icloud-services=CloudKit, aps-environment, Background Modes remote-notification | **Verified** | developer.apple.com/documentation/xcode/configuring-icloud-services; Core Data "Setting Up Core Data with CloudKit" |
| 16 | tvOS background-execution limits and multi-user profile edge cases | **Unverified** | Searched Apple docs; nothing found |
| 17 | SwiftData discovers CloudKit from entitlements by default; `.none` turns sync off | **Verified** | SwiftData sync article; CloudKitDatabase docs |
| 18 | The opt-in toggle needs a dynamic `ModelContainer` rebuild or a dual store | **Unverified** (design inference); no Apple doc covers switching at runtime | Searched SwiftData and Core Data docs and Developer Forums |
| 19 | On sign-out the app must fall back to a local store without deleting cached progress | **Unverified / unclear**. Community reports say the CloudKit container may purge mirrored local data when the account changes | StackOverflow 70755205, 58179862 (community) |
| 20 | `CKAccountChanged` notification and `CKAccountStatus` exist on all target platforms | **Verified** | ckaccountstatus and CKAccountChanged docs |
| 21 | Apple asks apps to offer a way to delete CloudKit data; zone deletion via `CKModifyRecordZonesOperation`; SwiftData sync uses `NSPersistentCloudKitContainer` | **Verified**, with project implementation inference: stop sync or switch the mirror to local-only before deleting the zone, then delete or keep local records according to the user's choice and verify no re-upload | developer.apple.com/documentation/cloudkit/responding-to-requests-to-delete-data; SwiftData sync article; developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer |
| 22 | "GDPR/privacy compliance *requires*" a Delete iCloud Data function | **Unverified** (legal claim). Apple's GDPR tech talk explicitly says it isn't legal advice | developer.apple.com/videos/play/tech-talks/703/ |
| 23 | SwiftData's default conflict handling is "last-writer-wins" field merging | **Unverified** | Not found in the Core Data/SwiftData CloudKit docs checked |
| 24 | Leitner / exam-attempt merge rules | Researcher inference (design, not an external fact) | — |
| 25 | Tests can use `ModelConfiguration(isStoredInMemoryOnly:…, cloudKitDatabase: .none)` | **Verified** (the API exists) | ModelConfiguration docs |
| 26 | Such tests "pass under `CODE_SIGNING_ALLOWED=NO`" with no account | **Unverified**; open risk for macOS ad-hoc signing once iCloud entitlements are added | Secondary sources only |
| 27 | The v1 requirement quote comes from `docs/requirements.md` / `docs/privacy.md` | **Corrected**: the exact wording is in `AGENTS.md`; the same rule appears in DEC-APPLE-003, REQ-APPLE-003 and `privacy.md` | repo |
| 28 | Export/import exists as `REQ-PROGRESS-001`, T-506 | **Corrected**: no REQ-PROGRESS-001 exists; it is REQ-QUIZ-005 (and REQ-APPLE-003). T-506 **Unverified** | `docs/requirements.md` |
| 29 | Add rows to `tasks/PLAN.md` | **Corrected**: PLAN.md is now only a pointer; T-705 maps to Backlog **task-13** | `tasks/PLAN.md` |
| 30 | Container `iCloud.ca.canadianham.app` | **Corrected**: bundle IDs use the `com.djensenius` prefix (`com.djensenius.CanadianHam`, `.TV`, `.Vision`) | `apps/apple/project.yml` |
| 31 | RIC-3 URL (ISED) | **Verified**: resolves to Issue 5, March 2022 | ised-isde.canada.ca RIC-3 |
| 32 | ISED Basic bank PDF URL (2025-07-15) | **Unverified**: PDF fetch failed. The project's authority is the delimited TXT (SHA-256 `34c7cd79…284f`) | — |
| 33 | WWDC22 "Evolve your Core Data schema" (10120) | **Verified** | developer.apple.com/videos/play/wwdc2022/10120/ |
| 34 | App Privacy Details page "Updated 2024/2025" | **Unverified**: no update date is shown on the page | — |
| 35 | RAC claims | Not applicable: the brief makes no RAC claims | — |

---

## Summary (corrected)

Optional iCloud sync with SwiftData and a CloudKit **private** database is technically possible on every Apple platform the project targets. The APIs exist on iOS/iPadOS 17+, macOS 14+, tvOS 17+ and visionOS 1+, well below the project's 27.0 minimums. In this repo, though, only the iOS/iPadOS/macOS target currently has a SwiftData progress store; the tvOS and visionOS targets do not.

Apple defines "collect" as sending data off the device in a way that lets **you or your third-party partners** access it. Private CloudKit data is "only [accessible to] the user … by default" and "isn't visible in the developer portal". So, *by inference*, keeping progress only in the user's private database should still allow **"Data Not Collected"**.

Apple does not say this explicitly, and two caveats apply:

- The data is **not end-to-end encrypted by default**. Apple holds the keys under standard data protection.
- The developer can see **per-user operation logs** (anonymous container-specific IDs, platform, OS version, operation type) in the CloudKit Console. These should not be exported or kept.

SwiftData with CloudKit cannot enforce `@Attribute(.unique)`. In practice the store fails to load if unique constraints are present, or if any non-optional attribute lacks a default value. The v1 schema breaks both rules on all three entities. CloudKit Production schemas are additive-only.

The recommendation is unchanged: **LATER (after v1, gated behind a schema refactor and a privacy review)**. Keep the zero-networking / no-iCloud boundary for v1.

---

## Findings

### 1. App Store privacy labels: "Data Not Collected"

**Claim:** Storing data only in the user's private CloudKit database is not developer collection, so "Data Not Collected" can stay.
**Status:** Verified as inference, with lower confidence than the original. **Confidence:** medium-high (was "High").

**Evidence (verbatim, developer.apple.com/app-store/app-privacy-details/):**
> "“Collect” refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time."

> "“Third-party partners” refers to analytics tools, advertising networks, third-party SDKs, or other external vendors whose code you’ve added to your app."

> "You use Apple frameworks or services, such as MapKit, CloudKit, or App Analytics. If you collect data about your app from Apple frameworks or services, you should indicate what data you collect and how you use it. You are not responsible for disclosing data collected by Apple."

**Evidence (developer.apple.com/documentation/cloudkit/ckcontainer/privateclouddatabase):**
> "Only the user can access their private database, by default. They own all of the database’s content and can view and modify that content. Data in the private database isn’t visible in the developer portal."
> "Data in the private database counts toward the user’s iCloud storage quota."

**Corrections:**
- **Encryption.** The original said private DB records are "end-to-end encrypted or protected". Apple Support (support.apple.com/en-us/102651) says: "Third-party app data stored in iCloud is always encrypted in transit and on server. When you turn on Advanced Data Protection, third-party app data stored in iCloud Backup and CloudKit encrypted fields and assets are end-to-end encrypted." Under standard data protection, "The encryption keys … are secured in Apple data centers." Apple can technically decrypt; the developer cannot read the records. Optional hardening: `@Attribute(.allowsCloudEncryption)` (SwiftData, iOS/iPadOS 17+, macOS 14+, tvOS 17+, visionOS 1+ per Apple's attribute-option docs) stores values as CloudKit encrypted fields.
- **Developer access.** The original said the developer has "zero access". developer.apple.com/icloud/logs/ says: "Logs show you every CloudKit server event for each user without exposing any personally identifiable information. Log entries only display anonymous, container-specific CloudKit user IDs … The reports can show record modifications per account, but not the actual data that has changed." Fields include Time, Platform, CK User ID, Client OS, Database and Operation. Logs cover "the past week" and can be exported "for offline analysis".
- *Interpretation:* Apple presents these logs as privacy-preserving, and viewing them is not clearly "collection". But the App Privacy guidance says to disclose data you **collect about your app from Apple services**. The safest way to keep "Data Not Collected" honest is a written policy: do not export, retain or link CloudKit Console logs or telemetry. Re-check the App Store Connect questionnaire before release.

### 2. SwiftData + CloudKit model constraints and schema conflicts

**Claim:** CloudKit integration can't use `@Attribute(.unique)` or non-optional relationships, which conflicts with the v1 models.
**Status:** Verified for `.unique`. Corrected for relationships (the v1 models have none) and for the "fatal exception" wording.

**Repo (Verified):** `ProgressModels.swift` declares `@Attribute(.unique) var questionId` (QuestionProgressEntity), `@Attribute(.unique) var id` (ExamAttemptEntity) and `@Attribute(.unique) var key` (PreferencesEntity). None of these properties has a default value **at the declaration**. Defaults appear only on some `init` parameters.

**Apple (verbatim, SwiftData "Syncing model data across a person’s devices"):**
> "…the SwiftData framework does include a small number of features that CloudKit doesn’t support natively, such as unique constraints and nonoptional relationships."
> "@Attribute — The framework synchronizes changes concurrently and at opportune times, which means CloudKit is unable to enforce the unique property option."
> "@Relationship — … CloudKit requires all relationships to be optional. … CloudKit is unable to support the deny delete rule."

Core Data "Creating a Core Data Model for CloudKit" adds: "Unique constraints aren’t supported." "`Undefined` and `objectID` attribute types aren’t supported." "Entities in a configuration must not have relationships to entities in another configuration."

**Optional-or-default rule (Verified, secondary source only):** The current Apple docs do **not** state this rule. Core Data's store-load error text does, as reproduced in a 2023 developer blog (alexanderlogan.co.uk) and in an Apple Developer Forums thread title (thread 735349):
> "NSCocoaErrorDomain Code=134060 … CloudKit integration requires that all attributes be optional, or have a default value set. … CloudKit integration does not support unique constraints."

*Inference:* every non-optional property in the three entities needs a default at the declaration (for example `var attempts: Int = 0`); defaults on `init` parameters do not count.

**Correction:** the failure is "Store failed to load" with a thrown error, not a "fatal runtime exception". It only becomes fatal if the app calls `fatalError` on container-creation errors.

**New project-specific note (inference):** `PreferencesEntity` is a singleton keyed `"preferences"`. Without uniqueness, each device would create its own singleton and sync would produce duplicates. This supports keeping preferences out of sync (Decision 2).

### 3. Schema evolution and migration

**Claim:** CloudKit schemas are additive-only once in Production.
**Status:** Verified, with wording corrected.

- SwiftData sync article: "CloudKit schemas are additive only, which means you’re unable to delete model types or change existing model attributes after you promote a schema to production."
- Core Data article: "After you promote your schema to production, the record types and their fields are immutable and exist for all time. You can add new record types, and additional fields to existing record types, but you can’t modify or delete existing record types." Also "you can’t rename or delete CloudKit record types and fields in production." Suggested strategies: migrate to a new container, add fields incrementally, or use a `version` attribute.
- WWDC22 10120 (Verified): "lightweight migration only materializes schema changes in the local store file … does not make changes to the CloudKit schema."
- SwiftData syncs through `NSPersistentCloudKitContainer` (Verified: "SwiftData uses the NSPersistentCloudKitContainer class from Core Data to handle CloudKit synchronization"). The schema is set up in DEBUG with `initializeCloudKitSchema()` (Verified, from the article's code sample).
- **Correction:** the original said "records cannot be deleted or renamed". User **records** can be deleted. It is record **types and fields** that are immutable. "Non-optional attributes cannot be added without default values" follows from the optional-or-default rule in Finding 2 (secondary source).

### 4. Entitlements and platform support

**Claim:** Supported on iOS, iPadOS, macOS, visionOS and tvOS, with specific capabilities.
**Status:** API support Verified. CKDatabase versions Corrected. Project-level parity Corrected. tvOS caveats Unverified.

**Availability (Apple docs metadata):**
- SwiftData and `ModelConfiguration.CloudKitDatabase`: iOS/iPadOS 17.0, Mac Catalyst 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0 (watchOS 10.0).
- `NSPersistentCloudKitContainer`: iOS/iPadOS 13.0, macOS 10.15, tvOS 13.0, visionOS 1.0.
- `CKDatabase`: iOS/iPadOS **8.0**, macOS **10.10**, Mac Catalyst 13.1, tvOS (available, no version listed), visionOS 1.0. The original's 10.0 / 10.12 / 10.0 figures were wrong.
- All are far below the project's 27.0 minimums (DEC-APPLE-004).

**Project parity (Corrected):** `apps/apple/project.yml` adds `ProgressModels.swift` and `ProgressStore.swift` only to `CanadianHam` (iOS + macOS) and its tests. The `CanadianHamTV` and `CanadianHamVision` targets are separate apps (`com.djensenius.CanadianHam.TV`, `.Vision`) with no SwiftData progress store. Syncing on tvOS or visionOS first needs those targets to get progress storage (REQ-APPLE-005/006 "later parity"). All three apps would need the same iCloud container in their entitlements. Configuring iCloud services: "You can also use containers to share files and data between multiple apps belonging to the same developer."

**Capabilities (Verified):**
- SwiftData article: "SwiftData requires two separate capabilities … the iCloud capability … and the Background Modes capability, which lets your app receive remote notifications from CloudKit."
- Configuring iCloud services: the iCloud capability adds `com.apple.developer.icloud-container-identifiers`; CloudKit adds `com.apple.developer.icloud-services`; and "Xcode automatically adds the Push Notifications capability to your target if you enable the CloudKit service because CloudKit uses push notifications."
- Core Data setup: enable the "Remote notifications" Background Mode for silent CloudKit notifications.

**Conflicts with project policy (new, from the repo):** `docs/privacy.md` currently lists "Push notifications" under disallowed data flows. It also says "No app entitlements for iCloud sync or push notifications" and "Do not add entitlements for network-dependent capabilities unless a future privacy review approves a new scope." Enabling sync needs a privacy review that changes these rules (DEC-APPLE-003: "iCloud sync may be reconsidered later only with a privacy review").

**tvOS:**
- The background-execution and multi-user profile caveats are **Unverified**.
- Apple's *archived* tvOS App Programming Guide (2017; old) says: "Storage on Apple TV is limited, and there is no guarantee that information stored on the device will be available the next time a user opens your app … For large storage needs, greater than 1MB, your app needs to implement CloudKit." *Inference:* if tvOS ever stores progress, cloud backing may matter more there than on other platforms. Check current tvOS storage guidance before relying on this.

### 5. User controls: opt-in default, sign-out, cloud data deletion

**Claim:** A default-OFF toggle needs container rebuild or a dual store; sign-out must fall back gracefully; GDPR/privacy requires "Delete iCloud Data".
**Status:** Mixed (see below).

- **Default discovery (Verified):** "By default, SwiftData inspects your app’s Entitlements.plist file to determine which CloudKit container to use." Also: "Specifying `none` overrides any automatically discovered identifiers and disables SwiftData’s automatic iCloud sync." `.private(_:)` "Enables managed CloudKit sync using the specified ubiquity container"; `.automatic` uses "the primary ubiquity container from the app’s entitlements". *Implication:* once entitlements are added, every `ModelConfiguration` without an explicit `.none` would sync. Default-OFF must therefore be enforced in code.
- **Dynamic toggle and migration (Unverified):** Apple has no doc on switching a SwiftData container between local and CloudKit at runtime. Treat the design (rebuild the container, copy and deduplicate local records) as inference, and prototype it.
- **Sign-out (Unverified / unclear):**
  - `CKAccountChanged` ("A notification that a container posts when the status of an iCloud account changes"; iOS 9+, macOS 10.11+, tvOS 9+, visionOS 1+) and `CKAccountStatus` (`.available`, `.noAccount`, `.restricted`, `.temporarilyUnavailable`, `.couldNotDetermine`) are **Verified**.
  - The privateCloudDatabase doc says that without an iCloud account "any attempt to use it results in an error".
  - The claim that the app can fall back "without deleting the user's cached study progress" is **not** guaranteed by the framework. Community reports (StackOverflow 70755205, 58179862) say `NSPersistentCloudKitContainer` removes or reloads mirrored local data when iCloud is turned off or the account changes.
  - *Recommendation (inference):* keep a local-only store as the source of truth, or test sign-out explicitly before promising "no progress loss".
- **Cloud data deletion:**
  - Apple guidance is **Verified**: "If your app stores data in CloudKit on behalf of your users, give them a simple way to delete their data." The `CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: zoneIDs)` sample on `privateCloudDatabase` is **Verified**.
  - SwiftData's sync article says SwiftData uses `NSPersistentCloudKitContainer` for CloudKit synchronization; the delete flow should not leave that mirror active against local records after deleting the CloudKit zone, or those local records can be eligible for re-upload.
  - *Project inference:* implement deletion as a coordinated flow: stop sync / rebuild the progress container with explicit `.none`, delete the private CloudKit progress zone, then either delete local records or keep them in the local-only store according to the user's choice, and verify the zone is not recreated or re-uploaded after restart.
  - "GDPR/privacy compliance *requires*" is **Unverified** as a legal claim. Apple's GDPR & CloudKit tech talk: "I am an engineer, not a lawyer … consult a lawyer."
  - *Project inference:* REQ-QUIZ-005 "Reset all data" semantics should be extended to cover cloud data when sync is on.

### 6. Conflict resolution with Leitner progress and web export/import

**Claim:** SwiftData's default "last-writer-wins" field merging can cause problems; deterministic domain merges can fix it.
**Status:** "Last-writer-wins" is **Unverified** (not in the Apple CloudKit/Core Data docs checked). The merge rules are **researcher inference** and unchanged.

- Apple does document that sync happens in the background on the system's schedule: "CloudKit periodically sends push notifications … the system creates a background task to download all of the changed records". It also says "Push notifications may get dropped or deferred". Divergent progress across devices is therefore plausible (inference).
- Merge rules (inference, unchanged): order by `lastAttemptedAt`. Take `box`, `dueAt`, `lastResult` and `recentResults` from the latest attempt. Union exam attempts by `id`.
- **Repo note:** `lastAttemptedAt`, `dueAt`, `startedAt` and `submittedAt` are stored as `String`. Max/compare logic must use a normalized, sortable timestamp format (inference).
- The web export/import schema is in `docs/architecture.md`, which was not re-audited here. The same merge function can serve both paths (inference).

### 7. Zero-network testability

**Claim:** CloudKit-capable SwiftData code can be tested offline without accounts.
**Status:** API Verified. The signing claim is Unverified.

- `ModelConfiguration.init(_:schema:isStoredInMemoryOnly:allowsSave:groupContainer:cloudKitDatabase:)` and `isStoredInMemoryOnly` ("A Boolean value that determines whether the associated persistent storage is ephemeral and exists only in memory") are **Verified**. With `.none`, managed sync is turned off (Verified).
- "Passes under `CODE_SIGNING_ALLOWED=NO`" is **Unverified**. **Risk:** the repo's macOS test command signs ad hoc with an entitlements file (`CODE_SIGN_IDENTITY=-`). Secondary sources say iCloud entitlements are restricted on macOS and need a provisioning profile, so an ad-hoc-signed test host may fail to launch. Plan test-only entitlements, or keep iCloud entitlements out of the test configuration.
- Pure-function merge tests against `fixtures/` (inference) are unchanged.

---

## Contradictions

- **Developer intuition vs Apple's definition.** Resolution (corrected): Apple's "collect" definition plus the private-database access model *support* "Data Not Collected" by inference. Apple does **not** explicitly rule on CloudKit private data. The CloudKit-specific line on the App Privacy page is about data you collect *from* Apple services, not an exemption. The original's "explicitly distinguishes … no decryption key" was wrong: Apple holds the keys under standard data protection, and the developer can see anonymous per-user operation logs.
- **"Seamless" SwiftData sync vs unique constraints.** Resolution: Verified. Unique constraints and non-defaulted non-optional attributes make the CloudKit-backed store fail to load. Enforce uniqueness in the repository/fetch layer.
- **Brief vs project policy (new).** CloudKit needs the Push Notifications capability and the remote-notification background mode. `docs/privacy.md` currently disallows both, so the privacy docs must be changed through the required privacy review.

---

## Missing Evidence (corrected — the original said "None")

- No explicit Apple statement that private-database-only CloudKit storage qualifies for "Data Not Collected". This is an inference.
- No current official Apple doc states the "all attributes optional or defaulted" rule; it rests on framework error text seen in secondary sources.
- No official guidance on toggling SwiftData CloudKit sync at runtime, or on local-data behaviour when the iCloud account changes.
- No official source on SwiftData/CloudKit conflict-resolution semantics ("last-writer-wins").
- No verification of tvOS background-notification limits or multi-user Apple TV behaviour.
- No verification that tests with iCloud entitlements run under the repo's unsigned/ad-hoc `xbuild` commands.
- ISED question-bank PDF URL not fetched (not decision-relevant; the project uses the delimited TXT).

---

## Sources

**Kept (verified):**
- App Privacy Details on the App Store: https://developer.apple.com/app-store/app-privacy-details/
- SwiftData, Syncing model data across a person’s devices: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
- ModelConfiguration.CloudKitDatabase: https://developer.apple.com/documentation/swiftdata/modelconfiguration/cloudkitdatabase-swift.struct
- Responding to Requests to Delete Data: https://developer.apple.com/documentation/cloudkit/responding-to-requests-to-delete-data
- CKDatabase: https://developer.apple.com/documentation/cloudkit/ckdatabase (versions corrected)
- CKAccountStatus: https://developer.apple.com/documentation/cloudkit/ckaccountstatus
- WWDC22 Evolve your Core Data schema: https://developer.apple.com/videos/play/wwdc2022/10120/
- ISED RIC-3 (Issue 5, March 2022): https://www.ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/radiocom-information-circulars-ric/ric-3-information-amateur-radio-service

**Added:**
- CKContainer.privateCloudDatabase: https://developer.apple.com/documentation/cloudkit/ckcontainer/privateclouddatabase
- Core Data, Creating a Core Data Model for CloudKit: https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit
- Core Data, Setting Up Core Data with CloudKit: https://developer.apple.com/documentation/coredata/setting-up-core-data-with-cloudkit
- NSPersistentCloudKitContainer: https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer
- Configuring iCloud services: https://developer.apple.com/documentation/xcode/configuring-icloud-services
- CloudKit Logs: https://developer.apple.com/icloud/logs/
- iCloud data security overview: https://support.apple.com/en-us/102651
- GDPR & CloudKit tech talk: https://developer.apple.com/videos/play/tech-talks/703/
- `@Attribute(.allowsCloudEncryption)` (iOS/iPadOS 17+, macOS 14+, tvOS 17+, visionOS 1+): https://developer.apple.com/documentation/swiftdata/schema/attribute/option/allowscloudencryption
- Archived tvOS App Programming Guide, iCloud Storage (2017): https://developer.apple.com/library/archive/documentation/General/Conceptual/AppleTV_PG/iCloudStorage.html

**Secondary (used only where no official source exists; flagged):**
- Alex Logan, "SwiftData, meet iCloud" (2023): framework error text
- Apple Developer Forums thread 735349
- StackOverflow 70755205 and 58179862 (sign-out data loss reports)

**Unverified:** ISED Basic bank PDF URL (`amateur_basic_questions_en_2025-07-15.pdf`).

**Rejected (unchanged):** third-party sync SDKs (Firebase, Realm, Couchbase). They violate `docs/privacy.md`'s forbidden-dependency list.

---

## Recommendation: LATER (after v1) — unchanged

### Verdict: **DO NOT IMPLEMENT IN V1; SCHEDULE FOR AFTER V1 (P7), BEHIND A PRIVACY REVIEW**

**Rationale (adjusted):**
1. **Keep v1 simple and network-free.** v1 policy forbids iCloud sync: `AGENTS.md` says "Apple app must work fully offline and collect no data; no networking code, third-party SDKs, analytics, or iCloud sync in v1". The same rule is in DEC-APPLE-003, REQ-APPLE-003 and `docs/privacy.md`. Sync would also bring in the Push Notifications capability and remote-notification background mode, which `privacy.md` currently disallows. *Corrected:* the original's "guarantees an effortless App Store approval" was an unsupported claim and has been removed.
2. **Schema change.** CloudKit needs `@Attribute(.unique)` removed from all three entities **and** declaration-level defaults (or optionals) for every non-optional property. Uniqueness then has to be enforced in `ProgressStore`. *Adjusted:* the repo stays private until T-009, so there is no public install base yet. "Migrating existing stores" before v1 would affect only development and TestFlight data. The main cost of doing it now is rewriting upsert/dedup logic in v1, not migrating users (see Decision 1).
3. **Users can already move their data.** Export and import of progress JSON is **REQ-QUIZ-005** (with REQ-APPLE-003 and REQ-OFFLINE-001), not "REQ-PROGRESS-001" as the brief said. T-506 not verified.

---

## Phased Implementation Plan (after v1 / P7) — adjusted

### Phase 0: Privacy review (new; required by DEC-APPLE-003)
- Change `docs/privacy.md` and REQ-APPLE-003/004 to allow, **only when the user opts in**: iCloud (CloudKit) entitlements, the Push Notifications capability, and the remote-notification background mode.
- Write down the reasoning for "Data Not Collected", citing the App Privacy "collect" definition and the privateCloudDatabase access model.
- Adopt a **no-export/no-retention policy for CloudKit Console logs and telemetry**.
- Re-run the App Store Connect questionnaire.

### Phase 1: Schema refactor and removing uniqueness (estimate ~1–2 days, unverified)
- Add `CanadianHamProgressSchemaV2` with a `SchemaMigrationPlan` stage. Remove `@Attribute(.unique)` from all three entities. Give every non-optional property a **declaration-level** default.
- Add query-before-insert and duplicate resolution in `ProgressStore`, keyed by `questionId`, exam `id`, and preferences `key`.
- Keep timestamps in a normalized, sortable format.
- Tests: V1→V2 migration, deduplication, in-memory `cloudKitDatabase: .none`.

### Phase 2: Opt-in CloudKit configuration (estimate ~2–3 days, unverified)
- Add the iCloud (CloudKit) capability, Push Notifications (Xcode adds it automatically) and Background Modes → Remote notifications in `apps/apple/project.yml`. Regenerate with XcodeGen.
- Use an explicit container. **Corrected:** not `iCloud.ca.canadianham.app`; for example `iCloud.com.djensenius.CanadianHam`, to be confirmed by the owner. Use the same container for any tvOS/visionOS app that later gets progress storage.
- Settings → **"iCloud Sync"**, **OFF by default**:
  - OFF: `ModelConfiguration(cloudKitDatabase: .none)`. This must be explicit, because entitlements trigger auto-discovery.
  - ON: `.private("<container-id>")` (explicit, rather than `.automatic`).
- Keep `PreferencesEntity` in a separate `ModelConfiguration` with `.none`. This is allowed because there are no cross-configuration relationships.
- Prototype the runtime toggle and first-time copy/dedup (no Apple guidance; inference).
- Watch `CKAccountChanged`, check `accountStatus`, and **test sign-out and iCloud-disable for local data loss** before promising progress is kept.
- Make the test configuration (macOS ad hoc, `CODE_SIGNING_ALLOWED=NO`) build without restricted iCloud entitlements.

### Phase 3: Conflict resolution and cloud data management (estimate ~1–2 days, unverified)
- Deterministic merge for Leitner progress and exam attempts. Use the same function for web JSON import.
- **"Delete iCloud Progress"** in Settings as a coordinated delete, not a standalone zone delete while the mirror is active:
  1. Stop sync first: quiesce CloudKit work and rebuild/switch the progress container to explicit local-only `.none`.
  2. Delete the private CloudKit progress zone with `CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: zoneIDs)`.
  3. Follow the user's choice: delete local progress too (for Reset all data / delete everywhere), or keep local records only in the local-only store.
  4. Verify restart and disabled sync do not recreate the zone or re-upload records.
- Optional: `@Attribute(.allowsCloudEncryption)` on progress fields.
- Airplane-mode, no-account and account-switch smoke tests.
- tvOS/visionOS: sync only after those targets get progress storage (REQ-APPLE-005/006 parity).

---

## Decisions for the Owner (kept; adjusted where facts changed)

1. **Schema strategy (now vs later).** Remove `@Attribute(.unique)` *and* add declaration-level defaults now in v1 (keeping `cloudKitDatabase: .none` and no entitlements), or keep the v1 schema and migrate after v1?
   *Recommendation (kept):* keep v1 as is and migrate later through `SchemaMigrationPlan`.
   *Adjusted note:* there is no public install base before T-009, so changing it now costs less in migration than the original brief said. The trade-off is mostly about adding dedup logic to v1 now.
2. **Sync scope.** Should preferences sync, or only learning progress?
   *Recommendation (kept, reinforced):* sync learning progress only. Keep `PreferencesEntity` local in a separate `.none` configuration. As a synced singleton it would duplicate across devices without uniqueness.
3. **Default state.** Confirm sync stays strictly **opt-in** (OFF until the user turns it on).
4. **(New) Container ID and platform scope.** Confirm the container ID (for example `iCloud.com.djensenius.CanadianHam`) and whether tvOS/visionOS get progress storage, and therefore sync, in the same phase.
5. **(New) Privacy-doc changes.** Approve the scoped exception in `docs/privacy.md` for CloudKit, Push Notifications and the remote-notification background mode, and the CloudKit Console log no-retention policy.

---

## Proposed Backlog subtasks (replaces "Proposed PLAN.md Rows")

`tasks/PLAN.md` is now only a pointer (T-705 → **task-13** "Optional iCloud sync"). Create these with the `backlog` CLI on a task branch, for example `backlog task create -p task-13 … --ac …`. Do not edit PLAN.md.

| Proposed subtask | Depends on | Acceptance criteria |
|---|---|---|
| task-13.x Privacy review for opt-in iCloud sync | v1 release | `docs/privacy.md`, REQ-APPLE-003/004 and DEC-APPLE-003 updated for opt-in CloudKit, Push and Remote-notification scope; "Data Not Collected" reasoning recorded with Apple sources; CloudKit Console log no-retention policy documented. |
| task-13.x SwiftData schema V2 for CloudKit compatibility | privacy review | `.unique` removed from all three entities; declaration-level defaults on all non-optional properties; dedup in `ProgressStore`; V1→V2 migration and dedup tests pass via `xbuild`. |
| task-13.x Opt-in iCloud sync toggle | schema V2 | iCloud (CloudKit), Push and Background Modes (remote notifications) added in `project.yml`; toggle defaults OFF using explicit `.none` / `.private("<container>")`; preferences stay in a local configuration; account-change and sign-out behaviour tested for local data loss; tests build without restricted entitlements. |
| task-13.x Merge rules, cloud deletion and privacy verification | toggle | Deterministic Leitner/exam merge shared with web import; coordinated "Delete iCloud Progress" flow that stops sync / switches to local-only before zone deletion, handles the user's local delete-or-keep choice, and verifies no re-upload; Reset-all covering cloud data; airplane-mode and no-account smoke tests; App Store privacy answers re-checked. |

---

## Audit appendix

**1. Verified claims:** rows 1, 2 (quote only), 6, 7, 11, 12, 15, 17, 20, 21, 25, 31, 33 in the summary table. Row 3 is verified as inference only. Row 10 is verified from secondary sources only.

**2. Contradicted (corrected) claims:**
- Encryption is not end-to-end by default (row 4).
- The developer is not at "zero access": CloudKit Logs exist (row 5).
- The relationship conflict doesn't apply to v1 (row 8).
- "Fatal exception" should be "store fails to load" (row 9).
- CKDatabase versions were wrong (row 13).
- tvOS/visionOS targets have no progress store (row 14).
- The quote is attributed to the wrong file (row 27).
- `REQ-PROGRESS-001` doesn't exist (row 28).
- PLAN.md is obsolete (row 29).
- The container/bundle ID prefix was wrong (row 30).

**3. Weak, unclear or unsupported claims:** tvOS background/multi-user (16); dynamic toggle (18); sign-out keeping data (19); GDPR "requires" (22); last-writer-wins (23); unsigned testing (26); "Updated 2024/2025" (34).

**4. Source-quality concerns:**
- The optional/default rule and the unique-constraint load failure rest on framework error text quoted in a 2023 blog and a forum thread, not on current Apple docs.
- The tvOS storage guidance is from an archived 2017 guide.
- The sign-out data-loss evidence is community StackOverflow.

**5. Missing evidence:** see the "Missing Evidence" section above.

**6. Material contradictions:**
- The original's "Missing Evidence: None" vs the gaps listed above.
- The original's own inconsistency: Phase 2 uses `.private(...)` while the T-705b row uses `.automatic`. Resolved here in favour of an explicit `.private`.
- The brief's plan vs `docs/privacy.md`, which forbids push notifications and iCloud/push entitlements.

**7. Implications for the conclusion:**
- The LATER verdict is unchanged, and the corrections make it stronger: a broader schema refactor, a required privacy-doc change, and an unproven sign-out data path.
- Confidence in keeping "Data Not Collected" drops from High to medium-high. It is a well-supported inference, conditional on not exporting or keeping CloudKit logs, and should be re-checked in App Store Connect before release.
