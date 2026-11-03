# App Store distribution and Xcode Cloud

Status: TASK-86 preparation. Nothing here has been uploaded. The owner sets up Xcode Cloud; the coordinator still uploads only internal TestFlight builds with Fastlane ([TestFlight runbook](testflight.md)). Use this with the [release checklist](release-checklist.md).

## Gates

- Internal team-member TestFlight is the only delivery allowed now (TASK-1.10 exception).
- External TestFlight testing, App Store submission and any upload of a distribution build (one without `testFlightInternalTestingOnly`) wait for both:
  - **TASK-1.7** and the release gates it depends on (ISED permission in TASK-1.1, the release-candidate pass in TASK-1.6 and the [release checklist](release-checklist.md#store-submission)); and
  - **TASK-85**: required-reason API declarations in every `PrivacyInfo.xcprivacy`. App Store Connect rejects uploads without them.
- Only the owner creates or edits Xcode Cloud workflows, App Store Connect settings, testers and groups. Agents never do.
- Every archive, local or Xcode Cloud, uses the **Release** configuration. Never archive or distribute `DebugCloudKit`; v1 has no iCloud, CloudKit or push capability.

## What is in the repository

| Item | Purpose |
| --- | --- |
| `fastlane/ExportOptions.plist` | Internal-only export (`testFlightInternalTestingOnly`). Default for every `beta` lane. |
| `fastlane/ExportOptions-AppStore.plist` | App Store distribution export: `app-store-connect`, automatic signing, team `9JALHNGRBQ`, no internal-only flag. Used only with `distribution:true`. |
| `apps/apple/ci_scripts/` | Xcode Cloud custom build scripts and the build-number floor (see [Xcode Cloud scripts](#xcode-cloud-scripts)). |
| `scripts/test-xcode-cloud-ci-scripts.sh` | Local dry run of the Xcode Cloud scripts with simulated `CI_*` variables. |

## Fastlane distribution export (fallback and local check)

Any `beta` lane accepts `distribution:true`, which needs `export_only:true`:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer FASTLANE_SKIP_UPDATE_CHECK=1 fastlane ios beta export_only:true distribution:true       # .ipa with Watch/CanadianHamWatch.app
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer FASTLANE_SKIP_UPDATE_CHECK=1 fastlane mac beta export_only:true distribution:true       # .pkg
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer FASTLANE_SKIP_UPDATE_CHECK=1 fastlane appletvos beta export_only:true distribution:true # .ipa
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer FASTLANE_SKIP_UPDATE_CHECK=1 fastlane xros beta export_only:true distribution:true      # .ipa
```

- Run one at a time. Each archives Release through `xbuild` with the dedicated build keychain, exactly like an internal beta.
- Exports use `ExportOptions-AppStore.plist` and **do not** add the internal-only official reference sheet (`-DOFFICIAL_REFERENCE_SHEET`).
- Artifacts go to `fastlane/archives/appstore/<platform>/` and `fastlane/builds/appstore/<platform>/<build>/`, apart from internal exports. Both folders are gitignored; delete them after inspection.
- The lane refuses `distribution:true` without `export_only:true`, and refuses to upload an `artifact_path` under `fastlane/builds/appstore/`. Lifting that refusal is part of the work that clears TASK-1.7 and TASK-85, not something to work around.
- `pnpm test:fastlane` covers the option parsing and those refusals.

Inspect each export before relying on it:

```sh
codesign -dv --verbose=2 <App>.app                    # Authority=Apple Distribution: … (9JALHNGRBQ)
codesign -d --entitlements - --xml <App>.app          # no com.apple.developer.icloud*, ubiquity*, aps-environment
plutil -p fastlane/builds/appstore/<platform>/<build>/ExportOptions.plist   # testFlightInternalTestingOnly => false
pkgutil --check-signature CanadianHam.pkg             # macOS: 3rd Party Mac Developer Installer
```

For the iOS IPA, also confirm `Payload/CanadianHam.app/Watch/CanadianHamWatch.app` is present and signed the same way, with matching `CFBundleVersion`. No app may contain `official-basic-exam/`.

## Build numbers

Fastlane uploads use a timestamp build number (`%Y%m%d%H%M`, such as `202610271757`) for every platform. Xcode Cloud instead stamps its own integer `CI_BUILD_NUMBER` into every build it distributes; it starts at 1 and adds 1 per build. Scripts can't safely override that, so build numbers are kept in order this way:

1. **Before the first Xcode Cloud build**, the owner sets **App Store Connect → the app → Xcode Cloud → Settings → Build Number → Next Build Number** to the current timestamp (`date +%Y%m%d%H%M`) or later. That is above every Fastlane upload. Only an Admin or App Manager can change it.
2. `apps/apple/ci_scripts/build-number-floor` holds the highest Fastlane build number uploaded so far. `ci_pre_xcodebuild.sh` fails any archive whose `CI_BUILD_NUMBER` isn't greater, so a forgotten setting fails the build instead of going backwards.
3. **After any Fastlane upload** while both paths are in use, the owner raises Next Build Number above that upload, and the coordinator raises `build-number-floor` to the uploaded build number in a pull request. Xcode Cloud adds only 1 per build, so it falls behind the clock and a later Fastlane timestamp would otherwise be higher.

Why not restart at 1: iOS, tvOS and visionOS accept a lower build number only in a new version, and macOS build numbers must keep increasing even across versions. Bumping `MARKETING_VERSION` would not help the Mac app.

Open risk: App Store Connect has not yet been tried with a 12-digit Next Build Number. If it refuses the value, stop and tell the coordinator. Don't start Xcode Cloud archives with a lower number; the Mac app can't go back below `202610271757`.

## Xcode Cloud setup (owner only)

Agents don't do these steps. Record the date and settings in TASK-86's notes.

1. **Environment.** Use an Xcode release that includes the iOS, iPadOS, macOS, tvOS, visionOS and watchOS 27 SDKs (Xcode 27.2 builds locally) and the matching macOS image. Don't use a beta Xcode for distribution.
2. **Connect the repository.** In Xcode, open the project and create the first workflow from the Report navigator's Cloud tab. Choose the existing **Canadian Ham** app record, and grant Xcode Cloud access to `djensenius/canadian-ham`. Access doesn't change repository visibility; the repo stays private until TASK-1.7.
3. **Set Next Build Number** as in [Build numbers](#build-numbers) before starting any build.
4. **Internal workflow** (for example, "Internal TestFlight"):
   - Start condition: manual. Apple suggests a start condition that never fires, such as a branch that doesn't exist, then **Start Build** by hand on `main`.
   - Environment: the Xcode above; **Clean** on. No custom environment variables or secrets are needed. Never add variables mentioning `ICLOUD_SYNC`, `DebugCloudKit`, CloudKit entitlements or `OFFICIAL_REFERENCE_SHEET`; the scripts fail the archive if one appears.
   - Four archive actions, each with **Deployment Preparation: TestFlight (Internal Testing Only)**:

     | Platform | Scheme | Notes |
     | --- | --- | --- |
     | iOS | `CanadianHam` | Embeds `CanadianHamWatch`; don't archive the watch scheme separately. |
     | macOS | `CanadianHam` | Same target as iOS (`platform: auto`). |
     | tvOS | `CanadianHamTV` | |
     | visionOS | `CanadianHamVision` | |

     Every shared scheme archives Release; there's no configuration to choose in the workflow.
   - Post-action: **TestFlight Internal Testing** to the internal team group only.
   - No test actions are needed: GitHub CI and the local `xbuild` merge-batch runs cover tests.
5. **Distribution workflow** (for example, "App Store"), created only after TASK-1.7 and TASK-85 are Done:
   - General: **Restrict Editing** on (required for review-eligible builds).
   - Environment: **Clean** on, same Xcode.
   - The same four archive actions with **Deployment Preparation: TestFlight and App Store**.
   - Start condition: manual or a `release` tag on `main`.
   - Optional post-action: **TestFlight External Testing** (subject to beta app review).
   - Submit for App Store review in App Store Connect after the builds process; follow the [release checklist](release-checklist.md#store-submission).
6. **First run.** Check each action's log for `canadian-ham-ci:` lines: the guards passed, the scheme uses Release, and the build number is above the floor. Then confirm each platform's build processed in TestFlight. If the visionOS archive fails with `unsupported archive platform '<value>'`, Xcode Cloud reports a platform name the scripts don't know yet; add it to `ch_check_archive_scheme` in a pull request.

## Xcode Cloud scripts

Xcode Cloud runs scripts from `ci_scripts` next to the project (`apps/apple/ci_scripts/`). They are Bash 3.2 compatible, use `set -euo pipefail`, and share `canadian-ham-ci.sh`.

| Script | When | What it does |
| --- | --- | --- |
| `ci_post_clone.sh` | After the clone | Finds Node 26 (PATH, then Homebrew `node@26`, installing it if needed) and runs `check:apple-network`, `test:apple-network`, `check:apple-icloud-gate` and `test:apple-icloud-gate` with `node --run`. No `pnpm install` is needed. Fails if Node or a guard fails. |
| `ci_pre_xcodebuild.sh` | Before each `xcodebuild` | For `archive`: allows only `CanadianHam` (iOS/macOS), `CanadianHamTV` (tvOS) and `CanadianHamVision` (visionOS); requires the shared scheme's Archive configuration to be `Release`; rejects `CONFIGURATION` other than Release and any environment variable mentioning `ICLOUD_SYNC`, `DebugCloudKit`, CloudKit entitlements or `OFFICIAL_REFERENCE_SHEET`; requires `CI_BUILD_NUMBER` above `build-number-floor`. Then reruns the guards for every action that builds from source. `test-without-building` has no source, so it skips. |
| `ci_post_xcodebuild.sh` | After each `xcodebuild` | After a successful archive, reads the signed entitlements of every app in `CI_ARCHIVE_PATH` (including the embedded watch app) and fails on iCloud, ubiquity, CloudKit or `aps-environment` entitlements, unreadable signatures, or a bundled `official-basic-exam/`. |

Node 26 matches `.github/workflows/ci.yml`; update `CH_REQUIRED_NODE_MAJOR` in `canadian-ham-ci.sh` with it. Xcode Cloud builds don't run the official-sheet opt-in, so Xcode Cloud builds never contain the internal-only reference sheet.

Dry run (macOS, Node 26 on PATH, no build, no real Homebrew calls):

```sh
pnpm test:xcode-cloud-scripts   # or: node --run test:xcode-cloud-scripts
```

It runs the real guards against the repository and simulates archives for all four platforms, non-archive and `test-without-building` actions, `DebugCloudKit` and environment overrides, low build numbers, failing and missing guards, Node discovery with a stub Homebrew, and ad-hoc signed fake archives with and without push or iCloud entitlements. Run `shellcheck -x apps/apple/ci_scripts/*.sh scripts/test-xcode-cloud-ci-scripts.sh` after editing the scripts. This dry run is macOS-only, so it's not part of `pnpm test`.

## Differences from Fastlane

- **macOS SDK.** The Fastlane mac lane passes `SDKROOT=macosx SUPPORTED_PLATFORMS=macosx`; Xcode Cloud can't pass build settings. On 2026-11-02 a local `xbuild` Release build of `CanadianHam` for `generic/platform=macOS` without those overrides (unsigned, separate derived data) succeeded and produced a native macOS 27 app without the watch app, so no project change is expected. Confirm on the first Xcode Cloud macOS archive.
- **Official reference sheet.** Owner decision 2A allows it only in internal Fastlane betas. Xcode Cloud archives and `distribution:true` exports never include it.
- **Build numbers.** Timestamps for Fastlane, an incrementing integer for Xcode Cloud (see above).

## Retiring Fastlane

Keep the Fastlane `beta` lanes as the working fallback until one Xcode Cloud build has archived and processed **all four platforms** (iOS with the watch, macOS, tvOS and visionOS) in TestFlight. Then the owner decides whether to retire them:

- The coordinator stops uploading with Fastlane and starts the owner's internal Xcode Cloud workflow instead (or the owner starts it).
- Internal builds then lose the official reference sheet (owner decision 2A); the owner accepts that or keeps Fastlane for it.
- Removing the lanes, `ExportOptions*.plist` and the build keychain is a separate Backlog task. `asc_status`, `register_bundle_ids` and the signing lanes may stay for maintenance.
- Until then, keep `build-number-floor` current after every Fastlane upload.

## References

- [Writing custom build scripts](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts)
- [Environment variable reference](https://developer.apple.com/documentation/xcode/environment-variable-reference)
- [Making dependencies available to Xcode Cloud](https://developer.apple.com/documentation/xcode/making-dependencies-available-to-xcode-cloud)
- [Setting the next build number for Xcode Cloud builds](https://developer.apple.com/documentation/xcode/setting-the-next-build-number-for-xcode-cloud-builds)
- [Creating a workflow that builds your app for distribution](https://developer.apple.com/documentation/xcode/creating-a-workflow-that-builds-your-app-for-distribution)
- [Configuring your Xcode Cloud workflow's actions](https://developer.apple.com/documentation/xcode/configuring-your-xcode-cloud-workflow-s-actions)
- [Xcode Cloud workflow reference](https://developer.apple.com/documentation/xcode/xcode-cloud-workflow-reference)
- [Distributing your Xcode Cloud builds through TestFlight](https://developer.apple.com/documentation/xcode/distributing-your-xcode-cloud-builds-through-testflight)
