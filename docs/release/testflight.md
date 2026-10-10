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

If an archive reaches `CodeSign` and fails with `errSecInternalComponent`, the project has already resolved a signing identity and provisioning profile, but the non-interactive process cannot use the private key. This is usually a locked login keychain or a signing-key ACL prompt that the agent/CI session cannot answer.

Terminal multiplexers (Herdr, tmux) and agent panes often run in launchd's `Background` session rather than the GUI (`Aqua`) session; check with `launchctl managername`. From a `Background` session, macOS can't show the keychain "Allow" prompt, and `security show-keychain-info ~/Library/Keychains/login.keychain-db` fails with "User interaction is not allowed", even when you run the lane yourself. Run the beta lanes from a new Terminal.app window (where `launchctl managername` prints `Aqua`), or run `security unlock-keychain ~/Library/Keychains/login.keychain-db` in the same shell first.

Fix it from an interactive Terminal session, then rerun the same beta lane:

1. Unlock the login keychain if needed:

   ```sh
   security unlock-keychain ~/Library/Keychains/login.keychain-db
   ```

2. Rerun the lane interactively and choose **Always Allow** if macOS prompts for access to the signing key.
3. If the prompt cannot be used, update the key partition list for the signing identity from an interactive session according to the local signing-key policy, then rerun the lane.

Do not switch to `DebugCloudKit`, do not disable Release signing for uploads, and do not retry repeatedly from a headless/agent session that cannot show the keychain prompt.
