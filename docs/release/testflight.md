# TestFlight runbook

Status: internal TestFlight setup for Backlog `task-1.10`. Do not invite external testers or submit public/App Store builds until `task-1.7` and the release gates in [`release-checklist.md`](release-checklist.md) allow it.

## Scope and identifiers

- App name: **Canadian Ham**.
- SKU: `canadian-ham`.
- Primary language: `en-CA`.
- Team: `9JALHNGRBQ`.
- Universal purchase bundle ID for every app target: `org.davidjensenius.CanadianHam`.
- Test bundle IDs use sub-identifiers such as `org.davidjensenius.CanadianHam.tests`, `.uitests`, `.tv.tests`, `.tv.uitests`, `.vision.tests`, and `.vision.uitests`.
- Gated post-v1 iCloud container: `iCloud.org.davidjensenius.CanadianHam`.

## One-time local setup

Before any beta lane can run, the build host needs the dedicated signing keychain, its password file (mode 600) and certificates. See [Dedicated signing keychain](#dedicated-signing-keychain-build-host): `archive_and_export` and `signing_certificates` stop with an error if the keychain or password file is missing.

1. Install fastlane if it is not already available:

   ```sh
   brew install fastlane
   ```

2. Put the App Store Connect API key at the path expected by `fastlane/Fastfile`:

   ```text
   ~/.appstoreconnect/AuthKey_XP65R4N5A2.p8
   ```

   Never commit, print, paste, or otherwise record the key contents. The Fastfile references only the key path, key ID `XP65R4N5A2`, and issuer ID `69a6de7e-a5f5-47e3-e053-5b8c7c11a4d1`.

3. Register the universal Developer Portal bundle ID. This lane is idempotent and uses the API key:

   ```sh
   fastlane ios register_bundle_ids
   ```

   Default Release/TestFlight builds require no App ID capabilities. The off-by-default `DebugCloudKit` gate is not distributed by these lanes; if a future post-v1 task distributes that gated build, the owner must separately configure the `iCloud.org.davidjensenius.CanadianHam` container plus iCloud/CloudKit and Push Notifications capabilities.

4. The owner creates the App Store Connect app record from an interactive shell because `produce` requires Apple ID authentication and 2FA:

   ```sh
   fastlane ios create_app_record
   ```

   The lane requests platforms `ios`, `osx`, and `tvos` for the same universal-purchase bundle ID. Fastlane `produce` does not accept the App Store Connect API names `appletvos` or `xros`; after the record exists, add visionOS manually in App Store Connect with **App Information → Add Platform**. Do not run this from automation.

5. Check App Store Connect state when needed:

   ```sh
   fastlane ios asc_status
   ```

### Dedicated signing keychain (build host)

Signing uses a dedicated keychain, so the lanes work from SSH, terminal multiplexers and agent sessions without unlocking the login keychain:

- Keychain: `~/Library/Keychains/canadian-ham-build.keychain-db` (no auto-lock, first in the user search list).
- Password: a random password for this keychain only (not the login password) in `~/.appstoreconnect/build-keychain.pw`, mode 600. Never commit or print it.
- Identities: Apple Development ("Created via API"), Apple Distribution and 3rd Party Mac Developer Installer for team 9JALHNGRBQ, created with the API key. Certificate files are in `~/.appstoreconnect/certs/` (mode 600).

One-time setup on a new build host:

```sh
umask 077
openssl rand -base64 32 | tr -d '\n' > ~/.appstoreconnect/build-keychain.pw
KC=~/Library/Keychains/canadian-ham-build.keychain-db
security create-keychain -p "$(cat ~/.appstoreconnect/build-keychain.pw)" "$KC"
security set-keychain-settings "$KC"
security list-keychains -d user -s "$KC" $(security list-keychains -d user | tr -d '"')
fastlane signing_certificates   # idempotent: reuses certificates whose keys are in the keychain
security set-key-partition-list -S apple-tool:,apple:,codesign:,productbuild: -s -k "$(cat ~/.appstoreconnect/build-keychain.pw)" "$KC"
```

Every beta lane unlocks this keychain before archiving. Archives sign with the Apple Development identity, and the export step re-signs for App Store Connect with the distribution identities.

To revoke access, delete the keychain, remove it from the search list, and revoke the three certificates in the Developer Portal.

## Internal beta lanes

Each beta lane archives and exports a **Release** build through `xbuild` with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, automatic signing, team `9JALHNGRBQ`, `fastlane/ExportOptions.plist` (`method=app-store-connect`), and App Store Connect API-key signing arguments. The lanes then upload the exported `.ipa` or `.pkg` with `upload_to_testflight(skip_waiting_for_build_processing: true)`.

Run only after review/merge approval and only for internal TestFlight until `task-1.7` explicitly permits wider distribution:

```sh
fastlane ios beta       # CanadianHam, generic/platform=iOS, exports .ipa
fastlane mac beta       # CanadianHam, generic/platform=macOS, exports .pkg
fastlane appletvos beta # CanadianHamTV, generic/platform=tvOS, exports .ipa
fastlane xros beta      # CanadianHamVision, generic/platform=visionOS, exports .ipa
```

Do not call `gym`, `build_app`, or `xcodebuild` directly for these uploads. The Fastfile uses only `xbuild` for archive/export.

### Re-upload an existing export

If archive and export succeeded but the upload step failed, upload the exported artifact without rebuilding:

```sh
fastlane ios beta artifact_path:$PWD/fastlane/builds/ios/<build-number>/CanadianHam.ipa
fastlane mac beta artifact_path:$PWD/fastlane/builds/mac/<build-number>/CanadianHam.pkg
```

The Fastfile points fastlane's own Xcode lookup at `/Applications/Xcode.app` because `xcode-select` on the build host points at the Command Line Tools; without that, `upload_to_testflight` fails with `undefined method 'start_with?' for nil`.

## Versioning and build numbers

- `apps/apple/project.yml` sets `MARKETING_VERSION` to `1.0.0` and generated Info.plists read `CFBundleShortVersionString` from `$(MARKETING_VERSION)` and `CFBundleVersion` from `$(CURRENT_PROJECT_VERSION)`.
- The beta lanes override `CURRENT_PROJECT_VERSION` at archive time with a timestamp build number in `%Y%m%d%H%M` format, matching the Telephone Booth convention.
- For a version change, update `MARKETING_VERSION` in `apps/apple/project.yml`, regenerate the Xcode project twice with XcodeGen, and verify the generated project is stable before archiving.

## Keeping DebugCloudKit out of uploads

The optional iCloud sync work remains behind the non-default `DebugCloudKit` configuration. The TestFlight lanes always archive `-configuration Release`, so Release uploads have no iCloud capability, no Push Notifications capability, no remote-notification background mode, and no Settings iCloud toggle. Before uploading, keep running the guard checks:

```sh
pnpm check:apple-icloud-gate
pnpm test:apple-icloud-gate
pnpm check:apple-network
pnpm test:apple-network
```

If any guard reports iCloud, push, remote-notification, networking, telemetry, or third-party SDK leakage in default builds, stop and fix that before any archive or upload.

## Troubleshooting

### `errSecInternalComponent` during CodeSign

`errSecInternalComponent` at `CodeSign` means the signing process found an identity but can't use its private key. The lanes sign with the dedicated build keychain, so check that keychain, not the login keychain:

1. Confirm the keychain and password file exist (`ls -l ~/Library/Keychains/canadian-ham-build.keychain-db ~/.appstoreconnect/build-keychain.pw`) and that the keychain is in the search list (`security list-keychains -d user`).
2. Confirm it holds the identities: `security find-identity -v ~/Library/Keychains/canadian-ham-build.keychain-db` should list Apple Development, Apple Distribution and 3rd Party Mac Developer Installer. If not, run `fastlane signing_certificates`.
3. Reapply the key partition list, then rerun the lane:

   ```sh
   KC=~/Library/Keychains/canadian-ham-build.keychain-db
   security set-key-partition-list -S apple-tool:,apple:,codesign:,productbuild: -s -k "$(cat ~/.appstoreconnect/build-keychain.pw)" "$KC"
   ```

Background: the original setup signed with the login keychain. Terminal multiplexers (Herdr, tmux), SSH and agent sessions run outside the GUI (`Aqua`) session (`launchctl managername` prints `Background`), so they can't show the keychain "Allow" prompt, and the login keychain stays locked there. The dedicated keychain avoids that; never put the login keychain password in scripts or agent sessions.

Do not switch to `DebugCloudKit` or disable Release signing for uploads.

### Internal-only builds

`fastlane/ExportOptions.plist` sets `testFlightInternalTestingOnly`, so App Store Connect only allows these builds for internal testing. Builds uploaded before that flag was added (2026-10-10, 13:06–13:16) aren't flagged; no external groups exist, so they stay internal. Remove the flag only as part of task-1.7.

## Internal-only official reference sheet

Owner decision 2026-10-12 (2A) permits the official English Basic exam reference sheet in **internal team-member TestFlight builds only**, pending ISED permission. All four `beta` lanes explicitly add `OTHER_SWIFT_FLAGS=$(inherited) -DOFFICIAL_REFERENCE_SHEET` to their Release archive command. The iOS/iPadOS/macOS app copies the rendered pages and accessible text offline; tvOS/visionOS still have no reference-sheet tool and do not bundle these assets. No upload is needed to enable the study fallback.

Default Release builds do not opt in. A future App Store/public lane **must not copy this override** until permission covers the sheet; check that `official-basic-exam/` is absent from the public app bundle. For private web previews only, `OFFICIAL_REFERENCE_SHEET=YES pnpm build:web` opts in; default production builds exclude it. Never publicly deploy the preview. See [content licensing](../content-licensing.md#official-sheet-implementation-gate-task-444) and the [release checklist](release-checklist.md#official-reference-sheet-build-gate-task-444).
